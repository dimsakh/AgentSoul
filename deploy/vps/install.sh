#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Run as root: sudo bash deploy/vps/install.sh <domain> <email>" >&2
  exit 1
fi

DOMAIN=${1:-}
EMAIL=${2:-}
if [[ -z "$DOMAIN" ]]; then
  echo "Usage: sudo bash deploy/vps/install.sh <domain> [acme-email]" >&2
  exit 1
fi

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
INSTALL_DIR=/opt/agentsoul
DATA_DIR=/var/lib/agentsoul
BACKUP_DIR=/var/backups/agentsoul
TOKEN_FILE=/etc/agentsoul/token
ENV_FILE=/etc/agentsoul/agentsoul.env

command -v docker >/dev/null 2>&1 || { echo "Docker is required." >&2; exit 1; }
docker compose version >/dev/null 2>&1 || { echo "Docker Compose v2 is required." >&2; exit 1; }

install -d -m 0755 "$INSTALL_DIR" "$DATA_DIR" "$BACKUP_DIR" /etc/agentsoul
rsync -a --delete --exclude '.git' "$ROOT_DIR/" "$INSTALL_DIR/"

if [[ ! -s "$TOKEN_FILE" ]]; then
  umask 077
  python3 - <<'PY' > "$TOKEN_FILE"
import secrets
print(secrets.token_urlsafe(48))
PY
fi
chmod 600 "$TOKEN_FILE"
TOKEN=$(cat "$TOKEN_FILE")

cat > "$ENV_FILE" <<EOF
AGENTSOUL_DOMAIN=$DOMAIN
ACME_EMAIL=$EMAIL
AGENTSOUL_API_TOKEN=$TOKEN
AGENTSOUL_DATA_DIR=$DATA_DIR
AGENTSOUL_BACKUP_DIR=$BACKUP_DIR
EOF
chmod 600 "$ENV_FILE"

install -m 0644 "$INSTALL_DIR/deploy/vps/agentsoul.service" /etc/systemd/system/agentsoul.service
install -m 0644 "$INSTALL_DIR/deploy/vps/agentsoul-backup.service" /etc/systemd/system/agentsoul-backup.service
install -m 0644 "$INSTALL_DIR/deploy/vps/agentsoul-backup.timer" /etc/systemd/system/agentsoul-backup.timer
install -m 0755 "$INSTALL_DIR/deploy/vps/backup.sh" /usr/local/sbin/agentsoul-backup
install -m 0755 "$INSTALL_DIR/deploy/vps/update.sh" /usr/local/sbin/agentsoul-update

systemctl daemon-reload
systemctl enable --now agentsoul.service
systemctl enable --now agentsoul-backup.timer

for _ in {1..60}; do
  if curl -fsS "https://$DOMAIN/health" >/dev/null 2>&1; then
    echo "AgentSoul is available at https://$DOMAIN/ui"
    echo "Bearer token stored in $TOKEN_FILE"
    exit 0
  fi
  sleep 2
done

echo "Deployment started, but HTTPS health check is not ready yet." >&2
systemctl status agentsoul.service --no-pager || true
exit 1
