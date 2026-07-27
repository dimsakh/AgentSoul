# ClaudSoul — CLAUDE.md

> Система самообучения для Claude Code

<!-- narrative-start -->
<!-- narrative-end -->

## 1. О проекте

ClaudSoul — система управления знаниями и самообучения для AI-агентов. Не отдельное приложение, а набор скиллов, правил и структур файлов, которые превращают Claude Code в самообучающегося агента.

Когнитивная модель из 7 слоёв (реализованы все 7 с v1.0.9, см. секцию 5):
1. Persistence — SESSION.md, CLAUDE.md, global-lessons, memory, git
2. Knowledge — case/pattern/principle с якорями, FSRS decay, кросс-доменный перенос
3. Communication — intent gaps, decision trails, satisfaction signals, interlocutor model
4. Thought Trajectory — отслеживание развития идей, гипотезы о направлении
5. Meta-Cognition — рефлексия над процессом обучения, метрики здоровья
6. Prediction — silent prep, gentle suggestion, proactive action
7. Co-Cognition — совместное мышление, конструктивное несогласие

## 2. Стек

| Компонент | Технология |
|-----------|-----------|
| Знания, правила, скиллы | Markdown + YAML frontmatter |
| Установка | Shell scripts |
| Метаданные знаний | YAML v0.2 (confidence, impact, 9 якорей, demand) |
| Skills API | Claude Code native |
| Семантический поиск | сервер MCP (sqlite-vec + fastembed, работает с v1.0.10) |

## 3. Структура

```
ClaudSoul/
├── CLAUDE.md              # Этот файл
├── README.md              # Документация
├── PLAN.md                # План разработки (5 фаз, 8 гипотез)
├── CHANGELOG.md           # История изменений
├── SESSION.md             # Лог сессий разработки
├── install.sh             # Скрипт установки на чистую машину
├── docs/
│   ├── architecture.md    # Когнитивная архитектура (7 слоёв)
│   ├── research.md        # Результаты исследований
│   └── decisions.md       # Архитектурные решения (ADR)
├── hooks/                 # 37 активных хуков + 19 библиотек alive learning system + tests/
│   └── *.sh               # error-tracker, knowledge-activator, session-collector,
│                          # intrusiveness-tracker, trust-guard, output-language-check, ...
├── skills/                # 21 скилл: user-invocable + координатор + оркестратор
│   └── */SKILL.md         # /retro, /learn, /knowledge, /knowledge-audit, /skill-forge,
│                          # /quality-gate, /decompose, /pipeline, /enrich, /wiki, ...
├── templates/             # Шаблоны файлов
│   ├── CLAUDE.md.tmpl     # Шаблон проектного CLAUDE.md
│   ├── SESSION.md.tmpl    # Шаблон SESSION.md
│   └── knowledge.md.tmpl  # Шаблон записи знания (v0.2)
├── rules/                 # Глобальные правила
│   └── CLAUDE.md          # Мастер-копия глобальных правил (v0.2)
├── bridges/               # Inter-Layer Bridges (16 мостов, v0.5.7)
│   ├── _index.md          # Индекс мостов между слоями
│   └── L*-L*-*.md         # Формализованные мосты (L3↔L6, L2↔L6)
├── domains/               # Граф доменов (7 root + depth 1-2, v1.0.9)
│   ├── _roots.md          # Индекс 7 корневых доменов
│   └── *.md               # Узлы доменов (name, aliases, depth, связи)
├── knowledge/             # Seed базы знаний (для чистой установки)
│   ├── META.md            # Мета-правила эволюции знаний (v0.2)
│   └── *.md               # 9 принципов + 12 universal-паттернов (генерируется scripts/regen-seed.py)
├── scripts/               # regen-seed, count-stats, smoke-test, calibrate,
│   ├── publish-public.sh  # публикация снимка наружу: archive → exclude → redact → гейт
│   └── publish/           # конфиг публикации (не публикуется: в нём реальные имена)
└── hooks/tests/           # 47 файлов тестов хуков + 20 mcp (см. секцию 5)
```

## 4. Правила разработки

**MANDATORY READ перед добавлением фичи / изменением кода:** `docs/development.md` — как добавлять фичи (хук/библиотека/скилл/знание/сервер), как менять код (характеризующий тест перед рефактором, единый источник, хирургические правки), как вести документацию (числа и статусы из генераторов, не руками; стражи). Архитектурные решения — `docs/decisions.md` (ADR).

### Версионирование и коммиты

| Правило | Действие |
|---------|---------|
| Версионирование | semver (major.minor.patch) |
| Коммиты | На русском, атомарные |
| Каждое изменение | → CHANGELOG.md |
| Каждая сессия | → SESSION.md |
| Архитектурные решения | → docs/decisions.md |

