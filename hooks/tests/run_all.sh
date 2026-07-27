#!/usr/bin/env bash
# run_all.sh — единый раннер всех хуковых тестов.
# До него «824/824 зелёных» нельзя было воспроизвести одной командой (F16):
# тесты с разнородными форматами итога приходилось запускать вручную и суммировать.
# Прогоняет каждый test_*.sh, суммирует pass/fail по файлам, единый exit code.
#
# Таймаут на файл (v1.11). Библиотечная функция, читавшая stdin при явно
# переданном аргументе, заморозила весь прогон на 10 минут: у раннера не было
# предела, и одно блокирующее чтение выглядело как «тесты идут», а не как отказ.
# Зависание — тоже провал и должно называться провалом. `timeout(1)` на macOS без
# coreutils отсутствует (pattern-shell-portability), поэтому watchdog на bash.

set -uo pipefail
cd "$(dirname "$0")" || exit 2

TEST_TIMEOUT="${TEST_TIMEOUT:-120}"

total=0
failed=0
failed_names=""
timed_out=""

# stdin закрыт намеренно: тест не должен зависеть от терминала, а открытая труба —
# ровно то окружение, в котором всё вставало.
run_with_timeout() {
    local script="$1" pid watch_pid rc=0
    bash "$script" >/dev/null 2>&1 </dev/null &
    pid=$!
    ( sleep "$TEST_TIMEOUT"; kill -9 "$pid" 2>/dev/null ) &
    watch_pid=$!
    wait "$pid" 2>/dev/null || rc=$?
    kill "$watch_pid" 2>/dev/null
    wait "$watch_pid" 2>/dev/null || true
    return "$rc"
}

for t in test_*.sh; do
    [ -f "$t" ] || continue
    total=$((total + 1))
    rc=0
    run_with_timeout "$t" || rc=$?
    if [ "$rc" -ne 0 ]; then
        failed=$((failed + 1))
        failed_names="$failed_names $t"
        # 137 = SIGKILL от watchdog: тест не упал, а завис.
        [ "$rc" -eq 137 ] && timed_out="$timed_out $t"
    fi
done

echo "Hook test files: $((total - failed))/$total passed"
[ -n "$failed_names" ] && echo "FAILED:$failed_names"
[ -n "$timed_out" ] && echo "ЗАВИСЛИ (убиты по таймауту ${TEST_TIMEOUT}с):$timed_out"
[ "$failed" -eq 0 ]
