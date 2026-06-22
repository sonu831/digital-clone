# ──────────────────────────────────────────────────────────────────────────────
# Custom n8n image (OPT-IN).
#
# The default stack uses the upstream `docker.n8n.io/n8nio/n8n:latest` image.
# Use THIS image only when you need extra capabilities, e.g.:
#   - system libraries for PDF/chart rendering in the cron debrief,
#   - additional community nodes baked in,
#   - extra CLI tools available to the n8n "Execute Command" node.
#
# To activate: in docker-compose.yml comment out the n8n `image:` line and
# uncomment the `build:` block pointing at ./docker/n8n.
# ──────────────────────────────────────────────────────────────────────────────
ARG N8N_VERSION=latest
FROM docker.n8n.io/n8nio/n8n:${N8N_VERSION}

# Drop to root to install system packages, then return to the non-root `node` user.
USER root

# Example extras: fonts + tini for clean signal handling. Trim to what you need.
RUN apk add --no-cache \
      tini \
      font-noto \
      ca-certificates

# --- Add community nodes here (uncomment + list) ------------------------------
# ENV N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
# RUN cd /usr/local/lib/node_modules/n8n && npm install n8n-nodes-<package>

# Never run n8n as root.
USER node
