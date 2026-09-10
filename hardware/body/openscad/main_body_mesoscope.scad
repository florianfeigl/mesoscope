/******************************************************************
*                                                                 *
* Mesoscope main body (OpenFlexure override)                      *
*                                                                 *
* Copied into the upstream clone as openscad/main_body.scad by    *
* build_body.sh together with main_body_structure_mesoscope.scad. *
* Renders the Z-focus-only body: no sample stage (Tisch), no X/Y  *
* flexure legs, actuators or motor housings.                      *
*                                                                 *
******************************************************************/

use <./libs/utilities.scad>
use <./libs/libdict.scad>
use <./libs/microscope_parameters.scad>
use <./libs/main_body_structure.scad>

//Note that the main body is complex enough you should run Render not preview
// To use in preview wrap with render(6)
VERSION_STRING = "Mesoscope";
main_body_stl(VERSION_STRING);

module main_body_stl(version_string){
    params = default_params();
    smart_brim_r = key_lookup("smart_brim_r", params);
    exterior_brim(r=smart_brim_r){
        main_body(params, version_string);
    }
}