### Формат знаний (v0.2)

**MANDATORY READ:** Load `knowledge/META.md` — полная спецификация формата.

| Группа | Поля |
|--------|------|
| Обязательные | confidence (1-5), impact (1-5), outcome, status |
| Якоря (9) | domain, situation, trigger, stakes, actors, environment, circumstances, purpose, method |
| Demand | need, urgency, availability |
| Связи | related, edges (caused_by, similar_to, contradicts, led_to, specializes, generalizes) |

`reliability = confirmed_count - contradicted_count` (без ограничений)
`priority = impact × (1 + ln(1 + max(0, reliability)))`

### Seed-база знаний (`knowledge/`)

`knowledge/` — seed для чистой установки, **генерируется** из рабочей базы (`~/.claude/global-lessons`) скриптом `scripts/regen-seed.py`: все принципы (универсальны по определению) + паттерны со `scope: universal`; личные кейсы/сущности и `per-speaker` не шипаются; счётчики `confirmed_count`/`contradicted_count` сброшены к базовым (confidence/impact сохранены). **Не править руками** — правь рабочую базу и пересобирай. Перед релизом: `regen-seed.py --check` (падает при дрейфе). CI-страж: `mcp-server/tests/test_seed_integrity.py`.

### Skill contract

**MANDATORY READ:** Load `docs/skill-contract.md` — контракт для SKILL.md файлов.

Каждый скилл: YAML frontmatter, `**Type:** worker`, `## Definition of Done` с чекбоксами, Version + Last Updated.

### Глобальные правила
Мастер-копия: `rules/CLAUDE.md` → `~/.claude/CLAUDE.md` через install.sh (там же —
принцип неопределённости и прочие сквозные правила; здесь не дублируем — канон D1/D3).

## 5. Текущий статус

| Компонент | Статус | Версия |
|-----------|--------|--------|
| Когнитивные слои 1-7 + каскадность | Реализованы | v1.0.9 |
| Хуки alive learning system (~20 активных) | Работают | v1.7.x |
| Автосканер + weekly knowledge audit + monthly bridge health digest | Работают | v1.5.3 |
| Скиллы (21: user-invocable + координатор + оркестратор) | Работают | v0.7.4 |
| Знания: 9 якорей, demand, edges, кросс-доменный перенос, FSRS decay | Работают | v1.0.9 |
| Конвейер L1→L2: capture (activity-flush) → /compile (кросс-проектный сбор) → нудж | Работает | v1.1.0 |
| Inter-Layer Bridges (16 мостов L2-L7) | Формализованы | v0.5.7 |
| Domain Graph (7 root + depth 1-2, графовый scoring) | Работает | v1.0.9 |
| MCP-сервер: semantic search, 9 tools, sqlite-vec + fastembed | Работает | v1.0.10 |
| Визуализация графа знаний (2D D3.js + 3D Universe) | Работает | v1.2.0-rc.3 |
| Dashboard метрик (D3.js, 7 виджетов) | Работает | v1.0.0 |
| Export/Import Brain (tar.gz, smart merge) | Работает | v1.0.0 |
| Entity Knowledge (второй контур: entity/fact/relation, /ingest, /enrich, /wiki) | Работает | v1.1.7 |
| Session Registry (lifecycle, дельты, startup context) | Работает | v1.0.11 |
| L6 4D gate (confidence × value × cost × state) + active state classifier | Работает | v1.3.3 |
| Auto-collection gentle/proactive outcomes (itr-event-detector) | Работает | v1.3.6 |
| Calibration v1.4.0 на 575 backfill-событиях (proactive 2→3) | Применено | v1.7.0 |
| Affect prosthetics: AP1 trust-guard / AP2 distressed / AP3 silence debt | Работают | v1.5.8 |
| Cross-contour analogy surfacing (детект → ранжирование → инжект → метрика) | Работает | v1.6.0 |
| Output language check (4 события, regex по смешению алфавитов) | Работает | v1.6.5 |
| ClaudSoul context pointer (cross-directory awareness) | Работает | v1.6.8 |
| Install drift safeguards + marker-based CLAUDE.md merge | Работают | v1.7.4 |
| install.sh + smoke-test.sh + dependency check | Готов | v1.7.5 |
| Публикация наружу: снимок из `git archive` + exclude/redact/гейт на выходе | Работает | v1.11.1 |
| Тесты | 47 файлов тестов хуков + 20 mcp (111 mcp-тестов) зелёные | v1.11.1 |

> Детали каждого релиза — в `CHANGELOG.md`. В этой таблице — короткий статус.
