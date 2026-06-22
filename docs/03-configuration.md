# 03 · Configuration

All configuration lives in **one file: `.env`** (copied from `.env.example`).
`docker-compose.yml` reads only from it — no secret is ever hardcoded.

## Sections of `.env`

| Section            | Keys                                  | Notes                                              |
| ------------------ | ------------------------------------- | -------------------------------------------------- |
| Global             | `COMPOSE_PROJECT_NAME`, `TZ`, `GENERIC_TIMEZONE` | TZ drives cron timing.                  |
| Toggles            | `ENABLE_OPEN_WEBUI`, `ENABLE_GPU`     | Documentation flags; see below.                    |
| Ports              | `*_PORT`                              | Host-side; change on conflicts.                    |
| Postgres           | `POSTGRES_*`                          | `POSTGRES_PASSWORD` is **required**.               |
| n8n                | `N8N_*`, `WEBHOOK_URL`                | `N8N_ENCRYPTION_KEY` is **required & immutable**.  |
| Ollama             | `OLLAMA_*`                            | Model list + router/analyst selection.             |
| Spokes             | `SLACK_*`, `DISCORD_*`, `BROKER_*`    | Optional; fill only what you use.                  |

## Required values (the stack refuses to start without them)

`docker-compose.yml` uses `${VAR:?message}` for these, so a missing value fails fast:

- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `N8N_ENCRYPTION_KEY`
- `N8N_BASIC_AUTH_PASSWORD`

Generate them:

```bash
openssl rand -base64 24   # passwords
openssl rand -hex 32      # N8N_ENCRYPTION_KEY (NEVER change after first run)
```

> 🔐 **`N8N_ENCRYPTION_KEY` is permanent.** It encrypts every credential n8n stores.
> Change it and all saved credentials become unreadable.

## Toggling optional services

`ENABLE_OPEN_WEBUI` / `ENABLE_GPU` are **documentation/scripting flags** — they tell
*you* and the helper scripts what you intend. Docker Compose doesn't conditionally
skip services from an env var, so to actually change the runtime:

- **Remove Open WebUI:** comment out the `# >>> OPTIONAL: OPEN WEBUI … <<<` block in
  `docker-compose.yml`.
- **Skip model auto-pull:** comment out the `# >>> OPTIONAL: ollama-init … <<<` block.

## Enabling GPU

1. Install NVIDIA drivers + the NVIDIA Container Toolkit on the host.
2. In `docker-compose.yml`, uncomment the `# >>> OPTIONAL: GPU ACCELERATION` block
   under the `ollama` service.
3. Set `ENABLE_GPU=true` in `.env` (signals intent; the `deploy` block does the work).
4. `docker compose up -d` and confirm with `nvidia-smi` inside the container:
   `docker exec digital-clone-ollama nvidia-smi`.

## Ports & reverse proxies

For local use the defaults are fine. To put n8n behind HTTPS (Caddy/Traefik/nginx):

- set `N8N_PROTOCOL=https`, `N8N_HOST=clone.example.com`, `WEBHOOK_URL=https://clone.example.com/`,
- set `N8N_SECURE_COOKIE=true`,
- in production, **remove the host port mapping for Postgres** so the DB is only
  reachable inside the Docker network.

More hardening in [07 · Security](07-security.md).
