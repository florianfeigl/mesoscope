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

**Recommended tube lens: 135 mm or 150 mm achromatic doublet** (12.7 mm diameter).

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
| **135 mm** | **0.489** | **20.0 mm** | **~100%** | **Optimal for IMX477** |
| 150 mm | 0.515 | 19.0 mm | ~100% | Slight overfill, still good |
| 200 mm | 0.586 | 16.7 mm | overfill | FN slightly below 17 mm minimum |

Calculation for each row: `M = f / (f − |p|)` where `|p| = 141.5 mm`.

**Buy:** ThorLabs AC127-135-A (12.7 mm, 135 mm) or AC127-150-A (12.7 mm, 150 mm).
AliExpress: search `12.7mm 135mm achromatic doublet` or `12.7mm 150mm achromatic lens`.

---

## Step 3 — Lens-to-sensor distance (q)

```
q = f_t × p / (p − f_t)

For f_t = 135 mm, p = −141.5 mm:
q = 135 × (−141.5) / (−141.5 − 135)
  = −19102.5 / −276.5
  = 69.1 mm

For f_t = 150 mm:
q = 150 × (−141.5) / (−141.5 − 150)
  = −21225 / −291.5
  = 72.8 mm
```

The standard module (50 mm tube lens, Pi Cam v2) has `q ≈ 37 mm`.
With a 135 mm tube lens: `q ≈ 69 mm` — the sensor must sit **~32 mm further** from
the tube lens than in the standard design.

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

---

## Step 5 — Total optics module tube length

```
Required tube length = q + C-mount offset

Standard (Pi Cam v2, 50 mm lens):   37 mm + ~1 mm  = ~38 mm
This project (IMX477, 135 mm lens): 69 mm + ~22 mm  = ~91 mm
This project (IMX477, 150 mm lens): 73 mm + ~22 mm  = ~95 mm
```

The printed optics module tube (from tube lens seat to camera face) needs to be
**~53–57 mm longer** than the standard OpenFlexure part.

---

## Step 6 — OpenFlexure source customisation

The optics module geometry is parametric. In the OpenFlexure microscope source
([GitLab](https://gitlab.com/openflexure/openflexure-microscope)), the relevant
parameters are in `openscad/microscope_parameters.scad` (OpenSCAD) or the
CadQuery equivalent:

| Parameter | Standard value | Required value (IMX477 + 135 mm lens) |
|---|---|---|
| `camera` | `"picamera_2"` | `"c_mount"` or custom |
| Tube lens focal length | 50 mm | 135 mm |
| `optics_module_cam_tube_h` | ~38 mm | ~91 mm |
| `camera_z` offset | 0 mm | +20–25 mm (C-mount body depth) |

The OpenFlexure v7 build system supports a `c_mount` camera variant — check
`cameras/` in the source for an existing C-mount adapter definition before
writing a custom one.

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
- [ ] Order tube lens: **ThorLabs AC127-135-A** or AC127-150-A (or AliExpress equivalent)
- [ ] Measure C-mount adapter depth on your HQ Camera assembly (target: confirm ~22 mm)
- [ ] Generate custom optics module STL with `optics_module_cam_tube_h ≈ 91–95 mm`
- [ ] Verify `camera_z` offset in printed part matches measured C-mount depth
- [ ] Print test piece before committing to full print

---

## References

- [OpenFlexure imaging optics explanation](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/info_pages/imaging_optics_explanation.html)
- [OpenFlexure optics module assembly](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/high_res_optics_module.html)
- [OpenFlexure customisation](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/customisation.html)
- [OpenFlexure microscope source (GitLab)](https://gitlab.com/openflexure/openflexure-microscope)
- ThorLabs achromatic doublets: AC127-135-A, AC127-150-A
- IMX477 datasheet: sensor size 7.857 × 5.893 mm, pixel pitch 1.55 µm, C-mount FFD 17.526 mm
