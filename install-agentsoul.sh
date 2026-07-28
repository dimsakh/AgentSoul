#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-python3}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v "$PYTHON_BIN" >/dev/null 2>&1 || {
  echo "Python 3 is required." >&2
  exit 1
}

"$PYTHON_BIN" -m pip install --upgrade pip
"$PYTHON_BIN" -m pip install "$ROOT_DIR"

if command -v agentsoul >/dev/null 2>&1; then
  agentsoul init
else
  "$PYTHON_BIN" -m agentsoul_core.cli init
fi

echo "AgentSoul installed successfully."
echo "Run: agentsoul install-project <path-to-project>"
