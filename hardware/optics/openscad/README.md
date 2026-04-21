# Mesoscope HQ Camera Optics Module — OpenSCAD Sources

Custom OpenSCAD configurations for the Pi HQ Camera (IMX477) with extended tube
lens options (125mm and 150mm achromatic doublets).

## Files

| File | Purpose |
|------|---------|
| `optics_configurations_hq.scad` | Tube lens configs: 125mm and 150mm |
| `rms_optics_module_hq.scad` | Main module with dispatch for all 6 optics types |
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