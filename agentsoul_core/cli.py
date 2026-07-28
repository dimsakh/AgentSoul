from __future__ import annotations

import argparse
import json
from pathlib import Path

from .events import AgentEvent
from .knowledge import KnowledgeStore
from .migrate import migrate_claudsoul
from .project import install_agents_block
from .store import MemoryStore


def _json_object(value: str, option: str) -> dict:
    parsed = json.loads(value)
    if not isinstance(parsed, dict):
        raise SystemExit(f"{option} must be a JSON object")
    return parsed


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="agentsoul")
    parser.add_argument("--home", type=Path, default=None)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init", help="Create the local AgentSoul memory layout")

    install = sub.add_parser("install-project", help="Add/update the managed AgentSoul block in AGENTS.md")
    install.add_argument("path", nargs="?", type=Path, default=Path.cwd())

    migrate = sub.add_parser("migrate-claudsoul", help="Import portable ClaudSoul memory files")
    migrate.add_argument("source", type=Path)

    emit = sub.add_parser("emit", help="Append a canonical event")
    emit.add_argument("event_type")
    emit.add_argument("--provider", required=True)
    emit.add_argument("--project", required=True)
    emit.add_argument("--session")
    emit.add_argument("--payload", default="{}", help="JSON object")

    recent = sub.add_parser("recent", help="Print recent events")
    recent.add_argument("--limit", type=int, default=20)

    capture = sub.add_parser("knowledge-capture", help="Capture a case, pattern, or principle")
    capture.add_argument("kind", choices=("case", "pattern", "principle"))
    capture.add_argument("title")
    capture.add_argument("summary")
    capture.add_argument("--confidence", type=int, default=1)
    capture.add_argument("--anchors", default="{}", help="JSON object")
    capture.add_argument("--evidence", action="append", default=[])

    confirm = sub.add_parser("knowledge-confirm", help="Confirm a knowledge item and raise confidence")
    confirm.add_argument("knowledge_id")
    confirm.add_argument("--evidence")

    contradict = sub.add_parser("knowledge-contradict", help="Record contradictory evidence")
    contradict.add_argument("knowledge_id")
    contradict.add_argument("stated_value")
    contradict.add_argument("--evidence")

    listing = sub.add_parser("knowledge-list", help="List knowledge items")
    listing.add_argument("--kind", choices=("case", "pattern", "principle"))
    listing.add_argument("--limit", type=int, default=20)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    store = MemoryStore(args.home)

    if args.command == "init":
        print(store.initialise())
        return 0

    if args.command == "install-project":
        path, changed = install_agents_block(args.path)
        print(json.dumps({"path": str(path), "changed": changed}, ensure_ascii=False))
        return 0

    if args.command == "migrate-claudsoul":
        destination = store.initialise()
        result = migrate_claudsoul(args.source, destination)
        print(json.dumps(result.__dict__, ensure_ascii=False))
        return 0

    if args.command == "emit":
        payload = _json_object(args.payload, "--payload")
        event = AgentEvent(
            event_type=args.event_type,
            provider=args.provider,
            project_id=args.project,
            session_id=args.session,
            payload=payload,
        )
        store.append(event)
        print(json.dumps(event.to_dict(), ensure_ascii=False))
        return 0

    if args.command == "recent":
        for event in store.iter_events(args.limit):
            print(json.dumps(event.to_dict(), ensure_ascii=False))
        return 0

    home = store.initialise()
    knowledge = KnowledgeStore(home)

    if args.command == "knowledge-capture":
        item = knowledge.capture(
            kind=args.kind,
            title=args.title,
            summary=args.summary,
            confidence=args.confidence,
            anchors=_json_object(args.anchors, "--anchors"),
            evidence=args.evidence,
        )
        print(json.dumps(item.to_dict(), ensure_ascii=False))
        return 0

    if args.command == "knowledge-confirm":
        item = knowledge.confirm(args.knowledge_id, args.evidence)
        print(json.dumps(item.to_dict(), ensure_ascii=False))
        return 0

    if args.command == "knowledge-contradict":
        item = knowledge.contradict(args.knowledge_id, stated_value=args.stated_value, evidence=args.evidence)
        print(json.dumps(item.to_dict(), ensure_ascii=False))
        return 0

    for item in knowledge.list_items(args.kind)[: args.limit]:
        print(json.dumps(item.to_dict(), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
