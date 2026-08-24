# Rail Mount Concept — Tilted Microscope on Linear X-Rail

> **Status:** Concept + first schematic CAD draft (updated 2026-08-25).
> Next milestone: the mount ("Halterung") that lays the mesoscope on its side
> and carries it along a linear X-rail past a series of bioreactors.
>
> **Schematic massing draft:** `hardware/mount/openscad/rail_mount_mesoscope.scad`
> (parametric block model — shared **base plate (Grundplatte)**, the rail beam +
> MGN12 guide under the moving microscope, NEMA17 + T8 leadscrew drive, and a
> **reactor bridge (Brücke)**: a continuous traverse board with per-station
> cutouts from which the chips hang **hochkant**). Previews:
> `rail_mount_preview.png` (3/4 from the objective side) and
> `rail_mount_top.png` (3/4 from the light-source side, full row). This is a
> massing model to make the layout discussable, **not** print-ready geometry.
>
> ✅ **Full mesoscope model embedded — registration CORRECTED (2026-08-25):**
> the real assembled geometry is `import()`ed into the draft
> (`real_model = true`) from `hardware/stl/models/complete_microscope_rms.stl`.
> The upstream render applies `rotate([-90,0,0])`, so in the STL the optical
> axis is the line `x=0, z=0` pointing **+Y** (objective toward the reactors).
> **Important correction:** the render scene includes the **stand**, which
> raises the microscope body frame by **75 mm** (`microscope_on_stand_pos`:
> lug_z 55 + lug 20). The sample plane therefore sits at **model y = 150**,
> *not* at `sample_z = 75` as previously assumed — that wrong registration
> placed the chip 75 mm *inside* the microscope and caused both rounds of
> visible clipping. Measured from the STL: **objective tip = y 146.65**
> (global foremost point, working distance 3.35 mm), condenser tip = y 167.5
> (17.5 mm above the sample plane — the earlier "2.5 mm" figure was an
> artifact of the wrong registration).
>
> ✅ **Illumination arm removed from the model (per decision):** the 16 mm chip
> would leave only ~1.5 mm nominal clearance under the stock condenser, and
> the illumination must be redesigned anyway for trans-illumination from
> behind the chip row. The model is now rendered **without sample clips AND
> without the illumination assembly** (dovetail, condenser, wiring):
> `hardware/mount/openscad/complete_microscope_rms_noclips_noillum.scad`, a
> variant of upstream `rendering/complete_microscope.scad` that re-composes
> `assembled_microscope_without_electronics` as motors +
> `mounted_microscope()` only. Copy into the upstream `rendering/` dir and
> render there to regenerate the STL. The custom light source ("Halterung
> unten") comes later as a separate part on the +Y side behind the chips.
>
> ✅ **10 mm working gap established (per decision):** the microscope is shifted
> back along the optical axis (`model_dy = (75 − 10) − 146.65 ≈ −81.7 mm`)
> so the objective tip stops **10 mm** before the chip window (world y = 65
> vs. window at y = 75). Since the tip is the model's foremost point, the
> **entire microscope stays at world y ≤ 65 at every rail position** —
> chips (y ≥ 75), traverse board (y ≥ 80) and pillars are cleared by
> construction; no separate travel-path check needed. **Optics consequence:**
> the stock focus plane lies 3.35 mm beyond the tip, so to focus at the chip
> window inner face the objective must protrude **~8 mm beyond stock** —
> more to reach deeper planes inside the 16 mm chip. This optics-module
> adaptation (longer nose/extension tube) is an accepted follow-up task.
>
> ✅ **Bridge clearance:** with the shifted microscope (everything ≤ y 65) the
> slim traverse board (24 mm, starting at y = 80, `bridge_y_clear = 5`) is
> trivially clear. The station cutouts are **front-open notches**: chips
> slide in from the objective side.
>
> ✅ **Bioreactor STL integrated:** `hardware/bioreactors/chip_senkrecht_mit_bodenplatte.stl`.
> Base plate (Bodenplatte) removed for the calculations per
> instruction → chip body **70 × 40 × 16 mm**, optical window **18 × 8 mm**,
> 4 fluidic ports. Only the **series pitch** (reactor-to-reactor spacing along
> X) is still an assumption (80 mm) to confirm.
>
> ✅ **Hochkant + Brücke (2026-08-25):** the chips are now mounted **upright
> (hochkant)** and **hang from a bridge** — a continuous traverse board
> ("schmales Brett" in chip dimensions) with per-station cutouts
> (Aussparungen), carried by two end pillars on the Grundplatte. Imaging goes
> horizontally **through the 16 mm chip thickness**: light source on the +Y
> side → chip → objective on the −Y side. The fluidic ports + tubes
> (Schläuche) exit at the **top** — that is why top access is impossible and
> the chips must hang, keeping the space **below** free for the moving
> mesoscope. Pillar clearance at the end stops is confirmed: microscope
> half-width 85 mm vs. `bridge_x_clear = 120 mm` → ≥ 35 mm margin; the
> travel path under the hanging row is clear (microscope ≤ y 65 everywhere).

This document captures the geometry, the mechanical concept, open decisions, and
the reasoning behind them, so the next session can start from a shared picture.

---

## 1. Goal

Transform the microscope from a static inverted instrument into a **moving
imaging head** that scans a **row of bioreactors** arranged in series:

- Lay the whole OpenFlexure microscope on its side (**90° tilt**), resting on the
  face of the **Z-axis motor**, so the **optical axis becomes horizontal**.
- Bind a **linear rail under the microscope** so it rides on a **carriage** in
  **X** (90° to the optical path) — **only the microscope moves.**
- On the **same base plate (Grundplatte)**, a **fixed bridge (Brücke)** holds the
  **bioreactors in a stationary row** at a working-distance offset along the
  optical axis. The reactors do **not** move with the carriage.
- A **separate stepper drive** moves the microscope carriage in X so it travels
  **along the fixed row of reactors**; at each station it images the sample.

This matches the system architecture diagram in the root `README.md`
("montiert auf Schlitten" / "Linearschiene" / "Antrieb/Motor" / Bioreaktoren #1…#n).

---

## 2. Coordinate transformation (90° tilt)

**Before (current, inverted OpenFlexure):**
- Optical axis = Flexure **Z**, **vertical**. Objective below the sample.
- Gravity acts **along** the optical axis (Z) — the stage is designed for this.

**After (tilted onto the Z-motor face):**

| World axis | Direction | Role |
|---|---|---|
| World **Y** | horizontal, toward the reactors | optical axis = old Flexure **Z** (focus) |
| World **X** | horizontal, along the rail | scan direction (separate stepper drive) |
| World **Z** | vertical (gravity) | now **perpendicular** to the optical axis |

**Consequence for focus (good):** the old Flexure-Z (focus travel) is now
horizontal and points at the reactor → **autofocus/focus still works via the
stage.** Flexure X/Y provide fine framing within the field of view at each station.

**Consequence for gravity (risk — see §5):** gravity is now transverse to the
optical axis and loads the flexure joints in a direction they were not
pre-tensioned for.

> ⚠ The exact mapping of the two lateral flexure axes (which becomes vertical vs.
> horizontal) depends on **which face of the Z-motor** the microscope rests on.
> Confirm the physical resting face before CAD — it decides the gravity load
> direction on the flexure stage.

---

## 3. Mechanical concept — one shared base plate (Grundplatte)

**Key principle:** the **rail (with the moving microscope)** and the **fixed
reactor bridge (Brücke)** both mount to **one rigid base plate (Grundplatte)**.
Because both are referenced to the same foundation, the **optical-axis-to-sample
distance is fixed by construction** and cannot drift; the stationary row of
reactors stays coplanar and parallel to the rail. **Only the microscope
travels**; the reactors stand still and the imaging head drives along them.

The reactors **hang hochkant from above**: a continuous traverse board
("schmales Brett" in chip dimensions) spans the row on two end pillars, with a
cutout (Aussparung) per station from which each chip hangs. The tubes
(Schläuche) exit the chip tops through/above the board; the space **below** the
chips stays completely free so the moving mesoscope can reach every station
unobstructed (the stock illumination arm is removed from the model; a custom
light source behind the chips comes later as a separate part).

```
   (view along the rail, gravity ↓)      reactors FIXED & HANGING, microscope moves ⊙

   pillar ─┐  ┌───────────── traverse board (cutouts per station) ─────┐┌─ pillar
           ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
           ║        ║ tubes ↑↑            ║                             ║
           ║      ┌─┴─┐  chip hochkant    ║   ┌───────────┐             ║
           ║      │ R │◄── optical axis ──╫───│ Microscope│ (tilted)    ║
           ║      └───┘  (through 16 mm)  ║   │ objective─┘◄─ light arm ║
           ║   free space below ▼         ║   └────┬──────┘             ║
           ║                              ║   ═════╪═════ rail X        ║
   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  base plate (Grundplatte) = shared foundation ▓▓▓▓▓▓▓▓▓▓▓
```

Sub-assemblies:
1. **Rail + carriage adapter** — the linear rail is bound under the microscope;
   the adapter interfaces the tilted microscope body (Z-motor face + an
   additional support) to the MGN12 carriage. Must resist the transverse gravity
   moment (long lever arm of the Pi5 + AI HAT + camera + optics tower).
2. **Reactor bridge (Brücke)** — a stationary traverse board with per-station
   cutouts, on two end pillars rising from the Grundplatte, holding the chips
   hanging hochkant at the correct height/spacing so each optical window lands
   on the optical axis. It is **not** attached to the carriage or the rail beam.
   The pillars stand `bridge_x_clear` beyond the end stations so the microscope
   body clears them at the end stops.

---

## 4. Rail & drive — recommendation

Decision was left open ("Empfehlungen?"). Recommendation:

| Element | Choice | Rationale |
|---|---|---|
| Foundation | **Base plate (Grundplatte)** | Shared reference for the rail and the fixed reactor bridge → fixed working distance. |
| Structural beam | **2040 V-Slot aluminium extrusion** | Stiff, cheap; carries the rail under the microscope, mounted on the Grundplatte. |
| Guide | **MGN12 profile rail + carriage** | Low play / high stiffness for the cantilevered microscope mass; clean mounting hole pattern. |
| Drive | **NEMA17 + T8 leadscrew (anti-backlash nut)** | Self-locking → holds position at each stop without current; no backlash for step-and-image. |
| Alt. drive | GT2 belt + NEMA17 | Faster, but slight backlash; only if scan speed matters more than repeatability. |

**Why absolute rail repeatability is not critical:** at every station the
microscope re-centers optically (Flexure X/Y + autofocus in Z / CSM). The rail
only has to be **stiff and get close**; final positioning is done optically.

**Alternatives considered:**
- *Fully printed dovetail guide* — rejected: not stiff enough for this mass over
  the required length.
- *MGN15* — viable if the loaded mass turns out higher than expected; heavier/costlier.

---

## 5. Gravity / flexure — the main risk

The OpenFlexure flexure stage is pre-tensioned for gravity **along** the optical
axis. Tilting 90° loads it **transversely**, which can cause sag, drift, or
changed backlash of the X/Y/Z flexures.

Mitigation ideas to evaluate at design/test time:
- Add a **secondary support** on the mount so the microscope body is clamped on
  **two faces**, not cantilevered off the Z-motor face alone.
- Check whether flexure **pre-load (O-rings / actuator tension)** needs adjusting
  for the new orientation.
- Empirically measure focus drift over a full X-scan before trusting positions.
- Consider counter-balancing or shortening the lever arm of the electronics tower.

This is the item most likely to force a design revision, so it is called out
explicitly and should be validated on a test print early.

---

## 6. Bioreactor chip — real geometry (STL integrated)

Source STL: `hardware/bioreactors/chip_senkrecht_mit_bodenplatte.stl` (ASCII/binary
STL, single chip). The file **includes a base plate (Bodenplatte)**; per
instruction the plate is **removed for the calculations** — it is a
mounting/handling feature, not part of the reactor envelope.

Measured (base plate excluded):

| Feature | Value | Axis in mount (hochkant, hanging) |
|---|---|---|
| Chip body width | **70 mm** | X (along rail) |
| Chip body thickness | **16 mm** | Y (**along the optical axis** — imaged through) |
| Chip body height | **40 mm** | Z (vertical, hanging from the bridge) |
| Optical window | **18 × 8 mm**, centered on the objective-facing (−Y) face, on the optical axis | window on optical axis |
| Fluidic ports | 4 × ⌀ ~4.5 mm, exiting the **top** edge (tubes go up) | — |
| Base plate (removed) | 140 × 100 mm thin panel | ignored for calculations |

**Orientation rationale:** the chip is imaged in **trans-illumination through
its 16 mm thickness** — light source on +Y, objective on −Y. The tubes leave
the ports on the top edge, so the chip cannot be accessed or held from above
by anything bulky and cannot rest on a shelf below (the mesoscope needs that
space); hence it **hangs hochkant from the bridge cutout**.

These values are now hard-wired as defaults in the SCAD reactor block. The rack
stays **parametric** (`n_reactors`, `reactor_pitch`, `reactor_w/d/h`, window
size) so the row length and stop spacing update automatically.

**Still to confirm:** the **series pitch** (reactor-to-reactor center distance
along X). The STL contains one chip only, so pitch is currently assumed
`reactor_pitch = 80 mm` (70 mm chip + 10 mm gap). Set this to the real rack
spacing once the multi-reactor frame is defined.

### 6.1 Standalone parametric rack (earlier drop-in concept)

A standalone parametric rack already exists at
`hardware/rails/openscad/bioreactor_rack.scad` (render:
`hardware/rails/openscad/build_rack.sh [N]` → `hardware/stl/models/bioreactor_rack_n<N>.stl`;
**no upstream OpenFlexure clone needed**). It was designed for the **earlier
retention concept** — the chip held **with** its base plate via a vertical
**drop-in slot + removable clamp**, plate **back face as the focus datum**,
`PITCH ≈ 148 mm`, and an `OPTICAL_AXIS_H` placeholder (60 mm).

The hochkant/bridge decision above (base plate **removed**, chips **hanging**,
pitch ≈ 80 mm, imaged through the 16 mm thickness) **supersedes** that base-plate
retention approach. This rack therefore still needs updating to the
hanging-bridge geometry — but the parametric `build_rack.sh` stays the tooling
entry point (and is documented as standalone in `CLAUDE.md`).

---

## 7. Open decisions / questions for next session

1. **Stepper control integration** — how is the separate X-stepper driven?
   - 4th axis on Sangaboard v0.5 (does it expose one?), or
   - a separate driver (e.g. TMC2209 / A4988) off the Pi GPIO, or
   - reuse a 28BYJ-48 + ULN2003 (already on hand, but weak for this mass).
   Affects firmware/OpenFlexure stage abstraction.
2. **Resting face** on the Z-motor (confirms gravity load direction — §2).
3. **Scan length** = n × reactor pitch → beam length + leadscrew length.
4. **Bioreactor STL** → fixes rack geometry (§6).
5. Whether X becomes a **software-controlled OpenFlexure axis** (for smart-scan
   automation) or an independent motion controller.

---

## 8. Next steps

- [x] Bioreactor STL integrated (`hardware/bioreactors/`), base plate removed,
      real chip dims wired into the SCAD draft.
- [x] Parametric standalone rack — `hardware/rails/openscad/bioreactor_rack.scad`
      (build: `hardware/rails/openscad/build_rack.sh [N]`). Embodies the earlier
      drop-in-slot/clamp concept (§6.1); **to be updated** to the hochkant/bridge geometry.
- [ ] Confirm the **series pitch** (reactor-to-reactor spacing) for the rack.
- [ ] Confirm the Z-motor resting face and measure the microscope's mass/CoG in
      the tilted orientation → fixes `OPTICAL_AXIS_H` in the rack.
- [ ] Decide stepper control path (§7.1).
- [ ] Carriage adapter to MGN12 (the other sub-assembly, §3.1) — still blocked on the
      Z-motor resting face; new entry point under `hardware/rails/openscad/`.
