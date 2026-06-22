# Contracts — the API between Spokes and the Hub

These JSON Schemas are the **load-bearing decoupling layer** of Digital Clone.
They define the *only* two shapes that cross the boundary between integrations
("Spokes") and the AI core ("Hub"):

| File                                                       | Direction        | Produced by      | Consumed by      |
| ---------------------------------------------------------- | ---------------- | ---------------- | ---------------- |
| [`inbound-event.schema.json`](inbound-event.schema.json)   | Spoke → Hub      | **Input** spokes | The AI Hub       |
| [`ai-output.schema.json`](ai-output.schema.json)           | Hub → Spoke      | The AI Hub       | **Output** spokes |

## The rule that keeps the project forkable

> A Spoke may know everything about its provider (Slack, Discord, Alpaca…).
> The Hub may know **nothing** about any provider — only these two contracts.

Because of this:

- Swapping **Slack → Discord** means writing a new *input* spoke that emits a
  valid `inbound-event`. The Hub is untouched.
- Swapping the **delivery channel** means writing a new *output* spoke that
  consumes `ai-output`. The Hub is untouched.
- Bumping a model or rewriting the prompt changes the Hub only. Spokes are untouched.

## Versioning

Both schemas carry `schema_version` (`"1.0"`). Treat them as a public API:

- **Additive** changes (new optional field) → keep the version.
- **Breaking** changes (rename/remove/retype a required field) → bump the version
  and have the Hub branch on `schema_version`.

## Validating

```bash
# Validate a sample payload against a contract (requires: npx, ajv-cli)
npx ajv-cli validate -s contracts/inbound-event.schema.json -d samples/inbound.json --spec=draft2020
```

CI validates these schemas on every PR (see `.github/workflows/ci.yml`).
