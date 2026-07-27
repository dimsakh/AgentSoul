#!/usr/bin/env bash
# error-tracker.sh — PostToolUse[Bash]: при 2+ последовательных ошибках Bash останавливает, предлагает переосмыслить и записать /learn.
# Tracks consecutive Bash failures. At 2+ failures, sends systemMessage
# to Claude suggesting to stop, rethink, and use /learn after resolution.
#
# v1.5.8 — success-cascade → 💡 /learn + 📝 /retro auto-draft (steps 2.2 + 2.3).
#
# Input: JSON on stdin from Claude Code (PostToolUse event)
# Output: JSON with systemMessage (when triggered), or nothing

set -euo pipefail

PATHS_LIB="${PATHS_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths-lib.sh}"
if [ -f "$PATHS_LIB" ]; then source "$PATHS_LIB"; else : "${STATE_DIR:=$HOME/.claude/hooks/state}"; : "${LESSONS_DIR:=$HOME/.claude/global-lessons}"; fi
DRAFT_DIR="${ERROR_TRACKER_DRAFT_DIR:-$LESSONS_DIR/_drafts}"

# Session-specific state: each Claude Code session tracks its own errors
SESSION_ID="${CLAUDE_CODE_SESSION_ID:-$PPID}"
COUNT_FILE="$STATE_DIR/error_count_${SESSION_ID}"
STRUGGLE_FILE="$STATE_DIR/had_struggle_${SESSION_ID}"

mkdir -p "$STATE_DIR"

# Check jq availability
if ! command -v jq &>/dev/null; then
    exit 0
fi

# Read input from stdin
INPUT=$(cat)

# Extract tool result fields
# PostToolUse provides tool_result with stdout/stderr/exit_code
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_result.exit_code // .tool_result.exitCode // "0"')
STDERR=$(echo "$INPUT" | jq -r '.tool_result.stderr // ""')

# Normalize exit code to integer
EXIT_CODE="${EXIT_CODE:-0}"
if ! [[ "$EXIT_CODE" =~ ^[0-9]+$ ]]; then
    EXIT_CODE=0
fi

# Read current count
CURRENT_COUNT=0
if [ -f "$COUNT_FILE" ]; then
    CURRENT_COUNT=$(cat "$COUNT_FILE" 2>/dev/null || echo "0")
    if ! [[ "$CURRENT_COUNT" =~ ^[0-9]+$ ]]; then
        CURRENT_COUNT=0
    fi
fi

if [ "$EXIT_CODE" -ne 0 ]; then
    # Failure detected
    # Filter out false positives: grep/rg returning no matches (exit 1, empty stderr)
    if [ "$EXIT_CODE" -eq 1 ] && [ -z "$STDERR" ]; then
        # Likely grep no-match or similar — don't count
        exit 0
    fi

    # Increment counter
    NEW_COUNT=$((CURRENT_COUNT + 1))
    echo "$NEW_COUNT" > "$COUNT_FILE"

    if [ "$NEW_COUNT" -ge 2 ]; then
        # Mark that this session had a struggle
        echo "1" > "$STRUGGLE_FILE"

        cat <<'ENDJSON'
{
  "systemMessage": "⚠️ 2+ consecutive Bash failures detected.\n\n1. STOP — do not retry the same approach\n2. Re-read ALL error output from scratch\n3. List 2-3 alternative hypotheses\n4. Try a different approach\n5. After resolving — run /learn to record the lesson"
}
ENDJSON
    fi
else
    # Success
    if [ "$CURRENT_COUNT" -ge 2 ]; then
        # Resolved after struggle — suggest recording + auto-draft /retro skeleton
        ATTEMPTS="$CURRENT_COUNT"
        echo "0" > "$COUNT_FILE"

        # Step 2.3: auto-draft /retro skeleton (attempts ≥ 2 filter)
        mkdir -p "$DRAFT_DIR" 2>/dev/null
        TODAY=$(date +%Y-%m-%d)
        DRAFT_FILE="$DRAFT_DIR/case-${TODAY}-auto-draft.md"
        DRAFT_NOTE=""
        if [ ! -f "$DRAFT_FILE" ] && [ -w "$DRAFT_DIR" ]; then
            cat > "$DRAFT_FILE" <<DRAFT
---
date: ${TODAY}
type: case
status: draft
attempts: ${ATTEMPTS}
source: error-tracker auto-draft
---

# Case ${TODAY} — auto-draft

> Скелет сгенерирован автоматически после resolved-каскада (attempts=${ATTEMPTS}).
> Заполни через \`/retro\` или удали если случай тривиален.

## Что произошло

(опиши: что пытался сделать, что падало)

## Последовательность попыток

(${ATTEMPTS} попытки — восстанови по недавним Bash командам и их stderr)

## Что сработало

(финальный fix)

## Корневая причина vs симптом

(если разные — укажи оба)

## Урок / правило

(одно предложение, actionable)

## Якоря

- domain:
- trigger:
- stakes:
DRAFT
            DRAFT_NOTE="\n📝 Скелет авто-черновика сохранён: ${DRAFT_FILE/#$HOME/~}"
        fi

        # Step 2.2: 💡 /learn suggestion with attempts count
        MESSAGE="💡 Паттерн сложного fix (${ATTEMPTS} attempts) — стоит /learn?${DRAFT_NOTE}"
        if command -v jq >/dev/null 2>&1; then
            jq -n --arg msg "$MESSAGE" '{systemMessage: $msg}'
        else
            printf '{"systemMessage":"%s"}\n' "${MESSAGE//\"/\\\"}"
        fi
    else
        # Normal success — just reset counter
        echo "0" > "$COUNT_FILE"
    fi
fi
