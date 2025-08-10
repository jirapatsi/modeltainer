import os
import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent.parent))

import asyncio

import httpx
import pytest
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
    assert "gpt-oss-20b-it" in body["models"]
    assert "gemma-3-1b-it" in body["models"]


def test_models_endpoint():
    load_config()
    resp = client.get("/v1/models", headers={"Authorization": "Bearer test"})
    assert resp.status_code == 200
    body = resp.json()
    ids = [m["id"] for m in body["data"]]
    assert "gpt-oss-20b-it" in ids and "gemma-3-1b-it" in ids


def test_auth_required():
    load_config()
    resp = client.get("/v1/models")
    assert resp.status_code == 401
    resp = client.get("/v1/models", headers={"Authorization": "Bearer wrong"})
    assert resp.status_code == 401


def test_unknown_model():
    payload = {"model": "unknown", "messages": [{"role": "user", "content": "hi"}]}
    resp = client.post("/v1/chat/completions", json=payload, headers={"Authorization": "Bearer test"})
    assert resp.status_code == 404
    body = resp.json()
    assert "suggestions" in body["error"]


def test_streaming_proxy():
    load_config()

    class Stream(httpx.AsyncByteStream):
        async def __aiter__(self):
            yield b"chunk1"
            yield b"chunk2"

        async def aclose(self) -> None:  # pragma: no cover - required by interface
            pass

    async def handler(request):
        return httpx.Response(200, stream=Stream())

    transport = httpx.MockTransport(handler)
    async_client = httpx.AsyncClient(transport=transport)
    app.state.client = async_client

    payload = {
        "model": "gpt-oss-20b-it",
        "messages": [{"role": "user", "content": "hi"}],
        "stream": True,
    }

    with client.stream("POST", "/v1/chat/completions", json=payload, headers={"Authorization": "Bearer test"}) as resp:
        data = b"".join(resp.iter_bytes())

    assert b"chunk1" in data and b"chunk2" in data
    asyncio.run(async_client.aclose())


def test_concurrent_models():
    load_config()

    async def handler(request):
        if "8000" in str(request.url):
            return httpx.Response(200, json={"model": "vllm"})
        if "8002" in str(request.url):
            return httpx.Response(200, json={"model": "llcpp"})
        return httpx.Response(500)

    transport = httpx.MockTransport(handler)
    async_client = httpx.AsyncClient(transport=transport)
    app.state.client = async_client

    payload_a = {"model": "gpt-oss-20b-it", "messages": [{"role": "user", "content": "hi"}]}
    payload_b = {"model": "gemma-3-1b-it", "messages": [{"role": "user", "content": "hi"}]}

    async def run():
        transport = httpx.ASGITransport(app=app)
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as async_test_client:
            resp_a, resp_b = await asyncio.gather(
                async_test_client.post("/v1/chat/completions", json=payload_a, headers={"Authorization": "Bearer test"}),
                async_test_client.post("/v1/chat/completions", json=payload_b, headers={"Authorization": "Bearer test"}),
            )
        assert resp_a.json()["model"] == "vllm"
        assert resp_b.json()["model"] == "llcpp"
        await async_client.aclose()

    asyncio.run(run())
