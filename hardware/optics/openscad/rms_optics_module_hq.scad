// Mesoscope optics module — HQ Camera (IMX477) with 125mm/150mm tube lenses
//
// This file extends the upstream OpenFlexure rms_optics_module.scad (hq_camera branch)
// with mesoscope-specific tube lens configurations for the Pi HQ Camera (IMX477).
//
// Available OPTICS configurations:
//   "rms_f50d13"                — upstream default (50mm tube lens, Pi Camera v2)
//   "rms_f125d13"               — mesoscope: 125mm achromatic doublet
//   "rms_f150d13"               — mesoscope: 150mm achromatic doublet
//   "rms_infinity_f50d13"       — upstream: 50mm infinity-corrected
//   "rms_infinity_f125d13"      — mesoscope: 125mm infinity-corrected
//   "rms_infinity_f150d13"      — mesoscope: 150mm infinity-corrected
//
// CAMERA should be set to "picamera_hq" for the Pi HQ Camera (IMX477).
//
// Build examples:
//   openscad -o optics_hq_125_rms.stl -D 'OPTICS="rms_f125d13"' -D 'CAMERA="picamera_hq"' rms_optics_module_hq.scad
//   openscad -o optics_hq_150_rms.stl -D 'OPTICS="rms_f150d13"' -D 'CAMERA="picamera_hq"' rms_optics_module_hq.scad

use <./libs/microscope_parameters.scad>
use <./libs/lib_optics.scad>
use <./libs/rms_calculations.scad>
use <./libs/optics_configurations.scad>
use <./libs/optics_configurations_hq.scad>

// Override these from the command line with -D, e.g. -D 'OPTICS="rms_f125d13"'
OPTICS = "rms_f125d13";
BEAMSPLITTER = false;
CAMERA = "picamera_hq";
PARFOCAL_DISTANCE = 45;

configurable_optics_module(OPTICS, CAMERA, BEAMSPLITTER, PARFOCAL_DISTANCE);

// C-mount geometry constants — must match picamera_hq_cmount.scad
CMOUNT_SEAT_ID    = 32.6;   // centering seat inner diameter (mm)
CMOUNT_CLEAR_D    = 26.0;   // optical clear bore diameter (mm)
CMOUNT_SEAT_H     = 4.0;    // depth of centering seat (mm)
CMOUNT_RING_ID    = 36.6;   // entry recess inner diameter for locking ring (mm)
CMOUNT_RING_H     = 2.5;    // depth of entry recess for locking ring (mm)
CMOUNT_BORE_EXTRA = 40.0;   // extra depth to punch through any hull-closed floor

// Total depth of the two-step bore
CMOUNT_TOTAL_H    = CMOUNT_SEAT_H + CMOUNT_RING_H;  // 6.5mm

// Outer wall radius: sized to the wider ring recess + 2mm wall thickness
CMOUNT_R_OUTER    = CMOUNT_RING_ID/2 + 2.0;  // 20.3mm

// Axial PCB screw flange geometry for camera retention.
// A flat annular flange carries 4× M2 axial screw holes matching the HQ Camera
// PCB mounting pattern:
//   - 30mm square grid, rotated 45° → holes at (0,±21.21mm) and (±21.21mm,0)
//   - M2 self-tapping: 1.7mm pilot hole
// The flange sits at the PCB level, reached via a thin cylindrical standoff tube
// that extends CMOUNT_PCB_OFFSET mm below the entry recess.
//
// CMOUNT_PCB_OFFSET: measured distance from the bottom face of the C-mount body
// (= bottom of entry recess) down to the HQ Camera PCB surface. ~12mm measured.
CMOUNT_PCB_OFFSET     = 12.0;  // mm — C-mount body bottom to PCB surface
CMOUNT_PCB_HOLE_SPACING = 30.0;  // mm — square grid side length
CMOUNT_PCB_HOLE_R = CMOUNT_PCB_HOLE_SPACING / 2 * sqrt(2);  // 21.21mm radius
CMOUNT_PCB_HOLE_D = 1.7;   // M2 pilot hole diameter (mm)
CMOUNT_FLANGE_R   = CMOUNT_PCB_HOLE_R + 3.0;  // 24.2mm — 3mm wall around holes
CMOUNT_FLANGE_H   = 3.0;   // flange thickness (mm)

