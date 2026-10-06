// Mesoscope — parametric rounded-tooth gear pair (3D print)
//
//   RAD 1  — a toothed RING that hugs an existing gear. Its BORE is the negative
//            of the described gear profile (a keyed, form-fit hole) so it slips
//            over the existing gear and is rotationally locked to it
//            ("schmiegt sich um ein vorhandenes Zahnrad"). NEW teeth sit on the
//            OUTSIDE and drive Rad 2.
//              bore profile (= existing gear): tip R18 / root R16.5, Z=24,
//              tooth ~2.0 mm, valley ~2.5 mm, rounded valleys, + fit clearance.
//
//   RAD 2  — the solid mate on a 5 mm motor shaft with ONE flat (D-shaft, "Nase").
//
// Sizing decision (user): centre distance = 30 mm FIXED, Rad 2 as large as
// possible. Rad 1 must enclose the Ø36 existing gear, so it is the larger wheel;
// equal diameters are geometrically impossible at a 30 mm centre.
//
// Outer mesh math (same module both gears, centre = sum of pitch radii):
//   m (module) = 2*CENTER/(Z1+Z2)    pitch_r = CENTER*Z/(Z1+Z2)
//   Z1=33, Z2=15 -> m=1.25, pr1=20.625, pr2=9.375 (sum=30.000)
//
// STANDALONE: no upstream OpenFlexure clone needed.
//   ./build_gears.sh                 # both gears -> two STLs
//   openscad -o rad1.stl -D part=\"rad1\" gear_pair.scad
//   openscad -o rad2.stl -D part=\"rad2\" gear_pair.scad
//   openscad            -D part=\"demo\" gear_pair.scad   # meshed preview (F5)
//
// ---------------------------------------------------------------------------
// Primary parameters
// ---------------------------------------------------------------------------
part   = "demo";    // "rad1" | "rad2" | "demo"

CENTER = 30.0;      // centre-to-centre distance (mm) — FIXED
H      = 8.0;       // gear thickness / height in Z (mm)

// --- Rad 1 bore = the described existing gear (negative, keyed form-fit) ---
BORE_TIP  = 18.0;   // existing gear tooth tips (Aussenradius)
BORE_ROOT = 16.5;   // existing gear valley bottoms (Innenradius)
Z_BORE    = 24;     // teeth on the existing gear (hugged by Rad 1's bore)
BORE_VR   = 1.30;   // valley rounding of the existing-gear profile
BORE_FIT  = 0.25;   // radial clearance so Rad 1 slips over the existing gear (mm)

// --- Outer mesh (Rad 1 outer teeth <-> Rad 2) ---
Z1     = 33;        // Rad 1 outer teeth (big wheel, must clear the bore)
Z2     = 15;        // Rad 2 teeth (max that fits at a 30 mm centre)
ADD_K  = 0.55;      // addendum  = ADD_K * module
DED_K  = 0.70;      // dedendum  = DED_K * module  (DED_K>ADD_K builds in clearance)
OUT_VR = 1.00;      // outer valley rounding radius (mm); need 2*OUT_VR > tooth depth
BACKLASH = 0.00;    // extra flank gap per tooth for print fit (mm; try 0.1-0.2)

// --- Rad 2 mounting: 5 mm D-shaft (one flat) + grub-screw hub ---
SHAFT_D    = 5.0;   // shaft diameter (mm)
SHAFT_FIT  = 0.2;   // added to bore for slip fit
FLAT_DEPTH = 0.5;   // depth of the shaft flat (D-cut) (mm)
HUB        = true;  // grub-screw hub boss
HUB_D      = 9.0;   // hub boss diameter (mm)
HUB_H      = 5.0;   // hub boss height above the gear face (mm)
SET_M      = 3.2;   // radial grub-screw hole (M3 clearance); 0 = none

MIN_WALL = 1.2;     // minimum ring wall required over the bore (assert guard)
$fn = 200;
EPS = 0.01;

