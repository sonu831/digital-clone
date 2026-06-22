# Integrations Registry

A catalog of available **spokes** (provider integrations). When you add a spoke
([05 · Adding a Spoke](../docs/05-adding-a-spoke.md)), register it here so others can
discover it.

## Legend

- **Kind** — `input` (provider → Hub), `output` (Hub → provider), or `both`.
- **Status** — `core` (shipped), `community` (contributed), `planned`.

## Catalog

| Spoke            | Kind   | Provider        | Status    | Workflow folder                                   |
| ---------------- | ------ | --------------- | --------- | ------------------------------------------------- |
| `slack-inbound`  | both   | Slack           | core      | `n8n/workflows/spokes/slack-inbound/`             |
| `cron-debrief`   | input  | Schedule + broker | core    | `n8n/workflows/spokes/cron-debrief/`              |
| `discord-inbound`| both   | Discord         | planned   | _your PR here_                                    |
| `telegram-inbound`| both  | Telegram        | planned   | _your PR here_                                    |
| `notion-out`     | output | Notion          | planned   | _your PR here_                                    |
| `binance-data`   | input  | Binance (read-only) | planned | _your PR here_                                  |

## Add yours

1. Build & export the spoke under `n8n/workflows/spokes/<name>/`.
2. Add a row above (kind, provider, status, folder).
3. List any new `.env` keys it needs (added empty to `.env.example`).
4. Open a PR — see [CONTRIBUTING.md](../CONTRIBUTING.md).

> Reminder: a spoke is the **only** place a provider SDK/token may appear. The Hub
> stays provider-agnostic. If your change edits the Hub to support a provider, it will
> be sent back.
