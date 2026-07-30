# Mesoscope Electronics Drawer — Pi5 + AI HAT+ + Sangaboard

## Hardware Stack

```
Drawer base (Z = 0)
  Pi5 on 5.5 mm standoffs
    → GPIO stacking header
      → AI HAT+ (Hailo-8)
        → GPIO stacking header
          → Sangaboard
```

### Measured heights (from drawer floor to board underside)

| Board | Z (mm) |
|-------|-------:|
| Pi5 PCB bottom | 5.5 |
| Pi5 PCB top | 7.0 |
| AI HAT+ bottom | 18.4 ¹ |
| Sangaboard bottom | 34.2 ¹ |

¹ Physical measurement on assembled hardware.

Gaps between boards:
- Pi5 top → AI HAT+ bottom: **13.7 mm**
- AI HAT+ bottom → Sangaboard bottom: **15.8 mm** (= 34.2 − 18.4)

### Upstream baseline

The upstream OpenFlexure `master` branch supports Pi3 and Pi4 only
(`pi_version` 3 or 4, no Pi5). No Pi5 branch exists on GitLab as of
July 2026. Our changes are entirely in the mesoscope-specific files.

---

## Approach

We keep the original `sanga_lugs(sanga_version)` call **unchanged** at
the stock `stack_11mm` height (Z = 20.5 mm). This is where the AI HAT+
mounts (same position as the Sangaboard in the original Pi4 design).

Two additional `no2_selftap_lug` calls add a second mounting level at
`sanga_stand_height(sanga_version) + 15.2 mm = 35.7 mm` for the
Sangaboard.

The Sangaboard USB-C connector cutout (`sanga_connector_holes`) is
**shifted up by 15.2 mm** for the `ai_hat_stack` configuration instead
of using the default first-level position.

---

## Modified files

| File | Role |
|------|------|
| `lib_microscope_stand_mesoscope.scad` | Drop-in replacement for upstream `libs/lib_microscope_stand.scad` |
| `microscope_stand_mesoscope.scad` | Entry point — sets `pi_version=5`, `sanga_version="ai_hat_stack"` |
| `electronics_drawer_mesoscope.scad` | Entry point for electronics drawer only |
| `build_stand.sh` | Copies custom files into upstream repo clone, renders both STLs |

---

## Key diffs vs. upstream `lib_microscope_stand.scad`

### `default_stand_params`
- Accepts `pi_version=5`
- Accepts `sanga_version="ai_hat_stack"`
- `electronics_drawer_h = 60` for Pi5 (47 mm upstream)
- Key renamed: `block_usbc` instead of `block_usb` (Pi5 uses USB-C)

### `sanga_stand_height`
- `"ai_hat_stack"` uses `extra_h = 15` — same as `"stack_11mm"` (20.5 mm
  from drawer floor). This places the AI HAT+ at the original Sangaboard
  position.

### `electronics_drawer_walls`
For `sanga_version == "ai_hat_stack"`:
1. `sanga_lugs(sanga_version)` — original call, unchanged → AI HAT+ lugs
   at Z = 20.5 mm.
2. Two additional `no2_selftap_lug` at
   `sanga_stand_height(sanga_version) + 15.2` = **35.7 mm** →
   Sangaboard lugs.
3. `sanga_connector_holes` shifted `+15.2 mm` → Sangaboard USB-C cutout
   at the correct height. No cutout at the AI HAT+ level (AI HAT+ has no
   connector at that wall position).

### `pi_front_connectors` (Pi5)
Pi5 uses the **same Y positions as Pi4** for the three front-edge
cutouts:

| Cutout | Y centre | Width | Height | Covers |
|--------|:--------:|:-----:|:------:|--------|
| 45.75 mm | 17 mm | 14.5 mm | Gigabit Ethernet |
| 27 mm | 15.5 mm | 17 mm | USB 2.0 |
| 9 mm | 15.5 mm | 17 mm | USB 3.0 + 2× micro-HDMI |

> **⚠ Open issue:** The user confirmed USB-C and micro-HDMI fit as-is,
> but **Ethernet and USB-A positions differ from Pi4** and may need
> adjustment. Physical Y measurements for Pi5 Ethernet and USB-A are not
> yet available. The current cutouts may need to be widened or repositioned
> after a test print.

### `pi_side_connectors` (Pi5)
- SD card at X = 11.2 mm (same as Pi4)
- Side components at X = 26 mm, 39.5 mm (same as Pi4)
- **No headphone jack** (removed on Pi5)

---

## Build

Prerequisites:
- OpenSCAD ≥ 2021.01 in `$PATH`
- Upstream repo cloned at `sources/openflexure-microscope`
  (`hq_camera` branch, git-lfs not required for SCAD files)

```bash
cd hardware/stand/openscad
./build_stand.sh
```

Output (in `hardware/stl/models/`):
- `microscope_stand_mesoscope.stl`
- `electronics_drawer_mesoscope.stl`

Reference (upstream Pi4 + stack_11mm):
- `electronics_drawer_original.stl`

---

## Open issues

1. **Pi5 Ethernet + USB-A cutout positions** — current values copied
   from Pi4 and are known to deviate. Requires physical measurement or
   test print to determine correct Y values.
2. **AI HAT+ connector cutout** — no wall cutout exists for the AI HAT+
   connectors (micro-HDMI / USB-C on the HAT itself). Add if needed.
3. **Sangaboard USB-C cutout Z** — uses `sanga_stand_height + 15.2 mm`
   as offset. Verify against physical assembly.
