# Security Policy

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

Report privately via GitHub's **[Security Advisories](https://github.com/sonu831/digital-clone/security/advisories/new)**
("Report a vulnerability"). Include:

- a description and impact assessment,
- reproduction steps or a proof of concept,
- affected version/commit and your environment (CPU/GPU, OS).

We aim to acknowledge within **72 hours** and to provide a remediation timeline after
triage. Coordinated disclosure is appreciated.

## Scope

In scope: the stack and its defaults — `docker-compose.yml`, helper scripts, the Hub
contract/guardrails, and documentation that could lead users into an insecure setup.

Out of scope: vulnerabilities in upstream projects (n8n, Ollama, PostgreSQL, Open WebUI)
— report those to their maintainers. Misconfigurations contrary to
[docs/07-security.md](docs/07-security.md) (e.g. exposing Ollama to the internet) are
user responsibility, though doc improvements are welcome.

## Hardening guidance

Operational security guidance for deployers lives in
[docs/07-security.md](docs/07-security.md). Highlights:

- Keep `.env` out of git (it is git-ignored by default).
- Back up `N8N_ENCRYPTION_KEY` separately from database dumps.
- Don't expose Postgres or Ollama ports publicly; front n8n with HTTPS.
- Provision third-party API keys (e.g. brokerage) with **read-only** scope.
