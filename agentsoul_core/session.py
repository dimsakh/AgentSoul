from __future__ import annotations

import json
import uuid
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from .events import AgentEvent
from .knowledge import KnowledgeStore
from .retrieval import render_context, retrieve
from .store import MemoryStore


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass(slots=True)
class SessionRecord:
    session_id: str
    provider: str
    project_id: str
    query: str
    anchors: dict[str, Any]
    started_at: str
    status: str = "active"
    outcome: str | None = None
    completed_at: str | None = None


class SessionManager:
    def __init__(self, home: Path):
        self.home = Path(home).expanduser().resolve()
        self.memory = MemoryStore(self.home)
        self.knowledge = KnowledgeStore(self.home)
        self.sessions = self.home / "sessions"

    def start(self, *, provider: str, project_id: str, query: str, anchors: dict[str, Any] | None = None,
              session_id: str | None = None, limit: int = 5, max_chars: int = 4000) -> tuple[SessionRecord, str]:
        self.memory.initialise()
        self.sessions.mkdir(parents=True, exist_ok=True)
        record = SessionRecord(
            session_id=session_id or uuid.uuid4().hex,
            provider=provider,
            project_id=project_id,
            query=query,
            anchors=anchors or {},
            started_at=_utc_now(),
        )
        results = retrieve(self.knowledge, query=query, anchors=record.anchors, limit=limit)
        context = render_context(results, max_chars=max_chars)
        self._save(record)
        self.memory.append(AgentEvent(event_type="session.started", provider=provider, project_id=project_id,
                                      session_id=record.session_id, payload={"query": query, "anchors": record.anchors}))
        return record, context

    def finish(self, session_id: str, *, outcome: str, success: bool | None = None) -> SessionRecord:
        record = self.load(session_id)
        record.status = "completed"
        record.outcome = outcome.strip()
        record.completed_at = _utc_now()
        self._save(record)
        self.memory.append(AgentEvent(event_type="session.completed", provider=record.provider,
                                      project_id=record.project_id, session_id=record.session_id,
                                      payload={"outcome": record.outcome, "success": success}))
        return record

    def load(self, session_id: str) -> SessionRecord:
        path = self.sessions / f"{session_id}.json"
        if not path.exists():
            raise FileNotFoundError(session_id)
        return SessionRecord(**json.loads(path.read_text(encoding="utf-8")))

    def _save(self, record: SessionRecord) -> Path:
        path = self.sessions / f"{record.session_id}.json"
        temporary = path.with_suffix(".json.tmp")
        temporary.write_text(json.dumps(asdict(record), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temporary.replace(path)
        return path
