#!/usr/bin/env bash
# test_disagreement_loop.sh — контур опровержения: producer → читатель → закрытие.
#
# Зачем. Читатель pending-записей существует с v0.4.6, писателя не было ни одного
# дня: 0 файлов disagreement-pending на 1239 в state/, и как следствие
# contradicted_count = 0 во всех 265 знаниях. Отказ был тихим — ничего не падало,
# просто счётчик умел только расти. Тест фиксирует все три звена, включая то, на
# чём контур разошёлся бы снова: писатель и читатель обязаны собирать ОДНО имя файла
# (в session-collector сосуществуют payload-sid и PPID-версия).
set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ACTIVATOR="$HOOKS_DIR/knowledge-activator.sh"
COLLECTOR="$HOOKS_DIR/session-collector.sh"
BUMP="$HOOKS_DIR/knowledge-counter-bump.sh"
REPO_ROOT="$(cd "$HOOKS_DIR/.." && pwd)"
for f in "$ACTIVATOR" "$COLLECTOR" "$BUMP"; do
    [ -f "$f" ] || { echo "FAIL: $f not found"; exit 1; }
done
command -v jq >/dev/null 2>&1 || { echo "SKIP: jq недоступен"; exit 0; }

PASS=0
FAIL=0
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

assert_eq() {
    local expected="$1" actual="$2" label="$3"
    if [ "$expected" = "$actual" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: ожидалось '$expected', получено '$actual'"; fi
}
assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if printf '%s' "$haystack" | grep -qF "$needle"; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: не найдено '$needle'"; fi
}

STATE="$TMP/home/.claude/hooks/state"
LESSONS="$TMP/home/.claude/global-lessons"

# $1 — slug, $2 — confidence, $3 — blocker (true/false)
make_knowledge() {
    cat > "$LESSONS/pattern-$1.md" <<KF
---
name: $1 rule
description: desc $1
type: pattern
confidence: $2
impact: 4
confirmed_count: 1
contradicted_count: 0
last_confirmed: 2026-01-01
status: active
blocker: $3
domain: [devops]
situation: deploying_to_production
trigger: deploy_command
tags: [deploy, rsync, database, exclude]
---
Body.
KF
}

setup() {
    rm -rf "$TMP/home"
    mkdir -p "$LESSONS" "$STATE"
}
reset_gate() { rm -f "$STATE"/knowledge_injected_* 2>/dev/null || true; }

run_activator() {  # $1 — session_id
    printf '{"session_id":"%s","tool_name":"Bash","cwd":"/tmp/proj","tool_input":{"command":"rsync deploy database to production server"}}' "$1" | \
    env HOME="$TMP/home" CLAUDE_CODE_SESSION_ID="$1" STATE_DIR="$STATE" \
        CLAUDSOUL_ROOT="$REPO_ROOT" SKIP_MCP_FALLBACK=1 bash "$ACTIVATOR" >/dev/null 2>&1
}
run_collector() {  # $1 — session_id; печатает накопленные алерты
    printf '{"session_id":"%s","transcript_path":"","cwd":""}' "$1" | \
        STATE_DIR="$STATE" bash "$COLLECTOR" >/dev/null 2>&1
    cat "$STATE/pending-alerts.txt" 2>/dev/null || true
}
PLOG() { echo "$STATE/disagreement-pending-$1.jsonl"; }
lines() { { grep -c '' "$1" 2>/dev/null || echo 0; } | tr -d ' '; }

# === T1: blocker-tier знание с confidence>=4 → pending-запись ===
setup
make_knowledge blocked 5 true
run_activator s1
assert_eq "1" "$(lines "$(PLOG s1)")" "T1a: pending-запись создана"
assert_eq "pending" "$(jq -r '.outcome' "$(PLOG s1)")" "T1b: outcome=pending"
assert_eq "pattern-blocked" "$(jq -r '.key' "$(PLOG s1)")" "T1c: ключ = имя знания"
assert_eq "5" "$(jq -r '.confidence' "$(PLOG s1)")" "T1d: confidence записан"
assert_eq "Bash" "$(jq -r '.tool' "$(PLOG s1)")" "T1e: инструмент встречи записан"

