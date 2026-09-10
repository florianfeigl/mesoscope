#!/usr/bin/env bash
# Build the mesoscope main body STL — Z-focus-only variant (no sample stage,
# no X/Y flexure legs / actuators / motor housings) for the rail mount.
#
# Prerequisites:
#   - OpenSCAD >= 2021.01 installed and in PATH
#   - openflexure-microscope repo cloned at UPSTREAM_DIR
#     (with hq_camera branch checked out, git lfs pulled)
#
# This script copies the custom main_body .scad files into the upstream repo
# before building, overriding the upstream defaults (same pattern as
# build_stand.sh). The upstream originals are kept in this directory as
# main_body_original.scad / main_body_structure_original.scad.
#
# Usage:
#   ./build_body.sh            # mesoscope variant -> main_body_mesoscope.stl
#   ./build_body.sh original   # upstream body     -> main_body_original.stl
#   ./build_body.sh all        # both

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPSTREAM_DIR="${SCRIPT_DIR}/../../../sources/openflexure-microscope"
OUTPUT_DIR="${SCRIPT_DIR}/../../../hardware/stl/models"
VARIANT="${1:-mesoscope}"

mkdir -p "${OUTPUT_DIR}"

OPENSCAD_CMD="openscad"
if [ -n "${OPENSCAD:-}" ]; then
    OPENSCAD_CMD="${OPENSCAD}"
fi

echo "=== Mesoscope Main Body Builder ==="
echo "Upstream repo: ${UPSTREAM_DIR}"
echo "Output dir:    ${OUTPUT_DIR}"
echo "OpenSCAD:      ${OPENSCAD_CMD}"
echo ""

if [ ! -d "${UPSTREAM_DIR}/openscad/libs" ]; then
    echo "ERROR: Upstream repo not found at ${UPSTREAM_DIR}"
    echo "Clone it first: git clone --branch hq_camera https://gitlab.com/openflexure/openflexure-microscope.git"
    exit 1
fi

build_variant() {
    local name="$1"   # mesoscope | original
    local output_file="${OUTPUT_DIR}/main_body_${name}.stl"

    cp "${SCRIPT_DIR}/main_body_${name}.scad" "${UPSTREAM_DIR}/openscad/main_body.scad"
    cp "${SCRIPT_DIR}/main_body_structure_${name}.scad" "${UPSTREAM_DIR}/openscad/libs/main_body_structure.scad"
    echo "--- Building main_body (${name}) ---"
    echo "    Output: ${output_file}"
    "${OPENSCAD_CMD}" -o "${output_file}" \
        "${UPSTREAM_DIR}/openscad/main_body.scad" 2>&1 || {
        echo "ERROR: OpenSCAD build failed for main_body (${name})."
        exit 1
    }
    echo "    Done: $(du -h "${output_file}" | cut -f1)"
    echo ""
}

case "${VARIANT}" in
    mesoscope) build_variant "mesoscope" ;;
    original)  build_variant "original" ;;
    all)       build_variant "original"; build_variant "mesoscope" ;;
    *) echo "Usage: $0 [mesoscope|original|all]"; exit 1 ;;
esac

# Leave the upstream clone in the mesoscope state so the rendering scenes
# (rendering/librender/rendered_main_body.scad etc.) pick up the variant.
cp "${SCRIPT_DIR}/main_body_mesoscope.scad" "${UPSTREAM_DIR}/openscad/main_body.scad"
cp "${SCRIPT_DIR}/main_body_structure_mesoscope.scad" "${UPSTREAM_DIR}/openscad/libs/main_body_structure.scad"

echo "=== Build complete ==="
