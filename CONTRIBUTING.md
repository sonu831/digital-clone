# Contributing to Digital Clone

Thanks for helping build a privacy-first automation agent people can actually own.
The most valuable contributions are **new spokes** (integrations) and docs.

## The one rule that matters

> **Integrate via the [contracts](contracts/). Never edit the Hub to add a provider.**

If your change makes the Hub aware of Slack/Discord/Alpaca/Notion specifics, it will be
sent back. Provider knowledge belongs in spokes. This is what keeps the project forkable
for everyone. See [docs/04-workflow-design.md](docs/04-workflow-design.md).

## Ways to contribute

- 🧩 **New spoke** — Discord, Telegram, Notion, Binance, Jira… Follow
  [docs/05-adding-a-spoke.md](docs/05-adding-a-spoke.md).
- 📝 **Docs** — clarify a step, fix a command, add a troubleshooting entry.
- 🐛 **Bug fixes** — to the core stack, scripts, or compose.
- 💡 **Proposals** — open a discussion/issue before large changes.

## Dev setup

```bash
git clone https://github.com/<you>/digital-clone.git
cd digital-clone
make bootstrap
```

## Workflow (PR process)

1. **Fork** and create a branch: `feat/discord-spoke`, `docs/fix-quickstart`, etc.
2. Make your change. For workflows, build in the n8n UI, then `make export-workflows`.
3. **Self-check** (CI runs these too):
   - `docker compose config -q` — compose is valid.
   - JSON in `contracts/` and `n8n/workflows/` parses.
   - No secrets committed; `.env` is not staged; `n8n/credentials/` is empty.
4. Update docs + the [integrations registry](integrations/README.md) if you added a spoke.
5. Open a PR using the template. Describe what providers it touches and confirm the Hub
   is unchanged (`git diff -- n8n/workflows/hub`).

## Coding & style conventions

- **Secrets:** every new secret goes into `.env.example` (empty value) and is documented.
  Nothing secret in compose, scripts, or workflow JSON.
- **Compose:** new config is driven by `.env` via `${VAR}`; optional services get the
  `# >>> OPTIONAL … <<<` fence so they're cleanly removable.
- **Scripts:** POSIX `bash`, `set -euo pipefail`, idempotent where possible.
- **Spokes:** one folder per spoke under `n8n/workflows/spokes/<name>/` with a `README.md`.

## Commit messages

Conventional-ish prefixes help: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`.

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).

## License

Contributions are licensed under the project's [GPLv3](LICENSE).
