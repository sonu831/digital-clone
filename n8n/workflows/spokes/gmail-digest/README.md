# Spoke: `gmail-digest` (INPUT, scheduled)

Daily inbox digest: fetches today's emails, asks the AI to summarize them, and
posts the digest to a delivery channel (Slack/Discord/Telegram).

```
[Schedule Trigger: 08:00 daily ($GENERIC_TIMEZONE)]
        │
        ▼
[Gmail: search today's emails]              ← query: "after:YYYY/MM/DD"
        │
        ▼
[Function: build inbound-event]             ← type:"data_snapshot", source:"gmail-digest"
        │                                       data:{ emails: [...], count, unread_count, ... }
        ▼
[Execute Workflow: hub/ai-hub]              ← analyst model summarizes
        │
        ▼
[Switch on ai-output.path] → [Post digest to Slack/Discord/Telegram]
```

**Credentials needed:** Gmail OAuth2 (same as `gmail-inbound`), plus delivery channel token.

> Combine with `cron-debrief` for a unified morning brief: emails + calendar + tasks.
