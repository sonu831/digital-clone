# Architecture Diagram

```mermaid
graph TD
    %% ── Input spokes ────────────────────────────────────────────────
    Slack[Slack / Discord / Telegram]:::spoke -->|provider event| InSpoke
    Cron[Schedule Trigger]:::spoke --> InSpoke
    Broker[Brokerage API - READ ONLY]:::spoke -->|P&L snapshot| InSpoke

    subgraph Host[Self-Hosted Docker Network: digital_clone_net]
        InSpoke[Input Spokes<br/>normalize → inbound-event]:::n8n
        InSpoke ==>|inbound-event contract| Hub
        Hub[AI HUB<br/>provider-agnostic core]:::hub
        Hub <-->|infer| Ollama[(Ollama<br/>Llama3 · DeepSeek-R1)]:::brain
        Hub ==>|ai-output contract| OutSpoke[Output Spokes<br/>ai-output → provider call]:::n8n
        Hub <-->|log / read| DB[(PostgreSQL<br/>clone.activity_logs)]:::db
        WebUI[Open WebUI<br/>optional]:::opt <-->|manage models| Ollama
    end

    OutSpoke -->|reply| Slack
    OutSpoke -->|debrief| DebriefChan[#executive-debriefs]:::spoke

    classDef spoke fill:#e3f2fd,stroke:#1976d2,color:#0d47a1;
    classDef n8n fill:#ffe0b2,stroke:#f57c00,color:#5d2c00;
    classDef hub fill:#fff3e0,stroke:#e65100,stroke-width:3px,color:#3e2723;
    classDef brain fill:#e8f5e9,stroke:#388e3c,color:#1b5e20;
    classDef db fill:#e1f5fe,stroke:#0288d1,color:#01579b;
    classDef opt fill:#f3e5f5,stroke:#8e24aa,color:#4a148c,stroke-dasharray:5 5;
```

**Read it as three layers:**

1. **Spokes (blue)** — provider-specific. Replaceable. They speak HTTP/SDK on one
   side and the **contracts** on the other.
2. **Hub (orange, bold)** — provider-agnostic. The only thing that talks to the model.
   It accepts `inbound-event`, returns `ai-output`, and never imports a provider SDK.
3. **Infra (green/blue)** — Ollama (compute) + Postgres (state), plus optional Open WebUI.

The `==>` edges are the **contract boundaries** — the two interfaces in
[`/contracts`](../../contracts/). Everything to the left of `inbound-event` and to
the right of `ai-output` is swappable without touching the Hub.
