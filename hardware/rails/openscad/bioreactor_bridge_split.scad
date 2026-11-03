// Mesoscope RAILS — bioreactor bridge (Brücke) as ONE printable piece on two
// separate end towers (Türme). 3 printed parts total: 1 bridge + 2 towers.
//
// Holds N bioreactor chips ("Chip senkrecht") in series along X, HANGING
// hochkant, for the tilted-microscope linear-rail scan
// (see docs/RAIL_MOUNT_CONCEPT.md §3, §6).
//
// Concept (one-piece bridge + separate towers — supersedes the earlier
// 3-segment half-lap split of this same file, and is the alternative to the
// metal-spine rack of bioreactor_rack.scad):
//   * ONE continuous traverse board (the bridge) with a drop-in chip through-
//     hole per station; each chip drops in FROM THE TOP, a 2 mm Kranz (rim)
//     rests FLAT on the board top, the chip HANGS below. Tubes exit the top.
//   * Imaging is horizontal THROUGH the 16 mm chip thickness: light source +Y ->
//     chip -> objective -Y. The optical window sits at the chip vertical centre
//     (= optical axis), well below the board, so the board never blocks the view.
//   * The bridge spans only the STATION ROW plus a short end margin (no long
//     overhang), so at N<=3 it stays UNDER the 300 mm print bed and prints as a
//     SINGLE piece — no splice needed. (At N>=4 the bare chip row already
//     exceeds the bed; reduce N or re-introduce a splice.)
//   * Two separate end TOWERS rise from the shared base plate (Grundplatte) and
//     sit just OUTSIDE the end chips; the bridge ends drop onto the tower tops
//     over 2x press-fit locating pins each (no screws). The space BELOW the chips
//     stays free so the moving mesoscope reaches every station.
//
// The chip itself exists only as a mesh STL (no SCAD source), so the chip+Kranz
// here is a NON-PRINT reference block (show_chip_ref) for visualising the fit.
// The printed parts are the 1 bridge board + 2 towers.
//
// STANDALONE: no upstream OpenFlexure clone needed — render directly.
//   ./build_bridge_split.sh 3
//   openscad -o bridge.stl -D part="bridge" -D N=3 bioreactor_bridge_split.scad
//   openscad            -D part="all"  bioreactor_bridge_split.scad   // F5 preview
//
// Axes (in-use orientation, matching rail_mount_mesoscope.scad / bioreactor_rack.scad):
//   X = along the rail / chip width
//   Y = optical axis / chip thickness (imaged through)
//   Z = vertical (gravity down); chips hang, bridge + towers above

// ---------------------------------------------------------------------------
// Chip geometry (bare body, hanging hochkant; base plate excluded per doc §6)
// ---------------------------------------------------------------------------
chip_w = 70;    // X  chip width (along the rail)
chip_t = 16;    // Y  chip thickness (optical axis, imaged through)
chip_h = 40;    // Z  chip height (hanging)
window_w = 18;  // X  optical cutout width on the -Y face (ROI Ø5 inside)
window_h = 8;   // Z  optical cutout height
port_d  = 4.5;  // fluidic ports on the TOP edge (tubes point up)
port_dx = 30;   // outer port pair X offset from centre (approx)

// Kranz (hanging flange around the chip top; rests FLAT on the board top)
kranz_w = 2;    // rim width added per side (X and Y)
kranz_h = 4;    // Z height of the flange lip (protrudes above the board top)

// ---------------------------------------------------------------------------
// Bridge configuration
// ---------------------------------------------------------------------------
N = 3;                 // number of stations in series (<=3 keeps the bridge 1-piece)
reactor_pitch = 80;    // centre-to-centre along X (70 chip + 10 gap)

// Optical-axis height — TODO: finalize once the Z-motor resting face / carriage
// height is fixed (docs/RAIL_MOUNT_CONCEPT.md §2, §7.1a, §8). Chip vertical
// centre (= optical window) lands here, measured from the Grundplatte top (z=0).
OPTICAL_AXIS_H = 115;  // PLACEHOLDER (matches oa_h in the massing model)

board_t = 4;                        // bridge board thickness (Z) — halved from 8
board_w = chip_t + 2*kranz_w + 4;   // board width in Y (24): chip hole + margin
fit     = 0.4;                      // chip through-hole clearance per side

// End margin: how far the board extends beyond the OUTER chip edge at each end.
// The tower sits in this margin, just outside the end chip. Larger = more head
// clearance at the end stations, but a longer (eventually too-long) bridge.
end_ext = 25;

