// IDANA bioreactor chip — base plate removed, thin anti-warp foot lip kept.
// ---------------------------------------------------------------------------
// Derived from the delivered mesh chip_senkrecht_mit_bodenplatte.stl (an opaque
// AutoCAD binary export, no parametric source). That part carries a full
// 140 x 100 mm flat plate on its back face purely as print warp control.
//
// This override cuts the plate away and keeps the chip body 1:1:
//   * intersection() of the original watertight solid with the chip-body
//     footprint box removes only the surrounding plate overhang — it never
//     touches the fluidics (optical window, 4 ports, internal chamber all sit
//     inside the 70 x 16 mm footprint), so the chip stays watertight by
//     construction (CGAL yields a closed 2-manifold).
//   * a slim 3 mm-wide, 0.5 mm-thick lip around the bed-contact (back) face is
//     kept as reduced warp control in place of the full plate.
//
// Rebuild (binary STL, Git LFS):
//   openscad --export-format=binstl -o chip_senkrecht_optimiert.stl \
//            chip_senkrecht_optimiert.scad
//
// Source STL sits next to this file (same directory).
chip_stl = "chip_senkrecht_mit_bodenplatte.stl";

// Chip-body footprint in the source STL coordinate frame (measured):
FX0 = 960.9; FXW = 70.6;   // X 960.9 .. 1031.5  (70.6 wide, chip width)
FZ0 = 41.8;  FZH = 16.4;   // Z  41.8 ..   58.2  (16.4 tall, chip height)
// (full Y depth 0..40.5 is kept — that is the optical-axis thickness.)

lip = 3;                   // anti-warp lip width, outward in X/Z (mm)
ply = 40.0; plt = 0.5;     // lip plane: back-face Y start / thickness (mm)

module chip_body(){
  intersection(){
    import(chip_stl, convexity = 12);
    translate([FX0, -2, FZ0]) cube([FXW, 46, FZH]);
  }
}

module foot_lip(){
  translate([FX0 - lip, ply, FZ0 - lip]) cube([FXW + 2*lip, plt, FZH + 2*lip]);
}

union(){ chip_body(); foot_lip(); }
