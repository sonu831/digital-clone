# Spoke: `cron-debrief` (INPUT, scheduled)

Runs on a schedule, gathers the day's activity + a **read-only** broker snapshot,
asks the analyst model to summarize, and posts the debrief.

```
[Schedule Trigger: 18:00 daily ($GENERIC_TIMEZONE)]
        │
        ▼
[Postgres: SELECT * FROM clone.v_today]               ← today's events
        │
        ▼
[HTTP Request: GET broker account + orders (READ-ONLY)]
        │   uses BROKER_API_* from .env; day-filtered
        ▼
[Merge + Function: build inbound-event]               ← type:"data_snapshot", source:"cron"
        │                                                 data:{logs, pnl, orders}
        ▼
[Execute Workflow: hub/ai-hub]                        ← analyst model summarizes
        │   (Hub selects $OLLAMA_ANALYST_MODEL for data_snapshot events)
        ▼
[Switch on ai-output.path] → [Slack/Discord: post reply.text to debrief channel]
```

**Credentials needed:** `BROKER_API_KEY_ID`, `BROKER_API_SECRET_KEY` (READ-ONLY scope),
plus your delivery channel token.

> ⚠️ The Hub's guardrails forbid trade execution. Provision broker keys with
> read-only permissions at the broker as defense-in-depth.
