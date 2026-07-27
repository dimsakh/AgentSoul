#!/usr/bin/env bash
# session-collector.sh — Stop: напоминает записать незафиксированные уроки через /learn, финализирует сессию в реестре, чистит ephemeral state.
# Fires when Claude is about to stop. Reminds to record unrecorded
# learnings (corrections, successes, struggles) via /learn.
# Also finalizes session in the registry and cleans up ephemeral state files.
#
# Session registry (v0.5.1):
#   - Finalizes active session: appends to registry.jsonl, updates last-session.json
#   - Cleans up active/{session_id}.json
#
# Input: JSON on stdin from Claude Code (Stop event)
# Output: JSON with systemMessage

set -euo pipefail

PATHS_LIB="${PATHS_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths-lib.sh}"
if [ -f "$PATHS_LIB" ]; then source "$PATHS_LIB"; else : "${STATE_DIR:=$HOME/.claude/hooks/state}"; fi

# Read stdin payload once (used for session_id resolution)
INPUT="$(cat)"

# Stable session_id from Claude Code payload — overrides PPID-based fallback
# in session-registry-lib.sh so finalize matches the active record written by
# knowledge-activator/session-start (also using payload session_id).
PAYLOAD_SID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
if [ -n "$PAYLOAD_SID" ]; then
    export SR_OVERRIDE_SESSION_ID="$PAYLOAD_SID"
fi

# Activity flush (v1.5.2-alpha): parse transcript, append machine log to
# .claude-docs/session-activity.md. Complements /save narrative flow —
# activity survives even if /save wasn't called.
PAYLOAD_TRANSCRIPT=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
PAYLOAD_CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
ACTIVITY_LIB="$HOME/.claude/hooks/activity-flush-lib.sh"
if [ -f "$ACTIVITY_LIB" ] && [ -n "$PAYLOAD_SID" ] && [ -n "$PAYLOAD_TRANSCRIPT" ] && [ -n "$PAYLOAD_CWD" ]; then
    # shellcheck source=/dev/null
    source "$ACTIVITY_LIB"
    activity_flush "$PAYLOAD_SID" "$PAYLOAD_TRANSCRIPT" "$PAYLOAD_CWD" >/dev/null 2>&1 || true
fi

# Session-specific state (PPID-based, preserves compatibility with error-tracker
# and other hooks that key state files by ${CLAUDE_CODE_SESSION_ID:-$PPID})
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-$PPID}"
STRUGGLE_FILE="$STATE_DIR/had_struggle_${SESSION_ID}"

# Source session registry library (will pick up SR_OVERRIDE_SESSION_ID if set)
REGISTRY_LIB="$HOME/.claude/hooks/session-registry-lib.sh"
HAS_REGISTRY=false
if [ -f "$REGISTRY_LIB" ]; then
    source "$REGISTRY_LIB"
    HAS_REGISTRY=true
fi

# Check if this session had struggles (set by error-tracker)
HAD_STRUGGLE=false
if [ -f "$STRUGGLE_FILE" ]; then
    HAD_STRUGGLE=true
fi

# User-visible systemMessage: keep short. Verbose self-reflection prompts
# (interlocutor model questions, intrusiveness summary, H10 section) were
# moved to silent file logging — feedback v1.7.2: видимый Stop-вывод не
# должен занимать пол-экрана пользователя. Agent self-reflection on next
# session start через session-start startup-signals.

# Disagreement outcomes check — surface only as compact alert.
# SID по той же схеме, что ITR_SID ниже (payload первичен, PPID — fallback).
# Писатель (knowledge-activator) использует то же выражение: разойдутся — файл не
# найдётся, и счётчик будет молча нулевым, как было до v1.11.
DIS_SID="${PAYLOAD_SID:-$SESSION_ID}"
DISAGREEMENT_LOG="$STATE_DIR/disagreement-pending-${DIS_SID}.jsonl"
PENDING_COUNT=0
if [ -f "$DISAGREEMENT_LOG" ]; then
    # Ключ считается закрытым, если по нему есть более поздняя строка с outcome != pending
    # (её дописывает /learn). for-in вместо length(array) — BSD awk, pattern-shell-portability.
    PENDING_COUNT=$(awk -F'"key":"' 'NF>1 {
        split($2, a, "\""); k = a[1];
        if ($0 ~ /"outcome":"pending"/) p[k] = 1; else delete p[k]
    } END { n = 0; for (kk in p) n++; print n }' "$DISAGREEMENT_LOG" 2>/dev/null || echo 0)
    PENDING_COUNT="${PENDING_COUNT:-0}"
