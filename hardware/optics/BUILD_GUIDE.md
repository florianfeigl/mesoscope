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

The standard OpenFlexure STL files (in `../stl/models/`) are for the Pi Camera v2 with
50mm tube lens. We need to generate a custom optics module for the HQ Camera with our
tube lens.

### 3.1 Clone OpenFlexure and checkout hq_camera branch

```bash
cd /tmp
git clone https://gitlab.com/openflexure/openflexure-microscope.git
cd openflexure-microscope
git checkout hq_camera
```

### 3.2 Edit parameters

**File: `openscad/rms_optics_module.scad`**
```openscad
CAMERA = "picamera_hq";         // Pi HQ Camera (IMX477, C-mount)
```

> **Important:** Use `"picamera_hq"`, not `"arducam_b0196"`. Confirmed by
> OpenFlexure team (William, 2026-03-30).

**File: `openscad/optics_configurations.scad`** -- in the `rms_f50d13_config` function:

| Parameter | Standard Value | Required Value |
|-----------|---------------|----------------|
| `tube_lens_f` | 50 | **125** or **150** (mm) |
| `tube_lens_ffd` | ~48 | **Check ThorLabs datasheet** for chosen lens |

For reference:
- ThorLabs AC127-125-A: `tube_lens_ffd` ≈ 122.6mm (check datasheet)
- ThorLabs AC127-150-A: `tube_lens_ffd` ≈ 146.9mm (check datasheet)

### 3.3 Build STL

```bash
openscad -o optics_hq_camera_rms.stl openscad/rms_optics_module.scad
```

Copy the output to `../stl/models/`:
```bash
cp optics_hq_camera_rms.stl /path/to/mesoscope/hardware/stl/models/
```

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
- `optics_hq_camera_rms.stl` -- **Custom** (generated in step 3)
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

2. **C-mount camera mounting:** The HQ Camera C-mount threads directly into the optics module
   (the `arducam_b0196` variant has the correct mounting geometry).

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
- [ ] Order tube lens: **ThorLabs AC127-125-A** or **AC127-150-A**
- [ ] Look up `tube_lens_ffd` from ThorLabs datasheet for chosen lens
- [ ] Clone OpenFlexure repo, checkout `hq_camera` branch
- [ ] Set `CAMERA = "arducam_b0196"` in `rms_optics_module.scad`
- [ ] Set `tube_lens_f` and `tube_lens_ffd` in `optics_configurations.scad`
- [ ] Build STL with OpenSCAD and verify geometry
- [ ] Print custom optics module
- [ ] Print remaining STL parts (main body, gears, condenser, feet, clips)
- [ ] Assemble microscope with HQ Camera + custom tube lens + scraped objective
- [ ] Run Ansible playbook for software
- [ ] Verify camera and OpenFlexure web UI
- [ ] Wire motor controller and verify stage control