// Mesoscope — exploded view of the RAIL stack (tilted microscope on X-rail)
// ---------------------------------------------------------------
// Re-uses the massing modules of hardware/mount/openscad/rail_mount_mesoscope.scad
// (via `use`, so its own assembly section is NOT emitted) and pulls the layers
// apart along +Z:
//   base plate -> 2040 beam -> MGN12 rail -> carriage -> adapter -> microscope
//   -> X drive (leadscrew, NEMA17, nut block) -> bridge -> bioreactor chips.
// Copied into the upstream rendering/ directory by build_exploded.sh; the
// `use` path below is relative to that location. The microscope STL path
// inside rail_mount_mesoscope.scad resolves relative to that file, so it
// still finds hardware/stl/models/complete_microscope_rms.stl.
//
// `use` does not export variables, so the few layout numbers needed here are
// MIRRORED from rail_mount_mesoscope.scad (keep in sync):
//   carriage_x = 0, n_reactors = 4, reactor_pitch = 80, margin = 100,
//   gp_t = 8, ext_h = 20, oa_h = 115, reactor_h = 40.

use <../../../hardware/mount/openscad/rail_mount_mesoscope.scad>

// 0 = assembled, 1 = fully exploded
explode = 1;

// --- mirrored layout parameters ---
carriage_x    = 0;
n_reactors    = 4;
reactor_pitch = 80;
margin        = 100;
gp_t          = 8;
oa_z          = 20 + 115;                       // ext_h + oa_h
reactor_h     = 40;
span          = (n_reactors - 1) * reactor_pitch;
rail_x0       = -margin;
rail_len      = span + 2 * margin;
ls_len        = rail_len - 20;

// explosion offsets (mm, scaled by `explode`)
ex_beam    = 25;
ex_rail    = 50;
ex_carr    = 75;
ex_adapter = 100;
ex_scope   = 140;
ex_drive   = 60;
ex_bridge  = 200;
ex_chips   = 240;

function ez(v) = [0, 0, v * explode];

base_plate();
translate(ez(ex_beam))    beam();
translate(ez(ex_rail))    mgn12_rail();
translate(ez(ex_carr))    mgn12_carriage(carriage_x);
translate(ez(ex_adapter)) carriage_adapter(carriage_x);
translate(ez(ex_scope)) {
    microscope(carriage_x);
    optical_axis_line(carriage_x);
}
translate(ez(ex_drive)) {
    leadscrew();
    nema17(rail_x0 + 10);
    coupler(rail_x0 + 10);
    end_bearing(rail_x0 + ls_len + 10);
    nut_block(carriage_x);
}
translate(ez(ex_bridge)) reactor_bridge();
translate(ez(ex_chips))  for (i = [0 : n_reactors - 1]) reactor(i * reactor_pitch);

if (explode > 0)
    color("Gray", 0.5) translate([carriage_x, 0, -gp_t])
        cylinder(d=1, h=oa_z + reactor_h + ex_chips * explode + gp_t);
