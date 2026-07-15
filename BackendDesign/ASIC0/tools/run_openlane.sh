#!/usr/bin/env bash
set -euo pipefail

# -------- user config --------
OPENLANE_DIR="${HOME}/OpenLane"
PDK_ROOT_HOST="${HOME}/.ciel"
PDK="sky130A"
IMAGE="ghcr.io/the-openroad-project/openlane:ff5509f65b17bfa4068d5336495ab1718987ff69-amd64"

DESIGN="${1:-designs/verilog_and}"   

# -------- sanity --------
if [ ! -d "${OPENLANE_DIR}" ]; then
  echo "[ERROR] OpenLane dir not found: ${OPENLANE_DIR}"
  exit 1
fi

if [ ! -d "${OPENLANE_DIR}/${DESIGN}" ] && [[ "${DESIGN}" != designs/* ]]; then
  echo "[WARN] design path should be like designs/<name> (relative to OpenLane root)"
fi

if [ ! -d "${PDK_ROOT_HOST}" ]; then
  echo "[ERROR] PDK root not found: ${PDK_ROOT_HOST}"
  echo "Put ciel PDK there (same as you had before)."
  exit 1
fi

# X11 (optional)
DISPLAY_VAR="${DISPLAY:-}"
XSOCK="/tmp/.X11-unix"

echo "[INFO] Running OpenLane container..."
docker run --rm -it \
  -v "${OPENLANE_DIR}:/openlane" \
  -v "${OPENLANE_DIR}/designs:/openlane/designs" \
  -v "${HOME}:${HOME}" \
  -v "${PDK_ROOT_HOST}:${PDK_ROOT_HOST}" \
  -v "${XSOCK}:${XSOCK}" \
  -e "PDK_ROOT=${PDK_ROOT_HOST}" \
  -e "PDK=${PDK}" \
  -e "DISPLAY=${DISPLAY_VAR}" \
  --security-opt seccomp=unconfined \
  --network host \
  --user "$(id -u):$(id -g)" \
  "${IMAGE}" \
  bash -lc "cd /openlane && ./flow.tcl -design ${DESIGN}"
