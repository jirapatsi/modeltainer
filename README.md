# modeltainer
ModelTainer — One-command deploy for any LLM, anywhere. Run GPU (vLLM) or CPU/ARM (llama.cpp) models side-by-side via an OpenAI-compatible API. Hot-swap models with config only, scale from laptop to HPC, and compare outputs instantly.

## Quickstart
1. Clone and enter the repository:
   ```bash
   git clone https://example.com/modeltainer.git && cd modeltainer
   ```
2. Start the default services:
   ```bash
   make up
   ```
3. Send a test request through the gateway:
   ```bash
   curl -N -X POST http://localhost:8080/v1/chat/completions \
     -H 'Content-Type: application/json' \
     -d '{"model": "llama3-8b-instruct", "messages": [{"role": "user", "content": "Hello"}]}'
   ```
   A streaming response indicates the stack is ready.

### Notes
- First start downloads models into `./data/hf`.
- Stop the stack with `make down`.

## Default Models
The reference compose files ship with the following defaults:

- **GPU (vLLM):** `openai/gpt-oss-20b` in `mxfp4` precision.
- **CPU (llama.cpp):** `gemma-3-1b-it-Q4_K_M.gguf`.

Override these by setting `VLLM_MODEL` or `LLAMACPP_MODEL` when launching the services.

## Further Reading
- [Quickstart guide](docs/quickstart.md)
- [Model swap guide](docs/model-swap.md)
- [Troubleshooting tips](docs/troubleshooting.md)
- [Resource sizing cheatsheet](docs/resource-sizing.md)
- [A/B testing](docs/ab-testing.md)
- [Multi-model compose example](multi-models-concurrency/compose.yaml)
