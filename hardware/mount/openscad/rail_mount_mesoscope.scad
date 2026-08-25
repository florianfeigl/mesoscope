// Rail Mount Concept — schematic massing draft (parametric)
// ---------------------------------------------------------------
// First visual draft of the "Halterung" milestone. This is a MASSING
// model (blocks/cylinders), NOT print-ready geometry. Its job is to make
// the arrangement discussable and to hold every open dimension as a
// variable, so it can be refined once the bioreactor STLs and the
// stepper/rest-face decisions land.
//
// See docs/RAIL_MOUNT_CONCEPT.md for the reasoning behind these choices.
//
// World axes:
//   X = rail / scan direction (carriage moves here, separate stepper)
//   Y = optical axis (microscope looks toward the reactors, +Y)
//   Z = vertical (gravity acts in -Z)   <-- transverse to optical axis!

$fn = 48;

// ===================== MICROSCOPE MODEL =====================
// Real assembled OpenFlexure/mesoscope geometry, rendered from upstream
// rendering/complete_microscope_rms.scad -> hardware/stl/models/.
// That render applies rotate([-90,0,0]), so in the exported STL:
//   * the optical axis is the line model x=0, z=0, pointing +Y (objective +Y);
//   * the microscope rests on its side face at model z = model_base_dz;
//   * the sample plane sits at model y = sample_z_model (OpenFlexure sample_z).
// -> we only translate it into place; no extra rotation needed.
real_model     = true;
model_file     = "../../stl/models/complete_microscope_rms.stl";
model_base_dz  = -90.78; // model min-Z (resting face) relative to optical axis
sample_z_model = 75;     // OpenFlexure sample_z -> sample plane at model y = 75
model_dy       = 0;      // shift along the optical axis (Y) if needed

// Placeholder envelope (used only when real_model = false).
// From main_body.stl bbox (151 x 121 x 85 mm). Former body-Z (optical) -> Y.
ms_w = 151;   // along X (rail)
ms_d = 85;    // along Y (optical axis)  = former body height/optical column
ms_h = 121;   // along Z (vertical)

// Optics / working distance
// oa_h is chosen so the model's resting face lands on the carriage adapter top
// (adapter_top ~= 44 mm; oa_z = adapter_top - model_base_dz ~= 135 mm).
oa_h         = 115; // optical-axis height above the beam top surface
objective_d  = 24;  // optics tube outer dia (placeholder box only)
objective_l  = 30;  // optics nose protrusion in +Y (placeholder box only)
working_dist = 45;  // gap: optics nose -> reactor window (placeholder box only)

// Bioreactor chip — REAL dims from hardware/bioreactors/
//   chip_senkrecht_mit_bodenplatte.stl (chip body 70 x 40 x 16 mm; the
//   Bodenplatte / mounting flange is excluded from the envelope).
// Orientation: HOCHKANT (upright), hanging from the bridge:
//   X = 70  chip width, along the rail
//   Y = 16  chip THICKNESS, along the optical axis — imaged THROUGH this;
//           light source (+Y side) -> chip -> objective (-Y side)
//   Z = 40  chip height; fluidic ports + tubes (Schlaeuche) exit the TOP
n_reactors    = 4;
reactor_pitch = 80;  // center-to-center along X (= X stop spacing); 70 chip + 10 gap — CONFIRM series spacing
reactor_w     = 70;  // X  (chip width along the rail)
reactor_t     = 16;  // Y  (chip thickness along the optical axis)
reactor_h     = 40;  // Z  (chip height, hanging)
// Optical window on the -Y (objective-facing) face, centered on the axis:
window_w      = 18;  // X extent of window
window_h      = 8;   // Z extent of window
port_d        = 4.5; // 4 fluidic ports on the TOP edge (tubes point up)
port_dx       = 30;  // port pair X offset from center (approx from STL)

// ===================== STRUCTURAL / GUIDE PARAMS =====================
// Shared reference beam: 2040 aluminium extrusion
ext_w = 40; ext_h = 20;

// MGN12 profile rail + carriage
mgn_rail_w = 12; mgn_rail_h = 8;
mgn_car_w  = 27; mgn_car_l = 45; mgn_car_h = 10;

// Carriage adapter plate (microscope <-> MGN12 carriage)
adapter_t = 6;

// ---- Shared base plate (Grundplatte) ----
// One common foundation: the rail (moving microscope) AND the FIXED reactor
// row both mount to it. Only the microscope travels; the reactors stand still.
gp_t = 8;   // Grundplatte thickness (top face at z = 0)

// ---- Reactor bridge (Bruecke): continuous traverse with cutouts ----
// The reactors HANG hochkant from above; the space below them stays free so
// the moving mesoscope (incl. its illumination arm) reaches them from below.
bridge_board_t    = 8;    // traverse board ("schmales Brett") thickness
bridge_board_w    = 24;   // board width in Y — slim, sits BEHIND the sample
                          // plane: at board height (z>=155) the microscope
                          // reaches only y=78 (measured from the STL), so the
                          // board starts at window_y + bridge_y_clear
