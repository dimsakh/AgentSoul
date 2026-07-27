#!/usr/bin/env bash
# code-review-reminder.sh — PreToolUse[Bash] на `git commit`: тихо напоминает
# прогнать /code-review (адверсариальный ревью дифа), если в staged крупный
# КОДОВЫЙ дифф. Механизирует канон A6 (ревью дифа свежим контекстом перед
# «готово») — always-fire правило лучше хуком, чем текстом (канон D5).
#
# Порог «крупный»: > LINES изменённых строк ИЛИ > FILES кодовых файлов в
# web/lib | web/app | web/components (*.ts/*.tsx). Scoped против ложных
# срабатываний: docs-only / tests-only / мелкие правки не триггерят.
# Throttle per-session per-diff-hash (тот же дифф не напоминаем дважды) — не
# детектит факт запуска /code-review (маркера нет), но не спамит. Silent.
#
# Input  (stdin): {tool_name, tool_input, session_id} (PreToolUse JSON)
# Output (stdout): {hookSpecificOutput:{hookEventName, additionalContext}} или пусто
# Exit:  always 0 (degrade gracefully).

set -uo pipefail

PATHS_LIB="${PATHS_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths-lib.sh}"
if [ -f "$PATHS_LIB" ]; then source "$PATHS_LIB"; else : "${STATE_DIR:=$HOME/.claude/hooks/state}"; fi
mkdir -p "$STATE_DIR" 2>/dev/null

command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

LINES_THRESHOLD=80
FILES_THRESHOLD=4

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+commit' || exit 0

# numstat по staged кодовым файлам (web/lib|app|components, *.ts/*.tsx).
NUMSTAT=$(git diff --cached --numstat 2>/dev/null) || exit 0
[ -z "$NUMSTAT" ] && exit 0
CODE=$(printf '%s\n' "$NUMSTAT" | grep -E '	web/(lib|app|components)/.*\.(ts|tsx)$' || true)
[ -z "$CODE" ] && exit 0

FILE_COUNT=$(printf '%s\n' "$CODE" | grep -c . )
LINE_COUNT=$(printf '%s\n' "$CODE" | awk '{a+=$1; d+=$2} END{print a+d+0}')

# Крупный дифф?
if [ "$LINE_COUNT" -le "$LINES_THRESHOLD" ] && [ "$FILE_COUNT" -le "$FILES_THRESHOLD" ]; then
  exit 0
fi

# Throttle per-session per-diff-hash.
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
KEY=$(printf '%s' "$CODE" | (command -v md5sum >/dev/null 2>&1 && md5sum || md5) 2>/dev/null | awk '{print $1}')
THROTTLE="$STATE_DIR/code-review-reminder-${SID}.txt"
if [ -f "$THROTTLE" ] && grep -qxF "$KEY" "$THROTTLE" 2>/dev/null; then exit 0; fi
printf '%s\n' "$KEY" >> "$THROTTLE" 2>/dev/null

MSG="🔍 Крупный кодовый дифф (${LINE_COUNT} строк / ${FILE_COUNT} файлов в web/lib|app|components). Перед коммитом, если ещё не делал — прогони /code-review адверсариально на инварианты §4 (резерв/unreserve, шифрование PESEL/IBAN, recordStageTransition, i18n ×5). Канон A6. Если ревью уже был / правка тривиальна — игнорируй."
jq -cn --arg m "$MSG" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $m}}'
exit 0
