#!/usr/bin/env bash
set -euo pipefail
ENV_FILE=/etc/agentsoul/agentsoul.env
[[ -r "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a
BACKUP_DIR=${AGENTSOUL_BACKUP_DIR:-/var/backups/agentsoul}
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
DEST="$BACKUP_DIR/agentsoul-$STAMP.zip"
mkdir -p "$BACKUP_DIR"
docker compose -f /opt/agentsoul/deploy/vps/compose.yml --env-file "$ENV_FILE" exec -T agentsoul \
  python -m agentsoul_core.cli --home /data/agentsoul backup "/data/backups/$(basename "$DEST")"
find "$BACKUP_DIR" -type f -name 'agentsoul-*.zip' -mtime +30 -delete
printf '%s\n' "$DEST"
