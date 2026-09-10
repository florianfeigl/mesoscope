# Assembly / exploded views

Exploded-view ("Explosionsdarstellung") renders of the full mesoscope, for the thesis figures.

## Files

| File | What |
|------|------|
| `openscad/exploded_view.scad` | Upright microscope stack, exploded along the optical (Z) axis: stand → electronics drawer (Pi 5 + AI HAT+ + Sangaboard) → Z-only main body → Z actuator + 28BYJ-48 motor → HQ-camera optics module (125 mm tube lens) → objective → HQ camera → bioreactor chip → trans-illumination LED. |
| `openscad/exploded_rail.scad` | Rail-mount stack, exploded along Z: base plate → 2040 beam → MGN12 rail → carriage → adapter → tilted microscope → X drive → bridge → 4 chips. Reuses `hardware/mount/openscad/rail_mount_mesoscope.scad`. |
| `openscad/exploded_drawer.scad` | Electronics drawer + tech stack **only**, exploded along Z: pull-out drawer → Raspberry Pi 5 → AI HAT+ (Hailo-8) → Sangaboard. A focused cut of `exploded_view.scad::drawer_with_boards()` with wider board spacing and per-board labels. |
| `build_exploded.sh` | Copies the scene + stand overrides into the upstream clone and renders the PNGs. |
| `exploded_view*.png` / `exploded_view_assembled.png` / `exploded_rail.png` | Rendered outputs (1600×1200, preview render). **Not committed / not LFS-tracked** — regenerate with the script. The upright stack is rendered in four variants: `exploded_view.png` (front, labelled), `exploded_view_back.png` (opposite side, rot_z 35° → 215°, labels mirrored to read correctly), and `_nolabels` versions of each (`exploded_view_nolabels.png`, `exploded_view_back_nolabels.png`) with the annotations removed (guide line kept). |
| `exploded_drawer*.png` | Electronics-drawer-only outputs: `exploded_drawer.png` (labelled), `exploded_drawer_nolabels.png` (guide line only) and `exploded_drawer_assembled.png` (boards seated). The thesis uses `exploded_drawer_nolabels.png` (Fig. "electronics drawer"). |

## Rendering

```bash
./build_exploded.sh          # upright stack + electronics drawer: exploded + assembled
./build_exploded.sh rail     # also the rail stack
EXPLODE=0.5 ./build_exploded.sh   # partial explosion (0 = assembled, 1 = full)
```

Needs OpenSCAD ≥ 2021.01, the upstream `hq_camera` clone at `sources/openflexure-microscope`
(see root `CLAUDE.md`), and the STLs in `hardware/stl/models/` (`git lfs pull`). Override the
binary with `OPENSCAD=…` and the image size with `IMGSIZE=…`.

## Placeholders (not print geometry)

`exploded_view.scad` imports the real STLs for stand, drawer, main body and optics module, and
uses upstream library models for feet, gears, lead screw and the 28BYJ-48 motor. **Simplified
boxes/cylinders** stand in for: the Pi 5 / AI HAT+ / Sangaboard PCBs, the HQ camera (C-mount
barrel + PCB, from the mechanical drawing), the bioreactor chip (70×40×16 mm, 18×8 mm window),
and the LED light source. The objective is the upstream generic RMS model, not ZEISS geometry.
Explosion offsets are hand-set (see the `ex_*` constants); they are illustrative, not to scale.
