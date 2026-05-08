#!/usr/bin/env bash
# backup.sh — PostgreSQL daily backup via pg_dump
#
# Keeps the last 7 days of backups.
# Intended to be run by cron:
#   0 3 * * * /path/to/ledge-app/backend/scripts/backup.sh >> /var/log/ledge-backup.log 2>&1

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────────────────
BACKUP_DIR="${BACKUP_DIR:-/var/backups/ledge}"
CONTAINER_NAME="${CONTAINER_NAME:-ledge-postgres}"
POSTGRES_USER="${POSTGRES_USER:-ledge}"
POSTGRES_DB="${POSTGRES_DB:-ledge_db}"
RETAIN_DAYS="${RETAIN_DAYS:-7}"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FILENAME="ledge_${TIMESTAMP}.sql.gz"

# ─── Run ──────────────────────────────────────────────────────────────────────
mkdir -p "$BACKUP_DIR"

echo "[$(date)] Starting backup → $BACKUP_DIR/$FILENAME"

docker exec "$CONTAINER_NAME" \
  pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" | \
  gzip > "$BACKUP_DIR/$FILENAME"

echo "[$(date)] Backup complete: $FILENAME ($(du -sh "$BACKUP_DIR/$FILENAME" | cut -f1))"

# ─── Cleanup: remove backups older than RETAIN_DAYS ───────────────────────────
find "$BACKUP_DIR" -name "ledge_*.sql.gz" -mtime +"$RETAIN_DAYS" -delete
echo "[$(date)] Cleanup done — keeping last $RETAIN_DAYS days"
