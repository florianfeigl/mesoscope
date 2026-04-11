# Data Collection

Scripts for capturing microscopy images from the OpenFlexure microscope.

## Quick Start

### Remote capture via OpenFlexure API (recommended)

```bash
# Capture 500 images at 60-second intervals
python scripts/data_collection/capture_timelapse.py \
  --output ../data/raw \
  --interval 60 \
  --count 500

# Capture for 24 hours
python scripts/data_collection/capture_timelapse.py \
  --output ../data/raw \
  --interval 120 \
  --duration 24h
```

### Local capture on Raspberry Pi

```bash
# On the Pi, using picamera2 directly
python3 scripts/data_collection/capture_local.py \
  --output /path/to/data/raw \
  --interval 60 \
  --count 500 \
  --resolution 2028x1520

# Full resolution capture (4056x3040)
python3 scripts/data_collection/capture_local.py \
  --output /path/to/data/raw \
  --interval 300 \
  --duration 72h \
  --resolution 4056x3040
```

## Recommended Dataset Size

| Class | Min Images | Recommended |
|-------|------------|-------------|
| Osteoblasts | 200 | 500 |
| Epithelial cells | 200 | 500 |
| Calcium deposits | 100 | 300 |

## Annotation Pipeline

1. Capture images using scripts above
2. Upload to CVAT (https://cvat.feigl.dev)
3. Annotate with polygon masks (instance segmentation)
4. Export as YOLO segmentation format
5. Place in `data/annotations/`

## Camera Configuration

The HQ Camera (IMX477) supports these resolutions:

| Resolution | Max FPS | Use Case |
|------------|---------|----------|
| 4056x3040 | 10 | Full resolution capture |
| 2028x1520 | 30 | Timelapse (recommended) |
| 1332x990 | 60 | Fast streaming |

Default for data collection: **2028x1520** (good balance of resolution and capture speed).