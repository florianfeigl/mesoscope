# Camera–Stage Mapping (CSM) Calibration on Pi 5 / HQ Camera

> **Status:** Working procedure captured 2026-08-25. Candidate for an upstream
> OpenFlexure PR (`v3` / `hq_camera` / Raspberry Pi 5 support).
>
> This documents why the stock `camera_stage_mapping.calibrate_xy` action fails
> intermittently on the Pi 5 + HQ Camera (IMX477, pisp ISP), the root causes we
> found, and a robust out-of-process calibration that succeeds reliably.

Camera–stage mapping produces the `image_to_stage_displacement` matrix that maps
image pixels ↔ stage steps. Smart/tiled scans need it to place adjacent tiles so
they overlap; a wrong matrix makes tiles non-overlapping and stitching fails with
`N image(s) are disconnected` (surfaces in the UI as the live-stitch "network
error").

---

## Symptoms

The built-in action (`POST /camera_stage_mapping/calibrate_xy`, or the "Calibrate"
button in the UI) fails **non-deterministically** with one of:

- `MappingError: The fit didn't look successful! The residuals of fit were too
  large.` — raised in `camera_stage_calibration_1d.py` when
  `fractional_error = residual / |Δ fit| > 0.1`.
- `no motion detected` — the initial `move_until_motion_detected` never crosses
  the detection threshold.

Re-running sometimes "works" and sometimes doesn't, on the **same** focused
sample — the tell-tale of a tracking/robustness problem, not a bad sample.

---

## Root causes

### A. FFT tracker decorrelates during the stock backlash ramp
`calibrate_backlash_1d` builds a `Tracker(..., method="fft")` (high-pass FFT
template + `displacement_from_fft_template`). FFT template matching is only
reliable to roughly **25 % of the field of view** (~77 px on the 308×410
downsampled frame). The routine then does `move_until_motion_detected` (threshold
= `max_safe_displacement × 0.2` ≈ 61.6 px) and a 15-step backwards / 15-step
forwards ramp. On lower-contrast or repetitive textures the **per-step
displacement drifts outside the reliable range**, the template decorrelates, the
tracked points scatter, the linear fit residual exceeds 10 % → `MappingError`.
Because it depends on where the ramp lands on the sample texture, it is
non-deterministic.

### B. Pi 5 returns **4-channel RGBA** downsampled arrays (Pi 5 / pisp specific)
On the Pi 5 pisp pipeline, `POST /camera/capture_downsampled_array` returns a
**308×410×4 (RGBA)** array, not RGB. Any consumer that assumes 3 channels — e.g.
`cv2.cvtColor(arr, cv2.COLOR_RGB2GRAY)` — corrupts the grayscale conversion and
feeds garbage to the tracker. Always slice `arr[..., :3]` before converting:

```python
a = np.array(output)
if a.ndim == 3:
    a = a[..., :3]          # drop alpha — Pi 5 pisp returns RGBA
gray = cv2.cvtColor(a.astype(np.uint8), cv2.COLOR_RGB2GRAY).astype(np.float32)
```

### C. Operational hazard: do not stop/starve the stream during CSM
`capture_downsampled_array` reads from the active MJPEG/lores stream. **Stopping
the stream** during a CSM operation, or **hammering** captures faster than the
pipeline delivers frames, can wedge the server: captures start returning empty /
`NaN` arrays and the stage stops responding to moves. Recovery is a service
restart:

```bash
sudo systemctl restart openflexure
```

Rules of thumb: keep the stream running throughout calibration; leave a short
settle (≥ 0.4 s) after each move before capturing; never call the stream
stop/start endpoints mid-calibration.

---

## Robust procedure (out-of-process, small-step)

Instead of the stock 15-step ramp, drive the stage in **small fixed steps** so
each incremental displacement stays well inside the reliable correlation range
(~12 px), track cumulative displacement with windowed **phase correlation**
(`cv2.phaseCorrelate` + a Hann window), and linear-fit cumulative pixels vs.
cumulative steps per axis. Combine the two axes with the **stock library**
function so the stored format matches the server exactly, then divide by the
downsampling factor and persist.

Reference implementation: `ansible/roles/openflexure/files/csm_calibrate_rpi5.py`.

```bash
# On the Pi, with a focused, textured sample under the objective and the
# camera stream running:
cd /opt/openflexure/venv/lib/python3.13/site-packages
/opt/openflexure/venv/bin/python3 \
  /home/lab/mesoscope/ansible/roles/openflexure/files/csm_calibrate_rpi5.py
```

It prints per-axis fit quality and writes the result to
`/tmp/csm_new_settings.json` **without** installing it. Sanity-check the output:

- `FIT_OK = True` (both axes `fractional_error < 0.1`; we saw ~1.6–1.7 %).
- `minResp` per axis ≳ 0.8 (phase-correlation confidence stayed high).
- Matrix magnitudes are physically sane and **near axis-aligned** for a
  non-rotated camera (small off-diagonals).

Install and reload:

```bash
DEST=/var/openflexure/settings/camera_stage_mapping/settings.json
sudo cp -a "$DEST" "$DEST.bak.$(date +%Y%m%d-%H%M%S)"     # back up first
sudo install -m 644 -o lab -g lab /tmp/csm_new_settings.json "$DEST"
sudo systemctl restart openflexure                        # server loads it on startup
```

Verify it went live:

```bash
curl -s localhost:5000/camera_stage_mapping/calibration_required          # -> false
curl -s localhost:5000/camera_stage_mapping/image_to_stage_displacement_matrix
```

---

## Persistence format

The server writes/reads `last_calibration` at
`/var/openflexure/settings/camera_stage_mapping/settings.json` and reloads it on
startup. Only these fields are consumed:

```json
{
  "last_calibration": {
    "camera_stage_mapping_calibration": {
      "image_to_stage_displacement": [[-19.80, 0.04], [-0.06, 19.26]]
    },
    "downsampled_image_resolution": [308, 410],
    "image_resolution": [616, 820],
    "downsampling": 2
  }
}
```

The stored matrix is in **full-resolution** pixels → steps: the library computes
it from the downsampled tracking frames, then divides by the downsampling factor
(2).

---

## Worked example (this machine)

| | stale / broken | new (small-step) |
|---|---|---|
| matrix | `[[13.2, -8.0], [-8.2, 12.7]]` | `[[-19.80, 0.04], [-0.06, 19.26]]` |
| character | large spurious **rotation** (off-diagonals ≈ −8) | near axis-aligned |
| X fit error | — | 1.7 % |
| Y fit error | — | 1.6 % |
| backlash (x, y) | — | 158 / 84 steps |

Ground-truth cross-check at the focused position: Y moves of +500 / +1000 / +2000
steps produced 12.7 / 24.6 / 48.7 px of pure-vertical displacement
(≈ 0.025 px/step), matching an independent open-loop ramp. The stale matrix's
rotation was the reason scan tiles did not overlap.

---

## Notes toward an upstream PR

Two independently useful fixes for `v3` on the Pi 5:

1. **RGBA handling** — anything consuming `capture_downsampled_array` (including
   the CSM tracker glue in `things/camera_stage_mapping.py`) should tolerate a
   4-channel array (`[..., :3]`). This is a plain Pi 5 / pisp correctness fix.
2. **Tracker robustness** — bounding per-step displacement (small-step ramp) or
   re-templating each step keeps FFT/phase correlation inside its reliable range
   and removes the non-deterministic `residuals ... too large` failure. This can
   be offered as an alternative calibration path without changing the stored
   format (we reuse `image_to_stage_displacement_from_1d`).
