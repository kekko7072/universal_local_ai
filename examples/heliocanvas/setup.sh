#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

use_local_ai=true

for argument in "$@"; do
  case "$argument" in
    --no-local-ai) use_local_ai=false ;;
    --with-local-ai) use_local_ai=true ;;
    -h|--help)
      cat <<'EOF'
Usage: ./setup.sh [--no-local-ai | --with-local-ai]

By default, HelioCanvas starts a private Ollama container and installs the
configured local model. Use --no-local-ai to run only the telemetry dashboard;
the Design UI feature will use its deterministic offline fallback.
EOF
      exit 0
      ;;
    *) echo "Unknown option: $argument" >&2; exit 2 ;;
  esac
done

if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo "Docker Engine and Docker Compose v2 are required." >&2
  echo "Install them from https://docs.docker.com/engine/install/ and run this script again." >&2
  exit 1
fi

if [[ ! -f .env ]]; then
  cp .env.example .env
  detected_ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  if [[ -n "$detected_ip" ]]; then
    sed -i.bak "s/^SERVER_IP=.*/SERVER_IP=$detected_ip/" .env
    rm -f .env.bak
  fi
  echo "Created private local configuration: .env"
fi

if "$use_local_ai"; then
  model="$(sed -n 's/^OLLAMA_MODEL=//p' .env | tail -n 1)"
  model="${model:-gemma3:1b}"
  compose=(docker compose -f docker-compose.yml -f docker-compose.local-ai.yml)

  echo "Starting the local telemetry and Local AI services..."
  "${compose[@]}" up -d --build ollama mosquitto
  echo "Installing the local AI model ($model). This is downloaded once..."
  "${compose[@]}" exec -T ollama ollama pull "$model"
  "${compose[@]}" up -d --build
else
  compose=(docker compose -f docker-compose.yml)
  echo "Starting HelioCanvas without Local AI..."
  "${compose[@]}" up -d --build --remove-orphans
fi

port="$(sed -n 's/^DASHBOARD_PORT=//p' .env | tail -n 1)"
grott_port="$(sed -n 's/^GROTT_PORT=//p' .env | tail -n 1)"
server_ip="$(sed -n 's/^SERVER_IP=//p' .env | tail -n 1)"
port="${port:-8080}"
grott_port="${grott_port:-5279}"
server_ip="${server_ip:-localhost}"

echo
echo "HelioCanvas is ready at http://$server_ip:$port"
if "$use_local_ai"; then
  echo "Local AI is enabled with model: $model"
else
  echo "Local AI is disabled; Design UI will use the offline fallback."
fi
echo "Run ./verify-live.sh after pointing the logger at $server_ip:$grott_port."
echo "Your .env and telemetry database stay local and are not committed to Git."
