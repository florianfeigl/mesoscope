// Custom HQ Camera mount for the mesoscope project
// =================================================
//
// This is a DROP-IN REPLACEMENT for the upstream
// `openscad/libs/cameras/picamera_hq.scad`.
//
// The upstream module mounts the BARE PCB of the HQ Camera (with the C-mount
// lens removed) on four mounting posts, and uses a small printed cover to
// protect the underside. That approach assumes the user has stripped the
// camera down to its sensor board.
//
// The mesoscope uses the HQ Camera intact, with its full C-mount body. The
// camera body threads/seats into the optics module via its native C-mount
// flange. There is no PCB-on-posts mounting and no cover -- the camera body
// is its own enclosure.
//
// Geometry (C-mount standard, ISO 1792):
//   - Thread:          1"-32 UN  (major dia 25.4 mm, pitch 0.794 mm)
//   - Flange diameter: ~32 mm (HQ Camera C-mount housing OD)
//   - Flange focal distance (FFD): 17.526 mm  (flange face to sensor)
//
// In this file:
//   - mount_height = 17.526   (FFD: distance from mount-top face to sensor)
//   - sensor_height = 0       (sensor is referenced directly to flange face)
//
// The optics module body builds upward from `mount_top_z`, and the camera
// hangs below the mount face -- only the C-mount flange seats against the
// printed face. This automatically gives the correct sensor-to-tube-lens
// distance via `rms_camera_mount_top_z()` in `rms_calculations.scad`.
//
// Securing the camera:
//   We do NOT print a 1"-32 UN female thread. FDM-printed C-mount threads
//   are unreliable (engagement is short, layer adhesion fights the helix).
//   Instead we provide a smooth seat with a ~0.3 mm clearance over the
//   camera's flange housing (~32 mm OD). The camera is held by either:
//     (a) a thin retaining clip (printed separately), or
//     (b) the optics module's existing M3 / objective load path -- the
//         camera weight is small and the C-mount face naturally seats
//         against the printed lip when the microscope is inverted.
//
// References:
//   - C-mount FFD: https://en.wikipedia.org/wiki/C_mount
//   - Pi HQ Camera mech drawing (page 9):
//     https://datasheets.raspberrypi.com/hq-camera/hq-camera-product-brief.pdf

use <../utilities.scad>
use <../libdict.scad>

// ---------------------------------------------------------------------------
// Camera dictionary -- consumed by camera.scad and rms_calculations.scad
// ---------------------------------------------------------------------------
//
// mount_height  is the distance from the top face of the printed mount
//               down to the reference plane the camera dictionary uses for
//               its "PCB" position. Because the camera mount calculation
//               places the sensor at  sensor_z = mount_top_z - mount_height
//                                                + sensor_height,
//               we pick:
//                   mount_height  = 17.526  (C-mount FFD)
//                   sensor_height = 0
//               so that the sensor sits exactly 17.526 mm below the
//               flange face -- matching the C-mount standard.
function picamera_hq_camera_dict() = [["mount_height", 17.526],
                                      ["sensor_height", 0]];

function picamera_hq_bottom_z() = -key_lookup("mount_height", picamera_hq_camera_dict());

// The flange housing OD on the Pi HQ Camera is ~32 mm (measured).
// We add a ~0.3 mm clearance for an easy slide-fit.
function picamera_hq_cmount_flange_od() = 32.0;
function picamera_hq_cmount_seat_id()   = picamera_hq_cmount_flange_od() + 0.6;

// Depth of the recess that the C-mount housing slides into (centering zone).
// 4 mm is enough to keep the camera concentric without forcing
// the sensor stack any further from the tube lens.
function picamera_hq_cmount_seat_h() = 4.0;

// The HQ Camera has a rotatable locking ring between the C-mount flange body
// and the PCB. This ring has a larger OD (~36 mm) and must be accommodated by
// a wider entry recess at the bottom of the seat so the flange can fully seat.
// Ring OD ~36 mm + 0.6 mm clearance; ring axial height ~2 mm + 0.5 mm margin.
function picamera_hq_cmount_ring_od()   = 36.0;
function picamera_hq_cmount_ring_id()   = picamera_hq_cmount_ring_od() + 0.6;
function picamera_hq_cmount_ring_h()    = 2.5;  // 2 mm ring + 0.5 mm margin

// Inner clear bore above the seat -- the optical path passes through this.
// Slightly wider than the C-mount thread major (25.4 mm) so the camera's
// internal IR-cut filter and sensor stack have unobstructed view of the
// tube lens.
function picamera_hq_cmount_clear_bore_d() = 26.0;

