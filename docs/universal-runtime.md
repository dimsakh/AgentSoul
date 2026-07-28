# Universal runtime architecture

## Goal

AgentSoul separates the cognitive memory model from the agent runtime. A single local memory store can be read and updated by Codex, Claude Code, Hermes, and custom OpenAI-compatible agents without converting the knowledge base for each tool.

## Components

### 1. Core

The core owns runtime-neutral behavior:

- memory item schema;
- case, pattern, and principle lifecycle;
- confidence and contradiction metadata;
- recall and promotion rules;
- safe path handling;
- import and export.

The core must not depend on `~/.claude`, `~/.codex`, or any provider-specific session format.

### 2. Event envelope

Adapters normalize native lifecycle events into one envelope:

```json
{
  "schema_version": "1.0",
  "runtime": "codex",
  "event": "session.start",
  "session_id": "runtime-provided-or-generated",
  "project_root": "/absolute/project/path",
  "timestamp": "RFC3339",
  "payload": {}
}
```

Initial canonical events:

- `session.start`
- `prompt.received`
- `tool.before`
- `tool.after`
- `context.compact.before`
- `session.stop`

An adapter may emulate an unavailable event or mark it unsupported. It must never claim an event was observed when it was inferred.

### 3. Runtime adapters

Each adapter contains:

- detection of its runtime;
- native-event parsing;
- canonical event mapping;
- context injection;
- session finalization;
- capability declaration.

Planned layout:

```text
adapters/
  codex/
  claude-code/
  hermes/
  openai-compatible/
```

### 4. Shared memory home

Default location:

```text
~/.agentsoul/
```

Suggested layout:

```text
~/.agentsoul/
  config.yaml
  knowledge/
    cases/
    patterns/
    principles/
  entities/
  sessions/
  indexes/
  logs/
  runtime-state/
```

The repository contains code and templates. Personal memory remains outside Git and is excluded from publication.

## Capability model

Adapters publish capabilities instead of relying on hard-coded runtime checks:

```yaml
runtime: codex
capabilities:
  session_start: true
  prompt_received: true
  tool_before: partial
  tool_after: partial
  pre_compact: false
  session_stop: partial
  native_commands: true
```

Core workflows use the capability declaration to choose native, emulated, or manual fallback paths.

## Compatibility strategy

The Claude Code adapter preserves existing ClaudSoul behavior as the reference implementation. Migration proceeds incrementally:

1. define the neutral event and memory contracts;
2. wrap existing Claude hooks with the contract;
3. add Codex integration with fallbacks for missing events;
4. add Hermes and generic OpenAI-compatible adapters;
5. move shared logic from hooks into the core;
6. retain compatibility shims until migration tests pass.

## Security boundaries

- Never commit personal memory, session transcripts, API keys, OAuth tokens, or runtime credentials.
- Treat hook and tool payloads as untrusted.
- Normalize and validate filesystem paths.
- Keep destructive-action guards independent of model/provider.
- Export archives must support redaction and an explicit manifest.
