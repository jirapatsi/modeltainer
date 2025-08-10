# ModelTainer

ModelTainer delivers one‑command deployment for large language models on CPUs or GPUs. It exposes an OpenAI‑compatible API that can serve vLLM and llama.cpp models side‑by‑side, allowing you to hot‑swap models and compare results with minimal effort.

## Features

- **Unified API** – Interact with GPU (vLLM) and CPU/ARM (llama.cpp) models through the same endpoint.
- **Hot‑swappable models** – Change models via configuration only; no rebuilds required.
- **Portable** – Runs on a laptop or scales out to multi‑node clusters using Docker Compose.
- **Streaming responses** – Tokens stream as they are generated.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- Git

## Quickstart

1. Clone the repository and enter it:
   ```bash
   git clone https://github.com/sirirajgenomics/modeltainer
   cd modeltainer
   ```
2. Launch the default services:
   ```bash
   make up
   ```
3. Verify the stack with a chat completion request:
   ```bash
   curl -N -X POST http://localhost:8080/v1/chat/completions \
     -H 'Content-Type: application/json' \
     -d '{"model": "llama3-8b-instruct", "messages": [{"role": "user", "content": "Hello"}]}'
   ```
   A streaming response confirms everything is running.

### Configuration

- The first run downloads models into `./data/hf`.
- Override the defaults by setting `VLLM_MODEL` or `LLAMACPP_MODEL` before `make up`.
- Stop and remove the stack with `make down`.

## Documentation

- [Quickstart guide](docs/quickstart.md)
- [Model swap guide](docs/model-swap.md)
- [Resource sizing cheatsheet](docs/resource-sizing.md)
- [Troubleshooting tips](docs/troubleshooting.md)
- [A/B testing](docs/ab-testing.md)
- [Security considerations](docs/Security.md)
- [vLLM runbook](docs/vllm-runbook.md)
- [Multi-model compose example](multi-models-concurrency/compose.yaml)

## License

ModelTainer is licensed under the [Apache 2.0 License](LICENSE).

