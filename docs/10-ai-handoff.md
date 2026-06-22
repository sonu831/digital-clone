# 10 · AI Handoff — "do the rest" continuation brief

This document hands the project off to **another AI tool or model** (DeepSeek, GPT,
Llama, Copilot, Cursor, Aider, a second Claude session — any of them) so it can
continue the build autonomously. Pair it with the repo-wide rules in
[`AGENTS.md`](../AGENTS.md).

> **If you are an AI agent reading this:** start at "Your mission", obey the
> [golden rule](../AGENTS.md#-the-golden-rule-do-not-break-this), and finish with the
> "Handoff-back protocol" so the next tool (or the human) knows what you did.

---

## 1. Current state (what's done vs. what's left)

### ✅ Done (committed scaffold)
- Full repo structure, `docker-compose.yml` (CPU + GPU-ready, healthchecks, `.env`-driven).
- The two **contracts** (`contracts/*.schema.json`) — the API between spokes and the Hub.
- Database genesis schema (`db/init/01_schema.sql` → `clone.activity_logs`, `clone.v_today`).
- Helper scripts + `Makefile`, CI, docs (01–09), community health files.
- **Specs** (as `README.md`) for the Hub and two reference spokes.

### ⛔ Not yet built (your job)
The actual **n8n workflow JSON exports** do not exist yet — only their specs do:
- `n8n/workflows/hub/ai-hub.json` — the provider-agnostic AI core.
- `n8n/workflows/spokes/slack-inbound/*.json` — Slack input/output spoke.
- `n8n/workflows/spokes/cron-debrief/*.json` — scheduled financial debrief spoke.

Optional follow-ons: a Discord/Telegram input spoke, a Notion output spoke, a Binance
data spoke — each as a NEW folder, never by editing the Hub.

---

## 2. Your mission (ordered tasks with acceptance criteria)

> Build in the n8n UI (recommended) or author the JSON directly, then
> `make export-workflows`. Each task is "done" only when its acceptance check passes.

| # | Task | Acceptance criteria |
| - | ---- | ------------------- |
| 1 | Build the **Hub** per [04-workflow-design.md](04-workflow-design.md) | Given a fixture `inbound-event`, the Hub returns a schema-valid `ai-output` echoing `correlation_id`. A trade request → `path:"deny"`. |
| 2 | Build **slack-inbound** per its [README](../n8n/workflows/spokes/slack-inbound/README.md) | A Slack mention is normalized to `inbound-event`, calls the Hub, and posts `reply.text` back. Bot/self messages ignored. Signature verified with `SLACK_SIGNING_SECRET`. |
| 3 | Build **cron-debrief** per its [README](../n8n/workflows/spokes/cron-debrief/README.md) | At schedule time it reads `clone.v_today` + a **read-only** broker snapshot, builds a `data_snapshot` `inbound-event`, and posts a debrief. Numbers are echoed, not invented. |
| 4 | `make export-workflows` and commit the JSON | Files land in the folders above; CI's JSON validation passes. |
| 5 | Register any new spoke in [integrations/README.md](../integrations/README.md) | Row added; folder has a `README.md`. |

**Guardrails to preserve (non-negotiable):** the AI is **read-only**; the Hub's
system prompt (in task 1's doc) refuses trades/transfers via `path:"deny"`. Broker
keys must be read-only scope. Do not weaken these to "make a demo work".

---

## 3. Which AI/model does what (agent responsibility matrix)

This system is **multi-model by design**. Keep responsibilities separated:

| Agent / model | Where it runs | Responsibility | Interface |
| ------------- | ------------- | -------------- | --------- |
| **Router** — `OLLAMA_ROUTER_MODEL` (default `llama3:8b`) | Ollama (runtime) | Classify each `inbound-event` into a path (alpha/beta/gamma/deny), draft replies, call tools | n8n AI Agent → `http://ollama:11434` |
| **Analyst** — `OLLAMA_ANALYST_MODEL` (default `deepseek-r1:8b`) | Ollama (runtime) | Heavy reasoning for the cron debrief: P&L math, structured summaries | n8n selects it when `type=="data_snapshot"` |
| **Builder AI** — *you* (DeepSeek/GPT/Claude/Copilot…) | dev-time | Generate the n8n workflow JSON + spokes from the specs in this repo | edits files, runs `make`/`docker compose` |
| **Open WebUI** (human-driven) | optional service | Prompt/model playground to test the system prompt before wiring it live | browser → Ollama |

> A common, effective split: use **DeepSeek-R1** (strong structured reasoning) as the
> *Builder AI* to emit the n8n JSON, and keep **Llama 3** as the runtime *Router* for
> speed. Both are local; nothing leaves the host.

---

## 4. How the components communicate (so any tool can integrate)

```
[ Spoke ] ──Execute Workflow(inbound-event)──► [ HUB ] ──HTTP──► [ Ollama 11434 ]
    ▲                                             │  └──Postgres node──► clone.activity_logs
    └────────────── ai-output ────────────────────┘
```

| Edge | Protocol / mechanism | Address | Contract |
| ---- | -------------------- | ------- | -------- |
| Spoke → Hub | n8n **Execute Workflow** | workflow `hub/ai-hub` | `inbound-event` |
| Hub → LLM | HTTP (Ollama API) | `http://ollama:11434` (in-network) | Ollama chat |
| Hub → DB | n8n Postgres node | host `postgres`, db `${POSTGRES_DB}` | SQL → `clone.activity_logs` |
| Hub → Spoke | Execute Workflow return | back to caller | `ai-output` |
| Ops/tooling | CLI | `make …`, `docker compose …` | — |
| Webhooks in | HTTP(S) | `${WEBHOOK_URL}` | provider-specific → normalized in spoke |

**Rules for any new copilot/tool you wire in:**
1. Talk to the Hub **only** through `inbound-event` / `ai-output` — never reach into
   its internals.
2. Use service names inside the Docker network (`ollama`, `postgres`), not `localhost`.
3. Put all new secrets in `.env.example` (empty) + `.env`; reference via `${VAR}`.
4. Validate your payloads against `contracts/*.schema.json` before handoff.

---

## 5. Ready-to-use prompt (paste into your Builder AI, e.g. DeepSeek)

```text
You are extending the open-source repo "digital-clone" (self-hosted AI automation:
n8n + Ollama + Postgres). Read AGENTS.md and docs/04-workflow-design.md first.

GOLDEN RULE: Spokes know providers; the Hub knows only the JSON contracts in
contracts/. Never put provider logic in the Hub.

TASK: Produce an importable n8n workflow JSON for <hub | slack-inbound | cron-debrief>
that implements the spec in its README and:
  - INPUT contract:  contracts/inbound-event.schema.json
  - OUTPUT contract: contracts/ai-output.schema.json
  - Ollama base URL inside the network: http://ollama:11434
  - Models: router=${OLLAMA_ROUTER_MODEL}, analyst=${OLLAMA_ANALYST_MODEL}
  - Read secrets from n8n credentials / env, never inline.

CONSTRAINTS:
  - Preserve the read-only guardrails: any trade/transfer request -> ai-output.path="deny".
  - Echo correlation_id from input to output.
  - Output ONLY valid n8n workflow JSON (no prose), importable via `n8n import:workflow`.

Then list the n8n credentials I must create and any new .env keys.
```

Adjust the bracketed target per workflow. Save the result to the correct folder and run
`make import-workflows` to test, then `make export-workflows` to normalize before commit.

---

## 6. Handoff-back protocol (finish every session with this)

When you stop, append a short note to your PR / commit message stating:

1. **Done:** which tasks in §2 you completed + how you verified (the acceptance check).
2. **Changed files:** especially confirm `git diff -- n8n/workflows/hub` matches intent.
3. **Blocked/assumptions:** anything you couldn't verify (e.g. no live Slack token) and
   what the next tool/human must do.
4. **Next task:** the lowest-numbered §2 row still open.

This keeps the relay between tools (and humans) deterministic.
