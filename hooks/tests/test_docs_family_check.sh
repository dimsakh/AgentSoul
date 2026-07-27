#!/usr/bin/env bash
# test_docs_family_check.sh — docs-family-check.sh coverage.
# Изоляция через STATE_DIR + tmp git repo per test.

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$HOOKS_DIR/docs-family-check.sh"

[ -f "$SCRIPT" ] || { echo "FAIL: $SCRIPT not found"; exit 1; }

PASS=0
FAIL=0

assert_contains() {
    local haystack="$1" needle="$2" label="$3"
    if echo "$haystack" | grep -Fq "$needle"; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: '$needle' not in output:"; echo "$haystack"; fi
}
assert_empty() {
    local actual="$1" label="$2"
    if [ -z "$actual" ] || [ "$actual" = "{}" ]; then PASS=$((PASS + 1))
    else FAIL=$((FAIL + 1)); echo "FAIL [$label]: expected empty, got: $actual"; fi
}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
export STATE_DIR="$TMP/state"
mkdir -p "$STATE_DIR"

# --- Setup helper: new tmp git repo ---
new_repo() {
    local repo="$1"
    rm -rf "$repo"
    mkdir -p "$repo"
    git -C "$repo" init -q 2>/dev/null
    git -C "$repo" config user.email "t@e"
    git -C "$repo" config user.name "t"
    # Seed initial commit so diff --cached shows staged changes, not whole tree
    echo "# Init" > "$repo/README.md"
    echo "# Plan" > "$repo/PLAN.md"
    echo "# Changelog" > "$repo/CHANGELOG.md"
    echo "# Claude" > "$repo/CLAUDE.md"
    mkdir -p "$repo/docs"
    echo "# Arch" > "$repo/docs/architecture.md"
    git -C "$repo" add . >/dev/null 2>&1
    git -C "$repo" commit -q -m "seed" 2>/dev/null
}

run_with() {
    local sid="$1" cwd="$2" command="$3" tool="${4:-Bash}"
    local payload
    payload=$(jq -cn \
        --arg sid "$sid" --arg cwd "$cwd" --arg cmd "$command" --arg tool "$tool" \
        '{session_id: $sid, tool_name: $tool, tool_input: {command: $cmd}, cwd: $cwd}')
    printf '%s' "$payload" | STATE_DIR="$STATE_DIR" bash "$SCRIPT" 2>/dev/null
}

# ============================================================================
# T1: tool_name != Bash → skip
# ============================================================================
REPO="$TMP/repo1"
new_repo "$REPO"
OUT=$(run_with "sid1" "$REPO" "git commit -m test" "Edit")
assert_empty "$OUT" "T1: non-Bash tool → skip"

# ============================================================================
# T2: Bash но не git commit → skip
# ============================================================================
OUT=$(run_with "sid2" "$REPO" "ls -la")
assert_empty "$OUT" "T2: Bash без git commit → skip"

# ============================================================================
# T3: git commit но staged пуст → skip
# ============================================================================
OUT=$(run_with "sid3" "$REPO" "git commit -m test")
assert_empty "$OUT" "T3: git commit без staged → skip"

# ============================================================================
# T4: staged без version marker → skip
# ============================================================================
echo "new content" >> "$REPO/README.md"
git -C "$REPO" add README.md
OUT=$(run_with "sid4" "$REPO" "git commit -m test")
assert_empty "$OUT" "T4: staged без version marker → skip"
git -C "$REPO" reset -q HEAD
git -C "$REPO" checkout -q -- .

# ============================================================================
# T5: version bump и вся docs family в stage → skip
# ============================================================================
for f in README.md PLAN.md CHANGELOG.md CLAUDE.md docs/architecture.md; do
    echo "v1.2.3-alpha update" >> "$REPO/$f"
done
git -C "$REPO" add . >/dev/null 2>&1
OUT=$(run_with "sid5" "$REPO" "git commit -m 'release v1.2.3'")
assert_empty "$OUT" "T5: full docs family staged → skip"
git -C "$REPO" reset -q HEAD
git -C "$REPO" checkout -q -- .

# ============================================================================
# T6: version bump с missing docs/architecture.md → fire
# ============================================================================
echo "v1.2.4-alpha bump" >> "$REPO/README.md"
echo "v1.2.4" >> "$REPO/CHANGELOG.md"
git -C "$REPO" add README.md CHANGELOG.md
OUT=$(run_with "sid6" "$REPO" "git commit -m 'release v1.2.4'")
assert_contains "$OUT" "Docs family drift" "T6a: version bump без полного family → fire"
assert_contains "$OUT" "docs/architecture.md" "T6b: architecture.md в missing"
assert_contains "$OUT" "PLAN.md" "T6c: PLAN.md в missing"
assert_contains "$OUT" "CLAUDE.md" "T6d: CLAUDE.md в missing"

# ============================================================================
# T7: per-session dedup — тот же diff → skip
# ============================================================================
OUT=$(run_with "sid6" "$REPO" "git commit -m 'release v1.2.4 retry'")
assert_empty "$OUT" "T7: same session same missing → dedup"

# ============================================================================
# T8: другая сессия — fire снова
# ============================================================================
OUT=$(run_with "sid8" "$REPO" "git commit -m 'release v1.2.4'")
assert_contains "$OUT" "Docs family drift" "T8: cross-session independence"

# ============================================================================
# T9: CWD не git repo → skip
# ============================================================================
NONGIT="$TMP/nongit"
mkdir -p "$NONGIT"
OUT=$(run_with "sid9" "$NONGIT" "git commit -m x")
assert_empty "$OUT" "T9: не git repo → skip"

