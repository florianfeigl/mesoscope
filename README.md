# CELLAIR: CELL Analysis with Intelligent Recognition

## Working title: mesoscope

## Roadmap

### Phase 1: Infrastructure & Base Setup
- [x] **Hardware Setup (Raspberry Pi 5)**
    - [x] Install Raspberry Pi OS (Trixie, Python 3.13)
    - [x] Configure AI HAT (26 TOPS) drivers and dependencies
    - [x] Configure Pi HQ Camera (IMX477) integration
    - [ ] Configure RTC Module (DS3231) -- hardware not yet connected
- [x] **Ansible Configuration**
    - [x] Create Ansible Playbook/Role for base system setup
    - [x] Create Ansible Role for AI HAT & Camera (`rpicam-apps`, `hailo-all`, `python3-picamera2`)
    - [x] Create Ansible Role for OpenFlexure dependencies

### Phase 2: Application Layer (OpenFlexure Porting)
- [x] Port OpenFlexure Server (v3, 3.0.0-alpha4) to RPi5/Trixie (Python 3.13)
    - [x] Switch from legacy `master` branch (Python 3.7/Flask) to `v3` branch (Python >= 3.11/FastAPI)
    - [x] Resolve build dependencies (`libcap-dev`, `rpicam-apps` replacing `libcamera-apps`)
    - [x] Deploy configuration (`ofm_config.json`) with HQ Camera and DummyStage
    - [x] Download and integrate web app frontend from GitLab CI artifacts
    - [x] Verify server starts, web UI accessible on port 5000
- [x] Fix Pi 5 pisp ISP compatibility (vc4 tuning files incompatible with Pi 5 ISP)
- [x] Fix pipewire camera device conflict (pipewire holds /dev/media* preventing picamera2 access)
- [x] Fix systemd SupplementaryGroups for camera access (video, render)
- [x] Fix DKMS kernel module build ordering (reboot between apt upgrade and modprobe)
- [ ] Fix camera black frame issue (ISP auto-exposure not active without tuning file)
- [ ] Create software list for OpenFlexure Suite
- [ ] Validate Autofocus with motorised stage

### Phase 3: HQ Camera (IMX477) Integration
> **Note:** The primary microscope camera is the Pi HQ Camera (IMX477, C-mount).
> OpenFlexure v3 supports the IMX477 natively via picamera2. A custom optics module
> with a 125-150mm tube lens is required to properly fill the larger IMX477 sensor
> (see `hardware/optics/OPTICS_MODULE.md`).

- [x] Deploy OpenFlexure with HQ Camera (IMX477) configuration
- [x] Test live preview via OpenFlexure web UI
- [x] Verify Hailo-8 NPU inference (see test results below)
- [x] Design and 3D-print custom optics module for IMX477 + 125-150mm tube lens (STLs generated)
- [ ] Assemble optics module with tube lens and IMX477
- [ ] Validate autofocus with motorised stage

### Phase 4: Integration Testing
- [x] **Hardware Verification**
    - [x] Hailo-8 AI Processor detected on PCIe (`lspci`)
    - [x] Pi HQ Camera (IMX477) detected: 4056x3040 @10fps / 2028x1520 @30fps
    - [x] I2C buses operational (bus 1, 6, 10, 13, 14)
    - [x] Hostname, timezone, NTP synchronization confirmed
- [x] **OpenFlexure Server**
    - [x] Server starts and responds on HTTP (port 5000)
    - [x] Web UI accessible
    - [x] HQ Camera (IMX477) initialised and streaming
    - [ ] Fix camera black frame issue (ISP auto-exposure without tuning file)
    - [ ] Test stage control via sangaboard (if connected)
    - [ ] Verify smart scan and autofocus functionality
- [x] **AI Inference (Hailo-8 NPU)**
    - [x] Hailo-8 NPU firmware verified: v4.23.0, Hailo-8 architecture
    - [x] DKMS driver build automated in Ansible (`hailo_pci` kernel module)
    - [x] Hailo-8 NPU inference verified (YOLOv8s Pose, 91.5 inf/s, 10.9ms latency)
    - [x] Benchmark complete (see Inference Test Results section)
- [x] **System Stability (post-reboot verification 2026-03-04)**
    - [x] RTC (DS3231) keeps time across reboots (`hwclock -r` confirmed)
    - [x] Hailo PCIe driver loads automatically on boot (`hailo_pci` module, `/dev/hailo0`)
    - [x] OpenFlexure service starts on boot, camera streaming active
    - [x] HQ Camera (IMX477) detected after reboot
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

> **Optics design:** See [`hardware/optics/OPTICS_MODULE.md`](hardware/optics/OPTICS_MODULE.md)
> for the full optical calculation — tube lens selection, sensor-to-lens distance,
> C-mount offset, and printed module dimensions for the IMX477 + scraped ≤10x objective.

