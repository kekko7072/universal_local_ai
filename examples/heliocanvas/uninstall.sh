#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

purge_docker=false
assume_yes=false

for argument in "$@"; do
  case "$argument" in
    --purge-docker) purge_docker=true ;;
    --yes) assume_yes=true ;;
    -h|--help)
      cat <<'EOF'
Usage: ./uninstall.sh [--purge-docker] [--yes]

Without flags, removes HelioCanvas containers, images, networks, volumes,
telemetry, local AI models, generated builds, and the private .env file.

--purge-docker  Additionally removes ALL Docker containers, images, networks,
                volumes, Docker Engine packages, and Docker runtime data from
                this Linux server. This affects unrelated Docker applications.
--yes           Skip interactive confirmation. Intended for automation only.
EOF
      exit 0
      ;;
    *) echo "Unknown option: $argument" >&2; exit 2 ;;
  esac
done

if "$purge_docker"; then
  warning="DELETE-ALL-DOCKER-DATA"
  echo "WARNING: this will permanently delete every Docker workload on this server"
  echo "and uninstall Docker Engine, not only HelioCanvas. The Git checkout remains."
else
  warning="DELETE-HELIOCANVAS"
  echo "This will permanently delete HelioCanvas containers, images, telemetry,"
  echo "Ollama models, generated builds, and its private .env file."
fi

if ! "$assume_yes"; then
  read -r -p "Type $warning to continue: " answer
  if [[ "$answer" != "$warning" ]]; then
    echo "Cancelled. Nothing was removed."
    exit 1
  fi
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  docker compose \
    -f docker-compose.yml \
    -f docker-compose.local-ai.yml \
    down --volumes --remove-orphans --rmi all || true
fi

rm -f -- .env
rm -rf -- build .dart_tool backend/__pycache__

if ! "$purge_docker"; then
  echo "HelioCanvas runtime data was removed. The source checkout was preserved."
  exit 0
fi

if [[ "$(uname -s)" != "Linux" ]] || ! command -v apt-get >/dev/null 2>&1; then
  echo "Automatic Docker package removal supports Debian/Ubuntu Linux only." >&2
  exit 1
fi

sudo systemctl disable --now docker.service docker.socket containerd.service 2>/dev/null || true
sudo apt-get purge -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin \
  docker-compose-plugin docker-ce-rootless-extras docker.io containerd runc || true
sudo apt-get autoremove -y

for runtime_path in /var/lib/docker /var/lib/containerd /etc/docker; do
  if [[ -d "$runtime_path" ]]; then
    sudo rm -rf -- "$runtime_path"
  fi
done

sudo rm -f -- \
  /etc/apt/sources.list.d/docker.list \
  /etc/apt/sources.list.d/docker.sources \
  /etc/apt/keyrings/docker.asc

echo "All Docker runtime data and Docker Engine packages were removed."
echo "The HelioCanvas Git checkout was preserved so it can be updated with git pull."
