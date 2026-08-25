// Mesoscope variant: complete RMS microscope WITHOUT sample clips and
// WITHOUT the illumination arm (dovetail + condenser + wiring).
// The rail-mount concept hangs bioreactor chips at the sample plane and
// images through them horizontally; the stock condenser reaches to only
// ~2.5 mm above the sample plane and cannot clear a 16 mm chip, so the
// illumination will be redesigned as a separate light source behind the
// chips. This render therefore omits the whole illumination assembly.
// Mirrors rendering/complete_microscope.scad::render_microscope minus
// render_sample_clips(), and re-composes
// mount_motors.scad::assembled_microscope_without_electronics without the
// mounted_microscope_with_illumination() call (motors + bare microscope).
// Copy into the upstream clone's rendering/ directory to render.
use <../openscad/libs/microscope_parameters.scad>
use <../openscad/libs/utilities.scad>
use <../openscad/libs/lib_microscope_stand.scad>
use <../openscad/electronics_drawer.scad>
use <librender/assembly_parameters.scad>
use <librender/render_utils.scad>
use <librender/render_settings.scad>
use <librender/hardware.scad>
use <librender/electronics.scad>
use <./electronics/sangaboard.scad>
use <mount_motors.scad>
use <mount_microscope.scad>

rotate([-90,0,0]) render_microscope_noclips_noillum(false);

module render_microscope_noclips_noillum(low_cost=false){
    // assembled_microscope_without_electronics() minus illumination:
    params = render_params();
    mounted_microscope_frame(){
        mirror([1, 0, 0]){
            y_motor_and_cap(params, mirror_connector=true);
        }
        y_motor_and_cap(params);
        z_motor_and_cap(params);
    }
    mounted_microscope(low_cost=low_cost);

    electronics_drawer_frame_xy(render_params()){
        coloured_render(body_colour()){
            electronics_drawer_stl(pi_version=4, sanga_version="stack_11mm");
        }

        translate(electronics_drawer_board_inset() + [0, 0, electronics_drawer_standoff_h()]){
            rpi_4b();
        }

        translate(electronics_drawer_board_inset() + [0, 0, sanga_stand_height("stack_11mm")]){
            sangaboard_v0_5();
        }
    }
}