// Post-process: cut the two-step C-mount opening through the bottom of the
// optics module, add a bridging frustum, and add a mounting flange with 4×
// axial M2 screw holes matching the HQ Camera PCB hole pattern.
//
// Problem: sequential_hull() leaves a gap between the body bottom
// (z=camera_top_z, inner_d~9.6mm) and the seat ring. The seat ring
// floats in air — unprintable and structurally weak.
//
// Fix: add a solid cylinder bridging the gap, then subtract:
//   - conical inner bore (CMOUNT_CLEAR_D → CMOUNT_SEAT_ID taper)
//   - centering seat pocket (CMOUNT_SEAT_ID, CMOUNT_SEAT_H deep)
//   - entry recess (CMOUNT_RING_ID, CMOUNT_RING_H deep) for the locking ring
//   - clear optical bore below
// Then add a flat annular flange at the base with 4× M2 pilot holes at the
// HQ Camera's PCB mounting pattern (30mm square, 45° rotated).
module optics_module_rms_cmount(params, optics_config){
    camera_top_z = rms_camera_mount_top_z(params, optics_config);

    // cone_h: bridging cylinder height — covers total bore depth + overlap
    cone_h = CMOUNT_TOTAL_H + 1.5;  // 8.0mm

    // Z position of the bottom face of the entry recess (= bottom of C-mount body)
    recess_bottom_z = camera_top_z - CMOUNT_TOTAL_H;

    // Z position of the top face of the flange = PCB surface level
    // = recess_bottom_z minus the PCB offset distance
    flange_top_z    = recess_bottom_z - CMOUNT_PCB_OFFSET;
    flange_bottom_z = flange_top_z - CMOUNT_FLANGE_H;

    // Total height of the standoff tube connecting recess bottom to flange top
    standoff_h = CMOUNT_PCB_OFFSET;

    difference(){
        union(){
            optics_module_rms(params, optics_config);
            // Solid bridging cylinder — fills gap between body bottom and seat ring
            translate([0, 0, camera_top_z - cone_h]){
                cylinder(r=CMOUNT_R_OUTER, h=cone_h, $fn=64);
            }
            // Thin standoff tube — connects the seat ring down to the flange level.
            // Wall thickness = CMOUNT_R_OUTER (solid cylinder; inner bore punched
            // out below by the CMOUNT_CLEAR_D bore subtraction).
            translate([0, 0, flange_top_z]){
                cylinder(r=CMOUNT_R_OUTER, h=standoff_h, $fn=64);
            }
            // Flat annular mounting flange at PCB level — extends outward to
            // CMOUNT_FLANGE_R so the PCB screw holes (radius 21.21mm) land in
            // solid material.
            translate([0, 0, flange_bottom_z]){
                cylinder(r=CMOUNT_FLANGE_R, h=CMOUNT_FLANGE_H, $fn=64);
            }
        }
        // Conical inner bore: tapers from CMOUNT_CLEAR_D (top) to CMOUNT_SEAT_ID
        // (bottom) — shallow taper, self-supporting, no flat overhang.
        translate([0, 0, camera_top_z - cone_h - 0.1]){
            cylinder(r1=CMOUNT_SEAT_ID/2, r2=CMOUNT_CLEAR_D/2,
                     h=cone_h + 0.2, $fn=64);
        }
        // Centering seat: 32.6mm bore, SEAT_H deep from top face
        translate([0, 0, camera_top_z - CMOUNT_SEAT_H]){
            cylinder(d=CMOUNT_SEAT_ID, h=CMOUNT_SEAT_H + 0.1, $fn=64);
        }
        // Entry recess: 36.6mm bore, RING_H deep below the centering seat
        translate([0, 0, camera_top_z - CMOUNT_TOTAL_H]){
            cylinder(d=CMOUNT_RING_ID, h=CMOUNT_RING_H + 0.1, $fn=64);
        }
        // Clear optical bore below the cone — punch through any hull material
        translate([0, 0, camera_top_z - cone_h - CMOUNT_BORE_EXTRA]){
            cylinder(d=CMOUNT_CLEAR_D, h=CMOUNT_BORE_EXTRA + 0.1, $fn=64);
        }
        // 4× M2 axial pilot holes on 30mm square pattern rotated 45°.
        // Holes run from flange bottom face upward through flange + standoff tube,
        // so a screw inserted from below passes through both and engages the PCB.
        // Pattern: rotate 45°, then place at (±15, ±15) → radius 21.21mm.
        rotate([0, 0, 45]){
            for (x = [-CMOUNT_PCB_HOLE_SPACING/2, CMOUNT_PCB_HOLE_SPACING/2]){
                for (y = [-CMOUNT_PCB_HOLE_SPACING/2, CMOUNT_PCB_HOLE_SPACING/2]){
                    translate([x, y, flange_bottom_z - 0.1]){
                        cylinder(d=CMOUNT_PCB_HOLE_D,
                                 h=CMOUNT_FLANGE_H + standoff_h + 0.2,
                                 $fn=16);
                    }
                }
            }
        }
    }
}

