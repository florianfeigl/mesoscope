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
    - [x] Deploy configuration (`ofm_config.json`) with picamera2 and DummyStage
- [ ] Create software list for OpenFlexure Suite
- [ ] Validate Autofocus with AI Cam (investigate OpenFlexure compatibility)

### Phase 3: Integration Testing
- [x] **Hardware Verification**
    - [x] Hailo-8 AI Processor detected on PCIe (`lspci`)
    - [x] AI Camera (IMX500) detected: 4056x3040 @10fps / 2028x1520 @30fps
    - [x] I2C buses operational (bus 1, 6, 10, 13, 14)
    - [x] Hostname, timezone, NTP synchronization confirmed
- [ ] **OpenFlexure Server**
    - [ ] Verify server starts and responds on HTTP (port 5000)
    - [ ] Test picamera2 integration (camera capture, live preview)
    - [ ] Test stage control via sangaboard (if connected)
    - [ ] Verify smart scan and autofocus functionality
- [ ] **AI HAT Inference**
    - [ ] Verify Hailo NPU firmware (`hailortcli fw-control identify`)
    - [ ] Run inference test with AI Camera (IMX500)
    - [ ] Benchmark inference performance (27 TOPS expected)
- [ ] **System Stability**
    - [ ] Verify RTC keeps time across reboots (pending hardware connection)
    - [ ] Test OpenFlexure systemd service (start, stop, restart, auto-recovery)
    - [ ] Monitor resource usage under load (CPU, RAM, temperature)

### Phase 4: Research & Experimentation
- [ ] **Incubator Setup (37C)**
    - [ ] Design separation of computing unit (outside) and camera (inside)
- [ ] **Experiments**
    - [ ] Acquire PFA-fixed chip preparations
    - [ ] Analyze significant movement pattern changes in cells during calcification
    - [ ] Investigate influence of pressure changes on calcification [in progress]
    - [ ] Test series: Test different medium flow rates [in progress]

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

## Notes
- **Branding:** "Mesoscopy"? (Dr. Lepperdinger's suggestion)
- **Repository Strategy:** "AG Lepperdinger" uses GitLab (self-hosted, CS dept, ITS, or personal). GitHub is unlikely.
- **Meetings:** Jour fixe is usually Tuesday 10:00 AM.

### Suppliers
- Praxisdienst: [https://www.praxisdienst.com/de-de]
- FluidControl: [https://www.fluidcontrolproducts.com/]
