# Cell Analysis Model Pipeline

AI-powered cell segmentation and tracking for bioreactor chip experiments.

## Overview

This module contains the complete pipeline for training and deploying cell segmentation models on the Hailo-8 NPU for real-time analysis of osteoblasts and epithelial cells.

## Quick Start

```bash
# 1. Set up training environment
conda create -n cellseg python=3.10 -y
conda activate cellseg
pip install ultralytics torch torchvision opencv-python

# 2. Prepare your data (see docs/SETUP.md)

# 3. Train model
python scripts/training/train.py --config configs/cellseg.yaml.example

# 4. Compile to HEF
# (See docs/SETUP.md Phase 5 for detailed instructions)

# 5. Run tracking
python scripts/tracking/track_cells.py --video data/raw/experiment.mp4
```

## Directory Structure

```
model/
├── data/               # Microscopy image datasets
│   ├── raw/           # Original captured images
│   ├── processed/     # Preprocessed/augmented images
│   └── annotations/   # YOLO format labels
├── models/            # Model files
│   ├── pretrained/    # Base pretrained weights
│   ├── trained/       # Fine-tuned .pt files
│   └── compiled/      # HEF files for Hailo-8
├── scripts/           # Executable scripts
│   ├── training/      # Model training
│   ├── inference/     # Inference pipelines
│   └── tracking/      # Cell tracking
├── configs/           # Configuration files
└── docs/              # Documentation
    ├── SETUP.md       # Detailed setup guide
    └── ROADMAP.md     # Project roadmap
```

## Documentation

| Document | Description |
|----------|-------------|
| [SETUP.md](docs/SETUP.md) | Complete setup guide for development and deployment |
| [ROADMAP.md](docs/ROADMAP.md) | Project timeline and milestones |

## Classes

| ID | Class | Description |
|----|-------|-------------|
| 0 | osteoblast | Bone-forming cells, calcium producers |
| 1 | epithelial | Epithelial cells |
| 2 | calcium | Calcium deposits |

## Model Selection

| Model | FPS (Hailo-8) | mAP | Use Case |
|-------|---------------|-----|----------|
| yolov8n-seg | 528 | 29.6 | Maximum speed |
| **yolov8s-seg** | 202 | 36.3 | **Recommended** |
| yolov8m-seg | 103 | 40.2 | Maximum accuracy |

## Requirements

### Training
- NVIDIA GPU (8GB+ VRAM recommended)
- Python 3.10+
- See `docs/SETUP.md` for full list

### Inference
- Raspberry Pi 5 + Hailo-8 AI HAT
- Picamera2 / OpenCV
- HailoRT Python SDK

## References

- [Ultralytics YOLOv8](https://github.com/ultralytics/ultralytics)
- [Hailo Model Zoo](https://github.com/hailo-ai/hailo_model_zoo)
- [ByteTrack](https://github.com/ifzhang/ByteTrack)
- [Cellpose](https://github.com/MouseLand/cellpose)
