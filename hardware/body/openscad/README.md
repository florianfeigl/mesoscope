# Mesoscope main body (Z-focus only)

OpenSCAD override of the OpenFlexure `main_body` for the rail mount
(`docs/RAIL_MOUNT_CONCEPT.md`). In the tilted setup the sample chips hang
externally from the bridge, so the microscope's own X/Y stage is never used.
This variant removes it.

## Files

| File | Purpose |
|------|---------|
| `main_body_original.scad` | Byte-identical backup of upstream `openscad/main_body.scad` (hq_camera branch, commit `5e90e97`). |
| `main_body_structure_original.scad` | Byte-identical backup of upstream `openscad/libs/main_body_structure.scad`. |
| `main_body_mesoscope.scad` | Entry file (copied over `openscad/main_body.scad`). `VERSION_STRING = "Mesoscope"`. |
| `main_body_structure_mesoscope.scad` | Upstream structure lib + a mesoscope `main_body()` at the bottom. All upstream modules are kept unchanged so the rendering scenes still work. |
| `build_body.sh` | Copies the overrides into the upstream clone and renders. |

## What was removed vs. upstream

- `xy_stage_with_nut_traps` — the sample stage (Tisch) incl. nut traps
- `xy_legs_and_actuators` — the four flexure legs, both X/Y actuator columns and their screw seats / motor lugs
- `xy_flexures`, `xy_leg_ties` — flexures and print ties
- `side_housing` — the two X/Y motor cable housings on the outer walls
- `xy_actuator_cut_outs` — no columns left to clear from the walls

## What is kept

- `complete_z_actuator` + `z_axis_casing` (focus, optics module mount, condenser/illumination dovetail mount)
- `internal_xy_structure` — inner wall + base with the central optics cut-out and the reflection-illuminator cut-out
- outer walls (`wall_inside/outside_xy_actuators`, `wall_between_actuators`) — where the actuator columns stood, a short straight wall segment (`mesoscope_actuator_stub_wall`) closes the gap
- `mounting_hole_lugs` — the four M3 base lugs (needed later for the rail carriage adapter)
- logos / version string on the outer walls

Removing the X/Y flexures also removes the X/Y gravity-sag risk of the tilted
microscope (RAIL_MOUNT_CONCEPT §5); only the Z flexure remains.

## Build

```bash
hardware/body/openscad/build_body.sh            # -> hardware/stl/models/main_body_mesoscope.stl
hardware/body/openscad/build_body.sh original   # -> hardware/stl/models/main_body_original.stl
hardware/body/openscad/build_body.sh all
```

Needs the upstream clone at `sources/openflexure-microscope` (same location
as `build_stand.sh`). After the run the upstream clone is left in the
*mesoscope* state, so `rendering/librender/rendered_main_body.scad` and the
full-microscope scenes (`hardware/mount/openscad/complete_microscope_*.scad`)
render the reduced body once `rendered_main_body.stl` is regenerated.

## Open points

- The Sangaboard stays for now (decision 2026-09-03); X/Y motor outputs are
  simply unused. `ofm_config.json.j2` still declares a 3-axis stage — OK for
  now, the X/Y axes just have nothing attached.
- Test print pending. Check that the stub walls and the front lugs print
  cleanly without the actuator columns behind them.
