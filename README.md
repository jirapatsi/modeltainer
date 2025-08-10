# ModelTainer

ModelTainer delivers one‑command deployment for large language models on CPUs or GPUs. It exposes an OpenAI‑compatible API that can serve vLLM and llama.cpp models side‑by‑side, allowing you to hot‑swap models and compare results with minimal effort.

## Features

- **Unified API** – Interact with GPU (vLLM) and CPU/ARM (llama.cpp) models through the same endpoint.
- **Hot‑swappable models** – Change models via configuration only; no rebuilds required.
- **Portable** – Runs on a laptop or scales out to multi‑node clusters using Docker Compose.
- **Streaming responses** – Tokens stream as they are generated.
- **Apptainer support** – Package models into transferable Apptainer images.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- Git

## Quickstart

1. Clone the repository and enter it:
   ```bash
   git clone https://github.com/sirirajgenomics/modeltainer
   cd modeltainer
   ```
2. Start your LLM backends (e.g., vLLM and llama.cpp) separately. They must expose endpoints matching the URLs in `config/models.yaml`.
3. Launch the gateway and supporting services:
   ```bash
   make up
   ```
   The `make` command prints the configured model backends before composing the Docker services.
4. Verify the stack with a chat completion request:
   ```bash
   curl -N -X POST http://localhost:8080/v1/chat/completions \
     -H 'Content-Type: application/json' \
     -d '{"model": "gpt-oss-20b-it", "messages": [{"role": "user", "content": "Hello"}]}'
   ```
   A streaming response confirms everything is running.

### Configuration

- Ensure your LLM containers serve the models referenced in `config/models.yaml`.
- The `make up` command prints the configured models so you can verify endpoints before startup.
- Stop and remove the gateway stack with `make down`.

## Documentation

- [Quickstart guide](docs/quickstart.md)
- [Model swap guide](docs/model-swap.md)
- [Resource sizing cheatsheet](docs/resource-sizing.md)
- [Troubleshooting tips](docs/troubleshooting.md)
- [A/B testing](docs/ab-testing.md)
- [Security considerations](docs/Security.md)
- [vLLM runbook](docs/vllm-runbook.md)
- [Multi-model compose example](multi-models-concurrency/compose.yaml)
- [Apptainer workflow](docs/apptainer.md)

## License

ModelTainer is licensed under the [Apache 2.0 License](LICENSE).

