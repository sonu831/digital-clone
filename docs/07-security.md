# 07 · Security

Digital Clone is privacy-first by design (local inference, no data egress), but a
self-hosted automation agent is still a juicy target. Treat this as a checklist.

## Threat model in one line

You're running a service that holds **provider tokens** and can **act on your behalf**.
Protect (a) the secrets, (b) the management UIs, and (c) the action surface.

## Secrets

- ✅ All secrets live in `.env`, which is **git-ignored**. Never commit it.
- ✅ `N8N_ENCRYPTION_KEY` encrypts stored credentials. Back it up *separately* from
  the DB dump; treat it like a root key. **Never change it after first run.**
- ✅ Never run `n8n export:credentials --decrypted`. The repo's `.gitignore` blocks
  `n8n/credentials/*.json` to prevent accidental leaks.
- ✅ Rotate provider tokens periodically; revoke immediately if a host is compromised.

## Network exposure

- Keep services on the private `digital_clone_net`. The only host-exposed ports are
  the ones you map in `.env`.
- **Production:** delete the Postgres `ports:` mapping so the DB is reachable *only*
  inside the network.
- Don't expose Ollama (`11434`) to the public internet — it has no auth.
- Put n8n behind a reverse proxy with **HTTPS** (Caddy/Traefik/nginx). Then set
  `N8N_PROTOCOL=https`, the real `N8N_HOST`/`WEBHOOK_URL`, and `N8N_SECURE_COOKIE=true`.

## Authentication

- n8n basic auth is **on by default** (`N8N_BASIC_AUTH_ACTIVE=true`). Keep it on.
- Open WebUI runs with `WEBUI_AUTH=true`. The first account you create is the admin.
- Use strong, generated passwords (`make bootstrap` does this for you).

## The action surface (this is the AI-specific risk)

- **Read-only by contract.** The Hub system prompt forbids trades/transfers/irreversible
  actions and routes such requests to `path:"deny"`. See
  [04 · Workflow Design](04-workflow-design.md).
- **Defense in depth:** provision broker/API keys with **read-only scope** at the
  provider. The prompt is a guardrail, not a permission system — least-privilege keys are.
- **Validate inbound webhooks.** Verify provider signatures (e.g. Slack signing secret)
  so attackers can't forge events into your Hub.
- **Bound the tools.** Only give the AI Agent the neutral tools it needs. An `http.fetch`
  tool should allow-list destinations, not fetch arbitrary URLs.

## Webhook verification (Slack example)

Use `SLACK_SIGNING_SECRET` to validate `X-Slack-Signature` in the input spoke before
the event reaches the Hub. Reject anything that doesn't verify.

## Supply chain & updates

- Pin image tags for production (e.g. `n8nio/n8n:1.x.x`) instead of `latest` once you
  settle on a version; review changelogs before bumping.
- Run `make backup` before any upgrade.

## Reporting a vulnerability

See [SECURITY.md](../SECURITY.md) for private disclosure.
