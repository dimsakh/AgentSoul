#!/usr/bin/env bash
# test_error_tracker.sh — error-tracker.sh success-cascade + /retro auto-draft (v1.5.8 steps 2.2, 2.3).

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$HOOKS_DIR/error-tracker.sh"

[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT not found"; exit 1; }

PASS=0
FAIL=0

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if echo "$haystack" | grep -Fq "$needle"; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: '$needle' not in:"; echo "$haystack"; fi
}
assert_empty() {
    local actual="$1" label="$2"
    if [ -z "$actual" ] || [ "$actual" = "{}" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: expected empty, got: $actual"; fi
}
assert_file_exists() {
    local path="$1" label="$2"
    if [ -f "$path" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: file not found: $path"; fi
}
assert_file_absent() {
    local path="$1" label="$2"
    if [ ! -f "$path" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: file unexpectedly exists: $path"; fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

STATE_DIR="$TMP/state"
DRAFT_DIR="$TMP/drafts"
mkdir -p "$STATE_DIR" "$DRAFT_DIR"

run_hook() {
    local sid="$1" exit_code="$2" stderr="$3"
    local payload
    payload=$(jq -cn \
        --arg ec "$exit_code" --arg se "$stderr" \
        '{tool_result: {exit_code: ($ec|tonumber), stderr: $se}}')
    printf '%s' "$payload" | \
        CLAUDE_CODE_SESSION_ID="$sid" \
        STATE_DIR="$STATE_DIR" \
        ERROR_TRACKER_DRAFT_DIR="$DRAFT_DIR" \
        bash "$SCRIPT" 2>/dev/null
}

TODAY=$(date +%Y-%m-%d)

# ============================================================================
# T1: single success — no systemMessage, no draft
# ============================================================================
OUT=$(run_hook "sid1" 0 "")
assert_empty "$OUT" "T1a: plain success → silent"
assert_file_absent "$DRAFT_DIR/case-${TODAY}-auto-draft.md" "T1b: no draft on plain success"

# ============================================================================
# T2: single failure → count=1, no cascade message
# ============================================================================
OUT=$(run_hook "sid2" 1 "error: something")
assert_empty "$OUT" "T2a: single failure → no cascade msg"
COUNT=$(cat "$STATE_DIR/error_count_sid2" 2>/dev/null)
[ "$COUNT" = "1" ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL [T2b]: count=$COUNT, expected 1"; }

# ============================================================================
# T3: second failure → cascade warning
# ============================================================================
OUT=$(run_hook "sid2" 1 "error: again")
assert_contains "$OUT" "2+ consecutive" "T3a: 2nd failure → warning"
COUNT=$(cat "$STATE_DIR/error_count_sid2")
[ "$COUNT" = "2" ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL [T3b]: count=$COUNT, expected 2"; }

# ============================================================================
# T4: success after cascade → /learn suggestion with attempts count (step 2.2)
# ============================================================================
OUT=$(run_hook "sid2" 0 "")
assert_contains "$OUT" "💡" "T4a: 💡 emoji in success-cascade"
assert_contains "$OUT" "Паттерн сложного fix" "T4b: russian phrase"
assert_contains "$OUT" "2 attempts" "T4c: attempts count in message"
assert_contains "$OUT" "/learn" "T4d: /learn mentioned"

# Count reset
COUNT=$(cat "$STATE_DIR/error_count_sid2")
[ "$COUNT" = "0" ] && PASS=$((PASS + 1)) || { FAIL=$((FAIL + 1)); echo "FAIL [T4e]: count=$COUNT after reset, expected 0"; }

# ============================================================================
# T5: /retro auto-draft created on cascade resolve (step 2.3)
# ============================================================================
DRAFT_FILE="$DRAFT_DIR/case-${TODAY}-auto-draft.md"
assert_file_exists "$DRAFT_FILE" "T5a: auto-draft file created"
DRAFT_CONTENT=$(cat "$DRAFT_FILE")
assert_contains "$DRAFT_CONTENT" "type: case" "T5b: frontmatter type=case"
assert_contains "$DRAFT_CONTENT" "status: draft" "T5c: status=draft"
assert_contains "$DRAFT_CONTENT" "attempts: 2" "T5d: attempts field"
assert_contains "$DRAFT_CONTENT" "source: error-tracker auto-draft" "T5e: source labeled"
assert_contains "$DRAFT_CONTENT" "## Что произошло" "T5f: skeleton heading ru"
assert_contains "$DRAFT_CONTENT" "## Урок / правило" "T5g: lesson heading"
assert_contains "$OUT" "Скелет авто-черновика сохранён" "T5h: draft note in message"

# ============================================================================
# T6: draft already exists today → not overwritten
# ============================================================================
echo "# already-written" > "$DRAFT_DIR/case-${TODAY}-auto-draft.md"
# run fresh cascade in new session
run_hook "sid6" 1 "err" >/dev/null
run_hook "sid6" 1 "err" >/dev/null
OUT=$(run_hook "sid6" 0 "")
assert_contains "$OUT" "💡" "T6a: cascade msg still fires"
CONTENT=$(cat "$DRAFT_DIR/case-${TODAY}-auto-draft.md")
assert_contains "$CONTENT" "already-written" "T6b: existing draft preserved"

# ============================================================================
# T7: grep no-match (exit 1, empty stderr) → not counted
# ============================================================================
OUT=$(run_hook "sid7" 1 "")
assert_empty "$OUT" "T7a: grep no-match → silent"
[ ! -f "$STATE_DIR/error_count_sid7" ] && PASS=$((PASS + 1)) \
    || { FAIL=$((FAIL + 1)); echo "FAIL [T7b]: count file created for grep no-match"; }

# ============================================================================
# T8: 3-attempt cascade → attempts=3 in message and draft
# ============================================================================
# Use isolated draft dir so T5 draft doesn't interfere
DRAFT_DIR2="$TMP/drafts2"
mkdir -p "$DRAFT_DIR2"
run3() {
    local sid="$1" exit_code="$2" stderr="$3"
    local payload
    payload=$(jq -cn --arg ec "$exit_code" --arg se "$stderr" \
        '{tool_result: {exit_code: ($ec|tonumber), stderr: $se}}')
    printf '%s' "$payload" | \
        CLAUDE_CODE_SESSION_ID="$sid" \
        STATE_DIR="$STATE_DIR" \
        ERROR_TRACKER_DRAFT_DIR="$DRAFT_DIR2" \
        bash "$SCRIPT" 2>/dev/null
}
run3 "sid8" 1 "e" >/dev/null
run3 "sid8" 1 "e" >/dev/null
run3 "sid8" 1 "e" >/dev/null
OUT=$(run3 "sid8" 0 "")
assert_contains "$OUT" "3 attempts" "T8a: 3 attempts count in msg"
DRAFT8="$DRAFT_DIR2/case-${TODAY}-auto-draft.md"
assert_file_exists "$DRAFT8" "T8b: draft created"
assert_contains "$(cat "$DRAFT8")" "attempts: 3" "T8c: attempts=3 in frontmatter"

# ============================================================================
# T9: JSON output validity on cascade resolve
# ============================================================================
DRAFT_DIR3="$TMP/drafts3"
mkdir -p "$DRAFT_DIR3"
run4() {
    local sid="$1" exit_code="$2" stderr="$3"
    local payload
    payload=$(jq -cn --arg ec "$exit_code" --arg se "$stderr" \
        '{tool_result: {exit_code: ($ec|tonumber), stderr: $se}}')
    printf '%s' "$payload" | \
        CLAUDE_CODE_SESSION_ID="$sid" \
        STATE_DIR="$STATE_DIR" \
        ERROR_TRACKER_DRAFT_DIR="$DRAFT_DIR3" \
        bash "$SCRIPT" 2>/dev/null
}
run4 "sid9" 1 "e" >/dev/null
run4 "sid9" 1 "e" >/dev/null
OUT=$(run4 "sid9" 0 "")
echo "$OUT" | jq -e '.systemMessage | type == "string"' >/dev/null 2>&1 \
    && PASS=$((PASS + 1)) \
    || { FAIL=$((FAIL + 1)); echo "FAIL [T9]: invalid JSON: $OUT"; }

echo ""
echo "=================================="
echo "error-tracker: $PASS passed, $FAIL failed"
echo "=================================="
[ "$FAIL" -eq 0 ]
