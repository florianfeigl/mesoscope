# Master's Thesis — Roadmap (9–12 months)

Start assumed 2026-10-01; submission window 2027-07 … 2027-09.
Milestones M0–M7; each has an exit criterion. Writing runs in parallel from M2 onward (chapter
numbers refer to `THESIS_OUTLINE.md`). Buffer of ~6 weeks is built into the 12-month variant.

```
        Oct  Nov  Dec  Jan  Feb  Mar  Apr  May  Jun  Jul  Aug  Sep
M0 Frame ██
M1 Optics    ████
M2 Motion         ████
M3 Rail                ████████
M4 Data/ML                  ████████████
M5 Biology                            ████████
M6 Evaluation                              ████████
M7 Writing   ░░░░░░░░░░░░░░░░░░░░░░░░░░████████████
Buffer                                                  ████
```

## M0 — Framing & housekeeping (Oct 2026, 3–4 weeks)

Goal: thesis registered, research questions fixed, documentation contradiction-free.

- [ ] Confirm faculty, supervisor(s), formal requirements (template, page count, colloquium date).
- [ ] Finalise RQ1–3 and success criteria H1–H3 with supervisor (`THESIS_OUTLINE.md` §1).
- [ ] Define the **biological readout** (confluence / cell count / morphology / calcification) — this decides the ML task and label schema.
- [ ] Resolve motor-architecture decision (Sangaboard hybrid vs. all-GPIO) and write it down once.
- [ ] Fix documented inconsistencies (sensor size, camera values, tube magnification) and retire the "CELLAIR" name — `THESIS_PARAMETER_GAPS.md` §"Immediate housekeeping".
- [ ] Create `docs/VERSIONS.md` (pinned commits/versions) and a literature database (Zotero) with ≥ 30 initial references.
- [ ] Set up thesis LaTeX repo (or `thesis/` dir) with CI build.

**Exit:** signed registration; RQs written; no contradictions in repo docs.

## M1 — Optics module & imaging validation (Nov–Dec 2026, 6 weeks)

Goal: RQ1 answerable. Ch. 4 draftable.

- [ ] Objective is a ZEISS Plan-Neofluar 10×/0.30: verify tube-length marking (160 mm finite vs. ∞) and thread (RMS vs. M27 → adapter or optics-module change), update `OPTICS_MODULE.md` (NA 0.30 → 1.12 µm Rayleigh).
- [ ] Print and assemble 125 mm optics module (`build_optics.sh 125`); assemble Z-only body (`build_body.sh mesoscope`), stand and drawer.
- [ ] Measure: lateral resolution (USAF 1951 target), FOV (stage micrometer), sensor fill, working distance at the chip window, focus repeatability (Z stepper).
- [ ] Flat-field / lens-shading calibration; document illumination (LED type, wavelength, power, condenser).
- [ ] Image a real bioreactor chip through its window (fixed cells) — first "hero" images for ch. 4/9.
- [ ] Decide 125 vs. 150 mm tube lens on measured data.

**Exit:** resolution/FOV/flat-field table exists; H1 evaluated (pass or documented deviation).

## M2 — Motion control & software stage (Dec 2026–Jan 2027, 6 weeks)

Goal: focus + rail drivable from OpenFlexure; ch. 6–7 draftable.

- [ ] Implement the GPIO stage class (ULN2003 focus + TMC2209 rail) or Sangaboard hybrid per M0 decision; wire into `ofm_config.json.j2`.
- [ ] Measure focus µm/step and Z travel; re-run CSM calibration (`csm_calibrate_rpi5.py`) on the assembled unit.
- [ ] Validate OpenFlexure autofocus on the chip window (success rate over ≥ 50 trials).
- [ ] Wiring diagram + pinout table + power budget (5 V rail with Hailo under load; 12–24 V motor supply).
- [ ] Implement `capture_timelapse.py` / scan orchestration (positions × interval × chips → timestamped images + metadata JSON).
- [ ] Update Ansible so a fresh Pi reproduces the full stack in one run (document run time).

**Exit:** autofocus success rate measured; time-lapse of one chip over 24 h captured unattended.

## M3 — Rail mount & bioreactor rack (Jan–Feb 2027, 8 weeks; overlaps M2/M4)

Goal: RQ2 answerable; ch. 5 draftable.

