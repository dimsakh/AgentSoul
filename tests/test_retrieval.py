from agentsoul_core.knowledge import KnowledgeStore
from agentsoul_core.retrieval import rank_item, render_context, retrieve


def test_anchor_matches_rank_above_text_only(tmp_path):
    store = KnowledgeStore(tmp_path)
    contextual = store.capture(
        kind="pattern",
        title="Confirm destructive actions",
        summary="Ask before irreversible shell operations.",
        confidence=4,
        anchors={"domain": "shell", "stakes": "data_loss", "trigger": "destructive_command"},
    )
    generic = store.capture(
        kind="principle",
        title="Confirm actions",
        summary="Ask before important operations.",
        confidence=4,
        anchors={"domain": "communication"},
    )

    results = retrieve(
        store,
        query="delete files",
        anchors={"domain": "shell", "stakes": "data_loss"},
        limit=2,
    )

    assert results[0].item.knowledge_id == contextual.knowledge_id
    assert set(results[0].matched_anchors) == {"domain", "stakes"}
    assert results[0].score > rank_item(generic, "delete files", {"domain": "shell"}).score


def test_deprecated_items_are_not_returned(tmp_path):
    store = KnowledgeStore(tmp_path)
    item = store.capture(kind="case", title="Old rule", summary="Legacy behavior", confidence=5)
    item.status = "deprecated"
    store.save(item)
    assert retrieve(store, query="legacy behavior") == []


def test_context_renderer_obeys_budget(tmp_path):
    store = KnowledgeStore(tmp_path)
    for index in range(5):
        store.capture(
            kind="case",
            title=f"Case {index}",
            summary="Relevant summary " * 20,
            confidence=3,
            anchors={"domain": "python"},
        )
    context = render_context(retrieve(store, query="summary", anchors={"domain": "python"}), max_chars=350)
    assert len(context) <= 350
    assert context.startswith("## AgentSoul relevant memory")
