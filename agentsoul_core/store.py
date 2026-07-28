from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Iterable

from .events import AgentEvent


def default_home() -> Path:
    configured = os.environ.get("AGENTSOUL_HOME")
    return Path(configured).expanduser() if configured else Path.home() / ".agentsoul"


class MemoryStore:
    """Append-only local event store kept outside the Git repository."""

    def __init__(self, root: Path | None = None) -> None:
        self.root = (root or default_home()).expanduser().resolve()
        self.events_dir = self.root / "events"
        self.events_file = self.events_dir / "events.jsonl"

    def initialise(self) -> Path:
        for relative in ("events", "knowledge/cases", "knowledge/patterns", "knowledge/principles", "sessions", "profiles", "state"):
            (self.root / relative).mkdir(parents=True, exist_ok=True)
        self.events_file.touch(exist_ok=True)
        return self.root

    def append(self, event: AgentEvent) -> None:
        self.initialise()
        with self.events_file.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event.to_dict(), ensure_ascii=False) + "\n")

    def iter_events(self, limit: int | None = None) -> Iterable[AgentEvent]:
        if not self.events_file.exists():
            return []
        lines = self.events_file.read_text(encoding="utf-8").splitlines()
        if limit is not None:
            lines = lines[-limit:]
        return [AgentEvent.from_dict(json.loads(line)) for line in lines if line.strip()]
