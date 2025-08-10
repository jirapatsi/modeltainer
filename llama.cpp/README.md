# LLaMA.cpp CPU Service

This setup runs the `llama-server` from [llama.cpp](https://github.com/ggml-org/llama.cpp) with CPU-only inference.

## Usage

1. Place a GGUF model in the `models` directory at the repository root:
   ```bash
   mkdir -p models
   cp /path/to/your/model.gguf models/
   ```
2. Start the service and gateway:
   ```bash
   LLAMACPP_MODEL=model.gguf docker compose -f llama.cpp/compose.yaml up -d
   ```
   * `LLAMACPP_MODEL` – filename of the model under `models/` (default: `model.gguf`)
   * `LLAMACPP_PORT` – port to expose the server (default: `8002`)
   * `LLAMACPP_CONTEXT` – context length passed via `-c` (default: `4096`)

3. Send requests through the gateway (OpenAI-compatible):
   ```bash
   curl http://localhost:8080/v1/models
   ```

The backend listens on port `8002` with `--host 0.0.0.0` and `-c 4096` by default.
