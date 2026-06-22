---
name: New integration (spoke)
about: Propose or claim a new provider integration
title: "[spoke] "
labels: spoke, enhancement
---

## Provider

Which provider? (e.g. Discord, Telegram, Notion, Binance, Jira)

## Kind

- [ ] Input spoke (provider event → `inbound-event` → Hub)
- [ ] Output spoke (Hub `ai-output` → provider action)
- [ ] Both

## Mapping sketch

How does the provider's payload map onto the [`inbound-event`](../../contracts/inbound-event.schema.json)
and/or [`ai-output`](../../contracts/ai-output.schema.json) contracts? List the key fields.

## Credentials / scopes

What `.env` keys does it need? For data/trading providers, confirm **read-only** scope.

## Decoupling confirmation

- [ ] This can be built **without modifying the Hub** (provider logic stays in the spoke).

## Are you working on it?

- [ ] Yes, assign me
- [ ] Just proposing
