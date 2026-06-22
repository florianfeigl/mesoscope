# OpenFlexure Suite — Software List

Complete inventory of software deployed on the mesoscope Raspberry Pi 5.

## Operating System

| Component | Version | Notes |
|-----------|---------|-------|
| Raspberry Pi OS | Trixie (book, 64-bit) | Debian-based, Python 3.13 |
| Kernel | RPi 6.x | With `hailo_pci` DKMS module |
| Hostname | `mesoscope` | |
| Timezone | Europe/Berlin | NTP sync, DS3231 RTC backup |

## Ansible-Deployed Software

Deployed via `ansible/roles/`:

### Base System (`roles/base`)
| Package | Purpose |
|---------|---------|
| git, curl, wget, vim | Common utilities |
| htop | System monitoring |
| build-essential | C compiler, make, headers |
| python3-pip, python3-venv | Python environment |
| i2c-tools | I2C bus scanning (RTC, Hailo) |
| dkms | Dynamic kernel module support |

### AI HAT + Camera (`roles/ai-hat`)
| Package | Purpose |
|---------|---------|
| rpicam-apps | Camera capture CLI (replaces libcamera-apps) |
| python3-picamera2 | Python camera interface (IMX477) |
| python3-libcamera | libcamera Python bindings |
| python3-opencv | Image processing |
| python3-numpy | Numerical computing |
| hailo-all | Hailo-8 SDK, firmware, model zoo |

### OpenFlexure Server (`roles/openflexure`)
| Component | Path / Details |
|-----------|----------------|
| Server repo | `/opt/openflexure/server` (Git, `v3` branch) |
| Python venv | `/opt/openflexure/venv` (system-site-packages) |
| Server package | `openflexure-microscope-server[pi]` (editable install) |
| Web app | Static frontend from GitLab CI artifacts |
| Config file | `/var/openflexure/settings/ofm_config.json` |
| Data directory | `/var/openflexure/data/` |
| Log directory | `/var/openflexure/logs/` |
| Service | `openflexure.service` (systemd, auto-start on boot) |
| Port | 5000 (HTTP) |
| Camera class | `StreamingPiCamera2` with `camera_board: "picamera_hq"` |
| Stage | `DummyStage` (until Sangaboard connected) |

### Motor Controller (`roles/motor-controller`)
| Component | Purpose |
|-----------|---------|
| Arduino IDE | Sangaboard firmware flashing |
| 28BYJ-48 driver | Stepper motor control |

## Camera Configuration

### IMX477 (Pi HQ Camera)
| Parameter | Value |
|-----------|-------|
| Sensor | Sony IMX477, 12.3 MP |
| Sensor size | 7.857 × 5.893 mm |
| Max resolution | 4056 × 3040 @10fps |
| Stream resolution | 2028 × 1520 @30fps |
| Mount | C-mount (FFD 17.526 mm) |
| OpenFlexure class | `StreamingPiCamera2` |
| Camera board kwarg | `picamera_hq` |
| Detection command | `rpicam-hello --list-cameras` |

### IMX500 (AI Camera) — Experimental
| Parameter | Value |
|-----------|-------|
| Sensor | Sony IMX500, 12.3 MP + NPU |
| Status | Custom `IMX500Camera` thing written (`imx500_camera.py`) |
| Integration | Not yet in Ansible config |
| Notes | Requires PISP tuning file; see Julian Stirling's email (2026-03-10) |

## Hailo-8 NPU

| Parameter | Value |
|-----------|-------|
| Architecture | Hailo-8, 26 TOPS |
| Firmware | v4.23.0 |
| Kernel module | `hailo_pci` (DKMS) |
| Device | `/dev/hailo0` |
| Pre-installed models | `/usr/share/hailo-models/` (18 models) |
| Key models | `yolov8s_pose_h8.hef`, `yolov5n_seg_h8.hef`, `yolov5s_personface_h8l.hef` |
| Benchmark | 91.5 inf/s, 10.9ms latency (YOLOv8s Pose) |
| Custom model target | `model/models/compiled/cellseg.hef` |

## OpenFlexure Server Configuration

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
        "camera_stage_mapping": "openflexure_microscope_server.things.camera_stage_mapping:CameraStageMapper",
        "system": "openflexure_microscope_server.things.system:OpenFlexureSystem",
        "smart_scan": {
            "class": "openflexure_microscope_server.things.smart_scan:SmartScanThing",
            "kwargs": {"default_workflow": "histo_scan_workflow"}
        },
        "histo_scan_workflow": "openflexure_microscope_server.things.scan_workflows:HistoScanWorkflow",
        "snake_workflow": "openflexure_microscope_server.things.scan_workflows:SnakeWorkflow",
        "raster_workflow": "openflexure_microscope_server.things.scan_workflows:RasterWorkflow",
        "bg_color_channels_luv": "openflexure_microscope_server.things.background_detect:ColourChannelDetectLUV",
        "bg_channel_deviations_luv": "openflexure_microscope_server.things.background_detect:ChannelDeviationLUV"
    },
    "settings_folder": "/var/openflexure/settings/",
    "application_config": {
        "log_folder": "/var/openflexure/logs/",
        "data_folder": "/var/openflexure/data/"
    }
}
```

### When Sangaboard is connected
Change `stage` from `DummyStage` to:
```json
"stage": "openflexure_microscope_server.things.stage.sangaboard:SangaboardThing"
```
Then: `ansible-playbook site.yml --tags openflexure && ssh lab@mesoscope.local 'sudo systemctl restart openflexure'`

## API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v2/camera/` | Camera status |
| `GET /api/v2/camera/capture` | Capture still image |
| `POST /api/v2/camera/stream/start` | Start MJPEG stream |
| `POST /api/v2/camera/stream/stop` | Stop stream |
| `GET /api/v2/stage/` | Stage position (DummyStage: always 0,0,0) |
| `POST /api/v2/stage/move_absolute` | Move to position (requires Sangaboard) |
| `GET /api/v2/scan/` | Smart scan workflows |

## Verification Commands

```bash
# System
hostname && timedatectl
sudo hwclock -r                          # RTC
sudo i2cdetect -y 1                      # I2C bus

# Camera
rpicam-hello --list-cameras              # Should show imx477

# Hailo
lsmod | grep hailo                       # Driver loaded
ls /dev/hailo*                            # Device present
hailortcli fw-control identify           # Firmware version

# OpenFlexure
sudo systemctl status openflexure         # Service running
curl -s http://localhost:5000/ | head -5  # Web UI accessible
```

## Resource Profile (idle with camera streaming)

| Resource | Value |
|----------|-------|
| CPU | 4 cores, load avg 0.71 (OpenFlexure ~63% of one core) |
| RAM | 762 MB used / 15 GB total (5%) |
| Temperature | 48.3 C |
| Disk | 11 GB used / 117 GB total (10%) |
| Swap | 0 B used |