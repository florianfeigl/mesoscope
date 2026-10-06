#!/usr/bin/env bash
# Build the parametric rounded-tooth gear pair STLs for the mesoscope.
#
# STANDALONE: like hardware/rails/openscad/build_rack.sh, this needs NO upstream
# OpenFlexure clone. gear_pair.scad has no upstream dependency.
#
# Prerequisites:
#   - OpenSCAD >= 2021.01 in PATH (or set OPENSCAD to the binary)
#
# Usage:
#   ./build_gears.sh            # builds both gears (rad1 ring + rad2 mate)
#   ./build_gears.sh rad1       # only Rad 1 (the ring)
#   ./build_gears.sh rad2       # only Rad 2 (the mate)
#
# Output: hardware/stl/models/gear_rad1.stl, gear_rad2.stl

set -euo pipefail

WHICH="${1:-both}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="$(cd "${SCRIPT_DIR}/../../stl/models" && pwd)"
SCAD_FILE="${SCRIPT_DIR}/gear_pair.scad"

mkdir -p "${OUTPUT_DIR}"

OPENSCAD_CMD="openscad"
if [ -n "${OPENSCAD:-}" ]; then
    OPENSCAD_CMD="${OPENSCAD}"
fi

echo "=== Mesoscope Gear Pair Builder (standalone) ==="
echo "SCAD:     ${SCAD_FILE}"
echo "OpenSCAD: ${OPENSCAD_CMD}"
echo "Build:    ${WHICH}"
echo ""

build_part() {
    local part="$1"
    local out="${OUTPUT_DIR}/gear_${part}.stl"
    echo "--- ${part} -> ${out}"
    "${OPENSCAD_CMD}" -o "${out}" \
        -D "part=\"${part}\"" \
        "${SCAD_FILE}" 2>&1 || {
        echo "ERROR: OpenSCAD build failed for part=${part}."
        exit 1
    }
    echo "    done: $(du -h "${out}" | cut -f1)"
}

case "${WHICH}" in
    rad1) build_part rad1 ;;
    rad2) build_part rad2 ;;
    both) build_part rad1; build_part rad2 ;;
    *) echo "ERROR: unknown argument '${WHICH}' (use: both | rad1 | rad2)"; exit 1 ;;
esac

echo ""
echo "=== Build complete ==="
