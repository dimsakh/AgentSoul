#!/bin/bash
# throttle-lib.sh — v1.0.0
# Единый per-session механизм подавления повторов для хуков ClaudSoul.
#
# До v1.0.0 логика throttle была скопирована в 6 хуков с расходящимися именами
# поля ключа ("key" в blocker-tier-check, "hash" в docs-family/enrich/
# quality-gate/skill-review) и флаг-файлом без ключа в decompose-detector.
# Копипаст уже посеял рассинхрон (см. docs/health-audit-2026-06-20.md, F1).
# Эта библиотека — единый источник. Каноническое имя поля — "key".
#
# Throttle-файлы эфемерны: имя содержит SESSION_ID, читаются только в своей
# сессии тем же кодом — смена имени поля ничего исторического не ломает.
#
# Provides:
#   throttle_file <state_dir> <name> <sid>   → путь к jsonl по единой схеме
#                                               <state_dir>/<name>-fired-<sid>.jsonl
#   throttle_seen <file> <key>               → код 0 если <key> уже зафиксирован,
#                                               иначе код 1 (в т.ч. если файла нет)
#   throttle_mark <file> <key> [extra_json]  → дописать запись о <key>;
#                                               extra_json — опц. сырой фрагмент
#                                               доп. полей, напр. '"marker":"v1.0"'
#
# Паттерн использования (проверка и запись разнесены — как в существующих хуках):
#   F=$(throttle_file "$STATE_DIR" docs-family "$SESSION_ID")
#   if throttle_seen "$F" "$key"; then exit 0; fi   # уже было в этой сессии
#   ... хук делает работу / инжектит маркер ...
#   throttle_mark "$F" "$key"                        # отметить, что сработал
#
# Fail silently — источается из хуков, где ошибка не должна ронять процесс.

throttle_file() {
    printf '%s/%s-fired-%s.jsonl' "$1" "$2" "$3"
}

throttle_seen() {
    local file="$1" key="$2"
    [ -f "$file" ] && grep -Fq "\"key\":\"$key\"" "$file" 2>/dev/null
}

throttle_mark() {
    local file="$1" key="$2" extra="${3:-}"
    local now
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if [ -n "$extra" ]; then
        printf '{"date":"%s","key":"%s",%s}\n' "$now" "$key" "$extra" >> "$file"
    else
        printf '{"date":"%s","key":"%s"}\n' "$now" "$key" >> "$file"
    fi
}
