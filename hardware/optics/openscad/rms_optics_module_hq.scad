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

// Post-process: cut the C-mount opening through the bottom of the optics module
// and add a bridging cone to structurally connect the body to the seat ring.
//
// Problem: sequential_hull() leaves a ~5mm unsupported gap between the body
// bottom (z=camera_top_z, inner_d~9.6mm) and the seat ring bottom
// (z=camera_top_z - CMOUNT_BORE_EXTRA, inner_d=32.6mm). The seat ring
// floats in air, which is unprintable and structurally weak.
//
// Fix: after cutting the bore, add a thin conical wall (frustum) that
// bridges the gap. The cone runs from the body bottom face outward/downward
// to the seat ring, with a shallow taper angle. It is subtracted from on the
// inside by the optical bore so it forms a ring frustum — stable, printable,
// and does not obstruct the camera insertion.
module optics_module_rms_cmount(params, optics_config){
    camera_top_z = rms_camera_mount_top_z(params, optics_config);

    // Geometry derived from STL scan:
    //   body bottom:  z = camera_top_z,            outer_r = 18.3mm, inner_r = 4.8mm
    //   seat ring:    z = camera_top_z - CMOUNT_BORE_EXTRA (clipped to body bottom),
    //                 outer_r = 18.3mm, inner_r = 16.3mm (seat ID/2)
    // The cone bridges inner_r from 4.8mm (top) to 16.3mm (bottom) over the gap height.
    // Outer radius stays constant at 18.3mm — matches existing body wall.
    // Cone geometry:
    //   The hull body ends at camera_top_z with outer_r ~18.3mm.
    //   The seat ring sits cone_h mm below, also outer_r ~18.3mm.
    //   We add a solid cylinder connecting them, then subtract:
    //     - the seat pocket (CMOUNT_SEAT_ID wide, CMOUNT_SEAT_H deep) at the bottom
    //     - a conical bore that tapers from CMOUNT_CLEAR_D (26mm) at the top face
    //       down to CMOUNT_SEAT_ID (32.6mm) at the bottom — this is the visible taper
    //     - the optical clear bore below the cone
    //   The taper keeps the inner wall self-supporting at any print angle and avoids
    //   a flat unsupported overhang in air.
    cone_h  = CMOUNT_SEAT_H + 1.5;      // 5.5mm — overlaps body + seat with margin
    r_outer = CMOUNT_SEAT_ID/2 + 2.0;   // 18.3mm — matches body outer wall

    difference(){
        union(){
            optics_module_rms(params, optics_config);
            // Solid bridging cylinder — fills the gap between body bottom and seat ring
            translate([0, 0, camera_top_z - cone_h]){
                cylinder(r=r_outer, h=cone_h, $fn=64);
            }
        }
        // Conical inner bore: tapers from CMOUNT_CLEAR_D (top, narrow) to
        // CMOUNT_SEAT_ID (bottom, wide). This creates the shallow visible cone
        // on the inside of the ring and keeps the wall self-supporting.
        translate([0, 0, camera_top_z - cone_h - 0.1]){
            cylinder(r1=CMOUNT_SEAT_ID/2, r2=CMOUNT_CLEAR_D/2,
                     h=cone_h + 0.2, $fn=64);
        }
        // Seat pocket: widens the bottom CMOUNT_SEAT_H mm to full CMOUNT_SEAT_ID
        // to create the step the camera flange seats against.
        translate([0, 0, camera_top_z - CMOUNT_SEAT_H]){
            cylinder(d=CMOUNT_SEAT_ID, h=CMOUNT_SEAT_H + 0.1, $fn=64);
        }
        // Clear optical bore below the cone — punch through any hull material
        translate([0, 0, camera_top_z - cone_h - CMOUNT_BORE_EXTRA]){
            cylinder(d=CMOUNT_CLEAR_D, h=CMOUNT_BORE_EXTRA + 0.1, $fn=64);
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