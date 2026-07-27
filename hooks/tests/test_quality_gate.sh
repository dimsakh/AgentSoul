#!/usr/bin/env bash
# test_quality_gate.sh — quality-gate-check.sh coverage.
# Изоляция через STATE_DIR + tmp git repo per test.

set -uo pipefail

HOOKS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$HOOKS_DIR/quality-gate-check.sh"

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

# --- Setup helper: tmp git repo with skills/ tree ---
new_repo() {
    local repo="$1"
    rm -rf "$repo"
    mkdir -p "$repo/skills/demo"
    git -C "$repo" init -q 2>/dev/null
    git -C "$repo" config user.email "t@e"
    git -C "$repo" config user.name "t"
    echo "# Seed" > "$repo/README.md"
    git -C "$repo" add README.md >/dev/null 2>&1
    git -C "$repo" commit -q -m "seed" 2>/dev/null
}

# Write a SKILL.md with a DoD section; $2 = "complete" | "incomplete" | "no_dod"
write_skill() {
    local path="$1" mode="$2"
    mkdir -p "$(dirname "$path")"
    case "$mode" in
        complete)
            cat > "$path" <<'EOF'
---
name: demo
description: "demo"
---

# Demo

**Type:** worker

## Step 1
Do stuff.

## Definition of Done

- [x] First criterion met
- [x] Second criterion met
- [x] Third criterion met

**Version:** 1.0.0
**Last Updated:** 2026-04-23
EOF
            ;;
        incomplete)
            cat > "$path" <<'EOF'
---
name: demo
description: "demo"
---

# Demo

**Type:** worker

## Step 1
Do stuff.

## Definition of Done

- [x] First criterion met
- [ ] Second criterion NOT met
- [ ] Third criterion NOT met

**Version:** 1.0.0
**Last Updated:** 2026-04-23
EOF
            ;;
        no_dod)
            cat > "$path" <<'EOF'
---
name: demo
description: "demo"
---

# Demo

**Type:** worker

## Step 1
Do stuff.

**Version:** 1.0.0
EOF
            ;;
    esac
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
# T3: git commit но staged пуст → skip (R3 guard — no SKILL.md touched)
# ============================================================================
OUT=$(run_with "sid3" "$REPO" "git commit -m test")
assert_empty "$OUT" "T3: git commit без staged → skip"

# ============================================================================
# T4: staged docs-only (не SKILL.md) → skip (R3 guard)
# ============================================================================
echo "more" >> "$REPO/README.md"
git -C "$REPO" add README.md
OUT=$(run_with "sid4" "$REPO" "git commit -m docs")
assert_empty "$OUT" "T4: staged docs-only без SKILL.md → skip (R3 guard)"
git -C "$REPO" reset -q HEAD
git -C "$REPO" checkout -q -- .

# ============================================================================
# T5: staged SKILL.md с полным DoD → skip (все чекбоксы ✅)
# ============================================================================
write_skill "$REPO/skills/demo/SKILL.md" complete
git -C "$REPO" add skills/demo/SKILL.md
OUT=$(run_with "sid5" "$REPO" "git commit -m 'add demo skill'")
assert_empty "$OUT" "T5: complete DoD → skip"
git -C "$REPO" reset -q HEAD
git -C "$REPO" checkout -q -- . 2>/dev/null || true
rm -rf "$REPO/skills/demo"

# ============================================================================
# T6: staged SKILL.md с incomplete DoD → fire
# ============================================================================
write_skill "$REPO/skills/demo/SKILL.md" incomplete
git -C "$REPO" add skills/demo/SKILL.md
OUT=$(run_with "sid6" "$REPO" "git commit -m 'add demo skill'")
assert_contains "$OUT" "Quality-gate" "T6a: incomplete DoD → fire"
assert_contains "$OUT" "skills/demo/SKILL.md" "T6b: incomplete skill path в inject"
assert_contains "$OUT" "unchecked" "T6c: unchecked count в inject"

# ============================================================================
# T7: per-session dedup — тот же incomplete-set → skip
# ============================================================================
OUT=$(run_with "sid6" "$REPO" "git commit -m 'retry'")
assert_empty "$OUT" "T7: same session same incomplete → dedup"

# ============================================================================
# T8: другая сессия — fire снова
# ============================================================================
OUT=$(run_with "sid8" "$REPO" "git commit -m 'retry in new session'")
assert_contains "$OUT" "Quality-gate" "T8: cross-session independence"

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
OUT=$(run_with "sid10" "$REPO" "git commit -m demo")
echo "$OUT" | jq -e '.hookSpecificOutput.hookEventName == "PreToolUse"' >/dev/null 2>&1 \
    && { PASS=$((PASS+1)); } \
    || { FAIL=$((FAIL+1)); echo "FAIL [T10]: invalid JSON or wrong hookEventName: $OUT"; }

