# CELLAIR: CELL Analysis with Intelligent Recognition

## Slide 1: What We Observe

**Calcium production through cell-cell interaction**

- **hFOB 1.19** (human fetal osteoblasts) and **hMEC 1** (human microvascular endothelial cells)
- Osteoblasts produce **hydroxyapatite** (Ca₁₀(PO₄)₆(OH)₂) — the mineral component of bone
- Key question: How do epithelial cells influence and respond to osteoblast mineralization?
- Understanding this interaction is relevant for bone tissue engineering, implant osseointegration, and regenerative medicine

---

## Slide 2: Technical Approach — Simulating the Natural Environment

**Custom bioreactor (chip) design:**

```
┌──────────────────────────────────────────────────────────────┐
│                     Bioreactor Chip                            │
│                                                                │
│   Compartment A              │         Compartment B           │
│   (stale medium)             │         (flowing medium)        │
│                              │                                 │
│   ┌────────────────┐    permeable    ┌────────────────┐       │
│   │  Artificial     │    membrane    │  hMEC 1         │  ──►  │
│   │  bone matrix    │   ◄──────►    │  (endothelial)  │ flow  │
│   │  (sponge)       │               │                  │       │
│   │  + hFOB 1.19    │               │                  │       │
│   │  (osteoblasts)  │               │                  │       │
│   └────────────────┘               └────────────────┘       │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

- **Compartment A:** Stale medium with artificial bone structure imitation (sponge matrix), colonized with hFOB 1.19 osteoblasts
- **Compartment B:** Flowing medium, colonized with hMEC 1 endothelial cells
- **Flow rate:** [TBD — to be determined based on chip geometry and pump setup]
- **Separation:** Perforated membrane — permeable for soluble signaling factors, impermeable for cells
- **Incubation:** 37°C, physiological conditions

---

## Slide 3: Current Status — What We Have

**General experiment structure established. Bringing specimen and observation unit in place.**

| Component | Status |
|---|---|
| Bioreactor chip design | Established |
| Cell lines (hFOB 1.19, hMEC 1) | Available |
| Computing unit (RPi 5 + Hailo-8 NPU) | ✅ Operational |
| HQ Camera (IMX477, C-mount) | ✅ Acquired, mounted on conventional microscope |
| OpenFlexure server (v3, FastAPI) | ✅ Running |

**Current phase:** Early stage evaluation — verifying imaging quality on existing microscope setup before transitioning to OpenFlexure platform.

---

## Slide 4: OpenFlexure Microscope — Hardware Platform

**Open-source, 3D-printed motorised microscope (Cambridge, CERN-OHL license)**

```
            Objective (≤10x RMS, scraped)
                │
    ┌───────────┼───────────┐
    │    Optics module       │   ← 3D printed, black PLA
    │    (custom for IMX477) │
    │           │            │
    │      Tube lens         │   ← 125-150 mm achromat (custom)
    │      (12.7 mm)         │
    │           │            │
    │      HQ Camera         │   ← IMX477, C-mount, 12.3 MP
    └───────────┼───────────┘
                │
    ┌───────────┼───────────┐
    │    Flexure stage       │   ← XYZ, sub-µm step resolution
    │    (3x 28BYJ-48        │
    │     stepper motors)    │
    │           │            │
    │    Sangaboard v5       │   ← Motor controller
    └───────────┼───────────┘
                │
    ┌───────────┼───────────┐
    │    Raspberry Pi 5      │   ← 8 GB, OpenFlexure Server
    │    + AI HAT (Hailo-8)  │   ← 27 TOPS NPU
    └────────────────────────┘
```

**Pending hardware:**

| Component | Status | Notes |
|---|---|---|
| Sangaboard v5 | ⏳ On order (Taulab) | Motor controller |
| Stepper motors (3x 28BYJ-48) | ⏳ On order (Taulab) | Stage actuators |
| Bag of Bits (M3 hardware, O-rings) | ⏳ On order (Taulab) | Assembly hardware |
| Illumination Kit | ⏳ On order (Taulab) | LED + condenser |
| Tube lens (125-150 mm achromat) | ⏳ On order (distributor) | Custom for IMX477 |
| Custom optics module STL | ⚠️ In development | Must compile from OpenSCAD source |

---

## Slide 5: Why Custom Optics — The 25% Problem

**Standard OpenFlexure optics module wastes 75% of our sensor**

The tube lens demagnifies the objective's intermediate image onto the camera sensor.
The standard 50 mm tube lens was calculated for the **Pi Camera v2** (4.6 mm diagonal).
Our **HQ Camera IMX477** has a 9.79 mm diagonal — **2.1× larger**.

$$M = \frac{f_t}{f_t + |p|} \quad \text{where } p = -141.5 \text{ mm (back focal length - lens position)}$$

| Tube lens | Magnification | Image circle on sensor | Sensor area used |
|---|---|---|---|
| 50 mm (standard) | 0.261× | 4.4 mm circle on 9.79 mm sensor | **~25%** |
| 125 mm | 0.469× | 8.0 mm circle | ~85% |
| 150 mm | 0.515× | 8.8 mm circle | ~95% |

**How 25% is calculated:**

```
Effective field number with 50mm lens:  FN = 9.79 / 0.261 = 37.5 mm
Standard eyepiece field number range:   17 – 26 mm
→ Image is designed for a 37.5 mm "eyepiece" but sensor is only 9.79 mm
→ Sensor captures:  (9.79 / 37.5)² ≈ (0.261)² ≈ 6.8% of area

