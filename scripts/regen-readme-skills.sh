#!/usr/bin/env bash
# ClaudSoul — регенерация авто-секций README.md
# Секции:
#   1. <!-- SKILLS-TABLE:START --> ... <!-- SKILLS-TABLE:END -->
#      источник: skills/*/SKILL.md (frontmatter name + description)
#   2. <!-- HOOKS-TABLE:START --> ... <!-- HOOKS-TABLE:END -->
#      источник: hooks/*.sh (строка 2 после "— "); исключены *-lib.sh
#
# Запуск: bash scripts/regen-readme-skills.sh [путь_к_репо]
# Цель файла README — переопределяется env README_FILE (по умолчанию $REPO/README.md).
# Маркеры таблиц сейчас живут в README.ru.md → README_FILE="$REPO/README.ru.md".

set -euo pipefail

REPO="${1:-${CLAUDSOUL_REPO:-$(cd "$(dirname "$0")/.." && pwd)}}"
SKILLS_DIR="$REPO/skills"
HOOKS_DIR="$REPO/hooks"
README="${README_FILE:-$REPO/README.md}"

[ -d "$SKILLS_DIR" ] || { echo "ERROR: skills/ not found at $SKILLS_DIR" >&2; exit 1; }
[ -d "$HOOKS_DIR" ]  || { echo "ERROR: hooks/ not found at $HOOKS_DIR" >&2; exit 1; }
[ -f "$README" ]     || { echo "ERROR: README.md not found at $README" >&2; exit 1; }

# ---------- helpers ----------

# Replace section between START/END markers in README with a file's contents.
# Args: marker_base (e.g. SKILLS-TABLE), section_file
replace_section() {
    local marker_base="$1"
    local section_file="$2"
    local start="<!-- ${marker_base}:START -->"
    local end="<!-- ${marker_base}:END -->"

    if ! grep -qF "$start" "$README"; then
        echo "WARN: marker '$start' not found in README.md — skipping $marker_base" >&2
        return 0
    fi
    if ! grep -qF "$end" "$README"; then
        echo "WARN: marker '$end' not found in README.md — skipping $marker_base" >&2
        return 0
    fi

    local tmp="${README}.tmp"
    awk -v start="$start" -v end="$end" -v section_file="$section_file" '
        BEGIN { in_section = 0 }
        index($0, start) {
            while ((getline line < section_file) > 0) print line
            close(section_file)
            in_section = 1
            next
        }
        index($0, end) {
            in_section = 0
            next
        }
        !in_section { print }
    ' "$README" > "$tmp"
    mv "$tmp" "$README"
}

# ---------- 1. SKILLS-TABLE ----------

SKILLS_ROWS=$(mktemp)
SKILLS_SECTION=$(mktemp)
trap 'rm -f "$SKILLS_ROWS" "$SKILLS_SECTION" "$HOOKS_ROWS" "$HOOKS_SECTION"' EXIT

for skill_dir in "$SKILLS_DIR"/*/; do
    skill_md="$skill_dir/SKILL.md"
    [ -f "$skill_md" ] || continue

    fields=$(awk '
        /^---$/ { delim++; if (delim > 1) exit; next }
        delim == 1 && /^name:/ {
            sub(/^name:[[:space:]]*/, "")
            gsub(/^["\x27]/, ""); gsub(/["\x27]$/, "")
            n = $0
        }
        delim == 1 && /^description:/ {
            sub(/^description:[[:space:]]*/, "")
            gsub(/^["\x27]/, ""); gsub(/["\x27]$/, "")
            d = $0
        }
        END { print n "\t" d }
    ' "$skill_md")

    name=$(printf '%s' "$fields" | cut -f1)
    desc=$(printf '%s' "$fields" | cut -f2-)
    [ -z "$name" ] && continue
    [ -z "$desc" ] && desc="(нет описания в SKILL.md)"
    desc=${desc//|/\\|}

    printf '| `/%s` | %s |\n' "$name" "$desc" >> "$SKILLS_ROWS"
done

sort "$SKILLS_ROWS" -o "$SKILLS_ROWS"

{
    echo "<!-- SKILLS-TABLE:START -->"
    echo ""
    echo "| Команда | Что делает |"
    echo "|---------|-----------|"
    cat "$SKILLS_ROWS"
    echo ""
    echo "<!-- SKILLS-TABLE:END -->"
} > "$SKILLS_SECTION"

replace_section "SKILLS-TABLE" "$SKILLS_SECTION"
SKILLS_COUNT=$(wc -l < "$SKILLS_ROWS" | tr -d ' ')

# ---------- 2. HOOKS-TABLE ----------

HOOKS_ROWS=$(mktemp)
HOOKS_SECTION=$(mktemp)

for hook_sh in "$HOOKS_DIR"/*.sh; do
    [ -f "$hook_sh" ] || continue
    base=$(basename "$hook_sh")

    # Skip libraries
    case "$base" in
        *-lib.sh) continue ;;
    esac

    # Extract line 2 after "— " separator
    # Line 2 format: # <name>.sh — <event>: <description>
    line2=$(awk 'NR == 2 { print }' "$hook_sh")

    # Must start with "# "
    case "$line2" in
        "# "*) ;;
        *) echo "WARN: $base: line 2 is not a comment, skipping" >&2; continue ;;
    esac

    # Extract everything after the first em-dash
    desc=$(printf '%s' "$line2" | sed -E 's/^# [^—]+—[[:space:]]*//')
    if [ -z "$desc" ] || [ "$desc" = "$line2" ]; then
        echo "WARN: $base: no '— ' separator on line 2, skipping" >&2
        continue
    fi

    desc=${desc//|/\\|}
    name="${base%.sh}"
    printf '| `%s` | %s |\n' "$name" "$desc" >> "$HOOKS_ROWS"
done

sort "$HOOKS_ROWS" -o "$HOOKS_ROWS"

{
    echo "<!-- HOOKS-TABLE:START -->"
    echo ""
    echo "| Хук | Когда срабатывает и что делает |"
    echo "|-----|-------------------------------|"
    cat "$HOOKS_ROWS"
    echo ""
    echo "<!-- HOOKS-TABLE:END -->"
} > "$HOOKS_SECTION"

replace_section "HOOKS-TABLE" "$HOOKS_SECTION"
HOOKS_COUNT=$(wc -l < "$HOOKS_ROWS" | tr -d ' ')

# ---------- report ----------

echo "README regenerated: $SKILLS_COUNT skills, $HOOKS_COUNT hooks."
