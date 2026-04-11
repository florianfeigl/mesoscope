# CELLAIR: CELL Analysis with Intelligent Recognition

## Slide 1: Title + Motivation

**CELLAIR: CELL Analysis with Intelligent Recognition**

- Portable, open-source microscopy system with real-time AI analysis
- **Research goal:** Study interaction between osteoblasts and epithelial cells in a custom bioreactor
- **Bioreactor setup:** Two compartments separated by a perforated membrane
  - Compartment A: Sponge matrix + **hFOB 1.19** osteoblasts (human fetal osteoblast cell line)
  - Compartment B: **hMEC 1** endothelial cells (human microvascular endothelial cell line)
  - Goal: Observe how osteoblasts influence epithelial cell behavior through the membrane
- **What to monitor:** Cell migration, morphological changes, response to osteoblast signaling, **calcium deposition (mineralization)**
- **Why live-cell imaging:** Processes occur over hours to days; fixed endpoints miss dynamic behavior
- **Biological significance:** Osteoblasts build calcium phosphate (hydroxyapatite) — key for bone formation and implant osseointegration. Understanding how epithelial cells respond to osteoblast activity via soluble factors through membranes provides insights for regenerative medicine and implant design.
- Solution: OpenFlexure-based motorised stage with custom optics for high-resolution imaging inside incubator (37°C)

---

## Slide 2: System Architecture

**Final product: Single-camera design**

```
┌─────────────────────────────────────────────────────────────────┐
│  Inside incubator (37°C)                                        │
│                                                                  │
│    ┌─────────────────────────────────────────┐                  │
│    │         Bioreactor (custom)              │                  │
│    │  ┌───────────────┐  ┌───────────────┐   │                  │
│    │  │  Osteoblasts │◄─►│  Epithelial   │   │                  │
│    │  │   (sponge)   │membrane│   cells    │   │                  │
│    │  └───────────────┘  └───────────────┘   │                  │
│    │        Compartment A    Compartment B    │                  │
│    └───────────────────┬─────────────────────┘                  │
│                        │                                         │
│                        ▼ (imaging from below)                  │
│    ┌───────────────────────────────────────────┐                 │
│    │  HQ Camera (IMX477) + ≤10x objective    │                 │
│    │     OpenFlexure motorised stage          │                 │
│    └───────────────────────────────────────────┘                 │
│                                                                  │
└──────────────────┼──────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────┐
│  Outside incubator                                              │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │ Raspberry Pi 5 (8 GB) + Hailo-8 NPU (27 TOPS)              ││
│  │ • OpenFlexure Server (stage control, camera)              ││
│  │ • AI inference: YOLOv8 segmentation, cell tracking         ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

> **Note:** The system uses a single-camera design with the HQ Camera (IMX477).

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
| Tube lens focal length | **50 mm** (encoded in STL) | **125-150 mm needed** | Must modify printed geometry |
| Lens-to-sensor distance (q) | ~37 mm | 66-73 mm | Tube 29-36 mm longer |
| Effective field number | 17.6 mm | 37.5 mm (too large) | Only ~25% of sensor used |

### The STL encodes optical parameters

Filename: `optics_picamera_2_rms_f50d13.stl`

- `f50` = 50 mm focal length (baked into tube geometry)
- `d13` = 13 mm diameter lens seat
- Internal lens seat position fixed for 50 mm lens at 37 mm from sensor
- Camera mounting face designed for Pi Camera v2 PCB thickness (~1 mm)

### Required modifications

1. **Tube lens focal length:** 50 mm → 125-150 mm achromatic doublet
2. **Tube length (q):** 37 mm → 66-73 mm (+29-36 mm)
3. **C-mount offset:** +20–25 mm (flange FFD + body depth)
4. **Total optics module length:** ~38 mm → ~88–95 mm

---

## Slide 5: Solution — What Parts Need to Change

### Parts that change

| Component | Standard OpenFlexure | Our Setup | Action |
|---|---|---|---|
| **Tube lens** | 50 mm achromat | 125-150 mm achromat (from taulab) | **Buy** |
| **Optics module STL** | `optics_picamera_2_rms_f50d13.stl` | Custom `optics_hq_camera_rms.stl` | **Compile from OpenSCAD** |
| **Objective** | 40x RMS (purchased) | ≤10x scraped from existing microscopes | **Source** (no purchase) |
| **Camera ribbon cable** | 200 mm (may suffice) | 200 mm | **Verify length** — tube is ~54 mm longer, likely OK |

### Parts that stay the same

| Component | Why |
|---|---|
| Illumination (condenser lens) | Lower NA (≤10x vs 40x) = less demanding, standard PMMA lens works |
| Stage mechanics (gears, motors) | No change |
| Sample clips, stand | No change |
| Raspberry Pi 5, HQ Camera mount | C-mount adapter is part of camera |

---

## Slide 5b: Solution — Custom Optics Module from OpenSCAD

> **Note:** This slide shows the original estimate. See Slide 5c for the confirmed workflow from the OpenFlexure team.

**Source:** https://gitlab.com/openflexure/openflexure-microscope (`hq_camera` branch)

### Parameters to modify

```openscad
// In rms_optics_module.scad
CAMERA = "picamera_hq";            // Pi HQ Camera (IMX477, C-mount)

