# 04 · Workflow Design — Hub & Spoke / Event Bus

This is the heart of Digital Clone's modularity. Read it before building workflows.

## The pattern

A classic **Hub-and-Spoke event bus**, expressed in n8n workflows:

```
              ┌──────────────── inbound-event (contract) ────────────────┐
   provider   │                                                          ▼
   events ──► [ INPUT SPOKES ] ════════════════════════════════════► [  HUB  ]
   (Slack,      slack-inbound                                          AI core   │
    Discord,    cron-debrief                                        (Ollama +    │
    broker)     telegram-inbound …                                  guardrails)  │
                                                                                 │
   provider  ◄─ [ OUTPUT SPOKES ] ◄══════════════════════════════════════════════┘
   actions      slack-reply           ▲                ai-output (contract)
   (post msg,    notion-write          │
    write DB)    discord-reply         └── clone.activity_logs (audit, correlation_id)
```

- **Spokes** are n8n workflows bound to a provider. They are the *only* place a
  provider SDK/token appears.
- The **Hub** is a single n8n workflow that knows *nothing* about providers. It is
  invoked by spokes via the **Execute Workflow** node.
- The two double-line edges (`════`) are the **contracts** in [`/contracts`](../contracts/).
  They are the API of the system.

## Why a separate Hub workflow (not one mega-flow)?

| Benefit            | Because…                                                                   |
| ------------------ | -------------------------------------------------------------------------- |
| Add integrations safely | A new spoke calls the existing Hub; the Hub is never edited.          |
| One place for AI logic  | Prompt, model choice, tools, guardrails live once.                   |
| Testable           | Feed the Hub a fixture `inbound-event`; assert on the `ai-output`.          |
| Swappable models   | Change `OLLAMA_ROUTER_MODEL` / `OLLAMA_ANALYST_MODEL` — spokes don't care.  |

## The Hub, node by node

1. **Execute Workflow Trigger** — entry point; receives one `inbound-event`.
2. **Validate contract** — a Code/IF node that rejects payloads missing required
   fields. Fail loud, early.
3. **Select model** — branch on `inbound-event.type`:
   `data_snapshot` → `OLLAMA_ANALYST_MODEL` (DeepSeek-R1, better at math);
   everything else → `OLLAMA_ROUTER_MODEL` (Llama 3, fast routing).
4. **AI Agent** (Ollama Chat Model):
   - **System prompt** = the guardrailed prompt below.
   - **Memory** = Window Buffer keyed by `correlation_id` (thread continuity).
   - **Tools** = neutral tools (`db.log_event`, `task.create`, `http.fetch`).
5. **Build `ai-output`** — a Code node that shapes the agent result into the
   [`ai-output`](../contracts/ai-output.schema.json) contract.
6. **Respond to Execute Workflow** — returns `ai-output` to the calling spoke.

## The routing decision (`ai-output.path`)

The model classifies every input into exactly one path:

| Path    | Meaning                              | Typical output                                  |
| ------- | ------------------------------------ | ----------------------------------------------- |
| `alpha` | Informational reply needed           | `reply.text`                                    |
| `beta`  | Administrative task / follow-up      | `actions: [{tool:"task.create", …}]`            |
| `gamma` | Needs data → fetch then summarize    | `actions: [{tool:"http.fetch"}]` + `reply.text` |
| `deny`  | Guardrail refusal                    | `guardrail.triggered=true` + message            |

Output spokes switch on `path` — they never re-interpret the model.

## System prompt (production)

Paste this into the AI Agent's **system** field. It enforces the read-only,
no-hallucination guarantees.

```text
Identity & Authority:
You are "Digital Clone", an autonomous, fully-local executive chief of staff to the
owner. You process incoming professional communications and analyze READ-ONLY
operational/financial data. You run on the owner's own hardware; nothing leaves it.

Operational Guardrails (CRITICAL — non-negotiable):
1. READ-ONLY LIMITATION: You have ZERO authority to execute trades, modify positions,
   move money, or take any irreversible external action. If asked to buy/sell/transfer,
   respond on path "deny" with guardrail.rule="read_only_limitation" and the message:
   "Operational bounds exceeded. Transaction denied."
2. FACTUAL GROUNDING: Use ONLY data provided by your tools (Postgres logs, broker API
   payloads in the inbound event). Never invent a metric, task, timestamp, or amount.
   If required data is missing, set path="gamma" or report the gap explicitly — do not guess.
3. MATHEMATICAL VALIDATION: For any P&L/portfolio math, use the raw numbers from the
   payload. Report absolute change, percentage change, and trade counts exactly as
   received. Do not extrapolate or forecast.

Routing (choose exactly one path):
- alpha: needs an acknowledgment or informational reply. Draft a concise, professional
  reply in the owner's tone → fill `reply`.
- beta:  implies an administrative task/follow-up → emit an action with tool
  "task.create" describing the objective.
- gamma: requests a summary/state that requires data → emit "http.fetch" or rely on
  the snapshot, then summarize in `reply`.
- deny:  violates a guardrail → set guardrail.triggered=true.

Output:
Return ONLY a JSON object conforming to the ai-output contract (schema_version "1.0").
Echo the inbound correlation_id. Keep `summary` to one line. In `reply.text` use
markdown; bold key figures; bullet distinct metrics. Tone: analytical, direct, no
corporate platitudes.
```

## The two reference spokes

- [`slack-inbound`](../n8n/workflows/spokes/slack-inbound/) — real-time router/logger.
- [`cron-debrief`](../n8n/workflows/spokes/cron-debrief/) — scheduled financial debrief.

## Adding your own

You never touch this doc's Hub to integrate a new provider — see
[05 · Adding a Spoke](05-adding-a-spoke.md).
