import os
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))

from fastapi.testclient import TestClient

from api.server import app, load_config

os.environ["API_KEY"] = "test"

client = TestClient(app)


def test_health():
    load_config()
    resp = client.get("/healthz")
    assert resp.status_code == 200
    body = resp.json()
    assert body["status"] == "ok"
    assert "test-model" in body["models"]


def test_models_endpoint():
    load_config()
    resp = client.get("/v1/models")
    assert resp.status_code == 200
    body = resp.json()
    ids = [m["id"] for m in body["data"]]
    assert "test-model" in ids


def test_unknown_model():
    payload = {"model": "unknown", "messages": [{"role": "user", "content": "hi"}]}
    resp = client.post("/v1/chat/completions", json=payload, headers={"Authorization": "Bearer test"})
    assert resp.status_code == 404
    body = resp.json()
    assert "suggestions" in body["error"]
