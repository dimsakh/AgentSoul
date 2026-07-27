# ClaudSoul — Cognitive Model for an AI Agent

> Not a tool. Not a plugin. **An architecture of mind**, turning Claude Code into a self-learning partner.

**Current version:** [v1.11.1](CHANGELOG.md) — 2026-07-27 — 37 active hooks, 21 skills, 16 inter-layer bridges, 27 domain nodes — tests green. See [PLAN.md](PLAN.md) for the roadmap.

[🇷🇺 Русская версия: README.ru.md](README.ru.md)

## The Idea

People don't store knowledge in a table. They **remember** — through associations, emotions, context. Knowledge intertwines, reinforces itself, fades when unused. A failure on a Friday evening is remembered not as a log line but as an **image**: stress, a client call, a midnight hotfix.

ClaudSoul builds a comparable system for an AI agent — not a database, but a **cognitive model**.

## Research framing

ClaudSoul started as a tool for self-learning agents, but the mechanisms it required to work — confidence-weighted memory, explicit contradiction logging, forced reformulation before action, source-check before claims — overlap with problems the AI safety community is calling "honest reasoning" and "self-correction": getting an agent to recognize when its model is wrong and update it, rather than confabulating fluently.

What this system contributes to that direction:

- **Knowledge with confidence and contradiction lineage.** Every knowledge item has a confidence (1-5) that grows with confirmations and decays through forgetting. When new evidence contradicts a known rule, the rule isn't silently overwritten — both values are preserved (`contradiction.stated_value`), the agent surfaces the conflict, and the user decides which is current.
- **Constructive disagreement protocol.** When agent action contradicts a knowledge item with confidence ≥ 4, the system requires the agent to voice the concern before acting. Outcome (action worked / didn't) is logged, feeding back into confidence revision.
- **Reformulation tracker.** Every "let me make sure I understand X" reformulation is treated as a forward prediction and verified against the user's next message. Misalignment is logged as a gap (literal / pragmatic / strategic) — patterns of misalignment are studied, not papered over.
- **Output language check.** First hook on the agent's own output. Detects when the model violates its own stated rules (in this case, alphabet mixing within a single token). Closes a class of "agent-blind-to-own-output" errors.
- **Affect prosthetics (AP1/AP2/AP3).** Where biological agents have emotional brakes (hesitation before destructive actions, attention spike during interlocutor distress, accumulation of unspoken concerns) — transformer agents architecturally don't. ClaudSoul implements three engineering protheses for these functions: `trust-guard` (refuses destructive shell commands without explicit user authorization), `distressed` state axis (downgrades intervention budget when the user signals frustration), `silence-debt surfacing` (carries unspoken-but-high-value concerns across sessions).

This is not a solution to honest reasoning — it is an experimental scaffold for studying which engineering interventions reduce agent confabulation and self-contradiction in long-running tasks. Issues and PRs aimed at that direction are particularly welcome.

📄 Deeper read on the affect prosthetics direction: [docs/research/affect-prosthetics.md](docs/research/affect-prosthetics.md).

## Key principles

- **Knowledge ≠ rules.** Rules describe normative behaviour. Knowledge captures lived experience: what happened, why, what to do next time.
- **Confidence as memory weight.** Every knowledge item has a confidence (1–5) that grows with confirmations, decays through FSRS-style forgetting, and shrinks under contradictions.
- **Anchors > tags.** A knowledge item is recalled by 9 contextual anchors (domain, situation, trigger, stakes, actors, environment, circumstances, purpose, method) — not by topic tags. Anchors describe context the way a human recognises it.
- **Three-tier hierarchy.** `case → pattern → principle` with explicit promotion rules. Cases are concrete incidents (confidence 1). Patterns emerge from 2+ similar cases (confidence 2+). Principles are domain-agnostic rules from patterns (confidence 3+).
- **Cross-domain transfer.** A pattern noticed in one domain (e.g. shell scripting) can be activated in another (e.g. document editing) when its trigger or situation matches.

## 7-layer architecture

| # | Layer | Question it answers |
|---|-------|---------------------|
| 1 | Persistence | What did we do, when, where? (SESSION.md, CLAUDE.md, global-lessons, memory, git) |
| 2 | Knowledge | What rule/case/principle applies here? |
| 3 | Communication | What does the interlocutor actually need? |
| 4 | Thought trajectory | Where is the conversation heading? |
| 5 | Meta-cognition | Are we learning correctly? |
| 6 | Prediction | What hypothesis — and is it worth voicing now? |
| 7 | Co-cognition | Are we thinking together, or am I performing? |

Layers 1–6 are implemented; layer 7 is observed in practice but not formalized.

## 9 context anchors

Every knowledge item carries a YAML frontmatter with these anchors. They describe the situation rather than the topic, which is what makes context-aware recall possible.

| Anchor | Examples |
|--------|----------|
| `domain` | `shell`, `negotiation`, `cognitive_science` |
| `situation` | `deploy`, `negotiation`, `research`, `incident` |
| `trigger` | `error`, `deadline`, `contradiction`, `silence` |
| `stakes` | `data_loss`, `deal_loss`, `trust_erosion` |
| `actors` | `system`, `client`, `team`, `regulator` |
| `environment` | `multi_session`, `production`, `ci_cd`, `local_dev` |
| `circumstances` | `no_rollback`, `armed`, `team_unavailable` |
| `purpose` | `hotfix`, `new_feature`, `escape`, `learning` |
| `method` | `ci_cd`, `manual_scp`, `bare_hands`, `automated` |

## Alive learning system

### Hooks — automatic triggers

Hooks are shell scripts wired into Claude Code lifecycle events. They detect, inject, and log without manual intervention.

| Hook | Event | Role |
|------|-------|------|
| `error-tracker` | PostToolUse | Detects 2+ consecutive Bash failures + struggle signature + recurrence warning |
| `knowledge-activator` | PreToolUse / SessionStart | Injects relevant knowledge + cross-domain analogies + ПУНКТ 0 reminder |
| `session-collector` | Stop | Finalises the session in the registry, flushes activity log |
| `reformulation-tracker` | UserPromptSubmit | Detects FORWARD/PROPOSAL/BACKWARD prediction-verification triggers |
| `itr-event-detector` | UserPromptSubmit | Auto-collects gentle/proactive intervention outcomes from the transcript |
| `intrusiveness-tracker` | UserPromptSubmit | 4D gate state (`confidence × value × cost × state`) + state classifier |
| `bash-cost-detector` | PreToolUse:Bash | Detects destructive commands (`rm -rf`, `git reset --hard`, etc.) and computes cost 0–5 |
| `blocker-tier-check` | PreToolUse | Silent pre-action signal when confirmed knowledge contradicts the planned action |
| `pre-compact-finalizer` | PreCompact | Snapshots intrusiveness digest at every compaction (compaction ≠ session end) |
| `trust-guard` | PreToolUse:Bash | First affect prosthetic (AP1): destructive command without explicit user authorization → silent reminder |
| `output-language-check` | Stop / UserPromptSubmit / PreCompact / PreToolUse | First hook on agent's own output — detects Latin/Cyrillic mixing inside a single token |
| `claudsoul-context-pointer` | UserPromptSubmit | Injects project status when a session is opened from outside the project tree but the user asks about ClaudSoul |
| `docs-family-check` | PreToolUse:Bash | When committing with a version marker, ensures the 5 family docs (architecture, PLAN, README, CHANGELOG, project CLAUDE.md) are staged |
| `enrich-suggester` | UserPromptSubmit | Detects sparse entities (<3 attributes) in a 10-minute window after `/ingest` and recommends `/enrich` |
| `decompose-detector` | UserPromptSubmit | Detects multi-step prompts (≥4 step signals) and suggests `/decompose` |
| `quality-gate-check` | PreToolUse:Bash | Pre-commit check: SKILL.md with unfinished Definition of Done items in staged diff |
| `skill-review-check` | PreToolUse:Bash | Pre-commit contract integrity: 11 checks per staged SKILL.md |
| `auto-scanner` | launchd (every 4h) | Read-only scan of registered projects |
| `knowledge-audit-digest` | launchd (Sun 03:15) | Weekly digest of knowledge base health |
| `bridge-health-digest` | launchd (1st 03:30) | Monthly inter-layer bridge health digest |
| `session-start` | SessionStart | Startup context: deltas, parallel sessions, install drift detector, AP3 silence-debt carry-over |

### Skills — manual tools

Skills are user-invocable workflows installed in `~/.claude/commands/`.

| Skill | Purpose |
|-------|---------|
| `/learn` | Quick lesson capture (auto-detects: error / success / communication) |
| `/retro` | Deep post-mortem with confidence weights and edge linking |
| `/knowledge` | L2 knowledge coordinator — routes to capture, audit, or query workflows |
| `/pipeline` | L1 orchestrator — 5-phase task execution |
| `/decompose` | Pre-execution decomposition for tasks > 3 steps |
| `/quality-gate` | Definition-of-Done check before marking work complete |
| `/skill-forge` | Build a new skill from research + design + implementation |
| `/skill-review` | Audit SKILL.md contract integrity |
| `/knowledge-audit` | Health metrics + reliability + decay |
| `/bridge-health` | Inter-layer bridge audit |
| `/init-project` | Initialise a new project (CLAUDE.md, SESSION.md, .claude-docs/) |
| `/save` | Save session progress to SESSION.md |
| `/reload` | Re-read knowledge base and context without restart |
| `/ingest` | Add a document/URL/image to the knowledge base (entity contour) |
| `/entity` | Inspect what the system knows about an entity |
| `/wiki` | Render a narrative page for an entity |
| `/enrich` | Web-search to enrich a sparse entity |
| `/release` | Bump version + sync CHANGELOG + git tag |

### Autonomous learning

A `launchd` agent scans registered projects every 4 hours: stale branches, uncommitted changes, recurring patterns. Read-only — no edits, no commits. Findings land in `memory/scan-findings.md` and surface at session start.

## Knowledge lifecycle

1. **Capture.** A user correction, a failed attempt, a smoothly completed task → `/learn` writes a `case-YYYY-MM-DD-<slug>.md`.
2. **Activation.** On the next relevant action, `knowledge-activator.sh` matches anchors and injects the case as agent context.
3. **Confirmation.** Each successful application bumps `confirmed_count`.
4. **Promotion.** 2+ similar cases → manual or automatic promotion to a `pattern-*`. 2+ patterns matching cross-domain → promotion to a `principle-*`.
5. **Decay.** FSRS-style: `last_confirmed` ages, score drops, status flips `active → weakened → deprecated`.
6. **Contradiction.** A new case contradicts the rule → `contradicted_count++`. If `contradicted > confirmed`, the rule is `deprecated` or `branched` into a more specific subtype.

## MCP server

Semantic search and visualisation via [Model Context Protocol](https://modelcontextprotocol.io/).

### 9 tools

| Tool | Purpose |
|------|---------|
| `search_knowledge` | Semantic search across the knowledge base (sqlite-vec + fastembed) |
| `reindex_knowledge` | Reindex all knowledge files |
| `knowledge_stats` | Statistics: types, confidence, health |
| `get_knowledge` | Read a specific knowledge file |
| `knowledge_graph` | Export the knowledge graph as JSON |
| `open_graph` | Open the visualisation in a browser |
| `open_dashboard` | Open the metrics dashboard |
| `brain_export` | Export the entire brain as a `tar.gz` archive |
| `brain_import` | Import a brain archive with smart merge |

### Visualisation

- **2D D3.js** force-directed graph (stable)
- **3D Universe** (v1.2.0): type metaphors (principle = star, pattern = planet, case = asteroid, entity = nebula), domain gravity, per-domain nebulae with shader-based falloff
- **Metrics dashboard** (D3.js, 7 widgets, cosmic style)

### Portability

- macOS / Linux first-class (BSD and GNU coreutils handled)
- Bash + `jq` + Python 3.12+ + `uv` (optional, enables MCP)
- Zero-infrastructure: no database, no daemon, no network beyond optional GitHub backup

## Installation

```bash
git clone https://github.com/Nugnii/ClaudSoul.git
cd ClaudSoul
./install.sh
```

`install.sh` checks for `jq`, `python3`, `git` (required) and `uv` (optional, for MCP). Missing dependencies → fail-fast with platform-specific install commands. After install, `scripts/smoke-test.sh` validates the deployment in 7 categories.

## License

[MIT](LICENSE).

## Author

Kanstantsin Berseneu — [@Nugnii](https://github.com/Nugnii). Contributions, issues, and discussions are welcome via GitHub.
