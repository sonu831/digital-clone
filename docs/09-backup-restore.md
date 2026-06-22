# 09 · Backup & Restore

## What's worth backing up

| Asset                              | Where                                   | How                          |
| ---------------------------------- | --------------------------------------- | ---------------------------- |
| n8n state + `clone.activity_logs`  | Postgres (`postgres_data` volume)       | `make backup` (pg_dump)      |
| **`N8N_ENCRYPTION_KEY`**           | `.env`                                  | store separately, encrypted  |
| Workflow definitions               | `n8n/workflows/*.json`                  | git (commit your exports)    |
| Pulled models                      | `ollama_data` volume                    | re-pullable; usually skip    |

> ⚠️ A Postgres dump contains your **encrypted** n8n credentials. They are useless
> without `N8N_ENCRYPTION_KEY`. Back up the key **separately** — losing it means losing
> every saved credential even if you have the dump.

## Backup

```bash
make backup           # → backups/pg_YYYYMMDD_HHMMSS.dump  (custom-format pg_dump)
make export-workflows # → refresh n8n/workflows/*.json, then commit them
```

Automate it (host cron):

```cron
0 3 * * *  cd /opt/digital-clone && make backup >> backups/cron.log 2>&1
```

Copy `backups/` off-box (object storage / another host). The folder is git-ignored.

## Restore (onto a fresh host)

```bash
# 1. clone repo, restore .env (incl. the SAME N8N_ENCRYPTION_KEY!), then:
docker compose up -d postgres
# 2. wait for healthy, then load the dump:
cat backups/pg_YYYYMMDD_HHMMSS.dump \
  | docker exec -i digital-clone-postgres \
      pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists
# 3. bring up the rest + re-pull models:
docker compose up -d
make pull-models
make import-workflows
```

## Disaster-recovery drill

Test your restore at least once. The two failure modes that bite people:

1. Restoring the DB but **not** the original `N8N_ENCRYPTION_KEY` → credentials unreadable.
2. Forgetting to re-pull models → workflows error on the first inference call.
