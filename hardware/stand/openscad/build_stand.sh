#!/usr/bin/env bash
# Build mesoscope microscope stand STL — Pi5 + AI-HAT + Sangaboard variant
#
# Prerequisites:
#   - OpenSCAD >= 2021.01 installed and in PATH
#   - openflexure-microscope repo cloned at UPSTREAM_DIR
#     (with hq_camera branch checked out, git lfs pulled)
#
# This script copies the custom microscope_stand .scad files into the
# upstream repo before building, overriding the upstream defaults
# (same pattern as build_optics.sh).
#
# Usage:
#   ./build_stand.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPSTREAM_DIR="${SCRIPT_DIR}/../../sources/openflexure-microscope"
OUTPUT_DIR="${SCRIPT_DIR}/../../stl/models"

mkdir -p "${OUTPUT_DIR}"

OPENSCAD_CMD="openscad"
if [ -n "${OPENSCAD:-}" ]; then
    OPENSCAD_CMD="${OPENSCAD}"
fi

echo "=== Mesoscope Microscope Stand Builder ==="
echo "Upstream repo: ${UPSTREAM_DIR}"

if [ ! -d "${UPSTREAM_DIR}/openscad/libs" ]; then
    echo "ERROR: Upstream repo not found at ${UPSTREAM_DIR}"
    echo "Clone it first: git clone --branch hq_camera https://gitlab.com/openflexure/openflexure-microscope.git"
    exit 1
fi

cp "${SCRIPT_DIR}/microscope_stand_mesoscope.scad" "${UPSTREAM_DIR}/openscad/microscope_stand.scad"
cp "${SCRIPT_DIR}/lib_microscope_stand_mesoscope.scad" "${UPSTREAM_DIR}/openscad/libs/lib_microscope_stand.scad"
echo "Custom stand configs copied into upstream repo."

echo "Output dir:   ${OUTPUT_DIR}"
echo "OpenSCAD:     ${OPENSCAD_CMD}"
echo ""

OUTPUT_FILE="${OUTPUT_DIR}/microscope_stand_mesoscope.stl"

echo "--- Building microscope stand (Pi5 + AI-HAT + Sangaboard) ---"
echo "    Output: ${OUTPUT_FILE}"
"${OPENSCAD_CMD}" -o "${OUTPUT_FILE}" \
    "${UPSTREAM_DIR}/openscad/microscope_stand.scad" 2>&1 || {
    echo "ERROR: OpenSCAD build failed."
    exit 1
}
echo "    Done: $(du -h "${OUTPUT_FILE}" | cut -f1)"
echo ""
echo "=== Build complete ==="
echo "STL written to: ${OUTPUT_FILE}"
