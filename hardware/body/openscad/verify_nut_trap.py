#!/usr/bin/env python3
"""Verify the M3 nut-trap geometry in main_body_mesoscope.stl.
Transforms STL vertices into the motor-screw-local frame and reports the
hole-wall radius profile by depth. Pass a path to any body STL as argv[1].
"""
import math, collections, sys

# rigid-inverse: body -> screw-local (+x screw at body x=+17.5; local +z = screw axis)
INV = [[1, 0, 0, -17.5],
       [0, 0.911971, -0.410256, -40.724750],
       [0, 0.410256, 0.911971, -64.733535],
       [0, 0, 0, 1]]

def xf(p):
    return [sum(INV[i][j] * p[j] for j in range(3)) + INV[i][3] for i in range(3)]

path = sys.argv[1] if len(sys.argv) > 1 else "hardware/stl/models/main_body_mesoscope.stl"
verts = []
for line in open(path):
    line = line.strip()
    if line.startswith("vertex"):
        _, x, y, z = line.split()
        verts.append(xf([float(x), float(y), float(z)]))

bins = collections.defaultdict(list)
for lx, ly, lz in verts:
    r = math.hypot(lx, ly)
    if r < 6 and -14 < lz < 6:
        bins[round(lz)].append((r, math.atan2(ly, lx)))

print("Screw-local hole profile for:", path)
print(f"{'z':>4} {'n':>5} {'rmin':>6} {'angles':>7}  note")
hex_found = clear_found = False
for z in sorted(bins):
    rs = [r for r, a in bins[z]]
    rmin = min(rs)
    nwall = len(set(round(math.degrees(a)) for r, a in bins[z] if r < rmin + 0.5))
    note = ""
    if abs(rmin - 1.725) < 0.12 and nwall >= 8:
        note = "round M3 clearance Ø%.2f (no triangular lobes)" % (2 * rmin); clear_found = True
    if 5 <= nwall <= 7 and 3.0 < rmin < 3.4:
        note = "HEX M3 nut pocket"; hex_found = True
    print(f"{z:>4} {len(rs):>5} {rmin:>6.3f} {nwall:>7}  {note}")

print()
print("round M3 clearance present: ", clear_found)
print("hex M3 pocket present:       ", hex_found)
print("RESULT:", "GEOMETRY-OK" if (clear_found and hex_found) else "GEOMETRY-MISSING")
