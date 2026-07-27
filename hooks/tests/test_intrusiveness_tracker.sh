#!/usr/bin/env bash
# test_intrusiveness_tracker.sh — характеризующий тест хука-обёртки.
# Сама intrusiveness-state-lib покрыта (182 ассерта в test_intrusiveness_lib);
# здесь — тонкая обёртка UserPromptSubmit: читает состояние и инжектит секцию.
# Тест закрывает F8 для обёртки: fresh-сессия молчит, без SID молчит, не падает.

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HOOKS_DIR/intrusiveness-tracker.sh"
[ -f "$HOOK" ] || { echo "FAIL: $HOOK not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq недоступен"; exit 0; }

PASS=0
FAIL=0
assert_silent() {
    if [ -z "$1" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$2]: ожидалась тишина, получено: $1"; fi
}
assert_rc0() {
    if [ "$1" -eq 0 ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$2]: rc=$1 (ожидался 0)"; fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/state"

run() {  # $1=session_id $2=prompt
    printf '{"session_id":"%s","prompt":"%s"}' "$1" "$2" \
        | STATE_DIR="$TMP/state" bash "$HOOK" 2>/dev/null
}

# fresh-сессия: первый turn создаёт пустой scaffold → инжекта ещё нет (тишина)
out=$(run "fresh-sid" "обычный вопрос"); rc=$?
assert_silent "$out" "T1 fresh session → silent"
assert_rc0 "$rc" "T1 rc=0"

# без session_id → ранний выход, тишина
out=$(run "" "вопрос"); rc=$?
assert_silent "$out" "T2 no session_id → silent"
assert_rc0 "$rc" "T2 rc=0"

# повторный вызов той же сессии не падает (idempotent init)
out=$(run "fresh-sid" "ещё вопрос"); rc=$?
assert_rc0 "$rc" "T3 repeat call rc=0"

echo ""
echo "intrusiveness-tracker tests: $PASS/$((PASS + FAIL)) passed"
[ "$FAIL" -eq 0 ]
