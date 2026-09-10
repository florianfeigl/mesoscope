// Mesoscope — exploded view of the complete upright stack
// ---------------------------------------------------------------
// Renders the full mesoscope (feet -> stand -> electronics drawer -> Z-only
// main body -> Z actuator + motor -> HQ-camera optics module -> sample /
// bioreactor chip -> light source) either assembled (explode = 0) or pulled
// apart along the optical axis (explode = 1).
//
// This file is COPIED into the upstream clone's rendering/ directory by
// build_exploded.sh (same pattern as hardware/mount/openscad/*.scad) so that
// it can `use` the upstream render library for small standard parts (foot,
// gears, lead screw, 28BYJ-48 motor, objective). The large mesoscope-specific
// parts are imported from our rendered STLs in hardware/stl/models/.
//
// Coordinate frame = upstream STAND frame: z up, stand base at z = 0.
// The microscope body frame sits at z = microscope_stand_height - 3 (= 88 mm
// for the Pi 5 stand: drawer_h 60 + 31 - microscope_depth 3), see
// lib_microscope_stand.scad::microscope_on_stand_pos(). Inside the body
// frame: sample plane z = 75, objective shoulder z = 30.1 (parfocal 45),
// optics module origin = body origin (assembly_parameters::optics_module_pos).
//
// Colour code:  printed parts  -> body_colour()/extras_colour() (white / blue)
//               bought parts   -> grey/silver/green (electronics), black (camera)
//               placeholders   -> translucent

use <../openscad/libs/utilities.scad>
use <../openscad/libs/microscope_parameters.scad>
use <../openscad/libs/lib_microscope_stand.scad>
use <../openscad/libs/gears.scad>
use <../openscad/libs/libfeet.scad>
use <../openscad/libs/z_axis.scad>
use <librender/assembly_parameters.scad>
use <librender/render_utils.scad>
use <librender/render_settings.scad>
use <librender/hardware.scad>
use <librender/electronics.scad>
use <librender/optics.scad>
use <actuator_assembly.scad>

$fn = 48;

// 0 = assembled, 1 = fully exploded (override with -D explode=0.5 etc.)
explode = 1;

// 0 = labels face the default (front) camera; 1 = mirror + reposition the
// labels so they read correctly from the opposite (back) camera. Set via
// -D label_back=1 for the exploded_view_back.png render.
label_back = 0;

// 1 = draw the text labels; 0 = geometry + guide line only (no annotations).
// Set via -D show_labels=0 for the *_nolabels.png renders.
show_labels = 1;

// ---- part sources (relative to upstream rendering/) ----
STL = "../../../hardware/stl/models/";
BODY_STL   = str(STL, "main_body_mesoscope.stl");
OPTICS_STL = str(STL, "optics_hq_125_rms_threaded.stl");
STAND_STL  = str(STL, "microscope_stand_mesoscope.stl");
DRAWER_STL = str(STL, "electronics_drawer_mesoscope.stl");

// ---- assembled positions ----
params       = render_params();
stand_params = default_stand_params(pi_version=5, sanga_version="ai_hat_stack");
body_z       = microscope_stand_height(stand_params) - microscope_depth();   // 88
sample_z     = 75;      // body frame (microscope_parameters: sample_z)
objective_z  = 30.1;    // body frame (rms_optics_assembly.scad)
optics_bottom_z = -22.3; // body frame, min z of optics_hq_125_rms_threaded.stl
drawer_slide    = 90;    // mm the drawer is pulled out (microscope_stand.scad uses 90)

// Board heights inside the drawer (hardware/stand/openscad/microscope_stand_readme.md)
pi5_z    = 5.5;
aihat_z  = 18.4;
sanga_z  = 34.2;

// ---- explosion offsets along +z (scaled by `explode`) ----
ex_stand   = 0;
ex_boards  = 12;    // per board inside the drawer
ex_foot    = 30;
ex_optics  = 70;
ex_camera  = 50;    // camera detaches downward from the optics module
ex_body    = 140;
ex_zact    = 175;
ex_motor   = 200;
ex_chip    = 250;
ex_led     = 290;

function ez(v) = [0, 0, v * explode];

// ===================== PARTS =====================

module stand(){
    coloured_render(stand_colour()) import(STAND_STL, convexity=6);
}

module drawer_with_boards(){
    slide = drawer_slide * explode;
    electronics_drawer_frame_xy(params, slide_dist=slide){
        coloured_render(extras_colour()) import(DRAWER_STL, convexity=6);
        inset = electronics_drawer_board_inset();
        // Raspberry Pi 5 (85 x 56 board)
        translate(inset + [0, 0, pi5_z] + ez(ex_boards)){
            color("ForestGreen") cube([85, 56, 1.6]);
            color("#404040") translate([22, 22, 1.6]) cube([15, 15, 2.5]); // BCM2712
            color("#303030") translate([70, 5, 1.6]) cube([14, 13, 15]);   // USB stack
            color("#303030") translate([70, 22, 1.6]) cube([14, 13, 15]);
            color("#303030") translate([70, 40, 1.6]) cube([14, 15, 13]);  // Ethernet
        }
        // AI HAT+ (Hailo-8) — HAT+ outline 65 x 56
        translate(inset + [0, 0, aihat_z] + ez(2*ex_boards)){
            color("ForestGreen") cube([65, 56, 1.6]);
            color("#202020") translate([25, 20, 1.6]) cube([14, 14, 1.5]);  // Hailo-8
            color("black") translate([0, 3, 1.6]) cube([51, 5, 8.5]);       // 40-pin header
        }
        // Sangaboard v0.5 (65 x 57) — motor controller (hybrid decision 2026-09-03)
        translate(inset + [0, 0, sanga_z] + ez(3*ex_boards)){
            color("DarkOliveGreen") cube([65, 57, 1.6]);
        }
    }
}

