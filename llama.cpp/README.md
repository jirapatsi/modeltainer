# LLaMA.cpp CPU Service

This setup runs the `llama-server` from [llama.cpp](https://github.com/ggml-org/llama.cpp) with CPU-only inference.

## Usage

1. Download the GPT-OSS 20B model in `mxfp4` precision to the `models` directory:
   ```bash
   mkdir -p models
   huggingface-cli download ggml-org/gpt-oss-20b-GGUF --include "gpt-oss-20b-mxfp4.gguf" --local-dir models
   ```
2. Start the service and gateway:
   ```bash
   docker compose -f llama.cpp/compose.yaml up -d
   ```
   * `LLAMACPP_MODEL` – override the model filename under `models/` (default: `gpt-oss-20b-mxfp4.gguf`)
   * `LLAMACPP_PORT` – port to expose the server (default: `8002`)
   * `LLAMACPP_CONTEXT` – context length passed via `-c` (default: `4096`)

3. Send requests through the gateway (OpenAI-compatible):
   ```bash
   curl http://localhost:8080/v1/models
   ```

The backend listens on port `8002` with `--host 0.0.0.0` and `-c 4096` by default.