- [ ] Order rail hardware (2040 V-slot, MGN12, NEMA17 + Tr8×2, TMC2209, PSU).
- [ ] Confirm bioreactor pitch and rack geometry with the biology side; update `bioreactor_rack.scad` and `rail_mount_mesoscope.scad`.
- [ ] Print/assemble tilt mount, carriage, rack (N=3); measure tilted mass, centre of gravity, deflection.
- [ ] Measure rail positioning repeatability (dial gauge + image-based, ≥ 20 cycles), focus drift after tilt over 12 h, thermal drift in the incubator.
- [ ] Multi-chip scan: 3 chips × k positions, 72 h in incubator, unattended.
- [ ] Incubator integration: cable routing, humidity/condensation protection, heat of Pi + Hailo inside the incubator (temperature log).

**Exit:** H2 evaluated; 72 h multi-chip time-lapse dataset exists.

## M4 — Dataset & Edge-AI pipeline (Feb–Apr 2027, 12 weeks)

Goal: RQ3 answerable; ch. 8 draftable.

- [ ] Data-acquisition protocol (which chips, cell densities, magnifications, illumination) and dataset card.
- [ ] CVAT label schema + annotation guideline; annotate ≥ 300 images (or ≥ 5 000 instances); inter-annotator check on a subset (≥ 30 images, 2 annotators).
- [ ] Train/val/test split **by chip** (no leakage); baseline models: YOLOv8-n/s (det or seg) vs. Cellpose/StarDist; report mAP@0.5, IoU, count MAE.
- [ ] Compile best model with Hailo Dataflow Compiler → `.hef`; measure accuracy delta after quantisation.
- [ ] Deploy on Pi 5: HailoRT inference service consuming the time-lapse output; measure latency/throughput NPU vs. CPU (ONNX Runtime) vs. reference GPU.
- [ ] Ground-truth method for cell counts (manual count on reference microscope or trypan blue) defined and applied to the test set.
- [ ] Create `model/` with training config, `requirements.txt`, and tests so the existing CI job becomes real.

**Exit:** H3 evaluated; model card + dataset card written; inference runs on-device end-to-end.

## M5 — Biological application study (Apr–May 2027, 8 weeks; overlaps M4/M6)

Goal: demonstrate the system on a real question, not just a benchmark. Ch. 9 application section.

- [ ] Experimental design with the biology side: cell lines (hFOB 1.19 / hMEC 1), medium, seeding density, flow/pressure conditions, replicates, controls, duration.
- [ ] Run ≥ 1 full monitoring campaign (e.g. 3 chips, 2 conditions, 5–7 days, imaging every 2 h).
- [ ] Derive the readout time series (confluence/count/morphology) automatically; compare to end-point reference measurement.
- [ ] Document failures (focus loss, condensation, motor stalls) quantitatively — this is thesis material.

**Exit:** one complete campaign with automated readout and reference comparison.

## M6 — Evaluation & consolidation (May–Jun 2027, 6 weeks)

- [ ] Consolidate all measurements into ch. 9 tables/figures (optics, mechanics, automation, ML, cost, build time).
- [ ] Cost/time balance vs. commercial live-cell imager; reproducibility check: second person rebuilds from repo + Ansible (log time and problems).
- [ ] Error analysis and limitations for ch. 10.

## M7 — Writing & submission (Jun–Sep 2027)

- Writing is continuous from M1 (target: chapter draft ≤ 2 weeks after each milestone). Ch. 2 literature review written during M1–M2 idle time (print jobs, orders).
- [ ] Full draft to supervisor by end of Jun 2027; revision loop July.
- [ ] Final figures, appendices (BOM, print settings, wiring, dataset/model cards, Ansible variable reference).
- [ ] Submission target Aug 2027 (12-month variant: Sep 2027). Colloquium prep.

## Risks & mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Tilted flexure drifts / loses focus | medium | high | Measure early in M3; fallback: horizontal-window chip holder with microscope upright, or stiffening brace |
| Rail hardware lead time | medium | medium | Order in M0/M1, not M3 |
| Too few cells / poor contrast through chip window for ML | medium | high | M1 hero images decide early; fallback: fixed/stained reference slides for the ML chapter, chip images as transfer test |
| Hailo DFC quantisation kills accuracy | low–medium | medium | Report CPU path as valid result; NPU as speed-up with documented accuracy delta |
| Biology campaign slips (cell availability, incubator time) | high | medium | Decouple: RQ1–3 must be answerable without M5; M5 is the "application" bonus |
| Scope creep (fluorescence, more rails, dashboards) | high | high | Anything not in RQ1–3 goes to Outlook |
| Pi 5 stack breakage after OS/OFM updates | medium | medium | Pin versions (`VERSIONS.md`), snapshot SD image after M2 |

## Minimum viable thesis (if time runs out)

RQ1 + RQ3 with a single stationary chip (no rail), model trained on fixed-cell images, NPU vs. CPU evaluation. RQ2/rail becomes a designed-and-partially-validated chapter plus outlook. Decide by end of M3 (Feb 2027).
