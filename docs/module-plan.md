# Plan Overview

This document outlines the planned modules, associated tasks, and deliverables for ModelTainer.

## M1. API Gateway (OpenAI-compatible)
- **Tasks:** request/response schema, routing by model, streaming SSE proxy, retries/timeouts, structured logging, auth, health/reload.
- **Deliverables:** FastAPI service + Dockerfile + tests.

## M2. Model Registry & Routing Config
- **Tasks:** config/models.yaml schema, hot-reload, validation, friendly errors, example entries.
- **Deliverables:** YAML schema + loader + unit tests.

## M3. vLLM Backend (GPU)
- **Tasks:** Compose service, NVIDIA profile, HF cache volume, gated model token handling, basic perf flags, readiness/health.
- **Deliverables:** Compose service + runbook.

## M4. llama.cpp Backend (CPU/Edge/ARM)
- **Tasks:** Compose service, .gguf model mount, sane defaults, health, ARM notes.
- **Deliverables:** Compose service + runbook.

## M5. Multi-Model Concurrency
- **Tasks:** run multiple services on distinct ports; gateway routes by model string; docs for A/B comparison.
- **Deliverables:** Example: 2×vLLM + 1×llama.cpp concurrently.

## M6. HPC Integration (Slurm + Apptainer)
- **Tasks:** sbatch template, --nv, port exposure, node proxy notes, MIG/A100 partitioning.
- **Deliverables:** scripts/slurm/*.sbatch + guide.

## M7. Security Baseline
- **Tasks:** Bearer key, reverse proxy recommendations (TLS/rate-limit), resource caps/ulimits, non-root containers, read-only FS (where possible).
- **Deliverables:** Security doc + example proxy snippets.

## M8. Observability
- **Tasks:** structured logs, request IDs, latency/error counters, Prometheus endpoints (gateway), log guidance for backends.
- **Deliverables:** metrics in gateway + Loki/ELK-ready logs.

## M9. CI/CD & Quality Gates
- **Tasks:** pre-commit (ruff/black), mypy, pytest, Docker build, compose config lint, smoke test.
- **Deliverables:** .pre-commit-config.yaml, pyproject.toml, GitHub Actions.

## M10. Benchmark Harness
- **Tasks:** simple load/latency sampler, concurrency sweep, token throughput report, CSV/JSON output.
- **Deliverables:** tools/bench.py + example plots.

## M11. Client Examples
- **Tasks:** Python and curl examples targeting gateway only; shows model routing and streaming usage.
- **Deliverables:** examples/ snippets.

## M12. Documentation
- **Tasks:** quickstart, model swap instructions, troubleshooting, resource sizing cheat-sheet.
- **Deliverables:** README sections + docs.

