# CELLAIR: CELL Analysis with Intelligent Recognition

## Slide 1: Title + Motivation

**CELLAIR: CELL Analysis with Intelligent Recognition**

- Portable, open-source microscopy system with real-time AI analysis
- Target application: live-cell imaging in bioreactor environment (37°C incubator)
- Key constraint: conventional microscopes cannot monitor samples inside incubator continuously
- Solution: OpenFlexure-based motorised stage with custom optics for high-resolution imaging

---

## Slide 2: System Architecture

**Final product: Single-camera design**

```
┌─────────────────────────────────────────────────────────────────┐
│  Inside incubator (37°C)                                        │
│  ┌───────────────────────────────────┐                          │
│  │ HQ Camera (IMX477) + ≤10x obj     │                          │
│  │ (OpenFlexure motorised stage)     │                          │
│  └───────────────┬───────────────────┘                          │
│                  │                                               │
└──────────────────┼───────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│  Outside incubator                                              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Raspberry Pi 5 (8 GB) + Hailo-8 NPU (27 TOPS)              ││
│  │ • OpenFlexure Server (stage control, camera)               ││
│  │ • AI inference: YOLOv8 segmentation, pose estimation       ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

> **Note:** IMX500 was tested during development but dropped from final design — see Slide 8.

---

## Slide 3: Hardware Status

| Subsystem | Status | Notes |
|---|---|---|
| Computing (RPi 5, AI HAT, RTC, GPIO header) | ✅ Acquired | OpenFlexure server running |
| HQ Camera (IMX477, C-mount) | ✅ Acquired | Currently mounted on conventional microscope for testing |

| Motor controller | ⏳ Pending | Sangaboard v0.5 preferred |
| Objective | ⏳ Sourced | Scraped from existing microscopes; ≤10x finite conjugate |
| Optics module | ⚠️ **Custom development needed** | Standard STL incompatible with HQ Camera + longer tube lens |
| 3D printed parts | ⏳ Pending | OpenFlexure v7 STLs + custom optics module |

---

## Slide 4: The Optics Challenge — Why Standard STL Won't Work

### Problem: Sensor size mismatch

| Parameter | Standard OpenFlexure | Our Setup | Impact |
|---|---|---|---|
| Camera | Pi Camera v2 (IMX219) | HQ Camera (IMX477, C-mount) | C-mount adds ~22 mm to sensor position |
| Sensor diagonal | 4.6 mm | **9.79 mm** (2.1× larger) | Standard tube lens underfills sensor |
| Tube lens focal length | **50 mm** (encoded in STL) | **~135 mm needed** | Must modify printed geometry |
| Lens-to-sensor distance (q) | ~37 mm | ~69 mm | Tube ~32 mm longer |
| Effective field number | 17.6 mm | 37.5 mm (too large) | Only ~25% of sensor used |

### The STL encodes optical parameters

Filename: `optics_picamera_2_rms_f50d13.stl`

- `f50` = 50 mm focal length (baked into tube geometry)
- `d13` = 13 mm diameter lens seat
- Internal lens seat position fixed for 50 mm lens at 37 mm from sensor
- Camera mounting face designed for Pi Camera v2 PCB thickness (~1 mm)

### Required modifications

1. **Tube lens focal length:** 50 mm → 135 mm achromatic doublet
2. **Tube length (q):** 37 mm → 69 mm (+32 mm)
3. **C-mount offset:** +20–25 mm (flange FFD + body depth)
4. **Total optics module length:** ~38 mm → ~91–95 mm

---

## Slide 5: Solution — Custom Optics Module from OpenSCAD

**Source:** https://gitlab.com/openflexure/openflexure-microscope

### Parameters to modify

```openscad
// In microscope_parameters.scad
TUBE_LENS_FOCAL_LENGTH = 135;    // Standard: 50 mm
CAMERA = "c_mount";              // Standard: "picamera_2"  
OPTICS_MODULE_CAM_TUBE_H = 91;   // Standard: ~38 mm
CAMERA_Z_OFFSET = 22;            // Standard: 0 mm (C-mount depth)
```

### Build command (example)

```bash
openscad \
  -D 'TUBE_LENS_FOCAL_LENGTH=135' \
  -D 'CAMERA="c_mount"' \
  -D 'OPTICS_MODULE_CAM_TUBE_H=91' \
  -o optics_hq_camera_rms_f135d13.stl \
  openscad/rms_optics_module.scad
