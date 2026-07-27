#!/usr/bin/env bash
# changelog-reminder.sh — PreToolUse[Bash] на `git commit`: тихо напоминает
# добавить запись в CHANGELOG.md, если в staged diff есть изменения КОДА, а
# CHANGELOG.md в staged нет.
#
# Механизирует текстовое правило «каждое изменение → CHANGELOG» (канон D5:
# always-fire правило — лучше хуком, чем текстом). Scoped против ложных
# срабатываний (урок R3 docs-family-check): только реальный код (hooks/*.sh,
# mcp-server/**/*.py, scripts/*), исключая tests/ и сам CHANGELOG; docs-only /
# SESSION-only / test-only коммиты не триггерят. Silent (additionalContext),
# не блокирует — агент решает.
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

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
printf '%s' "$COMMAND" | grep -qE 'git[[:space:]]+commit' || exit 0

# Staged-файлы (если не в git-репо или нет staged — выходим тихо).
STAGED=$(git diff --cached --name-only 2>/dev/null) || exit 0
[ -z "$STAGED" ] && exit 0

# CHANGELOG уже в staged → ничего не нужно.
printf '%s\n' "$STAGED" | grep -qxE 'CHANGELOG\.md' && exit 0

# Есть ли реальный КОД (исключая tests/ и сам CHANGELOG)?
CODE=$(printf '%s\n' "$STAGED" | grep -vE '/tests?/' \
    | grep -E '^(hooks/[^/]+\.sh|mcp-server/.+\.py|scripts/.+|bin/.+)$' || true)
[ -z "$CODE" ] && exit 0

# Per-session throttle по набору staged-кода (тот же diff не напоминаем дважды).
SID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
KEY=$(printf '%s' "$CODE" | (command -v md5sum >/dev/null 2>&1 && md5sum || md5) 2>/dev/null | awk '{print $1}')
THROTTLE="$STATE_DIR/changelog-reminder-${SID}.txt"
if [ -f "$THROTTLE" ] && grep -qxF "$KEY" "$THROTTLE" 2>/dev/null; then exit 0; fi
printf '%s\n' "$KEY" >> "$THROTTLE" 2>/dev/null

MSG="📝 CHANGELOG: в staged есть изменения кода, но CHANGELOG.md не добавлен. Если это содержательное изменение — добавь запись в [Unreleased] (правило «каждое изменение → CHANGELOG»). Если это рефактор/чор без пользовательского эффекта — игнорируй."
jq -cn --arg m "$MSG" '{hookSpecificOutput: {hookEventName: "PreToolUse", additionalContext: $m}}'
exit 0
