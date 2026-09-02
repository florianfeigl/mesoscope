#!/usr/bin/env bash
# Build the parametric bioreactor rack STL for the mesoscope RAILS construction.
#
# STANDALONE: unlike hardware/optics/openscad/build_optics.sh and
# hardware/stand/openscad/build_stand.sh, this script needs NO upstream
# OpenFlexure clone. bioreactor_rack.scad has no upstream dependency, so this
# just renders it directly.
#
# Prerequisites:
#   - OpenSCAD >= 2021.01 in PATH (or set OPENSCAD to the binary)
#
# Usage:
#   ./build_rack.sh          # default N=3 stations
#   ./build_rack.sh 5        # N=5 stations
#
# Output: hardware/stl/models/bioreactor_rack_n<N>.stl

set -euo pipefail

N="${1:-3}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$(cd "${SCRIPT_DIR}/../../stl/models" && pwd)"
SCAD_FILE="${SCRIPT_DIR}/bioreactor_rack.scad"

mkdir -p "${OUTPUT_DIR}"

OPENSCAD_CMD="openscad"
if [ -n "${OPENSCAD:-}" ]; then
    OPENSCAD_CMD="${OPENSCAD}"
fi

OUTPUT_FILE="${OUTPUT_DIR}/bioreactor_rack_n${N}.stl"

echo "=== Mesoscope Bioreactor Rack Builder (standalone) ==="
echo "SCAD:       ${SCAD_FILE}"
echo "Output:     ${OUTPUT_FILE}"
echo "OpenSCAD:   ${OPENSCAD_CMD}"
echo "Stations:   N=${N}"
echo ""

"${OPENSCAD_CMD}" -o "${OUTPUT_FILE}" \
    -D "N=${N}" \
    "${SCAD_FILE}" 2>&1 || {
    echo "ERROR: OpenSCAD build failed for N=${N}."
    exit 1
}

echo ""
echo "=== Build complete ==="
echo "Done: $(du -h "${OUTPUT_FILE}" | cut -f1)  ->  ${OUTPUT_FILE}"
