from agentsoul_core.hybrid import HybridStore


def test_hybrid_notes_entities_and_links(tmp_path):
    store = HybridStore(tmp_path)
    db_path = store.initialise()
    assert db_path.exists()

    note = store.add_note(
        "AUSN payment",
        "Check payment purpose before classifying revenue.",
        source="chatgpt",
        metadata={"project": "tax"},
    )
    assert note.title == "AUSN payment"

    company = store.upsert_entity("company", "Areal", {"tax_mode": "AUSN"})
    updated = store.upsert_entity("company", "Areal", {"status": "active"})
    assert updated.entity_id == company.entity_id
    assert updated.attributes == {"tax_mode": "AUSN", "status": "active"}

    document = store.upsert_entity("document", "Payment statement")
    link = store.link(company.entity_id, "has_document", document.entity_id)
    assert link["predicate"] == "has_document"

    results = store.search("AUSN")
    assert results["notes"][0]["note_id"] == note.note_id
    assert results["entities"][0]["entity_id"] == company.entity_id


def test_hybrid_rejects_invalid_relationships(tmp_path):
    store = HybridStore(tmp_path)
    entity = store.upsert_entity("project", "AgentSoul")
    try:
        store.link(entity.entity_id, "depends_on", entity.entity_id)
    except ValueError as exc:
        assert "self-links" in str(exc)
    else:
        raise AssertionError("self-link must be rejected")
