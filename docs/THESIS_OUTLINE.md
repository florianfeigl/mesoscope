# Master's Thesis — Draft Outline

**Working title:** Mesoscope — A Low-Cost, Edge-AI Automated Microscope for Serial Monitoring of Cell Cultures in Perfused Bioreactor Chips

**Alternative (shorter):** Automated Edge-AI Cell Imaging of Bioreactor Arrays with an Open-Source Mesoscope

> Naming: the former project acronym "CELLAIR" is retired. `README.md`, `CLAUDE.md`, `ansible/README.md` and `ansible/inventory/README.md` still carry it and need renaming (see roadmap M0). Cost data: `BOM_COSTS.md`. Exploded view: `hardware/assembly/`.

Language: English · Scope: system (hardware + infrastructure) **and** ML pipeline · Duration: 9–12 months
See `THESIS_ROADMAP.md` for the schedule and `THESIS_PARAMETER_GAPS.md` for the documentation audit.

---

## 1. Problem statement & research questions

Continuous, non-destructive observation of adherent cell cultures inside perfused bioreactor chips
(e.g. hFOB 1.19 osteoblasts, hMEC 1 endothelial cells under pressure/flow test series) currently
requires either manual microscopy (removes the chip from the incubator, operator-dependent,
low temporal resolution) or commercial live-cell imagers (expensive, closed, single-vessel).

This thesis builds and validates a **mesoscope**: an OpenFlexure-derived microscope on a
Raspberry Pi 5 with a Hailo-8 NPU, mounted horizontally on a linear rail so that one imaging head
scans a rack of bioreactor chips in series, and evaluates cell-level images on-device without
external compute infrastructure.

**RQ1 (System):** Can an open-source, sub-500 EUR microscope built from OpenFlexure, a Pi HQ camera
and 3D-printed parts deliver image quality (resolution, FOV, focus stability) sufficient for
automated cell analysis in a bioreactor chip through its observation window?

**RQ2 (Automation):** Can a single imaging head on a linear X-rail revisit N bioreactors
autonomously with positioning repeatability and autofocus reliability adequate for time-lapse
monitoring over days inside an incubator?

**RQ3 (Edge AI):** Can a cell-detection/segmentation model trained on data annotated in CVAT be
deployed on the Hailo-8 NPU with accuracy (mAP / IoU / count error) and throughput sufficient
for on-device, near-real-time analysis — and how does it compare to inference on the Pi CPU
and to manual counting?

**Hypotheses / success criteria (to be finalised):**
- H1: Measured lateral resolution ≤ 1.5 µm (USAF 1951; Rayleigh limit 1.1 µm at NA 0.30) and FOV ≥ 0.5 mm² with the ZEISS Plan-Neofluar 10×/0.30 + 125 mm tube lens.
- H2: Rail positioning repeatability ≤ ±10 µm; autofocus success rate ≥ 95 % across ≥ 3 chips over 72 h.
- H3: Cell detection mAP@0.5 ≥ 0.8 on held-out chips; Hailo-8 inference ≥ 10× faster than Pi CPU at equal accuracy (±2 % mAP).

## 2. Proposed structure

