from pathlib import Path

from agentsoul_core.events import AgentEvent
from agentsoul_core.store import MemoryStore


def test_event_round_trip() -> None:
    event = AgentEvent(
        event_type="session.started",
        provider="codex",
        project_id="demo",
        payload={"cwd": "/tmp/demo"},
    )
    restored = AgentEvent.from_dict(event.to_dict())
    assert restored.to_dict() == event.to_dict()


def test_store_appends_and_reads(tmp_path: Path) -> None:
    store = MemoryStore(tmp_path / "brain")
    event = AgentEvent(
        event_type="prompt.received",
        provider="codex",
        project_id="demo",
        payload={"text": "hello"},
    )
    store.append(event)
    events = list(store.iter_events())
    assert len(events) == 1
    assert events[0].event_id == event.event_id
    assert (tmp_path / "brain" / "events" / "events.jsonl").exists()
