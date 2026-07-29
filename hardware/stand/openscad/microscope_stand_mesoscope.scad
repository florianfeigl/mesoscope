// Mesoscope microscope stand entry point
// Override: Pi5 + AI-HAT + Sangaboard stack (vs. upstream Pi4 + Sangaboard)
//
// This file replaces the upstream microscope_stand.scad when building
// the mesoscope variant. The build script copies it into the
// openflexure-microscope repo before rendering.
//
// Build:
//   cd hardware/stand/openscad
//   ./build_stand.sh

use <./libs/microscope_parameters.scad>
use <./libs/lib_microscope_stand.scad>

TALL_BUCKET_BASE = false;

microscope_stand_stl(TALL_BUCKET_BASE);

module microscope_stand_stl(tall_bucket_base){
    params = default_params();
    stand_params = default_stand_params(
        tall=tall_bucket_base,
        pi_version=5,
        sanga_version="ai_hat_stack"
    );
    microscope_stand(params, stand_params);
}
