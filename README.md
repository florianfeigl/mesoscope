# CELLAIR: CELL Analysis with Intelligent Recognition

## Working title: mesoscope

## Roadmap

### Phase 1: Infrastructure & Base Setup
- [x] **Hardware Setup (Raspberry Pi 5)**
    - [x] Install Raspberry Pi OS (Trixie, Python 3.13)
    - [x] Configure AI HAT (27 TOPS) drivers and dependencies
    - [x] Configure AI Camera (IMX500) integration
    - [ ] Configure RTC Module (DS3231) -- hardware not yet connected
- [x] **Ansible Configuration**
    - [x] Create Ansible Playbook/Role for base system setup
    - [x] Create Ansible Role for AI HAT & Camera (`rpicam-apps`, `hailo-all`, `python3-picamera2`)
    - [x] Create Ansible Role for OpenFlexure dependencies

### Phase 2: Application Layer (OpenFlexure Porting)
- [x] Port OpenFlexure Server (v3, 3.0.0-alpha4) to RPi5/Trixie (Python 3.13)
    - [x] Switch from legacy `master` branch (Python 3.7/Flask) to `v3` branch (Python >= 3.11/FastAPI)
    - [x] Resolve build dependencies (`libcap-dev`, `rpicam-apps` replacing `libcamera-apps`)
    - [x] Deploy configuration (`ofm_config.json`) with SimulatedCamera and DummyStage
    - [x] Download and integrate web app frontend from GitLab CI artifacts
    - [x] Verify server starts, web UI accessible on port 5000
- [ ] Create software list for OpenFlexure Suite
- [ ] Validate Autofocus with AI Cam (investigate OpenFlexure compatibility)

### Phase 3: IMX500 Camera Integration
> **Finding:** OpenFlexure v3 only supports IMX219 (Pi Camera v2) and IMX477 (Pi HQ Camera).
> The IMX500 (AI Camera) is not supported. A custom `IMX500Camera` Thing class was written
> to bridge the IMX500 into OpenFlexure's camera interface, bypassing the tuning file system entirely.

- [x] Write custom `IMX500Camera` Thing class for OpenFlexure (`ansible/roles/openflexure/files/imx500_camera.py`)
- [x] Bypass tuning file system (IMX500 uses auto-exposure/auto-white-balance natively)
- [x] Deploy and verify server starts with IMX500 camera
- [x] Test live preview via OpenFlexure web UI
- [x] Verify IMX500 on-sensor inference (see test results below)
- [x] Verify Hailo-8 NPU inference (see test results below)
- [ ] Validate autofocus with IMX500

### Phase 4: Integration Testing
- [x] **Hardware Verification**
    - [x] Hailo-8 AI Processor detected on PCIe (`lspci`)
    - [x] AI Camera (IMX500) detected: 4056x3040 @10fps / 2028x1520 @30fps
    - [x] I2C buses operational (bus 1, 6, 10, 13, 14)
    - [x] Hostname, timezone, NTP synchronization confirmed
- [x] **OpenFlexure Server**
    - [x] Server starts and responds on HTTP (port 5000)
    - [x] Web UI accessible
    - [x] IMX500 camera initialised and streaming
    - [ ] Test stage control via sangaboard (if connected)
    - [ ] Verify smart scan and autofocus functionality
- [x] **AI Inference (dual NPU)**
    - [x] Hailo-8 NPU firmware verified: v4.23.0, Hailo-8 architecture
    - [x] DKMS driver build automated in Ansible (`hailo_pci` kernel module)
    - [x] IMX500 on-sensor inference verified (MobileNet V2, 15.1 inf/s, 4.5ms DNN latency)
    - [x] Hailo-8 NPU inference verified (YOLOv8s Pose, 91.5 inf/s, 10.9ms latency)
    - [x] Benchmark complete (see Inference Test Results section)
- [x] **System Stability (post-reboot verification 2026-03-04)**
    - [x] RTC (DS3231) keeps time across reboots (`hwclock -r` confirmed)
    - [x] Hailo PCIe driver loads automatically on boot (`hailo_pci` module, `/dev/hailo0`)
    - [x] OpenFlexure service starts on boot, camera streaming active
    - [x] IMX500 camera detected after reboot
    - [x] Resource usage under load (see below)

