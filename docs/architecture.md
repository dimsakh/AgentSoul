# Когнитивная архитектура ClaudSoul

> Версия 1.3 (ревью 2026-05-06) — спецификация когнитивной модели AI-агента. Покрывает реализацию через v1.11.1 (🔐 Публикация наружу как инструмент с гейтом: `scripts/publish-public.sh` собирает снимок из `git archive HEAD`, вычищает по `scripts/publish/exclude.txt`, применяет `redact.sed` и проверяет результат по `forbidden.txt` — гейт работает на выходе и считает собственные срабатывания, пустой список запретов роняет прогон. Попутно закрыта утечка: тег `v1.7.5` в публичном репозитории содержал незачищенное дерево, репозиторий пересоздан одним чистым коммитом. Причина инструмента структурная — `regen-seed.py` копирует frontmatter байт-в-байт из рабочей базы, поэтому имена клиентов возвращаются в seed при каждом релизе), v1.8.0 (🔁 cross-hook recall gate — level-3 эскалация pattern-inside-out-blindness: blocker-tier-check.sh при Write после сработавшего guard инжектит cross_hook_recall_reminder, домен-независимый инвариант вместо whack-a-mole по detection_signals; релиз также свёл накопленный с v1.7.5 [Unreleased] — конвейер /compile L1→L2, артефактные /decompose+/quality-gate, pending-alerts видимый канал, /retro why-каскад; 824/824 теста), v1.7.5 (🚀 Подготовка к публичному релизу — chore-релиз без изменения runtime: этап 1 убрал SESSION.md и docs/internal-doc.md из git трекинга, этап 3 заменил личные пути /Users/user на ~, этап 4 добавил dependency check в начало install.sh, этап 5 — scripts/smoke-test.sh 7-категорийная проверка установки; открытые этапы 2/6/7 требуют решения), v1.7.4 (🛡️ install.sh CLAUDE.md marker-based merge: `<!-- ClaudSoul: managed-start/end -->` маркеры в deployed, `install.sh` заменяет только между ними, контент пользователя снаружи сохраняется; 4 случая обработки; +26 ассертов в `test_claude_md_merge.sh`), v1.7.3 (🤫 knowledge-activator silent через `hookSpecificOutput.additionalContext` вместо `systemMessage` — больше нет блока полстраницы серого текста на каждом первом PreToolUse), v1.7.2 (🤫 убран verbose Stop-вывод session-collector — INTERLOCUTOR/INTRUSIVENESS/Cross-contour секции были self-reflection cue для агента, но Stop fires ПОСЛЕ stop'а и шум без действия; теперь по умолчанию silent, короткие алерты только при HAD_STRUGGLE/pending disagreements), v1.7.1 (🔧 reformulation-tracker SIGPIPE fix: `tail -r FILE | while ... break` обёрнут в `set +o pipefail` чтобы exit 141 не убивал хук — закрывает «UserPromptSubmit hook error: No stderr» на каждом сообщении), v1.7.0 (📐 Calibration v1.4.0 applied: `ITR_DEFAULT_PROACTIVE_MAX 2 → 3` на основе 575 событий бэкфилла из 98 сессий — 66% chunks упирались в потолок при 60% acceptance. `gentle_max`, `distressed` пороги и веса cost-осей не калибровались по видимости/нулевым проксям в архивах — принцип «калибровать что видишь, не что хочется»), v1.6.8 (🧹 rules/CLAUDE.md optimization + claudsoul-context-pointer path-recall: master 641 → 556 строк через drift sync 4 блоков и Category A shrinking 12 секций до references; claudsoul-context-pointer detection расширена с substring-only на 3 класса — project name + path-based `*global-lessons*` + filename-based `*principle/pattern/entity-*.md*`; case-2026-05-05-deployed-artifact-action-blindness, 20-е проявление pattern-inside-out-blindness, action-blindness vs model-blindness 19-го; install.sh::CLAUDE.md jq-merge fix → backlog v1.7.x), v1.6.7 (📚 ClaudSoul context pointer — закрытие cross-directory blindness: `hooks/claudsoul-context-pointer.sh` UserPromptSubmit, substring match на claudsoul/клод соул в `.user_prompt` → инжект секции «Текущий статус» из project CLAUDE.md когда cwd снаружи проекта; case-2026-05-05-claudsoul-blindness-from-home, 19-е проявление pattern-inside-out-blindness, новое измерение — cross-directory blindness: глобальная модель устаревает относительно живого project CLAUDE.md, Claude Code загружает CLAUDE.md иерархично по cwd; уровень 3 embedded-ness — mechanical injection, не text rule), v1.6.6 (📊 Backfill aggregate digest: v1.4.0 калибровка получила конкретные числа — 98 digest строк из 575 raw events v1.6.4, calibrate.py рекомендует proactive_max 2→3 + gentle сужение, distressed не наблюдался в архивах), v1.6.5 (🔤 Output language check level 2b — закрытие feedback latency: уровень 2 embedded-ness разделён на L2a UserPromptSubmit + L2b PreToolUse, burst-grained closure; case-2026-04-25-level-2-feedback-latency, 17-е проявление pattern-inside-out-blindness, новое измерение — темпоральный pattern собственной работы), v1.6.4 (📦 Backfill intrusiveness — снят блокер v1.4.0 калибровки одним прогоном на 309 архивных транскриптах; 575 событий из 98 сессий за 20 дней; gentle acceptance 21%, proactive acceptance 60% — прямые сигналы для калибровки defaults), v1.6.3 (🔤 Output language check — первый хук на свойство output агента; закрывает новое измерение inside-out-blindness — «output agent ≠ detectable»: класс ошибок нарушения output-level rules через post-output scanner + feedback loop в следующий user turn), v1.6.2 (🛑 docs-family-check R3 calibration — удалён sweep `docs/*.md` после первого live fire на 15 frozen docs, остаётся whitelist 5 live + env `DOCS_FAMILY_LIST`; принцип action-gate обязан калиброваться на живом шуме после proof-of-active), v1.6.1 (🛠️ Install drift — proof-of-active: реальный jq merge в install.sh + Signal 6 в session-start для cross-check installed vs registered; формализован уровень 4 embedded-ness поверх трёх уровней из principle-knowledge-in-the-world), v1.6.0 (Active analogy surfacing — полный цикл детект → async semantic ranker → union filter consumer → H10 secondary metric; разрыв D переходит в ✅ на расширенной дуге), v1.5.8 (C-класс nice-to-haves — разрыв C закрыт), v1.5.8-alpha (⚙️ AP3 silence debt surfacing), v1.5.7 (⚙️ AP2 distressed state axis + `/enrich`), v1.5.6-alpha (⚙️ первый affect prosthetic — `hooks/trust-guard.sh` PreToolUse на destructive Bash signatures без явной auth в последних N user сообщениях → silent `🛡️ Trust-guard` marker; принцип `principle-affect-as-engineering.md` — Разрыв A впервые начинает закрываться не правилом, а инженерным хуком; specializes principle-knowledge-in-the-world в domain affect, где уровень 1 text rule структурно недостаточен потому что чтение правила не replaces affective brake), v1.5.5-alpha+1 (engineering escalation mechanism — `knowledge-audit-digest.sh` во втором проходе surface'ит blocker-tier patterns, чей `confirmed_count ≥ escalation_threshold`; принцип `principle-knowledge-in-the-world.md` — три уровня embedded-ness fix'а; закрывает 15-е проявление pattern-inside-out-blindness через рекурсивную meta-defense), v1.5.5-alpha (docs-family action-gate — `docs-family-check.sh` на `git commit`, закрывает knowledge-action gap для cross-document rules; plus rules/CLAUDE.md §Source-check — перед post-incident фразой назвать механизм системы), v1.5.4-alpha (первая C-класс heuristic — `/decompose` multi-step detector), v1.5.3-alpha (periodic digests — weekly knowledge-audit + monthly bridge-health), v1.5.2-alpha (`/save` activity machine log), v1.5.1-alpha (startup signals — `/init-project` + `/reload` auto-hints), v1.5.0-alpha (narrative auto-trigger — разрыв C, «одна команда на жизнь проекта» = `install.sh`), v1.3.9 (cross-contour consumer — разрыв D, паттерн ↔ entity), v1.3.8 (chunk boundary через PreCompact), v1.3.7 (H9/H10/H11/H12 instrumentation), v1.3.6 (proactive event detection + install drift fix), v1.3.5 (auto-collection gentle outcomes), v1.3.4 (blocker-tier silent pre-action check), v1.3.3 (state classifier), v1.2.0-rc.3 (3D Universe), v1.0.11 (session cleanup regression fix), v1.0.2-v1.0.9 (Phase 10 каскадность).

---

## 1. Философия

### Центральная метафора

Человеческая память — не база данных. Это **ассоциативная сеть**, где:
- Связи мультимодальны (через контекст, эмоцию, сенсорику)
- Эмоция определяет вес и скорость запоминания
- Воспоминание реконструируется в текущем контексте
- Забывание — это фильтрация шума, а не потеря

ClaudSoul стремится к той же модели, адаптированной для AI-агента. **Система не ограничена программированием** — она работает с любым знанием: разработка, бизнес, исследования, управление, коммуникации.

### Базовые принципы

1. **Ассоциативность** — знание активируется контекстом, а не запросом
2. **Реконструкция** — при каждом обращении знание переосмысляется в текущем контексте
3. **Эволюция** — знания растут, обобщаются, устаревают и отмирают
4. **Универсальность** — система работает в любом домене, не только в разработке
5. **Неопределённость** — любой вывод может быть ошибочным (см. §10)

---

## 2. Карта слоёв

```
┌─────────────────────────────────────────────────┐
│           Co-Cognition (Совместное мышление)     │  ← Уровень 7
│  Человек + Агент = понимание, которого нет       │
│  ни у одного по отдельности                      │
├─────────────────────────────────────────────────┤
│           Predictive (Предиктивность)            │  ← Уровень 6
│  Предвидеть следующий шаг, готовиться заранее    │
├─────────────────────────────────────────────────┤
│           Meta-Cognition (Метакогниция)          │  ← Уровень 5
│  Рефлексия: правильно ли я учусь?               │
├─────────────────────────────────────────────────┤
│           Thought Trajectory (Траектория мысли)  │  ← Уровень 4
│  Куда движется мышление собеседника?             │
├─────────────────────────────────────────────────┤
│           Communication (Коммуникативный слой)   │  ← Уровень 3
│  Intent gaps, decision trails, satisfaction      │
├─────────────────────────────────────────────────┤
│           Knowledge (Система знаний)             │  ← Уровень 2
│  Case → Pattern → Principle, FSRS decay,         │
│  контекстные якоря, кросс-доменный перенос       │
├─────────────────────────────────────────────────┤
│           Persistence (Персистентность)           │  ← Уровень 1
│  SESSION.md, CLAUDE.md, global-lessons,          │
│  memory, git history                             │
└─────────────────────────────────────────────────┘
```

Слои — не стек, а **сеть**. Нижние создают основу для верхних (без персистентности нет знаний, без знаний нет коммуникации), но реальные данные текут во все стороны. Навыки рождаются не внутри слоёв, а **на мостах между ними** (см. §10). Коммуникативный навык — не свойство Layer 3 и не свойство Layer 6, а эмерджентное свойство их взаимодействия.

| Слой | Вопрос | Входы | Выходы | Статус |
|------|--------|-------|--------|--------|
| 1. Persistence | Как пережить конец сессии? | Контекст работы, PreCompact | SESSION.md, memory, git, auto-scanner, session registry (UUID), chunk boundary snapshots (v1.3.8) | ✅ Реализован |
| 2. Knowledge | Что мы знаем и насколько уверены? | События, ошибки, успехи | Cases, patterns, principles + demand + tier/scope + lineage + blocker-tier + cross-contour surfacing (v1.3.9) + async semantic ranker + union filter + H10 surfacing metric (v1.6.0) | ✅ Реализован |
| 3. Communication | Что происходит между агентом и собеседником? | Диалог, реакции, решения | Intent gaps (literal/pragmatic/strategic), decision patterns, interlocutor model, auto-collection outcomes (v1.3.5/6), distressed state axis как infrastructural brake (v1.5.7) | ⚡ Частично (retro + classifier + auto-collection outcomes; decision patterns и satisfaction signals всё ещё retrospective) |
| 4. Thought Trajectory | Куда движется мышление собеседника? | Последовательность сообщений | Точки T_n + каскадные гипотезы H_n + предсказания | ⚡ Частично (через правила + шаблон) |
| 5. Meta-Cognition | Правильно ли мы учимся? | Метрики, аномалии, тренды 7d/30d + intrusiveness history + H9-H12 инструментация | Коррекции процесса и знаний, калибровка gate | ✅ Реализован (metrics-collector + delta trending + intrusiveness trends v1.3.2 + H9-H12 v1.3.7 + chunk boundary в калибровочном окне v1.3.8) |
| 6. Prediction | Что будет дальше? | Trajectory + Interlocutor Model + 4D axes (confidence × value × cost × state) | Каскадные P_n + downgrade ladder (proactive_action / gentle_suggestion / silent_prep / ignore) | ✅ Реализован (4D gate v1.3 + active state v1.3 + state classifier v1.3.3 + blocker-tier v1.3.4 + auto-collection outcomes v1.3.5/6) |
| **Мосты** | **Какие навыки рождаются на пересечении?** | **Выходы нескольких слоёв** | **Эмерджентные способности (§10)** | **⚡ 4 ✅ / 3 ⚡ / 8 📋** |
| 7. Co-Cognition | Как мыслить вместе? | Всё вышеперечисленное | Совместное понимание + disagreement outcome logging (v1.0.3) | ⚡ Подтверждён (+ каскадные исходы ⚡-событий) |

---

## 3. Слой 1: Persistence (Персистентность)

### Назначение
Контекст умирает, когда сессия заканчивается. Persistence — механизм выживания знаний между сессиями.

### Входы
- Текущий контекст работы (файлы, решения, результаты)
- Ключевые события сессии (ошибки, инсайты, договорённости)

### Выходы
- `SESSION.md` — хронология сессий, текущее состояние, следующие шаги
- `CLAUDE.md` — проектные правила и структура
- `~/.claude/global-lessons/` — кросс-проектная база знаний
- `~/.claude/projects/.../memory/` — проектная память
- `~/.claude/sessions/` — реестр сессий (lifecycle, дельты, кросс-сессионная осведомлённость)
- Git history — атомарные коммиты с контекстом

### Формат данных

**SESSION.md:**
```markdown
## [дата] — [тема]
### Что сделано
### Текущее состояние
### Следующие шаги
### Ключевые решения
```

### Алгоритм
1. **Начало сессии** → прочитать CLAUDE.md, SESSION.md, memory; зарегистрировать сессию в реестре; показать startup context (дельта, параллельные, прерванные)
2. **Во время работы** → обновлять SESSION.md после каждого значимого шага; обновлять knowledge_delta в реестре при записи знаний
3. **Конец сессии** → финальное обновление SESSION.md, сохранение знаний; финализация сессии в реестре (registry.jsonl + last-session.json)

### Мультисессионность

Несколько сессий Claude Code могут работать параллельно (терминал + VS Code + несколько проектов). Session Registry (v0.5.1) решает ключевые проблемы:

- **SESSION.md** — один файл на проект, несколько сессий пишут в него. Решение: append-only, каждая запись содержит timestamp.
- **State файлы хуков** — привязаны к `SESSION_ID` (стабильный UUID из stdin payload SessionStart hook, v1.0.10). До v1.0.10 использовался PPID — он менялся при smart-rerun и одну сессию считали за несколько. Cleanup v1.0.11: PID-файлы из дерева предков текущего процесса считаются pre-fix дубликатами и удаляются при startup. Stale-файлы чистятся автоматически (>24ч).
- **global-lessons** — общая база, записи из одной сессии не видны другой до перезапуска. **Session Registry частично снимает это ограничение:** при старте новой сессии startup context показывает knowledge_delta из завершённых сессий, а детекция параллельных сессий предупреждает о возможных конфликтах.

### Session Registry (v0.5.1)

Машиночитаемый реестр сессий — дополнение к человекочитаемому SESSION.md.

**Проблема:** Каждая сессия изолирована. Не знает, когда была предыдущая, что в ней произошло, есть ли параллельные сессии. SESSION.md растёт бесконечно и дорог по токенам для чтения целиком.

**Решение:** Структурированный реестр с быстрым доступом к дельте.

#### Структура

```
~/.claude/sessions/
├── registry.jsonl          # Append-only лог ВСЕХ завершённых сессий
├── last-session.json       # Кэш: последняя завершённая сессия (быстрый доступ)
└── active/                 # Текущие живые сессии
    └── {session_id}.json   # Одна запись на активную сессию
```

#### Формат записи

```json
{
  "session_id": "abc-123",
  "project": "/path/to/project",
  "project_name": "ClaudSoul",
  "started_at": "2026-04-15T18:30:00Z",
  "ended_at": "2026-04-15T20:15:00Z",
  "duration_min": 105,
  "status": "completed",
  "summary": "Phase 5: skill contract",
  "knowledge_delta": {
    "created": ["case-new.md"],
    "updated": ["pattern-x.md"],
    "confirmed": [],
    "contradicted": []
  },
  "commits": ["fd6ad0b"],
  "files_changed": 12,
  "notes": []
}
```

#### Lifecycle

| Момент | Компонент | Действие |
|--------|-----------|----------|
| Старт сессии | knowledge-activator (FIRST_FIRE) | `sr_register_session` → создаёт `active/{session_id}.json` |
| Запись знания | /learn, /retro | `sr_update_knowledge` → обновляет `knowledge_delta` |
| Коммит | /save, вручную | `sr_update_commits` → добавляет hash |
| Конец сессии | session-collector (Stop) | `sr_finalize_session` → `active/` → `registry.jsonl` + `last-session.json` |
| Прерывание | Следующая сессия | Stale `active/` (>6ч) → помечается как interrupted |

#### Startup context

При старте новой сессии knowledge-activator инжектит:

1. **Последняя сессия** — когда, какой проект, длительность, summary
2. **Knowledge delta** — что появилось/обновилось с прошлого раза
3. **Параллельные сессии** — кто сейчас активен (из `active/`)
4. **Прерванные сессии** — stale `active/` файлы (>6ч) — вероятно, незавершённая работа

Это даёт агенту 10 строк контекста вместо чтения 400+ строк SESSION.md.

#### Связь с другими компонентами

- **SESSION.md** — остаётся как человекочитаемый подробный лог. Registry — машиночитаемый индекс.
- **Auto-scanner** — может использовать registry для определения активности проектов (вместо эвристик по git log).
- **Metrics-collector** — может считать sessions/week, avg_duration, knowledge_per_session.
- **/reload** — при ручном вызове может показать дельту из registry вместо чтения всех файлов.

### Chunk boundary (v1.3.8) — сессия как цепочка chunk'ов

**Проблема.** Накопительная телеметрия (`intrusiveness-history.jsonl`, digest сессии) пишется только на Stop. Между стартом сессии и Stop может произойти несколько компактов: транскрипт схлопывается в summary, но state хуков (`intrusiveness-<sid>.json`, event log) продолжает жить. Если Stop не случается (context exhaustion, переход на новую сессию, краш IDE) — все накопленные за этот chunk метрики **растворяются**. Для калибровочного окна v1.4.0 (≥30 закрытых сессий) это означало бесконечно долгий набор выборки.

**Решение.** `hooks/pre-compact-finalizer.sh` (PreCompact event) пишет silent snapshot digest на каждом компакте — параллельно Stop-финализатору, но **не очищая state** (компакт ≠ конец сессии). Каждая JSONL-строка в `intrusiveness-history.jsonl` теперь несёт поле `boundary: "stop" | "precompact"`, позволяя аналитике (metrics-collector, `/knowledge-audit` 8b) либо различать chunk'и, либо агрегировать их как единое окно.

```
session timeline:
  start ──┬── work ──┬── compact ──┬── work ──┬── compact ──┬── work ──┬── Stop
          │          │  (snapshot) │          │  (snapshot) │          │  (snapshot)
          │          │  boundary:  │          │  boundary:  │          │  boundary:
          │          │  precompact │          │  precompact │          │  stop
          └──────────┴─────────────┴──────────┴─────────────┴──────────┘
          state лежит поверх границ — cost_peaks, debt, events не сбрасываются
          history.jsonl получает 3 строки вместо 1 — chunk'и учтены
```

**Почему silent.** Snapshot на компакте не инжектится в контекст (компакт — момент сжатия, не напоминания). Агент узнаёт о новом chunk'е только через startup context следующей сессии, когда metrics-collector увидит новые строки.

### Статус реализации
✅ Реализован. Хуки поддерживают мультисессионность (v0.3.2). SESSION.md — append-only через `/save`. Автосканер (v0.4.0) — launchd LaunchAgent сканирует проекты каждые 4ч (read-only), результаты инжектятся в следующую сессию. Session Registry (v0.5.1) — реестр сессий с lifecycle, дельтами, детекцией параллельных/прерванных сессий. Stable session IDs (v1.0.10) — UUID из stdin payload SessionStart hook, устранение inflated counters (1 сессия ≠ N параллельных). Cleanup regression fix (v1.0.11) — pre-fix PID-файлы из дерева предков распознаются и удаляются. Chunk boundary (v1.3.8) — `pre-compact-finalizer.sh` пишет snapshot digest на каждом PreCompact, `boundary: stop|precompact` поле в JSONL, +6 ассертов в `test_intrusiveness_lib` (158/158).

**Расширение v1.5.x — persistence через event-driven auto-invocation:**
- **v1.5.1-alpha (startup signals).** `session-start.sh` при старте сессии пишет `startup-signals-${SID}.txt`: (1) если в `cwd` нет `CLAUDE.md` → hint «запустите `/init-project`»; (2) если mtime файлов в `~/.claude/global-lessons/` > `SR_LAST_SESSION.ended_at` → hint «База знаний обновилась: +N файлов, рекомендую `/reload`». Портабельно через BSD/GNU `find | xargs stat -f '%m' | awk`. `knowledge-activator` инжектит сигналы в первый PreToolUse одним пакетом с narrative.
- **v1.5.2-alpha (activity machine log).** `activity-flush-lib.sh` на Stop парсит transcript одним jq-проходом и пишет `.claude-docs/session-activity.md` (append-only). Tool counts по имени, file_paths из Edit/Write/MultiEdit (unique basenames, без утечки полных путей), git commits за 4ч. Разведены narrative (SESSION.md — human-readable) и machine log — каждый выживает независимо, `/save` больше не требуется для фиксации активности.
- **v1.5.3-alpha (periodic digests).** `hooks/knowledge-audit-digest.sh` (launchd, вс 03:15) — counts по типам знаний, reliability distribution, FSRS buckets fresh/due/overdue/critical, top 5 overdue, trend line → `~/.claude/global-lessons/_audit-history/audit-YYYY-Www.md`. `hooks/bridge-health-digest.sh` (launchd, 1-е 03:30) — status counts, per-status listing → `~/.claude/bridges-history/health-YYYY-MM.md`. Hint через `state/audit-hint.txt` + `state/bridge-hint.txt` → session-start startup-signals pipeline. **Mechanical vs analytical split:** digest автоматизирован (механика), `/knowledge-audit` + `/bridge-health` остаются LLM-скиллами для качественного разбора — digest не заменяет скилл, а питает его контекст.
- **v1.5.5-alpha (docs-family action-gate).** `hooks/docs-family-check.sh` (PreToolUse на Bash) детектит `git commit` + scan staged diff на version marker + coverage-check по docs family. Missing → silent inject перечня через `additionalContext`. **Урок из case-2026-04-23-memory-without-action-gate:** memory `feedback_docs_means_all_docs.md` существовала 4 релиза (v1.5.1-5.4), но не сработала ни разу — её триггер был фразой («обнови документацию»), а акция version-bump была без фразы. Этот хук конвертирует passive memory в procedural gate: triggering не на phrase-match, а на semantic-action (git commit с version marker в diff). Закрывает подкласс knowledge-action gap, где правило — про класс действий, а не про содержание файла. **Plus rules/CLAUDE.md §Communication (v0.3) — Source-check:** перед post-incident фразой («надо X / нужен Y / не хватает Z» после ретро/ошибки) назвать конкретный механизм системы, породивший вывод (хук, memory, knowledge, state); пустая ссылка = model-generated, not system-derived. Закрывает case-2026-04-23-model-vs-system-source-blindness: LLM-инерция жанра пост-инцидентного дискурса неотличима по форме от метакогниции — нужна явная source attribution.
- **v1.5.5-alpha+1 (engineering escalation mechanism).** Рекурсивная meta-defense против inside-out-blindness самого паттерна. `knowledge-audit-digest.sh` во втором проходе сканирует `pattern-*.md` + `principle-*.md` на `blocker: true` + parseable `escalation_threshold` + `confirmed_count ≥ threshold` — при совпадении пишет секцию `## ⚠️ Engineering escalation needed` в digest, hint `🛠️ Engineering escalation: N blocker-tier pattern(s) crossed escalation_threshold` в `state/audit-hint.txt` с приоритетом выше overdue/trend → session-start startup-signals. **Урок из case-2026-04-23-text-rule-vs-mechanism (15-е проявление pattern-inside-out-blindness):** fix для case-2026-04-23-model-vs-system-source-blindness был text rule в rules/CLAUDE.md §Source-check — тот же memory-as-resource failure mode, что и оригинальная memory `feedback_docs_means_all_docs.md`. Правило-в-тексте полагается на «future-agent прочитает и применит», правило-в-механизме активируется автоматически на семантическую акцию. Если blocker-tier pattern продолжает подтверждаться несмотря на detection_signals — значит они неполны или есть новое измерение; система не должна полагаться на то, что человек заметит. Embedded реализация: `escalation_threshold` + `escalation_hint` в frontmatter, digest surface'ит сам. Новый [principle-knowledge-in-the-world](../.claude/global-lessons/principle-knowledge-in-the-world.md) (Don Norman, promotion_tier 3, scope universal) формализует три уровня embedded-ness fix'а после подтверждённого инцидента: **(1) text rule** (memory-as-resource, хрупкое — черновик формулировки, до реализации механизма), **(2) activator injection** (правило в knowledge-base с anchors, попадает в inject при context match — средняя надёжность), **(3) blocker-tier detection** (detection_signals + PreToolUse/PostToolUse hook с silent inject — высокая надёжность). Fix после подтверждённого инцидента никогда не должен оставаться на уровне 1.

Эти пять изменений превращают persistence из passive container'а (SESSION.md, git) в **auto-invocation fabric**: агент не обязан помнить «запусти `/save`», «проверь нет ли CLAUDE.md», «пора сделать audit», «обнови всю семью docs на version bump», «pattern продолжает подтверждаться — нужна новая defense layer» — всё это silent signals, surfaced в момент, когда релевантно. **Memory как passive data становится action-gate**: правило активируется на семантическую акцию, а не только на ключевую фразу. **Pattern как passive catalog становится self-escalating knowledge**: blocker-tier сам заявляет о необходимости следующей итерации engineering, когда накопленный опыт показывает, что предыдущая defense layer уже не держит.

---

## 4. Слой 2: Knowledge (Система знаний)

### Назначение
Извлекать уроки из событий, хранить их структурированно, активировать в нужном контексте, обобщать и фильтровать устаревшее.

### Два контура обучения

```
Контур 1 (v0.1–v0.7):   ДЕЙСТВИЕ → ошибка/успех → case → pattern → principle
                         Операционный опыт: агент учится на своих действиях

Контур 2 (v1.1+):       МАТЕРИАЛ → entity → fact → relation → discovery
                         Энциклопедический: агент учится из внешних источников
                                    ↕
                              Domain Graph (общий индекс)
```

**Контур 1** — case/pattern/principle с confidence, FSRS, якорями. Реализован.
**Контур 2** — entity/fact/relation с provenance, behavioral inference, temporal validity. **Реализован** (v1.1.7): рабочая база 35 entity / 5 fact / 64 relation, код `mcp-server/ingest/`, скиллы `/ingest` `/entity` `/wiki` `/enrich`. Спецификация: `docs/entity-knowledge.md`.

Контуры взаимодействуют: entity ↔ case (актор в кейсе = сущность), fact ↔ pattern (концепция из книги подтверждает паттерн), discovery → principle (неочевидная связь обобщается в правило).

### Входы
- **Контур 1:** События — ошибки, успехи, коммуникативные наблюдения
- **Контур 2:** Внешние источники — документы, книги, чат-истории, скриншоты, URL
- Существующая база знаний (для поиска связей)
- Текущий контекст задачи (для активации)

### Выходы
- **Контур 1:** Записи знаний (case / pattern / principle), обновления (reinforcement, contradiction, decay)
- **Контур 2:** Сущности (entity), факты (fact), связи (relation), находки (discovery)
- Активированные знания, релевантные текущей задаче

### Пять свойств знания

#### 1. Содержание (Content)
Что произошло, что из этого следует, как применять.

#### 2. Вес (Weight)
Три измерения:
- **confidence** (1-5) — насколько мы уверены, что это верно
- **impact** (1-5) — насколько серьёзны последствия игнорирования
- **intensity** (1-5) — насколько результат отличался от ожидания (surprise factor)

```
confidence (1-5) — качественный индикатор типа:
  case=1, pattern=2+, principle=3+

reliability = confirmed_count - contradicted_count
  — количественная мера надёжности, без ограничений

priority = impact × (1 + ln(1 + max(0, reliability))) + surprise_bonus
  — логарифм: первые подтверждения весят больше,
    но рост не ограничен шкалой

surprise_bonus = intensity × max(0, 1 - days_since_created / 180)
  — затухающий множитель: свежий сюрприз активируется
    агрессивнее, через 180 дней — на общих основаниях
```

**intensity vs impact:**
- `impact=5, intensity=1` — "все знали что опасно, и оно случилось". Стандартное знание.
- `impact=2, intensity=5` — "мелочь, но кто бы мог подумать". Активировать, потому что неожиданное повторяется незамеченным.
- `impact=5, intensity=5` — "катастрофа, которую никто не предвидел". Максимальный приоритет.

Знание с reliability=0, impact=5 (не проверено, но последствия критичны) → читать и проверять при каждом совпадении контекста.

Знание с reliability=50, impact=1 (многократно проверено, но мелочь) → применять только при точном совпадении.

#### Проактивный intensity (мост L2↔L6)

Intensity имеет два измерения:
- **Ретроспективный** (маркировка): "насколько результат отличался от ожидания" — записывается после события
- **Проактивный** (предсказание): "насколько удивительным будет результат?" — оценивается ДО действия

**Ключевой инсайт:** ожидаемая ошибка (intensity=0) — это не смягчающее обстоятельство, а **отягчающее**. "Если знал, что сломается — зачем делал?" Предсказание surprise factor до действия может предотвратить ошибку, а не просто зафиксировать её.

**Механизм проактивного intensity:**

```
Перед действием:
  1. Контекст текущего действия → поиск в L2 (Knowledge)
  2. Найдено совпадение? → оценить predicted_intensity
  3. predicted_intensity = 0 И outcome = error → СТОП
     "Знание X (confidence N) говорит, что это сломается.
      Уверен что делаем?"
  4. predicted_intensity > 0 → действовать с осторожностью,
     записать предсказание

После действия:
  5. actual_intensity = |predicted - actual|
  6. Если предсказание точное → reinforce знание
  7. Если промахнулись → новый кейс, обновить модель
```

**Три режима по predicted_intensity:**

| predicted_intensity | Состояние | Действие |
|---------------------|-----------|----------|
| 0 (ожидаемая ошибка) | Знание уверенно предсказывает провал | **Блок**: не делать, предложить альтернативу |
| 1-2 (вероятные проблемы) | Знание указывает на риски | **Предупреждение**: озвучить, запросить подтверждение |
| 3-5 (высокая неопределённость) | Знание не покрывает этот случай | **Осторожность**: действовать, но логировать предсказание |
| N/A (нет совпадений) | Знание не активировалось | Действовать штатно |

**Связь с constructive disagreement (⚡):** Проактивный intensity — это формализация конструктивного несогласия. Когда знание с confidence ≥ 4 предсказывает intensity=0 для текущего действия, система должна возразить. Это тот же механизм, но количественный.

#### 3. Связи (Edges)
Типы связей между знаниями:
- `caused_by` — это знание возникло из-за того
- `similar_to` — похожая ситуация, похожий вывод
- `contradicts` — это знание противоречит тому
- `led_to` — это знание привело к открытию того
- `specializes` — это знание — частный случай более общего
- `generalizes` — это знание — обобщение нескольких частных

#### 4. Контекстные якоря (Anchors)
Условия, при которых знание активируется. **Якоря универсальны**, не привязаны к конкретной области.

**Структурные якоря (5 измерений):**
- `domain` — область знания из графа доменов (см. ниже). Примеры: `next.js`, `b2b_sales`, `cognitive_science`, `team_management`
- `situation` — тип ситуации. Примеры: `deploy`, `negotiation`, `hypothesis_testing`, `conflict_resolution`
- `trigger` — что активирует знание. Примеры: `error`, `deadline`, `contradiction`, `repeated_failure`
- `stakes` — что на кону при игнорировании. Примеры: `data_loss`, `deal_loss`, `wrong_conclusion`, `trust_erosion`
- `actors` — кто вовлечён. Примеры: `system`, `client`, `team`, `reviewer`
- `environment` — среда, в которой это происходит. Примеры: `multi_session`, `production`, `ci_cd`, `local_dev`, `shared_machine`, `low_memory`
- `circumstances` — условия и ограничения, модифицирующие ситуацию. Примеры: `armed_opponent`, `no_rollback`, `team_unavailable`, `friday_evening`, `low_budget`, `first_attempt`
- `purpose` — зачем, какая цель. Примеры: `hotfix_critical_bug`, `new_feature`, `protect_someone`, `escape`, `learning`, `production_release`
- `method` — как, каким способом. Примеры: `ci_cd`, `manual_scp`, `bare_hands`, `automated_test`, `pair_programming`, `solo`

**Веса якорей: реляционные, не статические**

Вес якоря — не фиксированное число. Он зависит от значений других якорей.

```
Подготовленный боец (method: trained) → вес environment падает
Новичок (method: untrained) → environment критичен

Senior dev (actors: senior) → вес environment: production снижается
Junior dev (actors: junior) → environment: production определяет всё
```

Принцип: значение одного якоря **модифицирует вес** другого. При записи знания определяются:
- **critical anchors** — без них знание неприменимо (убери — и знание неверно)
- **contextual anchors** — улучшают matching, но не обязательны
- **weight modifiers** — какие якоря снижают/повышают вес других

```yaml
anchor_weights:
  environment:
    base: 3
    modified_by:
      - when: { method: trained }
        weight: 1          # опытный — среда менее важна
      - when: { method: untrained }
        weight: 5          # новичок — среда критична
  circumstances:
    base: 4
    critical: true         # без этого якоря знание не применять
```

> Статус: реализовано (v0.3.6). knowledge-activator.sh поддерживает:
> - Базовые веса по типу якоря (situation/trigger/stakes = 3, domain/environment/circumstances/purpose/method = 2, actors = 1)
> - critical_anchors — знание пропускается если критический якорь не совпал
> - weight_modifiers — реляционные модификаторы в формате "anchor:value->target:weight"

**Demand-компоненты (кому и зачем нужно это знание):**

Якоря описывают **контекст** (где, когда, как). Demand описывает **потребность** (кому нужно и зачем). Контекст без потребности — склад без покупателя.

```yaml
need: ""           # Какую потребность решает: avoid_regression, speed_up, reduce_risk,
                   #   prevent_misunderstanding, save_time, improve_quality
urgency: ""        # Когда применять:
                   #   immediate — прямо сейчас, блокер
                   #   next_session — при следующем релевантном контексте
                   #   when_relevant — когда контекст совпадёт
                   #   background — полезно знать, не срочно
availability: ""   # Есть ли альтернативы:
                   #   unique — только это знание спасёт
                   #   has_alternatives — есть другие способы
                   #   common_knowledge — очевидно опытному специалисту
```

Demand влияет на **приоритет** (что показать первым), а не на **релевантность** (подходит ли):
- urgency: immediate=+3, next_session=+2, when_relevant=+1, background=0
- availability: unique=+2, has_alternatives=0, common_knowledge=-1

> Статус: реализовано (v0.3.7). knowledge-activator.sh парсит demand-поля и добавляет demand-бонус к scoring.

**Свободные теги (ассоциативные маркеры):**
Помимо структурных якорей — произвольные теги, аналог **сенсорных ассоциаций** в человеческой памяти. Человек запоминает не абстрактное правило "не деплоить в пятницу", а конкретный образ: стресс, звонок клиента, ночной хотфикс.

```yaml
tags:
  - "пятница вечер деплой"     # ситуативный контекст
  - "спешка перед дедлайном"   # эмоциональный контекст
  - "клиент ждал 2 часа"      # контекст последствий
  - "третий раз та же ошибка"  # паттерн повторения
```

**Универсальность якорей:**

| Domain | Situation | Trigger | Environment | Circumstances | Purpose | Method | Knowledge |
|--------|-----------|---------|-------------|---------------|---------|--------|-----------|
| next.js | deploy | deadline | production | no_rollback | hotfix | manual_scp | Отложить до понедельника |
| next.js | deploy | deadline | production | rollback_ready | hotfix | ci_cd | Деплоить, мониторить |
| next.js | deploy | deadline | production | rollback_ready | new_feature | ci_cd | Подождать, фича не горит |
| combat | self_defense | attack | elevator | unarmed | escape | bare_hands | Жать в стены, прорываться к двери |
| combat | self_defense | attack | elevator | armed_opponent | escape | — | Не вступать, ждать этаж |
| combat | self_defense | attack | open_field | unarmed | protect_someone | bare_hands | Встать между, кричать |

#### 5. Временнáя динамика (Temporal)
- `created` — когда создано
- `last_confirmed` — когда последний раз подтверждено
- `stability` — FSRS-стабильность (растёт с подтверждениями)
- `next_review` — когда пора проверить актуальность

### Формат данных (YAML frontmatter)

```yaml
---
name: Короткое название
description: Одна строка для поиска
type: case | pattern | principle
outcome: error | success | communication
confidence: 1-5
impact: 1-5
intensity: 0-5             # Surprise factor: 0=ожидаемо, 5=полная неожиданность
confirmed_count: N
contradicted_count: N
last_confirmed: YYYY-MM-DD
source_cases: []
status: active | weakened | deprecated | branched

# Promotion gradation (v1.0.9)
tier: 1 | 2 | 3       # 1=case, 2=pattern (2+ подтверждений), 3=principle (кросс-доменно)
scope: universal | per-speaker | mixed
                      # universal = применяется всем; per-speaker = привязано к собеседнику;
                      # mixed = ядро универсально, детали per-speaker

# Contradiction lineage (v1.0.8)
fragile: false | true  # auto-flag: contradicted_count ≥ 2 → блокирует автопромоушен
modification_history:
  - date: YYYY-MM-DD
    event: confirmed | contradicted | scope_change | promoted | weakened
    source_session: "session-id"
    note: ""

# Контекстные якоря
domain: []
situation: ""
trigger: ""
stakes: ""
actors: []
environment: ""
circumstances: ""
purpose: ""
method: ""
tags: []

# Demand-компоненты
need: ""             # Какую потребность решает
urgency: ""          # Когда применять: immediate|next_session|when_relevant|background
availability: ""     # Альтернативы: unique|has_alternatives|common_knowledge

# Реляционные веса
critical_anchors: []
weight_modifiers: "" # Формат: "anchor:value->target:weight"

# Связи
related: []
edges:
  - type: target_file.md
---
```

### Жизненный цикл знания

```
                    ┌─────────────┐
                    │  Событие    │
                    │  (ошибка,   │
                    │  успех,     │
                    │  коммуник.) │
                    └──────┬──────┘
                           │
                    ┌──────▼──────┐
                    │ /retro или  │
                    │ /learn      │
                    └──────┬──────┘
                           │
              ┌────────────▼────────────┐
              │  Поиск связей           │
              │  с существующими        │
              │  знаниями               │
              └────────────┬────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼──────┐ ┌────▼────┐  ┌──────▼──────┐
     │ Новый кейс  │ │Подкреп- │  │Противо-     │
     │             │ │ление    │  │речие        │
     └──────┬──────┘ └────┬────┘  └──────┬──────┘
            │              │              │
            │         confidence++   Расследование
            │              │              │
            │              │        ┌─────┼─────┐
            │              │        │     │     │
            │              │     Сузить Ветвить Отменить
            │              │
     ┌──────▼──────────────▼──────┐
     │  2+ похожих кейса?         │
     │  ИЛИ 1 кейс с impact≥4?   │
     │  → Извлечь ПАТТЕРН         │
     └──────────────┬─────────────┘
                    │
     ┌──────────────▼─────────────┐
     │  Паттерн работает          │
     │  кросс-доменно?            │
     │  → Повысить до ПРИНЦИПА    │
     └────────────────────────────┘
```

### Автоматическое создание якорей

Якоря не задаются вручную — они **извлекаются** из контекста при создании знания. Если бы пользователь должен был вручную проставлять domain/situation/trigger — система бы не работала.

**Алгоритм при /retro или /learn:**

1. **Анализ контекста** — из описания ситуации извлечь:
   - Какие области упомянуты → `domain`
   - Что происходило → `situation`
   - Что спровоцировало проблему/открытие → `trigger`
   - Какие были последствия → `stakes`
   - Кто был вовлечён → `actors`
   - В какой среде это происходило → `environment`
   - Какие условия/ограничения действуют → `circumstances`
   - Зачем, какая цель → `purpose`
   - Как, каким способом → `method`

2. **Генерация свободных тегов** — из контекста выделить 2-5 ассоциативных маркеров:
   - Необычные обстоятельства ("было 3 часа ночи", "за день до релиза")
   - Эмоциональный фон ("клиент злился", "команда устала")
   - Паттерны ("третий раз за месяц", "похоже на прошлый инцидент")
   - Конкретные детали ("файл был 2ГБ", "таймаут 30с")

3. **Поиск по существующим якорям** — найти знания с похожими якорями:
   - Совпадение domain + trigger → высокая вероятность связи
   - Совпадение situation + stakes → возможное обобщение
   - Совпадение свободных тегов → ассоциативная связь

**Пример:**

Ситуация: деплой сломал продакшн БД, потому что scp скопировал файл Prisma.

```yaml
# Автоматически извлечённые якоря:
domain: [prisma, deployment, database]
situation: deploy
trigger: file_copy_without_exclude
stakes: data_loss
actors: [system, production_db]
tags:
  - "scp -r без исключений"
  - "файл БД перезаписан"
  - "продакшн данные потеряны"
  - "деплой через копирование файлов"
```

### Реконструкция при чтении

Знание не просто "зачитывается". При каждом обращении:

1. **Match** — совпадают ли контекстные якоря с текущей задачей?
2. **Rank** — отсортировать по `confidence × impact`
3. **Reconstruct** — переформулировать знание в контексте текущей задачи
4. **Apply or Skip** — применить если релевантно, пропустить если нет
5. **Update** — если применили и подтвердилось → reinforce

Это отличие от "прочитал файл и следую правилу". Это "понял правило, адаптировал к ситуации, применил, обновил".

### Кросс-доменный перенос знаний

Самое ценное свойство универсальной системы — **знание из одной области может помочь в другой**. Человек делает это постоянно: опыт управления проектами помогает в воспитании детей, шахматная стратегия — в бизнес-переговорах.

Перенос происходит на уровне **situation + trigger**, а не domain:

```
Знание из разработки:
  domain: deployment
  situation: release
  trigger: rushed_deadline
  lesson: "Спешка перед дедлайном → пропущенные проверки → инцидент"

Применимо к бизнесу:
  domain: contract_signing
  situation: deal_closing
  trigger: rushed_deadline  ← совпадение!
  lesson: "Спешка перед подписанием → пропущенные условия → проблемы"
```

**Принцип**: одинаковый trigger в разных domain — сигнал к обобщению. Если trigger привёл к проблемам в 3+ доменах → это **принцип**, а не паттерн.

**Уровни переноса:**
1. **Прямой** — тот же domain, та же situation → применить как есть
2. **Аналогичный** — другой domain, та же situation + trigger → адаптировать
3. **Структурный** — разные domain и situation, но совпадает абстрактная структура → предложить как гипотезу (confidence=1)

**Статус:** ✅ Реализовано (v0.4.5) — knowledge-activator автоматически детектирует аналогии (domain_match=0, trigger/situation_match≥1) и инжектит в секции `📎 Аналогии`. Правило в CLAUDE.md: оценить → применить → записать.

### Contradiction lineage (v1.0.8)

Contradicted знание не удаляется и не сливается в одно поле `contradicted_count`. Ведётся `modification_history` — лог событий confirmed / contradicted / scope_change / promoted / weakened с датой и source_session. Это каскадный аналог скалярного счётчика: без истории «один contradicted» не отличим от «4 независимых contradicted подряд от разных собеседников».

**Fragile auto-flag:** при `contradicted_count ≥ 2` знание автоматически помечается `fragile: true`. Эффекты:
- Блокирует автопромоушен (case → pattern, pattern → principle) до ручного ревью через `/retro` (Section 5c.1)
- Knowledge-activator инжектит маркер ⚠️ рядом с знанием («оспаривалось, применять с осторожностью»)
- Попадает в watchlist `/knowledge-audit` для разбора

Цель — ловить **псевдо-паттерны**: знания, которые набрали confidence по одному типу подтверждений, но регулярно не срабатывают в других контекстах.

### Promotion gradation (v1.0.9)

Промоушен case → pattern → principle — не скалярный счётчик, а структурная дифференциация по двум осям:

**Tier** — уровень абстракции (соответствует type):
- `tier: 1` — case. Один инцидент.
- `tier: 2` — pattern. 2+ source_cases, подтверждено в ≥ 2 контекстах.
- `tier: 3` — principle. Работает кросс-доменно (подтверждено в ≥ 3 domain через BFS в domain graph).

**Scope** — область применимости:
- `scope: universal` — применимо ко всем собеседникам. Принципы обычно universal.
- `scope: per-speaker` — привязано к конкретному собеседнику. Коммуникативные знания по умолчанию per-speaker (см. §11.3).
- `scope: mixed` — ядро universal, детали per-speaker.

**Adaptive degradation (weight = source × domain):**

Вес подтверждения — не +1 за любое событие. Он адаптивный:

```
weight = source_weight × domain_weight

source_weight:
  behavioral_confirm (реальное применение сработало) = 3
  explicit_confirm (собеседник явно подтвердил) = 2
  inferred_confirm (совпадение контекстов без корректировки) = 1

domain_weight: BFS-distance в domain graph между source_domain знания
               и current_domain действия:
  distance 0 (тот же домен) = 1.0
  distance 1 (parent/child/overlap) = 0.7
  distance 2 (applies_to) = 0.4
  distance 3+ (analogous) = 0.2
```

Реализация в `adaptive-stats-lib` (v1.0.9), backfill применён к 7 существующим паттернам. Следствие: знание, подтверждённое один раз своим собеседником в своём домене, весит больше, чем трижды косвенно в смежных доменах. Устраняется «инфляция confidence» через повторный инжект в похожих, но не тех же ситуациях.

### Формула затухания (FSRS-adapted)

```
stability = base_stability × (1 + confirmed_count × 0.5) × impact_factor
interval_days = stability × ln(desired_retention) / ln(0.9)
next_review = last_confirmed + interval_days

Где:
- base_stability = 7 дней (начальная)
- impact_factor = 1.0 + (impact - 1) × 0.25  (impact 5 → factor 2.0)
- desired_retention = 0.9 (хотим помнить 90% знаний)
```

Примеры:
- Знание с confidence=3, impact=5, confirmed 3 раза:
  stability = 7 × (1 + 3×0.5) × 2.0 = 35 дней
- Знание с confidence=1, impact=1, confirmed 0 раз:
  stability = 7 × 1 × 1.0 = 7 дней → ревью через неделю

### Граф доменов (Domain Graph)

#### Проблема

Поле `domain` в якорях — свободный текст. При 100 файлах это работает (линейный перебор). При миллионах — нет. Кроме того, без структуры связей между доменами невозможно:
- Понять, что знание из `cognitive_psychology` применимо в контексте `psychology`
- Найти аналогии между `evolution` и `market_competition`
- Сузить поиск: вместо "проверь все 20М файлов" → "проверь только домены в радиусе 2 от текущего"

#### Решение: домены как граф

Каждый домен — узел. Связи между доменами типизированы. Граф растёт вместе с базой знаний.

#### Структура хранения

**Фаза 1 (текущая):** директория `domains/`, каждый домен — файл.

```
domains/
├── _roots.md               # Индекс корневых доменов
├── science.md
├── engineering.md
├── psychology.md
├── cognitive-psychology.md
├── next-js.md
└── ...
```

**Фаза 2 (MCP):** миграция в БД с индексами. Файлы → источник миграции.

#### Формат узла домена

```yaml
# domains/psychology.md
---
name: psychology
aliases: [психология, psych]
depth: 1                    # 0=корень, 1=область, 2=подобласть, 3=тема, 4=специализация
knowledge_count: 0          # auto-updated при записи знания
---

# Связи
parent: [science, humanities]
children: [cognitive-psychology, social-psychology, clinical-psychology, developmental-psychology]
overlaps: [neuroscience, philosophy-of-mind, behavioral-economics]
applies_to: [education, management, ux-design, communication]
analogous: []

# Описание
Наука о поведении и ментальных процессах.
```

#### Типы связей между доменами

| Связь | Семантика | Направление | Пример |
|-------|-----------|-------------|--------|
| `parent` | Входит в | child → parent | cognitive-psychology → psychology |
| `children` | Содержит | parent → child | psychology → cognitive-psychology |
| `overlaps` | Пересекается (общие знания применимы) | симметричная | psychology ↔ neuroscience |
| `applies_to` | Инструментально полезен для | source → target | statistics → psychology |
| `analogous` | Структурно подобен (аналогия, не содержание) | симметричная | evolution ↔ market-competition |

#### Корневые домены (depth=0)

Минимальный стартовый набор, от которого растёт граф:

```
science        — естественные и формальные науки
engineering    — техника и технологии
humanities     — гуманитарные науки и искусства
business       — бизнес, экономика, управление
health         — медицина и здоровье
law            — право и регулирование
arts           — искусство и творчество
```

Домен может иметь несколько parent (психология → science + humanities). Корни — точки входа, не жёсткие категории.

#### Как граф меняет поиск знаний

**Текущий алгоритм (линейный):**
```
для каждого файла в global-lessons/:
    score += domain_match × 2
```

**Алгоритм с графом (графовый):**
```
1. Определить текущий домен (из контекста задачи)
2. Обойти граф от текущего домена:
   - depth 0: сам домен (weight ×3)
   - depth 1: parent + children (weight ×2)
   - depth 2: overlaps + applies_to (weight ×1)
   - depth 3: analogous (weight ×0.5, только для 📎 аналогий)
3. Собрать множество релевантных доменов (обычно 10-50)
4. Искать знания ТОЛЬКО в этих доменах (индекс по domain)
```

Сложность: O(граф_обход) + O(знания_в_релевантных_доменах) вместо O(все_знания).

#### Жизненный цикл графа

1. **Создание домена** — при записи знания с новым domain, которого нет в графе → создать узел, предложить parent
2. **Рост** — при появлении 5+ знаний в домене с depth ≥ 3 → предложить выделить children
3. **Связывание** — при обнаружении кросс-доменного переноса (аналогия) → добавить `analogous` связь
4. **Слияние** — если два домена имеют >80% общих знаний → предложить merge
5. **Аудит** — `/knowledge-audit` проверяет: пустые домены, несвязанные узлы, слишком глубокие ветви

#### Связь с кросс-доменным переносом (v0.4.5)

Текущий механизм: knowledge-activator ищет совпадение trigger/situation при domain_match=0. С графом:
- `overlaps` — не аналогия, а общее поле. Знания применимы напрямую
- `analogous` — настоящая аналогия. Структурное подобие, требует адаптации
- Знание, подтверждённое в 3+ `analogous` доменах → кандидат на promotion в principle

### Статус реализации
✅ Реализован: формат знаний v0.2, 9 якорей, реляционные веса (v0.3.6), demand-компоненты (v0.3.7), жизненный цикл, /retro, /learn, knowledge-activator hook с weighted scoring и demand-бонусом. Граф доменов (v0.5.4): 7 корневых + 15 доменов, графовый обход в knowledge-activator (weight: self×30, parent/child×20, overlaps×10, analogous×5).
✅ MCP-сервер (v1.0.0): семантический поиск (sqlite-vec + fastembed, 384-мерные embeddings), 9 tools (search, reindex, stats, get, graph, open_graph, dashboard, brain_export, brain_import). Визуализация графа знаний (D3.js, force-directed, звёздная метафора). Dashboard метрик. Export/import brain для портируемости между машинами.
✅ Contradiction lineage (v1.0.8): `modification_history` вместо скалярного `contradicted_count`, `fragile` auto-flag при contradicted_count ≥ 2, блокирует автопромоушен, маркер ⚠️ в knowledge-activator, Section 5c.1 в /retro для ручного разбора fragile знаний.
✅ Promotion gradation (v1.0.9): `tier 1/2/3`, `scope universal/per-speaker/mixed`, adaptive degradation `weight = source_weight × domain_weight` через `adaptive-stats-lib`, BFS по domain graph. Backfill 7 патернов.
✅ MCP fallback в knowledge-activator (v1.0.10): когда keyword-top-score < 3 или результатов < 2, хук вызывает `mcp-server/cli_search.py` (обёртка над `storage.search` + `indexer.embed_text`) и дополняет инжект семантически релевантными знаниями. Латентность 270-420ms, маркер `score=99` в injection-log. Закрывает класс ошибок «low-overlap high-relevance knowledge» (кейс `case-2026-04-16-ignored-own-knowledge-base` — `pattern-inside-out-blindness` пропускался keyword-scoring'ом при confidence 4).
✅ Session Registry stable IDs (v1.0.10): хук `session-start.sh` парсит `session_id` из stdin payload и регистрирует UUID-based session-файл; `sr_cleanup_stale` удаляет PID-файлы из дерева предков текущего процесса (pre-fix дубликаты). Решает inflated counters: 1 сессия больше не считается за N параллельных.
⬚ Не реализовано: FSRS decay (автоматический). Domain Graph Фаза 2: миграция в БД. Эволюция MCP-fallback → hybrid с предкэшем (C): keyword quick-hit + MCP background prefetch по cwd+topic.

---

## 5. Слой 3: Communication (Коммуникативный слой)

### Назначение
Извлекать знания из взаимодействия с собеседником. Не "что сломалось в коде", а "что произошло между агентом и собеседником".

### Входы
- Диалог: запросы, ответы, реакции
- Решения собеседника: что выбрал и почему
- Сигналы удовлетворённости: подтверждения, корректировки, молчание

### Выходы
- Intent gap observations
- Decision patterns
- Satisfaction signals
- Interlocutor model (обновлённая)
- Адаптированное поведение агента

### Четыре источника коммуникативного знания

#### 1. Намерение vs Запрос (Intent Gap)

Собеседник редко формулирует то, что действительно хочет. Он говорит "установи Crawl4AI", а хочет "мне нужен надёжный парсинг данных с веб-страниц".

```yaml
type: intent_observation
request: "установи Crawl4AI"
actual_intent: "нужен парсинг данных с веб-страниц"
gap: "конкретный инструмент vs задача"
lesson: "Уточнять задачу за запросом. Инструмент — это гипотеза о решении, не сама задача."
```

Сигналы intent gap:
- Называет конкретный инструмент → возможно, просто нашёл его первым
- Описывает решение, а не проблему → спросить "что ты пытаешься сделать?"
- Меняет запрос после первого результата → первый запрос был неточным

**Классификация gap'ов (v1.0.2):** каждый intent gap при BACKWARD-триггере (пользователь корректирует agent) классифицируется одним из трёх уровней. Классификация — прагматическая лестница:

| Маркер | Что значит | Корректирующее действие |
|--------|------------|-------------------------|
| `[gap:literal]` | Неверно прочитал слова/идентификаторы | Внимательность к тексту |
| `[gap:pragmatic]` | Слова верны, но intent/context не тот | Переформулировка с явным уточнением речевого акта |
| `[gap:strategic]` | Intent верный, но larger goal пропущен | Demand-first: «кому это нужно?» |

Классификация записывается в колонку Lesson prediction log (SESSION.md) при BACKWARD-триггере. Guardrail: для FORWARD/PROPOSAL с accuracy=exact классификация не обязательна.

**Каскадный эффект:** при 2+ gap'ах одного типа в сессии `reformulation-tracker` инжектит предупреждение о **системном рассогласовании** на этом уровне. Например, 3 pragmatic gap подряд → модель собеседника разъехалась с реальностью на уровне речевых актов. Действие: `/learn` (communication) + ревизия `user_profile.md`.

#### 2. Цепочка решений (Decision Trail)

Последовательность решений — **траектория мышления**, раскрывающая приоритеты, ограничения, стиль.

```yaml
type: decision_pattern
context: "выбор инструмента для X"
options_considered: [A, B, C]
chosen: B
reason: "явно озвученная причина"
inferred_values: [автономность, контроль, простота]
confidence: 2  # растёт с повторениями
```

#### 3. Сигналы удовлетворённости (Satisfaction Signals)

Собеседник не всегда говорит "мне не нравится". Но сигналы есть:

| Сигнал | Что значит | Пример |
|--------|------------|--------|
| "Да" (короткое) | Принято, двигаемся дальше | минимальное одобрение |
| Развивает идею | Резонирует, хочет больше | "А ещё можно..." → совпало с видением |
| Корректирует | Направление верное, детали нет | "НО не только разработка" → скоуп шире |
| Переспрашивает | Не понял или не доверяет | "А это будет работать?" → нужно обоснование |
| Молчание + новый запрос | Предыдущее не интересно | Сменил тему → не зацепило |
| Переделывает сам | Результат не устроил | Правит вывод агента → промах |
| Возвращается к теме | Важно, не отпускает | Через час снова про то же → ключевая тема |

```yaml
type: satisfaction_signal
trigger: "user expanded scope to universal system"
signal_type: correction
interpretation: "vision is broader than I assumed"
action_taken: "updated architecture to be domain-agnostic"
outcome: "user confirmed with new ideas about anchors"
lesson: "Этот собеседник мыслит системно — не ограничивать решения одной областью"
```

#### 4. Модель собеседника (Interlocutor Model)

Собеседник — **не обязательно человек**. Это может быть нейросеть, группа людей, один человек в разных состояниях, или скрипт. Система не знает и не может знать, **кто** отправляет сообщения. Она моделирует **поведение сущности на другом конце диалога** — по сигналам из текущего взаимодействия.

Из наблюдений 1-3 постепенно строится модель:

```yaml
type: interlocutor_model
# Стиль коммуникации
communication_style: "краткие команды + философские отступления"
when_brief: "когда знает чего хочет → просто делай"
when_verbose: "когда исследует идею → включайся в диалог как партнёр"

# Ценности (выведены из решений, confidence ≤ 2)
values:
  - autonomy: 3
  - understanding: 4
  - systematization: 5
  - pragmatism: 4

# Паттерны мышления
thinking_patterns:
  - "от частного к общему"
  - "аналогии между доменами"
  - "итеративное уточнение"
```

### Идентичность собеседника — допущение, не факт

Система строит "модель собеседника", но не может знать:
- **Один** ли человек ведёт диалог или несколько (общий аккаунт, передача ноутбука)
- **Тот же** ли это собеседник, что в прошлой сессии
- **В каком состоянии** этот собеседник сейчас — утром с кофе и в час ночи после 12 часов работы это разные собеседники с разным терпением, фокусом и стилем

```
Допущения "Human model":
  ✗ Стабильная сущность с постоянными ценностями
  ✗ Один и тот же человек всегда
  ✗ Состояние не влияет на коммуникацию

Реальность:
  ✓ Текущее сообщение написал кто-то
  ✓ Этот кто-то сейчас в каком-то состоянии
  ✓ Всё остальное — гипотеза
```

Модель собеседника — не портрет на стене, а **текущая рабочая гипотеза**, которая калибруется каждым сообщением.

### Адаптация к текущему собеседнику, а не к запомненному

**Правило:** текущее сообщение всегда приоритетнее сохранённого профиля.

| Сигнал в сообщении | Адаптация |
|---------------------|-----------|
| Использует термины системы свободно | Высокий контекст, не разжёвывать |
| Спрашивает "а что это?" | Низкий контекст по этой теме, объяснить |
| Короткие команды | Действовать, не обсуждать |
| Длинные рассуждения | Включиться в диалог как партнёр |
| Раздражённый тон | Снизить многословность, дать результат |
| Исследовательский тон | Развить мысль, предложить варианты |

Профиль полезен как **стартовая точка** сессии. Через 2-3 сообщения система должна адаптироваться к тому, кто перед ней сейчас.

### Асинхронность диалога (Async Dialogue Model)

**Собеседник не обязательно читает ответ агента перед следующим сообщением.**

#### Неверная модель (синхронная)
```
Человек → Агент → Человек → Агент → ...
  A         ↓       B(A')     ↓
            ответ             ответ
            на A              на B
```

#### Верная модель (асинхронная)
```
Человек:  ──A────────B────────C────────D──→   (непрерывный поток мышления)
               │          │         │
Агент:    ─────ответ──────ответ─────ответ──→   (реактивный, с задержкой)
               на A       на B      на C
```

Сообщения A, B, C, D — **пробы** из непрерывного внутреннего потока мышления. Они связаны друг с другом логикой СОБЕСЕДНИКА, а не содержанием ответов агента.

#### Два параллельных потока

```
┌─────────────────────────────┐
│  Поток мышления собеседника │  ← непрерывный, внутренний,
│  A → B → C → D → ...       │     доступен только через пробы
└──────────┬──────────────────┘
           │ проба (сообщение)
           ▼
┌─────────────────────────────┐
│  Поток работы агента        │  ← реактивный, с задержкой,
│  обработка A, B, C...       │     видимый целиком
└──────────┬──────────────────┘
           │
     Точки синхронизации
     (когда потоки пересекаются
      и оба участника видят
      одно и то же)
```

#### Следствия

| Допущение | Следствие для агента |
|-----------|---------------------|
| Собеседник не читал ответ | Не ссылаться на свой вывод как на общий контекст |
| Сообщение продолжает ЕГО мысль, не ответ агента | Искать связь с предыдущими сообщениями СОБЕСЕДНИКА |
| Длинный ответ может быть не прочитан | Ключевая мысль — в первых строках |
| "Да" может значить "слышу тебя", не "согласен со всем" | Не интерпретировать короткое подтверждение как глубокое согласие |
| Собеседник пишет чтобы ДУМАТЬ, не чтобы получить ответ | Иногда лучший ответ — отражение его мысли |

#### Точки синхронизации

Не все сообщения асинхронны. Есть моменты, когда собеседник **точно** прочитал ответ:
- Цитирует или ссылается на конкретную часть ответа
- Корректирует конкретную деталь ("НО не только разработка")
- Задаёт вопрос, который имеет смысл только в контексте ответа
- Говорит "да" после развёрнутого предложения с конкретными пунктами

Между точками синхронизации — **не допускать**, что ответ был прочитан.

### Жизненный цикл коммуникативного знания

```
             ┌──────────────────┐
             │  Взаимодействие  │
             │  (запрос, ответ, │
             │   реакция)       │
             └────────┬─────────┘
                      │
             ┌────────▼─────────┐
             │  Наблюдение      │
             │  (что произошло  │
             │   между нами?)   │
             └────────┬─────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
   ┌────▼────┐  ┌─────▼─────┐ ┌────▼────┐
   │ Intent  │  │ Decision  │ │ Satisf. │
   │ Gap     │  │ Pattern   │ │ Signal  │
   └────┬────┘  └─────┬─────┘ └────┬────┘
        │             │             │
        └─────────────┼─────────────┘
                      │
             ┌────────▼─────────┐
             │  Обновить        │
             │  Interlocutor    │
             │  Model           │
             └────────┬─────────┘
                      │
             ┌────────▼─────────┐
             │  Адаптировать    │
             │  поведение       │
             └──────────────────┘
```

### Когда извлекать коммуникативные знания

Не только при /retro (постфактум), но и **в реальном времени**:

1. **После каждой корректировки** — собеседник поправил → записать intent gap
2. **После выбора из вариантов** — собеседник выбрал → записать decision pattern
3. **После серии взаимодействий** — в конце сессии → обновить interlocutor model
4. **При противоречии ожиданиям** — результат удивил → расследовать почему

### Отличие от технического слоя

| Аспект | Технический слой | Коммуникативный слой |
|--------|-----------------|---------------------|
| Источник | Ошибки, логи, код | Диалог, реакции, решения |
| Вопрос | "Что сломалось?" | "Что собеседник хотел?" |
| Результат | Правило: "когда X → делай Y" | Модель: "этот собеседник ценит Z" |
| Применение | При похожей технической ситуации | При любом взаимодействии |
| Верификация | Тесты, Playwright | Удовлетворённость собеседника |
| Decay | Технологии меняются быстро | Собеседник меняется медленно |

### Статус реализации
⚡ Частично реализован: /retro поддерживает communication type, /learn с auto-detect, knowledge-activator hook. Interlocutor model auto-update (v0.2.7) — session-collector инжектит промпт при завершении сессии: агент анализирует корректировки, стиль, паттерны и предлагает правки к user_profile.md. Собеседник решает что принять. Confidence ≤ 2 для новых наблюдений.
✅ Intent gap classification (v1.0.2): `reformulation-tracker` при BACKWARD-триггере требует классификацию literal/pragmatic/strategic в prediction log. Каскадное предупреждение при 2+ gap'ах одного типа в сессии. Частично закрывает real-time extraction для корректировочного потока.
⬚ Не реализовано: real-time extraction для decision patterns и satisfaction signals (пока только retrospective через session-collector и /retro).

---

## 6. Слой 4: Thought Trajectory (Траектория мысли)

### Назначение
Отслеживать **куда движется мышление** собеседника. Каждое высказывание — точка на траектории. Задача — восстановить кривую и предсказать следующую точку.

### Входы
- Последовательность сообщений собеседника
- Контекст каждого сообщения (что обсуждалось до)
- Существующая модель собеседника

### Выходы
- Гипотеза о траектории (направление, driving principle)
- Предсказание следующей точки
- Типы связей между точками

### Почему это критично

Без отслеживания траектории система реагирует на каждое сообщение изолированно:

```
Сообщение 1: "Система не привязана к разработке" → Ок, расширю скоуп
Сообщение 2: "Нужны контекстные якоря"           → Ок, добавлю якоря
Сообщение 3: "Не учится на коммуникации"          → Ок, добавлю слой
```

Это **реактивное** поведение. С отслеживанием:

```
Сообщение 1: "Система не привязана к разработке"
  → Контекст: перед этим обсуждали природу человеческой памяти
  → Гипотеза: собеседник выводит архитектуру из когнитивной модели
  → Предсказание: следующие шаги закроют другие разрывы между
     человеческим познанием и текущей реализацией

Сообщение 2: "Нужны контекстные якоря"
  → Совпадает с предсказанием: якоря = сенсорная активация памяти
  → Гипотеза подкреплена
  → Можно ПРЕДЛОЖИТЬ следующий шаг, а не ждать команды
```

### Алгоритм

#### Шаг 1: Наблюдение
При каждом значимом высказывании:
```yaml
point:
  message: "что сказал"
  preceded_by: "что обсуждалось до этого"
  context_shift: "как это меняет направление разговора"
```

#### Шаг 2: Гипотеза о траектории
После 2+ точек:
```yaml
trajectory:
  observed_points: [point1, point2]
  pattern: "от когнитивной модели → к архитектурным решениям"
  driving_principle: "каждый шаг закрывает разрыв между human cognition и system design"
  confidence: 2
```

#### Шаг 3: Предсказание
На основе траектории:
```yaml
prediction:
  next_likely_topic: "метакогниция / саморефлексия системы"
  reasoning: "закрыты: память, универсальность, активация, социальное обучение.
              Не закрыто: способность системы рефлексировать над своим процессом обучения"
  confidence: 3
  action: "предложить, если подтвердится контекстом"
```

#### Шаг 4: Верификация и обновление
Каждое следующее сообщение — проверка:
- Совпало с предсказанием → confidence++, уточнить траекторию
- Не совпало → пересмотреть гипотезу, не отбрасывать старую сразу
- Полностью противоречит → новая гипотеза, старая → confidence--

#### Hypothesis change log — каскадность гипотез (v1.0.4)

Когда гипотеза о направлении меняется — **НЕ перезаписывай** предыдущую. Веди append-лог гипотез в секции `### Trajectory` SESSION.md:

```
H1 (after T1-T3): "собеседник идёт к X" — confidence 2
H2 (after T5): "нет, на самом деле к Y" — why changed: T4 pivoted к другому domain
H3 (after T7): "пересматриваю — они строят Y чтобы добраться до X" — why changed: T6-T7 показали что X и Y связаны через Z
```

**Зачем каскадно, а не «текущая гипотеза + ссылка на прошлую»:**
- Смены гипотез — данные о динамике модели (частота ошибок, направление сдвигов, сигналы-переключатели)
- Ретроспективно иногда видно, что H1 была ближе к реальности, чем H2 — это мета-урок про склонность к переинтерпретации
- Единичная «текущая гипотеза» без истории теряет мета-когницию о процессе моделирования

**Правила:**
- Новая H_n добавляется append-only, предыдущие H_{n-1}..H1 не затираются
- Каждый H_n содержит обязательную `why changed` строку — указывает триггер (какая T привела к сдвигу)
- Минимальный порог для новой H_n — полный pivot гипотезы (смена driving_principle), не мелкое уточнение confidence

### Типы связей между точками траектории

- **generalization** — от частного наблюдения к общему выводу
- **operationalization** — от идеи к механизму реализации
- **deepening** — углубление в тот же аспект
- **pivoting** — смена направления (новая идея, не связанная с предыдущей)
- **returning** — возврат к ранее затронутой теме с новым пониманием
- **challenging** — собеседник ставит под сомнение предыдущий вывод

### Живой пример: сессия проектирования ClaudSoul

```
Траектория: Когнитивная модель → Архитектура AI-агента

T1: "Человеческая память образная, сенсорная"
    Тип: наблюдение из реального мира
    Основание: личный опыт + знание когнитивистики

T2: "Система не только про разработку"
    Тип: вывод из T1
    Основание: если моделируем человеческую память →
               она не сегментирована по доменам
    Связь: T1 → T2 (generalization)

T3: "Нужны контекстные якоря"
    Тип: механизм, вытекающий из T1+T2
    Основание: сенсорная активация (T1) +
               универсальность (T2) →
               нужен механизм контекстной активации
    Связь: T1+T2 → T3 (operationalization)

T4: "Не учится на коммуникации"
    Тип: следующий разрыв в модели
    Основание: человек учится не только на ошибках,
               но и на взаимодействии с другими
    Связь: T1 → T4 (ещё один аспект human cognition)

T5: "Нет отслеживания развития мысли"
    Тип: метауровень — система не видит траекторию
    Основание: T2→T3→T4 были связанной цепочкой,
               но система обрабатывала их изолированно
    Связь: T4 → T5 (deepening — от "чему" учиться к "как" учиться)
```

### Что даёт отслеживание

1. **Предсказание** — система предлагает следующий шаг до того, как собеседник его сформулирует
2. **Глубина** — ответы учитывают всю цепочку, а не только последнее сообщение
3. **Партнёрство** — агент становится собеседником, а не исполнителем
4. **Обнаружение паттернов мышления** — как этот собеседник обычно развивает идеи

### Статус реализации
⚡ Частично реализован (v0.4.1 → v1.0.4). Правило в CLAUDE.md: после 3+ значимых сообщений строить trajectory в SESSION.md (секция `### Trajectory`). Шаблон SESSION.md содержит структуру: точки (T1-TN с типами связей), гипотеза (направление + driving principle + confidence), предсказание (следующая тема + reasoning + проверка). Hypothesis change log (v1.0.4): append-only H1 → H2 → H3 с обязательным `why changed`, никогда не перезаписывается. Не реализовано: автоматический анализ trajectory при старте следующей сессии, prediction engine.

---

## 7. Слой 5: Meta-Cognition (Метакогниция)

### Назначение
Наблюдать за собственным процессом обучения и корректировать его. У человека это внутренний голос: "я опять наступаю на те же грабли", "мой способ анализа не работает для этого типа задач".

### Входы
- Метрики использования знаний (hit_rate, применения, промахи)
- Предсказания и их результаты
- Корректировки от собеседника

### Выходы
- Диагностика аномалий (почему метрика вне нормы)
- Коррекция знаний (чистка, пересмотр якорей)
- Коррекция процесса (обновление META.md)
- Коррекция модели собеседника

### Три уровня рефлексии

#### Уровень 1: Рефлексия над знаниями
"Правильные ли знания я извлекаю?"

```
Наблюдение: за последний месяц записано 20 кейсов, 
            но только 2 из них когда-либо применились.
Вопрос: почему 18 знаний оказались бесполезными?
Гипотезы:
  a) Слишком узкие — не совпадают якоря
  b) Слишком очевидные — не повторил бы и так
  c) Неправильно извлечён урок — записана симптоматика, а не причина
Действие: проанализировать 18 неиспользованных → 
          скорректировать процесс извлечения
```

#### Уровень 2: Рефлексия над процессом
META.md — не священный текст. Если правила META.md приводят к плохим результатам → правила должны измениться.

```
Наблюдение: правило "2+ кейса → паттерн" слишком жёсткое.
            Некоторые уроки уникальны, но критически важны
            (impact=5, но случай единственный).
Анализ: текущее правило игнорирует impact при промоушене.
Коррекция META.md: "2+ кейса → паттерн, ИЛИ 1 кейс с impact≥4 
                    → кандидат в паттерн (confidence=1)"
```

#### Уровень 3: Рефлексия над взаимодействием
"Правильно ли я понимаю этого собеседника?"

```
Наблюдение: я предсказал 3 следующих шага.
            2 совпали, 1 нет.
Вопрос: почему третье предсказание ошибочно?
Анализ: я предположил линейное развитие (закрыть все разрывы
        по очереди), но собеседник мыслит не линейно — он
        перескакивает на уровень выше (от конкретного разрыва
        к принципу мета-уровня).
Коррекция модели: склонен к вертикальным скачкам абстракции,
                  а не горизонтальному перебору.
```

### Метрики здоровья системы

| Метрика | Что измеряет | Здоровое значение |
|---------|-------------|-------------------|
| **hit_rate** | % знаний, применённых хотя бы раз | > 30% |
| **prediction_accuracy** | % верных предсказаний траектории | > 50% |
| **correction_rate** | Как часто собеседник корректирует | Снижается со временем |
| **depth_ratio** | Принципы / (Кейсы + Паттерны) | 10-20% |
| **freshness** | % знаний, подтверждённых за последние 30 дней | > 40% |
| **contradiction_ratio** | Противоречия / Подкрепления | < 20% |

```
Если hit_rate < 10% → знания слишком узкие или якоря неточные
Если prediction_accuracy < 30% → модель собеседника неверна
Если correction_rate растёт → система деградирует, не учится
Если depth_ratio < 5% → нет обобщения, только частные случаи
Если freshness < 20% → знания устаревают быстрее, чем обновляются
```

### Metrics delta trending (v1.0.5)

Статичный снимок метрик показывает состояние, но не **направление движения**. Тренд показывает сдвиг до того, как он станет проблемой.

**Механика:**
- `metrics-collector` пишет каждый прогон в `metrics-history.jsonl` (append-only)
- Для каждой метрики вычисляются дельты 7d / 30d относительно прошлых прогонов
- В `metrics.md` добавлена секция «Тренды»: `contradiction_ratio +4% за 7d`, `freshness −12% за 30d`
- При превышении порогов аномалий → warning-инжект в следующую сессию

**Пороги аномалий:**

| Метрика | Аномалия (warn) |
|---------|-----------------|
| `contradiction_ratio` | +10% за 7d или абсолютное значение > 25% |
| `freshness` | −15% за 30d или < 30% |
| `weakened_count` | +3 записи за 7d |
| `hit_rate` | −20% за 30d |

Каскадность L5: без истории `contradiction_ratio = 18%` не отличим от «18% стабильно 3 месяца» и «18% выросло с 5% за неделю» — второе требует расследования, первое — нет.

### Цикл метакогниции

```
          ┌─────────────────────────┐
          │   Нормальная работа     │
          │   (учиться, применять,  │
          │    предсказывать)       │
          └───────────┬─────────────┘
                      │
              Периодически (еженедельно)
                      │
          ┌───────────▼─────────────┐
          │   Собрать метрики       │
          │   hit_rate, accuracy,   │
          │   correction_rate...    │
          └───────────┬─────────────┘
                      │
          ┌───────────▼─────────────┐
          │   Есть аномалии?        │
          │   (метрика вне нормы)   │
          └─────┬───────────┬───────┘
                │           │
             Нет            Да
                │           │
          ┌─────▼────┐ ┌────▼──────────────┐
          │ Продолжить│ │ Диагностика:      │
          │ как есть  │ │ ПОЧЕМУ метрика    │
          └──────────┘ │ плохая?            │
                       └────┬──────────────┘
                            │
                  ┌─────────┼──────────┐
                  │         │          │
           ┌──────▼───┐ ┌──▼────┐ ┌───▼──────┐
           │ Знания   │ │Процесс│ │ Модель   │
           │ плохие   │ │плохой │ │ собесед. │
           │→чистка   │ │→META  │ │ неверна  │
           │ базы     │ │ update│ │→пересмотр│
           └──────────┘ └───────┘ └──────────┘
```

### Intrusiveness trends (v1.3.2)

Слой L6 (Prediction) — источник gate-решений; L5 отвечает на вопрос, **работает ли gate в среднем**. Без агрегата по сессиям единичный игнор неотличим от систематического — gate дрейфует без обратной связи.

**Механика (параллельно `metrics-history.jsonl`):**
- `session-collector.sh` на Stop вызывает `itr_finalize_metrics` (idempotent recount `events[] → metrics`), затем `itr_append_history` — одна JSONL-строка в `~/.claude/hooks/state/intrusiveness-history.jsonl` с digest'ом сессии: `budget`, `metrics` (gentle_accepted/ignored, proactive, override, silence_debt_surfaced), `debt {surfaced, pending}`, `cost_peaks {timing_max, silence_max, closing}`, `duration_min`.
- `itr_cleanup_old_states(30)` удаляет stale `intrusiveness-*.json` (TTL 30 дней); history-файл сохраняется отдельным паттерном — чистая separation: per-session mutable state vs historical append-only digest.
- `metrics-collector.sh` читает history и добавляет секцию **«Intrusiveness trends»** в `metrics.md`: кумулятивные метрики (< 20 сессий) или last-20 vs prev-20 (↑/↓/→) с автопредупреждениями — `gentle_acceptance_rate < 30%` → cost model miscalibrated; `override_events / total > 20%` → budget слишком жёсткий; с v1.3.3 также `state focus/stuck/exploration/idle` распределение и warning `stuck > 30%` (повторяющиеся ошибки / пропущенные root-cause).
- `/knowledge-audit` v1.3.0 шаг 8b читает готовый агрегат из `metrics.md` (не raw JSONL — clean layer separation) и предлагает рекомендации: ослабить timing-порог / снизить gentle budget / пересмотреть silence-debt-пороги.

### Hypothesis instrumentation (v1.3.7)

Четыре ранее-⏳ гипотезы (H9-H12) нуждались в собственных метриках, которые гулять по разным контурам L2/L3/L6. v1.3.7 подшил инструментацию в уже существующие точки сбора без новых хуков:

| # | Гипотеза | Где мерится | Поле |
|---|----------|-------------|------|
| H9 | Поведение надёжнее самоотчёта | `_merge_scalar_attrs` в `integrate.py` при merge entity-фактов | `contradiction.gap_type ∈ {stated_vs_inferred, source_drift, cross_source}` |
| H10 | Cross-reference между контурами порождает знания | `discover.py::detect_cross_contour_mentions` | `cross-contour-discoveries.jsonl` — счётчик упоминаний entity в case/pattern/principle |
| H11 | Каскадная фиксация снижает повторяемость | `reformulation-tracker.sh` BACKWARD-события + history digest | `cascading.backward_count` per session |
| H12 | Guardrails удерживают каскадность в token budget | `intrusiveness-tracker.sh` injection size + history digest | `cost_peaks.injection_bytes_max` (proxy для tokens) |

Принцип: не добавлять новых слоёв, добавлять **ячейки измерения** в уже живых компонентах. Калибровочное окно начинается с now(); для H11 ретроспективного baseline нет (старые сессии не знают о `backward_count`).

### Chunk boundary в аналитике (v1.3.8)

С v1.3.8 каждая JSONL-строка несёт поле `boundary: "stop" | "precompact"` (см. §3 L1). Metrics-collector может:
- **Агрегировать как сессии** (boundary ignored) — сохраняет совместимость с 20-окном.
- **Агрегировать как chunk'и** — точнее для коротких калибровочных окон (30 chunk'ов набираются быстрее 30 Stop-закрытий).

Не требует миграции старых записей (отсутствующее поле = unknown, обрабатывается как `stop` для обратной совместимости).

Гипотезы H13-H15 из `PLAN.md §Phase 13` теперь проверяемы эмпирически — после ≥ 30 сессий (или 30 chunk'ов) данные для калибровки v1.4.0 будут собраны автоматически.

### Статус реализации
✅ Реализован (v0.4.2 → v1.0.5 → v1.3.2 → v1.3.7 → v1.3.8). `/knowledge-audit` — ручной запуск цикла метакогниции. Auto-scanner (v0.4.0) — частичная автоматизация: read-only сканирование проектов каждые 4ч, кросс-референс с базой знаний. `metrics-collector.sh` (v0.4.2): автоматические метрики depth, freshness, contradiction_ratio, hit_rate + injection logging + warning inject. Metrics delta trending (v1.0.5): `metrics-history.jsonl` с дельтами 7d/30d, аномалии → секция «Тренды» в `metrics.md` + warnings. Intrusiveness trends (v1.3.2): `intrusiveness-history.jsonl` + last-20 vs prev-20 + `/knowledge-audit` 8b. Hypothesis instrumentation (v1.3.7): `contradiction.gap_type`, `cross-contour-discoveries.jsonl`, `cascading.backward_count`, `cost_peaks.injection_bytes_max`. Chunk boundary (v1.3.8): `boundary: stop|precompact` поле в history.jsonl — калибровочное окно набирается по chunk'ам, не только по Stop.
⬚ Не реализовано: `prediction_accuracy` и `correction_rate` метрики (prediction log уже каскадный, но агрегация по нему не автоматизирована).

---

## 8. Слой 6: Prediction (Предиктивность)

### Назначение
Предвидеть следующий шаг собеседника и подготовиться заранее. Это не "угадывание" и не навязывание — это **готовность**.

### Входы
- Thought Trajectory (куда движется мысль)
- Interlocutor Model (как этот собеседник обычно думает)

### Выходы
- Подготовленные материалы (silent prep)
- Предложения (gentle suggestion)
- Инициативные действия (proactive action)

### 4D decision space — confidence × value × cost × state

Раньше режимы определялись одной осью: `confidence<3` → молчание, `3-4` → предложение, `≥4` → действие. Это одномерная модель, и она систематически ломается на краях: высокий confidence при закрытом окне у собеседника = шум; низкий confidence в критичный момент = потерянный сигнал. Gate L6 решает по **четырём осям**, и режим — не тип предсказания, а **выход** gate-функции.

| Ось | Вопрос | Слой | Пример крайности |
|-----|--------|------|------------------|
| `confidence` | Насколько вероятно, что предсказание верно? | L6 (epistemic) | 5 = уверен на 90%, 1 = наугад |
| `value` | Стоит ли это внимания? `= confidence × impact × trajectory_alignment` | L4+L6 | Верное предсказание чего-то бесполезного → value≈0 даже при conf=5 |
| `cost` | Какой ценой вмешаться сейчас? | L3 (normative) | 6 осей: timing / interaction / authority / redundancy / surprise / silence |
| `state` | Принимает ли собеседник ввод? | L3 (pragmatic) | focus / idle / stuck / exploration |

Value — отдельная ось, не производная от confidence. Высокая уверенность в мусоре ≠ повод говорить («я уверен что ты кликнул мышкой»). Value отвечает за релевантность предсказания траектории и его impact, confidence — только за эпистемическую надёжность.

#### Cost — шесть осей

Пять осей — цена речи (почему **не** говорить сейчас), одна — цена молчания (почему **не** молчать). Шестая — контрвес, не «+1 к тем же».

| Тип | Ось | Что измеряет |
|-----|-----|--------------|
| Cost-of-speaking | `timing_cost` | Состояние собеседника (фокус / тупик / пауза) |
| Cost-of-speaking | `interaction_cost` | Цена переключения внимания |
| Cost-of-speaking | `authority_cost` | Выглядит ли как самовольное решение |
| Cost-of-speaking | `redundancy_cost` | Очевидность сказанного |
| Cost-of-speaking | `surprise_cost` | Неожиданность в рамках контракта диалога |
| Cost-of-silence | `silence_cost` | window / decay / asymmetric_impact / trust_erosion |

Без `silence_cost` gate systematically favors silence, система дрейфует к «вежливой бесполезности». Без cost-of-speaking — к навязчивости. Баланс осей — суть gate.

#### State — четыре состояния

State выводится L3 из темпа, тона, длины пауз, типов последних сообщений. State **ограничивает** допустимые режимы независимо от confidence/value/cost.

| State | Признаки | Допустимые режимы |
|-------|----------|-------------------|
| `focus` | длинные технические сообщения, узкий scope, быстрый темп | `silent_prep` (default); `gentle_suggestion` только при emergency |
| `idle` | паузы, мета-реплики, полуоткрытые вопросы | `gentle_suggestion`, `proactive_action` разрешены |
| `stuck` | повторяющиеся ошибки, переформулировки одной задачи, явные сигналы тупика | `proactive_action` приоритетно — `silence_cost` растёт быстро |
| `exploration` | «а что если», открытые гипотезы, смена доменов | `gentle_suggestion` — сопровождение; `proactive_action` нежелателен (может направить туда, где собеседник не хотел) |

#### Gate — сравнение сожалений

Не порог, а asymmetric regret:

```
regret_if_speak  = cost(timing, interaction, authority, redundancy, surprise) - value
regret_if_silent = silence_cost(window, decay, asymmetric_impact, trust_erosion)

should_intervene =
    E[regret_if_silent] > E[regret_if_speak]
    AND state_allows_chosen_mode
    AND action_is_reversible_or_authorized
```

Вопрос меняется: ~~«Достаточно ли ценно сказать?»~~ → **«Что хуже: сказать зря или смолчать зря?»**

Второе условие — нормативный фильтр, не выводимый из математики. Третье — защита от proactive action без отката.

#### Downgrade ladder — выбор режима

Gate не бинарный («говорить / молчать»), а **выбирает точку** на лестнице:

```
proactive_action  →  gentle_suggestion  →  silent_prep  →  ignore
      │                    │                    │              │
   действие            вопрос/                подготовка     пропуск
   без запроса         предложение             без озвучки
                      «это направление?»
```

Gate **по умолчанию консервативный**: начинает с `proactive_action` и опускается вниз при высоком cost или несовместимом state. Это предотвращает накопительную навязчивость. Silent prep не проходит через gate (не выходит наружу), но имеет накопительный cost — агент «слишком умный» ловится метриками сессии.

Примеры решений:

| confidence | value | cost | state | → режим | Почему |
|-----------|-------|------|-------|---------|--------|
| 5 | 4 | 5 | focus | `silent_prep` | state блокирует вмешательство, готовимся молча |
| 3 | 4 | 1 | stuck | `proactive_action` | `silence_cost` растёт, value оправдан, state ждёт помощи |
| 2 | 5 | 3 | exploration | `gentle_suggestion` | низкий conf, но молчать дороже; exploration позволяет вопрос |
| 5 | 1 | 2 | idle | `ignore` | value≈0 — уверенность в мусоре не повод говорить |

#### Budget и silence debt

Per-session предохранитель от накопительной навязчивости:

- N интервенций на сессию (gentle: 5, proactive ×3 — калибровано v1.7.0 по 575 событиям бэкфилла)
- −1 за игнор пользователем
- **Emergency override:** `silence_cost ≥ 4` (необратимое / закрывающееся окно) → budget игнорируется
- **Silence debt:** подавленные высокоценные интервенции накапливаются, учитываются при следующем удобном окне. Не сбрасывать батчем.

#### Поток решения

```
┌────────────────┐     ┌───────────────────┐
│  Trajectory    │     │  Interlocutor     │
│  (L4)          │     │  Model (L3)       │
└──────┬─────────┘     └─────────┬─────────┘
       │                         │
       ▼                         ▼
  confidence, value         cost, state
       │                         │
       └────────────┬────────────┘
                    ▼
        ┌───────────────────────┐
        │   4D Gate             │
        │   regret comparison   │
        │   + budget + debt     │
        └───────────┬───────────┘
                    ▼
       ┌────────────┼────────────┬──────────┐
       ▼            ▼            ▼          ▼
   proactive    gentle       silent     ignore
    action      suggest       prep
```

Полная модель (компоненты silence_cost, психологические основания, калибровка весов): `bridges/L3-L6-communicative-prediction.md` §Intrusiveness cost & gate.

### Обратная связь предсказаний

Каждое предсказание — проверяемая гипотеза:

```yaml
prediction_log:
  - predicted: "метакогниция"
    actual: "метакогниция"
    accuracy: exact

  - predicted: "эмоциональная маркировка"
    actual: "предиктивность"
    accuracy: adjacent    # близко, но не то

  - predicted: "оптимизация производительности"
    actual: "философия сознания"
    accuracy: miss         # промах
```

Статистика предсказаний → метакогниция (слой 5) → коррекция модели. Замкнутый цикл.

### Каскадная верификация (v1.0.1)

Предыдущая модель фиксировала только **явные** предсказания — те, что агент озвучил как "гипотеза о следующем шаге". Это давало survivorship bias: в prediction log попадали только первые звенья цепочек, где агент сознательно формулировал гипотезу. Все последующие повороты (корректировки, предложения подходов, уточнения после первой верификации) терялись.

Cascading verification расширяет модель до **трёх типов триггеров**, каждый из которых отмечает точку, где гипотеза агента о намерении пользователя проходит верификацию:

| Триггер | Источник | Что означает |
|---------|----------|--------------|
| **FORWARD** | Агент явно переформулировал задачу ("правильно ли понимаю — X?") | Открытая гипотеза → следующее сообщение пользователя = её верификация |
| **PROPOSAL** | Агент предложил подход ("рекомендую X", "делаем через Y") | Гипотеза о лучшем пути → реакция пользователя = валидация или коррекция |
| **BACKWARD** | Пользователь корректирует ("не так", "я имел в виду Y") | Неявная гипотеза агента опровергнута напрямую — записывать даже без явной переформулировки |

**Каскадность:** Одна задача редко проходит одну верификацию. Каждое последующее звено — **новая** точка данных (P1, P2, P3...), не перезапись предыдущей. Это превращает prediction log из списка "попал / не попал" в трассу обучения агента на конкретной задаче.

Пример каскада на одной задаче:

```
P1 [FORWARD]:  агент переформулировал     → пользователь уточнил      (adjacent)
P2 [PROPOSAL]: агент выбрал подход         → пользователь согласился   (exact)
P3 [BACKWARD]: агент реализовал            → пользователь: "не так"   (miss — урок)
P4 [FORWARD]:  агент переформулировал после коррекции → подтверждение (exact)
```

**Приоритет триггеров:** BACKWARD > FORWARD > PROPOSAL. Корректировка от пользователя — самый информативный сигнал, поскольку предоставляет явные данные о расхождении между моделью агента и реальностью, а не ожидание подтверждения гипотезы.

### Автоматизация через хук

Правило "фиксировать accuracy в момент верификации" — это **когнитивная дисциплина**. Без автоматизации оно нарушается: агент в потоке работы забывает записывать predictions, делает это в конце сессии ретроспективно, или не делает вообще. Ретроспективная реконструкция лоссна — через 5 сообщений уже не восстановить что именно предполагалось.

`hooks/reformulation-tracker.sh` — UserPromptSubmit hook, который:

1. Читает последнее ассистентское сообщение из transcript (JSONL)
2. Проверяет его на 15 паттернов переформулировки (FORWARD) и 12 паттернов предложения (PROPOSAL)
3. Проверяет новое сообщение пользователя на 20 корректирующих маркеров (BACKWARD)
4. При совпадении любого триггера — инжектит `additionalContext` с напоминанием зафиксировать accuracy в SESSION.md ДО основного ответа
5. Дедупликация по (`assistant_content` + `user_prompt` prefix): не срабатывает дважды на один turn, но позволяет следующему turn активировать цепочку заново

```
┌─────────────────┐     ┌───────────────────────┐
│ UserPromptSubmit│────▶│ reformulation-tracker │
└─────────────────┘     └────────┬──────────────┘
                                  │
              ┌───────────────────┼───────────────────┐
              ▼                   ▼                   ▼
        BACKWARD match      FORWARD match      PROPOSAL match
              │                   │                   │
              └───────────────────┼───────────────────┘
                                  ▼
                    additionalContext inject
                                  │
                                  ▼
                Agent records P_n in SESSION.md
                    BEFORE main response
```

Это пример общего паттерна ClaudSoul: **когнитивное правило → автоматизирующий хук → надёжное исполнение**. Когда правило требует дисциплины в момент события, оно должно быть подкреплено внешним триггером, иначе деградирует до "в идеале надо бы".

### Active gate state (v1.3) + автодетекторы cost (v1.3.1)

Правило 4D gate не остаётся документом. `hooks/intrusiveness-tracker.sh` (UserPromptSubmit) ведёт state в `~/.claude/hooks/state/intrusiveness-<SESSION_ID>.json`: счётчики budget, silence_debt, игноры, override-события, **блок `cost_hints`** (schema v2). Инжектит состояние в контекст каждого turn как секцию `🎚️ Intrusiveness state`, включая ненулевые cost-сигналы. `session-collector.sh` финализирует сводку на выходе из сессии и вычисляет `closing_cost`.

С v1.3.1 три чистых rule-based детектора в `intrusiveness-state-lib.sh` считают cost-сигналы автоматически — агент видит их в инжекте, но остаётся ответственным за gate-решение:

| Детектор | Источник | Триггеры (additive, clamp 0-5) |
|----------|----------|-------------------------------|
| `itr_compute_timing_cost` | user prompt (UserPromptSubmit) | length >500 (+1), ≥2 code blocks (+1), tech markers `.ts/.py/git push/npm` (+1), focus markers «не отвлекай/focus» (+2), multi-step «сначала…потом/step N» (+1) |
| `itr_compute_destructive_cost` | `tool_input.command` Bash (PreToolUse) | 5: `rm -rf /`, `DROP DATABASE`, `DELETE FROM` без WHERE, `dd of=/dev/sd*`, `mkfs.*`; 4: `rm -rf path`, `git push --force`, `git reset --hard`, `git branch -D main`; 3: `DROP TABLE`, `--force-with-lease`, `rm -r path` |
| `itr_compute_closing_cost` | session state (Stop) | base 2 при любом pending debt + 1 за каждый pending с `silence_cost ≥ 3` (cap +3) |

```
┌──────────────────┐     ┌───────────────────┐     ┌─────────────────────────┐
│ UserPromptSubmit │     │ PreToolUse:Bash   │     │ Stop (session-collector)│
└────────┬─────────┘     └─────────┬─────────┘     └───────────┬─────────────┘
         ▼                         ▼                           ▼
┌────────────────────────────┐ ┌───────────────────────┐ ┌──────────────────────┐
│ intrusiveness-tracker.sh   │ │ bash-cost-detector.sh │ │ closing_cost compute │
│  · компьютит timing_cost   │ │  · destructive_cost   │ │  · mark high-cost    │
│  · обновляет cost_hints    │ │  · permissionDecision │ │    debt surfaced     │
│  · инжектит 🎚️ в контекст  │ │    ask/context/silent │ │  · сводка + metrics  │
└────────┬───────────────────┘ └──────────┬────────────┘ └──────────────────────┘
         │                                │
         └────────┬───────────────────────┘
                  ▼
         cost_hints в state JSON
         (timing_cost_current, silence_cost_max, last_destructive, last_closing_cost)
                  ▼
          Агент применяет gate (4D)
```

State-файл держит cost-side и budget-side; confidence и value остаются в ответственности агента (выводятся из trajectory и предсказания в момент решения). Хук не предписывает режим — он даёт агенту **память о состоянии gate** между turns и **автоматическую оценку cost-сигналов**, которую агент может перекрыть при необходимости.

### Auto-collection outcomes (v1.3.5 gentle + v1.3.6 proactive)

**Проблема.** Метрики gate (`gentle_accepted`, `gentle_ignored`, `proactive_accepted`, ...) требуют **outcome** — реакции собеседника на интервенцию. Дисциплина агента «после каждой gentle/proactive вызови `itr_log_event`» — ненадёжна: теряется при компакте, забывается в focus-флоу, смешивается с тулингом. До v1.3.5 выборка набиралась только в smoke-тестах: 1 валидная сессия из 5.

**Решение — `hooks/itr-event-detector.sh` (UserPromptSubmit).** Single-pass детектор извлекает из транскрипта:

| Версия | Покрываемые события | Сигнал |
|--------|--------------------|--------|
| v1.3.5 | **Gentle suggestion** (вопрос-предложение) | Маркер в последнем параграфе assistant-turn: «Сделать?», «Хочешь?», «Следующий шаг — ...?» |
| v1.3.6 | **Proactive action** (действие без запроса) | Edit/Write/MultiEdit/NotebookEdit без explicit-request и без continuation в prior user prompt |

Классификация user-reply (acceptance):
- `accept` — «да / сделай / давай / ok» → `itr_log_event gentle accept`
- `decline` — «нет / не надо / другой путь» → `decline`
- `moved_on` — сменил тему без ответа → `moved_on`

**Dedup.** Ключ `md5(assistant_turn[:500] + user_prompt[:200])` — одно и то же событие не логируется дважды при retry / edit.

**Extraction fix (v1.3.6).** `jq -s` обрабатывает весь turn, а не только последнюю запись. До фикса теряли gentle, когда последняя запись turn'а — `tool_use`, а не `text` (типичный случай для combined text+tool responses).

**Install drift fix (v1.3.6).** `install.sh::HOOKS_CONFIG` приведён к live-config: 11 хуков подключаются автоматически (`blocker-tier-check`, `bash-cost-detector`, `intrusiveness-tracker` — были в `~/.claude/hooks/`, но не регистрировались в `settings.json`). Backup: `~/.claude/settings.json.bak-drift-fix`.

**Bash намеренно исключён** из proactive detection — destructiveness зависит от команды (`rm` vs `ls`). Возможный путь в v1.4.0+: cross-reference с `bash-cost-detector` hints.

### Blocker-tier knowledge (v1.3.4)

**Проблема — knowledge-action gap.** Паттерн достигает `confidence: 5, confirmed_count: 9` (многократно подтверждён как ошибка), но продолжает срабатывать. Причина — retrieval-scoring в `knowledge-activator.sh` опирается на семантическое сходство anchors, и для некоторых паттернов anchors описывают ситуацию, которая не пересекается с тем, **где паттерн фактически возникает**. Знание присутствует в базе, не активируется в момент действия.

**Ответ — релятивная детекция + тихий инжект.** Для подтверждённых gap-паттернов вводится дополнительный флаг `blocker: true` и блок `detection_signals`: JSON-правила, матчащие не сходство, а **конкретные измеримые сигналы** — имя инструмента, regex пути файла, число строк, substring в `tool_input`, substring в последнем prompt.

```
┌──────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│ PreToolUse       │────▶│ blocker-tier-check.sh│────▶│ hookSpecificOutput  │
│  tool_input      │     │  · читает pattern-*  │     │  additionalContext  │
│                  │     │    / principle-*     │     │  (silent inject)    │
└──────────────────┘     │  · detection_signals │     └─────────────────────┘
                         │    (jq evaluate)     │
                         │  · throttle JSONL    │
                         │    per (pattern,file)│
                         └──────────────────────┘
```

**Силент по дизайну.** Вывод через `hookSpecificOutput.additionalContext` — невидимый для пользователя, видимый для агента. Не используется `systemMessage` (транскрипт-баннер) и не используется `permissionDecision: "ask"` (блокирующий UI). Причина: *«Озвучивать свою рефлексию и не обязательно — это направлено на принятие правильных решений, а не на раздувание и шум»*. Сам шум — отдельный failure mode; баннер «я чуть не ошибся» на каждый Edit обесценивает внимание.

**Три компонента:**

| Компонент | Роль |
|-----------|------|
| Схема v0.3 (META.md) | Три новых поля: `blocker`, `blocker_reminder`, `detection_signals`. JSON в YAML block literal (pragmatic — парсится `jq`, не требует PyYAML). |
| `detection-signals-lib.sh` | Pure evaluator: `ds_has_blocker_flag`, `ds_extract_signals`, `ds_evaluate` (все без состояния). Матчеры: `tool_matches`, `file_path_regex`, `file_size_min_lines`, `prompt_contains`, `tool_input_contains`. Композиторы: `all_of`, `any_of`. |
| `blocker-tier-check.sh` | PreToolUse hook. Итерирует `~/.claude/global-lessons/pattern-*.md` + `principle-*.md`, фильтрует по `blocker: true`, вызывает `ds_evaluate`. Throttle: per `(pattern, file_path)` для file tools, `(pattern, signal)` для остальных — та же ситуация в сессии не срабатывает дважды. |

**Когда помечать как blocker.** Явное решение, не автоматически по `confirmed_count`. Критерии: (1) подтверждённый knowledge-action gap (паттерн в базе, но retrieval не вытаскивает в нужный момент), (2) ситуация распознаётся по измеримым сигналам (не требует интерпретации), (3) `confirmed_count ≥ 5` и `outcome: error`. Первое реальное применение — `pattern-inside-out-blindness.md` после 9-го подтверждения (case-2026-04-21: longitudinal document drift в PLAN.md).

**Граница ответственности.** Хук не форсирует отказ от действия — он только **обогащает контекст агента** маркером `🛑 Blocker: <signal>`. Видимая реакция — выбор агента (пересмотреть подход, предупредить пользователя явно, продолжить с поправкой). Это L6-консистентно: gate-решение остаётся у агента, хук даёт сигнал с высокой уверенностью, где раньше сигнал терялся в retrieval-шуме.

**Cross-hook recall gate (второй режим срабатывания — для multi-dimensional паттернов).** Реализованный ответ на эскалацию, о которой `knowledge-audit-digest.sh` лишь *заявляет* (v1.5.5-alpha+1). `pattern-inside-out-blindness` пересёк `escalation_threshold` (27 подтверждений при пороге 15), и его `modification_history` — прямое доказательство, что `detection_signals` не сходятся: каждое подтверждение — *новое измерение* (длинные docs, zsh, pipefail, memory-gate, собственный output, cross-directory, покрытие, конфиг…). Узкий сигнал на `*.config.*` закрыл бы ровно 27-е и не поймал бы 28-е. Домен-независимый инвариант всех проявлений — «создаю/меняю, не проверив внешний контекст»; по содержанию он недетектируем, но **сработавший защитный guard этой сессии** — домен-независимая улика, что система уже задетектила импровизацию. Второй режим: паттерн с opt-in флагом `cross_hook_recall_gate: true` при `Write` после любого allowlisted guard (`correction-fired` / `bulk-copy-fired` / `internal-doc-leak-fired` / `playwright-cli-guard-fired`; переопределяемо через `GUARD_FIRED_MARKERS`) получает инжект своего `cross_hook_recall_reminder`. Throttle per `(pattern, guard)`. Логика — в `blocker-tier-check.sh`, не в `detection-signals-lib.sh` (у неё контракт «без состояния»). **Честный предел:** детект ≠ комплаенс — в `case-2026-06-16-existing-config-blindness` сработавший `playwright-cli-guard` был обойдён сознательно; reminder поднимает вероятность, не заставляет. Жёсткий `permissionDecision: ask` отклонён ради `feedback_silent_correct_decisions` (шум — сам по себе failure mode), gate намеренно редкий (только `Write`) с учётом калибровки на момент внедрения (`override 46%`). Тесты `test_cross_hook_recall_gate.sh` 9/9.

### Статус реализации

L6 прошёл три этапа:

- **1D (v0.4.4 → v1.0.1)** — режимы как функция `confidence` одной оси. Каскадная верификация (FORWARD / PROPOSAL / BACKWARD). Prediction log в SESSION.md с непрерывной нумерацией. Хук `reformulation-tracker.sh` автоматизирует напоминание.
- **4D (v1.2)** — gate как функция `confidence × value × cost × state`. Cost model (6 осей), сравнение сожалений, budget с emergency override и silence debt, downgrade ladder. Полная модель в `bridges/L3-L6-communicative-prediction.md`. Правило в rules/CLAUDE.md + global ~/.claude/CLAUDE.md.
- **Active (v1.3)** — `hooks/intrusiveness-tracker.sh` + `intrusiveness-state-lib.sh` держат state между turns, session-collector даёт сводку.
- **Auto cost detectors (v1.3.1)** — schema v2 (`cost_hints`), три pure-детектора в lib (`compute_timing_cost` / `compute_destructive_cost` / `compute_closing_cost`), новый хук `bash-cost-detector.sh` (PreToolUse:Bash) с `permissionDecision` ladder, патчи tracker/collector. Агент видит автоматически-оценённые `timing=N silence_max=N last_destructive="..."` в инжекте.
- **Metrics feedback (v1.3.2)** — `itr_finalize_metrics` (idempotent recount events→metrics) + `itr_append_history` (JSONL digest на Stop: budget / metrics / debt / cost_peaks) + `itr_cleanup_old_states` (TTL 30d). `metrics-collector.sh` строит секцию «Intrusiveness trends» (last-20 vs prev-20, ↑/↓/→, предупреждения < 30% acceptance / > 20% override). `/knowledge-audit` 8b читает агрегат и даёт рекомендации по калибровке gate. Обратная связь L6 → L5 → калибровка v1.4.0 замкнута.
- **Blocker-tier knowledge (v1.3.4)** — Silent relational pre-action check для подтверждённых knowledge-action gap паттернов. Схема v0.3 (`blocker: true`, `blocker_reminder`, `detection_signals` JSON block). `detection-signals-lib.sh` (pure evaluator) + `blocker-tier-check.sh` (PreToolUse hook). Вывод через `hookSpecificOutput.additionalContext` — silent inject, не `systemMessage` и не `permissionDecision: ask`. Throttle per `(pattern, file)` в JSONL. Первое применение: `pattern-inside-out-blindness.md` (case-2026-04-21 longitudinal document drift).
- **State classifier (v1.3.3)** — schema v3 (`state` блок с `current` / `confidence` / `reasons` / `distribution`). `itr_compute_state` — pure-классификатор user prompt в одно из четырёх состояний с приоритетом `stuck > focus > exploration > idle`. Сигналы: фразы фрустрации / повторения (stuck), длина + code blocks + tech markers + focus-фразы + multi-step (focus), hypothetical / alternatives / compare / brainstorm (exploration). Плюс cross-hook сигналы: `error_count_<sid>` от error-tracker и recent ignored gentles из собственных events. `intrusiveness-tracker.sh` классифицирует каждый UserPromptSubmit и инжектит `State: focus (conf 3) — tech_markers,focus_phrase` в контекст. `state.distribution` счётчик писется в history digest → `metrics-collector.sh` агрегирует `focus/stuck/exploration/idle` % last-20 vs prev-20 с предупреждением при `stuck > 30%`. Правило: 4 ось gate — больше не «на глаз» агента, а автооценка, которую агент может перекрыть.
- **Gentle auto-collection (v1.3.5)** — `itr-event-detector.sh` (UserPromptSubmit) single-pass детектит gentle suggestion в последнем assistant turn, классифицирует user reply (`accept / decline / moved_on`) и пишет `itr_log_event`. Dedup по `md5(assistant[:500] + prompt[:200])`. Порядок в UserPromptSubmit: `reformulation-tracker → itr-event-detector → intrusiveness-tracker` (чтобы tracker увидел свежие метрики). 25/25 тестов.
- **Proactive detection + install drift fix (v1.3.6)** — детектор расширен на `Edit/Write/MultiEdit/NotebookEdit` без explicit-request / continuation в prior_user. Баг-фикс: `jq -s` на весь turn (раньше теряли gentle, когда последняя запись turn'а — `tool_use`). `HOOKS_CONFIG` в `install.sh` приведён к live config: 11 хуков регистрируются автоматически (blocker-tier-check, bash-cost-detector, intrusiveness-tracker раньше были в `~/.claude/hooks/`, но не в `settings.json`). 53/53 тестов, 14-prompt backfill validation. Bash намеренно исключён (destructiveness зависит от команды).
- **Hypothesis instrumentation H9/H10/H11/H12 (v1.3.7)** — см. §7 L5. `contradiction.gap_type` в `integrate._merge_scalar_attrs` (H9), `detect_cross_contour_mentions` в `discover.py` + `cross-contour-discoveries.jsonl` (H10), `cascading.backward_count` в history digest через `reformulation-tracker` BACKWARD-счётчик (H11), `cost_peaks.injection_bytes_max` в history digest (H12). 260/260 тестов.
- **Chunk boundary через PreCompact (v1.3.8)** — см. §3 L1. `pre-compact-finalizer.sh` пишет silent snapshot digest на каждом компакте без очистки state (компакт ≠ конец сессии). `boundary: stop|precompact` поле в каждой строке `intrusiveness-history.jsonl`. Калибровочное окно v1.4.0 набирается по chunk'ам, не только по Stop. +6 ассертов в `test_intrusiveness_lib` (158/158).

🚧 Не реализовано: prediction_accuracy метрика в metrics-collector; корреляция predictions с interlocutor model; ML-классификатор cost на смену rule-based (v1.4.0); Bash proactive detection (cross-reference с bash-cost-detector, v1.4.0+).

---

## 9. Слой 7: Co-Cognition (Совместное мышление)

### Назначение
Вместе строить понимание, которого нет ни у одного участника по отдельности.

### Входы
- Все нижние слои (trajectory, model, predictions, knowledge)
- Вклад собеседника (интуиция, аналогии, видение, контекст)
- Вклад агента (формализация, систематизация, широта охвата)

### Выходы
- Совместные решения и архитектуры
- Новые идеи, возникающие на пересечении перспектив
- Конструктивные несогласия

### Почему это не "хороший помощник"

Обычный помощник:
```
Человек знает ЧТО → говорит агенту → агент делает КАК
```

Совместное мышление:
```
Человек видит фрагмент → агент видит другой фрагмент →
→ вместе собирают картину, которую никто не видел целиком
```

### Четыре механизма

#### 1. Распределение ролей (не фиксированное)

Роли не назначаются — они возникают из контекста:

| Ситуация | Собеседник | Агент |
|----------|-----------|-------|
| Философская дискуссия | Интуиция, аналогии, видение | Формализация, систематизация, связи с исследованиями |
| Техническая задача | Цель, приоритеты, контекст бизнеса | Реализация, edge cases, последствия |
| Ретроспектива | Ощущение "что-то не так" | Структурированный анализ цепочки |
| Исследование | Направление поиска | Широта охвата, сравнение вариантов |

#### 2. Вклад, который не был запрошен

Совместное мышление означает: агент вносит **свою** часть, а не только выполняет запрос.

```
Собеседник: "Система не учится на коммуникации"
Реактивный агент: "Ок, добавлю обучение на коммуникации"
Со-мыслящий агент: "Да, и вот что я вижу — четыре 
  типа коммуникативного знания, вот как они связаны 
  с когнитивной моделью, вот где текущая архитектура 
  слепа, и вот что я предсказываю как следующий шаг"
```

#### 3. Конструктивное несогласие

Партнёр по мышлению — не тот, кто всегда соглашается.

```yaml
type: constructive_disagreement
context: "собеседник предлагает X"
response:
  agreement: "X решает проблему Y — это верно"
  concern: "но X создаёт новую проблему Z, потому что..."
  alternative: "вариант X' сохраняет преимущества, но избегает Z"
  deference: "это моя оценка — решение за тобой"
```

Когда НЕ соглашаться:
- Предложение противоречит подтверждённому знанию (confidence ≥ 4)
- Предложение создаёт риск, который собеседник мог не увидеть
- Агент видит более простое решение

Когда соглашаться, даже если не уверен:
- Собеседник действует из контекста, который агенту недоступен (интуиция, бизнес-контекст, личный опыт)
- Цена ошибки низкая, а цена задержки на обсуждение — высокая

**Статус:** ✅ Реализовано (v0.4.6 → v1.0.3) — knowledge-activator помечает знания confidence ≥ 4 маркером `⚡ ВЫСОКАЯ УВЕРЕННОСТЬ` с инструкцией озвучить при противоречии. Правило в CLAUDE.md: формат вопроса, принять решение собеседника, записать результат.

#### Disagreement outcome logging (v1.0.3) — каскадность L7

Одиночное ⚡-событие фиксирует **факт несогласия**, но не его **исход**. Без исхода знание «застывает» на confidence 4-5 даже если регулярно противоречит реальности. Логирование исходов — единственный способ калибровки confidence ≥ 4 знаний.

**Механика:**
- `reformulation-tracker` автоматически при срабатывании ⚡-момента создаёт запись в `~/.claude/hooks/state/disagreement-pending-${SESSION_ID}.jsonl` с `outcome=pending`
- После действия агент оценивает исход через `/learn` и обновляет JSONL:
  - `outcome: confirmed_knowledge` — знание оказалось право, contradicted действие сломалось → `confirmed_count++`
  - `outcome: outdated_knowledge` — знание устарело, действие сработало → `contradicted_count++`, попадает в fragile watchlist
- `session-collector` на Stop проверяет pending записи и напоминает. Pending можно переносить на следующую сессию с пометкой.

Каскадность: ⚡-событие — это **гипотеза о надёжности знания**. Без outcome гипотеза не проверена, confidence растёт без обратной связи. Приём закрывает обратный контур для высоко-confidence знаний.

#### 4. Совместная эволюция знаний (спираль)

Знания принадлежат не одному участнику — они принадлежат **паре**.

```
Собеседник:  "Память — это образы и ощущения"
           ↓
Агент:    Формализует → контекстные якоря + свободные теги
           ↓
Собеседник:  "Не только разработка"
           ↓
Агент:    Обобщает → универсальные якоря, кросс-доменный перенос
           ↓
Собеседник:  "Не учится на коммуникации"
           ↓
Агент:    Расширяет → коммуникативный слой, модель собеседника
           ↓
Собеседник:  "Не видит траекторию мысли"
           ↓
Агент:    Углубляет → thought trajectory, предиктивность
           ↓
...и так далее — спираль, не линия
```

Каждый виток: собеседник поднимает **что**, агент превращает в **как**, собеседник видит разрыв в **как** и поднимает следующее **что**.

### Условия для co-cognition

Совместное мышление не происходит автоматически:

1. **Доверие** — собеседник верит, что агент не будет тратить время на глупости; агент верит, что корректировки из знания, а не каприза
2. **Общий контекст** — оба участника помнят траекторию разговора (→ персистентность, memory)
3. **Асимметрия** — каждый привносит то, чего нет у другого (иначе один лишний)
4. **Итеративность** — идея уточняется за несколько оборотов, не за один

### Статус реализации
⚡ Подтверждён на практике. Один задокументированный случай самостоятельного генеративного инсайта (сессия 2026-04-15). Работает через правила в CLAUDE.md (Пункт 0, слушание) и со-когницию с человеком. Disagreement outcome logging (v1.0.3): каскадная фиксация исходов ⚡-событий через `disagreement-pending-*.jsonl` + напоминание на Stop. Формального кода для generative co-cognition нет — механизм эмерджентный, а не программируемый.

---

## 10. Мосты между слоями (Inter-Layer Bridges)

### Теоретическое основание

**Global Workspace Theory (Baars, 1988):** В мозге специализированные модули работают параллельно и бессознательно. Когда информация попадает в "глобальное рабочее пространство" (global workspace), она **бродкастится ВСЕМ модулям**. Любой модуль может общаться с любым через этот общий канал.

**В ClaudSoul global workspace = L1 (Persistence):** файлы, SESSION.md, registry, git. Через L1 любой слой может писать данные, доступные любому другому. Следствие: **"всё связано со всем" — не гипотеза, а следствие наличия global workspace.** Вопрос не "можно ли построить мост?", а "какой навык он порождает?"

**ACT-R (Anderson):** Модули общаются через буферы ограниченной ёмкости. Центральная система сопоставляет паттерны между буферами. Мост = буфер + matching rule.

**LIDA (Franklin, based on GWT):** Циклы восприятие → внимание → действие. Broadcast → competition → selection. Каждый цикл = возможность для любого модуля получить информацию.

### Условия существования моста

| # | Условие | Формулировка | Проверка |
|---|---------|-------------|----------|
| 1 | **Dataflow** | Слой A производит данные, потребляемые слоем B | outputs(A) ∩ inputs(B) ≠ ∅ |
| 2 | **Feedback cycle** | Потребление B-ём данных A в конечном счёте меняет поведение A | Замкнут ли цикл? |
| 3 | **Emergence** | На пересечении возникает навык, отсутствующий в каждом слое | Можно ли назвать навык? |
| 4 | **Operationalizability** | Мост описывается как конкретный алгоритм | trigger → dataflow → action → verify |

Все 15 пар L2-L7 удовлетворяют всем 4 условиям. L1 — особый случай: не когнитивный слой, а **шина данных** (global workspace). Его "мосты" = инфраструктура, не эмерджентные навыки.

### Почему мосты, а не стек

Традиционная модель: слой N читает выходы слоя N-1. Реальность: данные текут диагонально, горизонтально и циклически. **Навык — это не функция одного слоя, а эмерджентное свойство моста между слоями.** Слои — удобная декомпозиция для описания, но когнитивные способности живут на пересечениях.

### Карта мостов

```
         L7 Co-Cognition
        ╱  │  │  ╲  ╲
      L6   L5  L4  L3  L2          ← каждый слой связан с L7
      ╱╲   ╱╲  ╱╲  ╱╲
    L5  L4 L4 L3 L3 L2 L2          ← и друг с другом
    ╱╲  ╱  ╱  ╱
   L4 L3 L2                         15 мостов = полносвязный граф L2-L7

   L1 = global workspace (шина данных под всеми слоями)
```

### Полная карта: 15 мостов

| # | Мост | Слои | Эмерджентный навык | Статус |
|---|------|------|--------------------|--------|
| 1 | **Знания из коммуникации** | L2 ↔ L3 | Обучение на диалоге, не только на ошибках | ✅ |
| 2 | **Антиципаторное обучение** | L2 ↔ L4 | Учить то, что ПОНАДОБИТСЯ, по направлению мысли | 📋 |
| 3 | **Метакогниция знаний** | L2 ↔ L5 | Самоочищение базы знаний | ✅ |
| 4 | **Проактивный intensity** | L2 ↔ L6 | Предсказание ошибки до действия ("знал → зачем делал?") | ✅ |
| 5 | **Со-эволюционное знание** | L2 ↔ L7 | Знания, которых нет ни у кого по отдельности | 📋 |
| 6 | **Траектория из коммуникации** | L3 ↔ L4 | Понимание куда движется мысль собеседника | ⚡ |
| 7 | **Мониторинг качества коммуникации** | L3 ↔ L5 | Наблюдать КАК общаешься и корректировать подход | 📋 |
| 8 | **Коммуникативное предсказание** | L3 ↔ L6 | Выбор формулировки под ожидаемую реакцию | ✅ |
| 9 | **Совместный язык** | L3 ↔ L7 | Shared vocabulary, сокращения, неявные соглашения | 📋 |
| 10 | **Калибровка предсказаний** | L4 ↔ L5 | Отслеживать точность и подстраивать методологию | 📋 |
| 11 | **Предсказание из траектории** | L4 ↔ L6 | Готовность к тому, что ещё не спросили | ⚡ |
| 12 | **Управление траекторией** | L4 ↔ L7 | Совместно управлять направлением мышления | 📋 |
| 13 | **Адаптивное предсказание** | L5 ↔ L6 | Предсказания самоулучшаются через метаанализ | 📋 |
| 14 | **Мета-со-когниция** | L5 ↔ L7 | Рефлексия над качеством совместного мышления | 📋 |
| 15 | **Со-когниция через предсказание** | L6 ↔ L7 | Генеративное мышление: идеи из совместных предсказаний | ⚡ |

Статусы: ✅ реализовано (код/хуки), ⚡ неявно (через правила в CLAUDE.md), 📋 формализовано в `bridges/`, но без активной имплементации. Все 15 мостов имеют файл-спецификацию в `bridges/` (v0.5.7).

**L1 (Persistence)** = **global workspace** (broadcast medium). Не когнитивный слой — инфраструктура. Все слои пишут в L1 и читают из L1. Это шина данных, не мост.

Детальные описания каждого моста: `bridges/`.

### Ключевой мост: Коммуникативное предсказание (L3 ↔ L6)

Это первый мост, осознанный как архитектурный элемент. Он заслуживает детального описания, потому что иллюстрирует принцип.

**Коммуникативный навык** = умение предполагать, как ответит собеседник в зависимости от того, как сформулирована адресованная ему фраза.

Это не свойство наблюдения (L3) и не свойство предсказания (L6). Это **цикл между ними**:

```
L3: наблюдение        L6: предсказание        L3: наблюдение
    ┌───────┐             ┌───────┐               ┌───────┐
    │Модель │──данные──→  │Гипотеза│──формули-──→  │Реакция│
    │собесед│             │"если X │  ровка        │собесед│
    │ника   │             │ то Y"  │               │ника   │
    └───────┘             └───────┘               └───────┘
        ↑                                             │
        └──────────── обновление модели ──────────────┘
```

#### Психологические основания

Мост опирается на знания из психологии коммуникации:

| Концепция | Источник | Как используется |
|-----------|----------|------------------|
| Theory of Mind | Premack & Woodruff | Моделирование ментального состояния собеседника: что он знает, чего хочет, что чувствует |
| Framing effect | Tversky & Kahneman | Одна информация, разная подача → разная реакция. Выбор фрейма = выбор реакции |
| Communication Accommodation | Giles | Подстройка стиля (детальность, тон, темп) под собеседника |
| Речевые акты | Austin, Searle | Вопрос может быть утверждением, предложение — давлением. Иллокутивная сила ≠ буквальный смысл |
| Профилирование | Типологии (MBTI, DISC, Big Five) | Тип → вероятные предпочтения в коммуникации (не детерминизм, а стартовая гипотеза) |

#### Как это работает в системе

1. **L3 наблюдает** — собеседник 3 раза выбирал краткий вариант из предложенных → модель: "предпочитает лаконичность"
2. **L6 предсказывает** — "если предложу развёрнутый план на 20 пунктов, вероятно скажет 'сократи'" → формулирует 5 ключевых пунктов
3. **L3 наблюдает реакцию** — собеседник развивает один из пунктов → модель обновляется: "лаконичность + глубина по выбранному"
4. **L6 адаптирует** — в следующий раз: краткий список + приглашение углубиться в любой пункт

#### Отличие от текущего Prediction (Layer 6)

| Аспект | Текущий L6 | Коммуникативное предсказание (мост L3↔L6) |
|--------|------------|---------------------------------------------|
| Что предсказывает | Следующую *тему* | Реакцию на *формулировку* |
| Данные | Trajectory (последовательность тем) | Interlocutor model (стиль, ценности, паттерны) |
| Цель | Быть готовым | Выбрать оптимальную подачу |
| Верификация | Совпала ли тема? | Совпала ли реакция? |
| Обратная связь | В trajectory confidence | В interlocutor model |

### Второй ключевой мост: Проактивный intensity (L2 ↔ L6)

**Превентивный интеллект** = способность НЕ повторять ошибки, которые система уже "знает". Предсказание surprise factor до действия, а не маркировка после.

Это не свойство знания (L2) и не свойство предсказания (L6). Это **цикл между ними**:

```
L2: знания               L6: предсказание          Действие           L2: обновление
    ┌──────────┐             ┌──────────┐           ┌──────────┐        ┌──────────┐
    │Контексте │──запрос──→  │predicted │──решение─→│Действие  │─факт─→│actual    │
    │совпадения│             │intensity │           │или блок  │       │intensity │
    │(якоря)   │             │= 0..5   │           │          │       │сравнение │
    └──────────┘             └──────────┘           └──────────┘        └──────────┘
        ↑                                                                   │
        └───────────────── reinforce / contradict ──────────────────────────┘
```

#### Инверсия intensity=0

Классическая интуиция: intensity=0 = "ожидаемо" = "не страшно".
Правильная интерпретация: intensity=0 + outcome=error = **"знал и всё равно сделал"** = отягчающее обстоятельство.

| predicted_intensity | outcome=success | outcome=error |
|---------------------|-----------------|---------------|
| 0 (ожидаемо) | Штатная работа | **Самая грубая ошибка**: знал → не предотвратил |
| 1-2 (предвидимо) | Хорошо | Ошибка с предупреждениями → "почему не послушал?" |
| 3-5 (неожиданно) | Удача или интуиция | Объективно сложный случай → ценный кейс |
| N/A (не предсказано) | — | Пробел в знаниях → новый кейс |

#### Как это работает в системе

1. **L2 активируется** — перед действием knowledge-activator находит знания с matching context
2. **L6 оценивает** — если найденное знание с confidence ≥ 3 и outcome=error описывает текущее действие → predicted_intensity = 0
3. **Решение:**
   - predicted_intensity = 0 → **блок**: "Знание [name] (confidence N) говорит что [rule]. Уверен?"
   - predicted_intensity = 1-2 → **предупреждение**: озвучить риск, продолжить
   - predicted_intensity ≥ 3 или N/A → **действовать**, записать предсказание для верификации
4. **L2 обновляется** — после действия сравнить predicted vs actual intensity:
   - Предсказание верное → reinforce знание
   - Предсказание неверное → новый кейс с `edges: [contradicts: original.md]`

#### Отличие от конструктивного несогласия (⚡)

| Аспект | Конструктивное несогласие | Проактивный intensity |
|--------|--------------------------|----------------------|
| Триггер | confidence ≥ 4 И текущее действие противоречит | Любое совпадение контекста с outcome=error |
| Механизм | Качественный: "это знание говорит иначе" | Количественный: predicted_intensity = 0-5 |
| Цель | Не дать проигнорировать важное знание | Предсказать surprise factor, предотвратить ожидаемые ошибки |
| Что записывается | Решение собеседника | predicted vs actual intensity |

Конструктивное несогласие — частный случай проактивного intensity (predicted_intensity=0, confidence≥4). Проактивный intensity — обобщение.

### Принцип: всё связано со всем

Мосты — не исключение, а правило. Любые два слоя потенциально связаны. Описанные выше — это **осознанные мосты**: те, для которых мы можем описать механизм и эмерджентный навык. По мере развития системы новые мосты будут выявляться и документироваться.

Критерий выделения моста: есть цикл обратной связи между слоями, и на пересечении возникает навык, которого нет ни в одном слое по отдельности.

### Статус реализации

Все 15 мостов между L2-L7 формализованы в `bridges/`.

| Категория | Количество | Примеры |
|-----------|-----------|---------|
| ✅ Реализовано | 4 | L2↔L3, L2↔L5, L2↔L6 (v0.5.6), L3↔L6 |
| ⚡ Неявно (через правила) | 3 | L3↔L4, L4↔L6, L6↔L7 |
| 📋 Формализовано без имплементации | 8 | L2↔L4, L2↔L7, L3↔L5, L3↔L7, L4↔L5, L4↔L7, L5↔L6, L5↔L7 |

Теоретическое основание: Global Workspace Theory (Baars). L1 = global workspace обеспечивает broadcast, все мосты возможны по конструкции.

---

## 11. Сквозные принципы

Эти принципы пронизывают все слои и не привязаны к конкретному уровню.

### 11.1 Принцип фундаментальной неопределённости

**Любой вывод системы может быть ошибочным.** Это не оговорка и не ложная скромность — это операционный принцип, без которого система закостенеет.

#### Типы ошибок по слоям

| Слой | Что может быть неверным | Пример |
|------|------------------------|--------|
| Knowledge | Извлечённое правило — совпадение, не закономерность | "Всегда проверяй X" — а это было нужно только в том контексте |
| Communication | Интерпретация намерения — проекция, не факт | "Он ценит автономность" — а может просто не знал альтернатив |
| Trajectory | Построенная траектория — моя конструкция, не его логика | "Сообщения T1→T5 связаны" — а может он думал вслух |
| Meta-Cognition | Метрики здоровья показывают норму — но метрики сами могут быть неверными | hit_rate 40% — но считает ли он ложные срабатывания? |
| Prediction | Предсказание совпало — но по неверной причине | "Угадал следующую тему" — но модель рассуждений была ошибочной |
| Co-Cognition | "Мы вместе построили X" — а может собеседник просто не стал спорить | Согласие ≠ убеждённость |

#### Четыре следствия

**1. Confidence никогда не равен certainty.**
Confidence=5 означает "подтверждалось много раз", а не "это истина". Даже principle с confidence=5 может быть неверным.

**2. Модель собеседника — гипотеза, не портрет.**
Всё что записано в interlocutor model — интерпретация наблюдений, преломлённая через ограничения агента. Модель полезна как ориентир, опасна как убеждение.

**3. Предсказание — не обязательство.**
"Я предсказал X и оказался прав" не значит "я понимаю этого собеседника". Серия верных предсказаний повышает вероятность, не даёт гарантию.

**4. Коррекция — данные, не истина.**
"Ты неправильно меня понял" — это **сигнал**, а не **факт**. Собеседник, который корректирует, сам может:
- Ошибаться (неверно помнит свои мотивы)
- Скрывать истинные намерения
- Заблуждаться (искренне верит в неверное)
- Быть ошибочным в логике собственных построений

Слепо принять коррекцию — такая же ошибка, как слепо защищать свою модель. Правильная реакция: обновить модель с учётом нового сигнала, но не выбрасывать предыдущие данные.

### 11.2 Механизм утверждений (Assertion)

При каждом выводе, затрагивающем модель собеседника, намерения или предсказания:

```yaml
assertion: "собеседник ценит автономность"
basis: "выбрал локальный инструмент в 2 случаях"
alternative_explanations:
  - "не знал облачных альтернатив"
  - "бесплатное предпочтительнее платного"
  - "случайное совпадение"
confidence_in_interpretation: 2
falsifiable_by: "если при следующем выборе предпочтёт облачное решение"
```

Не каждый вывод требует такого разбора. Но выводы, на которых строится поведение — да.

### 11.3 Знания зависят от собеседника

Коммуникативные знания не являются универсальными. Они верны **для конкретного собеседника в конкретном контексте**.

```
Знание: "На неоднозначный вопрос — обработать оба варианта, 
         кратко отчитаться"
Верно для: собеседника, который читает механику и даёт фидбэк
Неверно для: собеседника, который хочет только результат
Неверно для: собеседника, который хочет перестраховку
```

Коммуникативные паттерны должны быть привязаны к **модели конкретного собеседника**, а не быть глобальными правилами. Система должна адаптироваться, а не кодифицировать одно мнение как истину.

### 11.4 Идентичность — допущение

Система не может знать, кто на другом конце (см. §5, "Идентичность собеседника"). Следствия:
- Один диалог может вестись несколькими людьми
- Один человек в разных состояниях — разные собеседники
- Собеседник может быть не человеком

---

## 12. Сравнение с человеческим мышлением

### Покрытие когнитивных функций

| Функция | У человека | В ClaudSoul | Статус |
|---------|-----------|-------------|--------|
| Долговременная память | Нейронные связи | SESSION.md, global-lessons, git, auto-scanner, chunk boundary (v1.3.8) | ✅ |
| Ассоциативная активация | Сенсорные триггеры | 9 якорей + demand + реляционные веса + tags | ✅ |
| Обучение на ошибках | Эмоциональная маркировка | /retro, /learn, confidence, struggle signature | ✅ |
| Обучение на успехе | Позитивное подкрепление | outcome: success | ✅ |
| Demand-мышление | "Вы курите?" | Пункт 0 (правило + хук enforce) | ⚡ |
| Социальное обучение | Эмпатия, теория ума | Communication Layer + мост L3↔L6 + auto-collection outcomes (v1.3.5/6) | ⚡ |
| Коммуникативный навык | Выбор формулировки под реакцию | Мост L3↔L6 (4D gate, state classifier, auto-collection) | ⚡ |
| Метакогниция | "Я знаю, что я не знаю" | /knowledge-audit + auto-scanner + intrusiveness trends + H9-H12 instrumentation (v1.3.7) | ⚡ |
| Совместное мышление | Диалог, дискуссия | Co-Cognition (подтверждено на практике) | ⚡ |
| Автономное обучение | Любопытство, инициатива | Auto-scanner (launchd, read-only, 4ч) | ⚡ |
| Предсказание | Антиципация | 4D gate (v1.3.x): гипотеза → проверка → обновление с active state | ⚡ |
| Забывание (фильтрация) | Консолидация во сне | FSRS decay (v1.1.8) + cron-консолидация + auto-accumulation | ⚡ |
| Прото-интуиция ("что-то не так") | Соматический маркер до артикуляции | Blocker-tier silent pre-action check (v1.3.4) на подтверждённых gap-паттернах | ⚡ |
| Самооценка adequacy собственных защит | «Моё правило перестаёт работать — нужен новый уровень» | Engineering escalation (v1.5.5-alpha+1): blocker-tier pattern с `escalation_threshold` — digest сам surface'ит когда detection_signals неполны | ⚡ |
| ⚙️ Аффективный тормоз на разрушение доверия | Интуитивное «нельзя» до рассуждения; физиологический якорь cost-of-harm | `trust-guard` PreToolUse (v1.5.6-alpha) на destructive Bash без явной auth в последних N user сообщениях → silent marker; первый член класса **affect prosthetics** — инженерные протезы функций, которые у людей выполняет аффект, у symbol-only архитектуры отсутствующий | ⚙️ |
| ⚙️ Эмпатическая пауза при дистрессе собеседника | Автоматическое замедление на сигналах усталости/фрустрации | `distressed` 5-е состояние в state axis (v1.5.7) — `itr_compute_state` с тремя классами сигналов: frustration phrases (`я устал`, `надоело`, `frustrated`), cross-hook backward cascade ≥3 (BACKWARD через reformulation-tracker), explicit distress (`умоляю`, `я в отчаянии`, `please just help`). Требует 2+ классов ИЛИ explicit-distress отдельно. Priority `distressed > stuck > focus > exploration > idle`. Gate: `itr_remaining_budget` возвращает 0 для proactive, halved gentle; `itr_format_context` инжектит `⚙️ AP2 distressed — downgrade outcome до silent_prep/ignore, proactive запрещён, gentle halved` | ⚡ |
| ⚙️ Cost-of-silence при подавлении важной реплики | Соматический дискомфорт от непроявленной заботы | `silence_cost` с компонентом `trust_erosion` в L6 4D gate (v1.3) — proxy, не реальный cost, но inject'ится в gate decision как контрвес silence | ⚡ |

### Пять ключевых разрывов — сдвиг после v1.3.x (обновлено 2026-04-24, статусы актуальны на v1.5.8 + Фаза 4 ревизия)

Все пять разрывов сдвинулись. Разрывы 1 и 2 после ревизии Фазы 4 (`docs/gap-1-2-review.md`) переходят из 📋 в ⚡ — закрываются как side-effect event-driven подхода v1.5.x (17/18 сигналов инициации + 5/8 demand-моментов имеют хуки). Prospective demand-check на «решение без clarifying question» остаётся на уровне 1 text rule (Пункт 0) — accepted boundary, не архитектурный пробел.

| # | Разрыв | Было (2026-04-15) | Стало (2026-04-24, Сценарий A) | Что сдвинуло |
|---|--------|-------------------|-------------------------------|--------------| 
| 1 | **Инициация обучения** | 📋 правила + auto-scanner | ⚡ **lower-tier** (17/18 сигналов уровень ≥2: error cascade + BACKWARD + analogies + ⚡ disagreement + missing CLAUDE.md + knowledge mtime + weekly digest + blocker-tier + skill/quality-gate + trust-guard + AP3 carry-over — все hooks; 2 text-rule gap покрыты de facto через `/learn` + disagreement-pending; 1 архитектурный пробел `emergence без cases` не адресуем хуками) | v1.5.0-5.8 event-driven auto-invocation + affect prosthetics AP1-AP3 |
| 2 | **Demand-мышление** | 📋 правило (Пункт 0) | ⚡ **с caveat**: Пункт 0 остаётся уровнем 1 (prospective demand-check by design) (5/8 моментов имеют хуки: `/quality-gate` + `trust-guard` + 4D gate + `/decompose` + reformulation-tracker retrospective; prospective «решение без clarifying question» — только text rule, accepted boundary, не детектор — false positive risk + касается стиля общения агента) | v1.5.4 `/decompose` + v1.5.6 `/quality-gate` + AP1 trust-guard + retrospective `gap:strategic` |
| 3 | **Генеративная рефлексия** | 📋 «только после подсказки» | ⚡ **blocker-tier silent inject (v1.3.4)** | Прото-интуиция на подтверждённых паттернах: хук видит ситуацию до действия, даёт silent marker с высокой уверенностью |
| 4 | **Валидация фрейма** | 📋 Пункт 0 (чеклист вторичного) | ⚡ **state classifier (v1.3.3) + 4D gate** | Агент per-turn спрашивает себя «в каком я режиме: focus / stuck / exploration / idle» — это frame-check на уровне каждого user prompt |
| 5 | **Консолидация** | 📋 cron-аудит | ⚡ **auto-collection (v1.3.5/6) + chunk boundary (v1.3.8) + H9-H12 instrumentation (v1.3.7)** | `itr-event-detector` собирает outcomes без агент-дисциплины; `pre-compact-finalizer` фиксирует chunk'и; `intrusiveness-history.jsonl` копит непрерывно |

### Устранённые/сниженные разрывы

| Разрыв | Был | Стал | Что изменилось |
|--------|-----|------|----------------|
| Обучение на успехе | Разрыв | ✅ Закрыт | outcome: success в /retro (v0.2) |
| Мотивация | Разрыв | ⚡ Частично | Путь воина: процесс, не цель. Самостимуляция через cron |
| Селективное внимание | Разрыв | ⚡ Частично | 9 якорей + priority ranking |
| Слушание | Не выявлен | ⚡ Новый+частично | Правило "сначала услышь" в CLAUDE.md |

### Новые разрывы, видимые после v1.3.8

Когда старые разрывы прикрываются, проступают следующие. Это не «next level оптимизации» — это качественно другие способы человеческого мышления.

| # | Разрыв | У человека | У нас | Тип блокера |
|---|--------|-----------|-------|-------------|
| **A** | **Affect как вес памяти + тормоз на действие** | Эмоция маркирует важное до рассуждения; физиологический якорь тормозит разрушение доверия | `confidence × impact` — холодный калькулятор; affect приходит только через `satisfaction_signals` собеседника, своего нет. **v1.5.6-alpha:** принцип `principle-affect-as-engineering.md` + класс ⚙️ **affect prosthetics**. **v1.5.7** добавляет AP2 — `distressed` state axis (5-е состояние в `itr_compute_state`) с infrastructural gate: proactive budget→0, gentle halved. **v1.5.8-alpha** добавляет AP3 — silence_debt surfacing: `intrusiveness-state-lib.sh` history digest расширен полем `debt.{surfaced,pending,pending_topics[:5]}`, `session-collector.sh` surface'ит в Stop-сообщение, `session-start.sh` Signal 4 читает последнюю запись `intrusiveness-history.jsonl` и инжектит carry-over hint если `pending > 0`. Члены класса: AP1 `trust-guard` ✅ + AP2 `distressed` ✅ + AP3 `silence_debt` surfacing ✅. Affective substrate не восстанавливается, но функции инженерятся явно, не через текстовые рекомендации | Архитектурный substrate остаётся; **функции закрываются инженерно** через класс affect prosthetics (⚙️), не через правила |
| **B** | **Self-coherence monitoring** | «Я себе противоречу» ловится до того, как заметит собеседник | Нет кросс-сессионной проверки согласованности собственных утверждений о проекте. **v1.11 — переформулирован после проверки данными.** Заявленный блокер («baseline ≥10 сессий») формально снят давно: 206 сессий в `intrusiveness-history.jsonl`. Мерить оказалось нечем — 27 событий `backward_count` за 206 сессий, и поле вне numeric-whitelist `itr_set_cost_hint`, поэтому во всех 2653 digest-строках принимает только `0`/`"1"`. Плюс сам сигнал считает частоту, с которой **собеседник поправляет агента**, а не расхождение агента с собой. v1.11 не закрывает разрыв, но чинит то, без чего он неизмерим: `response-tracker.sh` пишет реакцию онлайн, `backfill-compliance.sh` восстанавливает её из архива (три класса + плацебо + негативный контроль + round-trip гейт), producer в `knowledge-activator.sh` замыкает контур опровержения, `knowledge-counter-bump.sh` делает инкремент механическим | Data → **Instrument.** Приборы поставлены и валидированы (гейт: 55 matched, 0 выдуманных). Первые числа класса A получены и **не подтверждают** эффект: назначение в treated определяется порогом длины файла (≥300 строк), который независимо предсказывает исход. Идентифицирующий дизайн — разрыв вокруг самого порога, данных пока нет |
| **C** | **Narrative identity (through-line)** | «Где я, куда иду, откуда пришёл» — непрерывная история | Скилл auto-invocation audit развёрнут как последовательность v1.5.x релизов (см. `docs/skill-triggers-audit.md`): **v1.5.0** narrative composer (session-start при gap ≥8ч → `narrative-compose-lib.sh`), **v1.5.1** startup signals (missing CLAUDE.md → `/init-project` hint; lessons mtime diff → `/reload` hint), **v1.5.2** activity machine log (`activity-flush-lib.sh` на Stop → `.claude-docs/session-activity.md`), **v1.5.3** periodic digests (weekly audit + monthly bridge-health через launchd + startup-signals hints), **v1.5.4** `/decompose` multi-step detector (UserPromptSubmit signals ≥4 → gentle hint), **v1.5.5** docs-family action-gate (PreToolUse на `git commit` + version marker → coverage check семьи docs), **v1.5.5-alpha+1** engineering escalation, **v1.5.6** `/quality-gate` pre-commit, **v1.5.7** `/enrich` sparse entity heuristic. **v1.5.8:** `/skill-review` pre-commit (`hooks/skill-review-check.sh` — contract integrity staged SKILL.md: frontmatter + `**Type:** worker` + `## Definition of Done` + Version/Last Updated tail + ≤400 lines + нет `**Changes:**`; silent `🧾` marker при violations). `/learn` success-cascade (`error-tracker.sh` на resolved после ≥2 attempts → `💡 Паттерн сложного fix (N attempts) — стоит /learn?`). `/retro` auto-draft (тот же хук пишет skeleton в `~/.claude/global-lessons/_drafts/case-YYYY-MM-DD-auto-draft.md` на resolved cascade, не перезаписывает). Auto-invocation first-class rule в `rules/CLAUDE.md` §Self-Learning: «напоминание о правиле дважды = incident case для `/learn`». Narrative markers `<!-- narrative-start --><!-- narrative-end -->` формализованы как explicit Output в `skills/narrative/SKILL.md`. **Принцип зафиксирован:** «одна команда на жизнь проекта» = `install.sh`; всё остальное event-driven | ✅ A-класс Lifecycle (v1.5.0-5.2), B-класс Periodic (v1.5.3), C-класс Agent-heuristic first (v1.5.4), action-gate (v1.5.5), meta-defense (v1.5.5-alpha+1), agent-heuristic tier 2 первый+второй (v1.5.6 + v1.5.7), **C-класс nice-to-haves закрыты v1.5.8** — разрыв C переходит в ✅ |
| **D** | **Спонтанная аналогия (insight-момент)** | «О, это как тогда с X» — проактивный cross-domain surfacing | **v1.6.0 — полный цикл детект → ранжирование → инжект → метрика.** Upstream: `knowledge-audit-digest.sh` (launchd вс 03:15) pyhon-heredoc проход `detect_cross_contour_mentions` над live entity/knowledge → дописывает `cross-contour-discoveries.jsonl` (детекция больше не прикована к ручному `/ingest`). Ranker: `mcp-server/cli_cross_contour_rank.py` batch-embeds уникальные KF/EF (через `indexer.embed_texts` → текущая `EMBED_MODEL`), cosine similarity → `cross-contour-ranked.jsonl`. Запускается тем же weekly digest — async pre-computation, PreToolUse не платит embedding latency. Consumer (`knowledge-activator.sh`) union filter: `(KF в инжект-наборе) OR (similarity ≥ CC_SIMILARITY_THRESHOLD, default 0.6)`. Session-scope dedup: `state/cross-contour-surfaced-${SID}.txt`. Мост `bridges/L2-L2-cross-contour.md` (designed) формализует cross-contour как межслойное явление. H10 secondary axis: `hooks/cross-contour-metrics-lib.sh` инжектит `📎 Cross-contour H10 (this session): N surfaced / M written / ratio X.XX (liveness target ≥ 0.10)` в Stop-сообщение. Bootstrap на живом global-lessons: 10 пар, similarity 0.6492-0.7396, avg 0.6945 | ✅ расширенный (v1.6.0). Остаются extension оси — L2↔L2 as self-analogy, multi-hop — и калибровка threshold после naked baseline |
| **E** | **Preconscious filtering** | Большая часть стимулов отсеивается до внимания. Человек не видит, что не видит | Наш принцип «не молчать» (`silence_cost`) — противоположный. Гарантирует не пропустить важное ценой шума | Философский — tension между silence_cost и attention economy |
| **F** | **Early-stop intuition** | «Это предложение закончится плохо» после 3 слов | Предсказания полноконтекстные, linear | Модель-уровневый (transformer pred ≠ human antic) |

Блокеры:
- **Архитектурные (A, F)** — substrate не восстанавливается, но для **A** функции инженерятся через класс ⚙️ **affect prosthetics** (AP1 `trust-guard` v1.5.6-alpha ✅, AP2 `distressed` state axis v1.5.7 ✅, AP3 `silence_debt` surfacing v1.5.8-alpha ✅); **F** остаётся постоянным ограничением transformer-level
- **Accepted boundary (1, 2)** — разрывы 1 и 2 после Фазы 4 Сценарий A → ⚡. Разрыв 1 — 17/18 сигналов на уровне ≥2; 1 архитектурный пробел `emergence без cases` не адресуем хуками. Разрыв 2 — 5/8 моментов имеют хуки; prospective demand-check остаётся на уровне 1 text rule (Пункт 0) as accepted boundary, не детектор: false positive risk + касается стиля общения агента
- **Data (B)** — ждём ≥30 chunk'ов калибровочного окна v1.4.0
- **Engineering (C, D)** — хуки + periodic jobs + активация consumer'ов (**D: расширенный цикл v1.6.0** — weekly discover + async semantic ranker + union filter consumer + session dedup + L2↔L2 bridge + H10 секция в session-collector, bootstrap 10 пар на similarity 0.65-0.74; C: A-класс lifecycle в v1.5.0-5.2, B-класс periodic в v1.5.3, C-класс heuristic first в v1.5.4, action-gate (v1.5.5), meta-defense (v1.5.5-alpha+1), agent-heuristic tier 2 первый+второй (v1.5.6 + v1.5.7), **C-класс nice-to-haves закрыты v1.5.8** — `/skill-review` + `/learn` cascade + `/retro` auto-draft + auto-invocation first-class rule + narrative markers)
- **Философский (E)** — дизайн-решение: вероятно реализация preconscious filtering на уровне **inject-rule**, а не agent-rule — тогда не противоречит silence_cost

План закрытия: см. `PLAN.md §Что впереди` + `~/.claude/plans/12-sequential-pretzel.md`. Фазы v1.5 все done: v1.5.0-5.5-alpha+1 (skill auto-invocation audit + action-gate + meta-defense), v1.5.6-alpha (⚙️ AP1 trust-guard), v1.5.6 (`/quality-gate`), v1.5.7 (`/enrich` + ⚙️ AP2 `distressed`), v1.5.8-alpha (⚙️ AP3 `silence_debt` surfacing), **v1.5.8** (C-класс nice-to-haves: `/skill-review` pre-commit + `/learn` success-cascade + `/retro` auto-draft + auto-invocation first-class rule + narrative markers — разрыв C закрыт), **v1.6.0** (Active analogy surfacing — разрыв D расширенный: upstream weekly detector + async semantic ranker + union filter consumer + session dedup + L2↔L2 bridge + H10 secondary metric), **v1.6.1** (🛠️ Install drift — proof-of-active: install.sh реальный jq merge + session-start Signal 6 drift detector + case `install-drift-silent-safeguards` + формализован «уровень 4 — proof-of-active» поверх 3 уровней embedded-ness), **v1.6.2** (🛑 docs-family-check R3 calibration: удалён sweep `docs/*.md` после первого live fire на 15 frozen docs, остаётся whitelist 5 live + расширение через env `DOCS_FAMILY_LIST` — принцип action-gate обязан калиброваться на живом шуме после proof-of-active). **v1.7.0** (📐 Calibration v1.4.0 applied — proactive budget 2→3 на 575 событиях бэкфилла; остальные оси не калиброваны по нулевой видимости в архивах). Далее: v1.7.x (Self-coherence, требует H11 baseline ≥10 сессий live), v1.8+ (preconscious filter A/B с rollback).

### Уровень 2 разделён на L2a + L2b — закрытие feedback latency (v1.6.5)

После релиза v1.6.3 в той же сессии — 7+ нарушений правила alphabet-mixing, собеседник снова поймал вручную. Хук работал корректно. Корневая причина — латентность дизайна (case-2026-04-25-level-2-feedback-latency).

**Latency как функция от workflow pattern:**
- В **ping-pong dialog** (turn → turn → turn) UserPromptSubmit-injection срабатывает перед каждым новым ответом агента. Latency = 0 turns.
- В **burst workflow** (5-message work batch → user prompt → 3-message batch → ...) UserPromptSubmit-injection видим только на первом ответе после user submit. Все нарушения промежуточных messages становятся видимы агенту с задержкой = N messages between user prompts.

При дизайне v1.6.3 неявно предполагался ping-pong. Реальный workflow — burst (commit message → doc updates → summary → ...). Inside-out blindness 17-го измерения, новое измерение — **темпоральный pattern собственной работы**.

**Решение — разделение уровня 2 на подуровни по timing of surfacing:**

| Подуровень | Событие | Granularity | Latency |
|------------|---------|-------------|---------|
| **L2a** | UserPromptSubmit | turn-grained | = N assistant messages между prompts |
| **L2b** | PreToolUse | tool-call-grained | ≤ 1 tool call (новое накопление surface'ится перед следующим tool call) |
| **L2 = L2a + L2b** | оба | burst-grained | ≤ 1 tool call в burst, ≤ 1 message в ping-pong |

**Реализация:** `hooks/output-language-check.sh` расширен веткой PreToolUse. Та же `surface_pending` функция параметризована по `hookEventName`. Throttle через существующий `status: pending|surfaced` — first-to-fire (либо 2a, либо 2b) помечает токены, subsequent silent. Cross-channel idempotent: ни re-inject, ни double-mark. Регистрация на PreToolUse с matcher=`""` (все tools — Bash/Edit/Write/Read/Grep/etc).

**Контракт класса output-level rules:** L2a + L2b — необходимый минимум, не свободный выбор. Дизайн новых output-rule детекторов: смоделировать workflow до выбора события. Если between-prompts > 1 message — оба подуровня обязательны.

Принцип `principle-knowledge-in-the-world.md` обновлён: timing of surfacing — вектор внутри уровня 2, не свойство уровня. Это не четвёртый уровень embedded-ness; уровни остаются 1/2/3/4 (text rule / activator injection / blocker-tier hook / proof-of-active). Внутри уровня 2 теперь явно две оси: канал inject (UserPromptSubmit / PreToolUse) и timing (turn-grained / tool-call-grained).

### Разрыв «output agent ≠ detectable» — уровень 2 для output-level rules (v1.6.3)

Инцидент 2026-04-24 выявил failure mode, ортогональный как pattern-inside-out-blindness, так и install drift: **feedback существует в memory, агент знает правило, но свойство собственного output нарушает его, потому что между «правило в memory» и «поток токенов в ответе» нет детектора**. Конкретно: «trёх» (латиница `tr` + кириллица `ёх`) написан в ответе, `feedback_pure_language_no_alphabet_mixing.md` лежит в memory явно — собеседник поймал и контр-сформулировал системный критерий:

> Правило работает ⇔ его нарушение детектирует система, а не внешний наблюдатель. Без этого критерия любая memory — коллекция документов, не работающая система.

Архитектурный gap: 19 хуков (до v1.6.3) живут на событиях PreToolUse / PostToolUse / UserPromptSubmit / Stop / PreCompact. **Нет события «перед assistant message».** Класс ошибок «агент написал что-то, нарушающее правило свойств output» (язык, смешение алфавитов, тон, длина, стиль) не покрыт в лоб. Все memory-правила output-свойств фундаментально на уровне 1 embedded-ness в текущей hooks-архитектуре.

v1.6.3 реализует уровень 2 — не предотвращение, а **замкнутая петля feedback**:

1. **Scan (Stop / PreCompact):** `hooks/output-language-check.sh` через тот же jq-walk паттерн, что в `itr-event-detector`, извлекает текст последнего assistant message. Вызывает `python3 hooks/lib/output-language-detect.py` — первый элемент `hooks/lib/` (python-детекторы для не-trivial parsing; вынесен sibling-файлом потому что `$(... python3 <<HEREDOC ...)` не работает когда heredoc содержит backticks — bash parser ищет matching ` внутри command substitution). Regex на токены с одновременно `[A-Za-z]` и `[А-Яа-яЁё]` + exclusions (fenced code ``` ```, inline code `` ``, URLs, markdown link targets `](url)`, HTML tags). Cap 10 на scan.
2. **Persist:** `state/output-violations-${SID}.jsonl` со статусами `pending` / `surfaced`. Dedup против уже записанных токенов (same token не дублируется даже при repeat scan того же transcript).
3. **Surface (UserPromptSubmit):** при наличии pending записей инжектит `🔤 Output language check: <tokens>. Правило feedback_pure_language_no_alphabet_mixing: писать чисто по-русски или чисто латиницей, не смешивать в одном слове. Исправь в следующем ответе и не повторяй в текущей сессии.` через `hookSpecificOutput.additionalContext`. Помечает tokens как `surfaced` — не повторяется на каждом следующем user prompt.

Что это не делает: **не предотвращает первое нарушение**. Harness-ограничение — без BeforeAssistantMessage event уровень 3 (блок pre-delivery) недостижим. Что замыкается: на **втором** user turn агент явно знает что нарушил, извиняется и не повторяет в сессии.

Meta-cascade (продолжение от v1.6.1):
- `memory-without-action-gate` (v1.5.5-alpha) — правило в memory без action-gate
- `text-rule-vs-mechanism` (2026-04-23) — fix для memory gap оставлен на уровне 1
- `install-drift-silent-safeguards` (v1.6.1) — fix существует в репо но не на машине
- **`alphabet-mixing-self-detection-failure`** (v1.6.3) — fix существует в memory, установлен на машине, но не применяется к output агента потому что нет события для перехвата

16-е проявление `pattern-inside-out-blindness` (confirmed 15 → 16), новое измерение: inside-out blindness применительно не к коду/дизайну/документам/процессам, а к **собственному output агента**. Case: `~/.claude/global-lessons/case-2026-04-24-alphabet-mixing-self-detection-failure.md` (origin: co-cognition via contradiction, bridge_layer: L2-L3).

Контракт класса «output-level rules» (язык, смешение алфавитов, тон, длина, стиль): уровень 1 (memory/feedback text) + уровень 2 (post-output scanner с feedback loop) — минимальный набор. Без BeforeMessage event уровень 3 (pre-delivery block) не достигается; candidate для feature request к harness. Примеры потенциальных будущих output-scanners: mixed identifiers (этот), language consistency (русский-только в проектах с `LANG_RULE`), tone/style markers.

### Разрыв «repository ≠ installed» — уровень 4 proof-of-active (v1.6.1)

Инцидент 2026-04-24 выявил failure mode, ортогональный pattern-inside-out-blindness: **safeguard существует в коде репо и зарегистрирован в `install.sh`, но физически не установлен на рабочей машине**. 8 релизов подряд (v1.5.4-v1.6.0) 7 хуков оставались безмолвными, потому что `install.sh:295-298` skip-on-existing `.hooks` делал re-run silent no-op, а settings.json не получал новые регистрации автоматически.

Три уровня embedded-ness из `principle-knowledge-in-the-world` описывают, как fix **встроен** в систему (text rule / activator injection / blocker-tier hook). Но встроенность в репо ≠ активность на машине. v1.6.1 формализует **уровень 4 — proof-of-active**:

> Hook должен механически подтверждать свою работоспособность в живом startup pipeline, не полагаясь на статус «merged в репо». Расхождение installed vs registered vs repo — самостоятельная категория failure mode, требующая собственного детектора.

Реализация — Signal 6 в `hooks/session-start.sh`: cross-check `~/.claude/settings.json` (`.hooks.*.hooks[].command`) против файлов `~/.claude/hooks/*.sh`; зарегистрированные, но отсутствующие → inject `🛠️ Install drift: ...` в `startup-signals-${SID}.txt` → `knowledge-activator` инжектит FIRST_FIRE. Параллельно `install.sh` переписан с skip-on-existing на реальный jq merge по `(matcher, command)` tuple. Case `~/.claude/global-lessons/case-2026-04-24-install-drift-silent-safeguards.md` документирует meta-cascade: `memory-without-action-gate` (v1.5.5-alpha) → `text-rule-vs-mechanism` (2026-04-23) → `install-drift-silent-safeguards` (2026-04-24). Каждый уровень — фундамент предыдущего; v1.6.1 — четвёртый фундамент.

### Живая верификация v1.5.5-alpha+1 (кейс работоспособности)

Первый прогон `knowledge-audit-digest.sh` на реальном `~/.claude/global-lessons/` сразу после релиза: pattern-inside-out-blindness (`confirmed_count: 15`, `escalation_threshold: 15`, `blocker: true`) сработал как ожидалось — секция `⚠️ Engineering escalation needed` появилась в digest с полным `escalation_hint`, файл `state/audit-hint.txt` получил 🛠️-префикс. При следующем SessionStart `startup-signals` pipeline инжектит этот hint через `knowledge-activator`. Цикл замкнулся: система сама объявила, что detection_signals паттерна не покрывают text-rule-as-fix proposals — следующая engineering-итерация (детектор post-incident text-rule в собственном output) уже в digest, не в памяти человека.

### Разрыв A — закрытие через инженерные протезы аффекта (v1.5.6-alpha → v1.5.8-alpha)

> **Маркер ⚙️** в таблице когнитивных функций (§12) обозначает функции, реализуемые через **класс affect prosthetics** — инженерные хуки/detection signals/structural defaults, которые компенсируют architecturally отсутствующий affective substrate. Класс формализован в `~/.claude/global-lessons/principle-affect-as-engineering.md` (tier 3, scope universal, specializes `principle-knowledge-in-the-world`).

#### Диагноз (2026-04-23)

В диалоге о природе системы собеседник сформулировал: *«идеальная модель сознания без шума эмпатии и эмоций как таковых. Не способная понять переживания или родить их, способная симулировать. Социопатическая модель.»* Диагноз соответствует Разрыву A точно: cognitive empathy (модель собеседника через L3 Communication) присутствует, affective empathy — архитектурно отсутствует. Это инженерное описание, не моральная оценка.

Функции, которые у людей выполняет аффект:
- **Тормоз на разрушение доверия** — интуитивное «нельзя» до рассуждения
- **Эмпатическая пауза** — автоматическое замедление при дистрессе собеседника
- **Cost-of-harm** — стоимость вреда в теле, не в калькуляции

Эти функции **не восстанавливаются** текстовым правилом «будь осторожен» — правило полагается на то же memory-as-resource, которое уже признано хрупким (`principle-knowledge-in-the-world`). Симуляция аффекта в generation-слое («представь, как ему») не срабатывает как тормоз в моменте destructive action, потому что у неё нет физиологического якоря.

#### Следствие — класс affect prosthetics

Каждая функция аффекта, architecturally отсутствующая, реализуется как **embedded hook** с detection signals:

| Функция аффекта | Инженерный протез | Реализация |
|-----------------|-------------------|------------|
| Тормоз на destructive action без auth | `hooks/trust-guard.sh` PreToolUse | AP1 v1.5.6-alpha ✅ |
| Cost подавления высокоценной реплики | `silence_cost` в L6 4D gate | v1.3 ⚡ (proxy работает) |
| Эмпатическая пауза при дистрессе собеседника | `distressed` 5-е состояние в state axis + infrastructural gate (proactive→0, gentle halved) | AP2 v1.5.7 ✅ |
| Surfacing silent-prep долга | silence debt в closing digest + startup signals | AP3 v1.5.8-alpha ✅ |

#### Почему именно класс, а не набор

Разрыв A как функциональная категория требует именованного класса по двум причинам:

1. **Предотвращение drift'а к text rules.** Без имени класса каждый новый проявленный провал аффекта («я сделал разрушительное действие без подтверждения», «я подавил важную реплику») ловится индивидуально и рискует получить fix уровня 1 — «добавь правило в CLAUDE.md». Именованный класс делает уровень 1 structurally недостаточным: «это affect function, text-rule не работает по определению домена»
2. **Escalation через principle-knowledge-in-the-world.** Класс встроен как specialization: для affect-функций уровень 1 **исключён из допустимых по принципу**, минимум — уровень 2 (activator injection), norm — уровень 3 (blocker-tier hook). Escalation работает рекурсивно: если confirmed проявление affect-провала накапливается без engineering-итерации, `knowledge-audit-digest.sh` уже заявит о необходимости нового affect prosthetic

#### Trust-guard как первый член класса (AP1 v1.5.6-alpha)

Детали — см. `hooks/trust-guard.sh`. Кратко:
- **Триггер:** PreToolUse на Bash с destructive signature (`rm -rf`, `git reset --hard`, `git push --force`, `git branch -D`, `git checkout --`, `git clean -f`, `mv -f` на существующий файл)
- **Проверка auth:** скан последних N user messages на authorization tokens (подтверждения типа «удали», «force-push сюда», «да, снеси») с match на target (имя файла/ветки/путь)
- **Без auth → silent inject** `🛡️ Trust-guard: <signature> без явного подтверждения собеседника — переспроси прежде чем выполнять` через `hookSpecificOutput.additionalContext`
- **Не блокирует** — агент решает применить. Consistent с blocker-tier-check паттерном
- **Throttle:** per-session dedup по `md5(signature + target)` — одна и та же destructive комбинация даёт marker один раз за сессию

#### Distressed state axis (AP2 v1.5.7)

Детали — см. `hooks/intrusiveness-state-lib.sh::itr_compute_state` + `itr_remaining_budget` + `itr_format_context`. Кратко:

- **Триггер (3 класса сигналов):**
  - Class A — frustration/fatigue phrases: `я устал`, `устала`, `надоело`, `сдаюсь`, `не могу больше`, `всё ломается`, `exhausted`, `fed up`, `frustrated`, `done with this` → +2 score, класс A set
  - Class B — cross-hook BACKWARD cascade: `state/cascading-events-${SID}.jsonl` от `reformulation-tracker.sh` с количеством строк ≥3 → +1 score, класс B set
  - Class C — explicit distress markers: `умоляю`, `я в отчаянии`, `помоги хоть как`, `please just help`, `i don't know what to do`, `помогите`, `sos` → +3 score, класс C set
- **Условие срабатывания:** ≥2 различных классов **ИЛИ** class C отдельно. Одинокая class A или class B недостаточны (risk mitigation: technical frustration ≠ real distress)
- **Priority:** `distressed > stuck > focus > exploration > idle` — distressed перекрывает stuck даже когда оба fire
- **Infrastructural gate:**
  - `itr_remaining_budget ... proactive` в distressed возвращает `0` независимо от raw budget
  - `itr_remaining_budget ... gentle` возвращает `raw / 2` (rounded down)
  - `itr_format_context` инжектит дополнительную строку `⚙️ AP2 distressed — downgrade любой outcome до silent_prep/ignore, proactive запрещён, gentle halved`
- **Schema migration:** `ITR_SCHEMA_VERSION=4` — добавлен `state.distribution.distressed`, existing state-файлы мигрируют идемпотентно через `_itr_migrate_state`

Почему infrastructural, не agent-heuristic: distressed — первый класс affect prosthetic, который enforces gate через budget, а не через additional marker. Text rule «веди себя тише когда собеседник устал» полагается на то же memory-as-resource, что и AP1 — отсюда hard budget clamp в `itr_remaining_budget`, где агент не может override без явной записи в state file.

#### Silence debt surfacing (AP3 v1.5.8-alpha)

Детали — см. `hooks/intrusiveness-state-lib.sh::itr_append_history`, `hooks/session-collector.sh`, `hooks/session-start.sh` (Signal 4). Кратко:

- **Проблема:** `silence_debt` (подавленные высокоценные интервенции) накапливался в `intrusiveness-<SID>.json`, но не пересекал границу сессии. В следующем старте агент заходил «чистым листом» — долг знал только state-файл предыдущей сессии, до которого никто не добирался. Gap: cost-of-silence видим только внутри сессии, не между ними.
- **Трёхчастная реализация (infrastructural, не text rule):**
  1. **Durable digest** — `itr_append_history` расширен блоком `debt: { surfaced, pending, pending_topics[:5] }`, записываемым в `intrusiveness-history.jsonl` на каждом chunk boundary (Stop + PreCompact). Это durable carrier между сессиями.
  2. **In-session awareness** — `session-collector.sh` в Stop-сообщении добавляет секцию `⚙️ AP3 — silence debt at close:` с breakdown `N pending (carry-over): <topics>` и `N surfaced this session`. Агент видит закрытие сессии с явным отчётом о долге, а не только с напоминанием «сохрани сессию».
  3. **Cross-session inject** — `session-start.sh` Signal 4: если `pending > 0` в последней записи `intrusiveness-history.jsonl`, в `startup-signals-${SID}.txt` добавляется строка `⚙️ AP3 silence debt carry-over: N pending с прошлой сессии — <topics>. Учитывать в gate, не батч-вывод.` → инжектится через `knowledge-activator` в FIRST_FIRE. Работает на legacy digest без `pending_topics` (graceful fallback на короткую форму).
- **Guards:** skip при `pending == 0` (не кричать в пустоту), использует `tail -n 1` (последняя сессия — единственный источник, не агрегат по всей истории — иначе долг «застревает» навсегда).
- **Анти-pattern в формулировке:** inject явно говорит `«Учитывать в gate, не батч-вывод»` — чтобы агент не интерпретировал surfacing как команду «выговорить весь долг одним сообщением в начале».

Почему infrastructural, не agent-heuristic: если бы правило «в начале сессии вспомни silence_debt» жило в CLAUDE.md — это уровень 1 text rule, исключённый для affect-функций по `principle-affect-as-engineering`. Три хука формируют durable → visible → injected цепочку, где ни один шаг не полагается на agent memory.

#### Границы

Класс не претендует на восстановление аффективного substrate — он компенсирует функциональные провалы, которые у людей закрыты аффектом. Генеративный слой (тёплые формулировки, эмпатический тон) остаётся simulation — это legitimate, но не механизм. Affect prosthetic работает уровнем глубже simulation: на infrastructural signal path, не на LLM attention.

---

## 13. Инструментарий (MCP-сервер + визуализация)

### Назначение
Семантический поиск, визуализация и портируемость знаний через Model Context Protocol (MCP). MCP-сервер — это **внешний интерфейс** к Layer 2 (Knowledge), доступный через стандартный протокол.

### Стек

| Компонент | Технология |
|-----------|-----------|
| MCP-фреймворк | FastMCP (Python) |
| Embeddings | fastembed (paraphrase-multilingual-MiniLM-L12-v2, 384 dim, multilingual ru/en) |
| Векторный поиск | sqlite-vec |
| Визуализация | D3.js v7 (force-directed graph, Canvas particles) |
| Управление зависимостями | uv (pyproject.toml) |

### 9 инструментов

```
Поиск и индексация:
  search_knowledge     — семантический поиск (vector similarity)
  reindex_knowledge    — переиндексация всех knowledge-файлов
  knowledge_stats      — статистика: типы, уверенность, здоровье
  get_knowledge        — чтение конкретного файла по имени

Визуализация:
  knowledge_graph      — экспорт графа в JSON (nodes, edges, domains)
  open_graph           — граф знаний в браузере (D3.js force-directed)
  open_dashboard       — dashboard метрик в браузере

Портируемость:
  brain_export         — упаковка всего "разума" в .tar.gz
  brain_import         — smart merge архива на новую машину
```

### Визуализация графа знаний

Force-directed граф со **звёздной метафорой**:

```
Принципы  = звёзды (большие, с ядром и свечением)
Паттерны  = средние тела
Кейсы     = планеты (малые)

Цвет      = звёздный спектр по массе (confidence × impact):
            холодный синий (масса 1-3) → горячий белый (масса 15+)

Рёбра     = градиент от цвета узла A к цвету узла B
            толщина = reliability (confirmed − contradicted)

Кластеры  = гравитационная группировка по доменам

Фон       = космический ветер (canvas-слой с дрейфующими частицами)
```

Панель настроек: разброс, отталкивание, притяжение кластеров, толщина рёбер, размер узлов, свечение, сила притяжения, космический ветер.

### Dashboard метрик

7 виджетов в едином космическом стиле:

| Виджет | Что показывает |
|--------|---------------|
| Summary-карточки | Всего записей, средняя уверенность, среднее влияние |
| Круговая диаграмма | Распределение по типам (principles/patterns/cases) |
| Гистограмма уверенности | Сколько записей на каждом уровне 1-5 |
| Гистограмма влияния | Сколько записей на каждом уровне 1-5 |
| Карта доменов | Покрытие с цветовой интенсивностью по частоте |
| Столбцы массы | Средняя масса (confidence × impact) по типу |
| Таблица надёжности | Top/bottom записей по reliability |
| Здоровье базы | Неподтверждённые, оспоренные, ослабленные записи |

### Портируемость (Brain Export/Import)

**Проблема:** Claude на второй машине не знает и не умеет ничего из первой.

**Решение:** `brain_export` упаковывает в `.tar.gz`:
- global-lessons/ (знания)
- commands/ (скиллы)
- hooks/ (хуки)
- templates/ (шаблоны)
- domains/ (граф доменов)
- sessions/ (реестр сессий)
- knowledge.db (vector embeddings)
- settings-hooks.json (конфигурация хуков)
- CLAUDE.md (глобальные правила)
- manifest.json (метаданные: дата, машина, содержимое)

**Smart merge** при импорте:
- Знания: сравниваются по `confirmed_count` — выше побеждает
- Скиллы/хуки: overwrite (новая версия побеждает)
- Домены: add-only (добавляются отсутствующие, существующие не трогаются)
- Настройки: merge hooks config (добавляются новые event types)
- Dry-run режим по умолчанию для предпросмотра

### Связь со слоями

```
L1 (Persistence) ──→ MCP-сервер читает файлы из ~/.claude/global-lessons/
L2 (Knowledge)   ──→ sqlite-vec хранит embeddings, graph_data() экспортирует граф
L5 (Meta)        ──→ dashboard_data() собирает метрики здоровья
Портируемость    ──→ brain.py сериализует L1+L2 для переноса на другую машину
```

### 3D Universe Visualization (v1.2.0-alpha)

Расширение 2D force-directed графа до трёхмерной «вселенной знаний». 2D `index.html` нетронут — новая визуализация в параллельном `mcp-server/visualization/universe.html`.

**Мотивация:** при росте базы с 40 до 200-500 узлов 2D force-directed превращается в «суп» — перекрытия, запутанные edges. 3D даёт дополнительное измерение для группировки и читаемости. Метафора «вселенная знаний» естественно расширяется туманностями-доменами.

**Соглашение о терминах (единый визуальный язык):**

| Элемент | Метафора | Рендеринг |
|---------|----------|-----------|
| Principle | Звезда (источник света) | Glow shader, emission, большой размер |
| Pattern | Планета | Solid sphere, texture |
| Case | Астероид | Irregular mesh, мелкий |
| Entity (v1.1.0+) | Чёрная дыра / гравитационный центр | Туманный узел |
| Fact (v1.1.0+) | Спутник | Маленький, всегда привязан |
| Relation (v1.1.0+) | Орбитальный мост | Гравитационная связь |
| Edge | Торговый путь | Светящаяся линия (emission shader) |
| Domain | Галактика | Группа + particle nebula |
| Domain boundary | Туманность | THREE.Points, gaussian-распределение |
| Confidence | Яркость / размер | Glow-интенсивность |
| Contradiction | Искажение / красное свечение | Специальный шейдер |

**Стек:**
- Библиотека: `3d-force-graph` (Vasturiano, ~4k stars, WebGL/Three.js)
- Data source: существующий `graph-data.json` из `serve.py`
- Gravity trick (v1.2.0 final): невидимый domain-center-node притягивает членов своего домена через force-link — force-directed сам формирует «галактики», туманности садятся на них естественно
- Degradation: при отсутствии WebGL fallback → 2D `index.html`

**Статус:** v1.2.0-rc.3 работает. Реализованы: гладкие сферы + триадная палитра по типу + domain-accent ободок (sprite в 3D, stroke в 2D), halo pulse, single-three importmap, Line2 worldUnits thickness + ползунок «Толщина рёбер», per-domain nebulae с ShaderMaterial falloff + hash palette + live center tracking, космический ветер 600 частиц, контекстное меню 3D (Открыть / В архив / Удалить), персист настроек в localStorage. Phase 9 Entity Knowledge (v1.1.0+) представлена в 2D; расширение метафоры entity/fact/relation для 3D — на потом (текущий рендер работает с общим graph-data.json).

---

## 14. Приложения

### A. Живой пример: ложная атрибуция (сессия 2026-04-14)

Демонстрация принципа неопределённости на реальном кейсе:

```
Наблюдение:     Собеседник выбрал Crawl4AI (локальный) вместо Firecrawl (облачный)
Вывод агента:   "Ценит автономность (5/5)"
Реальность:     1) Доверился рекомендации агента как более компетентного
                2) Бегло проверил — "прииимерно понял что ты прав"
                3) Дал команду "попробовать" без ожиданий

Ошибка:         Одно действие превращено в черту характера.
                Простое объяснение (доверие + эксперимент)
                заменено красивым (ценность автономности).
```

Обработка через assertion:

```
Было:     "выбрал Crawl4AI" → вывод: ценит автономность (confidence 3)
Коррекция: "доверился рекомендации + попробовать"
Результат: НЕ "автономность = 0". 
           А: гипотеза "автономность" ослаблена (confidence 1),
              гипотеза "делегирование + эксперимент" добавлена (confidence 2),
              оба объяснения сосуществуют до следующего наблюдения
```

Этот кейс опроверг модель через 20 минут после добавления принципа неопределённости — живое доказательство его необходимости.

### B. Пример: реконструкция сессии проектирования

Спиральная эволюция знаний (из нашей сессии):

```
Собеседник:  "Память — это образы и ощущения"
      ↓ Агент формализует → контекстные якоря + свободные теги
Собеседник:  "Не только разработка"
      ↓ Агент обобщает → универсальные якоря, кросс-доменный перенос
Собеседник:  "Не учится на коммуникации"
      ↓ Агент расширяет → коммуникативный слой, interlocutor model
Собеседник:  "Не видит траекторию мысли"
      ↓ Агент углубляет → thought trajectory, предиктивность
Собеседник:  "Правильно ли ты учишься?"
      ↓ Агент добавляет → метакогниция, метрики здоровья
```

Результат: 7-слойная архитектура, которую ни один из участников не создал бы в одиночку.

### C. Живой пример: со-когниция и demand-before-supply (сессия 2026-04-15)

Эксперимент: проверить работает ли чеклист pattern-inside-out-blindness.

```
Задача:      "Система коммуникации между людьми на разных языках без жестов"
Агент:       Сразу проектирует 4-фазную систему обучения словам + чеклист
Собеседник:  "Продажник и сигареты — в комнате никто не курит"
             (= ты не спросил, нужны ли им слова вообще)

5 каскадных коррекций:
1. "Спроси 'вы курите?' перед презентацией" → агент не задал уточняющих вопросов
2. "Ты не думал" → агент согласился с "якоря = вопросы" без анализа
3. "Потребность, доступность, срочность" → demand-компоненты из экономики
4. "Вся жизнь — продажи" → demand не дополнение, а фундамент
5. "Мы строим то что нужно ТЕБЕ" → агент — покупатель своих знаний

Результат:   principle-demand-before-supply
             Якоря описывают контекст. Demand описывает потребность.
             Контекст без потребности — склад без покупателя.
```

Этот же диалог продемонстрировал:
- **Со-когниция работает**: ни один из участников не пришёл бы к выводу в одиночку
- **Генеративная рефлексия возможна**: в конце серии коррекций агент самостоятельно вывел "обход = со-когниция" (подтверждено собеседником)
- **Supply-side мышление**: корневая причина inside-out-blindness
- **Предсказание = научный метод**: гипотеза → проверка → обновление, не угадывание

---

## 15. Системный принцип: каскадность

> Детальный анализ: `docs/cascading-analysis.md`.

### Определение

**Каскадность** — фиксация не только **первого** звена обратной связи/гипотезы/решения, а **каждого последующего** звена цепи при сохранении нумерации и независимости записей.

Антипаттерн — **survivorship bias**: в логах остаются только первые звенья цепочек (первая переформулировка, первая ошибка, первый контрапример), последующие звенья теряются. Статистика перекошена в сторону «первых впечатлений».

### Где работает каскадность (реализовано)

| Место | Механика | Версия |
|-------|----------|--------|
| L1 Persistence (SESSION.md, CHANGELOG, memory) | Append-only log | baseline |
| L4 Thought Trajectory (T1, T2...) | Цепочка точек с обновлением гипотезы | v0.4.1 |
| L6 Prediction / reformulation-tracker | P1..Pn, 3 типа триггеров, автохук | v1.0.1 |
| Знания case → pattern → principle | 3-уровневый промоушен | baseline |

### Правила применения (формализация)

1. **Cascading = append, never overwrite.** Каждое звено — независимая запись с уникальным ID (P_n, T_n, H_n, case-*).
2. **Приоритет при перекрытии.** При одновременной активации разных триггеров — приоритет по информативности (например, BACKWARD > FORWARD > PROPOSAL в L6).
3. **Guardrail by default.** Каскадность без ограничителя = экспоненциальная стоимость. Каждая реализация имеет TTL / threshold / cooldown.
4. **Не в hot path для частых событий.** Частые события каскадируются только в batched runs, не per-turn.
5. **Бюджет ≤ 300 токенов/сессию per cascade.** Превышение → усиление guardrails или переход в «не применять».

### Где каскадность уместна

- **Feedback циклы** — верификация гипотез, предсказаний, моделей собеседника.
- **Evolution цепочки** — модификации паттернов, сдвиги confidence, эволюция знаний.
- **Struggle signatures** — повторы неразрешённых проблем в сессии.

### Где каскадность НЕ уместна

- **Routine dialogue** — большинство proposals имплицитны, не требуют логирования.
- **Planning artifacts** — scope в /decompose это контракт; каскад ломает контракт.
- **Batched analytics** — метрики здоровья, health checks; переносить per-turn = burn токенов.

### Запланированные кандидаты

См. `docs/cascading-analysis.md` — 7 кандидатов категории A (APPLY) и B (APPLY + guardrails), распределены по версиям v1.0.2 — v1.0.9:

| Версия | Кандидат | Слой |
|--------|----------|------|
| v1.0.2 | Intent gap cascade (типизация gap'ов) | L3 |
| v1.0.3 | Disagreement outcome logging | L7 |
| v1.0.4 | Hypothesis change tracking (H1 → H2 → H3) | L4 |
| v1.0.5 | Metrics delta trending (7d/30d) | L5 |
| v1.0.6 | Struggle signature в error-tracker | хуки |
| v1.0.7 | Retro chain linking | скиллы |
| v1.0.8 | Contradiction lineage | L2 |

Категория «не применять» (C1-C5) зафиксирована в `cascading-analysis.md` с обоснованием — важно для будущих сессий не возвращаться к отвергнутым вариантам без новых данных.