bridge_y_clear    = 5;    // board front edge offset behind the sample plane
bridge_slot_clear = 1;    // cutout (Aussparung) clearance around each chip
bridge_pillar     = 30;   // square end-pillar cross-section
bridge_x_clear    = 120;  // pillar distance beyond the end stations —
                          // must clear the microscope body at the end stops

// ---- X drive: NEMA17 + T8 leadscrew (separate stepper) ----
nema_sz   = 42.3;   // NEMA17 body cross-section
nema_len  = 40;     // NEMA17 body length
ls_dia    = 8;      // T8 leadscrew dia
coupler_d = 18; coupler_l = 25;
nut_block = [26, 20, 16];   // anti-backlash nut block under the carriage
bearing_d = 22; bearing_l = 16;   // end bearing block (KFL08-ish)

// ---- Gravity mitigation: second clamping face ----
back_plate_frac = 0.7;   // back support plate height as fraction of ms_h
back_plate_t    = 6;

// ===================== DERIVED LAYOUT =====================
span    = (n_reactors - 1) * reactor_pitch;  // X extent of the reactor row
margin  = 100;                               // rail overshoot each side
rail_x0 = -margin;
rail_len = span + 2 * margin;

beam_top   = ext_h;                 // z of extrusion top face
carr_top   = beam_top + mgn_rail_h + mgn_car_h;
adapter_top= carr_top + adapter_t;
oa_z       = beam_top + oa_h;       // world z of the optical axis

// Microscope placement.
// Real model: optical axis at x=carriage, z=oa_z; sample plane at world y.
// Placeholder box: centered in Y around 0, nose points +Y.
ms_y0      = -ms_d/2;
nose_y     = ms_d/2 + objective_l;          // tip of optics in +Y (box only)
sample_y   = sample_z_model + model_dy;     // world Y of the sample plane (real model)
// Reactor optical window plane. With the real model the reactor sits at the
// microscope's sample plane (window on its -Y face, toward the objective; the
// condenser/illumination arm is on the +Y side for trans-illumination).
window_y   = real_model ? sample_y : (nose_y + working_dist);

// X-drive geometry: leadscrew offset to the -Y side (opposite the reactors)
ls_y = -(ext_w/2 + 14);
ls_z = beam_top + 8;
ls_len = rail_len - 20;

// ===================== MODULES =====================
module extrusion_2040(len) {
    color([0.6,0.6,0.62])
    translate([rail_x0,0,0])
        cube([len, ext_w, ext_h]);   // centered in Y at 0? -> shift
}

module beam() {
    // centered on Y=0 line of the assembly's beam strip
    color([0.62,0.62,0.65])
    translate([rail_x0, -ext_w/2, 0]) cube([rail_len, ext_w, ext_h]);
}

module mgn12_rail() {
    color([0.3,0.3,0.34])
    translate([rail_x0, -mgn_rail_w/2, beam_top]) cube([rail_len, mgn_rail_w, mgn_rail_h]);
}

module mgn12_carriage(xpos) {
    color([0.2,0.2,0.24])
    translate([xpos-mgn_car_l/2, -mgn_car_w/2, beam_top+mgn_rail_h])
        cube([mgn_car_l, mgn_car_w, mgn_car_h]);
}

module carriage_adapter(xpos) {
    color([0.85,0.75,0.2])
    translate([xpos-ms_w/2, ms_y0, carr_top]) cube([ms_w, ms_d, adapter_t]);
}

module microscope(xpos) {
    if (real_model) {
        // Real assembled mesoscope. Its optical axis is model (x=0, z=0) -> map to
        // world (xpos, *, oa_z); objective already points +Y. No rotation needed.
        color([0.30,0.55,0.85,0.90])
        translate([xpos, model_dy, oa_z]) import(model_file, convexity=8);
    } else {
        // envelope box (tilted pose) + optics nose on +Y face at optical axis height
        color([0.30,0.55,0.85,0.85])
        translate([xpos-ms_w/2, ms_y0, adapter_top]) cube([ms_w, ms_d, ms_h]);
        color([0.15,0.15,0.15])
        translate([xpos, ms_d/2, oa_z]) rotate([-90,0,0]) cylinder(h=objective_l, d=objective_d);
    }
}

module optical_axis_line(xpos) {
    // along +Y through the sample plane and the chip thickness
    color([0.9,0.1,0.1])
    translate([xpos, 0, oa_z]) rotate([-90,0,0]) cylinder(h=window_y+reactor_t+20, d=1.2);
}

module reactor(xpos) {
    // chip HOCHKANT, hanging from the bridge: imaged horizontally THROUGH its
    // 16 mm thickness (objective -Y, light source +Y); tubes exit the top.
    color([0.75,0.85,0.9,0.9])
    translate([xpos-reactor_w/2, window_y, oa_z-reactor_h/2]) cube([reactor_w, reactor_t, reactor_h]);
    // optical window on the -Y (objective-facing) face, centered on the axis
    color([0.1,0.6,0.9])
    translate([xpos-window_w/2, window_y-0.6, oa_z-window_h/2]) cube([window_w, 0.8, window_h]);
    // 4 fluidic ports + tube stubs on the TOP edge
    color([0.15,0.15,0.15])
    for (dx=[-port_dx,-port_dx+12, port_dx-12, port_dx])
        translate([xpos+dx, window_y+reactor_t/2, oa_z+reactor_h/2]) cylinder(h=16, d=port_d);
}