More intuitively:  The image circle projected by the 50mm lens
covers the full sensor diagonal of a 4.6mm sensor (Pi Cam v2),
but only the central portion of a 9.79mm sensor (IMX477).
→ Area ratio: (4.6 / 9.79)² = 22%  ≈ 25%
```

**Solution:** Replace 50 mm tube lens with **125–150 mm achromatic doublet** (same 12.7 mm diameter).
This requires a custom optics module STL — the lens seat position and tube length change.

---

## Slide 6: Prospect #1 — Enhancing Data Quality

**Equipping experimental base setup with high-quality compounds**

| Upgrade | Purpose | Impact |
|---|---|---|
| Custom optics module | Match tube lens to IMX477 sensor (125-150 mm) | Full sensor utilization instead of ~25% |
| ≤10x RMS objective (scraped) | Appropriate magnification for cell-level observation | ~1.3 µm resolution at 10x |
| Flat-field correction | Compensate lens shading and illumination unevenness | Consistent intensity across FOV |
| Motorised stage (OpenFlexure) | Reproducible XYZ positioning, sub-µm step resolution | Automated time-lapse, consistent framing |

**Result:** Higher quality raw data → better annotation → better model performance

---

## Slide 7: Prospect #2 — Automated Event Recognition

**Automating event-sensitive cell-cell interaction recognition through NPU inference**

Training pipeline:

```
Manual annotation          Model training           Deployment
(500-1000 images)          (cloud/workstation)       (on-device)
                                    
  HQ Camera        CVAT           YOLOv8n-seg         Hailo-8 NPU
  (raw images) ──► (annotate) ──► (fine-tune) ──► .hef (27 TOPS)
                    classes:                        
                    - osteoblast                    91 inf/s
                    - endothelial                   10.9 ms latency
                    - mineralization                real-time
                    - membrane
