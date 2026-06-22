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
CMOUNT_SEAT_ID   = 32.6;   // flange seat inner diameter (mm)
CMOUNT_CLEAR_D   = 26.0;   // optical clear bore diameter (mm)
CMOUNT_SEAT_H    = 4.0;    // depth of flange seat pocket (mm)
CMOUNT_BORE_EXTRA = 40.0;  // extra depth to punch through any hull-closed floor

// Post-process: cut the C-mount opening through the bottom of the optics module.
// optics_module_rms() uses sequential_hull() which closes the underside.
// We reopen it here with an explicit difference() after the hull is complete.
//
// Geometry (all z values relative to OpenFlexure coordinate system):
//   camera_top_z  = rms_camera_mount_top_z() — the face the camera seats against
//   Seat pocket:  from camera_top_z downward by CMOUNT_SEAT_H (wider bore for flange)
//   Clear bore:   from camera_top_z downward through the entire hull (CMOUNT_BORE_EXTRA)
//
// The sequential_hull closes the body below camera_top_z. We cut both:
//   1. The wide seat (CMOUNT_SEAT_ID) for the full depth below camera_top_z
//   2. This automatically includes the clear bore since CMOUNT_SEAT_ID > CMOUNT_CLEAR_D
module optics_module_rms_cmount(params, optics_config){
    camera_top_z = rms_camera_mount_top_z(params, optics_config);
    difference(){
        optics_module_rms(params, optics_config);
        // Cut the full camera insertion bore from camera_top_z downward.
        // Use CMOUNT_SEAT_ID (32.6mm) for the top CMOUNT_SEAT_H (4mm) — flange seat.
        // Below that use CMOUNT_CLEAR_D (26mm) — optical path.
        // Both extend far enough down to punch through any hull-closed material.
        // Seat pocket: top CMOUNT_SEAT_H mm below camera_top_z (wide, for flange)
        translate([0, 0, camera_top_z - CMOUNT_SEAT_H]){
            cylinder(d=CMOUNT_SEAT_ID, h=CMOUNT_SEAT_H + 0.1, $fn=64);
        }
        // Clear bore: from seat bottom all the way through (CMOUNT_BORE_EXTRA down)
        translate([0, 0, camera_top_z - CMOUNT_SEAT_H - CMOUNT_BORE_EXTRA]){
            cylinder(d=CMOUNT_CLEAR_D, h=CMOUNT_BORE_EXTRA + 0.1, $fn=64);
        }
        // Safety: also cut the seat diameter all the way to the bottom of the body,
        // in case the hull extends below camera_top_z - CMOUNT_SEAT_H.
        translate([0, 0, camera_top_z - CMOUNT_BORE_EXTRA]){
            cylinder(d=CMOUNT_SEAT_ID, h=CMOUNT_BORE_EXTRA + 0.1, $fn=64);
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

    // 125mm tube lens (achromatic doublet) — finite conjugate
    if (optics=="rms_f125d13"){
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