from __future__ import annotations

from starlette.testclient import TestClient

from agentsoul_mcp.server import create_app


def test_health_is_public(monkeypatch, tmp_path):
    monkeypatch.setenv("AGENTSOUL_HOME", str(tmp_path / "memory"))
    monkeypatch.setenv("AGENTSOUL_API_TOKEN", "test-secret")
    with TestClient(create_app()) as client:
        response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["service"] == "agentsoul-mcp"


def test_mcp_requires_bearer_token(monkeypatch, tmp_path):
    monkeypatch.setenv("AGENTSOUL_HOME", str(tmp_path / "memory"))
    monkeypatch.setenv("AGENTSOUL_API_TOKEN", "test-secret")
    with TestClient(create_app()) as client:
        denied = client.get("/mcp")
        allowed = client.get("/mcp", headers={"Authorization": "Bearer test-secret"})
    assert denied.status_code == 401
    assert allowed.status_code != 401
