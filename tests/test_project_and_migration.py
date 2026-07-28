from pathlib import Path

from agentsoul_core.migrate import migrate_claudsoul
from agentsoul_core.project import END, START, install_agents_block


def test_install_agents_block_preserves_existing_content(tmp_path: Path) -> None:
    agents = tmp_path / "AGENTS.md"
    agents.write_text("# Existing\n\nKeep this.\n", encoding="utf-8")

    path, changed = install_agents_block(tmp_path)
    assert path == agents
    assert changed is True
    text = agents.read_text(encoding="utf-8")
    assert "Keep this." in text
    assert text.count(START) == 1
    assert text.count(END) == 1

    _, changed_again = install_agents_block(tmp_path)
    assert changed_again is False


def test_migration_never_overwrites_conflicts(tmp_path: Path) -> None:
    source = tmp_path / "claudsoul"
    destination = tmp_path / "agentsoul"
    (source / "knowledge").mkdir(parents=True)
    original = source / "knowledge" / "case.md"
    original.write_text("first", encoding="utf-8")

    first = migrate_claudsoul(source, destination)
    assert first.copied == 1

    original.write_text("second", encoding="utf-8")
    second = migrate_claudsoul(source, destination)
    assert second.conflicts == 1
    target = destination / "imports" / "claudsoul" / "knowledge" / "case.md"
    assert target.read_text(encoding="utf-8") == "first"
    assert target.with_name("case.md.incoming").read_text(encoding="utf-8") == "second"