#### Resource Profile (idle with camera streaming)
| Resource | Value |
|----------|-------|
| CPU | 4 cores, load avg 0.71 (OpenFlexure ~63% of one core) |
| RAM | 762 MB used / 15 GB total (5% utilisation) |
| Temperature | 48.3C |
| Disk | 11 GB used / 117 GB total (10%) |
| Swap | 0 B used |

### Phase 5: OpenFlexure Microscope Build
- [ ] **Hardware Procurement**
    - [ ] Pi HQ Camera (IMX477, C-mount)
    - [ ] 20x RMS Plan Achromat objective (0.40 NA, ~0.7 µm resolution) -- cell tracking, movement patterns
    - [ ] 40x RMS Plan Achromat objective (0.65 NA) -- subcellular detail, calcification analysis (optional, add later if needed)
    - [ ] Stepper motors for motorised stage
    - [ ] Sangaboard motor controller (or Arduino alternative)
- [ ] **3D Printing**
    - [ ] Print OpenFlexure microscope body, stage, and optics module
- [ ] **Assembly & Calibration**
    - [ ] Assemble OpenFlexure with HQ Camera + 20x objective
    - [ ] Integrate with Ansible-deployed software stack
    - [ ] Calibrate flat-field correction and lens shading
    - [ ] Test motorised stage control via OpenFlexure web UI

## Bill of Materials

### Computing & AI
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| Raspberry Pi 5 (8GB) | Main computing unit | ~80 EUR | Acquired |
| AI HAT (Hailo-8, 27 TOPS) | PCIe NPU for heavy inference | ~70 EUR | Acquired |
| AI Camera (IMX500) | On-sensor NPU, 12.3 MP | ~70 EUR | Acquired |
| DS3231 RTC Module | Battery-backed real-time clock | ~5 EUR | Acquired |
| GPIO Stacking Header | Pass-through for RTC under AI HAT | ~3 EUR | Acquired |
| MicroSD Card (32GB+) | OS and software storage | ~10 EUR | Acquired |
| USB-C Power Supply (27W) | Official RPi5 PSU | ~15 EUR | Acquired |

### Optics & Microscopy
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| Pi HQ Camera (IMX477) | C-mount, 12.3 MP sensor | ~35 EUR | Pending |
| 20x RMS Plan Achromat (0.40 NA) | Cell tracking, movement patterns (~0.7 µm resolution) | ~25-80 EUR | Pending |
| 40x RMS Plan Achromat (0.65 NA) | Subcellular detail, calcification (optional) | ~25-80 EUR | Optional |

### Motorised Stage
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| Arduino Nano (ATmega328p) | Sangaboard-compatible controller (DIY workaround) | ~5 EUR | Pending |
| 3x ULN2003 Driver Boards | Unipolar stepper drivers (usually bundled with motors) | ~3 EUR | Pending |
| 3x 28BYJ-48 Stepper Motors | 5V unipolar geared steppers (OpenFlexure standard) | ~5 EUR | Pending |
| Jumper Wires (19x) | Wiring between Nano and ULN2003 boards | ~3 EUR | Pending |
| USB Cable (Mini-B) | Power + serial between RPi5 and Arduino Nano | ~3 EUR | Pending |

> **Alternative:** Sangaboard v0.3 PCB (~30-40 EUR if available from OpenFlexure vendors).
> The DIY workaround uses the same firmware and is fully compatible.

### 3D Printed Parts
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| OpenFlexure Microscope Body | Main structure with flexure stage | ~5 EUR filament | Pending |
| Optics Module (HQ Camera) | Holds objective + camera | ~2 EUR filament | Pending |
| Illumination Module | LED illumination (transmission) | ~2 EUR filament | Pending |

### Consumables & Misc
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| M3 Screws/Nuts (assorted) | Assembly hardware | ~5 EUR | Pending |
| LED + Resistor | Sample illumination | ~2 EUR | Pending |
| Viton O-rings | Flexure preload (check OpenFlexure BOM) | ~3 EUR | Pending |

