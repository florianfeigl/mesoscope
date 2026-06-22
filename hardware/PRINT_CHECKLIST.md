# Mesoscope Print Checklist

## Print Settings (all parts)

| Setting | Value |
|---------|-------|
| Material | **PLA schwarz** (Streulicht — alle optischen Teile zwingend schwarz) |
| Layer height | **0.15 mm** (Optics-Modul); 0.20 mm (alle anderen) |
| Nozzle | 0.4 mm |
| Infill | 20–30% |
| Walls | 3 |
| Supports | As noted per part below |
| Build plate adhesion | Brim recommended for main_body |

## Parts List

### Structural — Must Print

| # | File | Size | Supports | Notes | Status |
|---|------|------|----------|-------|--------|
| 1 | `main_body.stl` | 6.0M | Yes (built-in) | Core frame with flexure stage | ☐ |
| 2 | `optics_hq_150_rms.stl` | 2.0M | No | IMX477 HQ Camera, 150mm tube lens (<=10x) — C-mount seat ⌀32.6mm | ☐ |
| 3 | `optics_hq_125_rms.stl` | 1.9M | No | IMX477 HQ Camera, 125mm tube lens (<=4x only) — C-mount seat ⌀32.6mm | ☐ |

### Actuation — Must Print

| # | File | Size | Supports | Notes | Status |
|---|------|------|----------|-------|--------|
| 4 | `large_gears.stl` | 1.2M | No | Z-axis actuation | ☐ |
| 5 | `small_gears.stl` | 813K | No | X/Y actuation | ☐ |


### Illumination — Must Print

| # | File | Size | Supports | Notes | Status |
|---|------|------|----------|-------|--------|
| 6 | `condenser.stl` | 653K | No | LED condenser housing | ☐ |
| 7 | `condenser_lid.stl` | 348K | No | Condenser top cover | ☐ |
| 8 | `illumination_dovetail.stl` | 191K | No | Condenser mount | ☐ |
| 9 | `illumination_thumbscrew.stl` | 21K | No | Condenser adjustment | ☐ |

### Accessories — Must Print

| # | File | Size | Supports | Notes | Status |
|---|------|------|----------|-------|--------|
| 10 | `feet.stl` | 554K | No | Rubber foot inserts | ☐ |
| 11 | `sample_clips.stl` | 180K | No | Slide retaining clips | ☐ |
| 12 | `cable_tidies.stl` | 487K | No | Cable management | ☐ |
| 13 | `microscope_stand.stl` | 489K | No | Optional stand | ☐ |

### Tools — Print Once

| # | File | Size | Supports | Notes | Status |
|---|------|------|----------|-------|--------|
| 14 | `actuator_assembly_tools.stl` | 261K | No | For gear assembly | ☐ |
| 15 | `gear_tools.stl` | 171K | No | For gear assembly | ☐ |
| 16 | `lens_tool.stl` | 73K | No | For tube lens insertion | ☐ |

## Not Printing

- ~~`optics_picamera_2_rms_f50d13.stl`~~ — Pi Camera v2 mount, incompatible mit IMX477
- ~~`picamera_2_cover.stl`~~ — Pi Camera v2 cover, incompatible mit IMX477
- ~~`picamera_hq_cover.stl`~~ — bare-PCB cover, nicht benötigt: die HQ Camera behält ihr
  C-Mount-Gehäuse und sitzt per Flansch direkt im Optics-Modul (kein PCB freigelegt)

## Optics Module Choice

Use **one** of the two custom optics modules:

| Module | Tube lens | Use case | Parameter |
|--------|-----------|----------|-----------|
| `optics_hq_150_rms.stl` | 150mm achromatic doublet | <=10x objectives (preferred) | `rms_f150d13` |
| `optics_hq_125_rms.stl` | 125mm achromatic doublet | <=4x objectives, wider FOV | `rms_f125d13` |

Verify `tube_lens_ffd` against your lens datasheet before printing. See `OPTICS_MODULE.md` for details.

> **STLs bereits generiert** (2026-06-20) — `build_optics.sh` wurde ausgeführt, beide STLs
> liegen in `hardware/stl/models/`. Neu generieren nur nötig wenn `tube_lens_ffd` angepasst wird.

## Regenerating STLs

If parameters change, rebuild from OpenSCAD:

```bash
cd hardware/optics/openscad
./build_optics.sh        # Both configurations
./build_optics.sh 150    # 150mm only
```

Output: `hardware/stl/models/optics_hq_{125,150}_rms.stl`

## Post-Print Checklist

- [ ] All parts printed and cleaned (remove supports, brims)
- [ ] Test fit: optics module on main body dovetail
- [ ] Test fit: gears on actuator shafts
- [ ] Insert M2/M3 heat-set inserts where required
- [ ] Verify tube lens seats cleanly in optics module
- [ ] **Test fit HQ Camera C-mount housing into optics module seat (32 mm OD, 4 mm deep, ~0.3 mm clearance)** — should slide in concentrically
- [ ] Check IMX477 ribbon cable routing through main body

## Assembly References

- `hardware/optics/BUILD_GUIDE.md` — Optics module assembly instructions
- `hardware/optics/OPTICS_MODULE.md` — Optics design parameters and lens selection
- `docs/OPENFLEXURE_SUITE.md` — Full software/hardware inventory