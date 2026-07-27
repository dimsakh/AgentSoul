#!/usr/bin/env bash
# quality-gate-check.sh — PreToolUse DoD gate при `git commit`.
#
# v1.5.6 — первый auto-invocation trigger для /quality-gate скилла (C-класс tier 2
# из docs/skill-triggers-audit.md). Закрывает подразрыв C «agent-heuristic skills
# live только через memory»: DoD-секция SKILL.md теперь проверяется механически
# перед коммитом, а не памятью агента.
#
# Contract:
#   Input  (stdin): {session_id, tool_name, tool_input, cwd}  (PreToolUse JSON)
#   Output (stdout): {hookSpecificOutput: {hookEventName, additionalContext}} или пусто
#   Exit:  always 0 (degrade gracefully) — не блокирует commit, только silent marker
#
# Scope:
#   Проверяется только skills/**/SKILL.md, присутствующие в staged diff (guard R3).
#   Для каждого измененного SKILL.md считаем unchecked DoD чекбоксы `- [ ]` в
#   секции `## Definition of Done`. Хоть один незавершённый — inject.
#
# Silent by design (feedback_silent_correct_decisions.md): additionalContext, не banner.
# Agent решает применить — не blocker.
#
# Throttle: state/quality-gate-fired-<SID>.jsonl — per-session, ключ = md5(missing_skills).
# Тот же набор неполных SKILL.md не fired дважды; новый diff → новый fire.

set -uo pipefail

PATHS_LIB="${PATHS_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/paths-lib.sh}"
if [ -f "$PATHS_LIB" ]; then source "$PATHS_LIB"; else : "${STATE_DIR:=$HOME/.claude/hooks/state}"; fi

# Shared per-session throttle (single source — see throttle-lib.sh).
THROTTLE_LIB="${THROTTLE_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/throttle-lib.sh}"
if [ -f "$THROTTLE_LIB" ]; then
    # shellcheck source=/dev/null
    source "$THROTTLE_LIB"
else
    echo "Missing throttle-lib.sh: $THROTTLE_LIB" >&2; exit 1
fi

# Shared hash helper (single source — see hash-lib.sh).
HASH_LIB="${HASH_LIB:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hash-lib.sh}"
if [ -f "$HASH_LIB" ]; then
    # shellcheck source=/dev/null
    source "$HASH_LIB"
else
    echo "Missing hash-lib.sh: $HASH_LIB" >&2; exit 1
fi

mkdir -p "$STATE_DIR" 2>/dev/null

command -v jq >/dev/null 2>&1 || exit 0
command -v git >/dev/null 2>&1 || exit 0

INPUT=$(cat)
[ -z "$INPUT" ] && exit 0

TOOL_NAME=$(printf '%s' "$INPUT" | jq -r '.tool_name // ""' 2>/dev/null)
[ "$TOOL_NAME" = "Bash" ] || exit 0

COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""' 2>/dev/null)
[ -z "$COMMAND" ] && exit 0

# Match "git commit" as distinct command invocation.
echo "$COMMAND" | grep -qE '(^|[[:space:]]|;|&|\||\$\()git[[:space:]]+commit([[:space:]]|$)' || exit 0

SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null)
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // ""' 2>/dev/null)
[ -z "$CWD" ] && CWD="$PWD"

# git repo check
[ -e "$CWD/.git" ] || exit 0

# Staged SKILL.md files (paths relative to repo root).
# Guard R3: если в staged нет skills/*/SKILL.md — skip, не false-positive на docs-only.
STAGED_SKILLS=$(git -C "$CWD" diff --cached --name-only 2>/dev/null \
    | grep -E '^skills/[^/]+/SKILL\.md$')
[ -z "$STAGED_SKILLS" ] && exit 0

# Для каждого SKILL.md — проверить DoD.
# check_dod <file_path_relative>: echoes "rel|unchecked_count" если есть unchecked; иначе nothing.
check_dod() {
    local rel="$1"
    local abs="$CWD/$rel"
    [ -f "$abs" ] || return 0

    # Выделить DoD секцию: от строки "## Definition of Done" до следующего "## " или EOF.
    local section
    section=$(awk '
        /^## Definition of Done[[:space:]]*$/ { in_section=1; next }
        in_section && /^## / { in_section=0 }
        in_section { print }
    ' "$abs")

    [ -z "$section" ] && return 0

    # Считаем unchecked.
    local unchecked
    unchecked=$(printf '%s\n' "$section" | grep -cE '^[[:space:]]*-[[:space:]]*\[[[:space:]]\]' || true)
    unchecked=${unchecked:-0}

    [ "$unchecked" -gt 0 ] && printf '%s|%s\n' "$rel" "$unchecked"
}

INCOMPLETE=""
while IFS= read -r skill_rel; do
    [ -z "$skill_rel" ] && continue
    result=$(check_dod "$skill_rel")
    [ -z "$result" ] && continue
    if [ -z "$INCOMPLETE" ]; then INCOMPLETE="$result"
    else INCOMPLETE="$INCOMPLETE"$'\n'"$result"
    fi
done <<< "$STAGED_SKILLS"

[ -z "$INCOMPLETE" ] && exit 0

# Per-session throttle by hash of incomplete-set.
# hash_value() — из общего hash-lib.sh (источается в bootstrap выше)

INCOMPLETE_HASH=$(hash_value "$INCOMPLETE")
THROTTLE_FILE=$(throttle_file "$STATE_DIR" quality-gate "$SESSION_ID")
if throttle_seen "$THROTTLE_FILE" "$INCOMPLETE_HASH"; then
    exit 0
fi
throttle_mark "$THROTTLE_FILE" "$INCOMPLETE_HASH"

# Сформировать список для inject.
ITEMS=$(printf '%s\n' "$INCOMPLETE" | awk -F '|' 'NF==2 {printf "  • %s — %s unchecked DoD item(s)\n", $1, $2}')

CONTEXT=$(printf '🚦 Quality-gate: в staged diff есть SKILL.md с неполным Definition of Done:\n%s\nПравило: `/quality-gate` (C-класс tier 2) перед коммитом скилла — все DoD чекбоксы должны быть ✅ или явно waived.\nПроверь каждый SKILL.md; если задача действительно done — отметь чекбоксы и пересобери stage. Если осознанно пропускаешь (WAIVED) — добавь причину в commit message.' \
    "$ITEMS")

jq -n --arg ctx "$CONTEXT" '{
    hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
    }
}'

exit 0
