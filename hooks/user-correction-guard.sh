#!/usr/bin/env bash
# user-correction-guard.sh — PreToolUse: pause when user just corrected me, before
# I do another tool action.
#
# Failure mode from a document-handling session: собеседник сказал «этот пункт никто
# не просит»; через несколько сообщений я писал документ, в котором пункт снова стоял
# как основной. Correction в transcript есть, но retrieval цепочка не превратила её
# в pre-action check. Этот хук — explicit gate: после correction следующее tool action
# требует подтверждения reformulation'а.
#
# Detection: last user message contains correction tokens.
#   - «не так», «не туда», «не то»
#   - «опять», «снова», «ты только что»
#   - «я говорил/говорила», «я сказал/сказала»
#   - «забудь», «не надо», «отмена»
#   - «не понял меня»
#   - «wrong», «that's not what I meant», «again»
#
# After detection: emit permissionDecision:"ask" with a reminder to reformulate
# user's actual intent before proceeding (Пункт 0).
#
# Throttle: one ask per (session, last_user_message_hash). New correction →
# new ask. Same correction message → no spam.

set -uo pipefail

STATE_DIR="${STATE_DIR:-${CORRECTION_STATE_DIR:-$HOME/.claude/hooks/state}}"

mkdir -p "$STATE_DIR" 2>/dev/null

command -v jq >/dev/null 2>&1 || exit 0

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
TRANSCRIPT_PATH=$(printf '%s' "$INPUT" | jq -r '.transcript_path // ""' 2>/dev/null)

[ -z "$TRANSCRIPT_PATH" ] && exit 0
[ -f "$TRANSCRIPT_PATH" ] || exit 0

# --- Extract last user text message ---
# Pick last entry with type=user and a text content block (skip tool_result entries).
LAST_USER_TEXT=$(jq -r '
    select(.type == "user")
    | .message.content // []
    | map(select(.type == "text") | .text)
    | .[]?
' "$TRANSCRIPT_PATH" 2>/dev/null | tail -1)

[ -z "$LAST_USER_TEXT" ] && exit 0

# --- Match correction tokens ---
USER_LOWER=$(printf '%s' "$LAST_USER_TEXT" | tr '[:upper:]' '[:lower:]')

CORRECTION_REGEX='не[[:space:]]+так|не[[:space:]]+туда|не[[:space:]]+то[[:space:]]|не[[:space:]]+то$|опять[[:space:]]+ты|снова[[:space:]]+ты|ты[[:space:]]+только[[:space:]]+что|я[[:space:]]+говорил|я[[:space:]]+сказал|я[[:space:]]+же[[:space:]]+говорил|забудь|не[[:space:]]+надо[[:space:]]+было|отмена|не[[:space:]]+понял[[:space:]]+меня|day[[:space:]]+wasted|день[[:space:]]+потрачен|стоп[[:space:]]|остановись|wrong|that.?s[[:space:]]+not[[:space:]]+what'

echo "$USER_LOWER" | grep -qE -- "$CORRECTION_REGEX" || exit 0

# --- Throttle by message hash ---
hash_value() {
    if command -v md5sum >/dev/null 2>&1; then
        printf '%s' "$1" | md5sum | awk '{print $1}'
    elif command -v md5 >/dev/null 2>&1; then
        printf '%s' "$1" | md5
    else
        printf '%s' "$1" | cksum | awk '{print $1}'
    fi
}

MSG_HASH=$(hash_value "$LAST_USER_TEXT")
THROTTLE_FILE="$STATE_DIR/correction-fired-${SESSION_ID}.jsonl"
if [ -f "$THROTTLE_FILE" ] && grep -Fq "\"hash\":\"$MSG_HASH\"" "$THROTTLE_FILE" 2>/dev/null; then
    exit 0
fi
NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SNIPPET=$(printf '%s' "$LAST_USER_TEXT" | head -c 160 | tr '\n' ' ' | sed 's/"/\\"/g')
printf '{"date":"%s","hash":"%s","snippet":"%s"}\n' \
    "$NOW" "$MSG_HASH" "$SNIPPET" >> "$THROTTLE_FILE"

# --- Emit permissionDecision:ask ---
REASON=$(printf '🔁 User correction detected: «%s»\nПрежде чем продолжить tool action — Пункт 0:\n1. Переформулируй ЧТО сказал собеседник (не интерпретацию)\n2. Demand: какая реальная потребность за коррекцией?\n3. Подтверди понимание прежде чем действовать.\nПрецедент: я проигнорировал «этот пункт никто не просит» и через несколько сообщений снова поставил его в документ.' \
    "$SNIPPET")

jq -n --arg ctx "$REASON" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "ask",
        permissionDecisionReason: $ctx
    }
}'

exit 0
