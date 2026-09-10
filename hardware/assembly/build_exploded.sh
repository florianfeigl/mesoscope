#!/usr/bin/env bash
# Render the mesoscope exploded-view PNGs (and optionally the rail-stack view).
#
# Prerequisites: OpenSCAD >= 2021.01, upstream openflexure-microscope clone
# (hq_camera branch) at UPSTREAM_DIR, and the rendered STLs in
# hardware/stl/models/ (git lfs pull).
#
# The scene files are copied into the upstream clone's rendering/ directory so
# they can `use` the upstream render library (same pattern as build_stand.sh
# and hardware/mount/openscad/*.scad). The stand overrides are copied too, so
# the Pi 5 / AI-HAT stand parameters resolve.
#
# Usage:
#   ./build_exploded.sh            # exploded + assembled PNG of the upright stack
#   ./build_exploded.sh rail       # also render the rail-stack view
#   EXPLODE=0.5 ./build_exploded.sh  # partial explosion

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
UPSTREAM_DIR="${REPO_DIR}/sources/openflexure-microscope"
STAND_DIR="${REPO_DIR}/hardware/stand/openscad"
OUT_DIR="${SCRIPT_DIR}"
OPENSCAD_CMD="${OPENSCAD:-openscad}"
EXPLODE="${EXPLODE:-1}"
IMGSIZE="${IMGSIZE:-1600,1200}"

if [ ! -d "${UPSTREAM_DIR}/rendering/librender" ]; then
    echo "ERROR: upstream clone not found at ${UPSTREAM_DIR}" >&2
    echo "Clone it: git clone --branch hq_camera https://gitlab.com/openflexure/openflexure-microscope.git ${UPSTREAM_DIR}" >&2
    exit 1
fi

# stand overrides (Pi 5 + AI HAT drawer parameters)
cp "${STAND_DIR}/lib_microscope_stand_mesoscope.scad" "${UPSTREAM_DIR}/openscad/libs/lib_microscope_stand.scad"
cp "${STAND_DIR}/electronics_drawer_mesoscope.scad"   "${UPSTREAM_DIR}/openscad/electronics_drawer.scad"
# scene files
cp "${SCRIPT_DIR}/openscad/exploded_view.scad"   "${UPSTREAM_DIR}/rendering/exploded_view_mesoscope.scad"
cp "${SCRIPT_DIR}/openscad/exploded_rail.scad"   "${UPSTREAM_DIR}/rendering/exploded_rail_mesoscope.scad"
cp "${SCRIPT_DIR}/openscad/exploded_drawer.scad" "${UPSTREAM_DIR}/rendering/exploded_drawer_mesoscope.scad"

render_png() {   # scene explode output camera [extra_define]
    local scene="$1" explode="$2" out="$3" cam="$4" extra_def="${5:-}"
    local extra_args=()
    [ -n "${extra_def}" ] && extra_args=(-D "${extra_def}")
    echo "--- ${out} (explode=${explode}${extra_def:+, ${extra_def}})"
    "${OPENSCAD_CMD}" -o "${out}" \
        -D "explode=${explode}" ${extra_args[@]+"${extra_args[@]}"} \
        --preview --projection=o --colorscheme=Tomorrow \
        --imgsize="${IMGSIZE}" --camera="${cam}" --viewall --autocenter \
        "${UPSTREAM_DIR}/rendering/${scene}"
}

# gimbal camera: tx,ty,tz,rot_x,rot_y,rot_z,distance (viewall/autocenter override tx..dist)
FRONT_CAM="0,0,0,65,0,35,900"
BACK_CAM="0,0,0,65,0,215,900"   # same tilt, rot_z + 180 = exactly opposite side
# labelled front + back
render_png exploded_view_mesoscope.scad "${EXPLODE}" "${OUT_DIR}/exploded_view.png"               "${FRONT_CAM}"
render_png exploded_view_mesoscope.scad "${EXPLODE}" "${OUT_DIR}/exploded_view_back.png"          "${BACK_CAM}"  "label_back=1"
# unlabelled front + back
render_png exploded_view_mesoscope.scad "${EXPLODE}" "${OUT_DIR}/exploded_view_nolabels.png"      "${FRONT_CAM}" "show_labels=0"
render_png exploded_view_mesoscope.scad "${EXPLODE}" "${OUT_DIR}/exploded_view_back_nolabels.png" "${BACK_CAM}"  "show_labels=0"
# assembled reference
render_png exploded_view_mesoscope.scad 0            "${OUT_DIR}/exploded_view_assembled.png"     "${FRONT_CAM/900/600}"

# electronics drawer + tech stack only (Pi 5 / AI HAT+ / Sangaboard)
DRAWER_CAM="0,0,0,60,0,35,400"
render_png exploded_drawer_mesoscope.scad "${EXPLODE}" "${OUT_DIR}/exploded_drawer.png"          "${DRAWER_CAM}"
render_png exploded_drawer_mesoscope.scad "${EXPLODE}" "${OUT_DIR}/exploded_drawer_nolabels.png" "${DRAWER_CAM}" "show_labels=0"
render_png exploded_drawer_mesoscope.scad 0            "${OUT_DIR}/exploded_drawer_assembled.png" "${DRAWER_CAM/400/300}"

if [ "${1:-}" = "rail" ]; then
    render_png exploded_rail_mesoscope.scad "${EXPLODE}" "${OUT_DIR}/exploded_rail.png" "0,0,0,60,0,25,1600"
fi

echo "=== done: ${OUT_DIR}/exploded_view*.png ==="
