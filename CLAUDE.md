# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

The **mesoscope** project (formerly "CELLAIR") is a **hardware + infrastructure** project, not a conventional
software application. It builds an automated cell-imaging microscope from a Raspberry Pi 5
(AI HAT+ / Hailo-8 NPU + HQ Camera IMX477) running the OpenFlexure microscope stack, plus
a VPS-hosted CVAT annotation server. The repo contains **no application source of its own** —
it is Ansible playbooks that deploy upstream software, OpenSCAD/CAD source for 3D-printed
parts, and Markdown documentation. There is no build/test/lint step for the repo itself;
the CI job is a no-op stub that only runs pytest if a `requirements.txt`/`model/` appears
(neither exists yet).

The `model/` directory (referenced in `.gitignore` and CI) and `.hef`/`.pt` model artifacts
are planned but not yet present.

## Two deployment targets

Deployment is split across two Ansible entry points with **separate inventories**:

- **`ansible/site.yml`** → the Raspberry Pi 5 (`hosts: rpi5`). Roles run in order:
  `base` → `ai-hat` → `openflexure` → `motor-controller`. This is the microscope itself.
- **`ansible/cvat.yml`** and **`ansible/users.yml`** → the VPS (`hosts: vps`, `152.53.16.72`).
  Deploys CVAT (Docker) behind a Caddy reverse proxy with auto-HTTPS at `cvat.feigl.dev`.

Note the two READMEs describe different scopes: `ansible/README.md` documents the **VPS/CVAT**
side; the root `README.md` documents the **Pi 5 microscope** side and overall project.

## Common commands

### Deploy the Pi 5 microscope
```bash
cd ansible
ansible-playbook site.yml --skip-tags motor-controller -v -K
```
Always skip `motor-controller` until the Sangaboard/Arduino hardware is physically connected.
`-K` prompts for the become (sudo) password. The playbook reboots the Pi mid-run (DKMS kernel
module build for Hailo, PCIe/camera config.txt changes) — this is expected.

### Deploy the VPS (CVAT)
```bash
cd ansible
ansible-playbook users.yml -i inventory/hosts.yml   # create cvat service user first
ansible-playbook cvat.yml  -i inventory/hosts.yml
ansible vps -m ping -i inventory/hosts.yml           # connectivity check
```

### Build 3D-printed parts (OpenSCAD)
The optics and stand scripts require an upstream OpenFlexure clone and **copy custom `.scad`
overrides into it** before rendering — they do not build standalone. Clone with:
`git clone --branch hq_camera https://gitlab.com/openflexure/openflexure-microscope.git`.
STLs are written to `hardware/stl/models/`.
```bash
hardware/optics/openscad/build_optics.sh [125|150|all]   # tube-lens optics module (needs upstream clone)
hardware/stand/openscad/build_stand.sh                    # Pi5+AI-HAT+Sangaboard stand (needs upstream clone)
hardware/body/openscad/build_body.sh [mesoscope|original|all]  # Z-focus-only main body, no XY stage (needs upstream clone)
hardware/rails/openscad/build_rack.sh [N]                 # RAILS parametric bioreactor rack (STANDALONE)
```
**Caveat:** the upstream-dependent scripts expect the clone in **different locations** —
`build_optics.sh` looks in `${HOME}/repositories/openflexure-microscope`, while
`build_stand.sh` and `build_body.sh` look in `../../../sources/openflexure-microscope` (relative
to the script, gitignored). `build_rack.sh` is **standalone** — it needs no upstream clone and renders
`bioreactor_rack.scad` directly to `hardware/stl/models/bioreactor_rack_n<N>.stl` (default N=3).
All three take an `OPENSCAD` env var to override the binary.

### Post-deployment verification on the Pi
The root `README.md` "Post-Deployment Verification" section has the canonical checklist
(`hailortcli fw-control identify`, `rpicam-hello --list-cameras`, `systemctl status openflexure`,
`curl http://localhost:5000/`, etc.). Use it after any fresh boot or deploy.

## Architecture notes that span multiple files

- **The Ansible roles encode hard-won Pi 5 fixes**, not just installs. When touching the
  `ai-hat` or `openflexure` roles, know that they exist to work around specific Pi 5 breakage:
  Hailo driver needs a **DKMS rebuild + reboot** ordering (`ai-hat/tasks/main.yml`);
  OpenFlexure needs a **pisp ISP tuning patch** (`openflexure/files/patch_rpi5_pisp.sh`, applied
  as a task), pipewire masking, and systemd `SupplementaryGroups` for camera access. Don't
  "simplify" these away — each maps to a resolved issue documented in the README roadmap.

- **OpenFlexure is installed from upstream GitLab, not vendored.** The `openflexure` role
  clones the `v3` branch (FastAPI, Python ≥3.11), sets up a `--system-site-packages` venv
  (so it can see the apt-installed `picamera2`/`libcamera`), and pulls the **web frontend as a
  prebuilt CI artifact** from GitLab (project 9238334, `job=build`). There is no frontend build here.

- **Camera/stage config lives in a Jinja template**, not code: `ofm_config.json.j2` →
  `/var/openflexure/settings/ofm_config.json`. This selects the HQ Camera and the stage
  (Dummy vs. Sangaboard). Changing microscope behavior usually means editing the template + a
  handler-triggered `restart_openflexure`, not editing OpenFlexure itself.

- **The custom OpenSCAD files are overrides layered onto upstream.** The build scripts copy
  e.g. `picamera_hq_cmount.scad` over the upstream `picamera_hq.scad` because the mesoscope
  uses the intact C-mount HQ Camera body, not the bare PCB. Edit the files under
  `hardware/*/openscad/`; the STLs in `hardware/stl/models/` are generated outputs (LFS-tracked).

## Conventions & gotchas

- **Global vars:** hostname `mesoscope`, app user `lab`, timezone `Europe/Berlin`
  (`ansible/group_vars/all.yml`). To retarget, edit `inventory/hosts.yml`,
  `group_vars/all.yml`, and `ansible.cfg` together.
- **STL files are Git LFS** (`.gitattributes`). Ensure `git lfs` is installed before committing
  or the pointers break (there is git history of LFS being toggled on/off for this reason).
- **Secrets:** `ansible/group_vars/vault.yml` is gitignored; use Ansible Vault for VPS passwords.
  Never commit unencrypted secrets.
- **Motor controller is a DIY Sangaboard** (Arduino Nano + ULN2003 + 3× 28BYJ-48). The role
  installs `arduino-cli`, clones Sangaboard firmware, adds udev rules (`/dev/sangaboard`), and
  a flash script — but is skipped by default until hardware is present.
- Some docs and the README architecture diagram are in **German**; match the existing language
  of a file when editing it.
</content>
</invoke>