# === T2: повторное срабатывание тем же знанием → дедуп ===
reset_gate
run_activator s1
assert_eq "1" "$(lines "$(PLOG s1)")" "T2: дедуп по знанию в пределах сессии"

# === T3: знание confidence>=4, но НЕ blocker-tier → записи нет (узкий режим) ===
setup
make_knowledge loud 5 false
run_activator s3
assert_eq "0" "$([ -f "$(PLOG s3)" ] && echo 1 || echo 0)" "T3: не-blocker знание не создаёт pending"

# === T4: blocker-tier, но confidence<4 → записи нет ===
setup
make_knowledge weak 3 true
run_activator s4
assert_eq "0" "$([ -f "$(PLOG s4)" ] && echo 1 || echo 0)" "T4: confidence<4 не создаёт pending"

# === T5: имя файла у писателя и читателя совпадает (payload-sid) ===
setup
make_knowledge blocked 5 true
run_activator "sid-shared-42"
assert_eq "1" "$(lines "$(PLOG sid-shared-42)")" "T5a: писатель использует payload-sid"
OUT=$(run_collector "sid-shared-42")
assert_contains "$OUT" "⚡ 1 blocker-tier" "T5b: читатель нашёл файл писателя"

# === T6: закрытие исхода снимает алерт ===
printf '{"date":"2026-07-25T00:00:00Z","key":"pattern-blocked","outcome":"outdated_knowledge"}\n' >> "$(PLOG sid-shared-42)"
: > "$STATE/pending-alerts.txt"
OUT=$(run_collector "sid-shared-42")
if printf '%s' "$OUT" | grep -qF "blocker-tier знание"; then
    FAIL=$((FAIL + 1)); echo "FAIL [T6]: алерт остался после закрытия исхода"
else PASS=$((PASS + 1)); fi

# === T7: два знания, одно закрыто → счётчик 1, не 0 и не 2 ===
setup
make_knowledge blocked 5 true
make_knowledge other 5 true
run_activator "sid-two"
assert_eq "2" "$(lines "$(PLOG sid-two)")" "T7a: две pending-записи"
printf '{"date":"2026-07-25T00:00:00Z","key":"pattern-blocked","outcome":"confirmed_knowledge"}\n' >> "$(PLOG sid-two)"
: > "$STATE/pending-alerts.txt"
OUT=$(run_collector "sid-two")
assert_contains "$OUT" "⚡ 1 blocker-tier" "T7b: закрытое не считается, открытое считается"

# === T8: читатель без файла не падает (регрессия на смену схемы имени) ===
setup
RC=0
run_collector "sid-nofile" >/dev/null || RC=$?
assert_eq "0" "$RC" "T8: нет pending-файла → rc=0, тишина"

# === T9-T11: механический инкремент счётчиков ===
setup
make_knowledge bump 5 true
LESSONS_DIR="$LESSONS" bash "$BUMP" pattern-bump contradicted "устарело" "case-x.md" >/dev/null 2>&1
assert_eq "1" "$(grep -c '^contradicted_count: 1$' "$LESSONS/pattern-bump.md")" "T9: contradicted_count 0 → 1"
assert_eq "1" "$(grep -c 'kind: contradicted' "$LESSONS/pattern-bump.md")" "T10: запись в modification_history"
LESSONS_DIR="$LESSONS" bash "$BUMP" pattern-bump confirmed >/dev/null 2>&1
assert_eq "1" "$(grep -c '^confirmed_count: 2$' "$LESSONS/pattern-bump.md")" "T11a: confirmed_count 1 → 2"
assert_eq "1" "$(grep -c "^last_confirmed: $(date '+%Y-%m-%d')$" "$LESSONS/pattern-bump.md")" "T11b: last_confirmed обновлён"

# === T12: несуществующее знание → rc=1, ничего не создано ===
RC=0
LESSONS_DIR="$LESSONS" bash "$BUMP" pattern-nope confirmed >/dev/null 2>&1 || RC=$?
assert_eq "1" "$RC" "T12: неизвестное знание → rc=1"

echo ""
echo "disagreement-loop tests: $PASS/$((PASS + FAIL)) passed"
[ "$FAIL" -eq 0 ]