// Outer wall radius of the printed mount face. Sized to the ring recess
// so there is structural wall material around the wider entry pocket.
function picamera_hq_mount_outer_r() = picamera_hq_cmount_ring_id()/2 + 2.0;

// PCB retention flange geometry.
// A flat annular flange with 4× towers carries M2 axial screw holes matching
// the HQ Camera PCB mounting pattern (30mm square, 45° rotated).
// The towers bridge the gap from the entry recess bottom down to PCB level.
//
// CMOUNT_PCB_OFFSET: measured distance from entry recess bottom to PCB surface.
function picamera_hq_pcb_offset()      = 12.0;  // mm — recess bottom to PCB
function picamera_hq_pcb_hole_spacing()= 30.0;  // mm — square grid side length
function picamera_hq_pcb_hole_r()      = picamera_hq_pcb_hole_spacing() / 2 * sqrt(2);  // 21.21mm
function picamera_hq_pcb_hole_d()      = 1.7;   // M2 pilot hole diameter (mm)
function picamera_hq_flange_r()        = picamera_hq_pcb_hole_r() + 3.0;  // 24.2mm
function picamera_hq_flange_h()        = 3.0;   // flange thickness (mm)
function picamera_hq_tower_r()         = 4.0;   // tower cylinder radius (mm)

// Legacy values retained so library code that still references them doesn't break.
function picamera_hq_hole_spacing() = 30;
function picamera_board_size()      = [38, 38];

// ---------------------------------------------------------------------------
// Optical-path cutout
// ---------------------------------------------------------------------------
// In the upstream design this carves out a cone for the (removed) C-mount
// lens barrel. Here the camera body inserts from below, so the cutout is a
// two-step bore:
//   - Upper zone (centering): 32.6 mm ID × 4 mm deep — grips the 32 mm flange body
//   - Lower entry zone:       36.6 mm ID × 2.5 mm deep — clears the rotatable
//     locking ring (~36 mm OD, ~2 mm tall) that sits between flange and PCB
module picamera_hq_cutout(beam_length=15){
    // Clear bore extending up into the optics body
    translate_z(-tiny()){
        cylinder(d=picamera_hq_cmount_clear_bore_d(),
                 h=beam_length+tiny(),
                 $fn=64);
    }
    // Upper centering seat — grips the 32 mm flange body
    translate_z(-picamera_hq_cmount_seat_h()){
        cylinder(d=picamera_hq_cmount_seat_id(),
                 h=picamera_hq_cmount_seat_h()+tiny(),
                 $fn=64);
    }
    // Lower entry recess — clears the locking ring (~36 mm OD)
    translate_z(-picamera_hq_cmount_seat_h()-picamera_hq_cmount_ring_h()){
        cylinder(d=picamera_hq_cmount_ring_id(),
                 h=picamera_hq_cmount_ring_h()+tiny(),
                 $fn=64);
    }
}

// ---------------------------------------------------------------------------
// Camera mount -- the printed face the HQ Camera flange seats against
// ---------------------------------------------------------------------------
// The optics module hulls onto a thin slice of this at z = mount_top_z.
// Top face is at z = 0, mount extends downward to z = picamera_hq_bottom_z().
//
// IMPORTANT: This must be an open-bottom tube, NOT a solid disk.
// optics_module_body_outer() uses sequential_hull() between camera_mount_top_slice()
// (at z=0) and bottom_of_body_and_wedge() (at z=-2). If camera_mount generates
// a solid floor, the hull closes the bottom and blocks camera insertion.
//
// We generate a thin-walled tube (annular ring): outer wall + seat lip, no floor.
// The inner bore (picamera_hq_cmount_clear_bore_d) is removed throughout, and
// the flange seat pocket (picamera_hq_cmount_seat_id) is recessed at the bottom.
module picamera_hq_camera_mount(screwhole=true, counterbore=false){
    // We ignore screwhole / counterbore -- not used in the C-mount design.
    //
    // Geometry (bottom to top):
    //   Flange (flange_h = 3mm, r = 24.2mm) at PCB level — annular ring with
    //     4× towers rising from it (tower_r = 4mm, tower_h = pcb_offset = 12mm)
    //   Entry recess  (ring_h = 2.5mm): 36.6mm ID — clears locking ring
    //   Centering seat (seat_h = 4.0mm): 32.6mm ID — grips 32mm flange body
    //   Clear bore above: 26.0mm ID — optical path

    total_bore_h = picamera_hq_cmount_seat_h() + picamera_hq_cmount_ring_h() + 1;
    recess_bottom_z = -(picamera_hq_cmount_seat_h() + picamera_hq_cmount_ring_h());
    // Flange sits at the bottom of the corpus (recess_bottom_z), not at PCB level.
    // Towers hang down from the flange to the PCB.
    flange_top_z    = recess_bottom_z;
    flange_bot_z    = flange_top_z - picamera_hq_flange_h();
    tower_h         = picamera_hq_pcb_offset();

