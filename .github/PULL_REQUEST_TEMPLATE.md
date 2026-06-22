<!-- Thanks for contributing to Digital Clone! -->

## What does this PR do?

<!-- One or two sentences. -->

## Type

- [ ] 🧩 New spoke (integration)
- [ ] 🐛 Bug fix
- [ ] 📝 Docs
- [ ] 🔧 Core / infra (compose, scripts, contracts)

## The decoupling rule

- [ ] This PR **does not** add provider-specific logic to the Hub
      (`git diff -- n8n/workflows/hub` is empty), **or** it's a deliberate, justified
      change to the Hub contract (explain below).

<!-- If you changed the Hub or a contract, explain why and the version impact. -->

## Checklist

- [ ] `docker compose config -q` passes.
- [ ] Any JSON I added (contracts / workflows) is valid and parses.
- [ ] New secrets are added to `.env.example` (empty) and documented — none hardcoded.
- [ ] No credentials committed; `n8n/credentials/` is still empty.
- [ ] Workflows exported via `make export-workflows` (if applicable).
- [ ] New spoke registered in `integrations/README.md` with a folder `README.md`.
- [ ] Docs updated where relevant.

## Testing

<!-- How did you verify this works? CPU or GPU? Which providers? -->