// ---------------------------------------------------------------------------
// Derived
// ---------------------------------------------------------------------------
m_out = 2*CENTER/(Z1+Z2);
pr1   = CENTER*Z1/(Z1+Z2);
pr2   = CENTER*Z2/(Z1+Z2);
add   = ADD_K*m_out;
ded   = DED_K*m_out;
tip1  = pr1 + add;  root1 = pr1 - ded;
tip2  = pr2 + add;  root2 = pr2 - ded;

echo(str("module=", m_out, "  pr1=", pr1, " pr2=", pr2, " sum=", pr1+pr2));
echo(str("Rad1 outer: Z=", Z1, " tip=", tip1, " root=", root1,
         " OD=", 2*tip1, "  wall_over_bore=", root1-(BORE_TIP+BORE_FIT)));
echo(str("Rad2: Z=", Z2, " tip=", tip2, " root=", root2, " OD=", 2*tip2));

assert(root1 >= BORE_TIP + BORE_FIT + MIN_WALL,
       "Rad 1 ring wall too thin over the bore: reduce Z2 / increase CENTER.");
assert(root2 > SHAFT_D/2 + 1.5,
       "Rad 2 too small for the shaft: reduce Z1 or check CENTER.");
assert(FLAT_DEPTH < SHAFT_D/2, "FLAT_DEPTH must be < shaft radius.");

// ---------------------------------------------------------------------------
// Generic rounded-valley tooth profile (2D)
// ---------------------------------------------------------------------------
module gear2d(n, tip_r, root_r, vr, backlash=0) {
    step = 360/n;
    cc   = root_r + vr;                 // valley-cutter centre (bottom at root_r)
    difference() {
        circle(r = tip_r);
        for (i = [0:n-1])
            rotate([0,0,(i+0.5)*step])
                translate([cc,0,0])
                    offset(delta = backlash/2) circle(r = vr);
    }
}

// D-shaped shaft bore (round with one flat), 2D
module dshaft2d() {
    r = (SHAFT_D + SHAFT_FIT)/2;
    flat_x = SHAFT_D/2 - FLAT_DEPTH + SHAFT_FIT/2;
    intersection() {
        circle(r = r);
        translate([-r-1, -r-1]) square([ (r+1)+flat_x, 2*(r+1) ]);
    }
}

// ---------------------------------------------------------------------------
// Rad 1 — outer teeth, keyed bore = negative of the existing gear
// ---------------------------------------------------------------------------
module rad1() {
    difference() {
        linear_extrude(height = H)
            gear2d(Z1, tip1, root1, OUT_VR, BACKLASH);
        // keyed bore: described gear profile, enlarged by BORE_FIT so it slips on
        translate([0,0,-EPS])
            linear_extrude(height = H + 2*EPS)
                offset(delta = BORE_FIT)
                    gear2d(Z_BORE, BORE_TIP, BORE_ROOT, BORE_VR);
    }
}

// ---------------------------------------------------------------------------
// Rad 2 — solid mate on a 5 mm D-shaft, grub-screw hub
// ---------------------------------------------------------------------------
module rad2() {
    difference() {
        union() {
            linear_extrude(height = H)
                gear2d(Z2, tip2, root2, OUT_VR, BACKLASH);
            if (HUB) cylinder(d = HUB_D, h = H + HUB_H);
        }
        translate([0,0,-EPS])
            linear_extrude(height = H + HUB_H + 2*EPS) dshaft2d();
        if (HUB && SET_M > 0)
            translate([0,0,H + HUB_H/2]) rotate([0,90,0])
                cylinder(d = SET_M, h = HUB_D, center = true);
    }
}

// ---------------------------------------------------------------------------
// Dispatch
// ---------------------------------------------------------------------------
if (part == "rad1") {
    rad1();
} else if (part == "rad2") {
    rad2();
} else {
    // demo: Rad 1 with the existing gear (ghost) seated in its bore + Rad 2 meshed
    rad1();
    color("tomato")                      // the existing gear that Rad 1 hugs
        linear_extrude(height = H)
            gear2d(Z_BORE, BORE_TIP, BORE_ROOT, BORE_VR);
    translate([CENTER,0,0]) rotate([0,0,180/Z2]) rad2();
}
