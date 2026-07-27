---
name: Source Tiers
description: Веса веб-источников по языку аудитории (primary) и юрисдикции (secondary) для обогащения сущностей (/enrich). Таблица доменов → tier → confidence модификатор.
type: reference
version: 0.3.0
last_updated: '2026-04-22'
---

# Source Tiers — веса источников при web-обогащении

Справочник для скилла `/enrich`. Описывает, какому домену в вебе можно доверять и насколько. **Не код** — текстовая таблица, редактируется вручную.

## Две оси отбора (v0.3)

`/enrich` использует **две оси** для выбора источников:

| Ось | Назначение | Когда primary |
|-----|------------|---------------|
| **Language** (русскоязычные / польскоязычные / англоязычные медиа) | Narrative: статьи, отзывы, обзоры, интервью, упоминания | Всегда, для narrative-поисков. Язык определяется interlocutor_lang ∪ support_languages ∪ target_audience ∪ domain |
| **Jurisdiction** (PL, US, DE, …) | Регуляторные факты: реестры, налоги, законы, лицензии | Только для регистрационных ID (`nip`, `ein`, `krs`) или по явному запросу «проверь реквизиты» |

**Почему language-first:** польская компания с русскоязычной аудиторией описывается в ru-медиа, а не в польских. Искать narrative в польских СМИ для такой сущности = почти гарантированно 0 результатов. Юрисдикция же отвечает на узкий класс вопросов (реестр, налоги) — для них язык неважен.

## Принцип tier

Tier — оценка надёжности домена. Независимо от `source_type` (self_report / document / third_party / behavioral / cross_reference), tier отвечает на вопрос «насколько мы верим этому конкретному сайту».

| Tier | Что это | Confidence override |
|------|---------|---------------------|
| 1 | Гос-реестры, официальные ведомства, первоисточники | 4 |
| 2 | Энциклопедии, мировые инфо-агентства, официальные сайты самих сущностей | 3 |
| 3 | Отраслевые СМИ, проверенные аналитические блоги | 2 |
| 4 | Форумы, соц-сети, любительские блоги, пересказ без атрибуции | 1 |

Tier 1 перекрывает стандартную формулу `recalc_confidence` — гос-реестр заслуживает доверия выше даже одиночного документа (source_type=document → 2 по формуле, но tier 1 → 4).

## Выбор tier для URL

1. Взять host (без www, без path).
2. Искать точное совпадение в таблице юрисдикции.
3. Искать по суффиксу (`*.gov.pl` → tier 1).
4. Если не нашлось — default tier 3 для обычных .com/.org, tier 4 для блог-платформ (substack, medium, livejournal, wordpress.com).

## PL (Польша)

### Tier 1 — первоисточники
| Домен | Что это |
|-------|---------|
| `*.gov.pl` | любое польское ведомство (biznes, podatki, obywatel, mf, zus) |
| `sejm.gov.pl`, `isap.sejm.gov.pl` | законы и правовые акты |
| `zus.pl` | соцстрах |
| `krs-online.com.pl`, `rejestr.io`, `aleo.com/pl` | выписки из KRS (польский реестр предпринимателей) |
| `stat.gov.pl`, `gus.gov.pl` | статистика |
| `nbp.pl` | Национальный банк Польши |

### Tier 2 — авторитет и первоисточники сущностей
| Домен | Что это |
|-------|---------|
| `wikipedia.org` (pl/en/ru) | энциклопедия |
| `reuters.com`, `apnews.com`, `bbc.com` | мировые агентства |
| `pap.pl` | Польское агентство печати |
| `rzeczpospolita.pl`, `rp.pl` | качественная пресса |
| `gazetaprawna.pl` | правовые новости |
| `<official-site-of-entity>` | сайт самой сущности (self_report, но подтверждает) |

### Tier 3 — отраслевые
| Домен | Что это |
|-------|---------|
| `bankier.pl`, `money.pl`, `forsal.pl` | финансы |
| `businessinsider.com.pl` | бизнес-новости |
| `gazeta.pl`, `wp.pl`, `onet.pl` | общие массовые СМИ |
| `prawo.pl`, `infor.pl` | правовые справочники |

### Tier 4 — блоги и форумы
| Домен | Что это |
|-------|---------|
| `wykop.pl` | польский «реддит» |
| `reddit.com` (r/poland, r/ELI5) | соц-дискуссии |
| `medium.com`, `substack.com`, `*.blogspot.com` | платформенные блоги |

> Русскоязычные `habr.com`, `vc.ru`, `example-it.media` — см. секцию «Russian-language media» ниже (Tier 3 ru-media, не PL Tier 4).

## Russian-language media (язык аудитории, не юрисдикция)

Применяется **дополнительно** к PL/US/DE/… когда у сущности есть признаки русскоязычной аудитории: `support_languages` содержит «Русский», `target_audience` упоминает русскоязычных / диаспору / СНГ, или `domain` содержит `russian_speaking_*`. Язык ≠ юрисдикция: польская компания с русскоязычным контентом должна проверяться и по PL-источникам, и по ru-язычным.

### Tier 2 — авторитет
| Домен | Что это |
|-------|---------|
| `thebell.io` | качественный бизнес-журнал |
| `meduza.io` | общая пресса в эмиграции |
| `example-news.media`, `news.example-news.media` | беларуское издание в эмиграции, наследник TUT.BY (Wikipedia подтверждает) |
| `nashaniva.com` | беларуская «Наша Нива» — старейшее независимое |
| `rbc.ru` | бизнес-новости |
| `vedomosti.ru` | деловая пресса |
| `kommersant.ru` | деловая пресса |
| `forbes.ru`, `forbes.com.cy`, `forbes.ua`, `forbes.pl`, `forbes.kz` | Forbes региональные издания (каждое самостоятельное, не дубль .com) |
| `novayagazeta.eu` | качественная пресса в эмиграции |

