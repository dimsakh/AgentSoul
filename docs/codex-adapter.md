# Codex adapter

The Codex adapter is deliberately thin. AgentSoul owns memory, retrieval, session state, and event persistence; Codex only receives a bounded context block and reports the outcome.

## Project installation

```bash
agentsoul init
agentsoul install-project /path/to/project
```

The installer updates only the managed AgentSoul section in `AGENTS.md`. Existing project instructions remain untouched.

## Start a session

```bash
agentsoul session-start "repair the failed deployment" \
  --provider codex \
  --project my-project \
  --anchors '{"domain":"deployment","situation":"incident","stakes":"data_loss"}'
```

The command:

1. creates a persistent session record under `~/.agentsoul/sessions/`;
2. retrieves relevant cases, patterns, and principles;
3. emits `session.started` into the canonical event log;
4. prints a bounded Markdown context block with the session identifier.

The returned memory is advisory and cannot override system, developer, user, repository, or current task instructions.

## Finish a session

```bash
agentsoul session-finish SESSION_ID "Rollback verified and deployment completed" --success true
```

This marks the session completed and emits `session.completed`. Outcomes are stored as session history; they are not automatically promoted into knowledge. Promotion remains explicit so an unverified agent conclusion cannot silently become a durable rule.

## Current integration level

Codex does not need a proprietary hook API for this first implementation. The adapter works through CLI entry points and the managed `AGENTS.md` contract. A later launcher can call `session-start` and `session-finish` automatically around Codex execution without changing the shared memory format.
