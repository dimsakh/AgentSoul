from pathlib import Path

from agentsoul_core.knowledge import KnowledgeStore


def test_capture_confirm_and_contradict(tmp_path: Path) -> None:
    store = KnowledgeStore(tmp_path)
    item = store.capture(
        kind="case",
        title="Preserve project instructions",
        summary="Managed blocks must not overwrite user-authored AGENTS.md content.",
        anchors={"domain": "tooling", "trigger": "install"},
        evidence=["installer design"],
    )

    assert item.confidence == 1
    assert item.status == "active"
    assert (tmp_path / "knowledge" / "cases" / f"{item.knowledge_id}.json").exists()

    confirmed = store.confirm(item.knowledge_id, "second successful installation")
    assert confirmed.confidence == 2
    assert confirmed.confirmed_count == 1
    assert "second successful installation" in confirmed.evidence

    contradicted = store.contradict(
        item.knowledge_id,
        stated_value="The runtime rewrites the entire file",
        evidence="legacy adapter behavior",
    )
    assert contradicted.confidence == 1
    assert contradicted.contradicted_count == 1
    assert contradicted.status == "active"
    assert contradicted.contradictions[0]["stated_value"] == "The runtime rewrites the entire file"


def test_more_contradictions_weaken_item(tmp_path: Path) -> None:
    store = KnowledgeStore(tmp_path)
    item = store.capture(kind="pattern", title="Example", summary="Example pattern", confidence=3)

    weakened = store.contradict(item.knowledge_id, stated_value="Counterexample")
    assert weakened.status == "weakened"
    assert weakened.confidence == 2


def test_duplicate_titles_get_unique_ids(tmp_path: Path) -> None:
    store = KnowledgeStore(tmp_path)
    first = store.capture(kind="case", title="Same title", summary="First")
    second = store.capture(kind="case", title="Same title", summary="Second")

    assert first.knowledge_id != second.knowledge_id
    assert second.knowledge_id.endswith("-2")
