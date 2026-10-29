#!/usr/bin/env bash
# Build the 3-part printable bioreactor bridge (continuous board split into 3
# segments + 2 end pillars, M3 splice tabs) for the mesoscope RAILS construction.
#
# STANDALONE: like build_rack.sh, this needs NO upstream OpenFlexure clone —
# bioreactor_bridge_split.scad renders directly.
#
# Prerequisites:
#   - OpenSCAD >= 2021.01 in PATH (or set OPENSCAD to the binary)
#
# Usage:
#   ./build_bridge_split.sh          # default N=4 stations
#   ./build_bridge_split.sh 5        # N=5 stations
#
# Outputs (hardware/stl/models/ — Git LFS, run `git lfs install` first):
#   bioreactor_bridge_seg0_n<N>.stl   left  board segment
#   bioreactor_bridge_seg1_n<N>.stl   middle board segment
#   bioreactor_bridge_seg2_n<N>.stl   right board segment
#   bioreactor_bridge_pillar_n<N>.stl end pillar (identical L/R, print 2x)
# And an exploded preview PNG for the presentation:
#   hardware/rails/bridge_split_exploded.png

set -euo pipefail

N="${1:-4}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$(cd "${SCRIPT_DIR}/../../stl/models" && pwd)"
PNG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"          # hardware/rails/
SCAD_FILE="${SCRIPT_DIR}/bioreactor_bridge_split.scad"

OPENSCAD_CMD="${OPENSCAD:-openscad}"
IMGSIZE="${IMGSIZE:-1600,1000}"

mkdir -p "${OUTPUT_DIR}"

echo "=== Mesoscope Bioreactor Bridge Split Builder (standalone) ==="
echo "SCAD:     ${SCAD_FILE}"
echo "Output:   ${OUTPUT_DIR}"
echo "OpenSCAD: ${OPENSCAD_CMD}"
echo "Stations: N=${N}"
echo ""

# --- printable parts (one-piece bridge + one tower; print the tower 2x) ---
BRIDGE_OUT="${OUTPUT_DIR}/bioreactor_bridge_n${N}.stl"
echo "--- bridge -> ${BRIDGE_OUT}"
"${OPENSCAD_CMD}" -o "${BRIDGE_OUT}" -D 'part="bridge"' -D "N=${N}" "${SCAD_FILE}" 2>&1 \
    | grep -iE "ECHO|ERROR|WARNING" || true
TOWER_OUT="${OUTPUT_DIR}/bioreactor_bridge_tower_n${N}.stl"
echo "--- tower -> ${TOWER_OUT}"
"${OPENSCAD_CMD}" -o "${TOWER_OUT}" -D 'part="pillarL"' -D "N=${N}" "${SCAD_FILE}" 2>&1 \
    | grep -iE "ERROR|WARNING" || true

# --- exploded preview PNG (bridge lifted off the two towers) ---
PNG_OUT="${PNG_DIR}/bridge_split_exploded.png"
CAM="0,0,0,62,0,22,900"   # gimbal: tx,ty,tz,rx,ry,rz,dist (viewall overrides dist)
echo "--- preview PNG -> ${PNG_OUT}"
"${OPENSCAD_CMD}" -o "${PNG_OUT}" \
    -D "N=${N}" -D 'part="all"' -D "exploded=true" -D "show_chip_ref=true" \
    --preview --projection=o --colorscheme=Tomorrow \
    --imgsize="${IMGSIZE}" --camera="${CAM}" --viewall --autocenter \
    "${SCAD_FILE}"

echo ""
echo "=== Build complete ==="
for f in "${OUTPUT_DIR}"/bioreactor_bridge_*_n${N}.stl "${PNG_OUT}"; do
    [ -f "${f}" ] && echo "  $(du -h "${f}" | cut -f1)  ${f}"
done