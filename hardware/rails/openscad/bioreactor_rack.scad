// Mesoscope RAILS — parametric bioreactor bridge (Brücke), hochkant hanging
//
// Holds N bioreactor chips ("Chip senkrecht") in series along X, HANGING
// hochkant, for the tilted-microscope linear-rail scan
// (see docs/RAIL_MOUNT_CONCEPT.md §3, §6).
//
// Concept (metal-spine assembly — supersedes both the old base-plate slot+clamp
// design AND the continuous one-piece board):
//   * Each chip is dropped in FROM THE TOP. A 2 mm Kranz (rim/flange) around the
//     chip top rests FLAT on the segment top surface (no recess — a Kranz on a
//     flat face seats evenly); the chip then HANGS below. Tubes exit the top,
//     above the Kranz.
//   * Imaging is horizontal THROUGH the 16 mm chip thickness: light source on
//     +Y -> chip -> objective on -Y. The optical window sits at the chip's
//     vertical centre (= the optical axis), well below the segment, so the
//     board never blocks the objective.
//   * The row is SUBDIVIDED into one printable SEGMENT per station (~pitch mm
//     each) so no single part exceeds the print bed. The segments do NOT carry
//     the span load through printed joints: at pitch 75 the ~4 mm gap between
//     adjacent chip holes leaves no room for a robust half-lap/pin/screw joint.
//     Instead TWO STEEL RODS (the metal "Rückgrat"/spine) run in X through the
//     front/back Y-rails of every segment and anchor in the two end pillars.
//     The rods carry all bending; each segment is threaded on like a bead and
//     locked in X by a small set screw. This removes tolerance stack-up and sag.
//   * The pillars rise from the shared base plate (Grundplatte); the space
//     BELOW the chips stays free so the moving mesoscope reaches every station.
//
// The chip itself exists only as a mesh STL (no SCAD source), so the chip+Kranz
// here is a NON-PRINT reference block (show_chip_ref) for visualising the mating
// fit. The STEEL RODS are likewise NON-PRINT reference (show_spine); their bores
// ARE subtracted from the printed segments and pillars. The printed parts are
// the N segments + 2 pillars.
//
// STANDALONE: unlike the optics/stand modules this file has NO upstream
// OpenFlexure dependency — render it directly.
//   ./build_rack.sh 3
//   openscad -o rack.stl -D N=3 bioreactor_rack.scad
//
// Axes (in-use orientation, matching the massing model rail_mount_mesoscope.scad):
//   X = along the rail / chip width
//   Y = optical axis / chip thickness (imaged through)
//   Z = vertical (gravity down); chips hang, segments + spine + pillars above

// ---------------------------------------------------------------------------
// Chip geometry (bare body, hanging hochkant; base plate excluded per doc §6)
// ---------------------------------------------------------------------------
chip_w = 70;    // X  chip width (along the rail)
chip_t = 16;    // Y  chip thickness (optical axis, imaged through) — imaging
                //    chamber thickness per doc; the mesh shows more material in
                //    Y, confirm by STL overlay and adjust if needed
chip_h = 40;    // Z  chip height (hanging)
window_w = 18;  // X  optical cutout width on the -Y face (ROI Ø5 inside)
window_h = 8;   // Z  optical cutout height
port_d  = 4.5;  // fluidic ports on the TOP edge (tubes point up)
port_dx = 30;   // outer port pair X offset from centre (approx)

// Kranz (hanging flange added around the chip top; rests FLAT on segment top)
kranz_w = 2;    // rim width added per side (X and Y)
kranz_h = 4;    // Z height / thickness of the flange lip (protrudes above top)

// ---------------------------------------------------------------------------
// Rack / bridge configuration
// ---------------------------------------------------------------------------
N = 3;                 // number of stations in series (= number of segments)
reactor_pitch = 75;    // centre-to-centre along X (70 chip + 5 gap)

// Optical-axis height — TODO: finalize once the Z-motor resting face / carriage
// height is fixed (docs/RAIL_MOUNT_CONCEPT.md §2, §7.1a, §8). Chip vertical
// centre (= optical window) lands here, measured from the Grundplatte top (z=0).
OPTICAL_AXIS_H = 115;  // PLACEHOLDER (matches oa_h in the massing model)

board_t = 10;                        // segment board thickness (Z); must be
                                     // thick enough to bury the spine rod bore
                                     // (see assert below) — Ø6 rod needs ≥~9 mm
