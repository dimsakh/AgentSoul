from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Literal

KnowledgeKind = Literal["case", "pattern", "principle"]


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _slugify(value: str) -> str:
    slug = re.sub(r"[^a-zA-Z0-9а-яА-ЯёЁ]+", "-", value.strip().lower()).strip("-")
    return slug or "untitled"


@dataclass(slots=True)
class KnowledgeItem:
    knowledge_id: str
    kind: KnowledgeKind
    title: str
    summary: str
    confidence: int = 1
    status: str = "active"
    anchors: dict[str, Any] = field(default_factory=dict)
    evidence: list[str] = field(default_factory=list)
    confirmed_count: int = 0
    contradicted_count: int = 0
    contradictions: list[dict[str, Any]] = field(default_factory=list)
    created_at: str = field(default_factory=_utc_now)
    updated_at: str = field(default_factory=_utc_now)

    def validate(self) -> None:
        if self.kind not in {"case", "pattern", "principle"}:
            raise ValueError(f"Unsupported knowledge kind: {self.kind}")
        if not 1 <= self.confidence <= 5:
            raise ValueError("confidence must be between 1 and 5")
        if not self.title.strip() or not self.summary.strip():
            raise ValueError("title and summary are required")

    def to_dict(self) -> dict[str, Any]:
        self.validate()
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "KnowledgeItem":
        item = cls(**data)
        item.validate()
        return item


class KnowledgeStore:
    def __init__(self, home: Path):
        self.home = Path(home).expanduser().resolve()
        self.knowledge_root = self.home / "knowledge"

    def _path(self, kind: KnowledgeKind, knowledge_id: str) -> Path:
        return self.knowledge_root / f"{kind}s" / f"{knowledge_id}.json"

    def capture(
        self,
        *,
        kind: KnowledgeKind,
        title: str,
        summary: str,
        confidence: int = 1,
        anchors: dict[str, Any] | None = None,
        evidence: list[str] | None = None,
    ) -> KnowledgeItem:
        date = datetime.now(timezone.utc).date().isoformat()
        base_id = f"{kind}-{date}-{_slugify(title)}"
        knowledge_id = base_id
        counter = 2
        while self._path(kind, knowledge_id).exists():
            knowledge_id = f"{base_id}-{counter}"
            counter += 1
        item = KnowledgeItem(
            knowledge_id=knowledge_id,
            kind=kind,
            title=title.strip(),
            summary=summary.strip(),
            confidence=confidence,
            anchors=anchors or {},
            evidence=evidence or [],
        )
        self.save(item, create_only=True)
        return item

    def save(self, item: KnowledgeItem, *, create_only: bool = False) -> Path:
        item.validate()
        path = self._path(item.kind, item.knowledge_id)
        path.parent.mkdir(parents=True, exist_ok=True)
        if create_only and path.exists():
            raise FileExistsError(path)
        item.updated_at = _utc_now()
        temporary = path.with_suffix(".json.tmp")
        temporary.write_text(json.dumps(item.to_dict(), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        temporary.replace(path)
        return path

    def load(self, knowledge_id: str) -> KnowledgeItem:
        for kind in ("case", "pattern", "principle"):
            path = self._path(kind, knowledge_id)
            if path.exists():
                return KnowledgeItem.from_dict(json.loads(path.read_text(encoding="utf-8")))
        raise FileNotFoundError(knowledge_id)

    def delete(self, knowledge_id: str) -> bool:
        for kind in ("case", "pattern", "principle"):
            path = self._path(kind, knowledge_id)
            if path.exists():
                path.unlink()
                return True
        return False

    def confirm(self, knowledge_id: str, evidence: str | None = None) -> KnowledgeItem:
        item = self.load(knowledge_id)
        item.confirmed_count += 1
        item.confidence = min(5, item.confidence + 1)
        if evidence:
            item.evidence.append(evidence)
        item.status = "active"
        self.save(item)
        return item

    def contradict(self, knowledge_id: str, *, stated_value: str, evidence: str | None = None) -> KnowledgeItem:
        item = self.load(knowledge_id)
        item.contradicted_count += 1
        item.confidence = max(1, item.confidence - 1)
        item.contradictions.append({"stated_value": stated_value, "evidence": evidence, "recorded_at": _utc_now()})
        if item.contradicted_count > item.confirmed_count:
            item.status = "weakened"
        self.save(item)
        return item

    def list_items(self, kind: KnowledgeKind | None = None) -> list[KnowledgeItem]:
        kinds = (kind,) if kind else ("case", "pattern", "principle")
        items: list[KnowledgeItem] = []
        for current_kind in kinds:
            folder = self.knowledge_root / f"{current_kind}s"
            if not folder.exists():
                continue
            for path in sorted(folder.glob("*.json")):
                items.append(KnowledgeItem.from_dict(json.loads(path.read_text(encoding="utf-8"))))
        return sorted(items, key=lambda item: item.updated_at, reverse=True)