### Tier 3 — отраслевые ru
| Домен | Что это |
|-------|---------|
| `habr.com` | IT / tech сообщество |
| `vc.ru` | стартапы / бизнес |
| `example-it.media`, `example-it.io` | белорусский IT / диаспора |
| `rb.ru` (Rusbase) | венчур / стартапы |
| `tproger.ru` | IT |
| `thevillage.ru` | lifestyle / бизнес |
| `the-village.ru` | мир урбан бизнеса |
| `zarplata.ru` | рынок труда |
| `hh.ru/article` | рынок труда |

### Tier 3 — диаспорные (RU → PL / EU)
| Домен | Что это |
|-------|---------|
| `thedevochki.com` | женская эмигрантская среда |
| `relocode.io`, `relocation.guide` | релокация-справочники |
| `emigration.guru` | эмиграция |
| `nawschetach.pl`, `polsha24.com`, `ru-pl.com`, `pol-ru.com` | русскоязычные СМИ в Польше |
| `salampol.com`, `belarusians.pl`, `nashaniva.com` | белорусская/украинская диаспорная пресса |

### Tier 4 — блоги / соцсети / мессенджеры
| Домен / платформа | Что это |
|-------------------|---------|
| `t.me/*` (Telegram каналы) | каналы диаспоры, тематические |
| `youtube.com` (каналы без проверки) | интервью / обзоры |
| `medium.com`, `substack.com` RU-язычные | индивидуальные авторы |
| `livejournal.com`, `dzen.ru` | блоги |
| `pikabu.ru`, `reddit.com/r/russia`, `reddit.com/r/Polska` | форумы |

**Важно:** эти источники добавляются к основной юрисдикционной таблице, не заменяют её. Польская компания с русскоязычной аудиторией проверяется по PL Tier 1-2 (реестр, сайт, польская пресса) **и** по ru-media Tier 2-3 (статьи про компанию в русскоязычных изданиях).

## Global (дефолт, если юрисдикция не определена или не охвачена выше)

### Tier 1
- Любой `*.gov.<cc>` (суверенные ведомства)
- Международные организации: `un.org`, `who.int`, `worldbank.org`, `imf.org`, `oecd.org`, `ec.europa.eu`, `eur-lex.europa.eu`

### Tier 2
- `wikipedia.org`, `britannica.com`
- `reuters.com`, `apnews.com`, `bbc.com`, `nytimes.com`, `economist.com`, `ft.com`
- `nature.com`, `science.org`, `ieee.org`, `acm.org`

### Tier 3
- Отраслевые СМИ (`techcrunch.com`, `theverge.com`, `arstechnica.com`)
- Национальная качественная пресса вне Tier 2
- Европейские бизнес-/стартап-порталы: `example.media` (Кипр, англоязычный; редакционные интервью про стартап-экосистему)

### Tier 4
- Блог-платформы, форумы, `linkedin.com` (персональные посты, не официальные профили)

## Детект язык+юрисдикция (порядок v0.3)

### A. Primary: языки аудитории

Собрать множество `primary_languages`:

1. **Interlocutor language** — язык текущей сессии. Если пользователь пишет по-русски → `ru` в множестве всегда.
2. **`attributes.support_languages`** — прямой список, нормализовать в ISO.
3. **`attributes.target_audience`** — «русскоязыч»/«диаспор»/«СНГ» → `ru`; «English-speaking»/«international» → `en`; «Polska»/«polsk*» → `pl`.
4. **`domain`** — `russian_speaking_*` → `ru`; `polish_speaking_*`/`pl_*` → `pl`; `us_*`/`international_*` → `en`.
5. **`aliases` / `name`** — алфавит алиасов как сигнал.

Пусто → fallback язык юрисдикции → default `en`.

### B. Secondary: юрисдикция (для регуляторных запросов)

Применять в таком порядке — первое сработавшее побеждает:

1. **Связь с place-сущностью** — `entity.relations[].to` или `edges` ведёт на `entity-<country>.md` / `entity-<city>.md` через `part_of`, `applied_to`, `located_in`
2. **Поле `domain`** — явные маркеры юрисдикции: `poland_business`, `poland_law`, `us_tax_law`, `eu_gdpr`, `russian_it`
3. **Атрибуты:**
   - `country: Poland` / `country_code: PL`
   - `address` содержит польский индекс (`NN-NNN <city>`) или город (Warszawa, Gdańsk, Kraków, Wrocław, Poznań)
   - `nip`, `regon`, `krs` — польские налоговые/регистрационные номера
   - `legal_form: Spółka z o.o. | JDG | S.A.` — польские юрформы
4. **Имя / aliases** — только если явный маркер юрисдикции (`* Sp. z o.o.`, `* LLC`, `* GmbH`)

Если ни один сигнал не сработал → юрисдикция `global`, regulatory pass пропустить.
Пользователь может переопределить через флаг `--jurisdiction=PL`.

## Новые юрисдикции

Когда встретится сущность из не-охваченной юрисдикции (например US, DE, UA):
1. Добавить секцию в этот файл (Tier 1-4, минимум 3-5 доменов на tier)
2. Обязательно включить: реестр компаний, налоговое ведомство, статистику, центральный банк, парламент / законы
3. Дата добавления — в `last_updated` файла
