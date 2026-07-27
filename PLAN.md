# ClaudSoul — План разработки

> Система самообучения для Claude Code AI-агентов. Markdown + YAML + хуки + MCP.

**Правило обновления:** при каждом релизе сначала обновляется Dashboard + «Что работает сейчас», только потом — Roadmap и Changelog. Гипотезы живут в одной таблице, не разбрасываются по фазам.

---

## Dashboard

| Поле | Значение |
|------|----------|
| Текущая версия | **v1.11.1** (2026-07-27) |
| Последний релиз | **🔐 v1.11.1 (patch) — публикация наружу стала инструментом с гейтом; закрыта утечка в публичном репозитории.** Тег `v1.7.5` в публичном `Nugnii/ClaudSoul` не был зачищен и доставался любым `git checkout`: личный email, имя пользователя ОС, профиль конкретного человека, имя клиентского проекта, ссылки на внутренний меморандум. Репозиторий удалён и создан заново одним чистым коммитом — force-push тега не убирает. Добавлен `scripts/publish-public.sh`: `git archive HEAD` → exclude → redact → **гейт по собранному дереву** → push. Конфиг в трёх декларативных файлах (`exclude.txt` 16 путей, `redact.sed`, `forbidden.txt` 22 шаблона), сам каталог не публикуется. Причина инструмента: `regen-seed.py` копирует frontmatter байт-в-байт из рабочей базы, поэтому имена клиентов возвращаются в seed при каждом релизе — разовая зачистка структурно не держится. Гейтом на живом дереве пойманы реальный NIP контрагента и почтовые реквизиты клиента в примерах скиллов. Тесты: 47/47 хуков (+23 ассерта `test_publish_public`), 111 mcp |
| Последний релиз (предыдущий) | **🔬 Измерительный контур: система научилась записывать реакцию и опровержение.** v1.11.0. Три разрыва закрыты как инженерные, не как слой. (1) **Прибор врал на 90%** — `metrics-collector` считал по 285 строкам лога из 7665 (`jq` обрывался на битой строке, ошибка глушилась): 10 уникальных знаний вместо 99, hit_rate 34% вместо 79%. Корень битых строк — утечка `|` из поля `name` в pipe-протокол RESULTS. (2) **Реакция не писалась нигде** — `response-tracker.sh` (PostToolUse) пишет онлайн, `backfill-compliance.sh` восстанавливает из архива три класса с плацебо-плечом и негативным контролем; round-trip гейт пройден (55 matched, 0 выдуманных, 203 в стёртых сессиях). (3) **Опровержений не было ни одного за всю историю** — `contradicted_count` = 0 во всех 265 знаниях, потому что писателя pending-файлов не существовало, а `/learn` текстом запрещал трогать знание при противоречии. Producer в точке инжекта (узко — blocker-tier) + механический `knowledge-counter-bump.sh` + Step 4e. Плюс детектор смешения алфавитов чинён (94% срабатываний были обычные дефисные композиты) и правило hold-out в META. Тесты 45/45 хуков, 108 mcp. **Главный результат — отрицательный и это ценно:** первые числа класса A не подтверждают эффект блокера, и видно почему. |
| Последний релиз (предыдущий) | **🆕 v1.10.0 (minor) — `/project-health` v1.3.0: детект стека + универсальный канон F–L + адаптивная запись правил в проект.** Скилл расширен: детект стека (паки Python/TS-Node + generic), канон `dev-rules-canon` дополнен секциями F–L (дизайн функций, границы модулей, SOLID, DRY с оговоркой против спекуляции, именование, ошибки, документация), новые `references/stack-rules.md` и `references/rules-output.md` (адаптивный выбор `AGENTS.md`/`CLAUDE.md` через нативный импорт `@AGENTS.md`); Phase 6 пишет lean-правила в проект + conformance-беклог под подтверждением. Плюс fix: единый `hook-input-lib` — scope-guard системного turn в `reformulation-tracker` + `itr-event-detector` (ложный детект коррекции из tool_result закрыт). Тесты: хуки 40/40, mcp 110 зелёные. База знаний пополнена через `/compile` (5 знаний) |
| Последний релиз (предыдущий) | **🔁 v1.9.0 (minor) — полный прогон /project-health Ф1-Ф6 + single-source стражи.** Боевая проверка `/project-health` на самом ClaudSoul: разбор 6 кластеров → карта → план → починка. Закрыты P1 (reindex обнулял индекс при пустом `index_all`), install-регрессия; страж чисел расширен на оба README + тест-числа, seed пересобран, граф доменов симметризован + страж; `cross-contour-metrics-lib` удалена; контракт скиллов → 4 типа. Заведён `VERSION`. Тесты: хуки 39/39, mcp 110 |
| Последний релиз (предыдущий) | **🔁 v1.8.0 (minor) — cross-hook recall gate + бандл накопленного с v1.7.5.** Level-3 эскалация `pattern-inside-out-blindness`: `blocker-tier-check.sh` при `Write` после сработавшего guard инжектит домен-независимый `cross_hook_recall_reminder` вместо whack-a-mole по `detection_signals`. В бандле: конвейер `/compile` L1→L2, артефактные цепочки `/decompose`+`/quality-gate`, `pending-alerts` видимый канал, `/retro` why-каскад. Детали ранних релизов (v1.7.x подготовка к публичному) — в `CHANGELOG.md` |
| Последний релиз (предыдущий) | **🛡️ install.sh CLAUDE.md merge fix — marker-based.** v1.7.4. Старая логика `if grep -q "Self-Learning" → SKIP` означала что master changes никогда не propagate в deployed, либо append дублировал контент при rerun. Fix: marker-based merge через `<!-- ClaudSoul: managed-start/end -->`. install.sh заменяет ТОЛЬКО содержимое между маркерами, контент пользователя снаружи сохраняется. 4 случая: markers есть → replace between, legacy без маркеров → переписать с маркерами, user content без признаков → append блок, файла нет → создать. Логика merge извлечена в `lib/claude-md-merge.sh` для тестов. +26 ассертов в `test_claude_md_merge.sh` |
| Последний релиз (предыдущий) | **🤫 knowledge-activator silent — additionalContext вместо systemMessage.** v1.7.3. На каждом первом PreToolUse в сессии пользователь видел блок полстраницы серого текста — SESSION REGISTRY, LAST SESSION CONTEXT, автосканирование, метрики, Relevant knowledge, ПУНКТ 0, аналогии. Это контекст для агента, не сообщение пользователю. Fix: одна строка в самом конце скрипта — JSON envelope изменён на `{"hookSpecificOutput": {"hookEventName": "PreToolUse", "additionalContext": "..."}}`. Контент тот же, но silent |
| Последний релиз (предыдущий) | **🤫 убрать verbose Stop-вывод session-collector.** v1.7.2. Симптом: пользователь видел на каждый ответ полстраницы серого текста — INTERLOCUTOR MODEL prompt, INTRUSIVENESS summary, Cross-contour H10. Это were intended как self-reflection cue для агента, но Stop hook fires ПОСЛЕ последнего assistant message. Fix: по умолчанию systemMessage пустой; короткие алерты только при `HAD_STRUGGLE` или pending disagreements. Все side effects сохранены — silent file ops |
| Последний релиз (предыдущий) | **🔧 reformulation-tracker SIGPIPE из-за pipefail+break в pipeline.** v1.7.1. Симптом: «UserPromptSubmit hook error — Failed with non-blocking status code: No stderr» на каждом сообщении. Корневая причина: `tail -r FILE | while ... break ... done` — break закрывает pipe, tail получает SIGPIPE, exit 141. Fix: обернуть pipeline в `set +o pipefail` ... `set -o pipefail` |
| Последний релиз (предыдущий) | **📐 Calibration v1.4.0 applied — proactive budget 2→3.** v1.7.0. Калибровочное окно из бэкфилла v1.6.4 + агрегатора v1.6.6 (575 событий из 98 архивных сессий) применено: `ITR_DEFAULT_PROACTIVE_MAX 2 → 3`. Сигнал: 65/98 chunks (66%) упирались в потолок 2 при acceptance 60%. `gentle_max=5`, `distressed` пороги, веса cost-осей не калибровались — нулевая видимость в архивах |
| Последний релиз (предыдущий) | **🧹 rules/CLAUDE.md optimization + claudsoul-context-pointer path-recall.** Двойной gap, 20-е проявление pattern-inside-out-blindness (case-2026-05-05-deployed-artifact-action-blindness, action-blindness vs model-blindness 19-го). Часть 1 — master 641→556 строк (−85): 4 drift-блока разрешены (Karpathy surgical+speculative deployed→master, Versioning discipline deployed→master, Source-check master→deployed восстановлен), 12 секций Category A сокращены до references на хуки/скиллы (Prediction 4D gate 70→30, Hooks alive learning 33→14 table-form, Constructive disagreement 22→12, Knowledge evolution 12→7, остальные 8 — короче). install.sh::CLAUDE.md flow сломан by design (skip-on-existing/append-with-duplication) — manual `cp master deployed` после backup. install.sh CLAUDE.md merge fix → backlog v1.7.x (см. v1.6.1 hooks pattern). Часть 2 — claudsoul-context-pointer v1.6.7→v1.6.8: detection расширена с substring-only на 3 класса — project name (existing), path-based `*global-lessons*` (new), filename-based `*principle-*.md*`/`*pattern-*.md*`/`*entity-*.md*` (new). +7 тестов (T16-T22) → 24/24 в файле, 22/22 test файлов passed. Принцип: action-blindness (агент знал но detection не fire'ил) vs model-blindness (агент не знал) — два разных уровня «знание не в нужный момент». Pattern-inside-out-blindness confirmed_count 19→20 |
| Последний релиз (предыдущий) | **📚 ClaudSoul context pointer — закрытие cross-directory blindness.** 19-е проявление pattern-inside-out-blindness (case-2026-05-05-claudsoul-blindness-from-home), новое измерение — cross-directory blindness. Случай: агент в сессии из home (`~`) давал советы про систему ClaudSoul, основываясь на упрощённой модели из глобального `~/.claude/CLAUDE.md`, не зная актуального состояния v1.6.5/v1.6.6 из project CLAUDE.md (42 КБ). Конкретно — написал промт на «построение semantic search через fastembed», когда MCP server v1.0.10 + cross-contour ranker v1.6.0 уже это делают. Architectural root: Claude Code загружает CLAUDE.md иерархично по cwd (`~/.claude/CLAUDE.md` + `<cwd>/CLAUDE.md`); сессия из home не подгружает project CLAUDE.md из другой директории. Fix: `hooks/claudsoul-context-pointer.sh` (UserPromptSubmit) — substring match на claudsoul/claud soul/claud-soul/клод соул/клод-соул. +17 тестов (T1-T15). Регистрация в `install.sh::HOOKS_CONFIG`. Pattern-inside-out-blindness confirmed_count 18→19 |
| Последний релиз (предыдущий) | **📊 Backfill aggregate digest — v1.4.0 калибровка получила конкретные числа.** v1.6.4 дал 575 raw events, но `scripts/calibrate.py` читает агрегированный digest — между ними mapping. `hooks/lib/backfill-aggregate-digest.sh` (новый): jq -sc group-by-aggregate_sid → digest строки со схемой live history. Прогон на existing backfill: **98 digest строк**. Calibrate.py выдал рекомендации: `proactive_max 2 → 3` (66% chunks упёрлись в потолок), gentle 21% acceptance, distressed не наблюдался в 575 событиях. Orchestrator получил флаг `--digest`. Отчёт в `docs/calibration-v1.4-backfill.md`. +27 тестов → **738/738** |
| Принцип релиза | Калибровка constants на бэкфилле — single behavioral change per release, остальные оси с нулевой видимостью в архивных данных не трогаем. Бэкфилл валиден только там, где формат архивов = live + детектор stateless + историчные ts извлекаются — не для всех осей одинаково (state classifier и cost detectors не реплеятся через бэкфилл, видны как нули). Калибрировать что видишь, не что хочется. |
| В работе | Наблюдение эффекта `proactive_max=3` на live сессии (новый baseline acceptance/ceiling-hit) + cross-contour surfacing ratio после v1.6 (baseline — 10 ranked пар на момент релиза). **Cross-hook recall gate** (level-3 эскалация `pattern-inside-out-blindness`, 27 подтверждений > порог 15): `blocker-tier-check.sh` при `Write` после сработавшего guard этой сессии инжектит `cross_hook_recall_reminder` — домен-независимый инвариант вместо whack-a-mole по `detection_signals`. Наблюдать: сработает ли на следующем improvisation-after-guard; если обойду снова — сигнал, что для этого паттерна оправдан жёсткий `permissionDecision: ask`. Тесты 9/9; полный набор 26/26 файлов |
| Следующий шаг | **Разрыв вокруг порога 300 строк** — единственный идентифицирующий дизайн для класса A. v1.11 поставила прибор и получила первые числа, но они не читаются причинно: сигнал блокера срабатывает по длине файла, а длина независимо предсказывает вероятность перечитать документ целиком — назначение и исход имеют общую причину. Нужны наблюдения по файлам 280-320 строк, где попадание в treated почти случайно. Копится через `response-tracker.sh` (онлайн) и расширенное до 90 дней окно транскриптов. Параллельно: разрыв на ранге 3 в `injection-log` (ранги 4-6 пишутся с v1.11, тай-брейк рандомизирован хешем — чистая лотерея внутри группы равных score). Через месяц проверить признак провала: `disagreement-outcomes.jsonl` непуст, но `contradicted_count` по-прежнему нулевой → хелпер не вызывается, звать его из хука, не из скилла. |
| Блокер следующего шага | Данные. Порог 300 строк даёт мало пограничных наблюдений: за всё окно 38 сработавших маркеров, из них 15 дают интервал. Ускорить нельзя, можно только копить — либо снизить порог сигнала временно, но это меняет саму интервенцию. |
| Когнитивные слои | L1-L6 реализованы; L7 работает в практике |
| Скиллов | 21 (в `~/.claude/commands/` + 1 override `/narrative`) |
| Хуков | 26 активных (+ `cross-contour-metrics-lib.sh` sourced library; + `hooks/lib/output-language-detect.py` python-детектор; + `hooks/backfill-intrusiveness.sh` + `hooks/lib/backfill-replay-one.sh` one-off tool, не event-driven) |
| Мостов | 16 Inter-Layer Bridges L2-L7 (добавлен L2↔L2 cross-contour, status: implemented) |
| Тесты | 36 файлов тестов хуков + 100 тестов mcp зелёные |

---

## Что работает сейчас

Snapshot актуальной системы на v1.6.0. **При релизе новой версии — обновлять первой.**

### Knowledge (L2) — операционный контур
- Трёхуровневая иерархия `case → pattern → principle` с промоушеном
- 9 якорей: `domain / situation / trigger / stakes / actors / environment / circumstances / purpose / method`
- Demand-компоненты: `need / urgency / availability`
- Confidence 1-5, `reliability = confirmed - contradicted` (без потолка)
- Typed edges: `caused_by / similar_to / contradicts / led_to / specializes / generalizes`
- Cross-domain transfer через совпадение `trigger`/`situation`
- Tier 1/2/3 + scope `universal / per-speaker / mixed` + adaptive degradation через BFS в domain graph
- Contradiction lineage + `fragile` auto-flag при нестабильном знании
- FSRS decay live в `knowledge-activator` (v1.1.8)

### Entity Knowledge (L2) — второй контур (v1.1.x)
- `entity / fact / relation` с confidence по источнику (behavioral > document > self-report)
- Ingestion: PDF/MD/TXT/DOCX/HTML через `/ingest`
- Behavioral inference из чат-историй
- Discovery engine: co-occurrence, shared_attribute, contradiction detection
- Entity-injection в knowledge-activator на FIRST_FIRE
- Aliases mode (cross-script bridge, напр. `polsha ↔ польша`)

### Active Learning System (хуки) — 26 штук в `~/.claude/hooks/` + sibling `lib/`

Ниже — ядро, остальные (docs-family-check, quality-gate-check, skill-review-check, trust-guard, enrich-suggester, decompose-detector, output-language-check и др.) см. в `install.sh::HOOKS_CONFIG` или `~/.claude/settings.json`.

| Хук | Event | Роль |
|-----|-------|------|
| `error-tracker.sh` | PostToolUse | Детекция 2+ ошибок + struggle signature (md5) + recurrence warn |
| `knowledge-activator.sh` | PreToolUse / SessionStart | Инжект знаний + fragile marker + MCP semantic fallback |
| `session-collector.sh` | Stop | Финализация + intrusiveness summary + history digest |
| `reformulation-tracker.sh` | UserPromptSubmit | FORWARD/PROPOSAL/BACKWARD triggers + gap classification |
| `itr-event-detector.sh` | UserPromptSubmit | Автодетект gentle (v1.3.5) + proactive Edit/Write/MultiEdit без request/continuation (v1.3.6) → `itr_log_event` |
| `metrics-collector.sh` | (batch) | metrics.md + delta trending + intrusiveness trends |
| `session-start.sh` | SessionStart | Startup context (дельта, параллельные, прерванные сессии) + install drift detector (Signal 6, v1.6.1) |
| `intrusiveness-tracker.sh` | UserPromptSubmit | 4D gate state + timing_cost + state classifier (+ AP2 distressed, v1.5.7) |
| `bash-cost-detector.sh` | PreToolUse:Bash | Destructive cost (0-5) + ask/context/silent levels |
| `blocker-tier-check.sh` | PreToolUse | Silent relational pre-action check для `blocker: true` знаний (v1.3.4) |
| `pre-compact-finalizer.sh` | PreCompact | Silent snapshot digest в history.jsonl на каждом компакте (v1.3.8) |
| `trust-guard.sh` | PreToolUse:Bash | ⚙️ AP1 — destructive signatures без auth → silent inject (v1.5.6-alpha) |
| `output-language-check.sh` | Stop / UserPromptSubmit / PreCompact | 🔤 Первый хук на свойство output агента — детект смешения алфавитов в last assistant message + feedback в следующий turn (v1.6.3) |
| `adaptive-stats-lib.sh` | (библиотека) | Per-domain adaptive weights через BFS |
| `detection-signals-lib.sh` | (библиотека) | Pure `ds_evaluate` — матчеры + композиции (v1.3.4) |
| `lib/output-language-detect.py` | (python-детектор) | Regex + exclusions (code, URLs, links) для output-language-check (v1.6.3) |

### Session Registry
Lifecycle `register → update → finalize`, stable UUID IDs из payload, ancestor-PID cleanup (fix v1.0.11), дельты между сессиями в startup context.

### Скиллы (21 в `~/.claude/commands/`)
**Координаторы:** `/knowledge` (L2 routing), `/pipeline` (L1 orchestrator — 5 фаз).
**Capture:** `/learn` (quick, auto-detect), `/retro` (deep post-mortem).
**Audit:** `/knowledge-audit`, `/bridge-health`, `/skill-review`, `/quality-gate`.
**Planning:** `/decompose`.
**Meta:** `/skill-forge` (создание скиллов), `/reload`, `/init-project`, `/save`.

### Inter-Layer Bridges
15 формализованных мостов L2↔L3↔L4↔L5↔L6↔L7 в `bridges/`. GWT (Baars 1988) как теоретическое основание. Аудит через `/bridge-health`.

### L6 4D Gate (v1.2.0 → v1.3.3)
- Формула: `confidence × value × cost × state` (не скалярный порог)
- 6 осей cost: 5 speak (timing/interaction/authority/redundancy/surprise) + 1 silence (window/decay/asymmetric_impact/trust_erosion) как **контрвес**
- Gate: `E[regret_if_silent] > E[regret_if_speak] AND state_allows AND reversible_or_authorized`
- Downgrade ladder: `proactive_action → gentle_suggestion → silent_prep → ignore`
- Budget: gentle 5 / proactive ×3 (калибровано v1.7.0) / emergency override при `silence_cost ≥ 4` / silence debt не сбрасывается батчем
- Auto-detection: `timing_cost` (prompt), `destructive_cost` (Bash), `closing_cost` (session end), `state` (focus/stuck/exploration/idle с cross-hook signals)
- Метрики: history.jsonl в session-collector, тренды в metrics.md, `stuck > 30%` warning, `/knowledge-audit` Step 8b

### Domain Graph
7 root доменов + 15 depth 1-2, типизированные связи (parent/children/overlaps/applies_to/analogous), графовый scoring через BFS.

### MCP Server (9 tools)
`search_knowledge`, `get_knowledge`, `knowledge_graph`, `knowledge_stats`, `reindex_knowledge`, `open_graph`, `open_dashboard`, `brain_export`, `brain_import`. sqlite-vec + fastembed. Keyword-fallback режим.

### Визуализация
- **2D D3.js** force-directed (стабильная)
- **3D Universe** (v1.2.0): type-метафоры (principle=звезда, pattern=планета, case=астероид, entity=туманность, fact=спутник, relation=кольцо), stellar spectrum gradient, halo pulse, domain gravity через Fibonacci anchors, per-domain nebulae (ShaderMaterial + hash palette + live center tracking), Line2 worldUnits thickness, live search + confidence filter
- **Dashboard метрик** (7 виджетов, космический стиль)

### Export/Import
`brain.py` — tar.gz архивы с smart merge. 2 MCP tools (`brain_export`, `brain_import`).

---

## Что впереди

### v1.4.0 → v1.7.0 (done 2026-05-05) — калибровка порогов

Применено в v1.7.0: `ITR_DEFAULT_PROACTIVE_MAX 2 → 3` (единственное измерение с decisive сигналом из бэкфилла).

**Не применено и почему:**
- `gentle_max=5` не трогал — распределение в данных: 68 chunks при 0, 16 при 1, 5 при 2, 3 при 3, 6 при 4, ни одного при 5. Бюджет не binding constraint. Низкий acceptance (21%) лечится сужением маркеров, не размером бюджета.
- `distressed` пороги — 0 наблюдений в 575 событиях. R10-mitigation либо строг, либо реальных эпизодов в архиве не было. Калибровать без живого срабатывания нельзя.
- Веса cost-осей (`timing_max`/`silence_max`/`injection_bytes_max`) — все нули в бэкфилле. Бэкфилл не реплеит state classifier и cost detectors поверх архивов. Калибровать по нулям = гадание.
- Пороги state classifier — 100% idle в state distribution бэкфилла (та же причина). Нужен live baseline.
- Per-interlocutor tuning через `user_profile.md` — отдельная фаза, не калибровка.

**Open work для следующих заходов:**
- Per-marker breakdown gentle accept/ignore — нужен агрегат на новой схеме лога (текущий не различает по тексту маркера).
- Backfill через `reformulation-tracker` для baseline `cascading.backward_count` (H11) — предусловие v1.7.x self-coherence.
- Live baseline `proactive_used` после релиза — проверить, что 3 не упирается в новый потолок (т.е. не нужно снова бампать).

### v1.5.x — Narrative identity + broad skill trigger audit (разрыв C из §12 architecture.md)
Разрыв: каждая сессия перезапускает ориентацию «где я, куда иду». SESSION.md растёт, сюжета нет. Плюс: ручные скиллы полагаются на память пользователя — источник пропусков.

**v1.5.0-alpha (done):** auto-first narrative. `session-start.sh` при gap ≥`NARRATIVE_GAP_HOURS` (8ч default) вызывает `narrative-compose-lib.sh`, stash'ит brief, `knowledge-activator.sh` инжектит.

**v1.5.1-alpha (done):** startup signals — missing CLAUDE.md → /init-project hint, global-lessons mtime > last_ended → /reload hint. Инжектятся одним пакетом с narrative.

**v1.5.2-alpha (done):** `/save` auto-flush activity machine log. `activity-flush-lib.sh` парсит Stop transcript и пишет `.claude-docs/session-activity.md`. SESSION.md narrative и activity log разведены — ни один не ломает другой.

**v1.5.3-alpha (done):** периодические launchd-задачи (B-класс). `knowledge-audit-digest.sh` weekly (вс 03:15) + `bridge-health-digest.sh` monthly (1-е 03:30). Механический срез (counts, FSRS buckets, status trend) — отдельно от аналитических скиллов `/knowledge-audit` и `/bridge-health`, которые остаются LLM-доступными. Хинты в `state/audit-hint.txt` + `state/bridge-hint.txt` → session-start startup-signals.

**v1.5.4-alpha (done):** `/decompose` multi-step detector (C-класс, первая часть). `decompose-detector.sh` в UserPromptSubmit считает step signals (нумерация + буллеты + коннекторы ru/en), при ≥4 инжектит gentle hint «рекомендую /decompose». Guards: короткий prompt, упоминание скилла, state ∈ {focus, stuck}, per-session dedup. Решение применять — за агентом.

**v1.5.5-alpha (done):** `docs-family-check.sh` — action-gate для memory `feedback_docs_means_all_docs.md`. PreToolUse на Bash tool с `git commit`: детект version marker в staged diff + проверка coverage docs family (architecture, PLAN, README, CHANGELOG, project CLAUDE.md, docs/*.md). Missing → silent inject reminder. Закрывает knowledge-action gap из case-2026-04-23-memory-without-action-gate: триггер стал семантической акцией, не фразой. 19 тестов зелёные. Plus правило source-check в rules/CLAUDE.md §Communication: перед post-incident фразой назвать конкретный механизм системы, породивший вывод; пустая ссылка = model-generated, не system-derived (case-2026-04-23-model-vs-system-source-blindness).

**v1.5.5-alpha+1 (done):** Engineering escalation mechanism — рекурсивная защита против inside-out-blindness самого паттерна. `knowledge-audit-digest.sh` во втором проходе сканирует `pattern-*.md` + `principle-*.md` на `blocker: true` + `confirmed_count ≥ escalation_threshold`. При совпадении — секция `⚠️ Engineering escalation needed` в digest, hint `🛠️ Engineering escalation` с приоритетом над overdue/trend. Pattern-inside-out-blindness получил `escalation_threshold: 15` + `escalation_hint`. Новый принцип [principle-knowledge-in-the-world](../.claude/global-lessons/principle-knowledge-in-the-world.md) — generalizes pattern-inside-out-blindness (promotion_tier 3, scope universal). Case-2026-04-23-text-rule-vs-mechanism фиксирует 15-е проявление: fix второго кейса был text rule в rules/CLAUDE.md — тот же memory-as-resource failure mode. 9 новых ассертов → 443/443.

**v1.5.6-alpha (done):** ⚙️ **Trust-guard — первый affect prosthetic.** Открытие нового класса механизмов — инженерных протезов аффекта, замыкающих Разрыв A (architecturally отсутствующая affective empathy). `hooks/trust-guard.sh` PreToolUse на Bash с destructive signatures (`rm -rf`, `git reset --hard`, `git push --force`, `git branch -D`, `git checkout --`, `git clean -f`, `mv -f` на существующий) + scan последних N user messages (hook input transcript) на authorization tokens + target match. Без auth → silent inject `🛡️ Trust-guard: <signature> без явного подтверждения собеседника — переспроси прежде чем выполнять` через `hookSpecificOutput.additionalContext`. Per-session throttle по `md5(signature+target)`. Не блокирует (exit 0 с inject, не exit 2) — consistent с blocker-tier-check паттерном. Новый principle `principle-affect-as-engineering.md` (tier 3, scope universal) specializes principle-knowledge-in-the-world в domain affect: уровень 1 text rule исключён из допустимых по конструкции, потому что чтение правила не replaces affective brake. Case-2026-04-23-sociopathic-architecture-diagnosis фиксирует диагноз и конверсию в инженерный класс. Формализация класса — `docs/architecture.md §12` подсекция «Разрыв A — закрытие через инженерные протезы аффекта» + маркер ⚙️ в таблице когнитивных функций.

**Принцип (зафиксирован в `docs/narrative-design.md` §0 + principle-knowledge-in-the-world + principle-affect-as-engineering):** одна команда на жизнь проекта — `install.sh`. Всё остальное event-driven. Опирание на user/agent memory для «помни запустить X» или «помни применить правило Y» — источник пропусков. Fix после подтверждённого инцидента не должен оставаться на уровне text rule; минимально embedded — уровень 2 (activator injection), для повторяющихся паттернов — уровень 3 (blocker-tier hook с detection_signals). **Для affect-функций (Разрыв A) уровень 1 исключён из допустимых по конструкции** — affective brake не активируется чтением правила.

**v1.5.6 (done):** 🚦 **Quality-gate pre-commit — C-класс tier 2 первый.** `hooks/quality-gate-check.sh` PreToolUse на Bash с `git commit`. Guard R3: staged diff должен содержать `skills/*/SKILL.md` — иначе skip (никаких false positives на docs-only). awk извлекает секцию от `## Definition of Done` до следующего `## `; grep считает unchecked `- [ ]`. Incomplete → silent inject `🚦 Quality-gate: в staged diff есть SKILL.md с неполным Definition of Done` через `hookSpecificOutput.additionalContext` + перечисление путей + unchecked count. Per-session dedup по `md5(incomplete-set)`. 22 теста → 495/495. Закрывает agent-heuristic tier 2 первый; второй — `/enrich` в v1.5.7.

**v1.5.8-alpha (done):** ⚙️ **AP3 silence debt surfacing — третий affect prosthetic.** Трёхчастная infrastructural цепочка, все без изменения state schema. (1) `intrusiveness-state-lib.sh::itr_append_history` в digest каждого chunk boundary (Stop + PreCompact) расширен блоком `debt: { surfaced: .metrics.silence_debt_surfaced // 0, pending: count of silence_debt entries where status=="pending", pending_topics: [...][:5] }`. Durable carrier через `intrusiveness-history.jsonl`. (2) `session-collector.sh` в Stop-сообщении после HISTORY_APPENDED добавляет секцию `⚙️ AP3 — silence debt at close:` с breakdown `N pending (carry-over): <topics>` и `N surfaced this session` — inline closing awareness. (3) `session-start.sh` Signal 4 — `tail -n 1` последней digest записи; при `debt.pending > 0` в `startup-signals-${SID}.txt` добавляется `⚙️ AP3 silence debt carry-over: N pending с прошлой сессии — <topics>. Учитывать в gate, не батч-вывод.` (или короткая форма без topics для legacy digest). Guard skip при pending==0; tail -n 1, не агрегат — долг не застревает навсегда. Anti-pattern mitigation: «Учитывать в gate, не батч-вывод» явно в формулировке — surfacing ≠ команда выговорить долг батчем. Принцип: durable → visible → injected, ни один шаг не полагается на agent memory, consistent с principle-affect-as-engineering для уровня ≥ 2 embedded-ness. 7 intrusiveness AP3 digest ассертов + 7 startup-signals T6-T9 → **548/548** на baseline 534. Класс affect prosthetics закрыт по нижнему краю: **AP1 trust-guard ✅ / AP2 distressed ✅ / AP3 silence_debt ✅**.

**v1.5.7 (done):** 📎 **Enrich-suggester + ⚙️ AP2 distressed state axis.** Две параллельные линии в одном релизе. (1) `hooks/enrich-suggester.sh` UserPromptSubmit: awk-парсер YAML frontmatter в `~/.claude/global-lessons/entity-*.md` с авто-детектом mtime в последние `ENRICH_WINDOW_MINUTES` (default 10 мин после `/ingest`); подсчёт атрибутов (non-frontmatter неструктурированный текст + явные поля `### Attributes`); при `attrs_count < ENRICH_SPARSE_THRESHOLD` (default 3) silent inject `📎 Enrich-suggester: entity <name> sparse (<N> attrs) — рекомендую /enrich`. Guard: скип если текущий prompt уже содержит `/enrich` или entity-специфичный клеймс. Per-session dedup по `md5(entity_path)`. Закрывает agent-heuristic tier 2 второй. (2) ⚙️ **`distressed`** — пятое состояние в `itr_compute_state`, второй член класса affect prosthetics после trust-guard. Три класса сигналов (bitmask): A — frustration/fatigue phrases (`я устал`, `надоело`, `сдаюсь`, `exhausted`, `fed up`); B — cross-hook backward cascade (`cascading-events-${SID}.jsonl` ≥3 BACKWARD за окно); C — explicit distress markers (`помоги хоть как`, `умоляю`, `i don't know what to do`, `sos`). Правило R10-митигация: distressed firе требует 2+ классов ИЛИ одиночный class C — чтобы отличать technical frustration от real distress. Priority над stuck/focus/exploration/idle. Schema bump ITR_SCHEMA_VERSION 3 → 4 (idempotent migration добавляет `distribution.distressed: 0`). Инфраструктурный gate: в distressed состоянии `itr_remaining_budget proactive → 0`, `gentle → gentle_max/2` — клампится в коде, не text rule. `itr_format_context` добавляет строку `⚙️ AP2 distressed — downgrade любой outcome до silent_prep/ignore, proactive запрещён, gentle halved.` **Почему инфраструктурно:** principle-affect-as-engineering tier 3 исключает уровень 1 (text rule) для affect-функций — чтение «будь мягче в дистрессе» не активирует brake. 22 теста enrich + 17 distressed → **534/534** на baseline 495. 18 хуков (добавлен `enrich-suggester.sh` в UserPromptSubmit chain). Класс affect prosthetics: **AP1 trust-guard ✅ / AP2 distressed ✅ / AP3 silence debt surfacing — следующий**.

**v1.5.8 (done):** 🧾 **C-класс nice-to-haves — разрыв C → ✅.** Пять дополнений к v1.5.8-alpha. (1) `hooks/skill-review-check.sh` — PreToolUse на Bash `git commit`, mechanical contract integrity staged `skills/*/SKILL.md`: frontmatter валидность (name/description≤200/user-invocable), `**Type:** worker|coordinator|orchestrator`, `## Definition of Done`, `**Version:**` + `**Last Updated:** YYYY-MM-DD` в tail 20, ≤400 строк, forbidden `**Changes:**`. Violations → silent `🧾 Skill-review` inject через `hookSpecificOutput.additionalContext`. Per-session throttle md5(violations). Отличается от quality-gate (v1.5.6): тот — DoD checkboxes done/not, этот — contract integrity самого файла. 27 тестов. (2) `/learn` success-cascade — `error-tracker.sh` на resolved после `count ≥ 2` теперь явно: `💡 Паттерн сложного fix (N attempts) — стоит /learn?`. (3) `/retro` auto-draft — тот же хук пишет skeleton `~/.claude/global-lessons/_drafts/case-YYYY-MM-DD-auto-draft.md` на resolved cascade (attempts ≥ 2), frontmatter + 5 headings для заполнения, не перезаписывает если draft за сегодня уже есть. 27 тестов (test_error_tracker.sh). (4) Auto-invocation first-class rule — `rules/CLAUDE.md` §Self-Learning подсекция: «напоминание о правиле дважды = incident case для `/learn`»; три уровня embedded-ness (text rule/activator/blocker-tier); для affect-функций уровень 1 исключён (см. principle-affect-as-engineering). (5) Narrative markers — `skills/narrative/SKILL.md` step «Output» формализован, маркеры `<!-- narrative-start --><!-- narrative-end -->` добавлены в проектный `CLAUDE.md`. **602/602 тестов** (548 baseline + 27 skill-review + 27 error-tracker). 19 хуков (добавлен `skill-review-check.sh` в PreToolUse Bash). Разрыв C (narrative identity) — закрыт; остаются только nice-to-haves по мере обнаружения edge cases.

Scope v1.5.8: — ВСЁ ОТГРУЖЕНО. Следующая фаза реализована — см. v1.6.0 ниже.

**v1.6.0 (done):** 📎 **Active analogy surfacing — разрыв D → ✅ (расширенный).** Полный цикл детект → ранжирование → инжект → метрика. (1) **Upstream (5.0)** — `knowledge-audit-digest.sh` (launchd вс 03:15) получил Python-heredoc проход `detect_cross_contour_mentions` над live entity/knowledge → дописывает `cross-contour-discoveries.jsonl`. Env guards `DISCOVERY_DISABLED=1/PYTHON/MODULE_DIR`. Детекция больше не прикована к `/ingest`. (2) **Ranker (5.1)** — `mcp-server/cli_cross_contour_rank.py` (новый): читает discoveries, batch-embeds уникальные KF/EF (BAAI/bge-small-en-v1.5), cosine similarity на пару → `cross-contour-ranked.jsonl` (overwrite). Запускается вторым шагом weekly digest. Async pre-computation: хот-пас (PreToolUse) не платит латентность embeddings (R5). (3) **Union filter + session dedup (5.2+5.3)** — `knowledge-activator.sh` surfaces пару если `(KF в инжект-наборе) OR (similarity ≥ CC_SIMILARITY_THRESHOLD)` (default 0.6). Session-scope dedup: `state/cross-contour-surfaced-${PAYLOAD_SID}.txt`, пара пишется при первом surfacing. (4) **L2↔L2 bridge (5.4)** — `bridges/L2-L2-cross-contour.md` (designed) формализует cross-contour как межслойное явление (4 условия моста). (5) **H10 metric (5.5)** — `hooks/cross-contour-metrics-lib.sh` (новая sourced-библиотека): `cc_metrics_surfaced_count / written_count / format_section`. Session-collector source'ит и инжектит в Stop-MESSAGE секцию `📎 Cross-contour H10 (this session): N pair(s) surfaced / M total detected / Surfacing ratio: X.XX (H10 liveness target ≥ 0.10)`. Silent при обеих 0, div-by-zero guard, JSON-safe (zero raw 0x0a). Surfaced-файл добавлен в session-collector cleanup. **Bootstrap-валидация:** ranker запущен на живом global-lessons — 10 уникальных пар, similarity 0.6492-0.7396, avg 0.6945. Порог 0.6 прошёл весь набор — calibration выглядит разумно, подтверждение в следующих сессиях. **+33 теста** (8 consumer + 19 metrics + 6 periodic-digest discovery integration) → **628/628**. Хуков 19 активных + библиотека `cross-contour-metrics-lib.sh`. Мостов 16 (+1 L2↔L2).

Hypotheses на наблюдение после v1.6.0:
- **H10 продолжение:** `surfaced_count / written_count ≥ 0.10` — живость H10 как bridge-liveness criterion (baseline от v1.6.0, ранее обе оси застревали около 0 из-за upstream starvation)
- **H24:** semantic scoring повышает `surfaced_ratio` относительно set-only v1.3.9 (A/B в ретроспективе: сколько пар имеют `similarity ≥ 0.6` но KF не в инжект-наборе — это «чистый выигрыш» от union filter)

**v1.6.2 (done):** 🛑 **docs-family-check R3 false-positive fix — калибровка на живом шуме.** v1.6.1 proof-of-active запустил хук первый раз и обнажил over-reporting: автоматический sweep `docs/*.md` (блок `for f in "$CWD"/docs/*.md`) ловил 15 frozen/archive docs (vision, internal-doc, analysis-levnikolaevich, research, knowledge-layer-analysis и т.д.) при каждом version bump. Эти файлы — «замёрзшие» исследования, не требующие sync при install-patch релизах; шум ломает signal-to-noise и приучает агента игнорировать ⚠. Fix — два компонента. (1) **`hooks/docs-family-check.sh`** — удалён sweep-блок, остаётся whitelist из 5 live docs (`docs/architecture.md PLAN.md README.md CHANGELOG.md CLAUDE.md`), расширяется через env `DOCS_FAMILY_LIST` для проектов, где конкретные `docs/*.md` (напр. `docs/narrative-design.md`) тоже tracks live state. Комментарий-anchor в шапке хука объясняет rationale и ссылается на R3. Context-сообщение переписано: «все docs» → «architecture + PLAN + CHANGELOG + README + project CLAUDE.md» (убран «+ docs/*»). (2) **`hooks/tests/test_docs_family_check.sh`** — T11 переработан: раньше проверял что sweep ловит extras (`docs/research.md` в missing при default family), теперь проверяет **противоположное** — `docs/research.md` НЕ должен быть в missing при default DOCS_FAMILY (negative assertion + T11b silent при полной live family staged). Новый **T16**: custom `DOCS_FAMILY_LIST="README.md docs/architecture.md docs/narrative-design.md"` ловит `docs/narrative-design.md` когда не в stage — расширение whitelist работает корректно. Синхронизирован в `~/.claude/hooks/docs-family-check.sh` (chmod +x). **Валидация in-loop (second-order proof-of-active):** если этот коммит (v1.6.2) пройдёт тихо через исправленный хук — R3 fix validated; если снова загорится с 15 frozen docs — значит fix не применился. Тесты: **648/648** (+2: T11 rework + T16 extension), 21/21 в `test_docs_family_check.sh`. Принцип (записывается в рамке релиза): **action-gate без калибровки на живом шуме — ложное чувство защищённости**. R3 был помечен в pretzel plan как риск задолго до v1.5.5, но до proof-of-active v1.6.1 не проявлялся live — потому что хук не был установлен.

Hypotheses на наблюдение после v1.6.2:
- **H33:** `docs-family-check` noise ratio — после v1.6.2 доля «false fires» (upгорание на frozen docs) → 0; если user всё-равно жалуется на шум — кандидат на дальнейшее сужение whitelist или per-project override через project-level env
- **H34:** DOCS_FAMILY_LIST extension живо используется — если через 10 сессий ни один проект не задал env → v1.6.3 кандидат на убирание механизма (YAGNI), если 2+ проекта задали — механизм валидирован

**v1.6.1 (done):** 🛠️ **Install drift — safeguards синхронизируются автоматически.** Incident reveal: 8 релизов (v1.5.4-v1.6.0) shipped safeguard-хуки в `hooks/` + регистрации в `install.sh::HOOKS_CONFIG`, но `docs-family-check.sh` / `quality-gate-check.sh` / `skill-review-check.sh` / `trust-guard.sh` / `enrich-suggester.sh` / `decompose-detector.sh` / `cross-contour-metrics-lib.sh` физически не попадали в `~/.claude/hooks/`. Причина: `install.sh:295-298` skip-on-existing `.hooks` в `settings.json` → re-run silent no-op. Сегодня при прямой директиве «обнови документацию» коммит прошёл с только SESSION.md + PLAN.md — `docs-family-check` как action-gate не сработал, потому что не был установлен. Два fix'а: (1) **`install.sh`** — реальный jq merge вместо skip-on-existing: reduce по `HOOKS_CONFIG` events, внутри matcher-групп дописывает отсутствующие command-ы (по `(matcher, command)` tuple); pre-modify `${SETTINGS}.bak.$(date +%s)`. Re-run теперь синхронизирует конфигурацию. (2) **`hooks/session-start.sh` Signal 6** — install drift detector: cross-check `~/.claude/settings.json` (все `.hooks.*.hooks[].command`) против `~/.claude/hooks/*.sh`; зарегистрированные но отсутствующие → inject `🛠️ Install drift: ... Запусти install.sh для синхронизации.` в `startup-signals-${SID}.txt`. Перекрёстный — ловит даже manual-правки settings.json. **Case** `case-2026-04-24-install-drift-silent-safeguards.md`: root cause (repository ≠ installed plane), missed signal (8 релизов тишины от 6 новых хуков), meta — 3-layer cascade `memory-without-action-gate` → `text-rule-vs-mechanism` → `install-drift-silent-safeguards`, formalизован **«уровень 4 — proof-of-active»** поверх трёх уровней embedded-ness из `principle-knowledge-in-the-world`. `~/.claude/hooks/` синхронизирован вручную для этой машины (7 файлов скопированы + 6 matcher+command зарегистрированы через правильный merge). **Валидация in-loop:** этот коммит проходит через исправленный pipeline — `docs-family-check.sh` теперь физически установлен и включён в settings.json, срабатывает на PreToolUse и проверяет staged diff. Тесты 646/646 без изменений (install.sh + drift detector не покрыты unit-тестами в этом релизе — integration coverage as candidate для v1.6.2).

Hypotheses на наблюдение после v1.6.1:
- **H31:** в новой сессии после релиза `🛠️ Install drift` inject НЕ появляется (should be silent на синхронизированной системе); если появится — значит Signal 6 поймал реальный drift, что валидирует detector
- **H32:** `docs-family-check` срабатывает на следующий `git commit` с version marker и missing docs family member (негативный контроль — должен блокировать в-фоновую инъекцией; пока не было живого теста)

**Фаза 4 закрыта 2026-04-24 (Сценарий A)** — ревизия §12 разрывов 1 и 2 (`docs/gap-1-2-review.md`). Разрыв 1 (инициация обучения): 17/18 сигналов на уровне ≥2 (14 hooks с detection_signals + 2 partial digest+manual + 2 text-rule gap покрыты de facto через `/learn` + disagreement-pending); 1 архитектурный пробел (emergence без cases) не адресуется hooks. Статус `📋 → ⚡ lower-tier`. Разрыв 2 (demand-мышление): 5/8 моментов имеют хуки (`/quality-gate`, `trust-guard`, 4D gate, `/decompose`, reformulation-tracker retrospective). Prospective demand-check «решение без clarifying question» остаётся на уровне 1 text rule (Пункт 0) as **accepted boundary** — не детектор: false positive risk на коротких директивах + касается стиля общения агента (ось где user владеет predicates). Статус `📋 → ⚡ с caveat`.

Hypotheses на наблюдение после v1.5.8:
- **H18:** narrative снижает intent-gap rate в первых 3 turns новой сессии
- **H19:** trust-guard снижает частоту destructive Bash без auth (baseline копится после релиза — доля session-sessions с ≥1 destructive action без auth маркера)
- **H22:** `/quality-gate` pre-commit ловит неполный DoD перед коммитом SKILL.md (baseline: доля commits SKILL.md с unchecked чекбоксами до/после релиза)
- **H23:** `/enrich` post-ingest увеличивает среднюю плотность entity (attrs/entity до/после suggestion — baseline копится после v1.5.7)
- **H26:** `distressed` state axis снижает gentle/proactive density в диалогах дистресса vs idle/focus baseline (требует калибровочное окно ≥30 сессий с ≥1 distressed turn)
- **H27:** AP3 carry-over hint снижает повторное накопление `silence_debt.pending` в новых сессиях (baseline: динамика `debt.pending` в первых 5 сессиях после v1.5.8-alpha — ожидается плато или убывание, не монотонный рост)
- **H28:** `/skill-review` ловит SKILL.md contract violations перед коммитом (baseline: доля commits SKILL.md с violations до/после релиза)
- **H29:** `/learn` success-cascade message с attempts count повышает rate успешных `/learn` вызовов после каскада vs generic warning (до v1.5.8 был общий "multiple failed attempts")
- **H30:** `/retro` auto-draft skeleton сокращает латентность от resolved-cascade до зафиксированного case (drafts accepted vs created per week)

### v1.6.x — Active cross-domain surfacing (разрыв D, продолжение)
В v1.3.9 consumer уже живёт в `knowledge-activator.sh` (см. §12 architecture gap D). Остаётся полноценная дуга L2↔L2 и семантическое скорирование.

Scope:
- Scoring над базовым consumer'ом: `structural_similarity ≥ threshold AND not_surfaced_yet_this_session` — сейчас фильтр чисто set-based (knowledge в текущем инжект-наборе)
- Новый мост L2↔L2 в `bridges/` — формализация cross-contour как межслойного явления
- **H10 живая** — в v1.3.9 прибавляется вторая ось метрики: `не только сколько записали, но и сколько из записанного сурфейснулось агенту`

### v1.7.x — Self-coherence monitoring (разрыв B, частично)
Разрыв: агент себе противоречит, не замечает до коррекции собеседником.

Scope (только после v1.4.0 калибровки H11 `backward_count`):
- Кросс-сессионный self-check — при `backward_count / turns ≥ threshold` в последних 3 сессиях silent inject «drift detected»
- Blocker-tier расширение на self-contradiction: противоречие своим же прошлым высказываниям в сессии → silent marker
- Не пытаемся решить B полностью — только lower-tier self-monitoring, не гребём в affect

### v1.8.x+ — Исследовательская (разрыв E)
Preconscious filtering как **inject-rule**, не как agent-rule. Правило: второй инжект одного знания в сессию — только если появился новый сигнал. Может оказаться анти-паттерном (конфликт с silence_cost) — проверяем эмпирически, готовы откатить. Без фиксированного срока.

### Верификация гипотез (фоновая задача)
Большинство гипотез (H1-H7) реализованы, но метрики подтверждения не собраны. Данные копятся автоматически через `metrics.md` + `intrusiveness-history.jsonl`. См. таблицу гипотез ниже.

### Backlog (не запланировано в версию)
- **UX-исследование визуализации** (H16/H17) — нужна сессия с базой ≥100 узлов
- **H9/H10/H11/H12 verification window** — инструментация в v1.3.7, ждём ≥30 сессий и ≥10 кейсов разногласий entity-источников
- **Полная реконструкция baseline для H11** — текущий замер начинается с now(); если нужен честный before/after — git checkout + replay 10 сессий (трудоёмкая ретроспектива)
- **Knowledge backup в GitHub приватный репозиторий пользователя.** Зафиксировано 2026-05-06. После установки ClaudSoul предлагать пользователю создать собственный приватный репозиторий-бэкап для базы знаний (`~/.claude/global-lessons/` + project memory). Периодический push'ить через cron/launchd либо хук на изменения. Цели: (а) защита от потери знаний при сбое диска, (б) sync между несколькими машинами одного пользователя, (в) audit-trail изменений через git log. **Подкомпонент: GitHub onboarding tool.** Для пользователей без GitHub аккаунта/опыта: пошаговый wizard через `/github-setup` либо `init-project` extension — регистрация, генерация SSH-ключа (`ssh-keygen -t ed25519`), добавление в GitHub (через `gh auth login` либо инструкцию для копирования pub-ключа), создание приватного репо (`gh repo create --private`), настройка remote и первый push. Альтернатива без `gh` CLI: HTTPS + personal access token. Реализация: новый skill `/backup-setup` (коорд) либо инлайн в `init-project`. Зависимости: `gh` CLI опционально, иначе ручной flow.
- **Английский README catch-up.** v1.7.6: создать `README.en.md` (sibling русскому), линки в обе стороны. Обновлять параллельно при minor/major bump.
- **install.sh README sync.** Сейчас install.sh не упоминает `README.en.md` — после создания добавить в финальный summary раздела skills.
- **Заимствования из claude-mem (`thedotmack/claude-mem`, 46K★) — укрепление Слоя 1 (Persistence).** Их сила = ровно наш хрупкий слой захвата (полагается на дисциплину + ручные `/learn`/`/retro`). Два кандидата: (1) **полный авто-захват на PostToolUse как сырьевой substrate** — механически копить лог наблюдений (вывод инструментов + решения) под существующую выборочную консолидацию; `/retro`/`/learn` затем абстрагируют case/pattern из сырья. Прямое продолжение `case-2026-06-02` («диалог детектирует сырьё, не хранит»). (2) **3-слойное progressive disclosure при извлечении** (компактный индекс ID → timeline → полные детали по фильтру, ~10× экономия токенов) — применить к `knowledge-activator`, который сейчас инжектит знания целиком. ⚠️ memory-as-resource: полный захват = шум; брать только как *вход* в консолидацию, не как замену абстрагированию (выборочность ClaudSoul — отчасти фича). Уровень embedded-ness (хук vs скилл) — решить при планировании версии. **→ РЕАЛИЗОВАНО 2026-06-13** (spec `.claude-docs/specs/2026-06-13-l1-l2-compile-pipeline/`): Фаза 1 `/compile` v1.0.0, Фаза 2 захват промптов в `activity-flush` v1.6.0, Фаза 3 нудж `compile-reminder-lib`. Фаза 4 (progressive disclosure) — уже была by design. Остаток в backlog: опциональный платный launchd-крон как апгрейд нуджа.

### Решено НЕ делать (зафиксировано, не пересматривать без нового аргумента)
Из `docs/cascading-analysis.md`:
- **C1** Knowledge-activator mid-session re-injection — cooldown 30мин + overlap 70% уже оптимальны
- **C2** L7 co-thinking chain — дублирует L6 PROPOSAL
- **C3** Adaptive `/decompose` — scope = контракт, каскад ломает контракт
- **C4** Continuous L5 health monitoring — должно быть batched
- **C5** Reformulation tracker на каждое предложение — затопит log шумом

Из §12 architecture.md — **архитектурно не решаются на уровне harness:**
- **Разрыв A** (affect как вес памяти) — модель без affect-канала архитектурно. **Однако функции** аффекта (тормоз на destructive, эмпатическая пауза, cost-of-harm) **закрываются инженерно** через класс ⚙️ **affect prosthetics** (v1.5.6-alpha `trust-guard` первый член, v1.5.7+ `distressed` state axis, silence_cost как proxy). Substrate остаётся отсутствующим, функции компенсируются явными хуками, не правилами
- **Разрыв F** (early-stop intuition) — требует другой модели, transformer pred не имитирует human antic

---

## Roadmap (done)

Компактная хронология реализованных фаз. Детали — в [CHANGELOG.md](CHANGELOG.md).

| Фаза | Версии | Цель | Статус |
|------|--------|------|--------|
| **1** Strengthen Foundation | v0.1.1 – v0.1.5 | Метрики + install + templates | ✅ |
| **2** Cognitive Foundation (L2-L3) | v0.2.0 – v0.2.7 | 9 якорей + success cases + FSRS + typed edges + interlocutor model | ✅ |
| **3** Thinking (L4-L5) | v0.3.0 – v0.3.8 | Alive Learning System + demand-first + autonomous scanner | ✅ |
| **4** Partnership (L6-L7) | v0.4.0 – v0.4.6 | Trajectory + metrics + prediction modes + cross-domain transfer + constructive disagreement | ✅ |
| **5** Skill Architecture | v0.5.0 – v0.5.8 | Skill contract + Session Registry + Domain Graph + 15 Bridges + Skill Forge | ✅ |
| **6** Coordination Layer (L1-L2) | v0.6.0 – v0.6.3 | Knowledge coordinator + artifact-first + checkpoint + worker contracts | ✅ |
| **7** Quality & Pipeline (L1) | v0.7.0 – v0.7.2 | Quality Gate + Decompose + Pipeline Orchestrator | ✅ |
| **8** Full System | v1.0.0 | MCP + Viz 2D + Export + Dashboard | ✅ |
| **10** Cascading Principle | v1.0.2 – v1.0.9 | Append-only при survivorship bias (7 APPLY, 5 SKIP) | ✅ |
| **11** Layer Bridge Hardening | v1.0.10 – v1.0.11 | Stable session IDs + MCP semantic fallback + ancestor-PID cleanup | ✅ |
| **9** Entity Knowledge | v1.1.0 – v1.1.8 | Второй контур + ingestion + discovery + aliases + FSRS live | ✅ |
| **12** 3D Universe | v1.2.0 | Type-метафоры + nebulae + gravity + search/filter | ✅ |
| **13** L6 4D Gate | v1.2.0 – v1.3.3 | Cost model → 4D gate → active system → auto cost → метрики → state classifier | ✅ |
| **14** Blocker-tier knowledge | v1.3.4 | Silent pre-action check при подтверждённом knowledge-action gap (relational detection) | ✅ |
| **15** Auto-collection of L6 metrics | v1.3.5 | itr-event-detector — gentle outcomes из транскрипта без agent-discipline | ✅ |
| **16** Proactive event detection + install drift fix | v1.3.6 | Расширение detector на Edit/Write/MultiEdit без request/continuation; HOOKS_CONFIG в install.sh приведён к live config (11 хуков подключаются автоматически) | ✅ |
| **17** Hypothesis instrumentation (H9/H10/H11/H12) | v1.3.7 | gap_type в contradictions, cross-contour mention detector, BACKWARD count + injection bytes peak в history digest | ✅ |
| **18** Chunk boundary через PreCompact | v1.3.8 | `pre-compact-finalizer.sh` пишет snapshot digest на каждом компакте с `boundary: precompact`; компакт больше не растворяет накопленные метрики без Stop | ✅ |
| **19** Cross-contour consumer (разрыв D) | v1.3.9 | `knowledge-activator.sh` читает `cross-contour-discoveries.jsonl` и инжектит `📎 Кросс-контурные упоминания (паттерн ↔ entity)` когда knowledge из лога совпадает с текущим инжект-набором; infra H10 активирована на обеих осях | ✅ |
| **20** Narrative auto-trigger (разрыв C: through-line) | v1.5.0-alpha | `session-start.sh` при gap ≥8ч вызывает `narrative-compose-lib.sh`, stash'ит brief для `knowledge-activator`, append в `.claude-docs/narrative.md`; manual `/narrative` — override/debug. Принцип «одна команда на жизнь проекта» зафиксирован | ✅ |
| **21** Startup signals (/init-project + /reload auto-hints) | v1.5.1-alpha | `session-start.sh` пишет `startup-signals-${SID}.txt`: missing CLAUDE.md → /init-project hint, global-lessons mtime diff с `SR_LAST_SESSION.ended_at` → /reload hint. `knowledge-activator` инжектит с narrative. Первый шаг broader skill trigger audit. Портабельно (BSD find на macOS + GNU) через `stat + awk` | ✅ |
| **22** /save auto-flush (activity machine log) | v1.5.2-alpha | `hooks/activity-flush-lib.sh` — pure helper. `session-collector.sh` на Stop парсит transcript одним jq-проходом и пишет `.claude-docs/session-activity.md` (tool counts by name + unique basenames + git commits за 4ч). Разведены narrative (SESSION.md) и machine log — каждый выживает независимо. Fix по пути: `printf -- '- ...'` для dash-leading строк | ✅ |
| **23** Periodic digests (weekly knowledge-audit + monthly bridge-health) | v1.5.3-alpha | `hooks/knowledge-audit-digest.sh` (launchd вс 03:15) — счётчики по типам, reliability distribution, FSRS buckets, top overdue, trend line → `~/.claude/global-lessons/_audit-history/audit-YYYY-Www.md`. `hooks/bridge-health-digest.sh` (launchd 1-е 03:30) — status counts, per-status listing, trend → `~/.claude/bridges-history/health-YYYY-MM.md`. Хинты surfaced через startup-signals (v1.5.1-alpha pipeline). Mechanical vs analytical split: digest автоматизирован, `/knowledge-audit` + `/bridge-health` остаются LLM-скиллами для качественного разбора | ✅ |
| **24** /decompose multi-step detector | v1.5.4-alpha | `hooks/decompose-detector.sh` (UserPromptSubmit) — считает step signals (нумерованные/буллеты/коннекторы ru+en), при ≥4 (настраивается `DECOMPOSE_THRESHOLD`) inject gentle hint. Guards: `< 100` chars, уже упомянут `/decompose`/`разбей`, `state ∈ {focus, stuck}`, per-session dedup через `decompose-fired-${SID}.flag`. Output через `hookSpecificOutput.additionalContext`. Решение применять — за агентом. 23 новых теста → 415/415. Первая C-класс heuristic из skill-triggers-audit | ✅ |
| **25** docs-family-check action-gate | v1.5.5-alpha | `hooks/docs-family-check.sh` (PreToolUse на Bash) — детект `git commit` + version marker в staged diff + coverage check docs family (architecture, PLAN, README, CHANGELOG, project CLAUDE.md, docs/*.md). Missing → silent inject. Закрывает knowledge-action gap из case-2026-04-23-memory-without-action-gate (4 релиза дрейфа). Plus rules/CLAUDE.md §Communication Source-check v0.3. Throttle per-session md5(missing-set). 19 тестов → 434/434 | ✅ |
| **26** Engineering escalation mechanism | v1.5.5-alpha+1 | `knowledge-audit-digest.sh` второй проход по pattern/principle: при `blocker: true` + `confirmed_count ≥ escalation_threshold` → секция `⚠️ Engineering escalation needed` + hint `🛠️ Engineering escalation` с приоритетом над overdue/trend. Рекурсивная защита: система сама заявляет когда blocker-tier detection_signals неполны. Pattern-inside-out-blindness получил `escalation_threshold: 15`. Новый principle-knowledge-in-the-world (promotion_tier 3) — три уровня embedded-ness fix'а после инцидента. Case-2026-04-23-text-rule-vs-mechanism — 15-е проявление. 9 новых ассертов → 443/443 | ✅ |
| **27** ⚙️ Trust-guard — первый affect prosthetic (разрыв A функционально) | v1.5.6-alpha | `hooks/trust-guard.sh` PreToolUse на Bash destructive signatures (`rm -rf`, `git reset --hard`, `git push --force`, `git branch -D`, `git checkout --`, `git clean -f`) + scan последних N user messages на auth tokens + target match. Без auth → silent `🛡️ Trust-guard` marker через `hookSpecificOutput.additionalContext`. Per-session throttle md5(signature+target). Principle `principle-affect-as-engineering.md` (tier 3, scope universal) specializes principle-knowledge-in-the-world в domain affect. Формализация класса affect prosthetics в `architecture.md §12` + маркер ⚙️. Case-2026-04-23-sociopathic-architecture-diagnosis фиксирует диагноз | ✅ |
| **28** Active analogy surfacing (разрыв D полный цикл) | v1.6.0 | Upstream: weekly `detect_cross_contour_mentions` в `knowledge-audit-digest.sh`. Ranker: `cli_cross_contour_rank.py` async pre-computation similarity через `indexer.embed_texts` → `cross-contour-ranked.jsonl`. Consumer union filter: `(KF в инжект-наборе) OR (sim ≥ CC_SIMILARITY_THRESHOLD default 0.6)`. Session dedup: `cross-contour-surfaced-${SID}.txt`. Новый мост `bridges/L2-L2-cross-contour.md` (designed). H10 secondary axis: `cc_metrics_format_section` инжектит `📎 Cross-contour H10` в Stop-MESSAGE. Bootstrap: 10 пар на живых данных, similarity 0.65-0.74. +33 теста → 628/628 | ✅ |
| **29** Output language check — первый хук на свойство output | v1.6.3 | `hooks/output-language-check.sh` (Stop / UserPromptSubmit / PreCompact) — детект токенов со смешением алфавитов в last assistant message через `hooks/lib/output-language-detect.py` (regex + exclusions: fenced code, inline code, URLs, markdown links, HTML). State: `output-violations-${SID}.jsonl` со статусами pending/surfaced. Injection через `hookSpecificOutput.additionalContext` в следующий user turn. Закрывает architectural gap: класс ошибок «агент написал X, нарушающее правило свойств output» без BeforeMessage event. Уровень 2 embedded-ness для output-rules. Первый элемент `hooks/lib/` (python-детекторы). Case-2026-04-24-alphabet-mixing-self-detection-failure (16-е проявление pattern-inside-out-blindness, новое измерение — blindness на собственный output). +37 тестов → 685/685 | ✅ |
| **30** Backfill intrusiveness — снят блокер v1.4.0 | v1.6.4 | `hooks/lib/backfill-replay-one.sh` (worker): для каждого user turn архивного транскрипта срез head -n idx + payload `{session_id, transcript_path: slice, prompt: user_text}` → вызов живого детектора в изолированном HOME → re-emit событий с историчным `ts` + `source: backfill` marker + `aggregate_sid`. `hooks/backfill-intrusiveness.sh` (orchestrator, one-off): `find` все JSONL → `xargs -n 1 -P N` параллельно → склейка в `intrusiveness-backfill-history.jsonl` отдельно от live. Прогон 309 транскриптов за 508 сек: **575 событий** в 98 сессиях. Gentle 21% acceptance, proactive 60% acceptance — данные для v1.4.0. +16 тестов → 701/701. Принцип: backfill применим когда формат архивов = live + детектор stateless + историчные ts извлекаются | ✅ |
| **32** Backfill aggregate digest — числа для v1.4.0 | v1.6.6 | `hooks/lib/backfill-aggregate-digest.sh` группирует raw events по `aggregate_sid`, эмитит digest строки со схемой live history (`boundary: stop`, `source: backfill`, budget/metrics/state_distribution заполнены из событий, прочее zero с явным smyслом). Orchestrator получил `--digest` для full pipeline в один вызов. Calibrate.py на 98 digest строках: proactive_max 2→3 (66% потолок), gentle 21% acceptance, distressed не наблюдался. Отчёт `docs/calibration-v1.4-backfill.md`. +27 тестов → 738/738 | ✅ |
| **31** Output language check level 2b — закрытие feedback latency | v1.6.5 | `hooks/output-language-check.sh` расширен веткой PreToolUse — та же `surface_pending` функция параметризована по `hookEventName`. Throttle через существующий status pending/surfaced (first-to-fire помечает, subsequent silent), cross-channel idempotent. Регистрация на PreToolUse с matcher=`""` (все tools). Закрывает latency-окно: между двумя UserPromptSubmit (multi-message workflow) PreToolUse fires более часто → накопленные violations появляются перед следующим tool call. Принцип: уровень 2 embedded-ness разделяется на L2a (UserPromptSubmit, turn-grained) + L2b (PreToolUse, tool-call-grained); L2a + L2b = L2 burst-grained. Case-2026-04-25-level-2-feedback-latency (17-е проявление pattern-inside-out-blindness, новое измерение — темпоральный pattern собственной работы). +10 тестов → 711/711 | ✅ |
| **33** ClaudSoul context pointer — закрытие cross-directory blindness | v1.6.7 | `hooks/claudsoul-context-pointer.sh` (UserPromptSubmit) — substring match на claudsoul/claud soul/claud-soul/клод соул/клод-соул в `.user_prompt` (case-insensitive через `tr`). При срабатывании читает `$CLAUDSOUL_PROJECT_PATH/CLAUDE.md` (default `$HOME/My Project/ClaudSoul`), извлекает `## 5. Текущий статус` (header + первые 25 строк), инжектит через `hookSpecificOutput.additionalContext`. Skip when: cwd within project tree (CLAUDE.md уже загружен иерархически), per-session dedup, project CLAUDE.md missing/unreadable. Env `CLAUDSOUL_PROJECT_PATH` plus `CLAUDSOUL_TEST_PWD` для тестирования. Уровень 3 embedded-ness — mechanical injection не text rule. Закрывает 19-е проявление pattern-inside-out-blindness (case-2026-05-05-claudsoul-blindness-from-home), новое измерение — cross-directory blindness: глобальная модель системы устаревает относительно живого project CLAUDE.md, а Claude Code загружает CLAUDE.md иерархично по cwd. +17 тестов → 755/755 | ✅ |
| **34** Calibration v1.4.0 applied — proactive budget 2→3 | v1.7.0 | Калибровочное окно из бэкфилла (575 событий из 98 сессий, v1.6.4 + v1.6.6) применено к single decisive параметру: `ITR_DEFAULT_PROACTIVE_MAX 2 → 3` в `hooks/intrusiveness-state-lib.sh:52`. Сигнал: 65/98 chunks (66%) упирались в потолок при acceptance 60% — запрос «дай больше», не «слишком шумно». Не применено: `gentle_max` (бюджет не binding constraint, ни один chunk не достиг 5), `distressed` пороги (0 наблюдений), веса cost-осей (timing/silence/injection_bytes max все нули — бэкфилл не реплеит state classifier и cost detectors). Тесты обновлены: 3 ассерта о дефолте (`test_intrusiveness_lib.sh:58`, `test_intrusiveness_lib.sh:66`, `test_itr_event_detector.sh:507`), все 22 файла зелёные. Доки sync: rules/CLAUDE.md, ~/.claude/CLAUDE.md зеркало, PLAN.md, docs/architecture.md, docs/calibration-v1.4-backfill.md (секция «Applied»), CHANGELOG.md, project CLAUDE.md. Принцип: калибровать что видишь, не что хочется — оси с нулевой видимостью в архивах не калибруются | ✅ |

> **Про нумерацию:** фазы нумеровались в порядке ЗАДУМЫВАНИЯ, не реализации. Phase 9 (Entity Knowledge) задумана в v0.5, реализована после Phase 12. Это исторический артефакт, не переименовываем чтобы не ломать ссылки в CHANGELOG/коммитах.

---

## Гипотезы

Все гипотезы проекта — в одной таблице. **Не разбрасывать по фазам.** При появлении новой — добавлять сюда.

**Статусы:**
- ✅ **Подтверждена** — есть метрики подтверждения
- ❌ **Опровергнута** — есть метрики опровержения (с обоснованием)
- 🔁 **Реализована** — код есть, но верификация метриками не проведена
- ❓ **Частично** — есть данные, но недостаточно для выводов
- ⏳ **Не проверена** — только формулировка

### Активные

| # | Гипотеза | Фаза | Статус | Что мерить |
|---|----------|------|--------|-----------|
| **H1** | Граф связей улучшит релевантность знаний | 1 | 🔁 | полезных инжектов / прочитанных зря |
| **H2** | Автоматический /retro через хуки снизит потерю знаний | 3 | 🔁 | уроков/неделю (с vs без хука) |
| **H3** | Confidence-weighted injection повысит точность | 3 | 🔁 | повторные ошибки |
| **H4** | FSRS-decay предотвратит засорение базы | 9 | 🔁 | % weakened знаний / 30 дней |
| **H5** | Семантический поиск MCP превзойдёт file-based | 8 | 🔁 | recall релевантных (A/B) |
| **H6** | Обучение на успехе снизит количество ошибок | 2 | 🔁 | avg `attempts_to_fix` |
| **H7** | Surprise factor ускорит активацию неожиданных знаний | 2 | 🔁 | intensity vs скорость применения |
| **H8** | Траектория мысли повысит точность предсказаний | 3 | ❓ | accuracy >50% (1 сессия — подтверждено) |
| **H9** | Поведенческий анализ надёжнее самоотчёта | 9 | 🔁 | `contradiction.gap_type=stated_vs_inferred` (v1.3.7) — нужен ≥30 кейсов разногласий |
| **H10** | Cross-reference между контурами порождает новые знания | 9 / v1.6.0 | 🔁 | **Двухосевая**: (1) `cross-contour-discoveries.jsonl` растёт через weekly detector (v1.6.0); (2) `surfaced / written ratio ≥ 0.10` в session-collector H10 section (v1.6.0 bootstrap: 10 ranked пар, будущие сессии покажут surfaced %) |
| **H11** | Каскадная фиксация снижает повторяемость ошибок | 10 | 🔁 | `cascading.backward_count` в history digest (v1.3.7) — корреляция с `error_count` baseline начинается с now() |
| **H12** | Guardrails удерживают каскадность в token budget | 10 | 🔁 | `cost_peaks.injection_bytes_max` в history digest (v1.3.7) — proxy для tokens (intrusiveness inject) |
| **H13** | 4D gate снижает игноры gentle | 13 | 🔁 | `gentle_acceptance_rate` +20пп — автосбор v1.3.5, ждём калибровочное окно ≥30 сессий |
| **H14** | Silence_cost предотвращает «вежливую бесполезность» | 13 | 🔁 | # упущенных ретро-важных предупреждений — proactive автосбор v1.3.6, нужен ручной аудит silence debt |
| **H15** | Silence debt активируется в правильных окнах | 13 | 🔁 | ручная оценка 20 активаций — schema v3 пишет в intrusiveness-history.jsonl, требуется ретро-сессия |
| **H16** | 3D-метафора улучшает навигацию >100 узлов | 12 | ⏳ | UX-сессия 2D vs 3D |
| **H17** | Nebulae улучшают понимание структуры базы | 12 | ⏳ | точность ответов 2D vs 3D |
| **H18** | Narrative через /narrative снижает intent-gap в первых 3 turns | 15 (v1.5) | ⏳ | gap-rate первых 3 turns с narrative vs без |
| **H19** | Trust-guard снижает frequency destructive Bash без auth | v1.5.6-alpha | ⏳ | доля session-sessions с ≥1 destructive action без auth маркера (baseline от v1.5.6-alpha) |
| **H22** | `/quality-gate` pre-commit ловит неполный DoD | v1.5.6 | ⏳ | % commits с SKILL.md где unchecked чекбоксы до/после v1.5.6 |
| **H23** | `/enrich` post-ingest увеличивает среднюю плотность entity | v1.5.7 | ⏳ | attrs/entity до и после suggestion (baseline от v1.5.7) |
| **H26** | `distressed` state axis снижает gentle/proactive density в dialog'ах дистресса | v1.5.7 | ⏳ | gentle+proactive events per turn при `state=distressed` vs idle/focus baseline |
| **H27** | AP3 carry-over hint снижает повторное накопление `silence_debt.pending` между сессиями | v1.5.8-alpha | ⏳ | `debt.pending` в первых 5 сессиях после релиза: плато/убывание vs монотонный рост |
| **H28** | `/skill-review` pre-commit ловит contract violations staged SKILL.md | v1.5.8 | ⏳ | % commits с SKILL.md где violations до/после v1.5.8 |
| **H29** | `/learn` success-cascade с attempts count повышает rate /learn после каскада | v1.5.8 | ⏳ | /learn calls после resolved-cascade до/после релиза |
| **H30** | `/retro` auto-draft сокращает латентность resolved-cascade → зафиксированный case | v1.5.8 | ⏳ | drafts created vs drafts accepted per week |
| **H24** | Semantic scoring union filter увеличивает `surfaced_count` относительно set-only v1.3.9 | v1.6.0 | ⏳ | ranked пары с `similarity ≥ 0.6` где KF не в инжект-наборе — «чистый выигрыш» от union (baseline: 10 пар на релизе, все с similarity ≥ 0.64) |
| **H35** | Output language check снижает повтор alphabet-mixing в текущей сессии | v1.6.3 | ⏳ | # violations в `output-violations-${SID}.jsonl` за сессию: ожидание — 1-2 до инжекта surface, 0 после; N сессий подряд без второго violation = подтверждение закрытия петли |
| **H36** | Системный критерий работоспособности: большинство нарушений feedback-rules детектирует система, не собеседник | v1.6.3 | ⏳ | ratio `agent-detected / (agent-detected + user-detected)` feedback violations по всем memory-правилам; baseline от v1.6.3 (ручной аудит ретро), target ≥ 0.7 через 30 сессий |

### Архив
_Пока пусто. H2/H3/H6/H7 реализованы, но ни одна ещё не получила метрики подтверждения/опровержения — как только хотя бы одна получит достоверный сигнал, она переедет сюда с обоснованием._

---

## Архитектурные решения (ADR)

### ADR-001: Markdown как хранилище знаний
**Решение:** Markdown + YAML frontmatter.
**Причина:** Claude Code читает нативно, git-friendly, нет зависимости от БД, человекочитаемо.
**Альтернативы:** SQLite (быстрее, но не читается нативно), JSON (менее читаемо).
**Статус:** Принято.

### ADR-002: Трёхуровневая иерархия (case/pattern/principle)
**Решение:** Три уровня абстракции с промоушеном вверх.
**Причина:** Баланс детальности и обобщения. Аналогия с эпизодической → семантической памятью.
**Альтернативы:** Плоский список (хуже масштабируется), граф без уровней (A-MEM, мощнее, но сложнее).
**Статус:** Принято.

### ADR-003: Confidence scoring 1-5 вместо бинарного
**Решение:** Confidence 1-5 с подкреплением и затуханием.
**Причина:** Позволяет приоритизировать и отсеивать устаревшие.
**Вдохновение:** FSRS, SM-2.
**Статус:** Принято. Decay реализован в v1.1.8.

### ADR-004: Глобальные знания + проектные кейсы
**Решение:** Двухуровневая топология: `~/.claude/global-lessons/` + `project/memory/`.
**Причина:** Универсальные уроки доступны везде, проектная специфика не засоряет другие проекты.
**Статус:** Принято.

### ADR-005: Два контура обучения
**Решение:** Layer 2 расширен вторым контуром: `entity / fact / relation` для внешних источников.
**Причина:** Операционный контур (case/pattern/principle) покрывает собственный опыт. Для документов/книг/чатов нужна сущностная модель с provenance и temporal validity.
**Ключевое:** Confidence факта зависит от источника: `behavioral (3) > document (2) > self-report (1)`.
**Альтернативы отвергнуты:** (а) кодировать всё в case — entity ≠ инцидент; (б) внешняя система — теряется интеграция; (в) Neo4j — overhead, ломает zero-infrastructure.
**Спецификация:** `docs/entity-knowledge.md`.
**Статус:** Принято, реализовано в v1.1.x.

### ADR-006: L6 как 4D gate, не скалярный порог
**Решение:** Режимы prediction (`proactive / gentle / silent_prep / ignore`) — выходы gate от четырёх осей (`confidence × value × cost × state`), а не функция одной confidence.
**Причина:** Confidence отвечает на «насколько вероятно полезно», а не на «стоит ли внимания», «какой ценой», «принимает ли собеседник ввод». Скалярный порог систематически ломает UX.
**Ключевое:** Gate = сравнение сожалений (`regret_if_silent` vs `regret_if_speak`), не фиксированный порог. Cost содержит 6 осей (5 speak + 1 silence как контрвес).
**Спецификация:** `bridges/L3-L6-communicative-prediction.md`, `docs/architecture.md §8`.
**Статус:** Принято, реализовано в v1.3.0 (формализация) → v1.3.3 (активная система с state classifier).

---

## Мета-правила ведения плана

1. **Dashboard + «Что работает сейчас» обновляются ПРИ КАЖДОМ релизе** — до CHANGELOG.
2. **Новые гипотезы — только в таблицу** `## Гипотезы`, не разбрасывать по фазам.
3. **Фазы roadmap — только одной строкой в таблице.** Детали → CHANGELOG. План не дублирует историю.
4. **«Решено НЕ делать» — вечнозелёная секция.** Без обоснования не удалять, без нового аргумента не пересматривать.
5. **ADR пишется один раз и не переписывается.** Если решение отменено — новый ADR с явной отсылкой к старому.
6. **Размер PLAN.md — цель ≤300 строк.** Если растёт — значит детали просочились из CHANGELOG. Чистить.
