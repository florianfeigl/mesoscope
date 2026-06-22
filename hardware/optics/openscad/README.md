# Mesoscope HQ Camera Optics Module — OpenSCAD Sources

Custom OpenSCAD configurations for the Pi HQ Camera (IMX477) with extended tube
lens options (125mm and 150mm achromatic doublets).

## Files

| File | Purpose |
|------|---------|
| `optics_configurations_hq.scad` | Tube lens configs: 125mm and 150mm |
| `rms_optics_module_hq.scad` | Main module with dispatch for all 6 optics types |
| `picamera_hq_cmount.scad` | **C-mount override** for upstream `picamera_hq.scad` — replaces bare-PCB mounting with a C-mount flange seat |
| `build_optics.sh` | Copies configs into upstream repo and builds STLs |

## Setup

```bash
# 1. Clone upstream repo (once):
cd ~/dev/mesoscope/sources
git clone --branch hq_camera --single-branch \
  https://gitlab.com/openflexure/openflexure-microscope.git
cd openflexure-microscope && git lfs install && git lfs pull

# 2. Build (the script copies custom files into the upstream repo automatically):
cd ~/dev/mesoscope/hardware/optics/openscad
./build_optics.sh
```

If the upstream repo is re-cloned, just re-run `./build_optics.sh` — it copies the custom files each time.

## Building STLs

```bash
./build_optics.sh          # Both configurations
./build_optics.sh 125      # 125mm only
./build_optics.sh 150      # 150mm only
```

Output: `../stl/models/optics_hq_125_rms.stl` and `optics_hq_150_rms.stl`

## Available Optics Configurations

| OPTICS name | Tube lens | f (mm) | ffd (mm) | Conjugate | Camera |
|-------------|-----------|--------|----------|-----------|--------|
| `rms_f125d13` | 125mm | 125 | 122.6 | Finite | picamera_hq |
| `rms_f150d13` | 150mm | 150 | 146.9 | Finite | picamera_hq |
| `rms_infinity_f125d13` | 125mm | 125 | 122.6 | Infinity | picamera_hq |
| `rms_infinity_f150d13` | 150mm | 150 | 146.9 | Infinity | picamera_hq |

## Key Parameters (from OPTICS_MODULE.md)

| Parameter | 125mm | 150mm |
|-----------|-------|-------|
| Magnification (M) | 0.469 | 0.515 |
| Effective FN | 20.9 mm | 19.0 mm |
| Sensor fill | ~85% | ~95% |
| Lens-to-sensor (q) | 66.4 mm | 72.8 mm |

Use **150mm** for <=10x objectives (preferred).
Use **125mm** for <=4x objectives or wider field of view.

## Verifying tube_lens_ffd

Before printing, check your lens datasheet for the **back focal distance (BFD)**.
If it differs from the values below, edit `optics_configurations_hq.scad`:

| Lens | Current ffd | Parameter |
|------|------------|-----------|
| 125mm | 122.6 mm | `rms_f125d13_config` line 23 |
| 150mm | 146.9 mm | `rms_f150d13_config` line 44 |

## C-mount camera-side interface

The mesoscope uses the Pi HQ Camera **intact** (with its C-mount body), not the
bare PCB. `picamera_hq_cmount.scad` overrides the upstream `picamera_hq.scad` so:

| Parameter | Upstream (bare PCB) | Mesoscope (C-mount) |
|-----------|---------------------|---------------------|
| `mount_height` | 4.5 mm | 17.526 mm (C-mount FFD) |
| `sensor_height` | 1 mm | 0 mm (referenced to flange face) |
| Camera mount | 4× M2 posts on a 30 mm pattern | Smooth bore + 32 mm flange seat |
| Camera screws | 4× No.2 self-tapping | None — not needed with C-mount |
| Cover STL | `picamera_hq_cover.stl` | None — camera body is its own enclosure |

The optics module has a **32.6 mm bore × 4 mm deep flange seat**; the
C-mount housing of the HQ Camera (32 mm OD) slides into it with ~0.3 mm
clearance. Above the seat, a **26 mm clear bore** lets the sensor see the tube
lens unobstructed. The sensor ends up exactly 17.526 mm below the printed seat
face — matching the C-mount standard.

We deliberately do **not** print 1"-32 UN female threads (FDM threads are
unreliable at this scale). The slip-fit is more than tight enough for an
inverted scope where the C-mount face seats against the printed lip under
gravity. If you mount the scope upright, add a small printed retainer or a
wrap of PTFE tape on the camera flange.

## Implementation note: sequential_hull fix

The OpenFlexure upstream `optics_module_rms()` uses `sequential_hull()` to build
the module body. This hull always **closes the underside** — regardless of what
`picamera_hq_camera_mount` subtracts internally. The C-mount opening is therefore
cut as a post-process in `rms_optics_module_hq.scad` via an explicit `difference()`
in `optics_module_rms_cmount()`:

- Flange seat (⌀32.6 mm, 4 mm deep) cut from `camera_mount_top_z` downward
- Clear optical bore (⌀26 mm) cut through the full remaining hull depth

`rms_camera_mount_top_z()` is `-33.8 mm` for the 150 mm config (computed from
sensor Z + C-mount FFD). The safety cutout extends 40 mm further down to punch
through any hull-generated floor.