from __future__ import annotations

import argparse
import json
from pathlib import Path

from .events import AgentEvent
from .store import MemoryStore


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="agentsoul")
    parser.add_argument("--home", type=Path, default=None)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("init", help="Create the local AgentSoul memory layout")

    emit = sub.add_parser("emit", help="Append a canonical event")
    emit.add_argument("event_type")
    emit.add_argument("--provider", required=True)
    emit.add_argument("--project", required=True)
    emit.add_argument("--session")
    emit.add_argument("--payload", default="{}", help="JSON object")

    recent = sub.add_parser("recent", help="Print recent events")
    recent.add_argument("--limit", type=int, default=20)
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    store = MemoryStore(args.home)

    if args.command == "init":
        print(store.initialise())
        return 0

    if args.command == "emit":
        payload = json.loads(args.payload)
        if not isinstance(payload, dict):
            raise SystemExit("--payload must be a JSON object")
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

    for event in store.iter_events(args.limit):
        print(json.dumps(event.to_dict(), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
