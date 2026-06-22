# 05 · Adding a Spoke

A "spoke" is a provider integration. This is the contributor guide for plugging in
**Discord, Telegram, Notion, Binance, Jira — anything** — *without modifying the Hub*.

## The golden rule

> Your spoke may import any provider SDK and hold any provider token.
> Your spoke must speak the [contracts](../contracts/) to the Hub — nothing else.

There are two kinds:

- **Input spoke** — receives a provider event, emits a valid `inbound-event`, calls the Hub.
- **Output spoke** — receives an `ai-output`, performs a provider action.

Many integrations are both (receive a message → reply).

## Recipe: a new INPUT spoke (e.g. Discord instead of Slack)

1. **Copy a sibling** as a starting point:
   `n8n/workflows/spokes/slack-inbound/` → `n8n/workflows/spokes/discord-inbound/`.
2. **Swap the trigger node** to the provider's trigger (Discord webhook / bot event).
3. **Map to the contract.** In a Code node, transform the provider payload into an
   [`inbound-event`](../contracts/inbound-event.schema.json):

   ```js
   return [{
     json: {
       schema_version: "1.0",
       event_id: $jmespath($json, "id") || crypto.randomUUID(),
       correlation_id: crypto.randomUUID(),
       source: "discord",
       type: "message",
       occurred_at: new Date().toISOString(),
       actor:   { id: $json.author.id, display_name: $json.author.username, is_bot: $json.author.bot },
       channel: { id: $json.channel_id, name: $json.channel_name, thread_id: null },
       text:    $json.content,
       raw:     $json
     }
   }];
   ```
4. **Call the Hub** via an **Execute Workflow** node → `hub/ai-hub`. It returns `ai-output`.
5. **Deliver** by switching on `ai-output.path` and posting `reply.text` to the provider.
6. **Add credentials** to `.env` (e.g. `DISCORD_BOT_TOKEN`) and to n8n's credential store.
7. **Register** your spoke in [`/integrations/README.md`](../integrations/README.md).
8. **Export** the workflow: `make export-workflows` (lands in your spoke folder).

That's it. **You did not open the Hub workflow.**

## Recipe: a new OUTPUT spoke (e.g. write to Notion)

1. Create `n8n/workflows/spokes/notion-out/`.
2. Trigger: **Execute Workflow Trigger** (the Hub or another spoke calls it), or read
   `ai-output.actions` for a matching `tool` (e.g. `task.create`).
3. Map `ai-output` fields → provider call (create a Notion page from `actions[].params`).
4. Add credentials, register, export.

## Recipe: a new DATA spoke (e.g. Binance instead of Alpaca)

Mirror `cron-debrief`: a schedule trigger + a **read-only** HTTP/SDK fetch that emits
an `inbound-event` with `type:"data_snapshot"` and the metrics under `data`. The Hub's
analyst model summarizes it. Keep API keys **read-only** — the Hub forbids trading.

## Checklist before you open a PR

- [ ] Spoke lives under `n8n/workflows/spokes/<name>/` with a short `README.md`.
- [ ] Input spokes emit a **schema-valid** `inbound-event`; output spokes consume `ai-output`.
- [ ] **No provider logic leaked into the Hub.** (`git diff` shows the Hub untouched.)
- [ ] New secrets added to `.env.example` (empty) and documented.
- [ ] No credentials committed (`n8n/credentials/` stays empty).
- [ ] Spoke registered in `/integrations/README.md`.
- [ ] Workflow exported with `make export-workflows`.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the PR process.
