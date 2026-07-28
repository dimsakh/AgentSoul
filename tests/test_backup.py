from __future__ import annotations

import json
import zipfile

import pytest

from agentsoul_core.backup import create_backup, restore_backup
from agentsoul_core.hybrid import HybridStore
from agentsoul_core.knowledge import KnowledgeStore


def test_backup_round_trip(tmp_path):
    home = tmp_path / "home"
    hybrid = HybridStore(home)
    hybrid.add_note("Test", "Backup me", source="pytest")
    hybrid.upsert_entity("project", "AgentSoul", {"status": "active"})
    knowledge = KnowledgeStore(home)
    knowledge.capture(kind="pattern", title="Backups matter", summary="Verify before restore", confidence=4)

    archive = tmp_path / "backup.zip"
    created = create_backup(home, archive)
    assert created.file_count >= 2
    assert archive.is_file()

    restored_home = tmp_path / "restored"
    restored = restore_backup(archive, restored_home)
    assert restored.restored_files == created.file_count

    restored_hybrid = HybridStore(restored_home)
    found = restored_hybrid.search("Backup")
    assert found["notes"][0]["body"] == "Backup me"
    assert KnowledgeStore(restored_home).list_items()[0].title == "Backups matter"


def test_restore_rejects_nonempty_destination(tmp_path):
    home = tmp_path / "home"
    home.mkdir()
    (home / "value.txt").write_text("original", encoding="utf-8")
    archive = tmp_path / "backup.zip"
    create_backup(home, archive)

    destination = tmp_path / "destination"
    destination.mkdir()
    (destination / "keep.txt").write_text("keep", encoding="utf-8")
    with pytest.raises(FileExistsError):
        restore_backup(archive, destination)
    assert (destination / "keep.txt").read_text(encoding="utf-8") == "keep"


def test_restore_rejects_checksum_tampering(tmp_path):
    home = tmp_path / "home"
    home.mkdir()
    (home / "value.txt").write_text("original", encoding="utf-8")
    archive = tmp_path / "backup.zip"
    create_backup(home, archive)

    tampered = tmp_path / "tampered.zip"
    with zipfile.ZipFile(archive, "r") as source, zipfile.ZipFile(tampered, "w") as target:
        for member in source.infolist():
            payload = source.read(member.filename)
            if member.filename == "value.txt":
                payload = b"changed"
            target.writestr(member, payload)

    with pytest.raises(ValueError, match="checksum"):
        restore_backup(tampered, tmp_path / "restored")


def test_manifest_is_portable_json(tmp_path):
    home = tmp_path / "home"
    home.mkdir()
    (home / "unicode.txt").write_text("память", encoding="utf-8")
    archive = tmp_path / "backup.zip"
    create_backup(home, archive)
    with zipfile.ZipFile(archive) as bundle:
        manifest = json.loads(bundle.read("manifest.json"))
    assert manifest["format"] == "agentsoul-backup-v1"
    assert manifest["files"][0]["path"] == "unicode.txt"
