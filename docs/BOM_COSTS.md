# Bill of Materials & Cost Comparison

State: 2026-09-08. All prices **EUR incl. VAT** unless noted. Column *Price basis*:
**est.** = estimate from `README.md` BOM (no invoice in repo) · **market** = typical used/new
market price · **TODO** = enter actual invoice value. Replace estimates with invoice values
before the thesis (appendix A).

## A. Mesoscope — parts actually installed / on hand

### A.1 Compute & control

| # | Part | Qty | Unit € | Line € | Price basis | Status |
|---|------|-----|--------|--------|-------------|--------|
| 1 | Raspberry Pi 5, 8 GB | 1 | 80 | 80 | est. | installed |
| 2 | Raspberry Pi AI HAT+ (Hailo-8, 26 TOPS) | 1 | 70 | 70 | est. | installed |
| 3 | DS3231 RTC module | 1 | 5 | 5 | est. | installed |
| 4 | GPIO stacking header (RTC pass-through) | 1 | 3 | 3 | est. | installed |
| 5 | microSD ≥ 32 GB (117 GB used in profile → 128 GB) | 1 | 10 | 10 | est. | installed |
| 6 | USB-C PSU 27 W (official) | 1 | 15 | 15 | est. | installed |
| 7 | 28BYJ-48 stepper, 5 V (Z-focus; 2 spare from original XYZ plan) | 3 | 2 | 6 | est. | on hand |
| 8 | ULN2003 driver board (bundled with 28BYJ-48) | 3 | 1 | 3 | est. | on hand |
| 9 | TMC2209 stepstick (rail axis) | 1 (+spares) | 4 | 4 | market | on hand |
| | **Subtotal compute & control** | | | **196** | | |

### A.2 Optics & imaging

| # | Part | Qty | Unit € | Line € | Price basis | Status |
|---|------|-----|--------|--------|-------------|--------|
| 10 | Raspberry Pi HQ Camera (IMX477, C-mount) | 1 | 35 | 35 | est. | installed |
| 11 | **ZEISS Plan-Neofluar 10×/0.30** objective | 1 | 0 (owned) / 150–350 | 0 | market (used); TODO if purchased | installed |
| 12 | Achromatic doublet tube lens f = 125 mm, Ø12.7 mm (Taulab, 2026-06-22) | 1 | 25 | 25 | TODO (invoice) | installed |
| 13 | Achromatic doublet tube lens f = 150 mm, Ø12.7 mm (Taulab, 2026-06-22) | 1 | 25 | 25 | TODO (invoice) | spare |
| 14 | PMMA condenser lens Ø13 mm f = 5 mm + LED (stock OFM illumination) | 1 | 3 | 3 | est. | not used in rail concept |
| | **Subtotal optics** (objective at 0) | | | **88** | | |
| | *Subtotal optics with objective at market value (250)* | | | *(338)* | | |

### A.3 Printed parts (PLA black, 0.2 mm, 3 walls, 20–30 % infill)

Mass estimated as solid STL volume × 1.24 g/cm³ × 0.6 (wall/infill factor); filament at 25 €/kg.
Print times from the `.bgcode` filenames in `hardware/gcode/` where available.

| # | Part (STL) | Solid vol. cm³ | ≈ mass g | ≈ € | Print time | Status |
|---|------------|---------------:|---------:|----:|-----------|--------|
| 15 | `main_body_mesoscope.stl` (Z-only body) | 87.6 | 65 | 1.6 | — | STL, test print pending |
| 16 | `optics_hq_125_rms_threaded.stl` | 28.5 | 21 | 0.5 | 1 h 07 (PETG) | printed |
| 17 | `microscope_stand_mesoscope.stl` | 122.7 | 91 | 2.3 | — | STL |
| 18 | `electronics_drawer_mesoscope.stl` | 35.1 | 26 | 0.7 | 4 h 12 | printed |
| 19 | `feet.stl` | 6.0 | 4 | 0.1 | — | STL |
| 20 | `large_gears.stl` + `small_gears.stl` | 12.3 | 9 | 0.2 | — | STL |
| 21 | `picamera_hq_cover.stl` | 2.1 | 2 | 0.1 | — | STL |
| 22 | `bioreactor_rack_n3.stl` (rail concept) | 305.3 | 227 | 5.7 | — | STL, geometry unconfirmed |
| 23 | tools (`actuator_assembly_tools`, `lens_tool`, `cable_tidies`) | 20.7 | 15 | 0.4 | — | STL |
| | **Subtotal printed** (≈ 460 g) | | | **≈ 12** | | |

### A.4 Fasteners & consumables (OFM standard)

