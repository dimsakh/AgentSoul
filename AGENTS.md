# AgentSoul contributor instructions

## Mission

AgentSoul is a provider-neutral cognitive memory layer for coding and general-purpose AI agents. The shared memory model must remain independent from any single runtime. Claude Code, Codex, Hermes, and OpenAI-compatible agents connect through adapters.

## Architecture rules

1. Keep the canonical memory format runtime-neutral.
2. Runtime-specific behavior belongs under `adapters/<runtime>/`.
3. Do not write user secrets, tokens, transcripts, or private memory into the repository.
4. Any adapter must degrade gracefully when its runtime lacks a lifecycle event available in another runtime.
5. Preserve compatibility with the original ClaudSoul hierarchy: `case -> pattern -> principle`.
6. Treat hook payloads as untrusted input. Validate fields, paths, and command arguments.
7. Destructive actions require explicit user authorization.
8. Never overwrite existing instruction or imported memory files silently.
9. Modify project instruction files only inside explicit AgentSoul-managed markers.
10. Prefer documented runtime integration points over guessed lifecycle hooks.

## Initial supported runtimes

- `codex`
- `claude-code`
- `hermes`
- `openai-compatible`

## Current priorities

1. Stable event schema and append-only local store.
2. Safe managed-block installer for `AGENTS.md`.
3. Explicit Codex CLI workflow.
4. Non-destructive ClaudSoul migration.
5. Knowledge capture, retrieval, confidence, and contradiction lifecycle.
6. Claude Code and Hermes adapters.
7. Cross-provider tests and packaging.

## Development workflow

- Work in focused branches.
- Add or update documentation with behavior changes.
- Prefer portable Python for shared logic and thin shell or PowerShell launchers for platform integration.
- Support Windows and Linux first; retain macOS compatibility where inherited.
- Add tests for event normalization, memory-path resolution, managed-file updates, migration conflicts, and adapter fallback behavior.

## Definition of done

A change is complete only when:

- shared behavior is not coupled to one runtime;
- runtime-specific assumptions are documented;
- relevant tests pass;
- no secrets or personal memory are committed;
- migration impact from ClaudSoul is described.
