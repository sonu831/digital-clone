# Database

PostgreSQL backs two things:

1. **n8n's own internal state** (workflows, executions, credentials) — managed by n8n.
2. **Your application data** — the `clone` schema, owned by you.

## Initialization

Any `*.sql` or `*.sh` file in [`db/init/`](init/) runs **once**, in lexical order,
the first time Postgres starts against an **empty** data volume
(Docker's `/docker-entrypoint-initdb.d` convention).

> ⚠️ These scripts do **not** re-run on subsequent boots. To force a re-init,
> destroy the volume: `docker compose down -v` (this also wipes n8n state — back up first).

## Schema overview (`clone` schema)

| Object                  | Purpose                                                            |
| ----------------------- | ----------------------------------------------------------------- |
| `clone.activity_logs`   | Append-only, spoke-agnostic event log (the heart of the system).  |
| `clone.v_today`         | View of today's events — feeds the cron "evening debrief".        |

The `activity_logs` table stores the **standardized JSON contracts** in its
`inbound_event` and `ai_output` columns. See [`/contracts`](../contracts/) for the
schemas and [`docs/04-workflow-design.md`](../docs/04-workflow-design.md) for how
data flows in.

## Migrations

For schema changes after first init, add **numbered, additive** migration files
(e.g. `db/migrations/0002_add_xyz.sql`) and apply them with `make migrate`
(see the `Makefile`). Never edit `db/init/01_schema.sql` after release — treat it
as the genesis snapshot.
