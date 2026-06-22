# Cell Analysis Pipeline - Roadmap

## Project Overview

**Goal**: Real-time cell type recognition and morphological analysis on Hailo-8 NPU for bioreactor chip experiments.

**Target**: Osteoblasts and epithelial cells - tracking, migration, calcium production

---

## Milestones

### M1: Foundation ✅
- [x] Hardware assembled
- [x] Ansible deployment for Hailo-8 + OpenFlexure
- [x] Basic inference working (MobileNet V2)

### M2: Data Collection
**Target**: March 2026 (2 weeks)

- [ ] Configure automated time-lapse capture
  - Capture interval: 1-5 minutes
  - Duration: 24-72 hour experiments
  - Storage: External SSD or NAS
- [ ] First dataset: 500+ images
  - Diverse lighting conditions
  - Multiple cell densities
  - Include calcium staining if possible
- [ ] Document capture parameters

### M3: Annotation Pipeline
**Target**: March 2026 (2 weeks)

- [ ] Deploy CVAT instance
- [ ] Define class taxonomy:
  - `0: osteoblast`
  - `1: epithelial`
  - `2: calcium_deposit`
- [ ] Annotate 500 images (or use semi-automatic methods)
- [ ] Validate annotation quality
- [ ] Export in YOLO segmentation format

### M4: Model Training
**Target**: April 2026 (3 weeks)

- [ ] Set up training environment (Colab/AWS/GPU workstation)
- [ ] Fine-tune YOLOv8s-seg on cell data
- [ ] Experiment with augmentation strategies
- [ ] Evaluate: mAP, per-class performance
- [ ] Select best model checkpoint
- [ ] **Deliverable**: `cellseg_yolov8s_seg.pt`

### M5: Hailo-8 Compilation
**Target**: April 2026 (1 week)

- [ ] Export to ONNX format
- [ ] Prepare calibration dataset (100 representative images)
- [ ] Compile to HEF using DFC
- [ ] Validate inference accuracy (compare .pt vs .hef)
- [ ] **Deliverable**: `cellseg.hef`

### M6: Integration
**Target**: May 2026 (2 weeks)

- [ ] Configure OpenFlexure for HQ Camera (IMX477) with custom tube lens
- [ ] Add cellseg model loading to Hailo-8
- [ ] Implement inference API endpoint
- [ ] Performance testing (FPS, latency)
- [ ] **Deliverable**: Integrated cellseg on mesoscope

### M7: Cell Tracking
**Target**: May 2026 (2 weeks)

- [ ] Implement ByteTrack integration
- [ ] Connect segmentation → tracking pipeline
- [ ] Calculate metrics:
  - Migration velocity
  - Trajectory analysis
  - Cell-cell proximity
  - Calcium proximity for osteoblasts
- [ ] Visualize tracking results

### M8: Analysis & Reporting
**Target**: June 2026 (2 weeks)

- [ ] Morphological measurements:
  - Cell area, perimeter, circularity
  - Calcium deposit size and location
  - Cell density maps
- [ ] Time-series analysis:
  - Calcium production over time
  - Cell population dynamics
- [ ] Statistical significance testing
- [ ] Generate plots for thesis

### M9: Validation
**Target**: June 2026 (1 week)

- [ ] Compare AI analysis vs manual counting
- [ ] Validate tracking accuracy
- [ ] Test robustness across experiments
- [ ] Document repeatability

### M10: Thesis Documentation
**Target**: July 2026

- [ ] Write methods section
- [ ] Include performance benchmarks
- [ ] Document limitations
- [ ] Add future work recommendations

---

## Timeline Overview

```
March        April          May           June          July
|------------|--------------|--------------|--------------|
M2  M3  M4   M4  M5  M6     M6  M7  M8     M8  M9  M10
|----DATA----|----TRAIN-----|---DEPLOY-----|---ANALYZE----|
             |----COMPILE----|
```

---

## Resource Requirements

| Phase | Compute | Storage | Time |
|-------|---------|---------|------|
| Data Collection | Pi 5 | 50GB+ | 2 weeks |
| Training | RTX 3080+ or A100 | 5GB | 24-48h |
| Compilation | Docker + Hailo DFC | 10GB | 2-4h |
| Inference | Pi 5 + Hailo-8 | 1GB | Real-time |

---

## Technical Decisions

### Model Architecture: YOLOv8s-seg
- **Rationale**: Best accuracy/speed tradeoff for 26 TOPS Hailo-8
- **Alternative considered**: YOLOv8n-seg (faster, lower accuracy)
- **Alternative considered**: YOLOv8m-seg (slower, better accuracy)

### Tracking: ByteTrack
- **Rationale**: Works well with YOLO detections
- **Alternative considered**: DeepSORT (slower)
- **Alternative considered**: Simple online tracker (less robust)

### Annotation: CVAT
- **Rationale**: Native YOLO format export
- **Alternative considered**: Labelme (manual polygon export)
- **Alternative considered**: SAM-assisted (semi-automatic)

---

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Annotation bottleneck | High | Medium | Use Cellpose for pre-annotation |
| Low mAP on cells | Medium | High | Domain-specific augmentation |
| HEF accuracy drop | Low | High | Extensive calibration set |
| Hailo-8 PCIe issues | Low | High | Test with official models first |
| Calcium visual similarity | Medium | Medium | Phase contrast + fluorescence |

---

## Future Enhancements

- [ ] Multi-class calcium staging (early/late calcification)
- [ ] Cell division detection
- [ ] 3D reconstruction from z-stacks
- [ ] Transfer learning from cellpose models
- [ ] Real-time anomaly detection
- [ ] Integration with OpenFlexure smart scan

---

## References

- [Ultralytics YOLOv8](https://github.com/ultralytics/ultralytics)
- [Hailo Model Zoo](https://github.com/hailo-ai/hailo_model_zoo)
- [HailoConverter](https://github.com/cyclux/HailoConverter)
- [ByteTrack](https://github.com/ifzhang/ByteTrack)
- [Cellpose](https://github.com/MouseLand/cellpose)
- [CVAT](https://github.com/opencv/cvat)
