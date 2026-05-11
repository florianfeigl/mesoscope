#!/usr/bin/env bash
# Build mesoscope HQ Camera optics module STLs for both tube lens configurations
#
# Prerequisites:
#   - OpenSCAD >= 2021.01 installed and in PATH
#   - openflexure-microscope repo cloned at ../../sources/openflexure-microscope/
#     (with hq_camera branch checked out, git lfs pulled)
#
# This script copies the custom .scad files into the upstream repo before building.
# If the upstream repo is re-cloned, just re-run this script.
#
# Usage:
#   ./build_optics.sh              # Build all configurations
#   ./build_optics.sh 125           # Build 125mm tube lens only
#   ./build_optics.sh 150           # Build 150mm tube lens only

set -euo pipefail

UPSTREAM_DIR="/home/feivel/dev/mesoscope/resources/openflexure-microscope"
OUTPUT_DIR="/home/feivel/dev/mesoscope/hardware/stl/models"

mkdir -p "${OUTPUT_DIR}"

OPENSCAD_CMD="openscad"
if [ -n "${OPENSCAD:-}" ]; then
    OPENSCAD_CMD="${OPENSCAD}"
fi

echo "=== Mesoscope Optics Module Builder ==="
echo "Upstream repo: ${UPSTREAM_DIR}"

# Copy custom .scad files into upstream repo
if [ ! -d "${UPSTREAM_DIR}/openscad/libs" ]; then
    echo "ERROR: Upstream repo not found at ${UPSTREAM_DIR}"
    echo "Clone it first: git clone --branch hq_camera https://gitlab.com/openflexure/openflexure-microscope.git"
    exit 1
fi

CONFIGS_DIR="/home/feivel/dev/mesoscope/hardware/optics/openscad"

cp "${CONFIGS_DIR}/optics_configurations_hq.scad" "${UPSTREAM_DIR}/openscad/libs/"
cp "${CONFIGS_DIR}/rms_optics_module_hq.scad" "${UPSTREAM_DIR}/openscad/"
# Override the upstream picamera_hq.scad with our C-mount variant.
# The mesoscope uses the HQ Camera intact (C-mount body), not the bare PCB.
cp "${CONFIGS_DIR}/picamera_hq_cmount.scad" "${UPSTREAM_DIR}/openscad/libs/cameras/picamera_hq.scad"
echo "Custom configs copied into upstream repo (including C-mount picamera_hq override)."

echo "Output dir:   ${OUTPUT_DIR}"
echo "OpenSCAD:     ${OPENSCAD_CMD}"
echo ""

build_stl() {
    local lens_f="$1"
    local optics_name="$2"
    local output_file="${OUTPUT_DIR}/optics_hq_${lens_f}_rms.stl"
    local scad_file="${UPSTREAM_DIR}/openscad/rms_optics_module_hq.scad"

    echo "--- Building ${lens_f}mm tube lens (OPTICS=${optics_name}) ---"
    echo "    Output: ${output_file}"
    "${OPENSCAD_CMD}" -o "${output_file}" \
        -D "OPTICS=\"${optics_name}\"" \
        -D "CAMERA=\"picamera_hq\"" \
        -D "PARFOCAL_DISTANCE=45" \
        "${scad_file}" 2>&1 || {
        echo "ERROR: OpenSCAD build failed for ${lens_f}mm lens."
        exit 1
    }
    echo "    Done: $(du -h "${output_file}" | cut -f1)"
    echo ""
}

case "${1:-all}" in
    125)
        build_stl 125 rms_f125d13
        ;;
    150)
        build_stl 150 rms_f150d13
        ;;
    all)
        build_stl 125 rms_f125d13
        build_stl 150 rms_f150d13
        ;;
    *)
        echo "Usage: $0 [125|150|all]"
        exit 1
        ;;
esac

echo "=== Build complete ==="
echo "STLs written to: ${OUTPUT_DIR}/"