    difference(){
        union(){
            // Outer tube wall: covers two-step bore depth
            translate_z(-total_bore_h){
                cylinder(r=picamera_hq_mount_outer_r(),
                         h=total_bore_h + tiny(),
                         $fn=64);
            }
            // Flat annular flange: sits at recess bottom, extends downward
            translate_z(flange_bot_z){
                cylinder(r=picamera_hq_flange_r(),
                         h=picamera_hq_flange_h(),
                         $fn=64);
            }
            // 4× towers: hang downward from flange bottom toward PCB
            rotate([0, 0, 45]){
                for(x=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
                    for(y=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
                        translate([x, y, flange_bot_z - tower_h]){
                            cylinder(r=picamera_hq_tower_r(),
                                     h=tower_h,
                                     $fn=32);
                        }
                    }
                }
            }
        }
        // Optical bore through entire height (from tower bottom up through corpus)
        translate_z(flange_bot_z - tower_h - tiny()){
            cylinder(d=picamera_hq_cmount_clear_bore_d(),
                     h=total_bore_h + tower_h + picamera_hq_flange_h() + 2*tiny(),
                     $fn=64);
        }
        // Centering seat: 32.6mm bore, seat_h deep from top face
        translate_z(-picamera_hq_cmount_seat_h() - tiny()){
            cylinder(d=picamera_hq_cmount_seat_id(),
                     h=picamera_hq_cmount_seat_h() + tiny(),
                     $fn=64);
        }
        // Entry recess: 36.6mm bore, ring_h deep below centering seat
        translate_z(recess_bottom_z - tiny()){
            cylinder(d=picamera_hq_cmount_ring_id(),
                     h=picamera_hq_cmount_ring_h() + tiny(),
                     $fn=64);
        }
        // M2 pilot holes through towers + flange (from tower bottom upward)
        rotate([0, 0, 45]){
            for(x=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
                for(y=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
                    translate([x, y, flange_bot_z - tower_h - tiny()]){
                        cylinder(d=picamera_hq_pcb_hole_d(),
                                 h=tower_h + picamera_hq_flange_h() + 2*tiny(),
                                 $fn=16);
                    }
                }
            }
        }
    }
}

// ---------------------------------------------------------------------------
// Stubs for upstream API compatibility
// ---------------------------------------------------------------------------
// These modules exist in the upstream picamera_hq.scad and are referenced
// from camera.scad and lib_optics.scad. We replace them with no-ops so the
// build doesn't error out, but they generate no geometry in the C-mount
// design (no PCB, no screws, no cover).

module picamera_hq_screwholes(){
    // No screwholes -- the camera is held by the C-mount seat.
}

module picamera_hq_counterbore(){
    // No counterbore -- nothing to seat from below.
}

module picamera_hq_bottom_mounting_posts(optics_config, outers=true, cutouts=true, bottom_slice=false){
    // No physical posts -- the C-mount flange does the mounting.
    //
    // bottom_slice=true is called by optics_module_body_outer / camera_platform
    // to get a thin cross-section at the bottom of the mount for sequential_hull.
    // We return the annular ring cross-section of the mount tube so the hull
    // knows the correct extent at the bottom -- without this the hull closes
    // the underside and blocks camera insertion.
    if (bottom_slice){
        difference(){
            cylinder(r=picamera_hq_mount_outer_r(), h=tiny(), $fn=64);
            cylinder(d=picamera_hq_cmount_seat_id(), h=2*tiny(), center=true, $fn=64);
        }
    }
    // outers / cutouts cases: no geometry needed (no posts to add or drill)
}

module at_picamera_hq_hole_pattern(){
    // Retained for API compatibility. Iterates over the legacy 30 mm hole
    // pattern; if anything still calls it, it gets the same children
    // placement, but nothing in the C-mount path uses this.
    hole_spacing = picamera_hq_hole_spacing();
    rotate(45){
        for(x_tr=[-.5, .5]*hole_spacing){
            for(y_tr=[-.5, .5]*hole_spacing){
                translate([x_tr, y_tr, 0]){
                    children();
                }
            }
        }
    }
}

module picamera_hq_board(h=tiny(), rotated=true, clearance=0){
    // No printed PCB outline in the C-mount design.
}

module picamera_hq_cover_pads(clearance=1){
    // No cover in the C-mount design.
}

module picamera_hq_cover(){
    // No cover in the C-mount design -- the camera body is its own enclosure.
}
