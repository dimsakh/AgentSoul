#!/usr/bin/env bash
# Unit tests for the Intrusiveness trends section of metrics-collector.sh.
# Builds synthetic intrusiveness-history.jsonl fixtures and verifies the
# resulting metrics.md contains expected aggregates, trends, and warnings.
#
# Run: bash hooks/tests/test_metrics_intrusiveness.sh

set -uo pipefail

COLLECTOR="$(cd "$(dirname "$0")/.." && pwd)/metrics-collector.sh"

PASS=0
FAIL=0
FAILED_TESTS=()

assert_contains() {
    local label="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1))
        FAILED_TESTS+=("$label: output does not contain '$needle'")
    fi
}

assert_not_contains() {
    local label="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        FAIL=$((FAIL + 1))
        FAILED_TESTS+=("$label: output unexpectedly contains '$needle'")
    else
        PASS=$((PASS + 1))
    fi
}

# Helper: set up a temporary HOME so metrics-collector reads our fixtures
# and writes to an isolated state dir. Emits the path of metrics.md.
_run_collector() {
    local history_lines="$1"   # newline-separated JSONL content
    local tmpd
    tmpd=$(mktemp -d)
    mkdir -p "$tmpd/.claude/hooks/state" "$tmpd/.claude/global-lessons"
    # Need at least one knowledge file so collector doesn't abort early
    cat > "$tmpd/.claude/global-lessons/principle-stub.md" <<'MD'
---
name: stub
type: principle
confidence: 3
impact: 3
confirmed_count: 1
contradicted_count: 0
last_confirmed: 2026-04-15
status: active
---
stub
MD
    if [ -n "$history_lines" ]; then
        printf '%s\n' "$history_lines" > "$tmpd/.claude/hooks/state/intrusiveness-history.jsonl"
    fi
    HOME="$tmpd" bash "$COLLECTOR" >/dev/null 2>&1
    echo "$tmpd/.claude/hooks/state/metrics.md"
    # Caller is responsible for cleaning up $tmpd; we stash it so trap can remove it.
    _LAST_TMPD="$tmpd"
}

_cleanup_last() {
    [ -n "${_LAST_TMPD:-}" ] && rm -rf "$_LAST_TMPD"
    _LAST_TMPD=""
}

# Helper: generate N history lines with specified per-session metrics.
# Args: n gentle_acc_per gentle_ign_per proactive_per override_per debt_pending_per
_gen_sessions() {
    local n="$1" ga="$2" gi="$3" pr="$4" ov="$5" pending="$6"
    local i
    for i in $(seq 1 "$n"); do
        printf '{"session_id":"s%d","date":"2026-04-%02d","created_at":"2026-04-%02dT10:00:00Z","closed_at":"2026-04-%02dT10:30:00Z","duration_min":30,"events_total":10,"budget":{"gentle_used":%d,"gentle_max":5,"proactive_used":%d,"proactive_max":2,"shrink_events":%d},"metrics":{"gentle_accepted":%d,"gentle_ignored":%d,"proactive_events":%d,"override_events":%d,"silence_debt_surfaced":0},"debt":{"surfaced":0,"pending":%d},"cost_peaks":{"timing_max":2,"silence_max":2,"closing":1}}\n' \
            "$i" "$((i % 28 + 1))" "$((i % 28 + 1))" "$((i % 28 + 1))" \
            "$ga" "$pr" "$gi" "$ga" "$gi" "$pr" "$ov" "$pending"
    done
}

# ============================================================================
# Test 1: no history file → no intrusiveness section
# ============================================================================
METRICS_PATH=$(_run_collector "")
OUTPUT=$(cat "$METRICS_PATH")
assert_not_contains "no history: no Intrusiveness section" "$OUTPUT" "## Intrusiveness trends"
_cleanup_last