// In optics_configurations.scad — function rms_f50d13_config:
tube_lens_f = 125;               // or 150, depending on purchased lens
tube_lens_ffd = <from datasheet>; // back focal distance (slightly < f)
```

### Build command

```bash
openscad -o optics_hq_camera_rms.stl openscad/rms_optics_module.scad
```

### Prerequisites verified
- [x] OpenSCAD installed
- [x] HQ Camera mount exists as `arducam_b0196` in `hq_camera` branch (confirmed by OpenFlexure team)
- [ ] Order 125 or 150 mm achromatic doublet (ThorLabs AC127-125-A or AC127-150-A)

### Risk: C-mount camera definition
~~Risk eliminated~~ — `arducam_b0196` mount confirmed present in `hq_camera` branch.

---

## Slide 5c: Update — OpenFlexure Team Confirmation (March 2026)

> Confirmed by William (OpenFlexure support) via email, March 2026.
> Previous slides assumed we'd need to write a custom camera mount — **we don't**.

### What changed

| Before (our assumption) | After (confirmed by OpenFlexure) |
|---|---|
| Use `main` branch, write custom C-mount module | Use **`hq_camera` branch** — mount already exists |
| Set 4 parameters manually (focal length, tube height, camera offset, camera type) | Set **2 parameters** — tube height computed automatically |
| Risk of ~2 hr custom CAD work | **Minimal changes** to existing config |

### Confirmed workflow

```bash
# 1. Clone and checkout the correct branch
git clone https://gitlab.com/openflexure/openflexure-microscope.git
git checkout hq_camera

# 2. Set camera type in rms_optics_module.scad
CAMERA = "arducam_b0196";    # Pi HQ Camera (IMX477, same C-mount)

# 3. In optics_configurations.scad, find rms_f50d13_config and change:
#    tube_lens_f = 125 or 150   (depending on purchased lens)
#    tube_lens_ffd = <from datasheet>  (back focal distance, slightly < f)