| # | Chapter | Content | Source material in repo |
|---|---------|---------|-------------------------|
| 1 | Introduction | Motivation, problem statement, RQ1–3, contributions, thesis structure | — (to write) |
| 2 | Background & Related Work | Live-cell imaging, open-hardware microscopy (OpenFlexure, UC2, Squid), edge AI on NPUs, cell detection/segmentation (YOLO, Cellpose, StarDist), microfluidic/perfused bioreactor chips | — (literature) |
| 3 | Requirements & System Concept | Use case (N chips in series in incubator), functional/non-functional requirements, architecture overview, design decisions (Pi 5 + Hailo, OFM v3, horizontal tilt, rail) | `README.md` architecture diagram, `docs/RAIL_MOUNT_CONCEPT.md` §1–3 |
| 4 | Optical Design | Sensor/objective/tube-lens calculation, magnification, sampling, resolution budget, C-mount module design, illumination | `hardware/optics/OPTICS_MODULE.md`, `hardware/optics/openscad/README.md`, `hardware/optics/CORRESPONDENCE.md` |
| 5 | Mechanical Design | Z-focus-only body, stand & electronics drawer, 90° tilt mount, V-slot rail + carriage, bioreactor rack, print parameters, tolerances | `hardware/body/…/README.md`, `hardware/stand/…/microscope_stand_readme.md`, `docs/RAIL_MOUNT_CONCEPT.md` §4–6, `hardware/PRINT_CHECKLIST.md` |
| 6 | Electronics & Motion Control | Pi 5 / AI HAT+ / RTC stack, focus stepper (28BYJ-48 + ULN2003), rail stepper (NEMA17 + TMC2209), power budget, GPIO stage driver | `docs/RAIL_MOUNT_CONCEPT.md` §7, `hardware/firmware/README.md` |
| 7 | Software & Infrastructure | Ansible provisioning, OpenFlexure v3 port to Pi 5 (pisp, pipewire, DKMS fixes), camera configuration, calibration (CSM), scan/time-lapse orchestration, CVAT server | `ansible/`, `docs/OPENFLEXURE_SUITE.md`, `docs/CSM_CALIBRATION_RPI5.md`, `docs/BIOREACTOR_POSITION.md`, `ansible/README.md` |
| 8 | Edge-AI Pipeline | Data acquisition protocol, CVAT label schema, dataset statistics, model selection, training, HEF compilation (Hailo Dataflow Compiler), deployment on the Pi | — (to build; `model/` planned) |
| 9 | Evaluation | Optical (resolution, FOV, flat-field), mechanical (repeatability, drift, tilt stiffness), automation (multi-chip time-lapse), ML (accuracy, latency, CPU vs NPU), cost & build time, comparison to reference microscope | partly: `docs/CSM_CALIBRATION_RPI5.md`, README benchmark |
| 10 | Discussion | Answers to RQ1–3, limitations, lessons learned (Pi 5 breakage, tilt risks), generalisation | — |
| 11 | Conclusion & Outlook | Contributions, future work (fluorescence, multi-rail, closed-loop control) | — |
| A | Appendices | BOM, print settings, wiring diagrams, Ansible variable reference, dataset card, model card, calibration logs | `README.md` BOM, `hardware/PRINT_CHECKLIST.md` |

## 3. Contributions (as they should appear in ch. 1)

1. Port of OpenFlexure Server v3 to Raspberry Pi 5 / Trixie with reproducible Ansible provisioning, including documented fixes for the Pi 5 ISP, camera stack and Hailo driver.
2. A C-mount HQ-camera optics module with 125/150 mm tube lens for the IMX477, with full optical derivation and printable CAD.
3. A tilted, rail-mounted imaging head with a Z-focus-only body and parametric bioreactor rack — a new form factor for serial monitoring of multiple chips.
4. An all-Python GPIO stage driver replacing the Sangaboard (to be confirmed — see open decision below).
5. A CVAT-annotated cell dataset from bioreactor-chip images and a Hailo-8-deployed detection model with a CPU-vs-NPU evaluation.
6. Quantitative validation of the complete system against stated requirements.

## 4. Open decisions that must be fixed before writing

| Decision | Current state | Needed by |
|----------|---------------|-----------|
| Motor architecture: Sangaboard hybrid vs. all-Python GPIO | Contradictory across `CLAUDE.md`, memory and `RAIL_MOUNT_CONCEPT.md` (2026-09-03 note) | Roadmap M2 |
| Objective: **ZEISS Plan-Neofluar 10×/0.30** — confirm tube-length marking (`160/-` finite vs. `∞/0.17` ICS) and thread (RMS vs. M27); the optics module assumes 160 mm finite + RMS | Model known; marking/thread unverified; docs still say "scraped ≤10×" | M1 |
| Biological readout: what is measured (confluence, cell count, morphology, migration, calcification)? | Not defined | M1 (drives label schema + evaluation) |
| Bioreactor pitch / rack geometry | 80 mm assumed, unconfirmed; `bioreactor_rack.scad` still on old concept | M3 |
| ML task: detection vs. segmentation; model family (YOLOv8-seg, Cellpose-lite, StarDist) | Only a foreign YOLOv8s-Pose benchmark exists | M4 |
| Reference method for ground truth (manual count, commercial microscope, trypan blue?) | Not defined | M4 |
| Supervising faculty / formal requirements (page count, template, colloquium) | Open | now |

## 5. Documentation gaps (summary — full list in `THESIS_PARAMETER_GAPS.md`)

- **Not written anywhere:** research question, biological experiment design, imaging schedule, measured FOV/resolution, dataset, labels, model metrics, power budget, wiring diagram, exact software versions/commits.
- **Inconsistent between files:** IMX477 sensor size (7.857×5.893 vs. 6.287×4.712 mm), camera exposure values (20 ms/1.5/[1.4,2.3] vs. 492 µs/1.0/[0.9,2.9]), tube-lens magnification (0.49 vs. 0.515), motor architecture.
- **Only calculated, not measured:** resolution, FOV, sensor fill, working distance.
