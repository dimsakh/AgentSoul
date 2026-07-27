#!/usr/bin/env bash
# test_session_collector.sh — характеризующий тест Stop-финализатора.
# Хук центральный (финализация сессии, напоминания /learn, pending-alerts, silence debt),
# но был без своего теста (F8). Полный прогон зависит от реестра/activity-flush, поэтому
# тест проверяет безопасный инвариант: на пустых transcript/cwd хук завершает Stop без
# падения (rc=0) и при наличии/отсутствии session_id. Изоляция STATE_DIR.

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HOOKS_DIR/session-collector.sh"
[ -f "$HOOK" ] || { echo "FAIL: $HOOK not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq недоступен"; exit 0; }

PASS=0
FAIL=0
assert_rc0() { if [ "$1" -eq 0 ]; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL [$2]: rc=$1"; fi; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/state"

run() {  # $1=session_id — пустые transcript/cwd → activity_flush пропускается
    printf '{"session_id":"%s","transcript_path":"","cwd":""}' "$1" \
        | STATE_DIR="$TMP/state" bash "$HOOK" >/dev/null 2>&1
}

# Stop с session_id (fresh, без накопленных алертов) → завершает без падения
run "stop-sid-fresh"; assert_rc0 "$?" "T1 Stop with SID → rc=0"

# Stop без session_id → завершает без падения
run ""; assert_rc0 "$?" "T2 Stop without SID → rc=0"

# повторный Stop той же сессии → без падения (idempotent finalize)
run "stop-sid-fresh"; assert_rc0 "$?" "T3 repeat Stop → rc=0"

echo ""
echo "session-collector tests: $PASS/$((PASS + FAIL)) passed"
[ "$FAIL" -eq 0 ]
