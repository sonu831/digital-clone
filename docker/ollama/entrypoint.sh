#!/bin/sh
# ──────────────────────────────────────────────────────────────────────────────
# Ollama entrypoint used by the OPT-IN custom image (docker/ollama/Dockerfile).
#
# Starts the Ollama server, then pulls any runtime models listed in the
# OLLAMA_MODELS env var (comma-separated) that are not already present.
# This makes the container self-warming without the separate ollama-init sidecar.
# ──────────────────────────────────────────────────────────────────────────────
set -eu

# Launch the server in the background.
ollama "$@" &
SERVER_PID=$!

# Wait for the API to answer before issuing pulls.
echo "[entrypoint] waiting for Ollama API..."
until ollama list >/dev/null 2>&1; do
  sleep 1
done

# Pull runtime models if requested.
if [ -n "${OLLAMA_MODELS:-}" ]; then
  OLD_IFS=$IFS
  IFS=','
  for model in $OLLAMA_MODELS; do
    model=$(echo "$model" | tr -d ' ')
    [ -z "$model" ] && continue
    echo "[entrypoint] ensuring model: $model"
    ollama pull "$model" || echo "[entrypoint] WARN: pull failed for $model"
  done
  IFS=$OLD_IFS
fi

echo "[entrypoint] ready. Tailing Ollama server (pid $SERVER_PID)."
wait "$SERVER_PID"
