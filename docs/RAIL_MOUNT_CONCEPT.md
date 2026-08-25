# Rail Mount Concept — Tilted Microscope on Linear X-Rail

> **Status:** Concept + first schematic CAD draft (updated 2026-08-25).
> Next milestone: the mount ("Halterung") that lays the mesoscope on its side
> and carries it along a linear X-rail past a series of bioreactors.
>
> **Schematic massing draft:** `hardware/mount/openscad/rail_mount_mesoscope.scad`
> (parametric block model — beam, MGN12 guide, tilted microscope, back-support
> plate, NEMA17 + T8 leadscrew drive, and the reactor row). Previews:
> `rail_mount_preview.png` (3/4) and `rail_mount_top.png` (elevation). This is a
> massing model to make the layout discussable, **not** print-ready geometry.
>
> ✅ **Bioreactor STL integrated:** `hardware/bioreactors/chip_senkrecht_mit_bodenplatte.stl`.
> Base plate (Bodenplatte) removed for the calculations per
> instruction → chip body **70 × 40 × 16 mm**, optical window **18 × 8 mm**
> centered on the microscope-facing face, flanked by 4 fluidic ports. Reactor
> dims in the draft are now real; only the **series pitch** (reactor-to-reactor
> spacing along X) is still an assumption (80 mm) to confirm.

This document captures the geometry, the mechanical concept, open decisions, and
the reasoning behind them, so the next session can start from a shared picture.

---

## 1. Goal

Transform the microscope from a static inverted instrument into a **moving
imaging head** that scans a **row of bioreactors** arranged in series:

- Lay the whole OpenFlexure microscope on its side (**90° tilt**), resting on the
  face of the **Z-axis motor**, so the **optical axis becomes horizontal**.
- Mount it on a **carriage on a linear rail** running in **X** (90° to the optical
  path).
- At a defined working-distance offset along the optical axis, the **same mount**
  carries a **frame ("Gerüst") holding the bioreactors in series** (also along X).
- A **separate stepper drive** moves the carriage in X from bioreactor to
  bioreactor; at each station the microscope images the sample.

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

## 3. Mechanical concept — one shared reference beam

**Key principle:** the microscope carriage **and** the bioreactor rack are both
mounted on **one rigid reference beam**. Because both are referenced to the same
structure, the **optical-axis-to-sample distance is fixed by construction** and
cannot drift; the row of reactors stays coplanar and parallel to the rail.

```
        (side view, gravity ↓)

   ┌───────────┐                         ┌──────────────────────────┐
   │ Microscope│  optical axis  ───►     │  Bioreactor rack (series)│
   │ (tilted)  │═══════════════════════► │  [R1][R2][R3] … [Rn]     │
   └────┬──────┘                         └───────────┬──────────────┘
        │ MGN12 carriage                             │ fixed to same beam
   ═════╪══════════════════════════════════════════════════════════════  ← rail X
   ▓▓▓▓▓▓▓▓▓▓▓▓▓▓  aluminium extrusion (2040) = shared reference beam ▓▓▓▓▓▓▓▓
                    ▲ NEMA17 + T8 leadscrew drives the carriage in X
```

Two sub-assemblies of the printed mount:
1. **Carriage adapter** — interfaces the tilted microscope body (Z-motor face +
   an additional support) to the MGN12 carriage. Must resist the transverse
   gravity moment (long lever arm of the Pi5 + AI HAT + camera + optics tower).
2. **Bioreactor rack** — parametric frame that holds the reactors in series at
   the correct height and spacing so each optical window lands on the optical axis.

---

## 4. Rail & drive — recommendation

Decision was left open ("Empfehlungen?"). Recommendation:

| Element | Choice | Rationale |
|---|---|---|
| Structural beam | **2040 V-Slot aluminium extrusion** | Stiff, cheap, carries **both** carriage and reactor rack → common reference. |
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

| Feature | Value | Axis in mount |
|---|---|---|
| Chip body width | **70 mm** | X (along rail) |
| Chip body depth | **40 mm** | Y (toward microscope; plate was the +Y face) |
| Chip body height | **16 mm** | Z (vertical) |
| Optical window | **18 × 8 mm**, centered on the microscope-facing (−Y) face, at mid-height | window on optical axis |
| Fluidic ports | 4 × ⌀ ~4.5 mm, flanking the window on the same face | — |
| Base plate (removed) | 140 × 100 mm thin panel | ignored for calculations |

These values are now hard-wired as defaults in the SCAD reactor block. The rack
stays **parametric** (`n_reactors`, `reactor_pitch`, `reactor_w/d/h`, window
size) so the row length and stop spacing update automatically.

**Still to confirm:** the **series pitch** (reactor-to-reactor center distance
along X). The STL contains one chip only, so pitch is currently assumed
`reactor_pitch = 80 mm` (70 mm chip + 10 mm gap). Set this to the real rack
spacing once the multi-reactor frame is defined.

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
- [ ] Confirm the **series pitch** (reactor-to-reactor spacing) for the rack.
- [ ] Confirm the Z-motor resting face and measure the microscope's mass/CoG in
      the tilted orientation.
- [ ] Decide stepper control path (§7.1).
- [ ] Then: OpenSCAD design — (a) carriage adapter to MGN12, (b) parametric
      bioreactor rack — as new entry points under `hardware/` analogous to
      `hardware/stand/openscad/microscope_stand_mesoscope.scad`.
