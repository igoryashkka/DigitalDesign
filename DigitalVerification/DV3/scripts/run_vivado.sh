#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJ_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROJ_DIR="$PROJ_ROOT/vivado_project"
REPO_ROOT="$(cd -- "$PROJ_ROOT/.." && pwd)"

ACTION="${1:-sim}"
SIM_MODE="${2:-gui}"

clean_artifacts() {
  echo "Cleaning Vivado-generated outputs..."
  rm -rf "$PROJ_DIR" "$PROJ_ROOT/xsim.dir" "$PROJ_ROOT/.Xil"

  shopt -s nullglob
  for dir in "$SCRIPT_DIR" "$PROJ_ROOT" "$REPO_ROOT"; do
    for pattern in "vivado.jou" "vivado.log" "*.jou" "*.jou.*" "*.log" "*.log.*"; do
      for file in "$dir"/$pattern; do
        [ -e "$file" ] || continue
        rm -f "$file"
      done
    done
  done
  shopt -u nullglob
  echo "Done."
}

if [[ "$ACTION" == "clean" ]]; then
  clean_artifacts
  exit 0
fi

echo "Running Vivado automation with action $ACTION (mode=$SIM_MODE)"
if ! vivado -mode batch -source "$SCRIPT_DIR/setup_vivado.tcl" -tclargs "$ACTION" "$SIM_MODE"; then
  status=$?
  echo "Vivado automation failed with exit code $status." >&2
  exit $status
fi

echo "Vivado automation complete."
