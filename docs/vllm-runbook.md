# vLLM GPU Backend Runbook

This runbook describes how to launch both the vLLM OpenAI-compatible server and the gateway on a single node with either NVIDIA (CUDA) or AMD (ROCm) GPUs using Docker Compose. The stack exposes a health endpoint and persists the Hugging Face cache to speed up subsequent runs.

## Prerequisites
- Docker Engine >= 24 with Compose V2
- GPU drivers installed on the host (NVIDIA or ROCm)
- At least one compatible GPU
- Network access to download models from Hugging Face on first start

Create a directory for the Hugging Face cache:

```bash
mkdir -p ./data/hf
```

## Launching the Services
The compose file defines two profiles. Choose the one matching your hardware and start the gateway alongside the appropriate vLLM container.

### NVIDIA / CUDA
```bash
docker compose -f vllm/compose.yaml --profile cuda up -d
```

### AMD / ROCm
```bash
docker compose -f vllm/compose.yaml --profile rocm up -d
```

On first launch Compose builds the vLLM service image from [`vllm/Dockerfile`](../vllm/Dockerfile), inheriting from the specified CUDA or ROCm base image.

Environment variables allow customization:

| Variable | Default | Description |
|----------|---------|-------------|
| `VLLM_MODEL` | `NousResearch/Meta-Llama-3-8B-Instruct` | Model repository to serve |
| `VLLM_PORT` | `8000` | vLLM host/container port |
| `GATEWAY_PORT` | `8080` | Gateway host port |
| `GPU_COUNT` | `1` | Number of GPUs to reserve |
| `VLLM_ARGS` | `` | Additional arguments passed to vLLM |
| `VLLM_IMAGE_CUDA` | `vllm/vllm-openai:v0.10.0` | CUDA base image |
| `VLLM_IMAGE_ROCM` | `vllm/vllm-openai-rocm:v0.10.0` | ROCm base image |

## Health Check
Verify the vLLM server is ready:

```bash
curl -sf http://localhost:${VLLM_PORT:-8000}/health
```

## Integration with the Gateway
`config/models.vllm.yaml` is mounted into the gateway container and already contains an entry pointing at the vLLM service:

```yaml
models:
  llama3-8b-instruct:
    backend: vllm
    backend_url: http://vllm-cuda:8000  # or vllm-rocm
```

Stream a response through the gateway:

```bash
curl -N -X POST http://localhost:${GATEWAY_PORT:-8080}/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"model": "llama3-8b-instruct", "messages": [{"role": "user", "content": "Hello"}]}'
```

A streaming response indicates the gateway is routing requests to vLLM successfully.

## Shutdown
```bash
docker compose -f vllm/compose.yaml down
```