fi

# Intrusiveness summary (v1.3)
# If this session had intrusiveness events — append summary and remind agent to reflect.
ITR_LIB="$HOME/.claude/hooks/intrusiveness-state-lib.sh"
ITR_SID="${PAYLOAD_SID:-$SESSION_ID}"
ITR_STATE="$STATE_DIR/intrusiveness-${ITR_SID}.json"
if [ -f "$ITR_LIB" ] && [ -f "$ITR_STATE" ]; then
    # shellcheck source=/dev/null
    source "$ITR_LIB"

    # Closing_cost detector (v1.3.1): compute cost-of-silence for session end.
    # If there are pending silence_debt items — elevate their priority by marking
    # high-cost ones as "surfaced" (triggers metric increment), and persist the
    # computed cost in cost_hints for cross-session audit.
    CLOSING_COST=$(itr_compute_closing_cost "$ITR_SID" 2>/dev/null || echo 0)
    itr_set_cost_hint "$ITR_SID" last_closing_cost "$CLOSING_COST" >/dev/null 2>&1 || true

    # Surface high-cost pending debt (silence_cost >= 3) — marks them so next
    # session's startup sees these as "closed-but-recorded" signals.
    if [ "${CLOSING_COST:-0}" -ge 3 ] && command -v jq >/dev/null 2>&1; then
        HIGH_DEBT_TOPICS=$(jq -r '[.silence_debt[] | select(.status=="pending" and .silence_cost>=3) | .topic] | .[]' "$ITR_STATE" 2>/dev/null || true)
        if [ -n "$HIGH_DEBT_TOPICS" ]; then
            while IFS= read -r topic; do
                [ -z "$topic" ] && continue
                itr_mark_debt_surfaced "$ITR_SID" "$topic" >/dev/null 2>&1 || true
                itr_log_event "$ITR_SID" silence_debt surfaced 3 "closing: $topic" >/dev/null 2>&1 || true
            done <<< "$HIGH_DEBT_TOPICS"
        fi
    fi

    # H11/H12 measurement: aggregate cascading + injection metrics into
    # cost_hints so itr_append_history picks them up in the digest.
    CASCADE_LOG="$STATE_DIR/cascading-events-${SESSION_ID}.jsonl"
    if [ -f "$CASCADE_LOG" ]; then
        BWD_COUNT=$(grep -c '"trigger":"BACKWARD"' "$CASCADE_LOG" 2>/dev/null || echo 0)
        BWD_COUNT=$(printf '%s' "$BWD_COUNT" | tr -d '[:space:]')
        [ -z "$BWD_COUNT" ] && BWD_COUNT=0
        itr_set_cost_hint "$ITR_SID" cascading_backward_count "$BWD_COUNT" >/dev/null 2>&1 || true
    fi
    INJECT_PEAK_FILE="$STATE_DIR/injection-bytes-peak-${SESSION_ID}"
    if [ -f "$INJECT_PEAK_FILE" ]; then
        INJ_PEAK=$(cat "$INJECT_PEAK_FILE" 2>/dev/null | tr -d '[:space:]')
        [ -z "$INJ_PEAK" ] && INJ_PEAK=0
        itr_set_cost_hint "$ITR_SID" injection_bytes_max "$INJ_PEAK" >/dev/null 2>&1 || true
    fi

    # Finalize → history → cleanup (v1.3.2).
    # Order matters: finalize AFTER all events are logged (including the
    # silence_debt/surfaced events added just above), so history digest
    # reflects the true final state.
    itr_finalize_metrics "$ITR_SID" >/dev/null 2>&1 || true
    HISTORY_APPENDED=false
    if itr_append_history "$ITR_SID" stop >/dev/null 2>&1; then
        HISTORY_APPENDED=true
    fi
    # Prune stale sessions (>30d). Runs once per session close — cheap.
    CLEANED_STATES=$(itr_cleanup_old_states 30 2>/dev/null || echo 0)

    # Detailed intrusiveness summary moved to silent log only (v1.7.2).
    # Session digest already written to intrusiveness-history.jsonl by
    # itr_append_history above. Carry-over surfacing happens on next session
    # via session-start.sh Signal 4 (AP3 pending debt).
