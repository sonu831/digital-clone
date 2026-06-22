#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────────────
# backup.sh — dump Postgres (n8n state + clone schema) to ./backups/.
# Restore with:  scripts/restore.sh <file.dump>  (or see docs/09-backup-restore.md)
# ──────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p backups
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT="backups/pg_${STAMP}.dump"

PG_USER="$(grep -E '^POSTGRES_USER=' .env | cut -d= -f2-)"
PG_DB="$(grep -E '^POSTGRES_DB=' .env | cut -d= -f2-)"
CONTAINER="${COMPOSE_PROJECT_NAME:-digital-clone}-postgres"

echo "→ Dumping ${PG_DB} from ${CONTAINER} → ${OUT}"
docker exec "$CONTAINER" pg_dump -U "$PG_USER" -d "$PG_DB" -Fc > "$OUT"
echo "✓ Backup written: ${OUT} ($(du -h "$OUT" | cut -f1))"
echo "  Store this off-box. It contains your encrypted n8n credentials + logs."