# ============================================================================
# T11: несколько SKILL.md — оба incomplete → оба в inject
# ============================================================================
REPO11="$TMP/repo11"
new_repo "$REPO11"
write_skill "$REPO11/skills/alpha/SKILL.md" incomplete
write_skill "$REPO11/skills/beta/SKILL.md" incomplete
git -C "$REPO11" add skills/alpha/SKILL.md skills/beta/SKILL.md
OUT=$(run_with "sid11" "$REPO11" "git commit -m 'add two skills'")
assert_contains "$OUT" "skills/alpha/SKILL.md" "T11a: alpha в inject"
assert_contains "$OUT" "skills/beta/SKILL.md" "T11b: beta в inject"

# ============================================================================
# T12: один complete, один incomplete → только incomplete в inject
# ============================================================================
REPO12="$TMP/repo12"
new_repo "$REPO12"
write_skill "$REPO12/skills/good/SKILL.md" complete
write_skill "$REPO12/skills/bad/SKILL.md" incomplete
git -C "$REPO12" add skills/good/SKILL.md skills/bad/SKILL.md
OUT=$(run_with "sid12" "$REPO12" "git commit -m 'mixed'")
assert_contains "$OUT" "skills/bad/SKILL.md" "T12a: incomplete bad в inject"
echo "$OUT" | grep -Fq "skills/good/SKILL.md" \
    && { FAIL=$((FAIL+1)); echo "FAIL [T12b]: good SKILL.md попал в inject"; } \
    || PASS=$((PASS+1))

# ============================================================================
# T13: SKILL.md без DoD секции → skip (нечего проверять)
# ============================================================================
REPO13="$TMP/repo13"
new_repo "$REPO13"
write_skill "$REPO13/skills/nodod/SKILL.md" no_dod
git -C "$REPO13" add skills/nodod/SKILL.md
OUT=$(run_with "sid13" "$REPO13" "git commit -m 'no dod skill'")
assert_empty "$OUT" "T13: SKILL.md без DoD → skip"

# ============================================================================
# T14: git commit в compound команде → детектится
# ============================================================================
REPO14="$TMP/repo14"
new_repo "$REPO14"
write_skill "$REPO14/skills/comp/SKILL.md" incomplete
git -C "$REPO14" add skills/comp/SKILL.md
OUT=$(run_with "sid14" "$REPO14" "git add . && git commit -m x")
assert_contains "$OUT" "Quality-gate" "T14: compound command matches"

# ============================================================================
# T15: empty/garbage input → silent
# ============================================================================
OUT=$(printf '' | STATE_DIR="$STATE_DIR" bash "$SCRIPT" 2>/dev/null)
assert_empty "$OUT" "T15a: empty input → empty output"

OUT=$(printf 'not-json' | STATE_DIR="$STATE_DIR" bash "$SCRIPT" 2>/dev/null)
assert_empty "$OUT" "T15b: garbage input → empty output"

# ============================================================================
# T16: только не-SKILL.md staged (например skills/demo/references/checks.md) → skip
# ============================================================================
REPO16="$TMP/repo16"
new_repo "$REPO16"
mkdir -p "$REPO16/skills/demo/references"
echo "# Checks" > "$REPO16/skills/demo/references/checks.md"
git -C "$REPO16" add skills/demo/references/checks.md
OUT=$(run_with "sid16" "$REPO16" "git commit -m 'update checks'")
assert_empty "$OUT" "T16: skills/*/references/*.md без SKILL.md → skip"

# ============================================================================
# T17: count-of-unchecked отображается (3 unchecked для incomplete)
# ============================================================================
REPO17="$TMP/repo17"
new_repo "$REPO17"
mkdir -p "$REPO17/skills/triple"
cat > "$REPO17/skills/triple/SKILL.md" <<'EOF'
---
name: triple
---

## Definition of Done

- [ ] One
- [ ] Two
- [ ] Three
EOF
git -C "$REPO17" add skills/triple/SKILL.md
OUT=$(run_with "sid17" "$REPO17" "git commit -m triple")
assert_contains "$OUT" "3 unchecked" "T17: unchecked count = 3"

echo ""
echo "=================================="
echo "quality-gate-check: $PASS passed, $FAIL failed"
echo "=================================="
[ "$FAIL" -eq 0 ]
