from __future__ import annotations

import argparse
import json
from dataclasses import asdict
from pathlib import Path

from .events import AgentEvent
from .knowledge import KnowledgeStore
from .migrate import migrate_claudsoul
from .project import install_agents_block
from .retrieval import render_context, render_json, retrieve
from .session import SessionManager
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
    emit.add_argument("event_type"); emit.add_argument("--provider", required=True); emit.add_argument("--project", required=True)
    emit.add_argument("--session"); emit.add_argument("--payload", default="{}", help="JSON object")
    recent = sub.add_parser("recent", help="Print recent events"); recent.add_argument("--limit", type=int, default=20)
    capture = sub.add_parser("knowledge-capture", help="Capture a case, pattern, or principle")
    capture.add_argument("kind", choices=("case", "pattern", "principle")); capture.add_argument("title"); capture.add_argument("summary")
    capture.add_argument("--confidence", type=int, default=1); capture.add_argument("--anchors", default="{}", help="JSON object")
    capture.add_argument("--evidence", action="append", default=[])
    confirm = sub.add_parser("knowledge-confirm", help="Confirm a knowledge item and raise confidence")
    confirm.add_argument("knowledge_id"); confirm.add_argument("--evidence")
    contradict = sub.add_parser("knowledge-contradict", help="Record contradictory evidence")
    contradict.add_argument("knowledge_id"); contradict.add_argument("stated_value"); contradict.add_argument("--evidence")
    listing = sub.add_parser("knowledge-list", help="List knowledge items")
    listing.add_argument("--kind", choices=("case", "pattern", "principle")); listing.add_argument("--limit", type=int, default=20)
    search = sub.add_parser("knowledge-search", help="Retrieve relevant knowledge")
    search.add_argument("query"); search.add_argument("--anchors", default="{}", help="JSON object")
    search.add_argument("--limit", type=int, default=5); search.add_argument("--minimum-score", type=float, default=1.0)
    search.add_argument("--format", choices=("context", "json"), default="context"); search.add_argument("--max-chars", type=int, default=4000)
    start = sub.add_parser("session-start", help="Create a runtime session and print bounded memory context")
    start.add_argument("query"); start.add_argument("--provider", default="codex"); start.add_argument("--project", required=True)
    start.add_argument("--session"); start.add_argument("--anchors", default="{}", help="JSON object")
    start.add_argument("--limit", type=int, default=5); start.add_argument("--max-chars", type=int, default=4000)
    start.add_argument("--format", choices=("context", "json"), default="context")
    finish = sub.add_parser("session-finish", help="Record the outcome of a runtime session")
    finish.add_argument("session_id"); finish.add_argument("outcome")
    finish.add_argument("--success", choices=("true", "false", "unknown"), default="unknown")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    store = MemoryStore(args.home)
    if args.command == "init": print(store.initialise()); return 0
    if args.command == "install-project":
        path, changed = install_agents_block(args.path); print(json.dumps({"path": str(path), "changed": changed}, ensure_ascii=False)); return 0
    if args.command == "migrate-claudsoul":
        print(json.dumps(asdict(migrate_claudsoul(args.source, store.initialise())), ensure_ascii=False)); return 0
    if args.command == "emit":
        event = AgentEvent(event_type=args.event_type, provider=args.provider, project_id=args.project, session_id=args.session,
                           payload=_json_object(args.payload, "--payload")); store.append(event)
        print(json.dumps(event.to_dict(), ensure_ascii=False)); return 0
    if args.command == "recent":
        for event in store.iter_events(args.limit): print(json.dumps(event.to_dict(), ensure_ascii=False))
        return 0
    home = store.initialise(); knowledge = KnowledgeStore(home)
    if args.command == "knowledge-capture":
        item = knowledge.capture(kind=args.kind, title=args.title, summary=args.summary, confidence=args.confidence,
                                 anchors=_json_object(args.anchors, "--anchors"), evidence=args.evidence)
        print(json.dumps(item.to_dict(), ensure_ascii=False)); return 0
    if args.command == "knowledge-confirm": print(json.dumps(knowledge.confirm(args.knowledge_id, args.evidence).to_dict(), ensure_ascii=False)); return 0
    if args.command == "knowledge-contradict":
        item = knowledge.contradict(args.knowledge_id, stated_value=args.stated_value, evidence=args.evidence)
        print(json.dumps(item.to_dict(), ensure_ascii=False)); return 0
    if args.command == "knowledge-list":
        for item in knowledge.list_items(args.kind)[: args.limit]: print(json.dumps(item.to_dict(), ensure_ascii=False))
        return 0
    if args.command == "knowledge-search":
        results = retrieve(knowledge, query=args.query, anchors=_json_object(args.anchors, "--anchors"), limit=args.limit,
                           minimum_score=args.minimum_score)
        print(render_json(results) if args.format == "json" else render_context(results, max_chars=args.max_chars), end=""); return 0
    sessions = SessionManager(home)
    if args.command == "session-start":
        record, context = sessions.start(provider=args.provider, project_id=args.project, query=args.query,
                                         anchors=_json_object(args.anchors, "--anchors"), session_id=args.session,
                                         limit=args.limit, max_chars=args.max_chars)
        if args.format == "json": print(json.dumps({"session": asdict(record), "context": context}, ensure_ascii=False))
        else: print(f"<!-- agentsoul-session: {record.session_id} -->\n{context}", end="")
        return 0
    success = None if args.success == "unknown" else args.success == "true"
    print(json.dumps(asdict(sessions.finish(args.session_id, outcome=args.outcome, success=success)), ensure_ascii=False)); return 0


if __name__ == "__main__": raise SystemExit(main())
