# ModelTainer Project Plan

## Vision
One command to deploy multiple LLM backends behind an OpenAI-compatible gateway. Supports vLLM on NVIDIA/AMD GPUs and llama.cpp on CPU/ARM with safe defaults, observability, and Slurm+Apptainer portability.

## Non-Goals
No training or full OpenAI platform clone; scope limited to `/v1/models`, `/v1/chat/completions` and streaming SSE.

## Architecture
```
[ Clients ] -> [ Gateway (FastAPI) ] -> [ vLLM | llama.cpp ]
```
`config/models.yaml` drives routing and hot reloads.

## Modules
### M1. API Gateway
- Endpoints: `/healthz`, `/v1/models`, `/v1/chat/completions`.
- Supports SSE streaming, Bearer auth, per-model routing, request timeouts/retries, JSON logs and OpenAI-compatible error schema.
- Deliverables: gateway app, Dockerfile, `openapi.json`, proxy snippets.
- Acceptance: curl/Python streaming through both backends.

### M2. Model Registry
- YAML schema for model name, backend URL, limits, optional env/headers.
- Hot reload with validation via Pydantic models.
- Deliverables: Pydantic schema, loader, tests, sample config & secrets env.
- Acceptance: editing the config file triggers live update; invalid configs are rejected.

### M3. vLLM Backend (GPU)
- Compose service for CUDA or ROCm with persistent HF cache and health checks.
- Deliverables: `compose.vllm.yaml`, runbook, multi-GPU notes.
- Acceptance: gateway streams to vLLM container locally.

### M4. llama.cpp Backend (CPU/ARM)
- `llama-server` or `llama_cpp.server` with sane defaults and GGUF mounts.
- Deliverables: `compose.llamacpp.yaml` and native runbook.
- Acceptance: two models on different ports listed via gateway.

### M5. Multi-Model Concurrency
- Gateway routes by model string; includes A/B comparison script.
- Acceptance: concurrent requests stream results from distinct models.

### M6. HPC Integration
- Slurm templates and Apptainer recipes with `--nv` and GPU selection.
- Acceptance: vLLM runs inside Slurm job; client reaches gateway via tunnel.

### M7. Security Baseline
- Bearer auth, per-key allow-lists, non-root/read-only containers, basic rate limits.
- Deliverables: `docs/security.md` and secure Compose defaults.
- Acceptance: unauthenticated requests rejected; vuln scans clean.

### M8. Observability
- Prometheus metrics, JSON logs, sample Grafana dashboards.
- Acceptance: `tools/bench.py` shows live QPS/latency.

### M9. CI/CD
- `pre-commit`, `mypy`, `pytest`, compose lint; GitHub Actions matrix and image publishing.
- Acceptance: CI passes before merge; images published on tag.

### M10. Benchmark Harness
- `tools/bench.py` sweeps concurrency and emits CSV/JSON (latency, tokens/sec).
- Acceptance: reproducible results for vLLM and llama.cpp.

### M11. Client Examples
- Python and curl snippets demonstrating streaming and model routing.
- Acceptance: examples run against both backends with one command.

### M12. Documentation
- Quickstart, model swap, troubleshooting, GPU sizing, HPC guide, security checklist.
- Acceptance: new user streams first token in <5 minutes via `docker compose up`.

## Example Config
```yaml
version: 1
models:
  - name: llama3-8b-instruct
    backend: vllm
    backend_url: http://vllm-1:8000
    format: chat_completions
  - name: q4-cpu-llama
    backend: llamacpp
    backend_url: http://llama-cpp-1:8080
    format: chat_completions
```

## Compose Excerpt
```yaml
services:
  gateway:
    build: ./gateway
    environment:
      - MT_CONFIG=/app/config/models.yaml
    ports: ["8081:8081"]
    depends_on: [vllm-1, llama-cpp-1]
    read_only: true
    user: "10001:10001"

  vllm-1:
    image: vllm/vllm-openai:latest
    command: --model NousResearch/Meta-Llama-3-8B-Instruct --port 8000
    volumes: [./data/hf:/data/hf]
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: [gpu]

  llama-cpp-1:
    image: ghcr.io/ggerganov/llama.cpp:server
    command: --model /models/llama3.q4_k_m.gguf --port 8080 --ctx-size 8192 --threads 8 --parallel 2
    volumes: [./models:/models]
```

## Done Criteria
1. `docker compose up` → `curl -N http://localhost:8081/v1/chat/completions` streams tokens.
2. Editing `config/models.yaml` hot-reloads routing with zero downtime.
3. `tools/bench.py` runs and emits `results.csv`.
