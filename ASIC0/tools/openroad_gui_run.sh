#!/usr/bin/env bash
set -euo pipefail

ODB_PATH="${1:?Usage: ./openroad_gui_run.sh <path/to/design.odb>}"
PDK_ROOT_HOST="${HOME}/.ciel"
PDK="sky130A"

TECH_LEF="${PDK_ROOT_HOST}/sky130A/libs.ref/sky130_fd_sc_hd/techlef/sky130_fd_sc_hd__nom.tlef"
LIB_LEF="${PDK_ROOT_HOST}/sky130A/libs.ref/sky130_fd_sc_hd/lef/sky130_fd_sc_hd.lef"

if [ ! -f "${ODB_PATH}" ]; then
  echo "[ERROR] ODB not found: ${ODB_PATH}"
  exit 1
fi

openroad -gui <<EOF
read_lef ${TECH_LEF}
read_lef ${LIB_LEF}
read_db ${ODB_PATH}
gui::show
EOF
