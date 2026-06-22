# Optics Module — HQ Camera (IMX477) Adaptation

This document covers the optical calculations and design decisions for using the
**Raspberry Pi HQ Camera (IMX477)** with a **scraped ≤10x finite conjugate objective**
in a custom OpenFlexure optics module, deviating from the upstream default
(Pi Camera v2 + 40x objective + 50 mm tube lens).

Reference: [OpenFlexure v7 optics module assembly](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/high_res_optics_module.html)
and [imaging optics explanation](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/info_pages/imaging_optics_explanation.html).

---

## Sensor parameters

| Parameter | Pi Camera v2 (upstream default) | HQ Camera IMX477 (this project) |
|---|---|---|
| Sensor | IMX219 | IMX477 |
| Resolution | 8 MP | 12.3 MP |
| Sensor size | 3.68 × 2.76 mm | 7.857 × 5.893 mm |
| Diagonal | 4.6 mm | **9.79 mm** |
| Mount | Fixed lens (removed for OFM) | **C-mount** |
| C-mount FFD | n/a | 17.526 mm |

The IMX477 sensor diagonal (9.79 mm) is **2.1× larger** than the IMX219 (4.6 mm).
This drives all downstream optical decisions.

---

## Objective: scraped finite conjugate ≤10x

Objectives salvaged from existing microscopes are almost certainly **160 mm finite
conjugate** (pre-1990s and budget instruments). This is the same class as the
OpenFlexure default — standard `p` applies directly.

**Before building, verify the objective:**

| Marking | Type | Compatible? |
|---|---|---|
| `160 / 0.17` or just `160` | 160 mm finite conjugate | Yes, directly |
| `∞ / 0.17` or `∞ / –` | Infinity corrected | Needs different `p` — see below |
| No marking | Likely 160 mm finite | Measure WD and confirm |

For a **160 mm finite conjugate** objective:
- Parfocal distance: 45 mm (standard DIN) or 35 mm (older)
- Back focal length ≈ tube length − 10 mm = **150 mm**
- `p` (distance from tube lens to primary image plane of objective) = `8.5 − 150 = −141.5 mm`
  (the 8.5 mm is the tube-lens-to-shoulder distance in the OpenFlexure printed module)

---

## Step 1 — Target magnification

The tube lens demagnifies the intermediate image onto the sensor. The target is to
match the sensor to a standard eyepiece field number (FN). Standard range: 14–26 mm;
target: **FN = 20 mm** (comfortable mid-range).

```
M_desired = sensor_diagonal / FN = 9.79 mm / 20 mm = 0.490
```

For reference, the upstream Pi Cam v2 calculation:
```
M = 4.6 / 17 = 0.27   (FN = 17 mm, standard)
```

---

## Step 2 — Required tube lens focal length

From the OpenFlexure thin-lens formula:

```
f_t = M / (M − 1) × p

With M = 0.490, p = −141.5 mm:

f_t = 0.490 / (0.490 − 1) × (−141.5)
    = 0.490 / (−0.510) × (−141.5)
    = 0.961 × 141.5
    = 135.9 mm
```

**Calculated optimum: ~136 mm.**
Available from distributor: **125 mm or 150 mm achromatic doublet** (12.7 mm diameter).
Both are within the acceptable range (see table below).

The standard 50 mm tube lens is a poor match for the IMX477:
```
M = 50 / (50 − (−141.5)) = 50 / 191.5 = 0.261
Effective FN = 9.79 / 0.261 = 37.5 mm   ← far above 26 mm maximum
```
With the 50 mm tube lens the intermediate image is larger than the sensor can capture,
meaning only the central ~25% of the image area is used.

### Tube lens options

| Focal length | M | Effective FN | Sensor fill | Note |
|---|---|---|---|---|
| 50 mm | 0.261 | 37.5 mm | ~25% | Standard OFM — poor fit for IMX477 |
| 100 mm | 0.414 | 23.6 mm | ~88% | Good, FN within range |
| **125 mm** | **0.469** | **20.9 mm** | **~85%** | **Available — good fit** |
| 136 mm (calc.) | 0.490 | 20.0 mm | ~100% | Calculated optimum |
| **150 mm** | **0.515** | **19.0 mm** | **~95%** | **Available — good fit** |
| 200 mm | 0.586 | 16.7 mm | overfill | FN slightly below 17 mm minimum |