module z_foot(){
    // Z foot sits in the stand cavity under the body; printed part
    translate([0, 0, body_z] + ez(ex_foot)){
        place_part(z_foot_placement()){
            coloured_render(extras_colour()) middle_foot(params, lie_flat=false, letter="Z");
        }
    }
}

module main_body(){
    translate([0, 0, body_z] + ez(ex_body)){
        coloured_render(body_colour()) import(BODY_STL, convexity=10);
    }
}

module z_actuator(){
    // brass nut, M3x25 lead screw + large gear + washers, viton band
    translate([0, 0, body_z] + ez(ex_zact)){
        place_part(z_nut_placement()) m3_nut(brass=true, center=true);
        place_part(z_lead_assembly_placement()) lead_screw_assembly();
        place_part(z_oring_placement()) viton_band_in_situ_vertical();
    }
}

module z_motor(){
    // 28BYJ-48 + small gear, in the Z cable-tidy frame (mount_motors.scad)
    translate([0, 0, body_z] + ez(ex_motor)){
        z_cable_tidy_frame(params){
            place_part(z_motor_pos()){
                motor28BYJ48_wo_wire();
                place_part(small_gear_pos()){
                    coloured_render(extras_colour()) small_gear();
                }
            }
        }
    }
}

module optics_module(){
    // printed HQ-camera C-mount optics module, 125 mm tube lens; STL frame == body frame
    translate([0, 0, body_z] + ez(ex_optics)){
        coloured_render(optics_module_colour()) import(OPTICS_STL, convexity=10);
        // tube lens (achromat 12.7 mm) roughly at lens position: 8.5 mm below the objective shoulder
        color("LightSkyBlue", 0.6) translate_z(objective_z - 8.5 - 2) cylinder(d=12.7, h=4);
    }
}

module objective(){
    // ZEISS Plan-Neofluar 10x/0.30 — rendered with the upstream generic objective model
    translate([0, 0, body_z + objective_z] + ez(ex_optics + 35)){
        rendered_objective();
    }
}

module hq_camera(){
    // PLACEHOLDER: Raspberry Pi HQ Camera (IMX477) with C-mount housing.
    // C-mount barrel (32 mm OD) + C/CS adapter ring sits in the optics module seat;
    // 38 x 38 mm PCB below. Dimensions from the HQ camera mechanical drawing.
    translate([0, 0, body_z + optics_bottom_z] + ez(ex_camera)){
        color("#202020") translate_z(-11.5) cylinder(d=32, h=11.5);       // housing/adapter
        color("#1a1a1a") translate_z(-13.0) cylinder(d=36, h=1.5);         // lock ring flange
        color("DarkGreen") translate([-19, -19, -14.5]) cube([38, 38, 1.5]); // PCB
        color("#303030") translate([-12, -21, -19]) cube([24, 5, 4.5]);      // CSI connector
        color("#505050") translate([-6, 19, -22]) cube([12, 8, 8]);          // tripod mount
    }
}

module chip(){
    // PLACEHOLDER bioreactor chip lying on the sample plane (upright pose):
    // 70 x 40 x 16 mm body, 18 x 8 mm optical window centred on the axis
    // (docs/RAIL_MOUNT_CONCEPT.md §6). In the rail concept the chip hangs
    // upright and is imaged through its 16 mm thickness — see exploded_rail.scad.
    translate([0, 0, body_z + sample_z] + ez(ex_chip)){
        color([0.75, 0.85, 0.9, 0.85]) translate([-35, -20, 0]) cube([70, 40, 16]);
        color("DeepSkyBlue") translate([-9, -4, -0.6]) cube([18, 8, 0.6]);
        color("#303030") for (dx = [-30, -18, 18, 30]) translate([dx, 0, 16]) cylinder(d=4.5, h=12);
    }
}

module light_source(){
    // PLACEHOLDER trans-illumination LED (replaces the upstream condenser arm,
    // which cannot clear a 16 mm chip — RAIL_MOUNT_CONCEPT.md).
    translate([0, 0, body_z + sample_z + 16 + 15] + ez(ex_led)){
        color("WhiteSmoke") cylinder(d=30, h=8);
        color("Gold", 0.7) translate_z(-1) cylinder(d=6, h=1);
    }
}

module guide_line(back=false, labels=true){
    if (explode > 0){
        z0 = 0;
        z1 = body_z + sample_z + 40 + ex_led * explode;
        color("Gray", 0.5) translate_z(z0) cylinder(d=0.6, h=z1 - z0);
        // labels (skipped when labels=false; mirrored when back=true so they
        // read correctly from the opposite camera)
        if (labels)
            for (t = [[ "feet",     ez(ex_foot)[2]   + body_z - 8],
                      [ "optics",   ez(ex_optics)[2] + body_z + 10],
                      [ "body",     ez(ex_body)[2]   + body_z + 30],
                      [ "Z drive",  ez(ex_zact)[2]   + body_z + 5],
                      [ "chip",     ez(ex_chip)[2]   + body_z + sample_z + 8]])
                color("DimGray") translate([back ? -95 : 95, 0, t[1]]) rotate([90, 0, 0])
                    linear_extrude(0.5)
                        if (back) mirror([1, 0, 0]) text(t[0], size=7, halign="left");
                        else text(t[0], size=7, halign="left");
    }
}

// ===================== ASSEMBLY =====================
stand();
drawer_with_boards();
z_foot();
main_body();
z_actuator();
z_motor();
optics_module();
objective();
hq_camera();
chip();
light_source();
guide_line(back = label_back > 0, labels = show_labels > 0);