// ---------------------------------------------------------------------------
// Bridge <-> tower connection: locating pins ON THE M3 PATTERN
// ---------------------------------------------------------------------------
// The BRIDGE is unchanged from the original screwed design: 2x M3 clearance
// through-holes per end at +/- screw_dy. This keeps an already-printed first
// bridge piece reusable. Only the TOWERS change: where the M3 blind holes used
// to be, solid pins now stand up and slip into those same M3 holes. The holes
// stay M3, so an M3 screw remains an option for extra retention. Two pins per
// end give anti-rotation. pin_d is the tuning knob: raise toward m3_clear for a
// snugger fit, lower for an easier slip.
m3_clear = 3.4;  // bridge through-hole (M3 clearance) — UNCHANGED, keeps old bridge usable
screw_dy = 7;    // Y offset of the pin/hole pair per end (the original M3 pattern)
pin_d    = 3.2;  // tower locating pin: slips into the M3 clearance hole (~0.2 play)
pin_h    = 5;    // pin height (Z); >= board_t -> full engagement, tip stands slightly proud
MAX_BED  = 300;  // print-bed limit (X); the one-piece bridge must stay under this

// ---------------------------------------------------------------------------
// Towers (slim end supports: bolt to the Grundplatte, carry the bridge ends)
// ---------------------------------------------------------------------------
pillar        = 20;    // square tower cross-section (slim so the bridge end clears the end chip)
foot_h = 6;            // tower foot slab thickness (Z), bolts to Grundplatte
M5 = 5.3;              // M5 clearance (tower-foot bolt holes)
BEAM_SLOT_PITCH = 20;  // Grundplatte T-nut hole pattern along X in each foot

// Preview / render switches
part          = "all"; // "all" | "bridge" | "pillarL" | "pillarR"
exploded      = false; // lift the bridge off the towers for a presentation render
show_chip_ref = false; // draw NON-PRINT chip+Kranz reference blocks

$fn = 48;
EPS  = 0.01;

// ---------------------------------------------------------------------------
// Derived layout
// ---------------------------------------------------------------------------
span        = (N - 1) * reactor_pitch;     // X extent of the station row (centres)
// The bridge covers the station row + end_ext beyond each outer chip edge.
bx0         = -chip_w/2 - end_ext;         // board start (just left of the first chip)
bx1         =  span + chip_w/2 + end_ext;  // board end   (just right of the last chip)
board_len   = bx1 - bx0;

// Towers sit under the board ends, just outside the end chips.
pillar_l_cx = bx0 + pillar/2;              // left tower centre (X)
pillar_r_cx = bx1 - pillar/2;              // right tower centre (X)

chip_top_z  = OPTICAL_AXIS_H + chip_h/2;   // chip top
board_top   = chip_top_z - kranz_h;        // Kranz rests FLAT on the board top
board_bottom= board_top - board_t;

y0          = -board_w/2;                  // board spans y0 .. y0+board_w

// Outer chip / Kranz edges (for the tower-clearance assertion)
kranz_half_x = chip_w/2 + kranz_w;         // Kranz reaches ±kranz_half_x in X
pillar_l_inner = pillar_l_cx + pillar/2;   // inner face of the left tower
pillar_r_inner = pillar_r_cx - pillar/2;

// Sanity checks
assert(N >= 2, "N must be >= 2 for a series bridge.");
assert(board_len < MAX_BED,
       str("one-piece bridge too long for the bed: ", board_len,
           " mm >= ", MAX_BED, " mm — reduce N or re-introduce a splice."));
assert(pillar_l_inner <= -kranz_half_x,
       "left tower overlaps the first chip/Kranz in X — increase end_ext or slim the tower.");
assert(pillar_r_inner >= span + kranz_half_x,
       "right tower overlaps the last chip/Kranz in X — increase end_ext or slim the tower.");
assert(board_bottom >= 0, "OPTICAL_AXIS_H too small: board_bottom below the Grundplatte.");
assert(screw_dy + m3_clear/2 < board_w/2, "screw_dy too large: M3 holes break out of the board width.");
assert(screw_dy + pin_d/2 < pillar/2 - 1, "screw_dy too large: pin wall on the tower top too thin.");
assert(pin_h <= board_t + 3, "pin_h too long: pin protrudes too far above the board top.");
echo(str("Bridge (1-piece): N=", N, "  board=", board_len, " x ", board_w, " x ", board_t,
         "mm (bed ", MAX_BED, ")  towers @ X=", pillar_l_cx, ",", pillar_r_cx,
         "  board_top z=", board_top));