Calculation for each row: `M = f / (f + |p|)` where `|p| = 141.5 mm`.

**Buy:** 125 mm or 150 mm achromatic doublet, 12.7 mm diameter.
Available from taulab or optics distributors. Exact choice depends on scraped objective
magnification — 150 mm preferred for ≤10x, 125 mm for lower magnification (≤4x).

---

## Step 3 — Lens-to-sensor distance (q)

```
q = f_t × p / (p − f_t)

For f_t = 125 mm, p = −141.5 mm:
q = 125 × (−141.5) / (−141.5 − 125)
  = −17687.5 / −266.5
  = 66.4 mm

For f_t = 150 mm:
q = 150 × (−141.5) / (−141.5 − 150)
  = −21225 / −291.5
  = 72.8 mm
```

The standard module (50 mm tube lens, Pi Cam v2) has `q ≈ 37 mm`.

| Tube lens | q (lens-to-sensor) | Delta vs standard |
|---|---|---|
| 50 mm (standard) | 37 mm | — |
| 125 mm | 66.4 mm | +29 mm |
| 150 mm | 72.8 mm | +36 mm |

---

## Step 4 — C-mount offset

The IMX477 is a C-mount camera. The **C-mount flange focal distance (FFD) is 17.526 mm**
— the sensor sits 17.526 mm behind the mounting flange face.

In the standard OpenFlexure module the Pi Camera v2 PCB seats directly against a
printed face, sensor approximately **1–2 mm** behind the board.

The C-mount adapter adds approximately **5–7 mm** of mechanical depth, and the HQ
Camera body behind the flange adds further distance. The net effect is that the
**IMX477 sensor sits ~20–25 mm further back** from an equivalent mounting face than
the IMX219 sensor in the Pi Cam v2.

**Effective extra offset compared to standard module: +20–25 mm.**

### Camera-side interface: C-mount seat (not bare PCB)

The upstream `picamera_hq.scad` mounts the **bare PCB** of the HQ Camera (with the
C-mount lens removed) on four M2 posts and uses a small printed cover for the
underside. We do not do that — we use the HQ Camera intact, with its full
C-mount housing.

`hardware/optics/openscad/picamera_hq_cmount.scad` is a drop-in replacement for
the upstream camera mount that:

- sets `mount_height = 17.526` (C-mount FFD) and `sensor_height = 0`, so the
  sensor lands at the correct optical distance automatically,
- replaces the printed PCB mount with a **32.6 mm bore × 4 mm deep flange seat**
  for the C-mount housing (32 mm OD + 0.3 mm clearance),
- opens a **26 mm clear bore** above the seat for the optical path,
- removes the screw posts, counterbore, and `picamera_hq_cover` (no longer
  needed — the C-mount housing is its own enclosure).

The build script (`build_optics.sh`) copies this file over the upstream
`picamera_hq.scad` before rendering, so the change is local to our repo.

---

## Step 5 — Total optics module tube length

```
Required tube length = q + C-mount offset

Standard (Pi Cam v2, 50 mm lens):      37 mm + ~1 mm  = ~38 mm
This project (IMX477, 125-150 mm lens): 66-73 mm + ~22 mm = ~88-95 mm
```

The printed optics module tube (from tube lens seat to camera face) needs to be
**~53–57 mm longer** than the standard OpenFlexure part.

---

## Step 6 — OpenFlexure source customisation

> **Confirmed by OpenFlexure team (William, March 2026):**
> The Pi HQ Camera mount exists in the `hq_camera` branch.
> Set `CAMERA = "picamera_hq"` in OpenSCAD (not `"arducam_b0196"`).
> Only the tube lens parameters need changing.

### Repository and branch

```bash
cd /path/to/mesoscope/sources
git clone --branch hq_camera --single-branch \
  https://gitlab.com/openflexure/openflexure-microscope.git
cd openflexure-microscope
git lfs install && git lfs pull
```

**Do not use the `main` branch** — the HQ Camera mount is only on `hq_camera`.

### Custom configurations (no upstream editing required)

Custom OpenSCAD configs for the mesoscope are in `hardware/optics/openscad/`:

| File | Purpose |
|------|---------|
| `optics_configurations_hq.scad` | 125mm and 150mm tube lens configs |
| `rms_optics_module_hq.scad` | Module dispatch with all 6 optics types |
| `build_optics.sh` | Build both STLs with one command |
| `README.md` | Parameter reference |

