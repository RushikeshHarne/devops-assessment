#!/usr/bin/env bash
set -euo pipefail

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-appuser}"
PGPASSWORD="${PGPASSWORD:-apppassword}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.dump"

echo "Backing up '${DB_NAME}' → ${BACKUP_FILE}"

PGPASSWORD="$PGPASSWORD" pg_dump \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_USER" \
  --format=custom \
  --compress=9 \
  --file="$BACKUP_FILE" \
  "$DB_NAME"

echo "Backup complete: ${BACKUP_FILE}"
echo "$BACKUP_FILE"