// ---------------------------------------------------------------------------
// Per-station chip through-holes
// ---------------------------------------------------------------------------
module board_holes() {
    for (k = [0 : N-1]) {
        xc = k * reactor_pitch;
        translate([xc - (chip_w/2 + fit), -(chip_t/2 + fit), board_bottom - EPS])
            cube([chip_w + 2*fit, chip_t + 2*fit, board_t + 2*EPS]);
    }
}

// ---------------------------------------------------------------------------
// The one-piece bridge board
// ---------------------------------------------------------------------------
module bridge() {
    color([0.8, 0.55, 0.3])
    difference() {
        translate([bx0, y0, board_bottom]) cube([board_len, board_w, board_t]);
        board_holes();
        // M3 clearance through-holes: 2x per end over each tower (UNCHANGED from
        // the original screwed bridge, so an already-printed bridge still fits).
        for (px = [pillar_l_cx, pillar_r_cx])
            for (sy = [screw_dy, -screw_dy])
                translate([px, sy, board_bottom - EPS])
                    cylinder(d = m3_clear, h = board_t + 2*EPS);
    }
}

// ---------------------------------------------------------------------------
// End towers: Grundplatte -> board bottom, M5 foot bolts + 2x M3 board bolts up top
// ---------------------------------------------------------------------------
module tower_with_foot(px) {
    foot_x = pillar + 2*BEAM_SLOT_PITCH;
    color([0.8, 0.45, 0.25]) {
        difference() {
            union() {
                translate([px - pillar/2, -pillar/2, -foot_h])
                    cube([pillar, pillar, board_bottom + foot_h]);
                translate([px - foot_x/2, -foot_x/2, -foot_h])
                    cube([foot_x, foot_x, foot_h]);
            }
            // M5 Grundplatte bolts straddling the tower along X
            for (hx = [px - BEAM_SLOT_PITCH, px + BEAM_SLOT_PITCH])
                translate([hx, 0, -foot_h - EPS]) cylinder(d = M5, h = foot_h + 2*EPS);
        }
        // 2x solid locating pins on the tower top, on the M3 pattern (replacing
        // the old M3 blind holes). They slip into the bridge's M3 holes. Printed
        // standing up from the tower top at z = board_bottom.
        for (sy = [screw_dy, -screw_dy])
            translate([px, sy, board_bottom]) cylinder(d = pin_d, h = pin_h);
    }
}

// ---------------------------------------------------------------------------
// NON-PRINT reference: one chip + 2 mm Kranz + window + top tube stubs
// ---------------------------------------------------------------------------
module chip_ref() {
    kox = chip_w + 2*kranz_w;
    koy = chip_t + 2*kranz_w;
    color([0.75, 0.85, 0.9, 0.55])
    translate([-chip_w/2, -chip_t/2, OPTICAL_AXIS_H - chip_h/2])
        cube([chip_w, chip_t, chip_h]);
    color([0.55, 0.75, 0.85, 0.7])
    translate([-kox/2, -koy/2, chip_top_z - kranz_h]) cube([kox, koy, kranz_h]);
    color([0.1, 0.6, 0.9, 0.8])
    translate([-window_w/2, -chip_t/2 - 0.6, OPTICAL_AXIS_H - window_h/2])
        cube([window_w, 0.8, window_h]);
    color([0.15, 0.15, 0.15, 0.8])
    for (dx = [-port_dx, -port_dx + 12, port_dx - 12, port_dx])
        translate([dx, 0, chip_top_z]) cylinder(h = 16, d = port_d);
}

// ---------------------------------------------------------------------------
// Assembly / dispatch
// ---------------------------------------------------------------------------
ex = exploded ? 70 : 0;   // bridge lift for the preview render

module assembly() {
    translate([0, 0, ex]) bridge();
    tower_with_foot(pillar_l_cx);
    tower_with_foot(pillar_r_cx);
    if (show_chip_ref)
        for (k = [0 : N-1]) translate([k*reactor_pitch, 0, 0]) chip_ref();
}

if      (part == "bridge")  bridge();
else if (part == "pillarL") tower_with_foot(0);
else if (part == "pillarR") tower_with_foot(0);
else                        assembly();   // "all"