| # | Part | Qty | Line € | Price basis |
|---|------|-----|--------|-------------|
| 24 | M3 screws/nuts, M3×25 hex-head actuator screws, M2 camera screws | set | 5 | est. |
| 25 | Viton O-rings (actuator preload) | 3 | 3 | est. |
| 26 | LED 5 mm + resistor, wire | 1 | 2 | est. |
| | **Subtotal** | | **10** | |

### A.5 Totals — microscope as currently built (no rail)

| Scope | € |
|-------|---|
| Compute & control (A.1) | 196 |
| Optics, objective owned (A.2) | 88 |
| Printed parts (A.3) | 12 |
| Fasteners (A.4) | 10 |
| **Total, objective owned** | **≈ 306** |
| of which "microscope only" (without Pi 5 + AI HAT + RTC + SD + PSU: −183) | ≈ 123 |
| **Total incl. objective at market value (250)** | **≈ 556** |

> The Pi 5 + AI HAT+ stack (≈ 150 €) is the price of on-device inference; the
> OpenFlexure reference designs use a Pi 3/4 without NPU (see §C).

## B. Rail mount — planned, not yet purchased (`docs/RAIL_MOUNT_CONCEPT.md` §7, decided 2026-09-02)

| # | Part | Qty | Unit € | Line € | Price basis |
|---|------|-----|--------|--------|-------------|
| 27 | 2040 V-slot aluminium extrusion, ≈ 500 mm | 1 | 12 | 12 | market |
| 28 | MGN12H linear rail 400–500 mm + carriage | 1 | 25 | 25 | market |
| 29 | NEMA17 with integrated Tr8×2 leadscrew (≈ 400 mm), ≤ 1.5 A | 1 | 25 | 25 | market |
| 30 | Anti-backlash nut (Tr8×2) + KFL08 end bearing + coupler | 1 set | 10 | 10 | market |
| 31 | 12–24 V PSU ≥ 2 A | 1 | 15 | 15 | market |
| 32 | Base plate (Grundplatte), bridge board, pillars (plywood/aluminium) | 1 set | 20 | 20 | est. |
| 33 | Carriage adapter + tilt mount (printed, ≈ 150 g) | 1 | 4 | 4 | est. |
| 34 | Trans-illumination LED panel/diffuser per station | 3–4 | 4 | 16 | est. |
| 35 | Cables, terminals, 100 µF caps, end-stop switches | set | 10 | 10 | est. |
| | **Subtotal rail mount** | | | **≈ 137** | |

**Full system (A + B), objective owned: ≈ 443 €** — inside the < 500 € target of RQ1.

## C. OpenFlexure project reference BOMs (published prices)

Research date 2026-09-08. The official v7 BOM pages list **items and quantities only, no
prices**; prices come from the project's papers and from kit vendors.

### C.1 Official v7 BOM (v7.0.0-beta1, build.openflexure.org) — items, no prices

| Category | Item | Low-cost | High-res |
|----------|------|:-------:|:--------:|
| Printed | PLA filament (any colour) | 205 g | 205 g |
| Printed | Black PLA (optics) | 50 g | 50 g |
| Material | 0.5 mm polypropylene sheet | 4 cm² | 4 cm² |
| Optics | Condenser lens f = 5 mm | 1 | 1 |
| Optics | Ø12.7 mm achromatic doublet (tube lens) | – | 1 |
| Optics | RMS objective, 160 mm finite | – | 1 |
| Electronics | Raspberry Pi 3B/3B+/4B | 1 | 1 |
| Electronics | Pi Camera Module v2 | 1 | 1 |
| Electronics | 200 mm camera ribbon | 1 | 1 |
| Electronics | Pi PSU | 1 | 1 |
| Electronics | Sangaboard v0.5 | 1 | 1 |
| Electronics | 28BYJ-48 geared stepper | 3 | 3 |
| Electronics | Illumination PCB + 2× 2-pin DuPont | 1 | 1 |
| Mechanical | M3 brass nut 3; M3 SS nut 14; M3 washer 8; M3×10 cap 11; M3×25 hex 4; M4×6 button 6; No.2×6.5 self-tap 16–18; Viton O-ring 30×2 3 | set | set |

The Delta Stage BOM is analogous (1 Sangaboard, 3 motors, condenser, objective, tube lens,
3 rubber feet; 16–19 h print, ~18 % infill), no prices. The `hq_camera` GitLab branch has
**no separate BOM or cost documentation**.

### C.2 Project cost estimates (Collins et al. 2020, Biomed. Opt. Express 11(5):2447, SI; UK retail Dec 2019, 1 GBP = 1.30 USD)

| Variant | Itemisation | Total (one-off) |
|---------|-------------|-----------------|
| Low-cost (webcam, no Pi, no motors) | PLA $5, webcam $5, hardware $26 | ≈ **$36** |
| Basic (Pi + Pi Cam, no motors) | PLA $5, Pi $35, Pi Cam v2.1 $25, hardware $26 | ≈ **$91** |
| High-res motorised | PLA $5, Pi $35, Pi Cam $25, hardware $26, 3× 28BYJ-48 $5, achromat $55, RMS objective $50, motor board $50 | ≈ **$251** (bulk hardware ≈ $230) |