```

### Prerequisites verified
- [x] OpenSCAD installed
- [ ] Verify C-mount camera definition exists in `cameras/` directory
- [ ] Order 135 mm achromatic doublet (ThorLabs AC127-135-A or AliExpress ~15 EUR)

### Risk: C-mount camera definition
If `c_mount` camera not defined in v7, need to write custom camera module (~1–2 hr additional work).

---

## Slide 6: Roadmap

| Phase | Timeline | Deliverable | Status |
|---|---|---|---|
| 1. Base setup | ✅ Done | RPi 5 + AI HAT + OpenFlexure server | Complete |
| 2. Optics module | **TBD** | Custom STL compiled, test print | In progress |
| 3. Stage assembly | TBD | Sangaboard + motors, stage control via web UI | Pending |
| 4. Dataset + training | TBD | >500 annotated images, YOLOv8 → Hailo HEF | Pending |
| 5. Validation | TBD | Live demo, biological validation | Pending |

**Critical path:** Optics module customisation (this week)

**Timeline unknowns:**
- OpenSCAD parameter modification: ~2–4 hr (first iteration)
- If C-mount definition missing: +1–2 hr to write
- Test print + iteration: depends on printer availability

---

## Slide 7: Budget

| Category | Spent | Pending |
|---|---|---|
| Computing + AI (RPi 5, AI HAT, RTC, GPIO header) | ~165 EUR | — |
| HQ Camera (IMX477) | ~35 EUR | — |
| Tube lens (135 mm achromat) | — | 15–30 EUR (AliExpress) or ~80 EUR (ThorLabs) |
| Sangaboard v0.5 | — | ~30–40 EUR |
| 28BYJ-48 stepper motors | ~5 EUR | — |
| 3D printing (filament) | — | ~10 EUR |
| **Total** | **~205 EUR** | **~55–80 EUR** |

---

## Slide 8: What Was Found Along the Road

### IMX500 AI Camera — Development dead end

| Aspect | Details |
|---|---|
| **What it is** | Raspberry Pi AI Camera with on-sensor NPU (Sony IMX500) |
| **What was tried** | Incubator watchdog camera for macro monitoring (chip position, media quality, anomaly detection) |
| **Why it was dropped** | No clear use case for current experiment scope; adds complexity without benefit |
| **Status** | Hardware acquired, software-compatible (tested), but not in final product design |
| **Potential future use** | Could be repurposed for autonomous cell culture monitoring (contamination, confluence) — separate project |

### What worked

- **Raspberry Pi 5 + AI HAT:** Seamless integration, PCIe detection, Hailo firmware loads automatically
- **OpenFlexure v3 migration:** Successfully ported from legacy Flask to FastAPI, compatible with Python 3.13
- **Picamera2 integration:** HQ Camera and IMX500 both stream via standard libcamera stack
- **Ansible automation:** Full deployment from scratch in <10 minutes

---

## Slide 9: Glossary

| Term | Definition |
|---|---|
| **RMS objective** | Standard microscope objective thread (0.8"-32 UNS, 36.5 TPI) — common on education/lab microscopes |
| **Finite conjugate** | Objective designed for fixed tube length (traditionally 160 mm) — forms real image at fixed distance |
| **Infinity conjugate** | Objective that outputs collimated light — needs additional "tube lens" to form image |
| **Parfocal distance** | Distance from objective shoulder to in-focus specimen — determines how much stage travel needed when changing objectives |
| **Tube lens** | Secondary lens between objective and camera sensor — demagnifies intermediate image to fit sensor |
| **Back focal length (BFL)** | Distance from rear of objective to its focal point — determines where tube lens must sit |
| **C-mount** | Standard industrial camera mount with 17.526 mm flange focal distance |
| **Flange focal distance (FFD)** | Distance from mount face to sensor plane — critical for correct optics alignment |
| **NA (Numerical Aperture)** | Determines resolution and light-gathering ability — NA = n × sin(θ) |
| **Effective field number (EFN)** | Equivalent eyepiece field of view — relates sensor size to microscope eyepiece standard |
| **Hailo HEF** | Hailo Executable Format — compiled neural network model for NPU inference |

---

## Backup: Optical Calculation Summary (see Slide 5)

For reference (detailed in `hardware/optics/OPTICS_MODULE.md`):

```
Given:
  Sensor diagonal (IMX477): 9.79 mm
  Target field number: 20 mm (mid-range, standard is 17–26 mm)
  Objective tube length: 160 mm (finite conjugate)
  Parfocal distance: 45 mm (DIN standard)
  p = 8.5 mm - 150 mm = -141.5 mm (tube lens to objective image plane)

Target magnification:
  M = 9.79 / 20 = 0.490

Required tube lens focal length:
  f_t = M / (M - 1) × p
      = 0.490 / (0.490 - 1) × (-141.5)
      = 0.961 × 141.5 = 136 mm → use 135 mm

Sensor-to-lens distance (q):
  q = f_t × p / (p - f_t)
    = 135 × (-141.5) / (-141.5 - 135)
    = 69.1 mm
```
