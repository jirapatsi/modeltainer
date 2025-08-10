# Quickstart

Bring up ModelTainer and serve an LLM behind an OpenAI-compatible API in minutes.

## Prerequisites
- Docker Engine \>= 24 with Compose V2
- Internet access for the first model download
- (Optional) [Hugging Face token](https://huggingface.co/settings/tokens) for gated models

## Steps
1. Clone the repository and change into the directory:
   ```bash
   git clone https://example.com/modeltainer.git && cd modeltainer
   ```
2. Start the default vLLM and llama.cpp services:
   ```bash
   make up
   ```
3. Verify the gateway is serving requests:
   ```bash
   curl -N -X POST http://localhost:8080/v1/chat/completions \
     -H 'Content-Type: application/json' \
     -d '{"model": "llama3-8b-instruct", "messages": [{"role": "user", "content": "Hello"}]}'
   ```
   A streaming response confirms the stack is running.

For advanced options such as model selection or multi-model setups, see the [model swap guide](model-swap.md) and [A/B testing](ab-testing.md).

## Notes
- The first run downloads models into `./data/hf`, which can take several minutes.
- Run `make down` to stop all services.
- Default ports are 8080 for the gateway and 8000 for vLLM; adjust via environment variables if needed.
