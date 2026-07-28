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
sleep 3
set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a
curl -fsS "https://${AGENTSOUL_DOMAIN}/health"
