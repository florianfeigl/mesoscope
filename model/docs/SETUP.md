# Cell Analysis Model Pipeline - Setup Guide

## Hardware Requirements

| Component | Specification | Status |
|-----------|---------------|--------|
| Raspberry Pi 5 | 8GB RAM | Required |
| Hailo-8 AI HAT | 27 TOPS | Required |
| HQ Camera (IMX477) | C-mount, 12.3 MP | Required |

## Directory Structure

```
model/
├── data/
│   ├── raw/              # Original microscopy images
│   ├── processed/        # Preprocessed/augmented images
│   └── annotations/      # CVAT/YOLO format labels
├── models/
│   ├── pretrained/       # Base models (YOLOv8, etc.)
│   ├── trained/          # Fine-tuned weights (.pt)
│   └── compiled/         # HEF files for Hailo-8
├── notebooks/            # Jupyter analysis notebooks
├── scripts/
│   ├── training/         # Model training scripts
│   ├── inference/        # Inference pipeline
│   └── tracking/         # Cell tracking scripts
├── configs/              # YAML configurations
└── docs/                # Documentation
```

---

## Phase 1: Development Environment Setup

### 1.1 Training Machine (GPU Required)

```bash
# Create conda environment
conda create -n cellseg python=3.10 -y
conda activate cellseg

# Install core dependencies
pip install ultralytics torch torchvision
pip install opencv-python pillow numpy pandas
pip install cellpose  # For label assistance
pip install wandb tensorboard  # Logging

# Install annotation tools
pip install cvat-sdk  # For CVAT integration

# Install tracking
pip install bytetrack
```

### 1.2 Raspberry Pi 5 (Inference)

```bash
# Already configured via ansible/roles/ai-hat
# Verify Hailo-8 is detected
 hailortcli fw-control identify

# Test inference
python3 -c "from hailo_platform import *; print('Hailo SDK OK')"
```

---

## Phase 2: Data Collection

### 2.1 Image Acquisition

```bash
# Capture via OpenFlexure API
curl http://mesoscope.local:5000/api/v1/camera/capture -o capture.tif

# Or capture with picamera2
python3 << 'EOF'
from picamera2 import Picamera2
import time

picam2 = Picamera2()
picam2.start()

for i in range(100):
    picam2.capture_file(f"/home/feivel/repos/mesoscope/model/data/raw/frame_{i:04d}.jpg")
    time.sleep(60)  # Every minute
EOF
```

### 2.2 Recommended Dataset Size

| Cell Type | Min Images | Recommended |
|-----------|------------|-------------|
| Osteoblasts | 200 | 500 |
| Epithelial cells | 200 | 500 |
| Calcium deposits | 100 | 300 |

---

## Phase 3: Annotation

### 3.1 Using CVAT

1. Deploy CVAT: `docker run -it -p 8080:8080 cvat/server`
2. Create project with classes:
   - `osteoblast`
   - `epithelial`
   - `calcium`
3. Annotate using polygon/brush tools for instance segmentation
4. Export as YOLO segmentation format

### 3.2 Data Format

```
annotations/
├── images/
│   ├── train/
│   └── val/
└── labels/
    ├── train/
    └── val/
```

Label format (YOLO polygon):
```
<class_id> <x1> <y1> <x2> <y2> ... <xn> <yn>
```

---

## Phase 4: Model Training

### 4.1 Configuration (`configs/cellseg.yaml`)

```yaml
# See configs/cellseg.yaml.example
```

### 4.2 Training Script

```bash
cd model/scripts/training
python train.py --config ../../configs/cellseg.yaml
```

### 4.3 Training Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Model | yolov8s-seg.pt | Balance speed/accuracy |
| Epochs | 100-300 | Early stopping enabled |
| Batch size | 16 | Adjust for GPU memory |
| Image size | 640 | Standard |
| Learning rate | 0.001 | Cosine schedule |
| Augmentation | Yes | Flip, rotate, mosaic |

---

## Phase 5: Model Compilation

### 5.1 Export to ONNX

```bash
# On training machine
yolo export model=runs/segment/train/weights/best.pt format=onnx opset=11
```

### 5.2 Compile to HEF

Using [HailoConverter](https://github.com/cyclux/HailoConverter):

```bash
# 1. Clone converter
git clone https://github.com/cyclux/HailoConverter.git
cd HailoConverter

# 2. Place your model and calibration images
cp best.onnx .
cp -r calibration_imgs/ .

# 3. Build docker
docker build -t hailo_converter:latest .

# 4. Compile
docker run -v $(pwd):/workspace --gpus all --ipc=host hailo_converter:latest
```

### 5.3 Alternative: Hailo Model Zoo

```bash
# Using official model zoo
git clone https://github.com/hailo-ai/hailo_model_zoo.git
cd hailo_model_zoo
pip install -e .

# Compile your trained ONNX
hailomz compile --ckpt best.onnx --hw-arch hailo8 --yaml yolov8s_seg.yaml
```

---

## Phase 6: Deployment

### 6.1 Deploy HEF to Pi

```bash
# Copy to model directory
scp best.hef lab@mesoscope.local:/var/openflexure/models/

# Or to shared location
sudo cp best.hef /usr/share/hailo-models/
```

### 6.2 Update OpenFlexure Config

The HQ Camera (IMX477) is configured via `StreamingPiCamera2` with `camera_board: "picamera_hq"`.

The config is deployed via Ansible: `ansible/roles/openflexure/templates/ofm_config.json.j2`

```json
{
    "things": {
        "camera": {
            "class": "openflexure_microscope_server.things.camera.picamera:StreamingPiCamera2",
            "kwargs": {
                "camera_board": "picamera_hq"
            }
        }
    }
}
```

### 6.3 Run Inference

```python
# model/scripts/inference/hailo_inference.py
import numpy as np
from hailo_platform import *

# Load compiled model
hef = HEF('cellseg.hef')
devices = Device.get_available_devices()
device = devices[0]
device.flash_hef(hef)

# Or use HailoRT Python API
from hailo_platform.pyhailort import HailoRTClassifier
```

---

## Phase 7: Cell Tracking

### 7.1 Tracking Pipeline

```bash
cd model/scripts/tracking
python track_cells.py --video data/raw/observation.mp4
```

### 7.2 Output Metrics

- Cell positions per frame
- Migration paths
- Velocity vectors
- Cell-cell interactions
- Calcium proximity analysis

---

## Verification

```bash
# Test full pipeline
cd model
pytest tests/ -v
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| CUDA OOM during training | Reduce batch size or image size |
| HEF compilation fails | Check calibration images (~100 diverse samples) |
| Low mAP on cells | Increase training data, check annotation quality |
| Hailo not detected | Check PCIe connection, run `hailortcli fw-control identify` |
