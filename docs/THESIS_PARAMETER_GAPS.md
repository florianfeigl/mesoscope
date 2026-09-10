# Thesis Parameter Audit — documented vs. missing

Audit of the repository documentation (state: 2026-09-08) against what a master's thesis must report.
"Documented" = value + source file exists. "Missing" = not written down, only implicit, or contradictory.

## 1. Optics

| Parameter | Status | Value / note | Source |
|-----------|--------|--------------|--------|
| Sensor active area | documented, **inconsistent** | 6.287 × 4.712 mm (corrected) vs. 7.857 × 5.893 mm (README, OPENFLEXURE_SUITE.md) | `hardware/optics/OPTICS_MODULE.md` |
| Pixel pitch | documented | 1.55 µm | OPTICS_MODULE.md |
| Tube lens | documented | 125 / 150 mm achromat, Ø12.7 mm, BFD 124.1 / 148.8 mm | `hardware/optics/openscad/README.md` |
| Tube magnification | documented, **inconsistent** | 0.469 / 0.515; calculation elsewhere uses 0.49 | OPTICS_MODULE.md |
| C-mount flange distance | documented | 17.526 mm | OPTICS_MODULE.md |
| Objective | known, **not yet in repo docs** | ZEISS Plan-Neofluar 10×/0.30 (stated 2026-09-08). Confirm marking `160/-` vs `∞/0.17` and thread RMS vs M27; parfocal 45 mm. README/OPTICS_MODULE.md still say "scraped ≤10×, NA 0.25" | — |
| Resolution | calculated only, **stale NA** | docs: Rayleigh 1.3 µm at NA 0.25 → with NA 0.30: 1.12 µm (λ 550 nm); sampling 0.32 µm/px unchanged | OPTICS_MODULE.md |
| Field of view | **missing** (TODO) | "measure FOV at chip window" | RAIL_MOUNT_CONCEPT.md |
| Working distance | measured from STL | 3.35 mm | RAIL_MOUNT_CONCEPT.md |
| Illumination | partial | PMMA condenser 13 mm / f 5 mm; LED type, wavelength, power **missing** | — |
| Flat-field / lens shading | **missing** | roadmap item only | README |

## 2. Camera

| Parameter | Status | Value / note | Source |
|-----------|--------|--------------|--------|
| Modes | documented | 4056×3040 @10 fps, 2028×1520 @30 fps | README |
| Exposure / gain / colour gains | documented, **stale copies** | 492 µs / 1.0 / [0.9, 2.9] (tested); README + OPENFLEXURE_SUITE.md still list 20 ms / 1.5 / [1.4, 2.3] | `docs/BIOREACTOR_POSITION.md` |
| AE / AWB | documented | disabled | BIOREACTOR_POSITION.md |
| CSM matrix, fit error, backlash | documented | [[−19.80, 0.04], [−0.06, 19.26]], 1.6/1.7 %, 158/84 steps, ≈0.025 px/step | `docs/CSM_CALIBRATION_RPI5.md` |
| Image orientation | documented | vertical flip (commit f3d4bff) | git |
| Snapshot format (JPEG quality, bit depth, RAW) | **missing** | — | — |
| Noise / SNR characterisation | **missing** | — | — |

## 3. Mechanics

| Parameter | Status | Value / note | Source |
|-----------|--------|--------------|--------|
| Print settings | documented | PLA black, 0.15/0.2 mm layer, 3 walls, 20–30 % infill | `hardware/PRINT_CHECKLIST.md` |
| C-mount seat | documented | Ø32.6 mm, 0.3 mm clearance | optics README |
| Drawer stack heights | documented | 5.5 / 18.4 / 34.2 mm | `microscope_stand_readme.md` |
| Bioreactor chip | documented | 70 × 40 × 16 mm, window 18 × 8 mm, 4 ports Ø4.5 | RAIL_MOUNT_CONCEPT.md §6 |
| Rail | documented | 2040 V-slot, MGN12, NEMA17 Tr8×2 (2 mm/rev, 0.01 mm/µstep) | RAIL_MOUNT_CONCEPT.md |
| Working gap | documented | 10 mm | RAIL_MOUNT_CONCEPT.md |
| Reactor pitch | **assumed** | 80 mm, unconfirmed; `bioreactor_rack.scad` still PITCH=148 | rails/openscad |
| Focus resolution (µm/step, 28BYJ-48 + flexure) | **missing** | only px/step indirectly | — |
| Z travel | **missing** | — | — |
| Tilted mass / centre of gravity / stiffness / drift | **missing** | named as risk, not measured | RAIL_MOUNT_CONCEPT.md §5 |
| Print tolerances (measured) | **missing** | — | — |

## 4. Electronics

