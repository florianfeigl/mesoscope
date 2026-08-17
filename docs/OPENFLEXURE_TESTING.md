# OpenFlexure Software Testing Guide

Step-by-step guide to get OpenFlexure Server running and verify camera control
with the Pi HQ Camera (IMX477).

## Prerequisites

- Raspberry Pi 5 with Pi OS Trixie (book), Python 3.13
- Pi HQ Camera (IMX477) connected via CSI ribbon cable
- AI HAT+ installed (optional for camera testing)
- Ansible playbook already run: `ansible-playbook site.yml`

## Step 1: Verify Camera Detection

```bash
# On the Pi:
rpicam-hello --list-cameras

# Expected output:
# Available cameras:
# 0 : imx477 [4056x3040] (/base/soc/i2c0mux/i2c@1/imx477@1a)

# If not detected:
# 1. Check ribbon cable is seated correctly (blue side facing Ethernet port)
# 2. Check camera_auto_detect=1 in /boot/firmware/config.txt
# 3. Reboot: sudo reboot
```

## Step 2: Test Camera with rpicam

```bash
# Quick test capture
rpicam-hello --timeout 5000

# Capture a still image
rpicam-still -o /tmp/test_capture.jpg

# Capture at different resolutions
rpicam-still -o /tmp/test_hires.jpg --width 4056 --height 3040
rpicam-still -o /tmp/test_preview.jpg --width 2028 --height 1520

# Capture a video
rpicam-vid -o /tmp/test_video.h264 -t 5000
```

## Step 3: Verify OpenFlexure Server

```bash
# Check service status
sudo systemctl status openflexure

# If not running, start it:
sudo systemctl start openflexure

# Check logs if there are errors:
sudo journalctl -u openflexure -f
```

### Common Issues

| Error | Cause | Fix |
|-------|-------|-----|
| `ModuleNotFoundError: openflexure_microscope_server` | Package not installed | `cd /opt/openflexure/server && /opt/openflexure/venv/bin/pip install -e ".[pi]"` |
| `Camera not found` | IMX477 not detected or config issue | Verify `rpicam-hello --list-cameras`, check config |
| `Address already in use` | Another process on port 5000 | `sudo lsof -i :5000` then kill or change port |
| Permission denied on `/var/openflexure/` | Wrong ownership | `sudo chown -R lab:lab /var/openflexure/` |

## Step 4: Access Web UI

Open in browser: **http://mesoscope.local:5000**

You should see the OpenFlexure Microscope web interface.

## Step 5: Verify Camera in OpenFlexure

### Via Web UI
1. Open http://mesoscope.local:5000
2. Click "Start Stream" — you should see a live camera feed
3. Click "Capture" — a still image should be saved

### Via API

```bash
# Check camera status
curl -s http://mesoscope.local:5000/api/v2/camera/ | python3 -m json.tool

# Capture an image via API
curl -o /tmp/ofm_capture.jpg http://mesoscope.local:5000/api/v2/camera/capture

# Start/stop stream
curl -X POST http://mesoscope.local:5000/api/v2/camera/stream/start
curl -X POST http://mesoscope.local:5000/api/v2/camera/stream/stop
```

## Step 6: Test picamera2 Directly (Debugging)

If OpenFlexure camera doesn't work, test picamera2 directly:

```python
# On the Pi, in the OpenFlexure venv:
/opt/openflexure/venv/bin/python3 << 'EOF'
from picamera2 import Picamera2

picam2 = Picamera2()
config = picam2.create_still_configuration(
    main={"size": (2028, 1520)}
)
picam2.configure(config)
picam2.start()
import time
time.sleep(1)
picam2.capture_file("/tmp/picam2_test.jpg")
picam2.stop()
print("Camera capture successful: /tmp/picam2_test.jpg")
EOF
```

## Step 7: Timelapse Capture (Data Collection)

```bash
# Capture 100 images at 60-second intervals via API
python3 model/scripts/data_collection/capture_timelapse.py \
  --output data/raw \
  --interval 60 \
  --count 100 \
  --base-url http://mesoscope.local:5000

# Or capture locally on the Pi:
python3 model/scripts/data_collection/capture_local.py \
  --output /tmp/timelapse \
  --interval 60 \
  --count 100 \
  --resolution 2028x1520
```

## Configuration File

The OpenFlexure configuration is at: `/var/openflexure/settings/ofm_config.json`

Current configuration (IMX477 HQ Camera):

```json
{
    "things": {
        "camera": {
            "class": "openflexure_microscope_server.things.camera.picamera:StreamingPiCamera2",
            "kwargs": {
                "camera_board": "picamera_hq"
            }
        },
        "stage": "openflexure_microscope_server.things.stage.dummy:DummyStage",
        "autofocus": "openflexure_microscope_server.things.autofocus:AutofocusThing",
        ...
    }
}
```

> **Stage:** Currently `DummyStage`. Once the Sangaboard is wired and flashed, switch to:
> `"openflexure_microscope_server.things.stage.sangaboard:SangaboardThing"`
> Update in `ansible/roles/openflexure/templates/ofm_config.json.j2` and redeploy.

## Redeploy After Config Changes

```bash
# From the Ansible control machine:
cd /path/to/mesoscope/ansible
ansible-playbook site.yml --tags openflexure

# Or on the Pi, just restart the service:
ssh lab@mesoscope.local 'sudo systemctl restart openflexure'
```