#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# bootstrap.sh — zero-to-one setup for Digital Clone.
#   1. Creates .env from template if missing.
#   2. Generates strong secrets for the REQUIRED placeholder values.
#   3. Brings the stack up and warms the models.
# Idempotent: safe to re-run (won't overwrite an existing .env).
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/.."

ENV_FILE=".env"

gen() { openssl rand "$@"; }

if [[ -f "$ENV_FILE" ]]; then
  echo "✓ $ENV_FILE already exists — leaving it untouched."
else
  echo "→ Creating $ENV_FILE from .env.example with generated secrets..."
  cp .env.example "$ENV_FILE"

  DB_PASS="$(gen -base64 24)"
  UI_PASS="$(gen -base64 18)"
  ENC_KEY="$(gen -hex 32)"

  # Portable in-place sed (GNU + BSD/macOS).
  sedi() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

  sedi "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=${DB_PASS}|" "$ENV_FILE"
  sedi "s|^N8N_BASIC_AUTH_PASSWORD=.*|N8N_BASIC_AUTH_PASSWORD=${UI_PASS}|" "$ENV_FILE"
  sedi "s|^N8N_ENCRYPTION_KEY=.*|N8N_ENCRYPTION_KEY=${ENC_KEY}|" "$ENV_FILE"

  echo "✓ Generated DB password, n8n UI password, and encryption key into $ENV_FILE"
  echo "  n8n UI login → user: admin   password: ${UI_PASS}"
  echo "  (Review $ENV_FILE and fill in any spoke credentials you need.)"
fi

echo "→ Starting the stack (docker compose up -d)..."
docker compose up -d

echo "→ Warming models (this can take a while on first run)..."
./scripts/pull-models.sh || true

echo ""
echo "✅ Digital Clone is up."
echo "   n8n        : http://localhost:${N8N_PORT:-5678}"
echo "   Open WebUI : http://localhost:${OPEN_WEBUI_PORT:-8080}  (if enabled)"
echo "   Ollama API : http://localhost:${OLLAMA_PORT:-11434}"
