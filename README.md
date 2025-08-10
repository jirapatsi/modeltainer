# modeltainer
ModelTainer — One-command deploy for any LLM, anywhere. Run GPU (vLLM) or CPU/ARM (llama.cpp) models side-by-side via an OpenAI-compatible API. Hot-swap models with config only, scale from laptop to HPC, and compare outputs instantly.

See [docs/ab-testing.md](docs/ab-testing.md) for running multiple models concurrently and A/B testing via the `model` field.

The [multi-models-concurrency/compose.yaml](multi-models-concurrency/compose.yaml) example spins up two vLLM instances and a llama.cpp service alongside the gateway.