Fastener detail (GBP unit/pack): M3×25 hex 0.104/3.12 (×3), M3 brass nut 0.049/2.45 (×4),
M3 washer 0.009/1.80 (×8), M3×8 cap 0.035/2.80 (×14), M2×6 cap 0.11/3.30 (×4), Viton O-ring
0.56/2.80 (×3), 5 mm LED 0.23, 60 Ω resistor 0.03/0.30, M4×6 button 0.06/2.40 (×6) — bulk
total £3.80, one-off £19.20. Assembly 3–4 h novice / 1–2 h experienced; printer excluded.

Later project statements: "around £200 in parts" for the motorised high-res version (MMC
2021); "~$300 to build in the lab" (Knapper, *The Pathologist*, 2024-03); IO Rodeo measured
**$305** for a v7 high-res build (blog 2024-03-20).

### C.3 Kit vendor prices (live 2026-09-08)

| Vendor | Product | Price | Includes | Excludes |
|--------|---------|-------|----------|----------|
| IO Rodeo (US) | Microscope Kit (printed parts + assembly kit) | **$200** | printed parts, Sangaboard v5, 3 motors, Pi Cam v2, illumination, condenser, hardware | Pi, PSU, objective + tube lens |
| IO Rodeo | Assembly Kit (no printed parts) | **$148** | Pi Cam v2, Sangaboard v0.5, 3 motors, 64 GB SD, condenser, illumination, hardware, oil, Allen key | Pi, PSU, high-res optics |
| LabCrafter (UK) | Microscope Kit (low-cost v7) | **£160** (sold out) | Sangaboard v5, motors, Pi Cam v2, illumination, hardware, tools | Pi, PSU, SD |
| LabCrafter | High-Res Upgrade Kit | **£99** (£30 w/o objective) | 40×/160 mm Plan objective, Ø12.7 f = 50 mm achromat, printed optics module + cover | — |
| TauLab (UK/EU) | Sangaboard v5 | **£28** | | |
| TauLab | Illumination kit / bag of bits / tube lens / geared stepper / O-ring / condenser lens / heatsink | £10 / £24 / £23 / £3.50 / £1 / £1 / £4.50 | | |

Other listed vendors without published prices: PSL3D (FR), Malkanicus (UK), MBOALAB (CM),
Fieldworkers (JP), IoWLabs (CL), Science Mate (AU), Bongo Tech (TZ), Pin29 (AR), PKI
Utveckling (SE), Africa OSH (GH).

**Derived single-unit v7 high-res motorised from TauLab parts (2026):** Sangaboard £28 + bag
of bits £24 + illumination £10 + 3 motors £10.50 + tube lens £23 + O-rings £3 + condenser £1
≈ £99.50; plus Pi 4/5 £50–80, Pi Cam v2 £25, PSU £10, objective £50–69, filament 255 g ≈ £6
→ **≈ £260–290 (≈ 305–340 €)**.

## D. Comparison for the thesis

| System | Camera / compute | Stage | Total |
|--------|------------------|-------|-------|
| OFM v7 low-cost (Collins 2020) | webcam, no Pi | manual | $36 |
| OFM v7 high-res motorised (Collins 2020) | Pi Cam v2, Pi 3/4 | XYZ, Sangaboard | $251 |
| OFM v7 high-res motorised (vendor parts 2026) | Pi Cam v2, Pi 4/5 | XYZ, Sangaboard | ≈ 305–340 € |
| **Mesoscope, as built** (§A, objective owned) | IMX477 HQ, Pi 5 + Hailo-8 | Z only | ≈ 306 € |
| **Mesoscope + rail** (§A + B) | IMX477 HQ, Pi 5 + Hailo-8 | Z + X-rail, N chips | ≈ 443 € |
| Mesoscope + rail, objective at market value | | | ≈ 695 € |

Interpretation: the mesoscope replaces the XY flexure stage + Sangaboard (≈ 60 €) with a
linear rail (≈ 137 €) and adds an NPU (≈ 150 € incl. Pi 5 premium); the HQ camera + tube
lens optics cost about the same as the v7 high-res optics. Cost parity with a stock v7 is
therefore within ≈ 1.5×, while gaining multi-vessel scanning and on-device inference.

Sources: build.openflexure.org v7.0.0-beta1 BOM pages (high_res / low_cost), Delta Stage
BOM; Collins et al. 2020 SI (bioRxiv 10.1101/861856); MMC 2021 abstract; *The Pathologist*
2024-03; iorodeo.com products + blog 2024-03-20; labcrafter.co.uk; taulab.eu;
openflexure.org/about/vendors.
