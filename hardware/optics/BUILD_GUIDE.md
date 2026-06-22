# OpenFlexure Microscope Build Guide -- HQ Camera (IMX477) Variant

This guide covers building the OpenFlexure microscope with a Pi HQ Camera (IMX477)
and a custom 125-150mm tube lens, adapted from the standard Pi Camera v2 build.

> **Prerequisite:** Read [`OPTICS_MODULE.md`](OPTICS_MODULE.md) before starting.
> The custom tube lens is **required** -- the standard 50mm tube lens wastes ~75% of the IMX477 sensor.

---

## 1. Order Components

See [`../../order_list.md`](../../order_list.md) and [`../../order_list_taulab.md`](../../order_list_taulab.md).

**Critical purchase:**
- Achromatic doublet, 12.7mm diameter, 125mm or 150mm focal length (available from taulab)
- Choose based on scraped objective: 150mm for ≤10x, 125mm for ≤4x

**From Taulab:**
- Sangaboard v5 + illumination kit + bag of bits + 3× 28BYJ-48 stepper motors

---

## 2. Verify Objective Type

Before generating the optics module STL, verify your scraped objective:

| Marking | Type | Compatible? |
|---------|------|-------------|
| `160 / 0.17` or `160` | 160mm finite conjugate | Yes, directly |
| `∞ / 0.17` or `∞ / -` | Infinity corrected | Needs different optics module |
| No marking | Likely 160mm finite | Measure WD and confirm |

Also check the parfocal distance:
- 45mm = standard DIN (most common)
- 35mm = older standard

---

## 3. Generate Custom Optics Module STL

The standard OpenFlexure STL files are for the Pi Camera v2 with 50mm tube lens.
We need custom optics modules for the HQ Camera (IMX477) with 125mm and 150mm tube lenses.

Custom OpenSCAD configurations are provided in `../openscad/`:

| File | Purpose |
|------|---------|
| `openscad/optics_configurations_hq.scad` | Tube lens configs (125mm and 150mm) |
| `openscad/rms_optics_module_hq.scad` | Main module with config dispatch |
| `openscad/build_optics.sh` | Build script for both STLs |
| `openscad/README.md` | Parameter reference and usage |

### 3.1 Clone OpenFlexure repo

```bash
cd /path/to/mesoscope/sources
git clone --branch hq_camera --single-branch \
  https://gitlab.com/openflexure/openflexure-microscope.git
cd openflexure-microscope
git lfs install && git lfs pull
```

The build script (`build_optics.sh`) copies the custom configs into the upstream repo automatically.

### 3.2 Available configurations

No manual editing required — all configs are in `optics_configurations_hq.scad`:

| OPTICS name | Tube lens | Conjugate | Use case |
|-------------|-----------|-----------|----------|
| `rms_f125d13` | 125mm | Finite (160mm) | <=4x objectives |
| `rms_f150d13` | 150mm | Finite (160mm) | <=10x objectives (preferred) |
| `rms_infinity_f125d13` | 125mm | Infinity | Infinity-corrected objectives |
| `rms_infinity_f150d13` | 150mm | Infinity | Infinity-corrected objectives |

All configs default to `CAMERA = "picamera_hq"` (confirmed by OpenFlexure team, William Wadsworth, 2026-03-30).

> **Note on camera screw holes:** The generated STL has no screw holes at the
> camera end. This is intentional — the four No.2 self-tapping holes in the
> upstream design are for bare-PCB mounting. The mesoscope uses the HQ Camera
> intact with its C-mount body; the camera is retained by the 32.6 mm flange
> seat, not screws.

> **Note on C-mount opening:** The OpenFlexure `sequential_hull()` closes the
> underside of the optics module. `rms_optics_module_hq.scad` reopens it with
> an explicit `difference()` (module `optics_module_rms_cmount`). See
> `openscad/README.md` for details.

### 3.3 Build STLs

```bash
cd /path/to/mesoscope/hardware/optics/openscad

# Build both configurations:
./build_optics.sh

# Or build one at a time:
./build_optics.sh 125     # 125mm tube lens
./build_optics.sh 150     # 150mm tube lens
```

