from __future__ import annotations

from pathlib import Path

START = "<!-- agentsoul:start -->"
END = "<!-- agentsoul:end -->"

MANAGED_BLOCK = f"""{START}
## AgentSoul integration

This project uses AgentSoul as a provider-neutral external memory layer.

- Before substantial work, read relevant project context and recent AgentSoul events.
- Record durable corrections, failures, decisions, and reusable lessons through the `agentsoul` CLI.
- Never commit personal memory, transcripts, credentials, or `~/.agentsoul/` contents.
- Treat repository instructions outside this managed block as authoritative and preserve them unchanged.

Useful commands:

```bash
agentsoul init
agentsoul recent --limit 20
agentsoul emit decision --provider codex --project <project-id> --payload '{{"summary":"..."}}'
```
{END}
"""


def install_agents_block(project_dir: Path) -> tuple[Path, bool]:
    """Create or update only the AgentSoul-managed section in AGENTS.md."""
    project_dir = project_dir.expanduser().resolve()
    path = project_dir / "AGENTS.md"
    current = path.read_text(encoding="utf-8") if path.exists() else ""

    if START in current or END in current:
        if current.count(START) != 1 or current.count(END) != 1:
            raise ValueError("AGENTS.md contains malformed AgentSoul markers")
        start = current.index(START)
        end = current.index(END) + len(END)
        updated = current[:start] + MANAGED_BLOCK.rstrip() + current[end:]
    else:
        separator = "\n\n" if current.strip() else ""
        updated = current.rstrip() + separator + MANAGED_BLOCK.rstrip() + "\n"

    changed = updated != current
    if changed:
        path.write_text(updated, encoding="utf-8")
    return path, changed
