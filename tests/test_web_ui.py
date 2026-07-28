from __future__ import annotations

from starlette.testclient import TestClient


def test_web_ui_and_crud_api(tmp_path, monkeypatch):
    monkeypatch.setenv("AGENTSOUL_HOME", str(tmp_path))
    monkeypatch.setenv("AGENTSOUL_API_TOKEN", "secret")

    from agentsoul_mcp.server import create_app

    with TestClient(create_app()) as client:
        page = client.get("/ui")
        assert page.status_code == 200
        assert "AgentSoul" in page.text

        assert client.get("/api/snapshot").status_code == 401
        headers = {"Authorization": "Bearer secret"}

        note = client.post(
            "/api/notes",
            headers=headers,
            json={"title": "Meeting", "body": "Decision recorded", "source": "chat"},
        )
        assert note.status_code == 201
        note_id = note.json()["data"]["note_id"]

        company = client.post(
            "/api/entities",
            headers=headers,
            json={"entity_type": "company", "name": "Areal", "attributes": {"status": "active"}},
        ).json()["data"]
        project = client.post(
            "/api/entities",
            headers=headers,
            json={"entity_type": "project", "name": "AgentSoul"},
        ).json()["data"]

        link = client.post(
            "/api/links",
            headers=headers,
            json={"subject_id": company["entity_id"], "predicate": "uses", "object_id": project["entity_id"]},
        )
        assert link.status_code == 201

        knowledge = client.post(
            "/api/knowledge",
            headers=headers,
            json={"kind": "pattern", "title": "Preserve evidence", "summary": "Keep source lineage", "confidence": 3},
        )
        assert knowledge.status_code == 201

        snapshot = client.get("/api/snapshot", headers=headers).json()["data"]
        assert len(snapshot["notes"]) == 1
        assert len(snapshot["entities"]) == 2
        assert len(snapshot["links"]) == 1
        assert len(snapshot["knowledge"]) == 1

        found = client.get("/api/search?q=Decision", headers=headers).json()["data"]
        assert found["notes"][0]["note_id"] == note_id

        deleted = client.delete(f"/api/notes/{note_id}", headers=headers)
        assert deleted.json()["data"]["deleted"] is True