# ============================================================================
# Test 2: < 20 sessions → cumulative view with "недостаточно данных" note
# ============================================================================
HIST=$(_gen_sessions 10 3 1 1 0 0)
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains "small history: shows section"       "$OUTPUT" "## Intrusiveness trends"
assert_contains "small history: notes insufficient"  "$OUTPUT" "Недостаточно данных"
assert_contains "small history: shows cumulative"    "$OUTPUT" "### Кумулятивные метрики"
assert_contains "small history: session count=10"    "$OUTPUT" "**Сессий всего:** 10"
# 10 sessions × 3 accepted = 30, × 1 ignored = 10 → acceptance = 75%
assert_contains "small history: acceptance 75%"      "$OUTPUT" "75%"
_cleanup_last

# ============================================================================
# Test 3: exactly 20 sessions → last-20 block, no prev-20 comparison
# ============================================================================
HIST=$(_gen_sessions 20 4 1 1 0 0)
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains "20 sessions: shows last-20 header"  "$OUTPUT" "### Последние 20 сессий"
# Prev column should be em-dash (no prev data)
assert_contains "20 sessions: prev column shows —"   "$OUTPUT" "| —"
_cleanup_last

# ============================================================================
# Test 4: 40+ sessions with rising acceptance → trend arrow ↑
# Prev-20 (sessions 1-20): 2 acc / 3 ign each → 40% acceptance
# Last-20 (sessions 21-40): 4 acc / 1 ign each → 80% acceptance
# Expected trend: ↑
# ============================================================================
PREV=$(_gen_sessions 20 2 3 1 0 0)
LAST=$(_gen_sessions 20 4 1 1 0 0)
HIST="${PREV}
${LAST}"
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains "trend ↑: last-20 acceptance 80%"    "$OUTPUT" "80%"
assert_contains "trend ↑: prev-20 acceptance 40%"    "$OUTPUT" "40%"
assert_contains "trend ↑: arrow present"             "$OUTPUT" "↑"
_cleanup_last

# ============================================================================
# Test 5: falling acceptance → trend arrow ↓
# ============================================================================
PREV=$(_gen_sessions 20 4 1 1 0 0)  # 80%
LAST=$(_gen_sessions 20 2 3 1 0 0)  # 40%
HIST="${PREV}
${LAST}"
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
# Warning: acceptance 40% is below 30% threshold? No — 40% is above. Sanity check.
assert_contains "trend ↓: arrow present"             "$OUTPUT" "↓"
_cleanup_last

# ============================================================================
# Test 6: low acceptance triggers warning (<30%)
# ============================================================================
HIST=$(_gen_sessions 25 1 4 1 0 0)  # 20% acceptance
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains "low acceptance: warning emitted"    "$OUTPUT" "gentle_acceptance_rate"
assert_contains "low acceptance: < 30% wording"      "$OUTPUT" "< 30%"
assert_contains "low acceptance: miscalibrated flag" "$OUTPUT" "cost model miscalibrated"
_cleanup_last

# ============================================================================
# Test 7: high override rate triggers warning (>20%)
# 20 sessions × (1 acc + 1 ign + 1 pro + 5 ovr) = 160 total, 100 overrides → 62%
# Expected: warning about override rate miscalibration
# ============================================================================
HIST=$(_gen_sessions 20 1 1 1 5 0)
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains "high override: warning emitted"     "$OUTPUT" "override rate"
assert_contains "high override: 20% boundary"        "$OUTPUT" "> 20%"
_cleanup_last

# ============================================================================
# Test 8: history file present but empty → no crash, no section
# ============================================================================
METRICS_PATH=$(_run_collector "")   # no history lines
# But also simulate truly-empty history file
tmpd=$(mktemp -d)
mkdir -p "$tmpd/.claude/hooks/state" "$tmpd/.claude/global-lessons"
cat > "$tmpd/.claude/global-lessons/principle-stub.md" <<'MD'
---
name: stub
type: principle
confidence: 3
impact: 3
confirmed_count: 1
contradicted_count: 0
last_confirmed: 2026-04-15
status: active
---
MD
: > "$tmpd/.claude/hooks/state/intrusiveness-history.jsonl"   # create empty file
HOME="$tmpd" bash "$COLLECTOR" >/dev/null 2>&1
OUTPUT=$(cat "$tmpd/.claude/hooks/state/metrics.md")
assert_not_contains "empty history file: no trends section" "$OUTPUT" "## Intrusiveness trends"
rm -rf "$tmpd"

