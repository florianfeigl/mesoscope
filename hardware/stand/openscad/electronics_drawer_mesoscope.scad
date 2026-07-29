// Mesoscope electronics drawer — Pi5 + AI-HAT + Sangaboard variant
//
// This file replaces the upstream electronics_drawer.scad when building
// the mesoscope variant. The build script copies it into the upstream repo.
//
// Build:
//   cd hardware/stand/openscad
//   ./build_stand.sh

use <./libs/lib_microscope_stand.scad>

PI_VERSION = 5;
SANGA_VERSION = "ai_hat_stack";

electronics_drawer_stl(PI_VERSION, SANGA_VERSION);

module electronics_drawer_stl(pi_version=5, sanga_version="ai_hat_stack"){
    stand_params = default_stand_params(pi_version=pi_version,
                                        sanga_version=sanga_version);
    electronics_drawer(stand_params);
}
