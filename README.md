# CELLAIR: CELL Analysis with Intelligent Recognition

## Working title: helena

## Roadmap

### Phase 1: Infrastructure & Base Setup
- [x] **Hardware Setup (Raspberry Pi 5)**
    - [x] Install Raspberry Pi OS (Trixie, Python 3.13)
    - [x] Configure AI HAT (27 TOPS) drivers and dependencies
    - [x] Configure AI Camera (IMX500) integration
    - [x] Configure RTC Module for time persistence
- [x] **Ansible Configuration**
    - [x] Create Ansible Playbook/Role for base system setup
    - [x] Create Ansible Role for AI HAT & Camera
    - [x] Create Ansible Role for OpenFlexure dependencies

### Phase 2: Application Layer (OpenFlexure Porting)
- [x] Port OpenFlexure Server (v3, 3.0.0-alpha4) to RPi5/Trixie (Python 3.13)
- [ ] Create software list for OpenFlexure Suite
- [ ] Validate Autofocus with AI Cam (investigate OpenFlexure compatibility)

### Phase 3: Integration Testing
- [ ] **OpenFlexure Server**
    - [ ] Verify server starts and responds on HTTP
    - [ ] Test picamera2 integration (camera capture, live preview)
    - [ ] Test stage control via sangaboard (if connected)
    - [ ] Verify smart scan and autofocus functionality
- [ ] **AI HAT + Camera**
    - [ ] Verify Hailo NPU is detected (`hailortcli fw-control identify`)
    - [ ] Run inference test with AI Camera (IMX500)
    - [ ] Benchmark inference performance (27 TOPS expected)
- [ ] **System Stability**
    - [ ] Verify RTC keeps time across reboots
    - [ ] Test OpenFlexure systemd service (start, stop, restart, auto-recovery)
    - [ ] Monitor resource usage under load (CPU, RAM, temperature)

### Phase 4: Research & Experimentation
- [ ] **Incubator Setup (37°C)**
    - [ ] Design separation of computing unit (outside) and camera (inside)
- [ ] **Experiments**
    - [ ] Acquire PFA-fixed chip preparations
    - [ ] Analyze significant movement pattern changes in cells during calcification
    - [ ] Investigate influence of pressure changes on calcification [in progress]
    - [ ] Test series: Test different medium flow rates [in progress]

## Deployment Prerequisites (Client Side)
To deploy the configuration to the Raspberry Pi 5, the following software is required on your control machine (laptop/desktop):

- **Ansible** (>= 2.10)
  - Used to automate the setup and configuration of the Raspberry Pi.
- **Python 3**
  - Required to run Ansible.
- **SSH Client** (e.g., OpenSSH)
  - Required for Ansible to communicate with the Raspberry Pi.
- **Git**
  - To clone this repository.

### Quick Start
1. Clone the repository:
   ```bash
   git clone <repository_url>
   cd cellair/ansible
   ```
2. Update the inventory file (`inventory/hosts.yml`) with your Pi's IP address and SSH user.
3. Run the playbook:
   ```bash
   ansible-playbook site.yml
   ```

## Notes
- **Branding:** "Mesoscopy"? (Dr. Lepperdinger's suggestion)
- **Repository Strategy:** "AG Lepperdinger" uses GitLab (self-hosted, CS dept, ITS, or personal). GitHub is unlikely.
- **Meetings:** Jour fixe is usually Tuesday 10:00 AM.

### Suppliers
- Praxisdienst: [https://www.praxisdienst.com/de-de]
- FluidControl: [https://www.fluidcontrolproducts.com/]
