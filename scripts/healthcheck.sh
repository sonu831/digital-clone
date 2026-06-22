#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# healthcheck.sh — quick status of all services + model availability.
# ──────────────────────────────────────────────────────────────────────────────
set -uo pipefail
cd "$(dirname "$0")/.."

echo "=== Container status ==="
docker compose ps

echo ""
echo "=== Service probes ==="
probe() { printf "  %-12s " "$1:"; shift; if "$@" >/dev/null 2>&1; then echo "OK"; else echo "DOWN"; fi; }

OLLAMA_PORT="$(grep -E '^OLLAMA_PORT=' .env 2>/dev/null | cut -d= -f2- || echo 11434)"
N8N_PORT="$(grep -E '^N8N_PORT=' .env 2>/dev/null | cut -d= -f2- || echo 5678)"

probe "ollama"  curl -fsS "http://localhost:${OLLAMA_PORT}/api/tags"
probe "n8n"     curl -fsS "http://localhost:${N8N_PORT}/healthz"

echo ""
echo "=== Installed models ==="
docker exec "${COMPOSE_PROJECT_NAME:-digital-clone}-ollama" ollama list 2>/dev/null || echo "  (ollama not reachable)"
