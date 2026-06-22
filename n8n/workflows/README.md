# n8n Workflows

This directory holds **version-controlled JSON exports** of the n8n workflows.
n8n stores live workflows in Postgres; we export them here so the design is
reviewable, diff-able, and importable on a fresh deploy.

## Layout — Hub & Spoke

```
workflows/
├── hub/                    # The AI core. Provider-agnostic. Rarely changes.
│   └── ai-hub.json         #   Input: inbound-event  →  Output: ai-output
└── spokes/                 # Integrations. Add freely; never edit the hub.
    ├── slack-inbound/      # INPUT spoke  : Slack event  → inbound-event → Hub
    ├── cron-debrief/       # INPUT spoke  : schedule + broker snapshot → Hub
    └── <your-spoke>/       # e.g. discord-inbound, telegram-inbound, notion-out
```

- **Hub** = one workflow that accepts the [`inbound-event`](../../contracts/inbound-event.schema.json)
  contract, runs the AI Agent, and emits the [`ai-output`](../../contracts/ai-output.schema.json)
  contract. It is called by spokes via **Execute Workflow**.
- **Spoke** = a workflow bound to a specific provider. Input spokes *translate into*
  `inbound-event`; output spokes *translate from* `ai-output`.

See [`docs/04-workflow-design.md`](../../docs/04-workflow-design.md) for the full
pattern and [`docs/05-adding-a-spoke.md`](../../docs/05-adding-a-spoke.md) to add one.

## Exporting (after you build/edit in the n8n UI)

```bash
# Export every workflow to this folder (pretty-printed, one file each)
make export-workflows
# …which runs, inside the container:
#   n8n export:workflow --all --separate --pretty --output=/workflows
```

## Importing (on a fresh machine)

```bash
make import-workflows          # n8n import:workflow --separate --input=/workflows
```

## ⚠️ Never commit credentials

Workflow JSON references credentials **by id/name only** — the secrets live in
n8n's encrypted store (keyed by `N8N_ENCRYPTION_KEY`). Do **not** run
`n8n export:credentials --decrypted`. The [`../credentials/`](../credentials/)
folder is git-ignored for this reason.
