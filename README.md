<div align="center">

# 🧠 Digital Clone

**A self-hosted, privacy-first AI automation agent you actually own.**

Fork it. Plug in *your* tools. Run it on *your* hardware. Your data never leaves the box.

[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Local-first](https://img.shields.io/badge/inference-100%25_local-success)](docs/06-models.md)
[![Built with](https://img.shields.io/badge/stack-n8n_·_Ollama_·_Postgres-orange)](docs/01-architecture.md)

[Quickstart](#-quickstart) · [Architecture](docs/01-architecture.md) · [Add an integration](docs/05-adding-a-spoke.md) · [Docs](docs/)

</div>

---

## What is this?

**Digital Clone** is a Docker-Compose stack that runs a local AI "chief of staff":
it listens to your channels, reasons with a **local LLM**, logs everything, and acts —
all on infrastructure you control. No cloud LLM, no data egress, no per-token bill.

It ships configured for **Slack + a read-only trading debrief**, but the architecture is
**deliberately decoupled**: swap Slack for Discord, Alpaca for Binance, Postgres-logging
for Notion — **without editing the AI core.** That's the whole design.

### Why you'd want it

- 🔒 **Private by construction** — inference runs on **Ollama** locally. Your messages and
  P&L never touch a third-party model.
- 🧩 **Forkable, not forked-up** — a strict **Hub-and-Spoke** contract means integrations
  are plug-ins, not surgery.
- 🐳 **One command up** — `make bootstrap` generates secrets and brings up the whole stack.
- 🛡️ **Safe by default** — the AI is **read-only**; guardrails refuse trades/transfers.
- 🦾 **Yours** — GPLv3, no telemetry, runs on a laptop or a $5 VPS (CPU) or a GPU box.

## The stack

| Component      | Role                                   | Default            |
| -------------- | -------------------------------------- | ------------------ |
| **n8n**        | Orchestration — triggers, the Hub, spokes | `latest`        |
| **Ollama**     | Local LLM inference ("the brain")      | Llama 3 + DeepSeek-R1 |
| **PostgreSQL** | n8n state + your event log             | `16-alpine`        |
| **Open WebUI** | Optional model playground              | `main` (toggleable) |

## The idea in one diagram

```
provider event ─► [ INPUT SPOKE ] ──inbound-event──► [ HUB → Ollama ] ──ai-output──► [ OUTPUT SPOKE ] ─► action
   (Slack,          normalize          (contract)      provider-agnostic   (contract)    deliver         (reply,
    Discord,                                            AI core +                                          write,
    broker)                                             guardrails)                                        debrief)
                                              │
                                              └──► PostgreSQL  (clone.activity_logs — audit trail)
```

> **Spokes know providers. The Hub knows only [contracts](contracts/).**
> Replace any spoke; the brain never changes. Full write-up:
> [docs/04-workflow-design.md](docs/04-workflow-design.md).

## System requirements

- **Docker 24+** with the **Compose v2** plugin, and **openssl**.
- **CPU-only:** 4+ vCPU, **16 GB RAM**, ~10 GB disk (for two 8B models).
- **GPU (optional):** NVIDIA GPU + [Container Toolkit](docs/03-configuration.md#enabling-gpu) for a big speedup.
- Works on Linux, macOS, and Windows (via WSL2 / Git Bash).

## 🚀 Quickstart

```bash
git clone https://github.com/sonu831/digital-clone.git
cd digital-clone
make bootstrap        # creates .env, generates secrets, starts the stack, pulls models
```

When it finishes it prints your **n8n login**. Then:

```bash
make health           # confirm all services are up + models installed
make import-workflows # load the bundled workflows into n8n
```

Open **n8n** at <http://localhost:5678>, add your provider credentials, activate the
workflows. Optional model playground (**Open WebUI**) at <http://localhost:8080>.

Prefer manual steps or hit a snag? → [Quickstart](docs/02-quickstart.md) ·
[Troubleshooting](docs/08-troubleshooting.md).

### Handy commands

```bash
make up / down        # start / stop (down keeps your data)
make logs s=n8n       # tail one service
make pull-models      # (re)pull models listed in OLLAMA_MODELS
make backup           # pg_dump to ./backups
make help             # list everything
```

## Make it yours

| I want to…                          | Do this                                                        |
| ----------------------------------- | -------------------------------------------------------------- |
| Use Discord instead of Slack        | Add an input spoke → [docs/05-adding-a-spoke.md](docs/05-adding-a-spoke.md) |
| Swap the LLM                        | Edit `OLLAMA_*` in `.env` → [docs/06-models.md](docs/06-models.md) |
| Drop Open WebUI                     | Comment out its block in `docker-compose.yml`                  |
| Run on a GPU                        | [docs/03-configuration.md#enabling-gpu](docs/03-configuration.md) |
| Change the AI's behavior            | Edit the Hub system prompt → [docs/04-workflow-design.md](docs/04-workflow-design.md) |
| Log to Notion instead of Postgres   | Add an output spoke → [docs/05-adding-a-spoke.md](docs/05-adding-a-spoke.md) |

## Documentation

Full docs live in [`/docs`](docs/). Highlights: [Architecture](docs/01-architecture.md) ·
[Configuration](docs/03-configuration.md) · [Security](docs/07-security.md) ·
[Backup & Restore](docs/09-backup-restore.md).

**Building with AI tools?** [`AGENTS.md`](AGENTS.md) is the operating manual that
Copilot/Cursor/Claude/Aider auto-read, and [docs/10-ai-handoff.md](docs/10-ai-handoff.md)
is a "do the rest" brief that lets another model (e.g. DeepSeek) continue the build via
the contracts — without touching the AI core.

## Contributing

PRs welcome — especially **new spokes**. The rule: integrate via the
[contracts](contracts/), never by editing the Hub. Start at
[CONTRIBUTING.md](CONTRIBUTING.md) and the
[integrations registry](integrations/README.md).

## Security

Local-first, read-only AI, secrets in a git-ignored `.env`. Please review
[docs/07-security.md](docs/07-security.md) before exposing anything to the internet, and
report vulnerabilities privately per [SECURITY.md](SECURITY.md).

## License

[GPLv3](LICENSE). Use it, fork it, improve it — keep it open.

---

<div align="center">
<sub>Built for people who want an AI assistant they <b>own</b>, not one they rent.</sub>
</div>
