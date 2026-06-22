# Spoke: `slack-inbound` (INPUT)

Translates a Slack event into the `inbound-event` contract, calls the Hub, then
delivers the Hub's `ai-output` back to Slack.

```
[Slack Trigger: app_mention / message]
        │
        ▼
[Filter: ignore bot + self messages]
        │
        ▼
[Function: map Slack payload → inbound-event]   ← source:"slack", new correlation_id
        │
        ▼
[Execute Workflow: hub/ai-hub]                  ← returns ai-output
        │
        ▼
[Switch on ai-output.path]
        ├── alpha/gamma → [Slack: post reply.text to channel]
        ├── beta        → [already logged via Hub tool; optional ack]
        └── deny        → [Slack: post guardrail.message]
```

**Credentials needed:** `SLACK_BOT_TOKEN`, `SLACK_SIGNING_SECRET` (set in `.env`,
added to n8n's credential store — never in the JSON).

> Forking to Discord/Telegram? Copy this folder, swap the trigger + the final
> delivery node, keep the same map-to-`inbound-event` and Execute-Workflow steps.
> See [`docs/05-adding-a-spoke.md`](../../../docs/05-adding-a-spoke.md).