board_w = chip_t + 2*kranz_w + 20;   // board width in Y (40): chip neck hole in
                                     // the centre + wide front/back rails that
                                     // house the two spine rods
fit = 0.4;                           // chip-neck through-hole clearance per side

// ---------------------------------------------------------------------------
// Metal spine (NON-PRINT steel rods; bores are subtracted from segments+pillars)
// ---------------------------------------------------------------------------
spine_rod_d = 6;       // steel rod diameter (the load-carrying spine); kept
                       // ≤ board_t so the bore stays buried inside the plate
rod_fit     = 0.3;     // rod bore clearance per side (segments slide on)
spine_rod_y = 14;      // |Y| of each rod centre (inside the front/back Y-rails)

// ---------------------------------------------------------------------------
// Segments
// ---------------------------------------------------------------------------
seg_gap     = 0.4;     // print gap between adjacent segments along X
setscrew_d  = 3.4;     // M3 set screw, from the top into the rod bore, locks X

// ---------------------------------------------------------------------------
// Pillars (end supports that anchor the rods and bolt to the Grundplatte)
// ---------------------------------------------------------------------------
pillar        = 30;    // square end-pillar cross-section
bridge_x_clear = 120;  // pillar offset beyond the end stations (microscope clears)
foot_h = 6;            // pillar foot slab thickness (Z), bolts to Grundplatte
M5 = 5.3;              // M5 clearance (pillar-foot bolt holes)
BEAM_SLOT_PITCH = 20;  // Grundplatte T-nut hole pattern along X in each foot

// Draw the NON-PRINT reference geometry. Both OFF by default so the built STL
// is the printable segments + pillars only; enable for preview:
//   -D show_chip_ref=true -D show_spine=true
show_chip_ref = false;
show_spine    = false;

$fn = 48;
EPS = 0.01;

// ---------------------------------------------------------------------------
// Derived layout
// ---------------------------------------------------------------------------
span        = (N - 1) * reactor_pitch;          // X extent of the station row
chip_top_z  = OPTICAL_AXIS_H + chip_h/2;        // chip top
board_top   = chip_top_z - kranz_h;             // Kranz rests FLAT on the top
board_bottom= board_top - board_t;
board_mid   = board_bottom + board_t/2;         // rods run at mid-thickness
spine_rod_z = board_mid;
kranz_out_x = chip_w + 2*kranz_w;               // Kranz footprint X (74)
kranz_out_y = chip_t + 2*kranz_w;               // Kranz footprint Y (20)

// Pillars (left/right) and rod span
pillar_l_x0 = -bridge_x_clear - pillar;         // left pillar near face
pillar_r_x0 =  span + bridge_x_clear;           // right pillar near face
rod_x0      = pillar_l_x0;                       // rods span pillar to pillar
rod_len     = (pillar_r_x0 + pillar) - pillar_l_x0;

// Sanity checks
assert(reactor_pitch >= kranz_out_x, "reactor_pitch too small: Kränze would overlap");
assert(board_w/2 >= spine_rod_y + spine_rod_d/2 + 1,
       "board_w too small: spine rod would break out of the Y-rail");
assert(board_t/2 >= spine_rod_d/2 + rod_fit + 1,
       "board_t too small: spine rod bore would break through the top/bottom faces");
assert(spine_rod_y - (spine_rod_d/2 + rod_fit) >= chip_t/2 + fit,
       "spine_rod_y too small: rod bore would collide with the chip through-hole");
assert(board_bottom >= 0, "OPTICAL_AXIS_H too small: board_bottom below the Grundplatte");
assert(board_top > spine_rod_z, "set screw cannot reach the rod from the top");
echo(str("Bridge (metal-spine): N=", N, " segments  pitch=", reactor_pitch,
         "mm  row span=", span, "mm  segment=", reactor_pitch - seg_gap, " x ",
         board_w, " x ", board_t, "mm  board_top z=", board_top,
         "mm  rods=2x Ø", spine_rod_d, " len=", rod_len,
         "mm  Kranz gap=", reactor_pitch - kranz_out_x, "mm"));

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------

