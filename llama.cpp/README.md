# LLaMA.cpp CPU Service

This setup runs the `llama-server` from [llama.cpp](https://github.com/ggml-org/llama.cpp) with CPU-only inference.

## Usage

1. Download the Gemma 3 1B (IT) model in `Q4_K_M` precision to the `models` directory:
   ```bash
   mkdir -p models
   huggingface-cli download unsloth/gemma-3-1b-it-GGUF --include "gemma-3-1b-it-Q4_K_M.gguf" --local-dir models
   ```
2. Start the service and gateway:
   ```bash
   docker compose -f llama.cpp/compose.yaml up -d
   ```
   * `LLAMACPP_MODEL` – override the model filename under `models/` (default: `gemma-3-1b-it-Q4_K_M.gguf`)
   * `LLAMACPP_PORT` – port to expose the server (default: `8002`)
   * `LLAMACPP_CONTEXT` – context length passed via `-c` (default: `4096`)

3. Send requests through the gateway (OpenAI-compatible):
   ```bash
   curl http://localhost:8080/v1/models
   ```

The backend listens on port `8002` with `--host 0.0.0.0` and `-c 4096` by default.