fi

# H10 cross-contour surfacing — moved to silent file logging (v1.7.2).
# Metrics still written via cross-contour-surfaced-${SID}.txt and discoveries
# log; verbose Stop-message section dropped per user feedback. Audit available
# via /knowledge-audit and weekly digest.
CC_SURFACED_SID="${PAYLOAD_SID:-$SESSION_ID}"
CC_SURFACED_FILE="$STATE_DIR/cross-contour-surfaced-${CC_SURFACED_SID}.txt"

# Finalize session in registry — silent.
if [ "$HAS_REGISTRY" = true ]; then
    SUMMARY=""
    if [ "$HAD_STRUGGLE" = true ]; then
        SUMMARY="Session with errors/struggles"
    fi
    sr_finalize_session "$SUMMARY" 2>/dev/null || true
fi

# Compose minimal user-visible message.
#   - Default: silent (empty MESSAGE — no systemMessage emitted).
#   - HAD_STRUGGLE: short alert that errors happened (agent may /learn).
#   - PENDING_COUNT > 0: pending disagreements need closure on next session.
ALERTS=""
if [ "$HAD_STRUGGLE" = true ]; then
    ALERTS="${ALERTS}⚠️ В сессии были ошибки — рассмотри /learn. "
fi
if [ "${PENDING_COUNT:-0}" -gt 0 ] 2>/dev/null; then
    # Формулировка честная: запись означает «blocker-tier знание было активно и не
    # получило исхода», а не «агент не согласился». Ложная этикетка → алерт читают
    # как шум → контур перестаёт закрываться.
    ALERTS="${ALERTS}⚡ ${PENDING_COUNT} blocker-tier знание(й) без исхода — /learn (подтвердилось / устарело). "
fi

# Compile reminder (Фаза 3 L1→L2): nudge to run /compile when raw material has
# accumulated past the threshold. Free, gate-aligned (once per session).
COMPILE_REMINDER_LIB="$HOME/.claude/hooks/compile-reminder-lib.sh"
if [ -f "$COMPILE_REMINDER_LIB" ]; then
    # shellcheck source=/dev/null
    source "$COMPILE_REMINDER_LIB"
    COMPILE_NUDGE=$(compile_reminder_check "${PAYLOAD_SID:-$SESSION_ID}" 2>/dev/null || true)
    [ -n "$COMPILE_NUDGE" ] && ALERTS="${ALERTS}${COMPILE_NUDGE}"
fi

if [ -n "$ALERTS" ]; then
    # Видимый канал: кладём алерты в очередь, pending-alerts-surface.sh покажет их
    # на следующем UserPromptSubmit через additionalContext. Причина: Stop→systemMessage
    # не отображается в части UI (VS Code) — алерты уходили в пустоту (case-2026-06-14).
    printf '%s\n' "$ALERTS" >> "$STATE_DIR/pending-alerts.txt" 2>/dev/null || true
    printf '{"systemMessage": "%s"}\n' "$ALERTS"
fi
# Else: silent exit, no systemMessage. Detailed digest in intrusiveness-history.jsonl.

# Clean up THIS session's state files
# Note: disagreement-pending log is NOT cleaned — it persists across sessions
# until outcomes are closed via /learn. Agent reviews in startup context.
rm -f "$STATE_DIR/error_count_${SESSION_ID}" "$STATE_DIR/had_struggle_${SESSION_ID}" "$STATE_DIR/knowledge_injected_${SESSION_ID}" "$STATE_DIR/last_keywords_${SESSION_ID}" "$STATE_DIR/reformulation_last_fire_${SESSION_ID}" "$STATE_DIR/struggle-signatures_${SESSION_ID}.jsonl" "$STATE_DIR/cascading-events-${SESSION_ID}.jsonl" "$STATE_DIR/injection-bytes-peak-${SESSION_ID}" "$CC_SURFACED_FILE" 2>/dev/null

# Intrusiveness state: NOT deleted here — itr_cleanup_old_states above handles
# stale (>30d) files. Current session file survives so a re-opened terminal or
# follow-up session can still read it. Authoritative digest was already written
# to intrusiveness-history.jsonl.

exit 0
