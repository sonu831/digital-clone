# AGENTS.md — operating manual for AI tools working in this repo

> This file is read automatically by many AI coding tools (Cursor, GitHub Copilot,
> Claude Code, Codex/Aider, Continue, etc.). Whichever model you are — Claude, GPT,
> DeepSeek, Llama — **read this before editing.** For a task-by-task continuation
> brief (what's left to build and how), see [docs/10-ai-handoff.md](docs/10-ai-handoff.md).

## What this project is

**Digital Clone** — a self-hosted, privacy-first AI automation agent.
Stack: **n8n** (orchestration) + **Ollama** (local LLM) + **PostgreSQL** (state) +
optional **Open WebUI**, wired by `docker-compose.yml`, configured by one `.env`.

## 🥇 The golden rule (do not break this)

> **Spokes know providers. The Hub knows only [contracts](contracts/).**

- A **spoke** (`n8n/workflows/spokes/<name>/`) is the *only* place a provider SDK,
  token, or API shape may appear (Slack, Discord, Alpaca, Notion…).
- The **Hub** (`n8n/workflows/hub/`) is provider-agnostic. It accepts an
  `inbound-event`, runs the AI Agent, and returns an `ai-output`. **Never** add
  provider-specific logic to the Hub.
- If a task tempts you to edit the Hub to support a provider, you're doing it wrong —
  write/extend a spoke instead.

## The two contracts (the system's API)

| File | Direction | Schema |
| ---- | --------- | ------ |
| [`contracts/inbound-event.schema.json`](contracts/inbound-event.schema.json) | Spoke → Hub | normalized input |
| [`contracts/ai-output.schema.json`](contracts/ai-output.schema.json) | Hub → Spoke | normalized output |

Any payload crossing the spoke↔hub boundary MUST validate against these.

## Repo map

```
.env.example              # ALL config/secrets template — single source of truth
docker-compose.yml        # the stack; optional services fenced with # >>> OPTIONAL
contracts/                # the decoupling JSON Schemas
db/init/01_schema.sql     # genesis schema: clone.activity_logs (event log)
n8n/workflows/hub/        # provider-agnostic AI core (spec in README; JSON TBD)
n8n/workflows/spokes/     # provider integrations (slack-inbound, cron-debrief, …)
docker/                   # optional custom images (n8n, ollama)
scripts/                  # bootstrap, pull-models, backup, healthcheck
docs/                     # human docs (01–09) + this handoff (10)
integrations/README.md    # registry of spokes
```

## Commands you may run

```bash
make bootstrap        # first-run: .env + secrets + up + pull models
make up | down | ps   # lifecycle (down keeps data)
make health           # probe services + list models
make logs s=n8n       # tail one service
make export-workflows # DB → n8n/workflows/*.json
make import-workflows # n8n/workflows/*.json → DB
docker compose config -q   # validate compose after edits
```

## Hard conventions (CI enforces several)

1. **Secrets:** every new secret is added to `.env.example` (empty/placeholder) and
   documented. Never hardcode secrets in compose, scripts, or workflow JSON.
2. **Never commit** `.env`, anything under `n8n/credentials/`, or data volumes.
3. **Compose:** new settings are `${VAR}`-driven from `.env`. Optional services keep
   the `# >>> OPTIONAL … <<<` fence so they're cleanly removable.
4. **Scripts:** POSIX `bash`, `set -euo pipefail`, idempotent.
5. **Inside containers** Ollama is `http://ollama:11434` — never `localhost`.
6. **AI is read-only:** the Hub's guardrails refuse trades/transfers/irreversible
   actions (path `deny`). Don't weaken them. Provision external keys read-only too.

## Definition of done for any change

- [ ] `docker compose config -q` passes; new JSON parses.
- [ ] The Hub is untouched unless the task is explicitly a contract change
      (`git diff -- n8n/workflows/hub` empty for spoke work).
- [ ] New secrets in `.env.example`; none hardcoded; nothing secret committed.
- [ ] Docs + `integrations/README.md` updated if behavior/integrations changed.
- [ ] Workflows exported via `make export-workflows` if you touched n8n.

## Inter-tool communication map (who talks to whom)

| From → To | Interface | Notes |
| --------- | --------- | ----- |
| Input spoke → Hub | n8n **Execute Workflow** node | passes `inbound-event` |
| Hub → Ollama | HTTP `http://ollama:11434` | model = `OLLAMA_ROUTER_MODEL` / `OLLAMA_ANALYST_MODEL` |
| Hub → Postgres | n8n Postgres node | writes `clone.activity_logs` |
| Hub → Output spoke | returns `ai-output` | spoke performs provider action |
| Human → Open WebUI → Ollama | browser | prompt/model testing only (optional) |
| Operator → stack | `make` / `docker compose` | lifecycle & ops |

Full picture: [docs/diagrams/architecture.md](docs/diagrams/architecture.md).
