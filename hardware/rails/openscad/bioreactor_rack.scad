// Mesoscope RAILS — parametric bioreactor rack
//
// Holds N bioreactor chips ("Chip senkrecht mit Bodenplatte") in series along X
// on a 2040 V-Slot beam, for the tilted-microscope linear-rail scan
// (see docs/RAIL_MOUNT_CONCEPT.md). Each chip drops into a vertical slot and is
// held against a back-wall datum; a removable clamp bar retains it.
//
// STANDALONE: unlike the optics/stand modules this file has NO upstream
// OpenFlexure dependency — render it directly.
//   ./build_rack.sh 3
//   openscad -o rack.stl -D N=3 bioreactor_rack.scad
//
// Axes (in-use orientation, matching the chip STL):
//   X = along the rail / plate width       (plate 140)
//   Y = optical axis / plate thickness      (plate 0..8.5, chip protrudes to ~40.5)
//   Z = vertical, plate height              (plate 100), gravity down
// The objective looks in from +Y at the chip; transmitted light enters from -Y
// through the back-wall window. Print orientation: as modelled the back wall is a
// good first layer if laid on its -Y face; see readme note.

// ---------------------------------------------------------------------------
// Measured chip geometry (from hardware/bioreactors/chip_senkrecht_mit_bodenplatte.stl)
// ---------------------------------------------------------------------------
PLATE_W = 140;      // base plate width  (X)
PLATE_H = 100;      // base plate height (Z)
PLATE_T = 8.5;      // base plate thickness (Y) — the part gripped by the slot
CHIP_PROTRUSION = 32;   // how far the chip body sticks out in +Y beyond the plate front
                        // (rack front must stay clear of this for the objective)

// ---------------------------------------------------------------------------
// Rack configuration
// ---------------------------------------------------------------------------
N = 3;              // number of stations in series
FIT = 0.4;          // slot clearance per side (drop-in fit)
GRIP = 12;          // perimeter width the rack grips (front lips + window border)
DIVIDER = 8;        // shared side/divider wall thickness (X)
WALL = 4;           // back wall thickness (Y)
FRONT_LIP = 3;      // depth of the front capture lip (Y overhang holding the plate)
LEDGE = 4;          // bottom ledge thickness (Z) the plate rests on
CLAMP_GAP = 6;      // gap between clamp bars in the print layout (must be > 0 so they don't fuse)

PITCH = PLATE_W + DIVIDER;   // station spacing along X (adjacent plates, shared wall)

// Optics coupling — TODO: finalize once the Z-motor resting face / carriage
// optical-axis height is fixed (docs/RAIL_MOUNT_CONCEPT.md §2, §7.2).
// Vertical distance from the 2040 beam top face to the chip window centre (plate Z=50).
OPTICAL_AXIS_H = 60;         // PLACEHOLDER

// 2040 beam interface
BEAM_W = 40;                 // beam face width the foot sits on (Y)
BEAM_SLOT_PITCH = 20;        // M5 T-nut hole pattern along X
FOOT_H = 6;                  // foot slab thickness (Z)
M5 = 5.3;                    // M5 clearance
M3 = 3.3;                    // M3 clearance (clamp screws)

$fn = 48;
EPS = 0.01;

// Derived
Z0 = OPTICAL_AXIS_H - PLATE_H/2;        // plate bottom Z (window centre lands at OPTICAL_AXIS_H)
SLOT_T = PLATE_T + 2*FIT;               // slot channel width (Y)
RACK_W = (N-1)*PITCH + PLATE_W + 2*DIVIDER;   // total X footprint (outer face to outer face)

// Sanity checks
assert(PITCH >= PLATE_W, "PITCH must be >= PLATE_W (plates would overlap)");
assert(GRIP*2 < PLATE_W && GRIP*2 < PLATE_H, "GRIP too large: window would vanish");
assert(FIT > 0, "FIT must be positive for a drop-in fit");
assert(Z0 >= 0, "OPTICAL_AXIS_H too small: plate bottom below the beam");
echo(str("Rack: N=", N, " PITCH=", PITCH, "mm  total width=", RACK_W,
         "mm  plate bottom Z0=", Z0, "mm  window=",
         PLATE_W-2*GRIP, "x", PLATE_H-2*GRIP, "mm"));

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------

