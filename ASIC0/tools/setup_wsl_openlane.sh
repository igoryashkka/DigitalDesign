#!/usr/bin/env bash
set -euo pipefail

# -------- paths --------
WORKDIR="${HOME}/OpenLane"
PDK_ROOT="${HOME}/.ciel"
PDK="sky130A"

echo "[1/5] Installing base deps (docker + git)..."
sudo apt-get update -y
sudo apt-get install -y git ca-certificates curl

if ! command -v docker >/dev/null 2>&1; then
  echo "[INFO] Docker not found. Installing docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "[WARN] You must logout/login (or restart WSL) for docker group to apply."
fi

echo "[2/5] Prepare folders..."
mkdir -p "${WORKDIR}"
mkdir -p "${WORKDIR}/designs"
mkdir -p "${PDK_ROOT}"

echo "[3/5] Clone OpenLane if not present..."
if [ ! -d "${WORKDIR}/.git" ]; then
  git clone https://github.com/The-OpenROAD-Project/OpenLane.git "${WORKDIR}"
else
  echo "[INFO] OpenLane already exists at ${WORKDIR}"
fi

echo "[4/5] Check ~/.ciel..."
if [ ! -d "${PDK_ROOT}" ]; then
  echo "[ERROR] ${PDK_ROOT} missing. Creating..."
  mkdir -p "${PDK_ROOT}"
fi

echo "[5/5] Done."
echo "Next:"
echo "  1) Put PDK into ${PDK_ROOT} (ciel-managed)."
echo "  2) Use run_openlane.sh (below) to start container & run flow."
