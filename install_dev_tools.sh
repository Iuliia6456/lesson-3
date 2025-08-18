#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="$(dirname "$0")/install.log"
touch "$LOG_FILE"

log() { echo "[$(date -Iseconds)] $*" | tee -a "$LOG_FILE"; }

need_cmd() { command -v "$1" >/dev/null 2>&1; }

check_version_ge() {
  # check_version_ge "cur" "req"
  python3 - <<PY
import sys, pkg_resources as pr
cur, req = sys.argv[1], sys.argv[2]
sys.exit(0 if pr.parse_version(cur) >= pr.parse_version(req) else 1)
PY
}

install_docker() {
  if need_cmd docker; then
    log "Docker already installed: $(docker --version)"
    return
  fi
  log "Installing Docker Engine..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gnupg lsb-release
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update -y
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  log "Docker installed: $(docker --version)"
  if groups "$USER" | grep -qv docker; then
    sudo usermod -aG docker "$USER" || true
    log "Added $USER to docker group (you may need to re-login)."
  fi
}

install_python() {
  if need_cmd python3; then
    PYV="$(python3 -c 'import sys;print(".".join(map(str,sys.version_info[:3])))')"
    if [[ "$PYV" > "3.9.0" ]]; then
      log "Python already installed: $PYV"
      return
    fi
  fi
  log "Installing Python via apt..."
  sudo apt-get update -y
  sudo apt-get install -y python3 python3-venv python3-pip
}


install_pip_and_libs() {
  if ! need_cmd pip3; then
    log "Installing pip3..."
    sudo apt-get update -y
    sudo apt-get install -y python3-pip
  fi
  PY="python3"
  if need_cmd pyenv; then
    PY="python"
  fi

  log "Upgrading pip..."
  $PY -m pip install --upgrade pip

  # Install libs idempotently 
  log "Installing Python libs: Django, torch, torchvision, pillow (CPU wheels)..."
  $PY -m pip install --upgrade \
    Django pillow \
    --extra-index-url https://download.pytorch.org/whl/cpu \
    torch torchvision

  log "Versions:"
  log "Python: $($PY -V 2>&1)"
  log "pip: $($PY -m pip --version)"
  log "Django: $($PY -c 'import django,sys;print(django.get_version())' 2>/dev/null || echo not found)"
  log "torch: $($PY -c 'import torch,sys;print(torch.__version__)' 2>/dev/null || echo not found)"
  log "torchvision: $($PY -c 'import torchvision,sys;print(torchvision.__version__)' 2>/dev/null || echo not found)"
  log "pillow: $($PY -c 'import PIL,sys;print(PIL.__version__)' 2>/dev/null || echo not found)"
}

main() {
  log "Starting install_dev_tools.sh"
  if need_cmd docker; then log "Docker: $(docker --version)"; else install_docker; fi
  if need_cmd docker compose; then log "Compose: $(docker compose version)"; fi
  install_python
  install_pip_and_libs
  log "All done."
}

main "$@"
