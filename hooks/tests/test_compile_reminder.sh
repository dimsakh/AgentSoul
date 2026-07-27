#!/usr/bin/env bash
# test_compile_reminder.sh — v1.0.0: проверка compile-reminder-lib (Фаза 3 L1→L2).
# Счётчик сессий, порог, нудж раз в сессию, сброс.

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LIB="$HOOKS_DIR/compile-reminder-lib.sh"
[ -f "$LIB" ] || { echo "FAIL: $LIB not found"; exit 1; }

PASS=0
FAIL=0
assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if echo "$haystack" | grep -Fq "$needle"; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: '$needle' not found in '$haystack'"; fi
}
assert_empty() {
    local val="$1" label="$2"
    if [ -z "$val" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: expected empty, got '$val'"; fi
}
assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [ "$actual" = "$expected" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: got '$actual', expected '$expected'"; fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
# Isolate state under a fake HOME
export HOME="$TMP/home"
mkdir -p "$HOME/.claude/hooks/state"
STATE="$HOME/.claude/hooks/state"
# shellcheck source=/dev/null
source "$LIB"

# --- Test 1: first session counted, no reminder below threshold (default 5) ---
OUT=$(compile_reminder_check "sid-1")
assert_empty "$OUT" "T1: no nudge below threshold"
assert_eq "$(cat "$STATE/compile-pending")" "1" "T1: counter=1 after first session"

# --- Test 2: same session counted only once (Stop fires many times) ---
OUT=$(compile_reminder_check "sid-1")
assert_eq "$(cat "$STATE/compile-pending")" "1" "T2: same sid does not re-increment"
assert_empty "$OUT" "T2: still no nudge"

# --- Test 3: distinct sessions accumulate to threshold → nudge at 5 ---
compile_reminder_check "sid-2" >/dev/null
compile_reminder_check "sid-3" >/dev/null
compile_reminder_check "sid-4" >/dev/null
OUT=$(compile_reminder_check "sid-5")
assert_eq "$(cat "$STATE/compile-pending")" "5" "T3: counter=5 at fifth session"
assert_contains "$OUT" "пора /compile" "T3: nudge appears at threshold"
assert_contains "$OUT" "5 сессий" "T3: nudge reports count"

# --- Test 4: once per session — re-check same session does not repeat nudge ---
OUT=$(compile_reminder_check "sid-5")
assert_empty "$OUT" "T4: no repeat nudge within same session"

# --- Test 5: reset zeroes counter and clears markers ---
compile_reminder_reset
assert_eq "$(cat "$STATE/compile-pending")" "0" "T5: counter reset to 0"
NEW=$(compile_reminder_check "sid-6")
assert_eq "$(cat "$STATE/compile-pending")" "1" "T5: counting restarts after reset"
assert_empty "$NEW" "T5: no nudge right after reset"

# --- Test 6: empty sid is a no-op ---
BEFORE=$(cat "$STATE/compile-pending")
OUT=$(compile_reminder_check "")
rc=$?
assert_eq "$rc" "0" "T6: empty sid returns 0"
assert_eq "$(cat "$STATE/compile-pending")" "$BEFORE" "T6: empty sid does not change counter"

# --- Test 7: custom threshold via env ---
compile_reminder_reset
OUT=$(COMPILE_REMINDER_THRESHOLD=2 compile_reminder_check "sid-7a")
assert_empty "$OUT" "T7: below custom threshold 2"
OUT=$(COMPILE_REMINDER_THRESHOLD=2 compile_reminder_check "sid-7b")
assert_contains "$OUT" "пора /compile" "T7: nudge at custom threshold 2"

echo ""
echo "Compile reminder tests: $PASS/$((PASS + FAIL)) passed"
[ "$FAIL" -eq 0 ]
