# Rail Mount Concept — Tilted Microscope on Linear X-Rail

> **Status:** Concept + first schematic CAD draft (updated 2026-09-03 —
> motor-control architecture is now a **hybrid**: the Sangaboard stays for
> focus + illumination LED, the linear rail runs on a standalone TMC2209 at
> GPIO; this narrows the earlier 2026-09-02 "all-Python GPIO stage" to just the
> rail axis. See the decision box in §7.1; handoff list at the end of §8).
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
horizontal and points at the reactor → **autofocus/focus still works.**
Flexure-Z moves the **optics module**, which is part of the microscope — it
works regardless of where the sample sits.

**Consequence for framing (important insight, 2026-09-02):** the Flexure
**X/Y axes move the sample stage platform** — but the chips hang externally
from the bridge, **not** on the microscope's stage. In the tilted setup the
X/Y flexures are therefore **functionless** for framing. Fine positioning is
instead:
- **horizontal (world X):** the rail drive itself — Tr8×2 gives
  0.01 mm/microstep, precise enough for fine framing, not just station hops;
- **vertical (world Z):** open — baseline is a one-time manual height
  adjustment; a motorized lift stage is a documented expansion option (§7.1a).

> TODO (fresh session): verify against the upstream OpenFlexure CAD which
> flexure axes move the stage platform vs. the optics module, to confirm this
> mapping before mechanical design.

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

**Motor spec (decided 2026-09-02):** NEMA17 with **integrated Tr8×2 leadscrew**
("linear stepper", 3D-printer-Z style — no coupler, no shaft misalignment;
free spindle end gets a simple bearing in the 2040 profile end):
- 1.8°, ~40 Ncm holding torque, **rated current ≤ 1.5 A** (TMC2209 sustains
  ~1.2–1.4 A RMS; run at ~80 % of rated).
- **Tr8×2 lead (2 mm/rev)**, not the common Tr8×8: strongly self-locking
  (holds without current, guaranteed) and 0.01 mm/microstep — fine enough
  that the rail doubles as the horizontal fine-framing axis (§2). Speed
  ~5–10 mm/s is ample for 80 mm station hops.
- **Spindle length = scan length + ~60 mm** (nut + motor flange + end
  reserve); e.g. 5 reactors × 80 mm pitch → ~320 mm travel → 400 mm spindle.
- 0.9° versions unnecessary — final positioning is optical anyway.

**Why absolute rail repeatability is not critical:** the chip positions are
fixed by construction (shared Grundplatte), horizontal fine positioning is
done by the **rail drive itself** (Tr8×2, 0.01 mm/microstep — see §2), focus
by flexure-Z autofocus, and the vertical alignment is set once manually
(§7.1a). The rail only has to be **stiff** and repeat well enough to land
within the Tr8×2 fine-stepping range — which it trivially does.

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

