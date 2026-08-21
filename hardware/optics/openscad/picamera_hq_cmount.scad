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
//
// Threaded variant: the camera is retained by a printed male 1"-32 UN thread
// that screws into the C-CS adapter's female C-mount thread. The seating face
// (adapter front face) is `cmount_thread_flange_h()` below the mount top, so
// the mount height is offset by the flange thickness to keep the sensor at the
// correct FFD.
function picamera_hq_camera_dict() = THREADED_CAMERA_MOUNT ?
    [["mount_height", 17.526 + cmount_thread_flange_h()],
     ["sensor_height", 0]] :
    [["mount_height", 17.526],
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
function picamera_hq_pcb_hole_d()      = 1.9;   // M2 self-tap hole diameter (mm)
function picamera_hq_flange_r()        = picamera_hq_pcb_hole_r() + 3.0;  // 24.2mm
function picamera_hq_flange_h()        = 3.0;   // flange thickness (mm)
function picamera_hq_tower_r()         = 2.5;   // tower cylinder radius (mm) — min wall around M2 hole

// Legacy values retained so library code that still references them doesn't break.
function picamera_hq_hole_spacing() = 30;
function picamera_board_size()      = [38, 38];

// ---------------------------------------------------------------------------
// Threaded C-mount interface (alternative to the smooth seat)
// ---------------------------------------------------------------------------
// The HQ Camera is used intact with its C-CS adapter fitted. The printed
// module presents a male 1"-32 UN thread that screws directly into the
// adapter's female C-mount thread, and a flat flange face that seats against
// the adapter's front face. The sensor then sits at the standard C-mount FFD
// (17.526 mm) below the seating face -- the same optics as the smooth seat.
//
// Enable with:  -D 'THREADED_CAMERA_MOUNT=true'
//
// NOTE on print orientation: this interface hangs below the flange, so the
// exported STL should be printed standing on the objective end (rotate 180° in
// the slicer), with the thread barrel pointing up.
THREADED_CAMERA_MOUNT = false;

function cmount_thread_pitch()      = 25.4/32;               // 0.79375 mm (32 TPI)
function cmount_thread_major_d()    = 25.2;                  // printed major diameter (nominal 25.4, ~0.2 mm FDM clearance)
function cmount_thread_minor_d()    = 24.3;                  // printed root diameter (internal minor ~24.5)
function cmount_thread_h()          = (cmount_thread_major_d() - cmount_thread_minor_d())/2;  // 0.45
function cmount_thread_base_w()     = 0.4;                   // tooth width at the root (axial)
function cmount_thread_top_w()      = 0.1;                   // tooth width at the tip (axial)
function cmount_thread_length()     = 5.0;                   // threaded barrel length below the flange
function cmount_thread_divisions()  = 40;                    // helix segments per pitch
function cmount_thread_flange_h()   = 2.5;                   // flange thickness; seating face is flange_h below mount top
function cmount_thread_flange_r()   = 21.0;                  // >= corpus outer (20.3) so the hull connects
function cmount_thread_bore_d()     = 16.0;                  // clear bore through flange + barrel (optical path)

// Self-contained male thread generator (external trapezoidal profile, 1"-32 UN).
// Geometry ported from OpenFlexure `threads.scad` (CERN-OHL, derivative of
// ZhuangLab 3D-printing / Hazen Babcock) so this file does not pull in that
// file's global `$fn = 200` for the whole build.
module cmount_male_thread(radius, thread_height, thread_base_width, thread_top_width,
                          thread_length, pitch, number_divisions){
    $fn = 64;
    cylinder_radius = radius + thread_height;
    overshoot = 20;                       // == extra=-0.5 (wrap-around trimmed below)
    turns = thread_length/pitch;
    angle_step = 360.0/number_divisions;
    z_step = pitch/number_divisions;
    angular_disp = 0.5 * angle_step;
    root_w = thread_base_width;
    tip_w  = thread_top_width;
    p0 = [ cylinder_radius*cos(-angular_disp), cylinder_radius*sin(-angular_disp), -0.5*tip_w ];
    p1 = [ radius*cos(-angular_disp),          radius*sin(-angular_disp),          -0.5*root_w ];
    p2 = [ radius*cos(-angular_disp),          radius*sin(-angular_disp),           0.5*root_w ];
    p3 = [ cylinder_radius*cos(-angular_disp), cylinder_radius*sin(-angular_disp),   0.5*tip_w ];
    p4 = [ cylinder_radius*cos(angular_disp),  cylinder_radius*sin(angular_disp),   -0.5*tip_w + z_step ];
    p5 = [ radius*cos(angular_disp),           radius*sin(angular_disp),            -0.5*root_w + z_step ];
    p6 = [ radius*cos(angular_disp),           radius*sin(angular_disp),             0.5*root_w + z_step ];
    p7 = [ cylinder_radius*cos(angular_disp),  cylinder_radius*sin(angular_disp),    0.5*tip_w + z_step ];
    points = [p1, p0, p3, p2, p5, p4, p7, p6];   // external-thread winding
    faces  = [[3,2,1,0],[1,5,4,0],[4,7,3,0],[7,4,5,6],[5,1,2,6],[2,3,7,6]];  // reversed winding: outer_thread CGAL fix
    difference(){
        union(){
            for(i = [overshoot : turns*number_divisions - overshoot]){
                rotate_z(i*angle_step){
                    translate_z(i*z_step){
                        polyhedron(points=points, faces=faces);
                    }
                }
            }
        }
        // trim the wrap-around ends
        translate_z(-2){ cylinder(r=cylinder_radius+0.1, h=2, $fn=64); }
        translate_z(thread_length){ cylinder(r=cylinder_radius+0.1, h=2, $fn=64); }
    }
}

// Printed face that screws into the HQ Camera C-CS adapter and seats against
// its front face. Top face at z = 0 (hull reference into the optics body),
// flange bottom at z = -flange_h is the seating face, and the threaded barrel
// hangs below it.
module cmount_threaded_interface(){
    $fn = 64;
    flange_h = cmount_thread_flange_h();
    barrel_h = cmount_thread_length();
    minor_r  = cmount_thread_minor_d()/2;
    bore_r   = cmount_thread_bore_d()/2;

    difference(){
        union(){
            // Flange: hulls into the optics body at z=0, seats the camera face
            // at z=-flange_h (17.526 mm FFD below this face).
            translate_z(-flange_h){
                cylinder(r=cmount_thread_flange_r(), h=flange_h + tiny(), $fn=64);
            }
            // Threaded barrel core (minor radius)
            translate_z(-(flange_h + barrel_h)){
                cylinder(r=minor_r, h=barrel_h + tiny(), $fn=64);
            }
            // Male 1"-32 UN thread teeth around the barrel
            translate_z(-(flange_h + barrel_h)){
                cmount_male_thread(radius=minor_r,
                                   thread_height=cmount_thread_h(),
                                   thread_base_width=cmount_thread_base_w(),
                                   thread_top_width=cmount_thread_top_w(),
                                   thread_length=barrel_h,
                                   pitch=cmount_thread_pitch(),
                                   number_divisions=cmount_thread_divisions());
            }
        }
        // Optical clear bore through flange + barrel
        translate_z(-(flange_h + barrel_h) - tiny()){
            cylinder(r=bore_r, h=flange_h + barrel_h + 2*tiny(), $fn=64);
        }
    }
}

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
    if (THREADED_CAMERA_MOUNT){
        // Straight clear bore through flange + threaded barrel (threaded variant).
        total_h = beam_length + cmount_thread_flange_h() + cmount_thread_length();
        translate_z(-(cmount_thread_flange_h() + cmount_thread_length()) - tiny()){
            cylinder(d=cmount_thread_bore_d(),
                     h=total_h + tiny(),
                     $fn=64);
        }
    }
    else{
        // Single consistent bore throughout — no undercut, no support trapping.
        // Diameter = ring_id (36.6mm) to clear both the locking ring and the
        // flange body. The camera is located axially by the flange contact face,
        // not by a step in the bore wall.
        total_h = beam_length + picamera_hq_cmount_seat_h() + picamera_hq_cmount_ring_h();
        translate_z(-(picamera_hq_cmount_seat_h() + picamera_hq_cmount_ring_h()) - tiny()){
            cylinder(d=picamera_hq_cmount_ring_id(),
                     h=total_h + tiny(),
                     $fn=64);
        }
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
    if (THREADED_CAMERA_MOUNT){
        // Threaded variant: flange + male 1"-32 UN barrel screwing into the
        // C-CS adapter. No corpus ring, no seat, no retention flange.
        cmount_threaded_interface();
    }
    else{
        // We ignore screwhole / counterbore -- not used in the C-mount design.
        //
        // This module generates only the corpus ring (the part that hulls into the
        // optics body). Towers and flange are added by picamera_hq_bottom_mounting_posts
        // so they are placed AFTER the hull and are not clipped by it.
        //
        // Bore is a single consistent diameter (ring_id = 36.6mm) throughout —
        // no undercut, no support trapping. The centering seat step is removed;
        // the camera is located axially by the flange contact face.
        //
        // Geometry:
        //   Outer wall: r = mount_outer_r = 20.3mm
        //   Single bore: d = ring_id = 36.6mm  (consistent, no step)
        //   Depth: seat_h + ring_h + 1mm overlap

        total_bore_h = picamera_hq_cmount_seat_h() + picamera_hq_cmount_ring_h() + 1;

        difference(){
            // Outer tube wall
            translate_z(-total_bore_h){
                cylinder(r=picamera_hq_mount_outer_r(),
                         h=total_bore_h + tiny(),
                         $fn=64);
            }
            // Consistent bore — same diameter throughout, no undercut
            translate_z(-total_bore_h - tiny()){
                cylinder(d=picamera_hq_cmount_ring_id(),
                         h=total_bore_h + 2*tiny(),
                         $fn=64);
            }
        }
    }
}

module picamera_hq_bottom_mounting_posts(optics_config, outers=true, cutouts=true, bottom_slice=false){
    // In the C-mount design this adds the retention flange + towers AFTER the hull.
    // The flange sits at the bottom of the corpus ring; towers hang down to PCB level.
    //
    // bottom_slice=true: return a thin cross-section at the base of the corpus ring
    // for sequential_hull() to know the correct outer extent.

    recess_bottom_z = -(picamera_hq_cmount_seat_h() + picamera_hq_cmount_ring_h());
    flange_top_z    = recess_bottom_z;
    flange_bot_z    = flange_top_z - picamera_hq_flange_h();
    tower_h         = picamera_hq_pcb_offset();

    if (bottom_slice){
        // Thin annular slice at corpus bottom for hull reference
        difference(){
            cylinder(r=picamera_hq_mount_outer_r(), h=tiny(), $fn=64);
            cylinder(d=picamera_hq_cmount_ring_id(), h=2*tiny(), center=true, $fn=64);
        }
    }
    else{
        difference(){
            union(){
                if (outers){
                    // Flat annular flange at corpus base
                    translate_z(flange_bot_z){
                        cylinder(r=picamera_hq_flange_r(),
                                 h=picamera_hq_flange_h(),
                                 $fn=64);
                    }
                    // 4× towers at PCB corner positions (±15, ±15) mm
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
            if (cutouts){
                // M2 pilot holes at (±15, ±15) from tower bottom through flange top
                for(x=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
                    for(y=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
                        translate([x, y, flange_bot_z - tower_h - 1]){
                            cylinder(d=picamera_hq_pcb_hole_d(),
                                     h=tower_h + picamera_hq_flange_h() + 2,
                                     $fn=16);
                        }
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
    // Protective lid for the back of the Pi HQ Camera PCB.
    // Mounts onto the 4× retention towers via M2 screws through the PCB holes.
    //
    // Geometry:
    //   Outer shell: 38×38mm rounded square, 1.5mm wall, 5mm deep
    //   Inner clearance: 3.5mm depth to clear PCB components
    //   4× M2 through-holes on 30mm pattern (45° rotated) for tower screws
    //   Central cutout for the ribbon cable exit (if present)

    board  = picamera_board_size();   // [38, 38]
    wall_t = 1.5;
    depth  = 5.0;    // total lid depth
    clear  = 3.5;    // inner component clearance
    roc    = 2.0;    // corner radius
    screw_d = 2.2;   // M2 clearance hole (lid passes screw through freely)

    difference(){
        // Outer shell — rounded square box
        linear_extrude(depth){
            offset(r=roc, $fn=16){
                offset(r=-roc){
                    square(board + [2*wall_t, 2*wall_t], center=true);
                }
            }
        }
        // Inner pocket — component clearance
        translate_z(wall_t){
            linear_extrude(depth){
                offset(r=roc - wall_t, $fn=16){
                    offset(r=-(roc - wall_t)){
                        square(board, center=true);
                    }
                }
            }
        }
        // 4× M2 clearance holes at PCB corner positions: (±15, ±15) mm
        // No rotation — holes are at the corners of the 30mm square grid
        for(x=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
            for(y=[-picamera_hq_pcb_hole_spacing()/2, picamera_hq_pcb_hole_spacing()/2]){
                translate([x, y, -1]){
                    cylinder(d=screw_d, h=depth + 2, $fn=16);
                }
            }
        }
    }
}
