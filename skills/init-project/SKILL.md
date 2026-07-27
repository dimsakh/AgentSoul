---
name: init-project
description: "Инициализация проекта: CLAUDE.md, SESSION.md, документация, память. Запускать при начале работы в новом проекте."
user-invocable: true
argument-hint: "[описание проекта в нескольких словах]"
---

# Init Project

**Type:** worker

Set up a new project directory for productive work with Claude Code.

## What to create

### 1. CLAUDE.md in the project root

Create `CLAUDE.md` using the template from `~/.claude/templates/CLAUDE.md.tmpl` (if exists) or following this structure. Fill in by reading project files (package.json, README, src/, etc.):

```markdown
# [Project Name] — CLAUDE.md

> Этот файл — единый источник правды для Claude Code при работе с проектом.

## 1. О проекте
[Что это за проект — 1-2 предложения. Спросить пользователя если неясно.]

## 2. Стек технологий
| Слой | Технология | Версия |
|------|-----------|--------|
[Заполнить из package.json, requirements.txt, etc.]

## 3. Структура проекта
[Дерево ключевых директорий и их назначение]

## 4. Как запустить
- Dev: `...`
- Build: `...`
- Test: `...`

## 5. Бизнес-правила
[Спросить пользователя о критических правилах, которые нельзя нарушать]

## 6. Паттерны кода
[Именование файлов, архитектура, паттерны из существующего кода]

## 7. Git и деплой
[Как деплоить, куда, какие ограничения]

## 8. Текущий статус
[Что работает, что в процессе — спросить пользователя]

## 9. Правила для этого проекта
- Всегда обновлять SESSION.md после завершения значимой работы
- Тестировать изменения перед тем как отчитаться
- Следовать существующим конвенциям кода
- При работе с библиотеками — проверять актуальную документацию
- Коммиты на русском языке
```

### 2. `.claude-docs/` — documentation structure

```
.claude-docs/
├── sessions/    # Session logs (YYYY-MM-DD_description.md)
├── modules/     # Module documentation (one file per module)
└── refactoring/ # Refactoring artifacts (audits, process maps)
```

### 3. SESSION.md in the project root

Use `~/.claude/templates/SESSION.md.tmpl` if available, or:

```markdown
# Session Log

## [today's date] — Инициализация проекта
### Что сделано
- Создан CLAUDE.md с правилами проекта
- Инициализирована структура документации
- Настроено отслеживание сессий

### Текущее состояние
- [Описать что видим в проекте]

### Следующие шаги
- [Спросить пользователя что будем делать]

### Ключевые решения
- Инициализирована система документирования
```

### 4. Project memory directory

Ensure `~/.claude/projects/[project-path]/memory/` exists with a MEMORY.md index file.

### 5. Project knowledge directory (v0.2)

If the project is likely to generate domain-specific knowledge, create:
```
knowledge/
└── META.md  # Copy from ~/.claude/global-lessons/META.md or ClaudSoul/knowledge/META.md
```

This is optional — most projects use only `~/.claude/global-lessons/` for cross-project knowledge.

## Process

1. Read the project directory — understand what's there
2. Analyze code: package.json, README, src structure, config files
3. Create all items above, filling in as much as possible automatically
4. Show the user what was created
5. Ask them to verify/correct, especially:
   - Business rules (section 5)
   - Deploy process (section 7)
   - Current status (section 8)
6. Ask: "Что будем делать сегодня?"

## Definition of Done

- [ ] CLAUDE.md created with all 9 sections filled
- [ ] SESSION.md created with initial entry
- [ ] `.claude-docs/` structure created (sessions/, modules/, refactoring/)
- [ ] Project memory directory ensured
- [ ] User verified business rules and deploy process

**Version:** 1.0.0
**Last Updated:** 2026-04-15