1. ✅ **Motor control architecture — REVISED (2026-09-02): Sangaboard removed,
   all-Python GPIO stage.** Supersedes the earlier (2026-08-26) "TMC2209
   Phase A/B with Sangaboard 4th axis" decision. Rationale: the DIY
   Sangaboard's ULN2003 cannot drive a NEMA17 (unipolar Darlington,
   ~500 mA/channel; NEMA17 is bipolar, ~1.2–1.5 A, needs a chopper driver);
   the flexure X/Y axes are functionless in the tilted setup anyway (§2);
   and dropping the Sangaboard HAT removes the 3-story HAT stack
   (thermal/5 V-budget concerns) plus the Arduino firmware maintenance
   entirely. **All remaining axes are driven directly from Pi 5 GPIOs by a
   pure-Python OpenFlexure stage class** (no serial protocol, no firmware).

   | Axis (world) | Function | Motor | Driver | GPIOs | Supply |
   |---|---|---|---|---|---|
   | Y (optical) | Focus (flexure Z → optics module) | 28BYJ-48 | ULN2003 | 4 | Pi 5 V |
   | X (rail) | Scan + horizontal fine framing | NEMA17 Tr8×2 | TMC2209 (standalone STEP/DIR/EN) | 3 (+2 UART opt.) | **12–24 V external** (only external consumer) |
   | Z (vertical) | deferred — see §7.1a | — | — | — | — |

   GPIO budget: ~7–9 of 28 (plus 3 more if the lift stage comes). Electrical
   notes: TMC2209 **VIO = 3.3 V** (never 5 V), common ground between Pi and
   VMOT supply mandatory, 100 µF electrolytic across VMOT, standalone current
   via poti (Vref ≈ 0.7 × I_RMS on common stepsticks), motor current ~80 %
   of rated. **De-energize the 28BYJ-48 after every move** (all 4 ULN inputs
   low; the flexure holds via O-ring pre-tension) so the 5 V budget stays
   clean for the Hailo-8. **Pi 5 gotcha:** `RPi.GPIO` does not work (RP1 I/O
   chip) — use `lgpio` / `gpiozero`. Python-side step timing is fully
   sufficient for step-and-image; drive the NEMA17 with a soft ramp, and
   generate the 28BYJ-48 half-step sequence in software (~30 lines).

   **TMC2209 wiring — two separate power domains (never mix them):**
   the high current (12–24 V, ~1.2–1.4 A) enters at the driver's **VM/VMOT
   screw terminal only** and flows out through **A1/A2/B1/B2** into the
   NEMA17 — it **never touches the Pi**. The Pi supplies only 3.3 V logic +
   three signal wires + a shared ground. The breakout is **not** plugged onto
   the Pi; it sits beside it, jumpered to the 40-pin header.

   ```
        ┌──────────── LOGIC SIDE (weak, 3.3 V) ────────────┐
   Pi 5 ── 3.3 V ─────────────► VIO   (never 5 V)          │
   40pin ── GND  ──────┬──────► GND (logic)                │
        ── GPIO ───────│──────► STEP  (1 pulse = 1 µstep)  │
        ── GPIO ───────│──────► DIR   (high/low)           │
        ── GPIO ───────│──────► EN    (enable)             │
        (opt) GPIO ────│──────► UART  (1 wire + resistor)  │
                       │        TMC2209 breakout           │
        ┌──────────────┴──── MOTOR SIDE (STRONG, 12–24 V) ─┤
   12–24 V PSU ─ + ──► VM/VMOT ┐  (screw terminal)         │
              ─ − ──► GND(mot) ┘                           │
                       └─ common ground with Pi GND ◄──────┘
        VM ══ 100 µF electrolytic ══ GND  (close to board)
        A1 A2 B1 B2 (screw terminal) ──► NEMA17 coils
   ```

   Mandatory: **both grounds joined** (Pi GND + PSU minus at the breakout GND)
   or STEP/DIR floats; **100 µF across VM/GND before first power-on**;
   set **Vref (≈ 0.7 × I_RMS)** at the poti *before* connecting the motor.

   Integration path: implement as a custom OpenFlexure-v3 stage class
   (the stage is already selected via `ofm_config.json.j2`, Dummy vs.
   Sangaboard today), deployed as a small package/patch by the `openflexure`
   Ansible role (analogous to the pisp patch). The `motor-controller` role
   is repurposed: arduino-cli/firmware/udev out, GPIO stage package +
   config in.

   > **Decision 2026-09-03: the Sangaboard stays for now** ("Sangaboard bleibt
   > vorerst implementiert") as a
   > **hybrid** — Sangaboard drives **focus (28BYJ-48) + illumination LED**
   > (both natively supported: the firmware has a PWM LED output and
   > OpenFlexure already controls Sangaboard illumination + axes out of the
   > box), while the **rail NEMA17** runs on a **standalone TMC2209 at GPIO**
   > (the Sangaboard's ULN can't drive it, so the TMC2209 is needed either
   > way). Trade-off: this removes the bare-GPIO focus + LED-PWM work
   > entirely, at the cost of keeping the HAT stack (5 V/thermal budget next
   > to the Hailo) and the Arduino firmware. Motivation: wiring the focus
   > motor and a dimmable illumination LED directly to GPIO turned out fiddly,
   > and the Sangaboard already solves exactly those two. Consequence: §7.1's
   > "all-Python GPIO stage" narrows to just the TMC2209 rail axis; the
   > Sangaboard's X/Y outputs stay unused. The X/Y motors + stage have been
   > removed from the body model (§8, `hardware/body/openscad/`).

   1a. **Vertical axis (world Z) — deferred, keep on the radar.** Baseline:
   **one-time manual height adjustment** at the carriage adapter (slotted
   holes / fine-pitch adjustment screw, then clamped) — all chips hang at
   the same height by construction. Motorization becomes necessary only if
   the field of view turns out **smaller than the window height (8 mm)** and
   vertical tiling is required → measure FOV at the chip window after the
   X-axis works. Expansion option, documented for then: a **mini lift stage
   (Hubtisch)** between MGN12 carriage and mesoscope adapter — two short
   vertical guides (MGN7/9 or bushings on 8 mm rods), NEMA17 + vertical
   Tr8×2 (3D-printer-Z principle), ~20 mm travel, self-locking → holds the
   ~2 kg without current. Cost: ~40–50 mm build height, ~200 g on the
   carriage, a second TMC2209 on the same VMOT supply, 3 more GPIOs.
   **Provision now:** give the carriage adapter a bolt pattern so the lift
   stage can be inserted later without reprinting the adapter.
2. **Resting face** on the Z-motor (confirms gravity load direction — §2).
3. **Scan length** = n × reactor pitch → beam length + leadscrew length.
4. **Bioreactor STL** → fixes rack geometry (§6).
5. ✅ **X as OpenFlexure axis — resolved by §7.1 (2026-09-02):** X becomes a
   normal axis of the custom all-Python GPIO stage class, so OpenFlexure
   scan/tiling/API features see it natively. No independent motion controller.

---

## 8. Next steps

- [x] Bioreactor STL integrated (`hardware/bioreactors/`), base plate removed,
      real chip dims wired into the SCAD draft.
- [x] Parametric standalone rack — `hardware/rails/openscad/bioreactor_rack.scad`
      (build: `hardware/rails/openscad/build_rack.sh [N]`). Embodies the earlier
      drop-in-slot/clamp concept (§6.1); **to be updated** to the hochkant/bridge geometry.
- [ ] Confirm the **series pitch** (reactor-to-reactor spacing) for the rack.
- [ ] Confirm the Z-motor resting face and measure the microscope's mass/CoG in
      the tilted orientation → also fixes `OPTICAL_AXIS_H` in the rack.
- [x] Decide stepper control path (§7.1, revised 2026-09-03): **hybrid** —
      Sangaboard keeps focus (28BYJ-48/ULN2003) + illumination LED, standalone
      TMC2209 at GPIO drives the rail; vertical axis deferred (§7.1a).
- [ ] Update the standalone rack (`hardware/rails/openscad/bioreactor_rack.scad`,
      §6.1) from the drop-in-slot/clamp concept to the hochkant/bridge geometry.
- [ ] Carriage adapter to MGN12 (the other sub-assembly, §3.1) — still blocked on
      the Z-motor resting face; new entry point under `hardware/rails/openscad/`,
      **with a bolt pattern for the optional lift stage** (§7.1a).
- [x] **Simplify the OpenFlexure model:** the X/Y flexure legs, actuator
      columns, motor lugs/cable housings and the **sample stage platform
      (Tisch)** are removed from the body — `hardware/body/openscad/`
      (`build_body.sh` → `main_body_mesoscope.stl`; upstream originals backed
      up alongside). Only the Z focus actuator + casing, inner wall/base with
      optics cut-out, outer walls and the four base lugs remain. Done
      2026-09-03; test print pending. Config (`ofm_config.json.j2`) still
      declares 3 axes — X/Y just have no motor attached.

### Handoff — fresh session starts here (2026-09-02)

1. **Verify upstream flexure axis mapping** (which axes move the stage
   platform vs. the optics module in the OpenFlexure CAD) — confirms the
   §2 insight before any mechanical design.
2. **Implement the rail axis** (`lgpio`: TMC2209 STEP/DIR with soft ramp for
   X) and bind it alongside the Sangaboard focus + illumination as an
   OpenFlexure-v3 stage class (selected via `ofm_config.json.j2`). Focus + LED
   stay on the Sangaboard; only the rail is new GPIO code.
3. **Rework the `motor-controller` Ansible role:** keep the Sangaboard path
   (arduino-cli / firmware / udev) for focus + LED; add the standalone TMC2209
   rail driver (GPIO stage package + wiring config).
4. **Measure the field of view at the chip window** → decide lift stage
   yes/no (§7.1a: needed only if FOV < 8 mm window height).
5. **Parts check/order for the X axis:** NEMA17 Tr8×2 linear stepper
   (≤1.5 A, spindle = scan + 60 mm), 2040 V-Slot, MGN12 rail + carriage,
   12–24 V supply. TMC2209 stepsticks already on hand.