| Parameter | Status | Value / note | Source |
|-----------|--------|--------------|--------|
| Compute | documented | Pi 5 8 GB, AI HAT+ Hailo-8 26 TOPS, FW 4.23.0, DS3231, 27 W PSU | README BOM |
| TMC2209 wiring, Vref, decoupling | documented | VIO 3.3 V, 100 µF, Vref ≈ 0.7 × I_RMS, 12–24 V | RAIL_MOUNT_CONCEPT.md §7.1 |
| GPIO budget | documented | 7–9 pins | RAIL_MOUNT_CONCEPT.md |
| Resource profile | documented | CPU load 0.71, 762 MB RAM, 48 °C | README |
| Power budget (5 V rail with Hailo + ULN2003) | **missing** | only a concern | — |
| Schematic / pinout table | **missing** | — | — |
| Motor architecture | **contradictory** | "Sangaboard removed" (CLAUDE.md, memory) vs. hybrid note 2026-09-03 | RAIL_MOUNT_CONCEPT.md |

## 5. Software / infrastructure

| Parameter | Status | Value / note | Source |
|-----------|--------|--------------|--------|
| OS / Python | documented | Pi OS Trixie, Python 3.13 | README |
| OpenFlexure | documented | v3 branch, 3.0.0-alpha4 | README, ansible role |
| Pi 5 fixes | documented | pisp, pipewire, DKMS ordering, SupplementaryGroups | ansible roles, README |
| CVAT deployment | documented | Docker + Caddy, cvat.feigl.dev | `ansible/README.md` |
| NPU benchmark | documented (foreign model) | YOLOv8s-Pose 91.5 inf/s, 10.9 ms | README |
| Exact versions / commit hashes (OFM, picamera2, libcamera, HailoRT, DFC) | **missing** | — | — |
| Time-lapse / scan orchestration script | **missing** | `capture_timelapse.py` referenced, does not exist | OPENFLEXURE_TESTING.md |
| ML: model, dataset, labels, metrics, `model/` dir | **missing entirely** | — | — |
| CVAT label schema / annotation guideline | **missing** | — | — |

## 6. Biology / application

| Parameter | Status | Value / note | Source |
|-----------|--------|--------------|--------|
| Cell lines | mentioned only | hFOB 1.19, hMEC 1 | README diagram |
| Experiment keywords | mentioned only | calcification, pressure/flow series, PFA-fixed, 37 °C incubator | README Phase 6 |
| Bioreactor type / manufacturer, medium, flow rates, seeding density, culture duration | **missing** | — | — |
| Imaging interval, number of chips, positions per chip | **missing** | — | — |
| Measured quantity (confluence, count, morphology, migration) | **missing** | — | — |
| Controls, replicates, experimental design | **missing** | — | — |
| Provenance / ethics of cell lines | **missing** | — | — |

## 7. Evaluation

| Parameter | Status | Value / note | Source |
|-----------|--------|--------------|--------|
| CSM ground-truth check | documented | +500/1000/2000 steps → 12.7/24.6/48.7 px | CSM_CALIBRATION_RPI5.md |
| Example images | documented | 4 images, 2026-08-04 … 08-17 | `resources/`, `docs/presentation.tex` |
| Resolution / FOV measurement (USAF, stage micrometer) | **missing** | — | — |
| Focus drift / repeatability (tilted) | **missing** | — | — |
| Rail positioning repeatability | **missing** | — | — |
| Image-quality metrics, flat-field residual | **missing** | — | — |
| Model metrics (mAP, IoU, count error), CPU vs. NPU | **missing** | — | — |
| Comparison with reference microscope | **missing** | — | — |
| Cost / build-time balance | partial | BOM prices only | README |

## 8. Framing

- **Research question / problem statement:** not stated anywhere. README has title and a diagram note ("without external compute infrastructure"); `presentation.tex` is an image gallery.
- **Done:** OFM v3 Pi 5 port, HQ camera + exposure, Hailo inference (foreign model), optics calculation + STLs, stand/drawer, CSM calibration, rail concept + massing CAD, Z-only body (SCAD).
- **Open:** print + assemble optics module, body/drawer test prints, rail hardware, GPIO stage class, rack update, FOV measurement, flat-field, incubator setup, entire ML pipeline, all biological experiments.

## Immediate housekeeping (before any thesis writing)

1. Fix sensor-size, camera-value and tube-magnification inconsistencies (README, OPENFLEXURE_SUITE.md, OPTICS_MODULE.md).
2. Record the motor-architecture decision in one place and align CLAUDE.md / RAIL_MOUNT_CONCEPT.md.
3. Add a `docs/VERSIONS.md` with pinned commits/versions (OFM, picamera2, libcamera, HailoRT, Hailo DFC, kernel).
4. Update OPTICS_MODULE.md and README BOM to the ZEISS Plan-Neofluar 10×/0.30 (NA 0.30, resolution 1.12 µm; verify tube length + thread).
5. Remove or implement the referenced `capture_timelapse.py`.
6. Retire the "CELLAIR" name in README.md, CLAUDE.md, ansible/README.md, ansible/inventory/README.md.
