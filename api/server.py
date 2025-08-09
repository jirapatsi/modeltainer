import os
import json
import time
import logging
from typing import Any, Dict
from uuid import uuid4

import yaml
import httpx
from fastapi import FastAPI, HTTPException, Request, Depends, Header
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field

CONFIG_PATH = os.environ.get("MODELS_CONFIG", "config/models.yaml")

logger = logging.getLogger("gateway")
logging.basicConfig(level=logging.INFO, format='%(message)s')

app = FastAPI()


def load_config() -> Dict[str, Dict[str, Any]]:
    try:
        with open(CONFIG_PATH, 'r') as f:
            data = yaml.safe_load(f) or {}
        models = data.get('models', {})
        app.state.models = models
        return models
    except FileNotFoundError:
        app.state.models = {}
        return {}


@app.on_event("startup")
async def startup_event() -> None:
    load_config()
    limits = httpx.Limits(max_connections=100, max_keepalive_connections=20)
    transport = httpx.AsyncHTTPTransport(retries=3)
    timeout = httpx.Timeout(10.0)
    app.state.client = httpx.AsyncClient(timeout=timeout, limits=limits, transport=transport)


@app.on_event("shutdown")
async def shutdown_event() -> None:
    await app.state.client.aclose()


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatCompletionRequest(BaseModel):
    model: str
    messages: list[ChatMessage]
    stream: bool = False

    class Config:
        extra = "allow"


class CompletionRequest(BaseModel):
    model: str
    prompt: Any
    stream: bool = False

    class Config:
        extra = "allow"


class EmbeddingRequest(BaseModel):
    model: str
    input: Any

    class Config:
        extra = "allow"


def verify_api_key(authorization: str | None = Header(default=None)) -> None:
    api_key = os.environ.get("API_KEY")
    if api_key:
        if authorization is None or not authorization.startswith("Bearer "):
            raise HTTPException(status_code=401, detail="Missing token")
        token = authorization.split(" ", 1)[1]
        if token != api_key:
            raise HTTPException(status_code=401, detail="Invalid token")


def get_model_config(model: str) -> Dict[str, Any]:
    models = getattr(app.state, "models", {})
    if model not in models:
        suggestions = list(models.keys())
        raise HTTPException(status_code=404, detail={"error": "Unknown model", "suggestions": suggestions})
    return models[model]


async def proxy_request(path: str, payload: Dict[str, Any], stream: bool, model_cfg: Dict[str, Any], request: Request) -> StreamingResponse | JSONResponse:
    url = model_cfg["service_url"] + path
    headers = dict(request.headers)
    headers.pop("host", None)
    if stream:
        async def event_stream() -> Any:
            async with app.state.client.stream("POST", url, json=payload, headers=headers) as resp:
                async for chunk in resp.aiter_raw():
                    yield chunk
        return StreamingResponse(event_stream(), media_type="text/event-stream")
    resp = await app.state.client.post(url, json=payload, headers=headers)
    return JSONResponse(content=resp.json(), status_code=resp.status_code)


@app.middleware("http")
async def log_middleware(request: Request, call_next):
    start = time.time()
    trace_id = uuid4().hex
    model = "-"
    body_bytes = await request.body()
    if body_bytes:
        try:
            body_json = json.loads(body_bytes)
            model = body_json.get("model", "-")
        except Exception:
            pass
        request._body = body_bytes
    response = await call_next(request)
    latency = (time.time() - start) * 1000
    log = {
        "method": request.method,
        "path": request.url.path,
        "model": model,
        "status": response.status_code,
        "latency_ms": round(latency, 2),
        "trace_id": trace_id,
    }
    logger.info(json.dumps(log))
    return response


@app.get("/.well-known/health")
async def health() -> Dict[str, Any]:
    models = getattr(app.state, "models", {})
    return {"status": "ok", "models": list(models.keys())}


@app.post("/admin/reload")
async def admin_reload() -> Dict[str, str]:
    load_config()
    return {"status": "reloaded"}


@app.post("/v1/chat/completions")
async def chat_completions(req: ChatCompletionRequest, request: Request, _: None = Depends(verify_api_key)):
    model_cfg = get_model_config(req.model)
    return await proxy_request("/v1/chat/completions", req.model_dump(), req.stream, model_cfg, request)


@app.post("/v1/completions")
async def completions(req: CompletionRequest, request: Request, _: None = Depends(verify_api_key)):
    model_cfg = get_model_config(req.model)
    return await proxy_request("/v1/completions", req.model_dump(), req.stream, model_cfg, request)


@app.post("/v1/embeddings")
async def embeddings(req: EmbeddingRequest, request: Request, _: None = Depends(verify_api_key)):
    model_cfg = get_model_config(req.model)
    if not model_cfg.get("embeddings", False):
        raise HTTPException(status_code=400, detail="Model does not support embeddings")
    return await proxy_request("/v1/embeddings", req.model_dump(), False, model_cfg, request)
