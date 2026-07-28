from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from typing import Any
import uuid


@dataclass(slots=True)
class AgentEvent:
    """Canonical provider-neutral event envelope."""

    event_type: str
    provider: str
    project_id: str
    payload: dict[str, Any] = field(default_factory=dict)
    session_id: str | None = None
    event_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "AgentEvent":
        required = {"event_type", "provider", "project_id"}
        missing = required.difference(data)
        if missing:
            raise ValueError(f"Missing required event fields: {sorted(missing)}")
        return cls(**data)
