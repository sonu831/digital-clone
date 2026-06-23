# ──────────────────────────────────────────────────────────────────────────────
# OpenClaw — optional personal AI assistant (shared Ollama)
#
# Runs alongside Digital Clone, using the SAME Ollama instance for inference.
# Provides WhatsApp, Telegram, Discord, and iMessage interfaces that
# complement n8n's Slack + debrief pipelines.
#
# OpenClaw runs 100% local when configured with Ollama — no cloud API needed.
# ──────────────────────────────────────────────────────────────────────────────
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine

# Install system deps for native modules and health checks
RUN apk add --no-cache curl bash

# Install OpenClaw globally
RUN npm install -g openclaw

# Non-root user. Pre-create + own the state dir BEFORE declaring it as a mount
# point: a named/anonymous volume inherits the ownership of the underlying image
# directory on first init, so this is what lets the non-root user write to
# ~/.openclaw/state (otherwise: EACCES mkdir '/home/openclaw/.openclaw/state').
RUN adduser -D -h /home/openclaw openclaw \
 && mkdir -p /home/openclaw/.openclaw \
 && chown -R openclaw:openclaw /home/openclaw

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER openclaw
WORKDIR /home/openclaw

# Gateway WebSocket + companion app port (actual value comes from config at runtime)
EXPOSE 18789

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
