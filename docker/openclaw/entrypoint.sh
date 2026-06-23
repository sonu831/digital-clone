#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# OpenClaw entrypoint — first-run setup, reconcile config, start the gateway.
#
# Commands verified against openclaw 2026.6.9:
#   setup --non-interactive --accept-risk --mode local   → baseline config+workspace
#   config patch --stdin                                  → one validated JSON5 write
#   gateway run --force --bind lan --port <n>             → run the WS gateway (foreground)
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail

GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
OLLAMA_URL="${OLLAMA_BASE_URL:-http://ollama:11434}"
MODEL="${OPENCLAW_MODEL:-ollama/llama3:8b}"
CONFIG_FILE="${HOME}/.openclaw/openclaw.json"

# ── First run: create baseline config + agent workspace (non-interactive) ─────
if [ ! -f "${CONFIG_FILE}" ]; then
  echo ">> OpenClaw first run: setup --non-interactive (local mode)"
  # setup writes config + workspace + sessions within a few seconds, then blocks
  # ~15s probing for a gateway that isn't up yet (we start it below). Background
  # it, wait for its files to land, then stop that pointless wait so the gateway
  # starts promptly (~7s instead of ~21s on first boot).
  openclaw setup --non-interactive --accept-risk --mode local >/tmp/oc-setup.log 2>&1 &
  SETUP_PID=$!
  for _ in $(seq 1 30); do
    [ -f "${CONFIG_FILE}" ] && [ -d "${HOME}/.openclaw/agents/main/sessions" ] && break
    sleep 1
  done
  kill "${SETUP_PID}" >/dev/null 2>&1 || true
  wait "${SETUP_PID}" 2>/dev/null || true
  grep -iE "config|workspace|sessions" /tmp/oc-setup.log 2>/dev/null | sed 's/^/   setup: /' | head -5 || true
fi

# ── Reconcile runtime settings every boot (idempotent, validated write) ───────
#    - point the default model provider at our shared Ollama instance
#    - bind the gateway to the LAN so the host-published port is reachable
#      (setup defaults to bind:"loopback", which is NOT reachable from outside
#      the container)
echo ">> Reconciling config — Ollama=${OLLAMA_URL}, model=${MODEL}, port=${GATEWAY_PORT}"
openclaw config patch --stdin <<EOF
{
  models: {
    providers: {
      ollama: {
        api: "ollama",
        baseUrl: "${OLLAMA_URL}",
      },
    },
  },
  agents: { defaults: { model: { primary: "${MODEL}" } } },
  gateway: { bind: "lan", port: ${GATEWAY_PORT} },
}
EOF

openclaw config validate || echo ">> WARN: 'config validate' reported issues (continuing)"

echo ">> Starting OpenClaw gateway on 0.0.0.0:${GATEWAY_PORT} (SIGTERM to stop)"
exec openclaw gateway run --force --bind lan --port "${GATEWAY_PORT}"
