# 01 · Architecture

## The one idea

> **Spokes know providers. The Hub knows only contracts.**

Digital Clone is an **event bus** wearing an n8n costume. Inputs are normalized into
one payload shape, the AI core acts on that shape, and its decision is normalized into
another shape that outputs consume. Because the core never touches a provider directly,
*you can replace any provider without touching the core.*

See the [architecture diagram](diagrams/architecture.md).

## Components

| Layer            | Component        | Role                                                       | Swappable? |
| ---------------- | ---------------- | ---------------------------------------------------------- | ---------- |
| Nervous system   | **n8n**          | Orchestration, triggers, scheduling, the Hub & spokes      | core       |
| Brain            | **Ollama**       | Local LLM inference (Llama 3, DeepSeek-R1, …)              | model-swap |
| Memory / state   | **PostgreSQL**   | n8n state + `clone.activity_logs` event log                | core       |
| Playground       | **Open WebUI**   | Manual prompt/model testing (optional)                     | removable  |
| Spokes           | **Your integrations** | Slack, Discord, broker, Notion, …                     | **yes**    |

Everything runs in Docker on one private network (`digital_clone_net`). Nothing is
exposed except the ports you map in `.env`.

## Data flow (happy path)

```
provider event ─► [input spoke] ─► inbound-event ─► [HUB → Ollama] ─► ai-output ─► [output spoke] ─► provider action
                                        │                                  │
                                        └──────────► clone.activity_logs ◄──┘   (audit, correlation_id-linked)
```

1. An **input spoke** receives a provider event (a Slack mention, a cron tick, a
   broker snapshot) and maps it to an [`inbound-event`](../contracts/inbound-event.schema.json).
2. The **Hub** validates the contract, runs the AI Agent (with guardrails + tools),
   and emits an [`ai-output`](../contracts/ai-output.schema.json).
3. An **output spoke** translates `ai-output` into a provider call (post a message,
   write a row, hit an API).
4. Every step is logged to `clone.activity_logs`, linked by `correlation_id`.

## Why this shape

- **Forkability** — the whole point. New users replace spokes, not the engine.
- **Privacy** — inference is 100% local; data never leaves the host.
- **Testability** — the Hub can be tested with fixture `inbound-event`s, no Slack required.
- **Observability** — one append-only log table answers "what happened and why".

## What lives where

```
contracts/        ← the two interfaces (the actual decoupling)
n8n/workflows/hub ← the provider-agnostic core
n8n/workflows/spokes ← provider integrations (add yours here)
db/init/          ← genesis schema for the event log
docker/           ← optional custom images
docs/             ← you are here
```

Next: [02 · Quickstart](02-quickstart.md).
