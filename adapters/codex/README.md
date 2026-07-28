# Codex adapter

This adapter maps Codex-visible lifecycle actions into AgentSoul's canonical event envelope.

## Current integration mode

Codex does not expose every Claude Code hook one-for-one. The first implementation therefore uses a portable wrapper contract:

1. initialise `~/.agentsoul/`;
2. inject a compact memory pointer through the project's `AGENTS.md`;
3. emit explicit session and task events through the AgentSoul CLI;
4. keep provider-specific state under `~/.agentsoul/state/codex/`.

## Event mapping

| Codex action | Canonical event |
|---|---|
| workspace opened | `session.started` |
| user task accepted | `prompt.received` |
| command/tool starts | `tool.before` |
| command/tool completes | `tool.after` |
| task summary saved | `session.checkpoint` |
| task finishes | `session.stopped` |

## Example

```bash
python -m agentsoul_core.cli init
python -m agentsoul_core.cli emit session.started \
  --provider codex \
  --project my-project \
  --payload '{"cwd":"/workspace/my-project"}'
```

The next implementation step is an installer that appends a managed AgentSoul section to project `AGENTS.md` without overwriting user instructions.