# 4. Build
openscad -o optics_hq_camera_rms.stl openscad/rms_optics_module.scad
```

### Key insight

The `arducam_b0196` camera type uses the same IMX477 sensor + C-mount as the
Pi HQ Camera. The mount geometry (C-mount FFD, sensor position) is already
defined — only the tube lens optics need adjusting.

### References

- [CAD pipeline](https://openflexure.discourse.group/t/alternative-file-options-other-than-stl-for-block-delta-stages/1438)
- [Arducam B0196 / HQ Camera mount](https://openflexure.discourse.group/t/arducam-b0196-on-high-resolution-v7-microscope/2393/3)
- [Source: `hq_camera` branch](https://gitlab.com/openflexure/openflexure-microscope/-/tree/hq_camera)

---

## Slide 5e: CAD Format — OpenSCAD vs Commercial CAD `[priority: lowest]`

| Aspect | OpenSCAD (current) | SOLIDWORKS / AutoCAD / FreeCAD |
|---|---|---|
| Version control | Git-native (text-based CSG) | Binary files, poor diffing |
| Open source | Yes | No (SW/AC) / Yes (FreeCAD) |
| Collaboration | GitLab merge requests, open review | Proprietary formats, license required |
| Conversion | One-way STL export only | Would require full rebuild from STL |
| Maintenance burden | None — upstream OpenFlexure uses OpenSCAD | Permanent fork, manual sync with upstream |

### Assessment `[priority: lowest]`

**A port to commercial CAD is not recommended.**

- OpenFlexure upstream uses OpenSCAD exclusively — confirmed by maintainers
  ([forum thread](https://openflexure.discourse.group/t/alternative-file-options-other-than-stl-for-block-delta-stages/1438))
- CSG (constructive solid geometry) cannot be losslessly converted to B-rep
  (boundary representation) used by SOLIDWORKS/FreeCAD
- Our modifications are minimal (2 parameters in config files) — no ongoing CAD
  development that would benefit from commercial tooling
- Porting would create a maintenance fork permanently disconnected from upstream updates
- OpenSCAD is code: fits naturally into our Git + Ansible workflow

> **If commercial CAD is required** for institutional reasons, the only viable
> path is importing the generated STL as a mesh body. This loses all parametric
> editability and is strictly worse than working in OpenSCAD directly.

---

## Slide 5d: Optical Equations — Calculating the New Tube

### Given parameters

| Symbol | Value | Meaning |
|---|---|---|
| `D_sensor` | 9.79 mm | IMX477 sensor diagonal |
| `FN_target` | 20 mm | Target field number (standard eyepiece range: 17–26 mm) |
| `L_tube` | 160 mm | Objective tube length (finite conjugate) |
| `d_parfocal` | 45 mm | Parfocal distance (DIN standard) |
| `p` | 8.5 − 150 = **−141.5 mm** | Distance from tube lens to objective's primary image plane |

### Step 1: Target magnification

The tube lens must demagnify the intermediate image to match the sensor to a standard eyepiece field of view:

$$M = \frac{D_{sensor}}{FN_{target}} = \frac{9.79}{20} = \mathbf{0.490}$$

### Step 2: Required tube lens focal length

From the thin lens equation, rearranged for the tube lens:

$$f_t = \frac{M}{M - 1} \times p$$

$$f_t = \frac{0.490}{0.490 - 1} \times (-141.5) = 0.961 \times 141.5 = \mathbf{136 \text{ mm}}$$

→ Calculated optimum: **136 mm**. Available options: **125 mm or 150 mm** achromatic doublet.

### Step 3: Actual magnification — both available options

| Tube lens | $M_{actual} = f_t / (f_t + |p|)$ | $FN_{eff} = D_{sensor} / M$ | In range? |
|---|---|---|---|
| 125 mm | 125 / 266.5 = **0.469** | 9.79 / 0.469 = **20.9 mm** | ✓ |
| 150 mm | 150 / 291.5 = **0.515** | 9.79 / 0.515 = **19.0 mm** | ✓ |

Both within standard eyepiece range (17–26 mm).

### Step 4: Lens-to-sensor distance (q)

$$q = \frac{f_t \times p}{p - f_t}$$

| Tube lens | q |
|---|---|
| 125 mm | 125 × (−141.5) / (−141.5 − 125) = **66.4 mm** |
| 150 mm | 150 × (−141.5) / (−141.5 − 150) = **72.8 mm** |

### Step 5: Total optics module length

| Component | 125 mm lens | 150 mm lens |
|---|---|---|
| Lens-to-sensor (q) | 66.4 mm | 72.8 mm |
| C-mount offset (flange FFD + body) | ~22 mm | ~22 mm |
| **Total tube length** | **~88 mm** | **~95 mm** |

Standard OpenFlexure: 37 mm → Ours: ~88–95 mm (+51–58 mm)

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
| Tube lens (125-150 mm achromat) | — | 15-80 EUR (from taulab) |
| Sangaboard v0.5 | — | ~30–40 EUR |
| 28BYJ-48 stepper motors | ~5 EUR | — |
| 3D printing (filament) | — | ~10 EUR |
| **Total** | **~205 EUR** | **~55–80 EUR** |

---

## Slide 8: What Was Found Along the Road

### IMX500 AI Camera — Not in final design

| Aspect | Details |
|---|---|
| **What it is** | Raspberry Pi AI Camera with on-sensor NPU (Sony IMX500) |
| **Why it was dropped** | M12 lens unsuitable for cell microscopy (~0.1-0.5mm resolution); adds complexity without benefit for current scope |
| **Status** | Hardware acquired but not in use |
| **Single-camera design** | HQ Camera (IMX477) with C-mount + RMS objective provides cell-level resolution (0.7µm at 20x) |

### What worked

- **Raspberry Pi 5 + AI HAT:** Seamless integration, PCIe detection, Hailo firmware loads automatically
- **OpenFlexure v3 migration:** Successfully ported from legacy Flask to FastAPI, compatible with Python 3.13
- **Camera integration:** HQ Camera (IMX477) streams via picamera2 with full OpenFlexure support
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
      = 0.961 × 141.5 = 136 mm → use 125 mm or 150 mm (available options)

Sensor-to-lens distance (q):
  q = f_t × p / (p - f_t)
    = 125 × (-141.5) / (-141.5 - 125) = 66.4 mm  (125 mm lens)
    = 150 × (-141.5) / (-141.5 - 150) = 72.8 mm  (150 mm lens)
```
