#!/usr/bin/env bash
# Weekly copy of both media buckets to storage outside the production R2 account (spec §35).
# `sync` mirrors deletions too, so objects of deleted accounts leave the copy at the next run.
#
#   MEDIA_SOURCE=r2: MEDIA_BACKUP=backup:plengo-media ./media-sync.sh
set -euo pipefail

: "${MEDIA_SOURCE:?MEDIA_SOURCE (rclone remote of the production R2 account) is required}"
: "${MEDIA_BACKUP:?MEDIA_BACKUP (rclone remote path of the copy) is required}"
for bucket in "${R2_PRIVATE_BUCKET:-media-private}" "${R2_PUBLIC_BUCKET:-media-public}"; do
  echo "syncing $bucket"
  rclone sync --fast-list --checksum "$MEDIA_SOURCE$bucket" "$MEDIA_BACKUP/$bucket"
done
echo "media copy up to date"