- [ ] **Hardware Procurement**
    - [x] Pi HQ Camera (IMX477, C-mount) -- acquired, currently mounted on conventional microscope
    - [x] Scraped objective ≤10x (finite conjugate 160 mm) -- sourced from existing microscopes
    - [x] Tube lens 125 mm + 150 mm achromatic doublet (12.7mm dia) — acquired 2026-06-20
    - [ ] Sangaboard v0.5 motor controller
    - [ ] 3x 28BYJ-48 stepper motors -- acquired
- [ ] **3D Printing**
    - [x] Verify objective type (160 mm finite conjugate) and parfocal distance (see OPTICS_MODULE.md)
    - [x] Clone OpenFlexure repo (`hq_camera` branch) and set `CAMERA = "picamera_hq"` + tube lens params
    - [x] Generate custom optics module STLs with OpenSCAD (125mm and 150mm variants)
    - [ ] Print all parts (see `hardware/PRINT_CHECKLIST.md`)
    - [ ] Assemble optics module with tube lens and IMX477
- [ ] **Assembly & Calibration**
    - [ ] Assemble OpenFlexure with HQ Camera + scraped objective
    - [ ] Integrate with Ansible-deployed software stack
    - [ ] Calibrate flat-field correction and lens shading
    - [ ] Test motorised stage control via OpenFlexure web UI

## Bill of Materials

### Computing & AI
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| Raspberry Pi 5 (8GB) | Main computing unit | ~80 EUR | Acquired |
| AI HAT+ (Hailo-8, 26 TOPS) | PCIe NPU for heavy inference (segmentation, YOLOv8) | ~70 EUR | Acquired |
| DS3231 RTC Module | Battery-backed real-time clock | ~5 EUR | Acquired |
| GPIO Stacking Header | Pass-through for RTC under AI HAT | ~3 EUR | Acquired |
| MicroSD Card (32GB+) | OS and software storage | ~10 EUR | Acquired |
| USB-C Power Supply (27W) | Official RPi5 PSU | ~15 EUR | Acquired |

### Optics & Microscopy
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| Pi HQ Camera (IMX477) | C-mount, 12.3 MP sensor -- **primary microscopy camera** | ~35 EUR | Acquired |
| Scraped ≤10x objective | Finite conjugate 160 mm, sourced from existing microscopes | ~0 EUR | Acquired |
| Tube lens (125 mm + 150 mm) | Achromatic doublet, 12.7 mm dia | ~15-80 EUR | **Acquired** |
| 20x RMS Plan Achromat (0.40 NA) | Cell tracking, movement patterns (~0.7 µm resolution) | ~25-80 EUR | Pending |
| 40x RMS Plan Achromat (0.65 NA) | Subcellular detail, calcification (optional) | ~25-80 EUR | Optional |

### Motorised Stage
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| Arduino Nano (ATmega328p) | Sangaboard-compatible controller (DIY workaround) | ~5 EUR | Pending |
| 3x ULN2003 Driver Boards | Unipolar stepper drivers (usually bundled with motors) | ~3 EUR | Pending |
| 3x 28BYJ-48 Stepper Motors | 5V unipolar geared steppers (OpenFlexure standard) | ~5 EUR | Acquired |
| Jumper Wires (19x) | Wiring between Nano and ULN2003 boards | ~3 EUR | Pending |
| USB Cable (Mini-B) | Power + serial between RPi5 and Arduino Nano | ~3 EUR | Pending |

> **Alternative:** Sangaboard v0.3 PCB (~30-40 EUR if available from OpenFlexure vendors).
> The DIY workaround uses the same firmware and is fully compatible.

### 3D Printed Parts
| Component | Description | Est. Price | Status |
|-----------|-------------|-----------|--------|
| OpenFlexure Microscope Body | Main structure with flexure stage | ~5 EUR filament | Ready to print |
| Optics Module (HQ Camera, 150mm) | Holds objective + HQ Camera + 150mm tube lens | ~2 EUR filament | STL generated |
| Optics Module (HQ Camera, 125mm) | Holds objective + HQ Camera + 125mm tube lens | ~2 EUR filament | STL generated |
| Illumination Module | LED illumination (transmission) | ~2 EUR filament | Ready to print |

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

## System Architecture

```
                          CELLAIR / MESOSCOPE SYSTEM
═══════════════════════════════════════════════════════════════════════════════

                    ┌─────────────────────────────────────┐
                    │         Raspberry Pi 5 (8GB)        │
                    │   ┌─────────────┐  ┌─────────────┐  │
                    │   │  OFM Server │  │ AI HAT+     │  │
                    │   │   (FastAPI) │  │ Hailo-8     │  │
                    │   └─────────────┘  │ 26 TOPS     │  │
                    │                    └─────────────┘  │
                    └──────────────┬──────────────────────┘
                                   │ CSI
                    ┌──────────────▼──────────────────────┐
                    │      HQ Camera (IMX477, 12MP)       │
                    │      C-Mount │ 150mm Achromat       │
                    │      10x/0.25 Objektiv              │
                    └──────────────┬──────────────────────┘
                                   │
                    ┌──────────────▼──────────────────────┐
                    │     OpenFlexure Microscope Body     │
                    │     Sangaboard v5 + 3× 28BYJ-48    │
                    │     XYZ-Flexure Stage               │
                    └──────────────┬──────────────────────┘
                                   │
                                   │  montiert auf Schlitten
                                   │
═══════════════════════╤═══════════▼══════╤══════════════════════════════════
  Linearschiene        │                  │
  ═════════════════════╪══════════════════╪═════════════════════════════════▶
                        │     ← →         │
                   Antrieb/Motor          │
═══════════════════════╧══════════════════╧══════════════════════════════════
          │                    │                    │
          ▼                    ▼                    ▼
   ┌─────────────┐      ┌─────────────┐      ┌─────────────┐
   │             │      │             │      │             │
   │ {Bioreaktor}│      │ {Bioreaktor}│      │ {Bioreaktor}│
   │             │      │             │      │             │
   │  hFOB 1.19  │      │  hFOB 1.19  │      │  hMEC 1    │
   │  + hMEC 1   │      │  + hMEC 1   │      │  (Kontrolle)│
   │             │      │             │      │             │
   └─────────────┘      └─────────────┘      └─────────────┘
         #1                   #2                   #n
```

