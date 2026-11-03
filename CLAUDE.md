# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

The **mesoscope** project (formerly "CELLAIR"; the instrument model is named **IDANA**) is a
**hardware + infrastructure** project, not a conventional software application. It builds an
automated cell-imaging microscope from a Raspberry Pi 5 (AI HAT+ / Hailo-8 NPU + HQ Camera
IMX477) running the OpenFlexure stack, plus a VPS-hosted CVAT annotation server. The repo has
**no application source of its own** — only Ansible playbooks that deploy upstream software,
OpenSCAD/CAD source for 3D-printed parts, and Markdown docs. There is no build/test/lint step;
CI is a no-op stub (runs pytest only if a `requirements.txt`/`model/` appears — neither exists
yet, both are planned alongside the `.hef`/`.pt` model artifacts).

## Two deployment targets

Deployment is split across two Ansible entry points with **separate inventories**:

- **`ansible/site.yml`** → the Raspberry Pi 5 (`hosts: rpi5`). Roles run in order:
  `base` → `ai-hat` → `openflexure` → `motor-controller`. This is the microscope itself.
- **`ansible/cvat.yml`** and **`ansible/users.yml`** → the VPS (`hosts: vps`, `152.53.16.72`).
  Deploys CVAT (Docker) behind a Caddy reverse proxy with auto-HTTPS at `cvat.feigl.dev`.

The two READMEs differ in scope: `ansible/README.md` covers the **VPS/CVAT** side; the root
`README.md` covers the **Pi 5 microscope** side and the overall project.

## Common commands

### Deploy the Pi 5 microscope
```bash
cd ansible
ansible-playbook site.yml --skip-tags motor-controller -v -K
```
Always skip `motor-controller` until the Sangaboard/Arduino hardware is connected. `-K` prompts
for the sudo password. The playbook reboots the Pi mid-run (Hailo DKMS build, PCIe/camera
config.txt changes) — this is expected.

### Deploy the VPS (CVAT)
```bash
cd ansible
ansible-playbook users.yml -i inventory/hosts.yml   # create cvat service user first
ansible-playbook cvat.yml  -i inventory/hosts.yml
ansible vps -m ping -i inventory/hosts.yml           # connectivity check
```

### Build 3D-printed parts (OpenSCAD)
STLs are written to `hardware/stl/models/`. All scripts take an `OPENSCAD` env var to override
the binary. Most scripts need an upstream OpenFlexure clone (they copy custom `.scad` overrides
into it before rendering); `build_rack.sh` is the exception — **standalone**.
```bash
hardware/optics/openscad/build_optics.sh [125|150|all]   # tube-lens optics module (upstream clone)
hardware/stand/openscad/build_stand.sh                    # Pi5+AI-HAT+Sangaboard stand (upstream clone)
hardware/body/openscad/build_body.sh [mesoscope|original|all]  # Z-focus-only body, no XY stage (upstream clone)
hardware/rails/openscad/build_rack.sh [N]                 # RAILS parametric bioreactor rack (STANDALONE, default N=3)
```
Clone the upstream with:
`git clone --branch hq_camera https://gitlab.com/openflexure/openflexure-microscope.git`.
**Caveat:** the upstream-dependent scripts expect the clone in **different locations** —
`build_optics.sh` in `${HOME}/repositories/openflexure-microscope`; `build_stand.sh` and
`build_body.sh` in `../../../sources/openflexure-microscope` (relative to the script, gitignored).

### Post-deployment verification on the Pi
Use the canonical checklist in the root `README.md` "Post-Deployment Verification" section
(`hailortcli fw-control identify`, `rpicam-hello --list-cameras`, `systemctl status openflexure`,
`curl http://localhost:5000/`, …) after any fresh boot or deploy.

## Architecture notes that span multiple files

- **The Ansible roles encode hard-won Pi 5 fixes**, not just installs — each works around
  specific Pi 5 breakage. Hailo needs a **DKMS rebuild + reboot** ordering (`ai-hat/tasks/main.yml`);
  OpenFlexure needs a **pisp ISP tuning patch** (`openflexure/files/patch_rpi5_pisp.sh`), pipewire
  masking, and systemd `SupplementaryGroups` for camera access. Don't "simplify" these away.

- **OpenFlexure is installed from upstream GitLab, not vendored.** The `openflexure` role clones
  the `v3` branch (FastAPI, Python ≥3.11), uses a `--system-site-packages` venv (to see apt's
  `picamera2`/`libcamera`), and pulls the **web frontend as a prebuilt CI artifact** (GitLab
  project 9238334, `job=build`). No frontend build here.

- **Camera/stage config lives in a Jinja template**, not code: `ofm_config.json.j2` →
  `/var/openflexure/settings/ofm_config.json` (selects HQ Camera + stage: Dummy vs. Sangaboard).
  Changing microscope behavior usually means editing the template + a handler-triggered
  `restart_openflexure`, not editing OpenFlexure itself.

- **The custom OpenSCAD files are overrides layered onto upstream** (e.g. `picamera_hq_cmount.scad`
  replaces upstream `picamera_hq.scad` for the intact C-mount HQ Camera body). Edit the files
  under `hardware/*/openscad/`; the STLs in `hardware/stl/models/` are generated outputs (LFS).

## Conventions & gotchas

- **Global vars:** hostname `mesoscope`, app user `lab`, timezone `Europe/Berlin`
  (`ansible/group_vars/all.yml`). To retarget, edit `inventory/hosts.yml`, `group_vars/all.yml`,
  and `ansible.cfg` together.
- **STL files are Git LFS** (`.gitattributes`). Run `git lfs install` before committing or the
  pointers break (history shows LFS being toggled on/off for this reason).
- **Secrets:** `ansible/group_vars/vault.yml` is gitignored; use Ansible Vault for VPS passwords.
  Never commit unencrypted secrets.
- **Motor controller is a DIY Sangaboard** (Arduino Nano + ULN2003 + 3× 28BYJ-48). The role
  installs `arduino-cli`, clones firmware, adds udev rules (`/dev/sangaboard`), and a flash
  script — skipped by default until hardware is present.
- Some docs and the README architecture diagram are in **German**; match the existing language
  of a file when editing it.
