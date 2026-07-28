from __future__ import annotations

import json
import sqlite3
import uuid
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


@dataclass(slots=True)
class Note:
    note_id: str
    title: str
    body: str
    source: str | None
    metadata: dict[str, Any]
    created_at: str
    updated_at: str


@dataclass(slots=True)
class Entity:
    entity_id: str
    entity_type: str
    name: str
    attributes: dict[str, Any]
    created_at: str
    updated_at: str


class HybridStore:
    """SQLite-backed notes, entities, and typed relationships.

    The store is intentionally dependency-free and suitable for small VPS hosts.
    Existing JSON knowledge remains supported by KnowledgeStore; this database adds
    structured growth without forcing an immediate migration.
    """

    def __init__(self, home: Path):
        self.home = Path(home).expanduser().resolve()
        self.db_path = self.home / "agentsoul.db"

    def initialise(self) -> Path:
        self.home.mkdir(parents=True, exist_ok=True)
        with self._connect() as db:
            db.executescript(
                """
                PRAGMA journal_mode=WAL;
                PRAGMA foreign_keys=ON;
                CREATE TABLE IF NOT EXISTS notes (
                    note_id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    body TEXT NOT NULL,
                    source TEXT,
                    metadata_json TEXT NOT NULL DEFAULT '{}',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS entities (
                    entity_id TEXT PRIMARY KEY,
                    entity_type TEXT NOT NULL,
                    name TEXT NOT NULL,
                    attributes_json TEXT NOT NULL DEFAULT '{}',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    UNIQUE(entity_type, name)
                );
                CREATE TABLE IF NOT EXISTS links (
                    link_id TEXT PRIMARY KEY,
                    subject_id TEXT NOT NULL,
                    predicate TEXT NOT NULL,
                    object_id TEXT NOT NULL,
                    metadata_json TEXT NOT NULL DEFAULT '{}',
                    created_at TEXT NOT NULL,
                    UNIQUE(subject_id, predicate, object_id)
                );
                CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updated_at DESC);
                CREATE INDEX IF NOT EXISTS idx_entities_name ON entities(name);
                CREATE INDEX IF NOT EXISTS idx_links_subject ON links(subject_id);
                CREATE INDEX IF NOT EXISTS idx_links_object ON links(object_id);
                """
            )
        return self.db_path

    def _connect(self) -> sqlite3.Connection:
        self.home.mkdir(parents=True, exist_ok=True)
        db = sqlite3.connect(self.db_path)
        db.row_factory = sqlite3.Row
        return db

    def add_note(self, title: str, body: str, *, source: str | None = None,
                 metadata: dict[str, Any] | None = None) -> Note:
        if not title.strip() or not body.strip():
            raise ValueError("title and body are required")
        self.initialise()
        timestamp = _now()
        note = Note(uuid.uuid4().hex, title.strip(), body.strip(), source,
                    metadata or {}, timestamp, timestamp)
        with self._connect() as db:
            db.execute(
                "INSERT INTO notes VALUES (?, ?, ?, ?, ?, ?, ?)",
                (note.note_id, note.title, note.body, note.source,
                 json.dumps(note.metadata, ensure_ascii=False), note.created_at, note.updated_at),
            )
        return note

    def upsert_entity(self, entity_type: str, name: str,
                      attributes: dict[str, Any] | None = None) -> Entity:
        if not entity_type.strip() or not name.strip():
            raise ValueError("entity_type and name are required")
        self.initialise()
        timestamp = _now()
        with self._connect() as db:
            row = db.execute(
                "SELECT * FROM entities WHERE entity_type=? AND name=?",
                (entity_type.strip(), name.strip()),
            ).fetchone()
            if row:
                merged = json.loads(row["attributes_json"])
                merged.update(attributes or {})
                db.execute(
                    "UPDATE entities SET attributes_json=?, updated_at=? WHERE entity_id=?",
                    (json.dumps(merged, ensure_ascii=False), timestamp, row["entity_id"]),
                )
                return Entity(row["entity_id"], row["entity_type"], row["name"], merged,
                              row["created_at"], timestamp)
            entity = Entity(uuid.uuid4().hex, entity_type.strip(), name.strip(),
                            attributes or {}, timestamp, timestamp)
            db.execute(
                "INSERT INTO entities VALUES (?, ?, ?, ?, ?, ?)",
                (entity.entity_id, entity.entity_type, entity.name,
                 json.dumps(entity.attributes, ensure_ascii=False), entity.created_at, entity.updated_at),
            )
            return entity

    def link(self, subject_id: str, predicate: str, object_id: str,
             metadata: dict[str, Any] | None = None) -> dict[str, Any]:
        if subject_id == object_id:
            raise ValueError("self-links are not allowed")
        if not predicate.strip():
            raise ValueError("predicate is required")
        self.initialise()
        link_id = uuid.uuid4().hex
        created_at = _now()
        with self._connect() as db:
            db.execute(
                "INSERT OR IGNORE INTO links VALUES (?, ?, ?, ?, ?, ?)",
                (link_id, subject_id, predicate.strip(), object_id,
                 json.dumps(metadata or {}, ensure_ascii=False), created_at),
            )
            row = db.execute(
                "SELECT * FROM links WHERE subject_id=? AND predicate=? AND object_id=?",
                (subject_id, predicate.strip(), object_id),
            ).fetchone()
        return {
            "link_id": row["link_id"], "subject_id": row["subject_id"],
            "predicate": row["predicate"], "object_id": row["object_id"],
            "metadata": json.loads(row["metadata_json"]), "created_at": row["created_at"],
        }

    def search(self, query: str, *, limit: int = 20) -> dict[str, list[dict[str, Any]]]:
        self.initialise()
        pattern = f"%{query.strip()}%"
        with self._connect() as db:
            notes = db.execute(
                "SELECT * FROM notes WHERE title LIKE ? OR body LIKE ? ORDER BY updated_at DESC LIMIT ?",
                (pattern, pattern, max(1, min(limit, 100))),
            ).fetchall()
            entities = db.execute(
                "SELECT * FROM entities WHERE name LIKE ? OR attributes_json LIKE ? ORDER BY updated_at DESC LIMIT ?",
                (pattern, pattern, max(1, min(limit, 100))),
            ).fetchall()
        return {
            "notes": [asdict(Note(r["note_id"], r["title"], r["body"], r["source"],
                                  json.loads(r["metadata_json"]), r["created_at"], r["updated_at"])) for r in notes],
            "entities": [asdict(Entity(r["entity_id"], r["entity_type"], r["name"],
                                        json.loads(r["attributes_json"]), r["created_at"], r["updated_at"])) for r in entities],
        }
