#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
port="$(sed -n 's/^DASHBOARD_PORT=//p' .env 2>/dev/null | tail -n 1)"
port="${port:-8080}"
base="http://localhost:$port"

echo "Service diagnostics:"
curl -fsS "$base/api/health"
echo
echo
echo "Latest telemetry:"
curl -fsS "$base/api/status"
echo
echo
echo "For packet-level verification, run:"
echo "  docker compose exec mosquitto mosquitto_sub -t 'energy/growatt/#' -C 1 -v"
