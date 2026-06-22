# 02 · Quickstart

From clone to a running Digital Clone in ~10 minutes (plus model download time).

## Prerequisites

- **Docker** 24+ and the **Docker Compose v2** plugin (`docker compose`, not `docker-compose`).
- **openssl** (for secret generation; preinstalled on macOS/Linux, available in Git Bash on Windows).
- Disk: ~10 GB for the two default 8B models. RAM: 16 GB recommended for CPU inference.
- *(Optional)* NVIDIA GPU + [Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) for acceleration.

## One-command setup

```bash
git clone https://github.com/sonu831/digital-clone.git
cd digital-clone
make bootstrap
```

`make bootstrap` will:
1. create `.env` from `.env.example`,
2. generate a strong DB password, n8n UI password, and encryption key,
3. `docker compose up -d`,
4. pull the models in `OLLAMA_MODELS`.

It prints your generated n8n UI login at the end. **Save it.**

## Manual setup (if you prefer)

```bash
cp .env.example .env
# Generate + paste these into .env:
openssl rand -base64 24   # → POSTGRES_PASSWORD
openssl rand -base64 18   # → N8N_BASIC_AUTH_PASSWORD
openssl rand -hex 32      # → N8N_ENCRYPTION_KEY

docker compose up -d
make pull-models          # or: docker exec digital-clone-ollama ollama pull llama3:8b
```

## Verify

```bash
make health
```

You should see all containers `Up`/`healthy` and your models listed. Then open:

- **n8n**: <http://localhost:5678> (log in with the printed credentials)
- **Open WebUI**: <http://localhost:8080> (if `ENABLE_OPEN_WEBUI=true`)

## Load the workflows

```bash
make import-workflows     # imports anything in n8n/workflows/
```

Then, in n8n, add your provider credentials (Slack token, broker keys) to the
relevant nodes and **activate** the workflows.

## Next steps

- Tune everything in [03 · Configuration](03-configuration.md).
- Understand the flow in [04 · Workflow Design](04-workflow-design.md).
- Plug in your own provider in [05 · Adding a Spoke](05-adding-a-spoke.md).
- **Before exposing to the internet:** read [07 · Security](07-security.md).

## Teardown

```bash
make down     # stop, keep data
make nuke     # stop and DELETE all data volumes (irreversible)
```