module configurable_optics_module(optics, camera_type, beamsplitter, parfocal_distance){
    params = default_params();

    if (parfocal_distance!=45){
        if (parfocal_distance==35){
            echo("Generating an optics module for older, 35mm parfocal, objectives.");
        }
        else {
            echo("WARNING: parfocal_distance is neither 35mm nor 45mm, this may be an error.");
        }
    }

    // For picamera_hq: use the C-mount wrapper that cuts the opening post-hull.
    // For other cameras: fall through to plain optics_module_rms.
    use_cmount = (camera_type == "picamera_hq");

    // 100mm tube lens (achromatic doublet) — finite conjugate — BEST MATCH for IMX477
    // ffd is a placeholder until datasheet is confirmed — do not print STL yet
    if (optics=="rms_f100d13"){
        optics_config = rms_f100d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        if (use_cmount) optics_module_rms_cmount(params, optics_config);
        else            optics_module_rms(params, optics_config);
    }
    // 100mm tube lens — infinity conjugate
    else if (optics=="rms_infinity_f100d13"){
        optics_config = rms_infinity_f100d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        if (use_cmount) optics_module_rms_cmount(params, optics_config);
        else            optics_module_rms(params, optics_config);
    }
    // 125mm tube lens (achromatic doublet) — finite conjugate
    else if (optics=="rms_f125d13"){
        optics_config = rms_f125d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        if (use_cmount) optics_module_rms_cmount(params, optics_config);
        else            optics_module_rms(params, optics_config);
    }
    // 150mm tube lens (achromatic doublet) — finite conjugate
    else if (optics=="rms_f150d13"){
        optics_config = rms_f150d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        if (use_cmount) optics_module_rms_cmount(params, optics_config);
        else            optics_module_rms(params, optics_config);
    }
    // 125mm tube lens — infinity conjugate
    else if (optics=="rms_infinity_f125d13"){
        optics_config = rms_infinity_f125d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        if (use_cmount) optics_module_rms_cmount(params, optics_config);
        else            optics_module_rms(params, optics_config);
    }
    // 150mm tube lens — infinity conjugate
    else if (optics=="rms_infinity_f150d13"){
        optics_config = rms_infinity_f150d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        if (use_cmount) optics_module_rms_cmount(params, optics_config);
        else            optics_module_rms(params, optics_config);
    }
    // Upstream: 50mm finite conjugate (default OpenFlexure)
    else if (optics=="rms_f50d13"){
        optics_config = rms_f50d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        optics_module_rms(params, optics_config);
    }
    // Upstream: 50mm infinity conjugate
    else if (optics=="rms_infinity_f50d13"){
        optics_config = rms_infinity_f50d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        optics_module_rms(params, optics_config);
    }
    else{
        assert(false, str("Unknown optics configuration: ", optics,
            ". Valid options: rms_f50d13, rms_f125d13, rms_f150d13, ",
            "rms_infinity_f50d13, rms_infinity_f125d13, rms_infinity_f150d13"));
    }
}