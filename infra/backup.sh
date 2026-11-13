#!/usr/bin/env bash
# Nightly database backup to S3. Run by cron on the server (see README.md).
# The server's IAM role gives access to the bucket, so no key is stored here.
set -euo pipefail

cd "$(dirname "$0")"
set -a
# shellcheck disable=SC1091
source .env
set +a

stamp="$(date -u +%Y-%m-%dT%H%MZ)"
target="s3://${BACKUP_BUCKET}/db/mallika-${stamp}.dump"

# Custom format, so pg_restore can bring back the whole database or one table.
docker compose exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc \
  | aws s3 cp - "$target" --only-show-errors

echo "$(date -u +%FT%TZ) backup saved to ${target}"
