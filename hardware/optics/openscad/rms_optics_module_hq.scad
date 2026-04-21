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
use <./libs/optics_configurations.scad>
use <./libs/optics_configurations_hq.scad>

// Override these from the command line with -D, e.g. -D 'OPTICS="rms_f125d13"'
OPTICS = "rms_f125d13";
BEAMSPLITTER = false;
CAMERA = "picamera_hq";
PARFOCAL_DISTANCE = 45;

configurable_optics_module(OPTICS, CAMERA, BEAMSPLITTER, PARFOCAL_DISTANCE);

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

    // 125mm tube lens (achromatic doublet) — finite conjugate
    if (optics=="rms_f125d13"){
        optics_config = rms_f125d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        optics_module_rms(params, optics_config);
    }
    // 150mm tube lens (achromatic doublet) — finite conjugate
    else if (optics=="rms_f150d13"){
        optics_config = rms_f150d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        optics_module_rms(params, optics_config);
    }
    // 125mm tube lens — infinity conjugate
    else if (optics=="rms_infinity_f125d13"){
        optics_config = rms_infinity_f125d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        optics_module_rms(params, optics_config);
    }
    // 150mm tube lens — infinity conjugate
    else if (optics=="rms_infinity_f150d13"){
        optics_config = rms_infinity_f150d13_config(
            camera_type=camera_type,
            beamsplitter=beamsplitter,
            parfocal_distance=parfocal_distance
        );
        optics_module_rms(params, optics_config);
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