The build script (`build_optics.sh`) copies these into the upstream repo automatically before building.

### Available configurations

| OPTICS name | Tube lens | f (mm) | ffd (mm) | Conjugate | Camera |
|-------------|-----------|--------|----------|-----------|--------|
| `rms_f125d13` | 125mm | 125 | 122.6 | Finite (160mm) | picamera_hq |
| `rms_f150d13` | 150mm | 150 | 146.9 | Finite (160mm) | picamera_hq |
| `rms_infinity_f125d13` | 125mm | 125 | 122.6 | Infinity | picamera_hq |
| `rms_infinity_f150d13` | 150mm | 150 | 146.9 | Infinity | picamera_hq |

All default to `CAMERA = "picamera_hq"`. The `ffd` values should be verified
against your lens datasheet.

### Build

```bash
cd /path/to/mesoscope/hardware/optics/openscad
./build_optics.sh          # Both configs
./build_optics.sh 125      # 125mm only
./build_optics.sh 150      # 150mm only
```

### References from OpenFlexure team

- CAD pipeline explanation: [Forum thread](https://openflexure.discourse.group/t/alternative-file-options-other-than-stl-for-block-delta-stages/1438)
- HQ Camera / Arducam B0196 mount: [Forum thread](https://openflexure.discourse.group/t/arducam-b0196-on-high-resolution-v7-microscope/2393/3)
- Source branch: [`hq_camera`](https://gitlab.com/openflexure/openflexure-microscope/-/tree/hq_camera)

---

## Step 7 — Condenser lens (illumination side)

The condenser lens (PMMA, 13 mm / 5 mm focal length from the BOM) sits in the
illumination arm. For a ≤10x objective the numerical aperture is lower than the
40x default (NA ≤ 0.25 vs. 0.65), so the condenser requirements are more relaxed
— the standard PMMA lens works fine. No condenser adjustment needed.

---

## Resolution estimate for ≤10x objective

Rayleigh criterion: `r = 0.61 × λ / NA`

| Objective | NA (typical) | Resolution (λ = 550 nm) | Pixel size on sensor (at M_obj × M_tube) |
|---|---|---|---|
| 4x Plan Achromat | 0.10 | 3.4 µm | 1.55 µm × 4 × 0.49 = 3.0 µm |
| 10x Plan Achromat | 0.25 | 1.3 µm | 1.55 µm × 10 × 0.49 = 7.6 µm |

IMX477 pixel size: **1.55 µm**. At 10x objective + M_tube = 0.49, one pixel
corresponds to `1.55 / (10 × 0.49) = 0.32 µm` on the sample — well below the
diffraction limit at NA 0.25, so the sensor is not the limiting factor. Good.

---

## Checklist before printing

- [ ] Confirm objective type: **finite conjugate 160 mm** (check markings)
- [ ] Confirm objective parfocal distance: **45 mm** (DIN standard) or 35 mm (older)
- [x] Order tube lens: **125mm or 150mm achromatic doublet** (12.7mm dia) — **erhalten 2026-06-20**
- [x] Look up `tube_lens_ffd` (back focal distance) from datasheet — **confirmed by taulab/Filip 2026-06-22**: 125mm → 124.1mm, 150mm → 148.8mm
- [x] Clone OpenFlexure repo (`hq_camera` branch) — liegt in `resources/openflexure-microscope/`
- [x] Run `build_optics.sh` — STLs generiert 2026-06-20 (150mm: 2.0M, 125mm: 1.9M)
- [x] STL in PrusaSlicer geprüft — C-Mount-Sitz ⌀32.6mm vorhanden, Unterseite offen
- [ ] Test-Fit HQ-Kamera in gedrucktes Optics-Modul
- [ ] Print test piece before committing to full print

---

## References

- [OpenFlexure imaging optics explanation](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/info_pages/imaging_optics_explanation.html)
- [OpenFlexure optics module assembly](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/high_res_optics_module.html)
- [OpenFlexure customisation](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/customisation.html)
- [OpenFlexure microscope source (GitLab)](https://gitlab.com/openflexure/openflexure-microscope)
- Achromatic doublets, 12.7mm dia: 125mm focal length and 150mm focal length
- IMX477 datasheet: sensor size 7.857 × 5.893 mm, pixel pitch 1.55 µm, C-mount FFD 17.526 mm
