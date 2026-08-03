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
| Stage | `SangaboardThing` (v0.5 HAT, port `/dev/ttyAMA0`) |

### Motor Controller (`roles/motor-controller`)
| Component | Purpose |
|-----------|---------|
| Sangaboard v0.5.5 | RP2040 HAT, firmware v1.0.4 (`Sangaboard Firmware v1.0.4`) |
| 28BYJ-48 driver | Stepper motor control (3× X/Y/Z) |
| UART | Pi GPIO 14/15 (RP1 UART0 → `/dev/ttyAMA0`) |

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

### Manual Exposure & White Balance (black-frame fix)

OpenFlexure runs the camera with **manual exposure** (`AeEnable: False`, `AwbEnable: False`,
see `things/camera/picamera.py` → `_get_persistent_controls()`). The defaults (500 µs exposure,
gain 1.0, colour gains 1.0/1.0) produce black frames in a dark microscope field. The working
values were set via the REST API (persisted in `/var/openflexure/settings/camera/*.json`):

```bash
curl -X PUT http://localhost:5000/camera/exposure_time -H "Content-Type: application/json" -d '20000'
curl -X PUT http://localhost:5000/camera/analogue_gain -H "Content-Type: application/json" -d '1.5'
curl -X PUT http://localhost:5000/camera/colour_gains  -H "Content-Type: application/json" -d '[1.4, 2.3]'
```

| Setting | Value | Note |
|---------|-------|------|
| exposure_time | 20000 µs | ~40× the default; starting point for current scene |
| analogue_gain | 1.5 | |
| colour_gains | (1.4, 2.3) | calibrated for neutral grey on current illumination |

Values survive `systemctl restart openflexure`. For a properly calibrated setup, run the
**Full Auto-Calibrate** wizard in the UI (LED illumination on, empty field of view) instead —
it calls `auto_expose_from_minimum`, `calibrate_lens_shading`, etc.

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
        "stage": {
            "class": "openflexure_microscope_server.things.stage.sangaboard:SangaboardThing",
            "kwargs": {
                "port": "/dev/ttyAMA0"
            }
        },
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

The stage runs as `SangaboardThing` on `/dev/ttyAMA0` (Pi GPIO 14/15 = RP1 UART0). Wiring/software setup is
described in [Sangaboard v0.5 HAT](#sangaboard-v05-hat--gpio-uart-setup) below.

## Sangaboard v0.5 HAT — GPIO UART setup

The Sangaboard v0.5 is an RP2040 HAT that talks to the Pi over the GPIO header UART (pins 14/15).
The RP1 UART0 is **disabled by default** on this CM5 (`status = disabled` in the device tree), so it must
be enabled explicitly — otherwise the board never responds (`OSError: The instrument doesn't seem to be responding`).

Applied on the microscope (all in place):

1. **Enable RP1 UART0** — `/boot/firmware/config.txt` (`[all]` section):
   ```
   dtoverlay=uart0-pi5
   ```
   After reboot this exposes GPIO 14/15 as `/dev/ttyAMA0`.

2. **Serial permissions** — `/etc/udev/rules.d/99-sangaboard.rules` (reload with `udevadm control --reload-rules && udevadm trigger`):
   ```
   KERNEL=="ttyAMA0", GROUP="dialout", MODE="0660"
   KERNEL=="ttyAMA10", GROUP="dialout", MODE="0660"
   ```

3. **Free the UARTs from console/getty** — the SoC console UART (`ttyAMA10`) does **not** carry the Sangaboard;
   `serial-getty@ttyAMA10` is masked so a login shell can never interfere:
   ```
   sudo systemctl mask serial-getty@ttyAMA10
   ```

4. **OpenFlexure stage** — `/var/openflexure/settings/ofm_config.json`:
   ```json
   "stage": {
       "class": "openflexure_microscope_server.things.stage.sangaboard:SangaboardThing",
       "kwargs": {
           "port": "/dev/ttyAMA0"
       }
   }
   ```

5. **Restart and verify**:
   ```bash
   sudo systemctl restart openflexure
   curl -s http://localhost:5000/stage/position     # {"x":0,"y":0,"z":0}
   curl -s -X POST -H "Content-Type: application/json" -d '{"z": 200}' \
       http://localhost:5000/stage/move_relative    # axis name is the key, value = steps
   curl -s http://localhost:5000/stage/position     # position updates after the move
   ```

Direct Sangaboard test:
```bash
/opt/openflexure/venv/bin/python -c "
import sangaboard
sb = sangaboard.Sangaboard(port='/dev/ttyAMA0')
print(sb.firmware)      # Sangaboard Firmware v1.0.4
print(sb.query('board')) # Sangaboard v0.5.5
sb.close()
"
```

Note: the motor moves are non-blocking actions in the REST API — `move_relative` returns a
`pending` action with an `id`; poll `/action_invocations/<id>` for completion and
`/stage/moving` for motor state.

Then: `ansible-playbook site.yml --tags openflexure && ssh lab@mesoscope.local 'sudo systemctl restart openflexure'`

## API Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /camera/` | Camera status |
| `PUT /camera/exposure_time` | Set exposure time (µs) |
| `PUT /camera/analogue_gain` | Set analogue gain |
| `PUT /camera/colour_gains` | Set colour gains (AWB) |
| `POST /camera/capture_jpeg` | Capture still image |
| `POST /camera/lores_mjpeg_stream/start` | Start MJPEG stream |
| `POST /camera/lores_mjpeg_stream/stop` | Stop stream |
| `GET /stage/position` | Stage position (x/y/z in steps) |
| `POST /stage/move_relative` | Relative move, body `{"<axis>": <steps>}` |
| `POST /stage/move_absolute` | Absolute move, body `{"<axis>": <steps>}` |
| `POST /stage/jog` | Continuous jog while held |
| `GET /stage/moving` | Whether a move is in progress |
| `GET /action_invocations/<id>` | Poll result of a pending action |

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