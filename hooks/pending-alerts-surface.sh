#!/usr/bin/env bash
# pending-alerts-surface.sh — v1.0.0: UserPromptSubmit hook.
# Показывает алерты, отложенные session-collector (Stop) в очередь
# pending-alerts.txt, через ВИДИМЫЙ канал additionalContext.
#
# Зачем: Stop→systemMessage не отображается в части UI (VS Code) — все алерты
# session-collector (ошибки→/learn, pending disagreements, silence debt, нудж
# /compile) уходили в пустоту. Канал UserPromptSubmit→additionalContext виден
# надёжно (как knowledge-activator, intrusiveness). См. case-2026-06-14.
#
# Контракт:
#   stdin  = UserPromptSubmit payload (читается и игнорируется)
#   stdout = jq hookSpecificOutput.additionalContext (или пусто)
# Показ ровно один раз: очередь очищается сразу после чтения.

set -uo pipefail

# Consume stdin payload (unused) — не оставляем хвост в пайпе.
INPUT=$(cat 2>/dev/null || true)
: "${INPUT:=}"

STATE_DIR="${CLAUDSOUL_STATE_DIR:-$HOME/.claude/hooks/state}"
QUEUE="$STATE_DIR/pending-alerts.txt"

# Пусто/нет очереди → молчим. Нет jq → не рискуем сломать промпт.
[ -s "$QUEUE" ] || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Читаем и сразу очищаем (показ один раз даже при сбое ниже).
MESSAGE=$(cat "$QUEUE" 2>/dev/null || true)
: > "$QUEUE" 2>/dev/null || true

[ -n "$MESSAGE" ] || exit 0

printf '🔔 Отложенные уведомления системы (с прошлых сессий — канал session-collector):\n%s' "$MESSAGE" \
  | jq -Rs '{
      hookSpecificOutput: {
        hookEventName: "UserPromptSubmit",
        additionalContext: .
      }
    }'
exit 0
