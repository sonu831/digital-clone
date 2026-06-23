# Spoke: `kite-data` (INPUT, scheduled)

Polls Zerodha Kite Connect API for live positions, holdings, margins, and P&L.
Builds a `data_snapshot` inbound-event for the AI Hub's analyst model.

```
[Schedule Trigger: every 15 min (market hours recommended)]
        │
        ▼
[HTTP Request: GET /portfolio/positions]       ← Kite API, READ-ONLY scope
        │
        ▼
[HTTP Request: GET /portfolio/holdings]        ← parallel or sequential
        │
        ▼
[HTTP Request: GET /user/margins]             ← account margin/segment info
        │
        ▼
[Function: merge → inbound-event]              ← type:"data_snapshot", source:"kite"
        │                                          data:{ positions, holdings, margins, pnl }
        ▼
[Execute Workflow: hub/ai-hub]                ← analyst model analyzes
        │
        ▼
[Switch on ai-output.path]
        └── alpha/gamma → [deliver via Slack/WhatsApp/Telegram spoke]
```

**Credentials needed:** `KITE_API_KEY`, `KITE_ACCESS_TOKEN` (READ-ONLY at broker level).

> The Hub's guardrails forbid trade execution. This spoke only fetches data.
> Provision your Kite Connect token with read-only scope as an extra layer.

## Setup

1. Register at [Kite Connect](https://kite.trade) (developer.kite.trade)
2. Create an app → get `api_key`
3. Generate an `access_token` via the Kite Connect login flow
4. Add to `.env`:
   ```
   KITE_API_KEY=
   KITE_ACCESS_TOKEN=
   KITE_API_BASE_URL=https://api.kite.trade
   ```
5. For 15-min polling during market hours only, set the schedule to:
   - Interval: 15 min
   - Or: multiple schedule triggers at 09:15, 09:30, 09:45 ... 15:30

## Market hours tip

Create multiple Schedule Trigger nodes for Indian market hours (Mon-Fri, 09:15-15:30)
to avoid polling when the market is closed.
