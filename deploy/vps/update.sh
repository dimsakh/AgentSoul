#!/usr/bin/env bash
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Run as root: sudo agentsoul-update" >&2
  exit 1
fi

INSTALL_DIR=/opt/agentsoul
ENV_FILE=/etc/agentsoul/agentsoul.env
[[ -d "$INSTALL_DIR" ]] || { echo "Missing $INSTALL_DIR" >&2; exit 1; }
[[ -r "$ENV_FILE" ]] || { echo "Missing $ENV_FILE" >&2; exit 1; }

/usr/local/sbin/agentsoul-backup
cd "$INSTALL_DIR"
if [[ -d .git ]]; then
  git fetch --all --prune
  git pull --ff-only
else
  echo "Install directory is not a Git checkout; replace files from a trusted release before updating." >&2
  exit 1
fi
systemctl reload agentsoul.service

for _ in {1..30}; do
  if curl -fsS "http://127.0.0.1:8000/health" >/dev/null 2>&1; then
    echo "AgentSoul updated successfully."
    exit 0
  fi
  sleep 2
done

echo "AgentSoul update completed, but the local health check failed." >&2
systemctl status agentsoul.service --no-pager || true
exit 1
