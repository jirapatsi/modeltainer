# modeltainer
ModelTainer — One-command deploy for any LLM, anywhere. Run GPU (vLLM) or CPU/ARM (llama.cpp) models side-by-side via an OpenAI-compatible API. Hot-swap models with config only, scale from laptop to HPC, and compare outputs instantly.

See [docs/ab-testing.md](docs/ab-testing.md) for running multiple models concurrently and A/B testing via the `model` field.

The [multi-models-concurrency/compose.yaml](multi-models-concurrency/compose.yaml) example spins up two vLLM instances and a llama.cpp service alongside the gateway.

## Default Models

The reference compose files ship with the following defaults:

- **GPU (vLLM):** `openai/gpt-oss-20b` in `mxfp4` precision.
- **CPU (llama.cpp):** `gemma-3-1b-it-Q4_K_M.gguf`.

Override these by setting `VLLM_MODEL` or `LLAMACPP_MODEL` when launching the services.
