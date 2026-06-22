<div align="center">

# 🧠 Digital Clone

**A self-hosted, privacy-first AI automation agent you actually own.**

Fork it. Plug in *your* tools. Run it on *your* hardware. Your data never leaves the box.

[![License: GPLv3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Local-first](https://img.shields.io/badge/inference-100%25_local-success)](docs/06-models.md)
[![Built with](https://img.shields.io/badge/stack-n8n_·_Ollama_·_Postgres-orange)](docs/01-architecture.md)

[Quickstart](#-quickstart) · [What it can do](#-what-it-can-do) · [Architecture](docs/01-architecture.md) · [Add an integration](docs/05-adding-a-spoke.md) · [Docs](docs/)

</div>

---

## What is this?

**Digital Clone** is a Docker-Compose stack that runs a local AI "chief of staff":
it listens to your channels, reasons with a **local LLM**, logs everything, and acts —
all on infrastructure you control. No cloud LLM, no data egress, no per-token bill.

It ships configured for **Slack + a read-only trading debrief**, but the architecture is
**deliberately decoupled**: swap Slack for Discord, Alpaca for Binance, Postgres-logging
for Notion — **without editing the AI core.** That's the whole design.

## 🧠 What it can do

Here's what ships out of the box, and what you can add:

### Built-in capabilities

| Capability | What happens | Which workflow |
| --- | --- | --- |
| **AI chat in Slack** | Mention the bot; it classifies your message, drafts a reply (or tasks, fetches data, or refuses unsafe requests), and posts back — all within seconds | `slack-inbound` → `ai-hub` |
| **Daily executive debrief** | Every evening at 18:00 your time, it pulls the day's activity log + a read-only broker snapshot, sends both to the analyst model, and posts a structured summary to your Slack debrief channel | `cron-debrief` → `ai-hub` |
| **Conversation memory** | The Hub keeps a rolling 10-message window per conversation (keyed by `correlation_id`), so follow-up questions work naturally | `ai-hub` Window Buffer Memory |
| **Full audit trail** | Every inbound message, every AI decision, and every action taken is logged to `clone.activity_logs` in PostgreSQL — queryable, indexable, yours | `ai-hub` Postgres node |
| **Read-only safety** | The AI's system prompt is **hardcoded to refuse** any trade, transfer, purchase, or irreversible action. If you ask it to buy stock, it replies "Operational bounds exceeded. Transaction denied." — no config needed | `ai-hub` system prompt |
| **Two-model intelligence** | Quick messages get routed to a fast model (Llama 3); financial data snapshots get routed to a deep-reasoning model (DeepSeek-R1). Both are local | `ai-hub` model switch |
| **Model playground** | Optional Open WebUI at `:8080` — a ChatGPT-style interface to test prompts, compare models, and prototype before wiring live | `open-webui` (optional) |

### Extend it (without touching the AI core)

| You want… | You build… | Using… |
| --- | --- | --- |
| Discord / Telegram / WhatsApp | A new input spoke | [docs/05-adding-a-spoke.md](docs/05-adding-a-spoke.md) |
| Notion / Google Docs logging | A new output spoke | Same guide |
| Binance / Interactive Brokers data | A new data spoke | Same guide |
| Different AI model | Edit `.env` | [docs/06-models.md](docs/06-models.md) |
| Custom guardrails / personality | Edit the system prompt in the Hub | [docs/04-workflow-design.md](docs/04-workflow-design.md) |

The golden rule: **spokes know providers; the Hub knows only JSON contracts.** You never
edit the Hub to add an integration — you write a spoke that speaks the contract.

## The stack

| Component      | Role                                   | Default            |
| -------------- | -------------------------------------- | ------------------ |
| **n8n**        | Orchestration — triggers, the Hub, spokes | `latest`        |
| **Ollama**     | Local LLM inference ("the brain")      | Llama 3 + DeepSeek-R1 |
| **PostgreSQL** | n8n state + your event log             | `16-alpine`        |
| **Open WebUI** | Optional model playground              | `main` (toggleable) |

## Architecture

```mermaid
graph TD
    %% ── External triggers ──────────────────────────────────────────────
    User[👤 User in Slack]:::user -->|"@bot message"| SlackEvt

    %% ── Docker network ─────────────────────────────────────────────────
    subgraph Host["🖥️ Self-Hosted — your hardware"]
        direction TB

        subgraph n8nLayer["n8n (orchestration)"]
            InSpoke["📥 slack-inbound spoke<br/><i>normalize → inbound-event</i>"]:::spoke
            Hub["🧠 ai-hub<br/><i>AI core · guardrails · router</i>"]:::hub
            OutSpoke["📤 slack-inbound spoke<br/><i>ai-output → post reply</i>"]:::spoke
            Cron["⏰ cron-debrief spoke<br/><i>schedule → snapshot → debrief</i>"]:::spoke
        end

        Ollama[("🤖 Ollama<br/>llama3:8b · deepseek-r1:8b")]:::brain
        DB[("🗄️ PostgreSQL<br/>clone.activity_logs")]:::db
        WebUI["🖥️ Open WebUI<br/><i>optional playground</i>"]:::opt
    end

    %% ── Edges ──────────────────────────────────────────────────────────
    User --> SlackEvt["Slack Events API"]
    SlackEvt -->|"webhook"| InSpoke
    InSpoke ==>|"inbound-event<br/>(JSON contract)"| Hub
    Cron -->|"query today"| DB
    Cron ==>|"inbound-event<br/>(JSON contract)"| Hub
    Hub <-->|"HTTP :11434"| Ollama
    Hub -->|"INSERT"| DB
    Hub ==>|"ai-output<br/>(JSON contract)"| OutSpoke
    Hub ==>|"ai-output<br/>(JSON contract)"| Cron
    OutSpoke -->|"post reply"| SlackEvt
    SlackEvt --> User
    Cron -->|"post debrief"| DebriefCh["📢 #executive-debriefs"]
    WebUI -.->|"manage"| Ollama

    %% ── Styles ─────────────────────────────────────────────────────────
    classDef user fill:#fce4ec,stroke:#c62828,color:#b71c1c,stroke-width:2px;
    classDef spoke fill:#e3f2fd,stroke:#1976d2,color:#0d47a1;
    classDef hub fill:#fff3e0,stroke:#e65100,stroke-width:4px,color:#3e2723,font-weight:bold;
    classDef brain fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20,stroke-width:2px;
    classDef db fill:#e1f5fe,stroke:#0288d1,color:#01579b,stroke-width:2px;
    classDef opt fill:#f3e5f5,stroke:#8e24aa,color:#4a148c,stroke-dasharray:5 5;
```

> **How to read this:** the bold `==>` edges are the two contract boundaries —
> everything left of `inbound-event` and right of `ai-output` is swappable without
> ever touching the Hub. The Hub talks only to Ollama and Postgres. See
> [docs/diagrams/architecture.md](docs/diagrams/architecture.md) for the layered view.

### Message flow (sequence)

```mermaid
sequenceDiagram
    actor U as 👤 User
    participant S as Slack
    participant IS as 📥 slack-inbound<br/>(spoke)
    participant H as 🧠 ai-hub<br/>(Hub)
    participant O as 🤖 Ollama
    participant D as 🗄️ Postgres
    participant OS as 📤 slack-inbound<br/>(spoke)

    U->>S: "@bot summary"
    S->>IS: webhook event
    IS->>IS: filter bots · map to inbound-event
    IS->>H: Execute Workflow(inbound-event)
    H->>H: validate · select model
    H->>O: chat(system prompt + user text)
    O-->>H: ai-output JSON
    H->>D: INSERT activity_logs
    H-->>IS: ai-output
    IS->>OS: route by path
    OS->>S: post reply
    S-->>U: "Here's your summary..."
```

### Daily debrief flow (scheduled)

```mermaid
sequenceDiagram
    participant CR as ⏰ cron-debrief<br/>(spoke)
    participant D as 🗄️ Postgres
    participant BR as 📊 Broker API
    participant H as 🧠 ai-hub<br/>(Hub)
    participant O as 🤖 Ollama
    participant SL as 📢 Slack

    Note over CR: 18:00 daily
    CR->>D: SELECT clone.v_today
    D-->>CR: today's activity rows
    CR->>BR: GET /account (read-only)
    BR-->>CR: portfolio snapshot
    CR->>CR: merge → data_snapshot event
    CR->>H: Execute Workflow(inbound-event)
    H->>O: chat(system prompt + snapshot data)
    O-->>H: ai-output JSON (analyst model)
    H->>D: INSERT activity_logs
    H-->>CR: ai-output
    CR->>SL: post debrief
    SL-->>CR: ✓ posted
```

Detailed walkthrough of what happens when you type `@bot summary` in Slack:

1. Slack sends the event to your n8n webhook URL
2. **slack-inbound** spoke picks it up, filters out bots/self-messages, maps the Slack payload into a normalized `inbound-event` JSON (with a `correlation_id` tying the whole lifecycle together)
3. The spoke calls the **ai-hub** workflow via n8n's Execute Workflow node
4. The Hub validates the payload, selects the model (Llama 3 for messages, DeepSeek for data), feeds it to the AI Agent with the guardrailed system prompt
5. The model returns an `ai-output` JSON: which path to take (`alpha`/`beta`/`gamma`/`deny`), what to reply, and any actions
6. The Hub logs everything to `clone.activity_logs` and returns the `ai-output` to the spoke
7. The spoke switches on the path: posts the reply to Slack (`alpha`/`gamma`), acknowledges a task (`beta`), or posts a denial message (`deny`)

**The two contracts** that make this decoupling work:

| File | Direction | What it guarantees |
| --- | --- | --- |
| [`contracts/inbound-event.schema.json`](contracts/inbound-event.schema.json) | Spoke → Hub | Every event has a UUID, source, type, timestamp, and optional actor/channel/text/data |
| [`contracts/ai-output.schema.json`](contracts/ai-output.schema.json) | Hub → Spoke | Every decision has a path (alpha/beta/gamma/deny), a summary, optional reply and actions |

Full architecture doc: [docs/04-workflow-design.md](docs/04-workflow-design.md).

## System requirements

- **Docker 24+** with the **Compose v2** plugin, and **openssl**.
- **CPU-only:** 4+ vCPU, **16 GB RAM**, ~10 GB disk (for two 8B models).
  - On Windows: WSL2 with Docker Desktop, or a Linux VM. Git Bash for `make`.
  - On macOS: Docker Desktop. If on Apple Silicon, models will run slower on CPU.
  - On Linux: Native Docker. Fastest option.
- **GPU (optional):** NVIDIA GPU + [Container Toolkit](docs/03-configuration.md#enabling-gpu). ~4x speedup on inference.
- First model pull downloads 4-8 GB; be on a decent connection.

## 🚀 Quickstart

### Pre-flight checklist

Before you start, make sure you have:

- [ ] Docker running (`docker --version` shows 24+)
- [ ] Ports **5678**, **11434**, **5432**, **8080** free on your machine
- [ ] ~20 GB free disk space
- [ ] A **Slack workspace** where you can install apps (or skip Slack — the stack still runs)
- [ ] (Optional) A **read-only** Alpaca API key if you want portfolio debriefs

---

### Step 1 — Clone and bootstrap

```bash
git clone https://github.com/sonu831/digital-clone.git
cd digital-clone
make bootstrap
```

**What just happened:**
- `.env.example` was copied to `.env` (this is YOUR config file — never commit it)
- Strong random passwords were generated for Postgres and n8n encryption
- `docker compose up -d` started all 4 services (Postgres, Ollama, n8n, Open WebUI)
- The model puller downloaded `llama3:8b` and `deepseek-r1:8b` into Ollama (~8 GB)
- Healthchecks verified every service is ready

**Expected output at the end:**
```
✓ .env created with generated secrets
✓ Stack is up (4 services healthy)
✓ Models pulled: llama3:8b, deepseek-r1:8b
→ Open n8n:     http://localhost:5678  (user: admin / password: <generated>)
→ Open WebUI:   http://localhost:8080
```

If something fails, run `make health` to see which service is down, or `docker compose logs <service>` to inspect.

---

### Step 2 — Verify the stack

```bash
make health
```

You should see something like:
```
✓ postgres   — healthy
✓ ollama     — healthy, models: llama3:8b, deepseek-r1:8b
✓ n8n        — healthy
✓ open-webui — healthy (optional)
```

Also run `docker compose ps` — every service should show `(healthy)`.

---

### Step 3 — Import the workflows

```bash
make import-workflows
```

This loads three workflows into n8n from the JSON files in `n8n/workflows/`:

| Workflow | File | What it does |
| --- | --- | --- |
| **ai-hub** | `hub/ai-hub.json` | The AI brain — validates, routes, calls Ollama, logs to DB, returns decisions. Called BY spokes, never directly. |
| **slack-inbound** | `spokes/slack-inbound/slack-inbound.json` | Listens for Slack mentions, normalizes them, calls the Hub, posts the reply back. |
| **cron-debrief** | `spokes/cron-debrief/cron-debrief.json` | Fires daily at 18:00, queries the day's activity + broker snapshot, gets an AI summary, posts it to your debrief channel. |

Open <http://localhost:5678>, log in with the credentials from Step 1. Go to **Workflows** — you should see all three.

---

### Step 4 — Create n8n credentials

The workflows reference credentials by name. Go to **Settings → Credentials → Add Credential** and create these:

#### 4a. Postgres credential

| Field | Value |
| --- | --- |
| **Credential name** | `Digital Clone Postgres` |
| **Credential type** | Postgres |
| **Host** | `postgres` |
| **Port** | `5432` |
| **Database** | `digital_clone` |
| **User** | `digital_clone` |
| **Password** | Copy `POSTGRES_PASSWORD` from your `.env` file |

> The host is `postgres` (the Docker service name), NOT `localhost`. Containers talk to
> each other on the internal Docker network.

#### 4b. Slack credential

First, create a Slack app:

1. Go to <https://api.slack.com/apps> → **Create New App** → **From scratch**
2. Name it (e.g. "Digital Clone"), pick your workspace
3. Go to **OAuth & Permissions** → Scopes → add these **Bot Token Scopes**:
   - `app_mentions:read`
   - `channels:history`
   - `channels:read`
   - `chat:write`
   - `groups:history` (if using private channels)
   - `im:history` (if using DMs)
4. Click **Install to Workspace** → Allow
5. Copy the **Bot User OAuth Token** (starts with `xoxb-`)
6. Go to **Basic Information** → **App Credentials** → copy the **Signing Secret**

Now in n8n:

| Field | Value |
| --- | --- |
| **Credential name** | `Digital Clone Slack` |
| **Credential type** | Slack API |
| **Access Token** | Your Bot User OAuth Token (`xoxb-...`) |

> Names must match exactly — the workflow JSON looks up credentials by name.

---

### Step 5 — Configure your `.env`

Open `.env` in your editor and fill in:

```env
# ── Slack (required for the default spoke) ──
SLACK_BOT_TOKEN=xoxb-your-bot-token
SLACK_SIGNING_SECRET=your-signing-secret
SLACK_DEBRIEF_CHANNEL=#executive-debriefs

# ── Broker (optional — skip if you don't need portfolio debriefs) ──
BROKER_API_BASE_URL=https://paper-api.alpaca.markets
BROKER_API_KEY_ID=your-key-id
BROKER_API_SECRET_KEY=your-secret-key
```

> Broker keys must be **read-only** at the provider level — the AI is already locked
> down, but this is defense-in-depth. On Alpaca, use paper trading keys.

After saving `.env`, restart n8n to pick up the new variables:

```bash
docker compose restart n8n
```

---

### Step 6 — Activate the workflows

In the n8n UI (<http://localhost:5678>), for each workflow:

1. Open the workflow
2. Click the **Active** toggle (top-right corner) — it turns green
3. **Save** the workflow

**Which ones to activate:**

| Workflow | Activate? | Why |
| --- | --- | --- |
| `ai-hub` | **Yes** | Must be Active for spokes to call it via Execute Workflow |
| `slack-inbound` | **Yes** | Must be Active to receive Slack events via webhook |
| `cron-debrief` | **Depends** | Activate if you set broker keys; skip if not |

> The `slack-inbound` workflow, once activated, will show a **Webhook URL** at the
> top. Slack needs this URL to send events to your bot. Go to your Slack app's
> **Event Subscriptions** page, enable events, paste the webhook URL, and subscribe to
> the `app_mention` and `message.channels` events.

---

### Step 7 — Test it

**Test the Slack bot:**
1. Invite your bot to a channel (`/invite @your-bot-name`)
2. Type: `@your-bot-name What can you do?`
3. The bot should reply within a few seconds with a summary of its capabilities

**Test the daily debrief manually:**
1. Open the `cron-debrief` workflow in n8n
2. Click **Test workflow** (play button, top-right)
3. Check your Slack debrief channel — you should see a summary

**Check the audit log:**
```bash
docker compose exec postgres psql -U digital_clone -d digital_clone \
  -c "SELECT created_at, source, event_type, ai_summary, status FROM clone.activity_logs ORDER BY created_at DESC LIMIT 10;"
```

You should see entries for every message and debrief processed.

---

### Handy commands

```bash
make up                # start the stack
make down              # stop (keeps all data volumes)
make ps                # show container status
make logs s=n8n        # tail n8n logs
make logs s=ollama     # tail Ollama logs
make pull-models       # re-pull models listed in OLLAMA_MODELS
make backup            # pg_dump to ./backups/
make export-workflows  # save live workflows from n8n DB → JSON files
make health            # probe all services + list models
make help              # show all available commands
```

---

## Troubleshooting common issues

| Problem | Likely cause | Fix |
| --- | --- | --- |
| `make bootstrap` fails | Port already in use | Change ports in `.env` (`N8N_PORT`, `OLLAMA_PORT`, etc.) |
| Ollama model pull hangs | Slow network or low disk space | Check disk: `df -h`. Re-run: `make pull-models` |
| Slack bot doesn't respond | Webhook URL not configured in Slack | Go to Slack App → Event Subscriptions → paste the webhook URL from n8n's `slack-inbound` workflow |
| AI replies are slow | CPU inference is underpowered | First message after idle takes longest (model loading). Subsequent messages ~5-15s. Enable GPU for speed |
| "Workflow not found" in n8n logs | `ai-hub` not activated | Make sure `ai-hub` is Active — spokes call it by name |
| `cron-debrief` fails | No broker keys set | Expected if you skipped broker config. Disable the workflow or set the keys |
| Credentials not working | Wrong credential name | Names must match exactly: `Digital Clone Postgres`, `Digital Clone Slack` |
| Postgres connection refused | Using `localhost` instead of `postgres` | Inside Docker, use service name `postgres`, not `localhost` |

See [docs/08-troubleshooting.md](docs/08-troubleshooting.md) for more.

## Make it yours

| I want to…                          | Do this                                                        |
| ----------------------------------- | -------------------------------------------------------------- |
| Use Discord instead of Slack        | Add an input spoke → [docs/05-adding-a-spoke.md](docs/05-adding-a-spoke.md) |
| Swap the LLM                        | Edit `OLLAMA_*` in `.env` → [docs/06-models.md](docs/06-models.md) |
| Drop Open WebUI                     | Comment out its block in `docker-compose.yml`                  |
| Run on a GPU                        | [docs/03-configuration.md#enabling-gpu](docs/03-configuration.md) |
| Change the AI's behavior            | Edit the Hub system prompt → [docs/04-workflow-design.md](docs/04-workflow-design.md) |
| Add a new data source               | Add a data spoke → [docs/05-adding-a-spoke.md](docs/05-adding-a-spoke.md) |

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
