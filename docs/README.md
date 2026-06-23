# Digital Clone — Documentation

Start here. The docs are ordered to take you from zero to a running, customized
deployment.

| #  | Doc                                                | Read it when…                                       |
| -- | -------------------------------------------------- | --------------------------------------------------- |
| 01 | [Architecture](01-architecture.md)                 | You want the mental model before touching anything. |
| 02 | [Quickstart](02-quickstart.md)                     | You just want it running in ~10 minutes.            |
| 03 | [Configuration](03-configuration.md)               | You're tuning `.env`, ports, toggles, GPU.          |
| 04 | [Workflow Design (Hub & Spoke)](04-workflow-design.md) | You want to understand how data flows through n8n. |
| 05 | [Adding a Spoke](05-adding-a-spoke.md)             | You're plugging in Discord/Notion/Binance/etc.      |
| 06 | [Models](06-models.md)                             | You're choosing/swapping LLMs in Ollama.            |
| 07 | [Security](07-security.md)                         | Before you expose anything to the internet.         |
| 08 | [Troubleshooting](08-troubleshooting.md)           | Something's red.                                     |
| 09 | [Backup & Restore](09-backup-restore.md)           | You care about not losing your data (you should).   |
| 10 | [AI Handoff](10-ai-handoff.md)                     | You want another AI tool/model (DeepSeek, Copilot…) to continue the build. |
| 11 | [WhatsApp Runbook & n8n 2.26 Gotchas](11-whatsapp-runbook.md) | A webhook spoke 404s/errors, or you hit the n8n 2.x draft/publish trap. |

Reference material:

- [`AGENTS.md`](../AGENTS.md) — operating manual auto-read by AI coding tools.

- [`/contracts`](../contracts/) — the JSON Schemas that decouple spokes from the Hub.
- [`/integrations`](../integrations/) — the registry of community spokes.
- [Architecture diagram](diagrams/architecture.md) — Mermaid source.
