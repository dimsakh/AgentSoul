# AgentSoul installation

## Requirements

- Python 3.11 or newer
- Git
- Windows PowerShell, or a POSIX shell on Linux/macOS

## Windows

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

For a per-user pip installation:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -User
```

## Linux and macOS

```bash
bash install-agentsoul.sh
```

The inherited `install.sh` remains the original Claude Code installer and is not used for the provider-neutral AgentSoul runtime.

## Connect a Codex project

```bash
agentsoul install-project /path/to/project
```

This command creates or updates only the managed AgentSoul block inside the project's `AGENTS.md`.

## Smoke test

```bash
agentsoul init
agentsoul session-start "verify AgentSoul installation" --provider codex --project smoke-test
```

The local memory root defaults to `~/.agentsoul/`. Do not commit this directory to a project repository.