Das Mikroskop fährt automatisch entlang der Schiene von Bioreaktor zu Bioreaktor,
nimmt Bilder auf, und der Hailo-8 läuft on-device Inferenz (Zellzählung,
Konfluenz, Segmentierung) — ohne externe Recheninfrastruktur.

### HQ Camera (IMX477) -- Microscopy

The Pi HQ Camera with C-mount and RMS objectives provides cell-level resolution:

| Objective | Resolution | Use Case |
|-----------|-----------|----------|
| ≤10x / ≤0.25 NA | ~1.3 µm | Overview, colony counting |
| 20x / 0.40 NA | ~0.7 µm | Cell tracking, movement patterns |
| 40x / 0.65 NA | ~0.4 µm | Subcellular detail, calcification |

The custom 125-150mm tube lens (vs. standard 50mm) fills the larger IMX477 sensor
(7.86×5.89 mm vs. 3.68×2.76 mm for Pi Camera v2), achieving ~85-95% sensor utilization.
See [`hardware/optics/OPTICS_MODULE.md`](hardware/optics/OPTICS_MODULE.md) for details.

### Hailo-8 NPU -- Inference

The Hailo-8 AI HAT runs compiled HEF models for real-time cell segmentation at the microscope:

- **YOLOv8s-seg**: Cell segmentation (osteoblast, epithelial, calcium classes)
- **ByteTrack**: Cell tracking for migration velocity and calcium proximity analysis
- **Throughput**: 91.5 inf/s at 10.9ms latency (YOLOv8s Pose benchmark)

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

# Camera (HQ Camera IMX477)
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
| Camera | `imx477` detected, 4056x3040 / 2028x1520 |
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
| Hardware        | RPi5, AI HAT 26 TOPS, HQ Camera IMX477 |

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
git clone git@github.com:florianfeigl/mesoscope.git
cd mesoscope/ansible
ansible-playbook site.yml --skip-tags motor-controller -v -K
```

> **Note:** The `motor-controller` tag is skipped until Sangaboard hardware is connected.
> The playbook includes Pi 5 compatibility patches (pisp ISP tuning, pipewire masking, etc.)
> applied automatically via the `patch_rpi5_pisp.sh` script.

### Step 4: Verify
Access OpenFlexure at `http://mesoscope.local:5000/`

### Customization
To use different credentials, update the following files:
- `ansible/inventory/hosts.yml` -- hostname, IP, and SSH user
- `ansible/group_vars/all.yml` -- hostname and application user
- `ansible/ansible.cfg` -- default remote user

## AI Models

### Hailo-8 NPU Models

Pre-installed HEF models at `/usr/share/hailo-models/` (installed via `hailo-models`).
These run on the Hailo-8 NPU (AI HAT, 26 TOPS) via PCIe for real-time cell analysis.

| Model | Task | File |
|-------|------|------|
| YOLOv8s Pose | Pose Estimation | `yolov8s_pose_h8.hef` |
| YOLOv5n Segmentation | Segmentation | `yolov5n_seg_h8.hef` |
| YOLOv5s PersonFace | Detection | `yolov5s_personface_h8l.hef` |
| SCRFD 2.5G | Face Detection | `scrfd_2.5g_h8l.hef` |

> See `ls /usr/share/hailo-models/` for the full list (18 models).
> The custom cellseg model (YOLOv8s-seg fine-tuned on osteoblast/epithelial/calcium classes)
> will be compiled to HEF and deployed at `model/models/compiled/cellseg.hef`.

## Inference Test Results

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
HQ Camera (IMX477) --> picamera2 streams (OpenFlexure UI)
                         |
                         v
Captured Frame --> Hailo-8 NPU (PCIe, 26 TOPS) --> Output tensors
                    Heavy: segmentation, pose estimation, custom HEF models
## Notes
- **Meetings:** Jour fixe is usually Tuesday 10:00 AM.

### Suppliers
- Praxisdienst: [https://www.praxisdienst.com/de-de]
- FluidControl: [https://www.fluidcontrolproducts.com/]
