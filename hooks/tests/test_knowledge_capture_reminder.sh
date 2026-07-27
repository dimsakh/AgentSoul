#!/usr/bin/env bash
# test_knowledge_capture_reminder.sh — тест мид-сессионного напоминания о захвате знаний.
set -uo pipefail

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$HOOK_DIR/knowledge-capture-reminder.sh"
PASS=0; FAIL=0
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/home/.claude/global-lessons/_drafts" "$TMP/state"

assert_empty()    { if [ -z "$1" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL [$2]: ожидалось пусто, получено '${1:0:60}'"; fi; }
assert_contains() { if printf '%s' "$1" | grep -qF "$2"; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FAIL [$3]: нет '$2' в '${1:0:60}'"; fi; }

run_hook() {
    printf '{"session_id":"test-kcr","tool_name":"Bash","tool_input":{"command":"%s"}}' "$1" | env \
        HOME="$TMP/home" \
        STATE_DIR="$TMP/state" \
        LESSONS_DIR="$TMP/home/.claude/global-lessons" \
        KCR_THRESHOLD=3 \
        PATHS_LIB="$HOOK_DIR/paths-lib.sh" \
        bash "$HOOK" 2>/dev/null
}

# T1: до порога (3) — тихо
assert_empty "$(run_hook 'git commit')" "T1a: коммит 1 тихо"
assert_empty "$(run_hook 'git commit')" "T1b: коммит 2 тихо"

# T2: на пороге — напоминание
OUT=$(run_hook 'git commit')
assert_contains "$OUT" "Захват знаний" "T2: коммит 3 — напоминание"
assert_contains "$OUT" "PostToolUse" "T2b: корректный конверт"

# T3: появился черновик (новее marker) → следующее окно подавлено
touch -t 200001010000 "$TMP/state/knowledge-capture-marker-test-kcr"   # состарить marker
touch "$TMP/home/.claude/global-lessons/_drafts/new-draft.md"          # свежий черновик
assert_empty "$(run_hook 'git commit')" "T3a: коммит 4 (окно не набрано) тихо"
assert_empty "$(run_hook 'git commit')" "T3b: коммит 5 тихо"
assert_empty "$(run_hook 'git commit')" "T3c: коммит 6 — подавлено (черновик появился)"

# T4: не-коммит — не считается, тихо
assert_empty "$(run_hook 'ls -la')" "T4: не-коммит игнорируется"

# T5: без черновика следующее окно снова напоминает
# (marker обновлён на коммите 6; черновиков новее нет)
assert_empty   "$(run_hook 'git commit')" "T5a: коммит 7 тихо"
assert_empty   "$(run_hook 'git commit')" "T5b: коммит 8 тихо"
OUT2=$(run_hook 'git commit')
assert_contains "$OUT2" "Захват знаний" "T5c: коммит 9 — снова напоминание (черновика нет)"

echo ""
echo "knowledge-capture-reminder tests: $PASS/$((PASS+FAIL)) passed"
[ "$FAIL" -eq 0 ]
