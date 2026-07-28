from __future__ import annotations

import hashlib
import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class MigrationResult:
    copied: int = 0
    skipped: int = 0
    conflicts: int = 0


def _same_file(left: Path, right: Path) -> bool:
    def digest(path: Path) -> str:
        hasher = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                hasher.update(chunk)
        return hasher.hexdigest()

    return digest(left) == digest(right)


def migrate_claudsoul(source: Path, destination: Path) -> MigrationResult:
    """Copy portable Markdown/YAML/JSON knowledge without overwriting conflicts."""
    source = source.expanduser().resolve()
    destination = destination.expanduser().resolve()
    if not source.exists() or not source.is_dir():
        raise FileNotFoundError(f"ClaudSoul source not found: {source}")

    allowed_suffixes = {".md", ".yaml", ".yml", ".json", ".jsonl"}
    copied = skipped = conflicts = 0

    for item in source.rglob("*"):
        if not item.is_file() or item.suffix.lower() not in allowed_suffixes:
            continue
        relative = item.relative_to(source)
        target = destination / "imports" / "claudsoul" / relative
        target.parent.mkdir(parents=True, exist_ok=True)

        if target.exists():
            if _same_file(item, target):
                skipped += 1
            else:
                conflict = target.with_name(target.name + ".incoming")
                index = 1
                while conflict.exists():
                    conflict = target.with_name(target.name + f".incoming-{index}")
                    index += 1
                shutil.copy2(item, conflict)
                conflicts += 1
            continue

        shutil.copy2(item, target)
        copied += 1

    return MigrationResult(copied=copied, skipped=skipped, conflicts=conflicts)
