# AgentSoul porting roadmap

## Phase 0 — Foundation

- Add provider-neutral project instructions.
- Define the canonical runtime event envelope.
- Define adapter capabilities and fallback semantics.
- Establish `~/.agentsoul/` as the shared memory home.

## Phase 1 — Core extraction

- Identify logic currently embedded in Claude Code hooks.
- Move reusable parsing, recall, confidence, contradiction, and session logic into a Python core.
- Add schema validation and migration tests.

## Phase 2 — Codex adapter

- Detect Codex project and session context.
- Generate or update project `AGENTS.md` integration blocks.
- Add context-loading and session-saving commands.
- Use native Codex lifecycle integration where available.
- Provide wrapper/manual fallbacks where native events are unavailable.
- Support Windows and Linux.

## Phase 3 — Claude Code compatibility

- Wrap existing hooks with the canonical event envelope.
- Preserve current ClaudSoul behavior.
- Add compatibility tests against representative hook payloads.

## Phase 4 — Hermes adapter

- Integrate shared memory loading into Hermes startup and request flow.
- Normalize Hermes tool events where exposed.
- Add explicit session-save and recall commands.

## Phase 5 — OpenAI-compatible SDK

- Provide a small Python API for custom agents.
- Support context retrieval, event submission, lesson capture, and session finalization.
- Keep model-provider configuration outside the memory core.

## Phase 6 — Migration and packaging

- Add migration from `~/.claude`-based ClaudSoul installations.
- Add installers for PowerShell and POSIX shells.
- Add smoke tests and a redacted export/import workflow.
- Publish a compatibility matrix.

## Initial acceptance criteria

The first usable release should let the same knowledge base be used by Codex and Claude Code without duplication, while preserving personal memory outside the Git repository.