// One printable segment: a board slice (one pitch wide) around one station,
// with the chip-neck through-hole, two spine-rod bores through the Y-rails, and
// a top set-screw hole per rod. Local origin at the world station centre in X.
module segment(k) {
    xc = k * reactor_pitch;
    x0 = xc - reactor_pitch/2 + seg_gap/2;
    x1 = xc + reactor_pitch/2 - seg_gap/2;
    color([0.8, 0.55, 0.3])
    difference() {
        // board slice
        translate([x0, -board_w/2, board_bottom]) cube([x1 - x0, board_w, board_t]);
        // chip-neck through-hole (full thickness), centred at xc, centred in Y
        translate([xc - (chip_w/2 + fit), -(chip_t/2 + fit), board_bottom - EPS])
            cube([chip_w + 2*fit, chip_t + 2*fit, board_t + 2*EPS]);
        // two spine-rod bores along X through the front/back rails
        for (sy = [spine_rod_y, -spine_rod_y])
            translate([x0 - EPS, sy, spine_rod_z]) rotate([0, 90, 0])
                cylinder(d = spine_rod_d + 2*rod_fit, h = (x1 - x0) + 2*EPS);
        // M3 set screw from the top down into each rod bore (locks X position)
        for (sy = [spine_rod_y, -spine_rod_y])
            translate([xc, sy, spine_rod_z])
                cylinder(d = setscrew_d, h = (board_top - spine_rod_z) + EPS);
    }
}

// One end pillar from the Grundplatte up to the board top, with rod bores and a
// foot slab with M5 bolt holes to the Grundplatte. px = pillar near-face X.
module pillar_with_foot(px) {
    foot_x = pillar + 2*BEAM_SLOT_PITCH;   // foot wider than the pillar for bolts
    color([0.8, 0.45, 0.25])
    difference() {
        union() {
            // pillar (down through the foot so the two fuse into one solid)
            translate([px, -pillar/2, -foot_h])
                cube([pillar, pillar, board_top + foot_h]);
            // foot slab, centred in Y
            translate([px - BEAM_SLOT_PITCH, -foot_x/2, -foot_h])
                cube([foot_x, foot_x, foot_h]);
        }
        // two M5 holes straddling the pillar along X
        for (hx = [px + pillar/2 - BEAM_SLOT_PITCH, px + pillar/2 + BEAM_SLOT_PITCH])
            translate([hx, 0, -foot_h - EPS])
                cylinder(d = M5, h = foot_h + 2*EPS);
        // rod bores through the pillar (rods anchor here)
        for (sy = [spine_rod_y, -spine_rod_y])
            translate([px - EPS, sy, spine_rod_z]) rotate([0, 90, 0])
                cylinder(d = spine_rod_d + 2*rod_fit, h = pillar + 2*EPS);
    }
}

// NON-PRINT reference: the two steel spine rods, pillar to pillar.
module spine() {
    color([0.6, 0.6, 0.62])
    for (sy = [spine_rod_y, -spine_rod_y])
        translate([rod_x0, sy, spine_rod_z]) rotate([0, 90, 0])
            cylinder(d = spine_rod_d, h = rod_len);
}

// NON-PRINT reference: one chip + 2 mm Kranz + window + top tube stubs, for
// visual fit only. Local origin at the station centre in X.
module chip_ref() {
    // chip body (hanging), vertical centre on the optical axis
    color([0.75, 0.85, 0.9, 0.55])
    translate([-chip_w/2, -chip_t/2, OPTICAL_AXIS_H - chip_h/2])
        cube([chip_w, chip_t, chip_h]);
    // Kranz flange around the top (rests flat on the segment top)
    color([0.55, 0.75, 0.85, 0.7])
    translate([-kranz_out_x/2, -kranz_out_y/2, chip_top_z - kranz_h])
        cube([kranz_out_x, kranz_out_y, kranz_h]);
    // optical window on the -Y (objective-facing) face, on the axis
    color([0.1, 0.6, 0.9, 0.8])
    translate([-window_w/2, -chip_t/2 - 0.6, OPTICAL_AXIS_H - window_h/2])
        cube([window_w, 0.8, window_h]);
    // top tube stubs
    color([0.15, 0.15, 0.15, 0.8])
    for (dx = [-port_dx, -port_dx + 12, port_dx - 12, port_dx])
        translate([dx, 0, chip_top_z]) cylinder(h = 16, d = port_d);
}

module rack() {
    for (k = [0 : N-1]) segment(k);
    pillar_with_foot(pillar_l_x0);
    pillar_with_foot(pillar_r_x0);
    if (show_spine) spine();
    if (show_chip_ref)
        for (i = [0 : N-1]) translate([i*reactor_pitch, 0, 0]) chip_ref();
}

rack();