```

- **Model:** YOLOv8n-seg (nano segmentation variant — optimized for edge deployment)
- **Training data:** 500–1000 manually annotated images from time-lapse series
- **Annotation tool:** CVAT (open source, self-hosted)
- **Target classes:** Osteoblasts, endothelial cells, mineralization zones, membrane boundary
- **Deployment:** Compiled to Hailo Executable Format (.hef) via Hailo Model Zoo toolchain
- **Inference:** Real-time on Hailo-8 NPU (27 TOPS), <11 ms per frame

### Annotation effort estimate

| Scenario | Time per image | 500 images | 1000 images |
|---|---|---|---|
| Manual (complex scene) | 5–10 min | 42–83 hours | 83–167 hours |
| Manual (simple scene) | 2–5 min | 17–42 hours | 33–83 hours |
| SAM2-assisted (review + correct) | 1–3 min | 8–25 hours | 17–50 hours |

**Recommendation:** Use SAM2 (Segment Anything Model 2) for pre-annotation, then manually review and correct in CVAT. This reduces annotation time by ~60–70%.

### Training time estimate

| Stage | Duration | Hardware |
|---|---|---|
| YOLOv8n-seg fine-tuning (500 images) | ~1–2 hours | GPU workstation or cloud (e.g. Google Colab) |
| YOLOv8n-seg fine-tuning (1000 images) | ~2–4 hours | GPU workstation or cloud |
| Hailo .hef export (compilation) | ~30–60 min | Hailo Model Zoo toolchain (CPU) |
| Validation on device | ~1 hour | RPi 5 + Hailo-8 NPU |

---

## Slide 8: Data Storage — Raw Image Estimates

**IMX477 sensor:** 4056 × 3040 pixels, 12.3 MP

| Format | Size per image | 500 images | 1000 images |
|---|---|---|---|
| 12-bit RAW (DNG) | ~18.5 MB | ~9.2 GB | ~18.5 GB |
| 16-bit TIFF | ~24.7 MB | ~12.3 GB | ~24.7 GB |
| JPEG (high quality) | ~8 MB | ~4.0 GB | ~8.0 GB |

### Time-lapse storage (48-hour experiment)

| Capture interval | Frames | RAW storage |
|---|---|---|
| 1 min | 2880 | ~53 GB |
| 5 min | 576 | ~11 GB |
| 10 min | 288 | ~5 GB |
| 30 min | 96 | ~2 GB |

### External storage recommendation

| Scenario | RPi 5 SD card (32 GB) sufficient? | Recommendation |
|---|---|---|
| 500 JPEG images | ✓ Yes (~4 GB) | SD card is fine |
| 1000 RAW images | ✗ No (~18.5 GB + OS = tight) | External USB SSD recommended |
| Time-lapse 48h @ 5 min, RAW | ✗ No (~11 GB per session) | External USB 3.0 SSD (256 GB+) |
| Multiple experiments | ✗ No | External USB SSD + NAS backup |

**Recommendation:** Attach a **USB 3.0 SSD (256 GB or larger)** to the RPi 5 for raw data collection. The RPi 5 has USB 3.0 ports with sufficient bandwidth (~400 MB/s). Back up to NAS or external storage after each session.

---

## Slide 9: Goal #1 — Biological Insight

**Gaining deeper insight into cell-cell interaction dynamics during hydroxyapatite production**

Specific questions to answer:

- How does proximity to active osteoblasts (via soluble factors through the membrane) affect endothelial cell morphology and migration?
- Does the rate of calcium deposition change in the presence of endothelial signaling?
- Can we identify temporal patterns — do interactions follow predictable phases?
- What morphological markers precede mineralization events?

**Measurement approach:**
- Time-lapse imaging (automated, hours to days)
- AI-assisted segmentation of cell populations and mineralization zones
- Quantitative tracking: cell count, area, migration velocity, mineralization density

---

## Slide 10: Goal #2 — Autonomous Reproducibility

**Building a stable, reproducible experimental platform on the OpenFlexure project**

| Requirement | Solution |
|---|---|
| **Hardware reproducibility** | Open-source 3D-printed microscope (CERN-OHL license) |
| **Software reproducibility** | Ansible-automated deployment — full stack in <10 minutes |
| **Protocol reproducibility** | Scripted imaging sessions via OpenFlexure REST API |
| **Analysis reproducibility** | Trained model (.hef) deployed identically on any Hailo-8 NPU |

**What this means:**
- Any lab with a 3D printer and ~300 EUR can replicate the entire setup
- Software stack is version-controlled and automatically deployed
- Imaging protocols are code, not manual procedures
- AI models are exported as compiled binaries — deterministic inference

**Open-source stack:**
- OpenFlexure (hardware + server): CERN-OHL
- YOLOv8 (Ultralytics): AGPL-3.0
- CVAT (annotation): MIT
- Ansible (deployment): GPL-2.0

---

## Slide 11: Timeline

| Phase | Deliverable | Status |
|---|---|---|
| Experiment design | Bioreactor chip, cell lines, protocol | ✅ Established |
| Hardware base | RPi 5, AI HAT, HQ Camera, OpenFlexure server | ✅ Operational |
| Optics + stage | Custom optics module, motorised stage | ⏳ In progress |
| Early evaluation | First images on conventional microscope | ⏳ Current |
| Dataset collection | 500–1000 annotated time-lapse images | Pending |
| Model training | YOLOv8n-seg fine-tuned on cell interaction data | Pending |
| Deployment + validation | Real-time inference on Hailo-8 NPU | Pending |

---

## Slide 12: Open Questions

- **Flow rate:** What is the optimal flow rate (µL/min) for Compartment B? Depends on chip geometry, pump, and shear stress tolerance of hMEC 1 cells.
- **Objective magnification:** Exact magnification of scraped objective to be verified — determines tube lens choice (125 mm vs 150 mm).
- **Capture interval:** Optimal time-lapse interval for observing mineralization dynamics (5 min? 10 min?)
- **Training data diversity:** Is a single experiment sufficient for 500–1000 diverse images, or are multiple runs needed?

---

## Slide 13: Glossary

| Term | Definition |
|---|---|
| **hFOB 1.19** | Human fetal osteoblast cell line — produces bone matrix and mineralizes |
| **hMEC 1** | Human microvascular endothelial cell line — lines blood vessels |
| **Hydroxyapatite** | Ca₁₀(PO₄)₆(OH)₂ — primary mineral in bone; produced by osteoblasts |
| **Bioreactor chip** | Microfluidic device with separate compartments for co-culture experiments |
| **Permeable membrane** | Perforated barrier allowing soluble factor exchange, blocking cell migration |
| **OpenFlexure** | Open-source 3D-printed microscope platform (Cambridge, CERN-OHL) |
| **RMS** | Royal Microscopical Society — standard microscope objective thread (0.8" × 36 TPI). Defines the mechanical interface between objective and microscope body. Most education and lab objectives use RMS threading. |
| **Tube lens** | Achromatic doublet between objective and sensor — demagnifies intermediate image to fit camera sensor. Focal length determines magnification and field of view. |
| **YOLOv8n-seg** | Ultralytics YOLO v8 nano segmentation — lightweight model for edge inference |
| **Hailo HEF** | Hailo Executable Format — compiled neural network for NPU deployment |
| **NPU** | Neural Processing Unit — dedicated AI accelerator (here: Hailo-8, 27 TOPS) |
| **CVAT** | Computer Vision Annotation Tool — open-source image labeling platform |
| **SAM2** | Segment Anything Model 2 (Meta) — foundation model for automatic pre-segmentation |
| **Finite conjugate** | Objective designed for fixed tube length (typically 160 mm) — forms real image at fixed distance |
| **C-mount** | Standard industrial camera mount with 17.526 mm flange focal distance |
