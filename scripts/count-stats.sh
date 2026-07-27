#!/usr/bin/env bash
# ClaudSoul — единый источник истины по числам проекта.
#
# Числа в документах (README / CLAUDE.md / PLAN.md) дрейфовали, потому что
# правились вручную в нескольких местах. Этот скрипт считает их из файловой
# системы — единственный авторитетный источник. Запускать перед релизом и
# сверять статус-строки документов; CI-страж mcp-server/tests/test_doc_counts.py
# проверяет канонную строку README против этого вывода.
#
# Вывод — key=value (для парсинга) + человекочитаемая сводка в stderr.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

hooks=$(find hooks -maxdepth 1 -name '*.sh' ! -name '*-lib.sh' | wc -l | tr -d ' ')
libs=$(find hooks -maxdepth 1 -name '*-lib.sh' | wc -l | tr -d ' ')
skills=$(find skills -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
domains=$(find domains -maxdepth 1 -name '*.md' ! -name '_*' | wc -l | tr -d ' ')
bridges=$(find bridges -maxdepth 1 -name 'L*.md' | wc -l | tr -d ' ')
hook_test_files=$(find hooks/tests -maxdepth 1 -name 'test_*.sh' | wc -l | tr -d ' ')
mcp_test_files=$(find mcp-server/tests -maxdepth 1 -name 'test_*.py' | wc -l | tr -d ' ')

cat <<OUT
hooks=$hooks
libs=$libs
skills=$skills
domains=$domains
bridges=$bridges
hook_test_files=$hook_test_files
mcp_test_files=$mcp_test_files
OUT

echo "ClaudSoul: ${hooks} хуков (+${libs} библиотек), ${skills} скиллов, ${bridges} мостов, ${domains} доменов; тест-файлов: ${hook_test_files} хук + ${mcp_test_files} mcp" >&2
