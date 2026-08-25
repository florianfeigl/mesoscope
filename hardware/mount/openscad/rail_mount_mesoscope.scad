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

// ===================== OPEN / PLACEHOLDER PARAMS =====================
// Microscope envelope, already in its 90°-tilted pose.
// From main_body.stl bbox (151 x 121 x 85 mm). Former body-Z (optical) -> Y.
ms_w = 151;   // along X (rail)
ms_d = 85;    // along Y (optical axis)  = former body height/optical column
ms_h = 121;   // along Z (vertical)

// Optics / working distance
oa_h         = 70;  // optical-axis height above the beam top surface
objective_d  = 24;  // optics tube outer dia (placeholder)
objective_l  = 30;  // optics nose protrusion in +Y
working_dist = 45;  // gap: optics nose -> reactor window (PLACEHOLDER)

// Bioreactor chip — REAL dims from hardware/bioreactors/
//   chip_senkrecht_mit_bodenplatte.stl, base plate (Bodenplatte) removed
//   for the calculations per instruction. Chip body bbox = 70 x 40 x 16 mm.
n_reactors    = 4;
reactor_pitch = 80;  // center-to-center along X (= X stop spacing); 70 chip + 10 gap — CONFIRM series spacing
reactor_w     = 70;  // X  (measured chip body width)
reactor_d     = 40;  // Y  (depth toward microscope / plate; plate excluded)
reactor_h     = 16;  // Z  (measured chip body height)
// Optical window on the -Y (microscope-facing) face, centered:
window_w      = 18;  // X extent of window
window_h      = 8;   // Z extent of window
port_d        = 4.5; // 4 fluidic ports flanking the window
port_dx       = 30;  // port pair X offset from center (approx from STL)

// ===================== STRUCTURAL / GUIDE PARAMS =====================
// Shared reference beam: 2040 aluminium extrusion
ext_w = 40; ext_h = 20;

// MGN12 profile rail + carriage
mgn_rail_w = 12; mgn_rail_h = 8;
mgn_car_w  = 27; mgn_car_l = 45; mgn_car_h = 10;

// Carriage adapter plate (microscope <-> MGN12 carriage)
adapter_t = 6;

// Rack support brackets (rise from the same beam)
bracket_t = 6;

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

// Microscope placed centered in Y around 0; nose points +Y.
ms_y0      = -ms_d/2;
nose_y     = ms_d/2 + objective_l;          // tip of optics in +Y
window_y   = nose_y + working_dist;         // reactor window plane

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
    // envelope box (tilted pose) + optics nose on +Y face at optical axis height
    color([0.30,0.55,0.85,0.85])
    translate([xpos-ms_w/2, ms_y0, adapter_top]) cube([ms_w, ms_d, ms_h]);
    // optics tube along +Y at optical axis height
    color([0.15,0.15,0.15])
    translate([xpos, ms_d/2, oa_z]) rotate([-90,0,0]) cylinder(h=objective_l, d=objective_d);
}

module optical_axis_line(xpos) {
    color([0.9,0.1,0.1])
    translate([xpos, ms_d/2, oa_z]) rotate([-90,0,0]) cylinder(h=working_dist+objective_l+reactor_d, d=1.2);
}

module reactor(xpos) {
    // real chip body (base plate removed); optical window + 4 ports on the
    // -Y (microscope-facing) face, centered at optical-axis height.
    color([0.75,0.85,0.9,0.9])
    translate([xpos-reactor_w/2, window_y, oa_z-reactor_h/2]) cube([reactor_w, reactor_d, reactor_h]);
    // rectangular optical window on the -Y face
    color([0.1,0.6,0.9])
    translate([xpos-window_w/2, window_y-0.6, oa_z-window_h/2]) cube([window_w, 0.8, window_h]);
    // 4 fluidic ports flanking the window
    color([0.15,0.15,0.15])
    for (dx=[-port_dx,-port_dx+12, port_dx-12, port_dx])
        translate([xpos+dx, window_y+1, oa_z]) rotate([90,0,0]) cylinder(h=2, d=port_d);
}

module rack() {
    // base bar spanning the reactor row, supported by two brackets off the beam
    rack_x0 = -reactor_w/2 - 15;
    rack_len= span + reactor_w + 30;
    base_z  = oa_z - reactor_h/2 - 8;
    // base bar
    color([0.8,0.4,0.2])
    translate([rack_x0, window_y-5, base_z]) cube([rack_len, reactor_d+10, 8]);
    // two support brackets rising from the beam top up to the base bar
    for (bx = [rack_x0+20, rack_x0+rack_len-20-bracket_t])
        color([0.8,0.45,0.25])
        translate([bx, ext_w/2, beam_top]) cube([bracket_t, window_y-ext_w/2, base_z-beam_top+8]);
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
carriage_x = 0;   // current station = reactor #0

beam();
mgn12_rail();
mgn12_carriage(carriage_x);
carriage_adapter(carriage_x);
back_support(carriage_x);
microscope(carriage_x);
optical_axis_line(carriage_x);
// X drive
leadscrew();
nema17(rail_x0+10);
coupler(rail_x0+10);
end_bearing(rail_x0+ls_len+10);
nut_block(carriage_x);
// reactor row
rack();
for (i = [0 : n_reactors-1]) reactor(i * reactor_pitch);
