#!/usr/bin/env python3
"""Robust camera-stage-mapping (CSM) calibration for Pi 5 / HQ Camera.

The stock ``camera_stage_mapping.calibrate_xy`` action fails non-deterministically
on the Pi 5 pisp pipeline (``MappingError: ... residuals of fit were too large``).
See ``docs/CSM_CALIBRATION_RPI5.md`` for the full analysis. In short:

  * the stock FFT tracker decorrelates during its 15-step backlash ramp when the
    per-step displacement drifts outside the reliable (~25 % FOV) range, and
  * ``capture_downsampled_array`` returns a 4-channel RGBA array on the Pi 5,
    which naive RGB->gray conversion corrupts.

This script instead drives the stage in small fixed steps (~12 px/increment),
tracks cumulative displacement with windowed phase correlation, linear-fits
pixels vs. steps per axis, and combines the two axes with the *stock* library
function so the persisted format matches the server exactly.

Run on the Pi with a focused, textured sample under the objective and the camera
stream running:

    cd /opt/openflexure/venv/lib/python3.13/site-packages
    /opt/openflexure/venv/bin/python3 csm_calibrate_rpi5.py

Prints per-axis fit quality and writes ``/tmp/csm_new_settings.json`` WITHOUT
installing it. Install/reload steps are in the doc.
"""
import json
import time
import urllib.request

import cv2
import numpy as np
from camera_stage_mapping.camera_stage_calibration_1d import (
    image_to_stage_displacement_from_1d,
)

BASE = "http://localhost:5000"
STEP = 500      # steps per increment (~12 px -> stays inside reliable range)
N_FWD = 6       # forward increments per axis (~72 px total)
SETTLE = 0.6    # seconds to wait after a move before capturing


def get(path, timeout=20):
    return json.load(urllib.request.urlopen(BASE + path, timeout=timeout))


def post(path, body=None, timeout=30):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(body or {}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    r = json.load(urllib.request.urlopen(req, timeout=timeout))
    if isinstance(r, dict) and r.get("href"):
        for _ in range(120):
            inv = json.load(urllib.request.urlopen(r["href"], timeout=timeout))
            if inv.get("status") not in ("pending", "running"):
                return inv
            time.sleep(0.12)
        return inv
    return r


def grab():
    out = post("/camera/capture_downsampled_array", {}).get("output")
    a = np.array(out)
    if a.ndim == 3:
        a = a[..., :3]          # drop alpha -- Pi 5 pisp returns RGBA
    return cv2.cvtColor(a.astype(np.uint8), cv2.COLOR_RGB2GRAY).astype(np.float32)


def getpos():
    p = get("/stage/position")
    return np.array([p["x"], p["y"], p["z"]], float)


def move(new, settle=SETTLE):
    d = np.array(new, float) - getpos()
    post("/stage/move_relative",
         {"x": int(round(d[0])), "y": int(round(d[1])), "z": int(round(d[2]))})
    for _ in range(150):
        if not get("/stage/moving"):
            break
        time.sleep(0.1)
    time.sleep(settle)


_win = {}


def shift(a, b):
    h, w = a.shape
    if (h, w) not in _win:
        _win[(h, w)] = cv2.createHanningWindow((w, h), cv2.CV_32F)
    (sx, sy), resp = cv2.phaseCorrelate(a, b, _win[(h, w)])
    return sx, sy, resp


def calibrate_axis(name, direction, start):
    d = np.array(direction, float)
    move(start)
    for _ in range(3):                       # seat backlash in + direction
        move(getpos() + d * STEP)
    ref = grab()
    steps, cdx, cdy, resps = [0.0], [0.0], [0.0], []
    ax = ay = 0.0
    for _ in range(N_FWD):
        move(getpos() + d * STEP)
        nx = grab()
        sx, sy, r = shift(ref, nx)
        ax += sx
        ay += sy
        resps.append(r)
        steps.append(steps[-1] + STEP)
        cdx.append(ax)
        cdy.append(ay)
        ref = nx
    steps, cdx, cdy = np.array(steps), np.array(cdx), np.array(cdy)
    A = np.vstack([steps, np.ones_like(steps)]).T
    mx, bx = np.linalg.lstsq(A, cdx, rcond=None)[0]
    my, by = np.linalg.lstsq(A, cdy, rcond=None)[0]
    resid = np.sqrt(np.sum((cdx - A @ [mx, bx]) ** 2 + (cdy - A @ [my, by]) ** 2))
    span = np.hypot(cdx[-1], cdy[-1])
    frac = resid / span if span else 1.0
    ppsv = np.array([mx, my])
    pps = float(np.hypot(mx, my))
    # backlash: reverse 1000 steps (~24 px, still reliable), deficit vs expected
    r0 = grab()
    move(getpos() - d * 1000)
    r1 = grab()
    rsx, rsy, _ = shift(r0, r1)
    backlash = max(0.0, (pps * 1000 - np.hypot(rsx, rsy)) / pps) if pps else 0.0
    move(start)
    print(f"  {name}: pps={pps:.4f}px/step vec={np.round(ppsv, 4).tolist()} "
          f"frac_err={frac:.4f} backlash={backlash:.0f}steps "
          f"minResp={min(resps):.2f} (travel {span:.1f}px/{steps[-1]:.0f}steps)",
          flush=True)
    return {
        "stage_direction": np.array(direction, float),
        "image_direction": (ppsv / pps).tolist() if pps else [0, 0],
        "pixels_per_step": pps,
        "pixels_per_step_vector": ppsv.tolist(),
        "backlash": float(backlash),
        "fractional_error": float(frac),
    }


def main():
    dsf = get("/camera/downsampled_array_factor")
    img_res = list(grab().shape[:2])
    print(f"downsampling_factor = {dsf}  downsampled_res = {img_res}", flush=True)

    start = getpos()
    cals = {}
    for name, direction in [("x", (1, 0, 0)), ("y", (0, 1, 0))]:
        print(f"\n=== Calibrating {name.upper()} axis ===", flush=True)
        cals[name] = calibrate_axis(name, direction, start)
    move(start)

    cal_xy = image_to_stage_displacement_from_1d([cals["x"], cals["y"]])
    M = np.array(cal_xy["image_to_stage_displacement"], float) / dsf
    print("\n=== RESULT ===", flush=True)
    print("image_to_stage_displacement (after /downsampling):", flush=True)
    for row in M:
        print("   ", np.round(row, 4).tolist(), flush=True)
    print("backlash_vector:", np.round(cal_xy["backlash_vector"], 1).tolist(),
          flush=True)

    data = {"last_calibration": {
        "camera_stage_mapping_calibration": {
            "image_to_stage_displacement": M.tolist()},
        "downsampled_image_resolution": img_res,
        "image_resolution": [int(r * dsf) for r in img_res],
        "downsampling": int(dsf)}}
    with open("/tmp/csm_new_settings.json", "w") as f:
        json.dump(data, f, indent=2)
    fe_ok = all(cals[a]["fractional_error"] < 0.1 for a in ("x", "y"))
    print("\nWrote /tmp/csm_new_settings.json (NOT installed).", flush=True)
    print("FIT_OK =", fe_ok, flush=True)


if __name__ == "__main__":
    main()
