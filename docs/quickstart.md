# Quickstart

Bring up ModelTainer and serve an LLM behind an OpenAI-compatible API in minutes.

## Prerequisites
- Docker Engine \>= 24 with Compose V2
- Internet access for the first model download
- (Optional) [Hugging Face token](https://huggingface.co/settings/tokens) for gated models

## Steps
1. Clone the repository and change into the directory:
   ```bash
   git clone https://github.com/sirirajgenomics/modeltainer.git
   cd modeltainer
   ```
2. Start example backends so the gateway has models to proxy. These commands launch vLLM on a GPU and llama.cpp on the CPU:
   ```bash
   mkdir -p models
   huggingface-cli download unsloth/gemma-3-1b-it-GGUF --include "gemma-3-1b-it-Q4_K_M.gguf" --local-dir models

   docker compose -f vllm/compose.yaml --profile cuda up -d vllm-cuda
   docker compose -f llama.cpp/compose.yaml up -d llcpp
   ```
3. Bring up the gateway:
   ```bash
   make up
   ```
4. Verify the gateway is serving requests:
   ```bash
   curl -N -X POST http://localhost:8080/v1/chat/completions \
     -H 'Content-Type: application/json' \
     -d '{"model": "gpt-oss-20b-it", "messages": [{"role": "user", "content": "Hello"}]}'
   ```
   A streaming response confirms the stack is running.

For advanced options such as model selection or running multiple containers, see the [model swap guide](model-swap.md) and [A/B testing](ab-testing.md).

## Notes
- The first run downloads models into `./data/hf`, which can take several minutes.
- Run `make down` to stop all services.
- Default ports are 8080 for the gateway and 8000 for vLLM; adjust via environment variables if needed.
