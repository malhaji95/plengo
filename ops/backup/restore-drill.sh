#!/usr/bin/env bash
# Restore drill (spec §35): restores a dump into an empty database and checks that it is usable.
# Run monthly by .github/workflows/backups.yml and before any risky migration.
#
#   DUMP=path/or/remote.dump RESTORE_URL=postgres://.../scratch ./restore-drill.sh
#
# DUMP may be an rclone remote path; "latest" takes the newest dump in BACKUP_REMOTE.
# RESTORE_URL must point at an empty scratch database — never production.
set -euo pipefail

: "${RESTORE_URL:?RESTORE_URL (an empty scratch database) is required}"
DUMP="${DUMP:-latest}"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-$(cd "$(dirname "$0")/../../packages/db/migrations" && pwd)}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
started=$(date +%s)

if [[ "$DUMP" == "latest" ]]; then
  : "${BACKUP_REMOTE:?BACKUP_REMOTE is required for DUMP=latest}"
  name="$(rclone lsf --files-only "$BACKUP_REMOTE" | grep '\.dump$' | sort | tail -1)"
  [[ -n "$name" ]] || { echo "no dump found in $BACKUP_REMOTE"; exit 1; }
  rclone copyto "$BACKUP_REMOTE/$name" "$work/$name"
  DUMP="$work/$name"
elif [[ "$DUMP" == *:* && ! -f "$DUMP" ]]; then
  rclone copyto "$DUMP" "$work/restore.dump"
  DUMP="$work/restore.dump"
fi
echo "restoring $DUMP"

existing="$(psql "$RESTORE_URL" -Atc "select count(*) from pg_tables where schemaname = 'public'")"
if [[ "$existing" != "0" ]]; then
  echo "refusing: the target database is not empty ($existing tables)"
  exit 1
fi
pg_restore --no-owner --no-privileges --exit-on-error --dbname="$RESTORE_URL" "$DUMP"

q() { psql "$RESTORE_URL" -Atc "$1"; }
fail() { echo "DRILL FAILED: $1"; exit 1; }

# Every migration in the repository is applied in the backup (or the backup predates the newest).
applied="$(q 'select count(*) from drizzle.__drizzle_migrations')"
expected="$(ls "$MIGRATIONS_DIR"/*.sql | wc -l | tr -d ' ')"
[[ "$applied" -ge 1 ]] || fail "no applied migrations"
echo "migrations: $applied applied, $expected in the repository"
[[ "$applied" -le "$expected" ]] || fail "backup has migrations this code does not know"

# Core tables exist and are readable; the fixed education levels are present.
for table in users profiles education_levels subjects questions flashcard_decks entitlements coupons quiz_attempts audit_logs; do
  count="$(q "select count(*) from $table")" || fail "cannot read $table"
  echo "  $table: $count rows"
done
[[ "$(q 'select count(*) from education_levels')" -ge 3 ]] || fail "education levels missing"
# Referential integrity survived the restore.
[[ "$(q "select count(*) from entitlements e left join users u on u.id = e.user_id where u.id is null")" == "0" ]] \
  || fail "entitlements without users"
[[ "$(q "select count(*) from question_options o left join questions q on q.id = o.question_id where q.id is null")" == "0" ]] \
  || fail "options without questions"

echo "restore drill passed in $(( $(date +%s) - started ))s"
