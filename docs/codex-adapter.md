# Codex adapter

AgentSoul integrates with Codex through repository instructions and a provider-neutral local event store. It does not assume undocumented Codex lifecycle hooks.

## Project installation

After installing the Python package, run from the project directory:

```bash
agentsoul init
agentsoul install-project .
```

`install-project` creates or updates only the block between:

```text
<!-- agentsoul:start -->
<!-- agentsoul:end -->
```

Any existing text outside those markers is preserved. A malformed or duplicated marker pair causes a hard failure rather than destructive rewriting.

## Initial event mapping

| Codex activity | Canonical AgentSoul event |
|---|---|
| Project opened / task begins | `session.started` |
| User correction | `knowledge.corrected` |
| Durable decision | `decision` |
| Command or tool failure | `tool.failed` |
| Work completed | `session.completed` |

Events can be recorded explicitly:

```bash
agentsoul emit decision \
  --provider codex \
  --project my-project \
  --payload '{"summary":"Use SQLite for the local MVP"}'
```

## Reading memory

```bash
agentsoul recent --limit 20
```

The first adapter is intentionally explicit and auditable. Automatic capture will be added only where Codex exposes a stable, documented integration point.

## Migrating ClaudSoul memory

```bash
agentsoul migrate-claudsoul ~/.claude
```

Only portable Markdown, YAML, JSON, and JSONL files are copied into `~/.agentsoul/imports/claudsoul/`. Existing files are never overwritten. Conflicting incoming files receive an `.incoming` suffix for manual review.
