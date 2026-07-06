#!/usr/bin/env bash
set -euo pipefail

BACKUP_FILE="${1:-}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-appdb}"
DB_USER="${DB_USER:-appuser}"
PGPASSWORD="${PGPASSWORD:-apppassword}"

if [[ -z "$BACKUP_FILE" ]]; then
  echo "Usage: $0 <backup_file.dump>"
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Error: backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Restoring '${BACKUP_FILE}' → ${DB_NAME}"

# Drop and recreate the target database for a clean restore
PGPASSWORD="$PGPASSWORD" psql \
  --host="$DB_HOST" --port="$DB_PORT" \
  --username="$DB_USER" \
  --dbname="postgres" \
  --command="SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='${DB_NAME}' AND pid <> pg_backend_pid();" \
  --quiet

PGPASSWORD="$PGPASSWORD" psql \
  --host="$DB_HOST" --port="$DB_PORT" \
  --username="$DB_USER" \
  --dbname="postgres" \
  --command="DROP DATABASE IF EXISTS ${DB_NAME};" \
  --quiet

PGPASSWORD="$PGPASSWORD" psql \
  --host="$DB_HOST" --port="$DB_PORT" \
  --username="$DB_USER" \
  --dbname="postgres" \
  --command="CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};" \
  --quiet

PGPASSWORD="$PGPASSWORD" pg_restore \
  --host="$DB_HOST" \
  --port="$DB_PORT" \
  --username="$DB_USER" \
  --dbname="$DB_NAME" \
  --no-owner \
  --no-privileges \
  --verbose \
  "$BACKUP_FILE"

echo "Restore complete."