# ============================================================================
# Test 9 (v1.3.3): state distribution row appears when history has state_distribution
# ============================================================================

# Helper: generate N sessions with custom state_distribution counts.
# Args: n ga gi pr ov pending  focus stuck exploration idle
_gen_sessions_state() {
    local n="$1" ga="$2" gi="$3" pr="$4" ov="$5" pending="$6"
    local sf="$7" ss="$8" se="$9" si="${10}"
    local i
    for i in $(seq 1 "$n"); do
        printf '{"session_id":"s%d","date":"2026-04-%02d","created_at":"2026-04-%02dT10:00:00Z","closed_at":"2026-04-%02dT10:30:00Z","duration_min":30,"events_total":10,"budget":{"gentle_used":%d,"gentle_max":5,"proactive_used":%d,"proactive_max":2,"shrink_events":%d},"metrics":{"gentle_accepted":%d,"gentle_ignored":%d,"proactive_events":%d,"override_events":%d,"silence_debt_surfaced":0},"debt":{"surfaced":0,"pending":%d},"cost_peaks":{"timing_max":2,"silence_max":2,"closing":1},"state_distribution":{"focus":%d,"stuck":%d,"exploration":%d,"idle":%d}}\n' \
            "$i" "$((i % 28 + 1))" "$((i % 28 + 1))" "$((i % 28 + 1))" \
            "$ga" "$pr" "$gi" "$ga" "$gi" "$pr" "$ov" "$pending" \
            "$sf" "$ss" "$se" "$si"
    done
}

# 10 sessions × (focus=6, stuck=1, exploration=1, idle=2) → 60% / 10% / 10% / 20%
HIST=$(_gen_sessions_state 10 3 1 1 0 0  6 1 1 2)
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains "state dist: row present"                    "$OUTPUT" "state focus/stuck/exploration/idle"
assert_contains "state dist: 60% focus reported"             "$OUTPUT" "60%"
assert_contains "state dist: 20% idle reported"              "$OUTPUT" "20%"
_cleanup_last

# ============================================================================
# Test 10 (v1.3.3): high stuck% (>30) triggers warning
# ============================================================================
# 25 sessions × (focus=2, stuck=5, exploration=1, idle=2) → 50% stuck
HIST=$(_gen_sessions_state 25 3 1 1 0 0  2 5 1 2)
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains "high stuck: warning emitted"                "$OUTPUT" "state stuck"
assert_contains "high stuck: > 30% wording"                  "$OUTPUT" "> 30%"
_cleanup_last

# ============================================================================
# Test 11 (v1.3.3): history without state_distribution (legacy pre-v1.3.3)
# → section works, no state row (backward compat)
# ============================================================================
HIST=$(_gen_sessions 10 3 1 1 0 0)   # uses legacy helper, no state_distribution
METRICS_PATH=$(_run_collector "$HIST")
OUTPUT=$(cat "$METRICS_PATH")
assert_contains     "legacy history: section still renders"       "$OUTPUT" "## Intrusiveness trends"
assert_not_contains "legacy history: no state row when missing"   "$OUTPUT" "state focus/stuck/exploration/idle"
_cleanup_last

# ============================================================================
# Report
# ============================================================================
TOTAL=$((PASS + FAIL))
echo ""
echo "metrics-collector intrusiveness tests: $PASS/$TOTAL passed"
if [ "$FAIL" -gt 0 ]; then
    echo ""
    echo "Failures:"
    for t in "${FAILED_TESTS[@]}"; do
        echo "  - $t"
    done
    exit 1
fi
exit 0