> **Estimated total (remaining):** ~110-170 EUR (depending on objective choice)

### Phase 6: Research & Experimentation
- [ ] **Incubator Setup (37C)**
    - [ ] Design separation of computing unit (outside) and camera (inside)
    - [ ] Inverted geometry: objective below, sample on top (OpenFlexure default)
- [ ] **Experiments**
    - [ ] Acquire PFA-fixed chip preparations
    - [ ] Analyze significant movement pattern changes in cells during calcification
    - [ ] Investigate influence of pressure changes on calcification [in progress]
    - [ ] Test series: Test different medium flow rates [in progress]

## Post-Deployment Verification

Run the following after a fresh boot to verify all subsystems:

```bash
# System basics
hostname && timedatectl

# RTC
sudo hwclock -r

# I2C - RTC at 0x68
sudo i2cdetect -y 1

# Hailo NPU
lsmod | grep hailo
ls /dev/hailo*
hailortcli fw-control identify

# Camera
rpicam-hello --list-cameras

# OpenFlexure
sudo systemctl status openflexure

# HTTP
curl -s http://localhost:5000/ | head -5
```

### Expected Results
| Check | Expected |
|-------|----------|
| Hostname | `mesoscope` |
| Timezone | `Europe/Berlin`, NTP synced |
| RTC | Current time, matches system clock |
| I2C bus 1 | `UU` at address `0x68` (DS3231) |
| Hailo module | `hailo_pci` loaded, `/dev/hailo0` present |
| Hailo firmware | v4.23.0, Hailo-8 architecture |
| Camera | `imx500` detected, 4056x3040 / 2028x1520 |
| OpenFlexure | `active (running)`, enabled on boot |
| HTTP | HTML response on port 5000 |

## Deployment

### Prerequisites (Client Side)
- **Ansible** (>= 2.10)
- **Python 3**
- **SSH Client** (e.g., OpenSSH)
- **Git**

### Target System Defaults
| Component       | Value                                |
|-----------------|--------------------------------------|
| Hostname        | `mesoscope`                          |
| Provision User  | `lab`                                |
| OS              | Raspberry Pi OS (Trixie)             |
| Python          | 3.13                                 |
| Hardware        | RPi5, AI HAT 27 TOPS, AI Cam IMX500 |