// One station, local origin at the plate's back-bottom-left corner projected to
// beam top (x=0 plate left edge, y=0 plate back/datum face, z=0 beam top).
module station() {
    difference() {
        union() {
            // back wall (datum) — full support height, plate width
            translate([0, -WALL, 0])
                cube([PLATE_W, WALL, Z0 + PLATE_H]);

            // side / divider walls (shared with neighbour at PITCH)
            for (sx = [-DIVIDER, PLATE_W])
                translate([sx, -WALL, 0])
                    cube([DIVIDER, WALL + SLOT_T + FRONT_LIP, Z0 + PLATE_H]);

            // bottom ledge the plate rests on
            translate([0, 0, Z0 - LEDGE])
                cube([PLATE_W, SLOT_T, LEDGE]);

            // front capture lips (overhang the plate front edges, hold it to the datum)
            for (lx = [0, PLATE_W - GRIP])
                translate([lx, PLATE_T + FIT, Z0])
                    cube([GRIP, FRONT_LIP, PLATE_H]);
        }

        // transmitted-light window through the back wall
        translate([GRIP, -WALL - EPS, Z0 + GRIP])
            cube([PLATE_W - 2*GRIP, WALL + 2*EPS, PLATE_H - 2*GRIP]);

        // M3 clamp-screw holes in the tops of both side walls
        for (hx = [-DIVIDER/2, PLATE_W + DIVIDER/2])
            translate([hx, (SLOT_T)/2 - WALL/2, Z0 + PLATE_H - 12])
                cylinder(d = M3, h = 12 + EPS);
    }
}

// Base flange spanning all stations, bolts onto the 2040 beam.
module beam_foot() {
    y_mid = SLOT_T/2;                       // rack footprint mid-line in Y
    difference() {
        translate([-DIVIDER, y_mid - BEAM_W/2, -FOOT_H])
            cube([RACK_W, BEAM_W, FOOT_H]);
        // M5 through-holes on the beam centreline at BEAM_SLOT_PITCH
        n_holes = floor((RACK_W - BEAM_SLOT_PITCH) / BEAM_SLOT_PITCH) + 1;
        x_start = -DIVIDER + (RACK_W - (n_holes-1)*BEAM_SLOT_PITCH)/2;
        for (i = [0 : n_holes-1])
            translate([x_start + i*BEAM_SLOT_PITCH, y_mid, -FOOT_H - EPS])
                cylinder(d = M5, h = FOOT_H + 2*EPS);
    }
}

// Removable clamp bar (one per station) — laid flat beside the rack for printing.
// Spans the slot, screwed down with M3 into the two side walls.
module clamp_bar() {
    bar_l = PLATE_W + DIVIDER;      // reaches onto both side walls
    bar_w = 12;
    bar_t = 5;
    difference() {
        translate([-DIVIDER/2, -bar_w/2, 0]) cube([bar_l, bar_w, bar_t]);
        // M3 clearance holes matching the side-wall centres
        for (hx = [-DIVIDER/2, PLATE_W + DIVIDER/2])
            translate([hx, 0, -EPS]) cylinder(d = M3, h = bar_t + 2*EPS);
    }
}

module rack() {
    beam_foot();
    for (i = [0 : N-1])
        translate([i*PITCH, 0, 0]) station();
    // clamp bars laid flat on the bed in front of the rack for printing.
    // Spaced at PITCH+CLAMP_GAP so the copies do not abut (bar length == PITCH),
    // keeping each bar a separate printable/removable piece.
    for (i = [0 : N-1])
        translate([i*(PITCH + CLAMP_GAP), -WALL - BEAM_W/2 - 20, 0]) clamp_bar();
}

rack();
