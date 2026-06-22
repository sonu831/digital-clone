# 08 · Troubleshooting

Start with the firehose:

```bash
make ps                 # what's up / healthy
make health             # service probes + installed models
make logs s=n8n         # tail one service (n8n | postgres | ollama | open-webui)
```

## Common issues

### A service won't start: `error while interpolating ... required variable`
A required `.env` value is missing. Compose uses `${VAR:?...}` for required keys.
Fix: ensure `POSTGRES_PASSWORD`, `N8N_ENCRYPTION_KEY`, `N8N_BASIC_AUTH_PASSWORD` are set.

### `port is already allocated`
Another process owns the port. Change the matching `*_PORT` in `.env` and `up` again.

### n8n: "There was an error initializing... encryption key"
`N8N_ENCRYPTION_KEY` changed between runs. Restore the original key, or wipe n8n state
(`make nuke` — **destroys data**) to start fresh.

### Ollama calls from n8n fail / connection refused
Inside containers, Ollama is `http://ollama:11434` — **not** `http://localhost:11434`.
Check the Base URL in your Ollama nodes.

### Model not found / 404 on inference
The model isn't pulled yet. `make pull-models`, then `docker exec digital-clone-ollama
ollama list` to confirm. First pulls of 8B models take several minutes.

### Inference is extremely slow
You're on CPU. That's expected for 8B models. Options: enable GPU
([03 · Configuration](03-configuration.md)), use a smaller/more-quantized model
([06 · Models](06-models.md)), or raise `OLLAMA_KEEP_ALIVE` to avoid reloads.

### DB init script changes aren't applied
`db/init/*.sql` runs **only** on a fresh (empty) Postgres volume. After the first boot
it's ignored. Use a migration in `db/migrations/` + `make migrate`, or `make nuke` to
re-init from scratch (**destroys data**).

### Webhooks never arrive
`WEBHOOK_URL` must be reachable by the provider. `localhost` won't work for a cloud
provider calling in — expose via a tunnel (ngrok/cloudflared) or a public domain, and
set `WEBHOOK_URL` accordingly.

### Open WebUI shows "healthy: false" but everything else works
It's optional and slower to come up. Give it `start_period`, or disable it if unused
(comment out the block in `docker-compose.yml`).

### GPU not detected
Confirm host has NVIDIA Container Toolkit, the GPU `deploy` block is uncommented, and
`docker exec digital-clone-ollama nvidia-smi` lists your GPU.

## Still stuck?

Open an issue with `make ps`, the relevant `make logs` output, your OS, and whether
you're CPU or GPU. Redact secrets.
