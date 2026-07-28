from __future__ import annotations

from agentsoul_core.knowledge import KnowledgeStore
from agentsoul_core.session import SessionManager


def test_session_start_builds_context_and_finish_records_outcome(tmp_path):
    knowledge = KnowledgeStore(tmp_path)
    knowledge.capture(
        kind="pattern",
        title="Check rollback before deploy",
        summary="Verify a rollback path before production changes.",
        confidence=4,
        anchors={"domain": "deployment", "stakes": "data_loss"},
    )

    manager = SessionManager(tmp_path)
    record, context = manager.start(
        provider="codex",
        project_id="demo",
        query="deploy safely",
        anchors={"domain": "deployment", "stakes": "data_loss"},
        session_id="session-1",
    )

    assert record.session_id == "session-1"
    assert "Check rollback before deploy" in context
    assert manager.load("session-1").status == "active"

    completed = manager.finish("session-1", outcome="Deployment validated", success=True)
    assert completed.status == "completed"
    assert completed.outcome == "Deployment validated"
    assert completed.completed_at is not None

    events = list(manager.memory.iter_events(10))
    assert [event.event_type for event in events] == ["session.started", "session.completed"]
