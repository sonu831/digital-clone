# ──────────────────────────────────────────────────────────────────────────────
# Custom Ollama image (OPT-IN).
#
# The default stack uses upstream `ollama/ollama:latest` plus the `ollama-init`
# sidecar to pull models. Build THIS image only if you want models baked into
# the image layer (heavier image, faster cold start, fully offline deploys).
#
# Activate by setting in docker-compose.yml:
#   ollama:
#     build:
#       context: ./docker/ollama
#       args:
#         BAKE_MODELS: "llama3:8b deepseek-r1:8b"
# ──────────────────────────────────────────────────────────────────────────────
FROM ollama/ollama:latest

# Space-separated list of models to bake into the image at build time.
ARG BAKE_MODELS=""

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Pre-pull models into the image layer (optional; skipped if BAKE_MODELS empty).
RUN if [ -n "$BAKE_MODELS" ]; then \
      ollama serve & \
      pid=$!; \
      sleep 5; \
      for m in $BAKE_MODELS; do echo "Baking $m"; ollama pull "$m"; done; \
      kill $pid; \
    fi

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["serve"]