module base_plate() {
    // Grundplatte: the shared foundation. Long enough in X to also carry the
    // bridge pillars; in Y it reaches from behind the rail past the microscope.
    x0 = min(rail_x0, -bridge_x_clear - bridge_pillar) - 10;
    x1 = max(rail_x0 + rail_len, span + bridge_x_clear + bridge_pillar) + 10;
    y0 = -(ext_w/2 + 30);
    y1 = 205;
    color([0.55,0.55,0.58])
    translate([x0, y0, -gp_t]) cube([x1 - x0, y1 - y0, gp_t]);
}

module reactor_bridge() {
    // FIXED bridge (Bruecke) on the Grundplatte: a continuous traverse board
    // ("schmales Brett") with per-station cutouts (Aussparungen) from which the
    // chips hang hochkant. The space BELOW the chips stays free so the moving
    // mesoscope reaches them from below as it travels the row.
    board_z0 = oa_z + reactor_h/2;      // board underside = chip top edge
    x0 = -bridge_x_clear - bridge_pillar;
    x1 = span + bridge_x_clear + bridge_pillar;
    y0 = window_y + bridge_y_clear;  // clear of the microscope (max y=78 up here)
    // continuous traverse with front-open notches: the chips (y 75..91) slide
    // in from the objective side; the board holds their rear portion
    color([0.8,0.55,0.3])
    difference() {
        translate([x0, y0, board_z0]) cube([x1 - x0, bridge_board_w, bridge_board_t]);
        for (i = [0 : n_reactors-1])
            translate([i*reactor_pitch - reactor_w/2 - bridge_slot_clear,
                       window_y - bridge_slot_clear, board_z0 - 1])
                cube([reactor_w + 2*bridge_slot_clear,
                      reactor_t + 2*bridge_slot_clear,
                      bridge_board_t + 2]);
    }
    // end pillars down to the Grundplatte, OUTSIDE the microscope's travel
    color([0.8,0.45,0.25])
    for (px = [x0, x1 - bridge_pillar])
        translate([px, y0 + bridge_board_w/2 - bridge_pillar/2, 0])
            cube([bridge_pillar, bridge_pillar, board_z0]);
}

module back_support(xpos) {
    // second clamping face behind the microscope (gravity mitigation)
    color([0.85,0.75,0.2])
    translate([xpos-ms_w*0.6/2, ms_y0-back_plate_t, adapter_top])
        cube([ms_w*0.6, back_plate_t, ms_h*back_plate_frac]);
}

module leadscrew() {
    color([0.75,0.75,0.78])
    translate([rail_x0+10, ls_y, ls_z]) rotate([0,90,0]) cylinder(h=ls_len, d=ls_dia);
}

module nema17(xpos) {
    color([0.12,0.12,0.14])
    translate([xpos-nema_len, ls_y-nema_sz/2, ls_z-nema_sz/2]) cube([nema_len, nema_sz, nema_sz]);
    // motor mount plate to the extrusion end
    color([0.5,0.5,0.55])
    translate([xpos-4, ls_y-nema_sz/2-2, 0]) cube([8, nema_sz+4, ls_z+nema_sz/2]);
}

module coupler(xpos) {
    color([0.9,0.55,0.1])
    translate([xpos, ls_y, ls_z]) rotate([0,90,0]) cylinder(h=coupler_l, d=coupler_d);
}

module end_bearing(xpos) {
    color([0.5,0.5,0.55])
    translate([xpos-bearing_l/2, ls_y-bearing_d/2, 0]) cube([bearing_l, bearing_d, ls_z+bearing_d/2]);
}

module nut_block(xpos) {
    color([0.9,0.3,0.3])
    translate([xpos-nut_block[0]/2, ls_y-nut_block[1]/2, ls_z-nut_block[2]/2])
        cube(nut_block);
    // arm tying the nut block to the carriage
    color([0.9,0.3,0.3])
    translate([xpos-nut_block[0]/2, ls_y, ls_z-3]) cube([nut_block[0], -ls_y-mgn_car_w/2, 6]);
}

// ===================== ASSEMBLY =====================
carriage_x = 0;   // current station = reactor #0 (microscope travels in X)

// shared foundation
base_plate();
// rail + moving microscope
beam();
mgn12_rail();
mgn12_carriage(carriage_x);
carriage_adapter(carriage_x);
if (!real_model) back_support(carriage_x);  // placeholder-only gravity plate
microscope(carriage_x);
optical_axis_line(carriage_x);
// X drive (moves the microscope, not the reactors)
leadscrew();
nema17(rail_x0+10);
coupler(rail_x0+10);
end_bearing(rail_x0+ls_len+10);
nut_block(carriage_x);
// FIXED reactor row hanging hochkant from the bridge on the Grundplatte
reactor_bridge();
for (i = [0 : n_reactors-1]) reactor(i * reactor_pitch);
