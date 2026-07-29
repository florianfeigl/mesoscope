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
cp "${SCRIPT_DIR}/electronics_drawer_mesoscope.scad" "${UPSTREAM_DIR}/openscad/electronics_drawer.scad"
cp "${SCRIPT_DIR}/lib_microscope_stand_mesoscope.scad" "${UPSTREAM_DIR}/openscad/libs/lib_microscope_stand.scad"
echo "Custom stand configs copied into upstream repo."

echo "Output dir:   ${OUTPUT_DIR}"
echo "OpenSCAD:     ${OPENSCAD_CMD}"
echo ""

build_stl() {
    local scad_name="$1"
    local scad_path="${UPSTREAM_DIR}/openscad/${scad_name}.scad"
    local output_file="${OUTPUT_DIR}/${scad_name}_mesoscope.stl"
    echo "--- Building ${scad_name} ---"
    echo "    Output: ${output_file}"
    "${OPENSCAD_CMD}" -o "${output_file}" \
        "${scad_path}" 2>&1 || {
        echo "ERROR: OpenSCAD build failed for ${scad_name}."
        exit 1
    }
    echo "    Done: $(du -h "${output_file}" | cut -f1)"
    echo ""
}

build_stl "microscope_stand"
build_stl "electronics_drawer"

echo "=== Build complete ==="