Output: `../stl/models/optics_hq_125_rms.stl` and `optics_hq_150_rms.stl`

> **Verify `tube_lens_ffd` values** (122.6mm for 125mm, 146.9mm for 150mm) against your
> lens datasheet before printing. Edit `optics_configurations_hq.scad` if needed.

---

## 4. 3D Print Settings

### Print all parts from `../stl/models/`:

| Setting | Value |
|---------|-------|
| Material | PLA or PETG |
| Layer height | 0.15-0.2mm |
| Infill | 20-30% |
| Nozzle | 0.4mm |
| Supports | As indicated per part (see OpenFlexure instructions) |

### Required STL files:

- `main_body.stl` -- Microscope body with flexure stage
- `optics_hq_125_rms.stl` -- **Custom** 125mm tube lens (generated in step 3)
- `optics_hq_150_rms.stl` -- **Custom** 150mm tube lens (generated in step 3)
- `large_gears.stl` + `small_gears.stl` -- Actuation gears
- `condenser.stl` + `condenser_lid.stl` -- Illumination
- `feet.stl` -- Foot pads
- `sample_clips.stl` -- Slide clips
- `cable_tidies.stl` -- Cable management

> **Note:** The `optics_picamera_2_rms_f50d13.stl` and `picamera_2_cover.stl` in
> `../stl/models/` are for the Pi Camera v2 build and should **not** be used.

---

## 5. Assembly Order

Follow the [OpenFlexure v7 assembly instructions](https://build.openflexure.org/openflexure-microscope/v7.0.0-beta5/),
with these adaptations:

1. **Tube lens insertion:** Insert the 125-150mm achromatic doublet (not the standard 50mm lens)
   into the custom optics module. The longer focal length means the lens sits closer to the
   objective end of the tube.

2. **C-mount camera mounting:** The HQ Camera C-mount threads into the `picamera_hq` optics module variant (confirmed by OpenFlexure team, William Wadsworth 2026-03-30).

3. **Ribbon cable:** Route the 200mm ribbon cable from the HQ Camera through the microscope
   body to the Raspberry Pi 5 CSI port.

4. **Condenser:** Standard PMMA condenser lens (13mm, 5mm focal) works with ≤10x objectives.

5. **Illumination LED:** Mount the illumination module below the condenser.

---

## 6. Software Configuration

The Ansible playbook deploys OpenFlexure Server v3 configured for the HQ Camera (IMX477):
`StreamingPiCamera2` with `camera_board: "picamera_hq"`.

```bash
cd /path/to/mesoscope/ansible
ansible-playbook site.yml
```

### Verify camera detection:
```bash
rpicam-hello --list-cameras
# Should show: imx477 ; 4056x3040 ; / 2028x1520 /
```

### Verify OpenFlexure:
```bash
curl -s http://localhost:5000/ | head -5
```

---

## 7. Motorised Stage (when Sangaboard arrives)

1. Wire Arduino Nano (or Sangaboard v5) with 3× 28BYJ-48 stepper motors
2. Flash Sangaboard firmware (see `../../ansible/roles/motor-controller/files/flash-sangaboard.sh`)
3. Update OpenFlexure config to use Sangaboard instead of DummyStage
4. Test stage control via OpenFlexure web UI

---

## Checklist

- [ ] Confirm objective type: **finite conjugate 160mm**
- [ ] Confirm parfocal distance: **45mm** (DIN standard)
- [ ] Order tube lens: **125mm or 150mm achromatic doublet** (12.7mm dia)
- [ ] Look up `tube_lens_ffd` from datasheet for chosen lens — verify values in `hardware/optics/openscad/optics_configurations_hq.scad`
- [ ] Clone OpenFlexure repo (`hq_camera` branch) and set up symlinks (see step 3.1)
- [ ] Run `./build_optics.sh` to generate STLs for both tube lens configurations
- [ ] Print custom optics modules (125mm and/or 150mm)
- [ ] Print remaining STL parts (main body, gears, condenser, feet, clips)
- [ ] Assemble microscope with HQ Camera + custom tube lens + scraped objective
- [ ] Run Ansible playbook for software
- [ ] Verify camera and OpenFlexure web UI
- [ ] Wire motor controller and verify stage control