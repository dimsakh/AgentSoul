---
name: Переносимость оболочки — не полагайся на семантику конкретного shell в коде хуков и скиллов
description: Код для хуков и скиллов полагается на семантику конкретной оболочки (bash word-splitting, массивы, read -ra), но среда исполнения не гарантирована — Bash-инструмент Claude Code на macOS это zsh. Результат — молчаливые сбои. Писать переносимо или оборачивать в bash -c; парсинг делегировать jq/awk.
type: pattern
outcome: error
confidence: 5
impact: 3
intensity: 2
confirmed_count: 1
contradicted_count: 0
last_confirmed: 2026-07-06
source_cases:
  - case-2026-04-21-bash-tool-is-zsh.md
  - case-2026-06-20-zsh-for-loop-no-word-split.md
  - case-2026-06-20-zsh-nested-quotes.md
  - case-2026-06-21-grep-is-ugrep-not-gnu.md
  - "ProjectA security-gate.sh (2026-07-06): незакавыченный `$SEMGREP` (= путь с пробелом «…/My Project/…/.venv-security/bin/semgrep») словоделился на 2 аргумента → команда не найдена → пустой JSON → гейт дал ЛОЖНУЮ блокировку релиза. Ручной прогон работал (относительный путь без пробела). Фикс: `\"$SEMGREP\"` во всех вызовах. Всегда квотить переменные с путями (репо под «My Project» — пробел в пути гарантирован)."
status: active

# Контекстные якоря
domain: [shell_scripting, bash, zsh, hooks, skills, claude_code_internals, tooling]
situation: "writing_shell_command_for_hook_or_skill"
trigger: "shell_specific_construct_in_unverified_environment"
stakes: "silently_broken_command, tests_pass_but_real_env_fails"
actors: [agent, bash_tool]
environment: "macos, claude_code_bash_tool_is_zsh"
circumstances: "sourced_library_or_skill_command, execution_shell_not_guaranteed"
purpose: "portable_robust_tooling"
method: "bash_c_wrapper_or_delegate_to_jq_awk"
tags: [shell_compat, environment_assumption, read_ra, arrays, word_splitting, portability]

need: "avoid_shell_specific_breakage_in_hooks_and_skills"
urgency: "when_relevant"
availability: "unique"

related:
  - case-2026-04-21-bash-tool-is-zsh.md
  - case-2026-04-15-grep-set-e-crash.md
  - case-2026-04-22-pipefail-head-jq-jsonl.md
  - pattern-inside-out-blindness.md
edges:
  - specializes: pattern-inside-out-blindness.md
  - generalizes: case-2026-04-21-bash-tool-is-zsh.md

# Promotion & scope (v1.0.9)
promotion_tier: 2
scope: universal
origin_domain: shell_scripting

# Modification lineage
modification_history:
  - date: 2026-06-21
    kind: narrowed
    reason: "limitation «grep переносимы, обёртки не требуют» сужена — системный grep может быть ugrep со строгим ERE (литеральные { падают); правило теперь покрывает не только shell, но и идентичность CLI-инструмента"
    trigger_case: case-2026-06-21-grep-is-ugrep-not-gnu.md
fragile: false

# Blocker-tier
blocker: false

# Escalation (demand зафиксирован 2026-06-21, без инкремента confirmed — двойной учёт)
escalation_mechanism_needed: true
escalation_hint: "2026-06-21 (ClaudSoul, сессия f7715c0f): собеседник прямо требует инженерного решения — «кавычки в zsh постоянно возникающая проблема практически везде, с ней нужно что-то делать. При активации в другом проекте …». Второе+ напоминание о том же правиле = знание не держится на уровне text rule (см. principle-knowledge-in-the-world). Кандидат на blocker-tier / activator: detection_signals на Bash с read -ra / -a / небезопасным quoting → inject напоминания об обёртке bash -c. confirmed_count НЕ инкрементирован: проявление из той же сессии, что уже в source_cases (case-2026-06-20-zsh-nested-quotes, case-2026-06-21-grep-is-ugrep-not-gnu)."
---

## Правило

В коде хуков (`*-lib.sh`, `*.sh`) и в командах, которые скилл просит выполнить, **не полагайся на семантику конкретной оболочки**. Среда исполнения не гарантирована: Bash-инструмент Claude Code на macOS — это zsh (`$SHELL=/bin/zsh`), а sourced-библиотека может быть подключена в bash, zsh или хост-шеле.

Конкретно избегать (или оборачивать в `bash -c '...'`):
- `read -ra` / `read -a` — массивы (в zsh: `bad option: -a`)
- word-splitting unquoted скаляра (`for x in $var`) — в zsh `SH_WORD_SPLIT` выключен по умолчанию
- bash-массивы `${arr[@]}`, `mapfile`, `local -n`
- `[[ ... ]]` с regex-семантикой bash

**Делегируй парсинг в `jq` / `awk` / `sed`** — они одинаковы во всех оболочках.

## Why (два проявления)

1. **2026-04-21** — реализация `detection-signals-lib.sh` (blocker-tier): `for t in $allowed` полагался на bash word-splitting, в zsh не разбивал → тест падал. Мета-ирония: сбой при имплементации защиты от `pattern-inside-out-blindness`.
2. **2026-06-14** — команда поиска корней в процедуре `/compile` v1.1.0: `IFS=':' read -ra _r` → `bad option: -a` в zsh, массив пуст, `find` нашёл 0 файлов. Поймано тестом до записи в скилл (verify-before-acting).

3. **2026-06-21** — фильтрация вывода тестов через `grep -vE` со сложным ERE (литеральные `{`/`}`): дважды `ugrep: invalid repeat/syntax`. Системный `grep` на машине — **ugrep**, не GNU grep; ugrep строг к ERE (малформленный интервал `{` отвергает, GNU трактует как литерал). Вывод тестов терялся в умершем пайпе. Расширяет правило за рамки оболочки — на **идентичность CLI-инструмента**: имя `grep` это тоже бренд, не спецификация реализации. См. `case-2026-06-21-grep-is-ugrep-not-gnu.md`.

Общий корень — `pattern-inside-out-blindness`: фокус на внутренней логике команды, слепота к внешнему контейнеру (в какой оболочке/каким бинарём она исполняется). Имя «Bash tool» / «grep» — бренд, не спецификация.

## How to apply

- Любую команду со встроенными массивами/word-splitting — либо POSIX-переносимо, либо `bash -c '...'`.
- Перед тем как положиться на семантику shell — проверь среду один раз: `echo $SHELL; echo $ZSH_VERSION`.
- Команду для скилла/хука **тестируй до** записи как «готово».
- Парсинг структур — через `jq`/`awk`, не через shell-конструкции.

## Limitations

- Простые POSIX-команды (`grep`, `sed`, `find`, пайпы) с **простыми** паттернами переносимы. НО (уточнено 2026-06-21): сам бинарь `grep` может быть **ugrep** (строгий ERE) — сложный ERE с литеральными `{`/`}` или нестандартными конструкциями падает там, где GNU grep толерантен. Для извлечения сводки используй фиксированные подстроки (`grep -E "стр1|стр2"`) или читай сохранённый файл; литеральные скобки экранируй (`\{`); структуры парси `jq`/`awk`.
- Внутри явного `#!/bin/bash` скрипта, запускаемого как файл (а не source/Bash-инструмент), bash-семантика гарантирована — правило про неопределённую среду, не про любой bash-код.
