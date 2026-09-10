// Mesoscope — exploded view of the electronics drawer + tech stack only
// ---------------------------------------------------------------------
// Renders just the pull-out electronics drawer and the boards it carries
// (Raspberry Pi 5 -> AI HAT+ (Hailo-8) -> Sangaboard) either assembled
// (explode = 0) or pulled apart along +z (explode = 1). This is a focused
// cut of exploded_view.scad::drawer_with_boards() with its own, larger board
// spacing and per-board labels.
//
// Copied into the upstream clone's rendering/ dir by build_exploded.sh so it
// can `use` the upstream render library (electronics_drawer_frame_xy etc.).
//
// Coordinate frame = drawer-local (board inset applied via
// electronics_drawer_board_inset()); z up.

use <../openscad/libs/utilities.scad>
use <../openscad/libs/microscope_parameters.scad>
use <../openscad/libs/lib_microscope_stand.scad>
use <librender/assembly_parameters.scad>
use <librender/render_utils.scad>
use <librender/render_settings.scad>
use <librender/electronics.scad>

$fn = 48;

// 0 = assembled, 1 = fully exploded (override with -D explode=0.5 etc.)
explode = 1;

// 1 = draw the text labels; 0 = geometry + guide line only.
show_labels = 1;

// ---- part sources (relative to upstream rendering/) ----
STL = "../../../hardware/stl/models/";
DRAWER_STL = str(STL, "electronics_drawer_mesoscope.stl");

params = render_params();

// Board heights inside the drawer (hardware/stand/openscad/microscope_stand_readme.md)
pi5_z    = 5.5;
aihat_z  = 18.4;
sanga_z  = 34.2;

// ---- explosion offsets along +z (scaled by `explode`) ----
drawer_slide = 90;   // mm the drawer is pulled out of the stand
ex_board     = 28;   // per-board separation when exploded (larger than the full-stack view for clarity)

function ez(v) = [0, 0, v * explode];

// ===================== PARTS =====================

module raspberry_pi5(){
    color("ForestGreen") cube([85, 56, 1.6]);
    color("#404040") translate([22, 22, 1.6]) cube([15, 15, 2.5]);  // BCM2712
    color("#303030") translate([70, 5, 1.6]) cube([14, 13, 15]);    // USB stack
    color("#303030") translate([70, 22, 1.6]) cube([14, 13, 15]);
    color("#303030") translate([70, 40, 1.6]) cube([14, 15, 13]);   // Ethernet
    color("#b0b0b0") translate([0, 3, 1.6]) cube([51, 5, 8.5]);     // 40-pin GPIO header
}

module ai_hat(){
    color("ForestGreen") cube([65, 56, 1.6]);
    color("#202020") translate([25, 20, 1.6]) cube([14, 14, 1.5]);  // Hailo-8
    color("black") translate([0, 3, 1.6]) cube([51, 5, 8.5]);       // 40-pin header
    color("#505050") translate([2, 40, 1.6]) cube([20, 12, 3]);     // PCIe FPC connector
}

module sangaboard(){
    color("DarkOliveGreen") cube([65, 57, 1.6]);
    color("#202020") translate([26, 24, 1.6]) cube([14, 14, 3]);    // MCU
    for (dx = [8, 24, 40]) color("#303030") translate([dx, 42, 1.6]) cube([12, 12, 12]); // ULN2003 driver blocks
}

// Guide line + labels live INSIDE the drawer frame so they share the boards'
// coordinate system (electronics_drawer_frame_xy applies a translate+rotate).
module guide_line(inset, labels=true){
    if (explode > 0){
        z1 = inset.z + sanga_z + 3 * ex_board * explode + 20;
        color("Gray", 0.5) translate([inset.x, inset.y, 0]) cylinder(d=0.6, h=z1);
        if (labels)
            for (t = [[ "drawer",           inset.z - 6],
                      [ "Raspberry Pi 5",    inset.z + pi5_z   + ez(ex_board)[2]],
                      [ "AI HAT+ (Hailo-8)", inset.z + aihat_z + ez(2 * ex_board)[2]],
                      [ "Sangaboard",        inset.z + sanga_z + ez(3 * ex_board)[2]]])
                color("DimGray") translate([inset.x + 120, inset.y, t[1]]) rotate([90, 0, 0])
                    linear_extrude(0.5) text(t[0], size=7, halign="left");
    }
}

module drawer_scene(labels=true){
    slide = drawer_slide * explode;
    electronics_drawer_frame_xy(params, slide_dist=slide){
        coloured_render(extras_colour()) import(DRAWER_STL, convexity=6);
        inset = electronics_drawer_board_inset();
        translate(inset + [0, 0, pi5_z]   + ez(ex_board))     raspberry_pi5();
        translate(inset + [0, 0, aihat_z] + ez(2 * ex_board)) ai_hat();
        translate(inset + [0, 0, sanga_z] + ez(3 * ex_board)) sangaboard();
        guide_line(inset, labels=labels);
    }
}

// ===================== ASSEMBLY =====================
drawer_scene(labels = show_labels > 0);
