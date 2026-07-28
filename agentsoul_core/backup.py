from __future__ import annotations

import hashlib
import json
import shutil
import sqlite3
import tempfile
import zipfile
from dataclasses import dataclass, asdict
from datetime import datetime, timezone
from pathlib import Path


BACKUP_FORMAT = "agentsoul-backup-v1"


def _utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


@dataclass(slots=True)
class BackupResult:
    archive: str
    created_at: str
    file_count: int
    total_bytes: int


@dataclass(slots=True)
class RestoreResult:
    archive: str
    destination: str
    restored_files: int
    replaced_existing: bool


def _snapshot_sqlite(source: Path, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    source_db = sqlite3.connect(source)
    target_db = sqlite3.connect(destination)
    try:
        source_db.backup(target_db)
    finally:
        target_db.close()
        source_db.close()


def create_backup(home: Path, destination: Path | None = None) -> BackupResult:
    home = Path(home).expanduser().resolve()
    home.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    destination = Path(destination or (home / "backups" / f"agentsoul-{timestamp}.zip")).expanduser().resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="agentsoul-backup-") as tmp:
        staging = Path(tmp) / "payload"
        staging.mkdir(parents=True)
        files: list[Path] = []
        for source in home.rglob("*"):
            if not source.is_file():
                continue
            if destination == source.resolve() or "backups" in source.relative_to(home).parts:
                continue
            relative = source.relative_to(home)
            target = staging / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            if source.name == "agentsoul.db":
                _snapshot_sqlite(source, target)
            elif source.suffix in {"-wal", "-shm"}:
                continue
            else:
                shutil.copy2(source, target)
            files.append(target)

        manifest_files = []
        total_bytes = 0
        for path in sorted(files):
            relative = path.relative_to(staging).as_posix()
            size = path.stat().st_size
            total_bytes += size
            manifest_files.append({"path": relative, "size": size, "sha256": _sha256(path)})
        manifest = {
            "format": BACKUP_FORMAT,
            "created_at": _utc_now(),
            "files": manifest_files,
        }
        manifest_path = staging / "manifest.json"
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

        temporary = destination.with_suffix(destination.suffix + ".tmp")
        with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(staging.rglob("*")):
                if path.is_file():
                    archive.write(path, path.relative_to(staging).as_posix())
        temporary.replace(destination)

    return BackupResult(str(destination), manifest["created_at"], len(manifest_files), total_bytes)


def _safe_member(name: str) -> bool:
    path = Path(name)
    return not path.is_absolute() and ".." not in path.parts and name not in {"", "."}


def restore_backup(archive_path: Path, destination: Path, *, replace: bool = False) -> RestoreResult:
    archive_path = Path(archive_path).expanduser().resolve()
    destination = Path(destination).expanduser().resolve()
    if not archive_path.is_file():
        raise FileNotFoundError(archive_path)

    with tempfile.TemporaryDirectory(prefix="agentsoul-restore-") as tmp:
        staging = Path(tmp) / "payload"
        staging.mkdir(parents=True)
        with zipfile.ZipFile(archive_path, "r") as archive:
            for member in archive.infolist():
                if not _safe_member(member.filename):
                    raise ValueError(f"unsafe backup path: {member.filename}")
                archive.extract(member, staging)

        manifest_path = staging / "manifest.json"
        if not manifest_path.is_file():
            raise ValueError("backup manifest is missing")
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if manifest.get("format") != BACKUP_FORMAT:
            raise ValueError("unsupported backup format")

        for entry in manifest.get("files", []):
            relative = entry.get("path", "")
            if not _safe_member(relative):
                raise ValueError(f"unsafe manifest path: {relative}")
            source = staging / relative
            if not source.is_file() or _sha256(source) != entry.get("sha256"):
                raise ValueError(f"backup checksum mismatch: {relative}")

        existing = destination.exists() and any(destination.iterdir())
        if existing and not replace:
            raise FileExistsError("destination is not empty; pass replace=True")
        if existing:
            shutil.rmtree(destination)
        destination.mkdir(parents=True, exist_ok=True)

        restored = 0
        for entry in manifest.get("files", []):
            source = staging / entry["path"]
            target = destination / entry["path"]
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, target)
            restored += 1

    return RestoreResult(str(archive_path), str(destination), restored, existing)