# ============================================================================
# T10: валидный JSON output
# ============================================================================
git -C "$REPO" reset -q HEAD
git -C "$REPO" checkout -q -- .
echo "v1.2.5-alpha" >> "$REPO/README.md"
git -C "$REPO" add README.md
OUT=$(run_with "sid10" "$REPO" "git commit -m v1.2.5")
echo "$OUT" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null 2>&1 \
    && { PASS=$((PASS+1)); } \
    || { FAIL=$((FAIL+1)); echo "FAIL [T10]: invalid JSON or wrong hookEventName: $OUT"; }

# ============================================================================
# T11 (v1.6.2 — R3 false-positive fix): extras в docs/*.md НЕ учитываются по
# умолчанию. Frozen/archive docs (research, vision, analysis-*) не требуют
# bump'а при install-patch релизе. Расширение — через DOCS_FAMILY_LIST env.
# ============================================================================
REPO11="$TMP/repo11"
new_repo "$REPO11"
echo "# Extra doc" > "$REPO11/docs/research.md"
git -C "$REPO11" add docs/research.md
git -C "$REPO11" commit -q -m "add research doc"
echo "v1.3.0-alpha" >> "$REPO11/README.md"
echo "v1.3.0" >> "$REPO11/CHANGELOG.md"
echo "v1.3.0" >> "$REPO11/PLAN.md"
echo "v1.3.0" >> "$REPO11/CLAUDE.md"
echo "v1.3.0" >> "$REPO11/docs/architecture.md"
git -C "$REPO11" add README.md CHANGELOG.md PLAN.md CLAUDE.md docs/architecture.md
OUT=$(run_with "sid11" "$REPO11" "git commit -m v1.3.0")
echo "$OUT" | grep -Fq "docs/research.md" \
    && { FAIL=$((FAIL+1)); echo "FAIL [T11a]: docs/research.md не должен быть в missing при default DOCS_FAMILY (R3 false-positive)"; } \
    || PASS=$((PASS+1))
# При полном default family в stage — silent
assert_empty "$OUT" "T11b: full default family staged → silent, frozen docs/*.md игнорируются"

# ============================================================================
# T12: отсутствие jq/git — graceful exit (симулируем через empty command)
# ============================================================================
# Не можем легко мокнуть jq/git. Проверим что на broken JSON не падает.
OUT=$(printf '' | STATE_DIR="$STATE_DIR" bash "$SCRIPT" 2>/dev/null)
assert_empty "$OUT" "T12: empty input → empty output"

OUT=$(printf 'not-json' | STATE_DIR="$STATE_DIR" bash "$SCRIPT" 2>/dev/null)
assert_empty "$OUT" "T13: garbage input → empty output"

# ============================================================================
# T14: git commit в середине команды (compound) детектится
# ============================================================================
REPO14="$TMP/repo14"
new_repo "$REPO14"
echo "v1.4.0-alpha" >> "$REPO14/README.md"
git -C "$REPO14" add README.md
OUT=$(run_with "sid14" "$REPO14" "git add . && git commit -m x")
assert_contains "$OUT" "Docs family drift" "T14: compound command matches"

# ============================================================================
# T15: custom DOCS_FAMILY_LIST работает
# ============================================================================
REPO15="$TMP/repo15"
new_repo "$REPO15"
echo "v1.5.0" >> "$REPO15/README.md"
git -C "$REPO15" add README.md
payload=$(jq -cn \
    --arg sid "sid15" --arg cwd "$REPO15" --arg cmd "git commit -m x" \
    '{session_id: $sid, tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}')
OUT=$(printf '%s' "$payload" | \
    STATE_DIR="$STATE_DIR" DOCS_FAMILY_LIST="README.md CHANGELOG.md" \
    bash "$SCRIPT" 2>/dev/null)
assert_contains "$OUT" "CHANGELOG.md" "T15a: custom family — CHANGELOG в missing"
# PLAN.md не должен быть — не в custom list
echo "$OUT" | grep -Fq "PLAN.md" \
    && { FAIL=$((FAIL+1)); echo "FAIL [T15b]: PLAN.md появился в missing вне custom list"; } \
    || PASS=$((PASS+1))

# ============================================================================
# T16 (v1.6.2): DOCS_FAMILY_LIST расширяется на docs/*.md для проектов,
# которые хотят отслеживать конкретные docs/ файлы как live.
# ============================================================================
REPO16="$TMP/repo16"
new_repo "$REPO16"
echo "# Narrative" > "$REPO16/docs/narrative-design.md"
git -C "$REPO16" add docs/narrative-design.md
git -C "$REPO16" commit -q -m "add narrative design"
echo "v1.6.0" >> "$REPO16/README.md"
git -C "$REPO16" add README.md
payload16=$(jq -cn \
    --arg sid "sid16" --arg cwd "$REPO16" --arg cmd "git commit -m x" \
    '{session_id: $sid, tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}')
OUT=$(printf '%s' "$payload16" | \
    STATE_DIR="$STATE_DIR" DOCS_FAMILY_LIST="README.md docs/architecture.md docs/narrative-design.md" \
    bash "$SCRIPT" 2>/dev/null)
assert_contains "$OUT" "docs/narrative-design.md" "T16: custom DOCS_FAMILY_LIST ловит docs/narrative-design.md как live"

echo ""
echo "=================================="
echo "docs-family-check: $PASS passed, $FAIL failed"
echo "=================================="
[ "$FAIL" -eq 0 ]
