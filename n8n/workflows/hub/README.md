# Hub — `ai-hub.json`

The **provider-agnostic** AI core. Spokes call it via **Execute Workflow**.

```
[Execute Workflow Trigger]                      ← receives an `inbound-event` JSON
        │
        ▼
[Validate: inbound-event contract]              ← reject malformed payloads early
        │
        ▼
[AI Agent  (Ollama Chat Model: $OLLAMA_ROUTER_MODEL)]
        ├── System Prompt: identity + guardrails (see docs/04-workflow-design.md)
        ├── Memory: Window Buffer (keyed by correlation_id / thread)
        └── Tools (neutral names, resolved by output spokes):
              ├── db.log_event     → INSERT into clone.activity_logs
              ├── task.create      → record a follow-up task
              └── http.fetch       → read-only context fetch
        │
        ▼
[Build: ai-output contract]                     ← normalize model result
        │
        ▼
[Respond to Execute Workflow]                   ← returns `ai-output` JSON to the spoke
```

**Contract in:** [`inbound-event.schema.json`](../../../contracts/inbound-event.schema.json)
**Contract out:** [`ai-output.schema.json`](../../../contracts/ai-output.schema.json)

> Place the exported `ai-hub.json` in this folder. Until then this README is the
> spec to build against. Do not add provider-specific nodes (Slack/Discord/broker)
> here — those belong in spokes.