### Step 1: Flash the SD Card
1. Download and install [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Select **Raspberry Pi OS (64-bit, Trixie)** as the operating system.
3. Click the **settings icon** (gear) and configure:
   - **Hostname:** `mesoscope`
   - **Username:** `lab`
   - **Password:** (choose a secure password)
   - **Enable SSH:** select "Allow public-key authentication only" and paste your public key (e.g., contents of `~/.ssh/id_ed25519.pub`)
   - **Timezone:** `Europe/Berlin`
   - **WiFi:** configure if not using Ethernet
4. Flash the SD card and insert it into the Raspberry Pi 5.

### Step 2: Verify SSH Connection
After the Pi has booted (allow ~1-2 minutes for first boot):
```bash
ssh lab@mesoscope.local
```

### Step 3: Run the Ansible Playbook
```bash
git clone <repository_url>
cd cellair/ansible
ansible-playbook site.yml
```

### Step 4: Verify
Access OpenFlexure at `http://mesoscope.local:5000/`

### Customization
To use different credentials, update the following files:
- `ansible/inventory/hosts.yml` -- hostname, IP, and SSH user
- `ansible/group_vars/all.yml` -- hostname and application user
- `ansible/ansible.cfg` -- default remote user

## IMX500 AI Models

The following pre-installed models are available at `/usr/share/imx500-models/` (installed via `imx500-all`).
The active model is configured in `ofm_config.json` via the `model_path` kwarg.

| Model | Task | File |
|-------|------|------|
| MobileNet V2 | Classification | `imx500_network_mobilenet_v2.rpk` |
| EfficientNet-Lite0 | Classification | `imx500_network_efficientnet_lite0.rpk` |
| EfficientNet B0 | Classification | `imx500_network_efficientnet_bo.rpk` |
| EfficientNetV2 B0/B1/B2 | Classification | `imx500_network_efficientnetv2_b{0,1,2}.rpk` |
| ResNet-18 | Classification | `imx500_network_resnet18.rpk` |
| MobileViT XS/XXS | Classification | `imx500_network_mobilevit_{xs,xxs}.rpk` |
| MNASNet 1.0 | Classification | `imx500_network_mnasnet1.0.rpk` |
| ShuffleNet V2 x1.5 | Classification | `imx500_network_shufflenet_v2_x1_5.rpk` |
| SqueezeNet 1.0 | Classification | `imx500_network_squeezenet1.0.rpk` |
| RegNetX/Y | Classification | `imx500_network_regnet{x,y}_00{2,4}.rpk` |
| SSD MobileNetV2 FPNLite | Object Detection | `imx500_network_ssd_mobilenetv2_fpnlite_320x320_pp.rpk` |
| EfficientDet-Lite0 | Object Detection | `imx500_network_efficientdet_lite0_pp.rpk` |
| NanoDet Plus 416x416 | Object Detection | `imx500_network_nanodet_plus_416x416{,_pp}.rpk` |
| DeepLabV3+ | Segmentation | `imx500_network_deeplabv3plus.rpk` |
| HigherHRNet COCO | Pose Estimation | `imx500_network_higherhrnet_coco.rpk` |
| PoseNet | Pose Estimation | `imx500_network_posenet.rpk` |

> **Current default:** `imx500_network_mobilenet_v2.rpk` (lightweight, good for testing)

## Hailo-8 AI Models

Pre-installed HEF models are available at `/usr/share/hailo-models/` (installed via `hailo-models`).
These run on the Hailo-8 NPU (AI HAT, 27 TOPS) via PCIe, separate from the IMX500 on-sensor NPU.

| Model | Task | File |
|-------|------|------|
| YOLOv8s Pose | Pose Estimation | `yolov8s_pose_h8.hef` |
| YOLOv5n Segmentation | Segmentation | `yolov5n_seg_h8.hef` |
| YOLOv5s PersonFace | Detection | `yolov5s_personface_h8l.hef` |
| SCRFD 2.5G | Face Detection | `scrfd_2.5g_h8l.hef` |

> See `ls /usr/share/hailo-models/` for the full list (18 models).

## Inference Test Results

### IMX500 On-Sensor NPU (tested 2026-03-03)
```
Model: MobileNet V2 (imx500_network_mobilenet_v2.rpk)
Input size: 224x224
Output: Tensor 0: shape=(1, 1000)
Throughput: 15.1 inferences/sec
DNN latency: 4.5ms avg
DSP latency: 3.8ms avg
```

### Hailo-8 NPU via PCIe (tested 2026-03-03)
```
Firmware: v4.23.0 (release, app, extended context switch buffer)
Device: /dev/hailo0 on PCIe bus 0001:01:00.0
Model: YOLOv8s Pose (yolov8s_pose_h8.hef)
Input: 640x640x3
Output: 9 tensors (multi-scale detection + keypoints)
Throughput: 91.5 inferences/sec
Latency: 10.9ms avg
```

### Architecture
```
IMX500 Sensor ──> Image pixels ──> ISP ──> picamera2 streams (OpenFlexure UI)
     |
     └──> On-sensor NPU ──> Output tensors (per-frame metadata)
                              Lightweight: classification, simple detection

Captured Frame ──> Hailo-8 NPU (PCIe, 27 TOPS) ──> Output tensors
                              Heavy: segmentation, pose estimation, custom models
```

## Notes
- **Branding:** "Mesoscopy"? (Dr. Lepperdinger's suggestion)
- **Repository Strategy:** "AG Lepperdinger" uses GitLab (self-hosted, CS dept, ITS, or personal). GitHub is unlikely.
- **Meetings:** Jour fixe is usually Tuesday 10:00 AM.

### Suppliers
- Praxisdienst: [https://www.praxisdienst.com/de-de]
- FluidControl: [https://www.fluidcontrolproducts.com/]
