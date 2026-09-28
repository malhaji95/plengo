#!/usr/bin/env bash
# Daily logical backup of the production database (spec §35), in addition to Neon's point-in-time
# recovery. Writes a custom-format pg_dump, uploads it with rclone to storage outside Neon and R2's
# production buckets, and deletes remote dumps older than RETENTION_DAYS (the privacy policy
# promises deleted accounts leave backups within 35 days).
#
#   DATABASE_URL=postgres://... BACKUP_REMOTE=backup:plengo-db ./db-backup.sh
#
# BACKUP_REMOTE is an rclone remote path (configure it with RCLONE_CONFIG_<NAME>_* variables).
# Without it the dump stays in BACKUP_DIR (useful locally).
set -euo pipefail

: "${DATABASE_URL:?DATABASE_URL is required}"
RETENTION_DAYS="${RETENTION_DAYS:-35}"
BACKUP_DIR="${BACKUP_DIR:-$(mktemp -d)}"
stamp="$(date -u +%Y-%m-%dT%H%M%SZ)"
file="$BACKUP_DIR/plengo-$stamp.dump"

mkdir -p "$BACKUP_DIR"
echo "dumping to $file"
pg_dump --format=custom --compress=9 --no-owner --no-privileges --file="$file" "$DATABASE_URL"
# A dump that cannot be listed is not a backup.
pg_restore --list "$file" > /dev/null
size="$(du -h "$file" | cut -f1)"
echo "dump ok ($size)"

if [[ -n "${BACKUP_REMOTE:-}" ]]; then
  rclone copyto "$file" "$BACKUP_REMOTE/plengo-$stamp.dump"
  rclone delete --min-age "${RETENTION_DAYS}d" "$BACKUP_REMOTE"
  echo "uploaded to $BACKUP_REMOTE; remote dumps older than $RETENTION_DAYS days removed"
  rm -f "$file"
else
  echo "BACKUP_REMOTE not set: dump kept at $file"
fi
