#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# pull-models.sh — pull the models listed in OLLAMA_MODELS into the running
# ollama container. Reads OLLAMA_MODELS from .env (comma-separated).
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/.."

# Load OLLAMA_MODELS from .env without leaking the rest into the shell.
MODELS="$(grep -E '^OLLAMA_MODELS=' .env 2>/dev/null | cut -d= -f2- || true)"
MODELS="${MODELS:-llama3:8b,deepseek-r1:8b}"

CONTAINER="${COMPOSE_PROJECT_NAME:-digital-clone}-ollama"

echo "→ Pulling models into ${CONTAINER}: ${MODELS}"
IFS=',' read -ra LIST <<< "$MODELS"
for m in "${LIST[@]}"; do
  m="$(echo "$m" | xargs)"   # trim whitespace
  [[ -z "$m" ]] && continue
  echo ">> ollama pull $m"
  docker exec "$CONTAINER" ollama pull "$m"
done
echo "✓ Models ready."
