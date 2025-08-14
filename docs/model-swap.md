# Model Swap Guide

Change which models are served without rebuilding containers.

## Swapping Models
ModelTainer reads model choices from environment variables at startup:

- **vLLM (GPU):** `VLLM_MODEL`
- **llama.cpp (CPU/ARM):** `LLAMACPP_MODEL`

Set them when launching the stack:

```bash
VLLM_MODEL="openai/gpt-4o-mini" LLAMACPP_MODEL="gpt-oss-20b-mxfp4.gguf" make up
```

The gateway automatically reloads its configuration and exposes both models via the `model` field.

## Adding Custom Configs
To register additional models or backends, edit files under `config/` and restart the relevant services.

## Notes
- Model repositories must be accessible from the host; supply a Hugging Face token for gated models.
- Changing `VLLM_MODEL` or `LLAMACPP_MODEL` triggers a fresh download into `./data/hf` if not cached.
- Ensure GPUs have enough VRAM for the selected vLLM model; see the [resource sizing cheatsheet](resource-sizing.md).
