#!/usr/bin/env bash
# compile-reminder-lib.sh — v1.0.0 (Фаза 3 конвейера L1→L2): мягкое напоминание
# запустить /compile, когда накопилось ≥ порога сессий сырья с последней
# консолидации. Бесплатно (без headless-прогонов) и в духе L6-гейта: нудж
# раз в сессию, только при пересечении порога; запуск — решение пользователя.
#
# Контракт:
#   compile_reminder_check <session_id>   → echo текст нуджа (или пусто), return 0
#   compile_reminder_reset                 → обнуляет счётчик (вызывает /compile)
#
# Состояние ($HOME/.claude/hooks/state):
#   compile-pending           — счётчик сессий с последней консолидации
#   compile-counted-<sid>     — маркер: эта сессия уже учтена (счёт раз/сессию)
#   compile-reminded-<sid>    — маркер: в этой сессии уже напомнили (нудж раз/сессию)
#
# Порог: COMPILE_REMINDER_THRESHOLD (по умолчанию 5).

compile_reminder_check() {
    local sid="${1:-}"
    [ -z "$sid" ] && return 0

    local state_dir="$HOME/.claude/hooks/state"
    local pending_file="$state_dir/compile-pending"
    local counted_file="$state_dir/compile-counted-${sid}"
    local reminded_file="$state_dir/compile-reminded-${sid}"
    local threshold="${COMPILE_REMINDER_THRESHOLD:-5}"
    mkdir -p "$state_dir" 2>/dev/null || true

    local n=0
    [ -f "$pending_file" ] && n=$(tr -dc '0-9' < "$pending_file" 2>/dev/null)
    [ -z "$n" ] && n=0

    # Count this session exactly once (Stop fires many times per session)
    if [ ! -f "$counted_file" ]; then
        n=$((n + 1))
        printf '%s' "$n" > "$pending_file" 2>/dev/null || true
        : > "$counted_file" 2>/dev/null || true
    fi

    # Already nudged this session — stay silent (no nagging every Stop)
    [ -f "$reminded_file" ] && return 0

    if [ "$n" -ge "$threshold" ]; then
        : > "$reminded_file" 2>/dev/null || true
        printf '🧱 Накопилось %s сессий сырья с последней консолидации — пора /compile (кандидаты знаний в _drafts). ' "$n"
    fi
    return 0
}

compile_reminder_reset() {
    local state_dir="$HOME/.claude/hooks/state"
    mkdir -p "$state_dir" 2>/dev/null || true
    printf '0' > "$state_dir/compile-pending" 2>/dev/null || true
    rm -f "$state_dir"/compile-reminded-* "$state_dir"/compile-counted-* 2>/dev/null || true
    return 0
}

# When invoked directly: subcommand dispatch
if [ "${BASH_SOURCE[0]}" = "${0:-}" ]; then
    case "${1:-}" in
        check) compile_reminder_check "${2:-}" ;;
        reset) compile_reminder_reset ;;
        *) echo "usage: $0 {check <sid>|reset}" >&2; exit 2 ;;
    esac
fi
