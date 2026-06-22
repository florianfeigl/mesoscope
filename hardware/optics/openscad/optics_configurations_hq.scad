// Optics configurations for the mesoscope project
// Pi HQ Camera (IMX477) with 125mm and 150mm achromatic doublet tube lenses
//
// Extends the upstream OpenFlexure optics_configurations.scad for the
// hq_camera branch. Two new RMS configurations are provided:
//   - rms_f125d13_config: 125mm achromatic doublet, 12.7mm dia (f=125mm, ffd=124.1mm)
//   - rms_f150d13_config: 150mm achromatic doublet, 12.7mm dia (f=150mm, ffd=148.8mm)
//
// Both use picamera_hq as the default camera type and maintain the same
// lens diameter (12.7mm) and finite conjugate 160mm tube length as upstream.
//
// Lens specs (BK7+SF2, from taulab supplier via Filip, 2026-06-22):
//   125mm: Fb=124.1mm, T1=3mm, T2=1.3mm, R1=100.08mm, R2=-46.88mm, R3=-109.15mm, AR@400-700nm
//   150mm: Fb=148.8mm, T1=3mm, T2=1.3mm, R1=130.619mm, R2=-55.232mm, R3=-121.056mm, AR@400-700nm
//
// References:
//   - OPTICS_MODULE.md for optical calculations
//   - CORRESPONDENCE.md for OpenFlexure team confirmation (William, 2026-03-30)

use <./libdict.scad>  // resolves via symlink in upstream libs/

// 125mm tube lens configuration (achromatic doublet, 12.7mm diameter)
// For <=4x objectives, or where wider field of view is desired
// tube_lens_ffd = 124.1mm (confirmed by taulab supplier via Filip, 2026-06-22)
function rms_f125d13_config(camera_type = "picamera_hq", beamsplitter=false, parfocal_distance=45) = let(
    parfocal_distance_validated = (parfocal_distance == undef) ? 45 : parfocal_distance,
    lens_objective_distance = max(45 - parfocal_distance_validated, 0) + 8.5,
    config_dict = [["optics_type", "RMS"],
                   ["camera_type", camera_type],
                   ["tube_lens_ffd", 124.1],
                   ["tube_lens_f", 125],
                   ["tube_lens_r", 12.7/2+0.1],
                   ["objective_parfocal_distance", parfocal_distance_validated],
                   ["beamsplitter", beamsplitter],
                   ["gripper_t", 1],
                   ["is_finite_conjugate", true],
                   ["objective_mechanical_tube_length", 160],
                   ["lens_objective_distance", lens_objective_distance],
                   ["camera_rotation", 0],
                   ["beamsplitter_rotation", 0]]
) config_dict;

// 150mm tube lens configuration (achromatic doublet, 12.7mm diameter)
// For <=10x objectives (preferred per OPTICS_MODULE.md analysis)
// tube_lens_ffd = 148.8mm (confirmed by taulab supplier via Filip, 2026-06-22)
function rms_f150d13_config(camera_type = "picamera_hq", beamsplitter=false, parfocal_distance=45) = let(
    parfocal_distance_validated = (parfocal_distance == undef) ? 45 : parfocal_distance,
    lens_objective_distance = max(45 - parfocal_distance_validated, 0) + 8.5,
    config_dict = [["optics_type", "RMS"],
                   ["camera_type", camera_type],
                   ["tube_lens_ffd", 148.8],
                   ["tube_lens_f", 150],
                   ["tube_lens_r", 12.7/2+0.1],
                   ["objective_parfocal_distance", parfocal_distance_validated],
                   ["beamsplitter", beamsplitter],
                   ["gripper_t", 1],
                   ["is_finite_conjugate", true],
                   ["objective_mechanical_tube_length", 160],
                   ["lens_objective_distance", lens_objective_distance],
                   ["camera_rotation", 0],
                   ["beamsplitter_rotation", 0]]
) config_dict;

// Infinity conjugate variants
// Use with infinity-corrected objectives (marked with ∞ on the barrel)
function rms_infinity_f125d13_config(camera_type = "picamera_hq", beamsplitter=false, parfocal_distance=undef) = let(
    finite_config = rms_f125d13_config(camera_type, beamsplitter, parfocal_distance=parfocal_distance),
    replacements = [["is_finite_conjugate", false]]
) replace_multiple_values(replacements, finite_config);

function rms_infinity_f150d13_config(camera_type = "picamera_hq", beamsplitter=false, parfocal_distance=undef) = let(
    finite_config = rms_f150d13_config(camera_type, beamsplitter, parfocal_distance=parfocal_distance),
    replacements = [["is_finite_conjugate", false]]
) replace_multiple_values(replacements, finite_config);