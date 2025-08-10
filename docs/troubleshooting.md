# Troubleshooting

Common issues when running ModelTainer.

## Port Conflicts
If ports `8080` (gateway) or `8000` (vLLM) are in use, change them when starting services:
```bash
GATEWAY_PORT=9090 VLLM_PORT=9000 make up
```
Verify with `docker ps` that the containers are bound to the desired ports.

## VRAM Out of Memory
vLLM requires sufficient GPU memory. If the container exits with OOM errors:
- Choose a smaller model via `VLLM_MODEL`.
- Reduce `GPU_COUNT` or other vLLM parameters.
- Ensure no other processes are using the GPU.

## Hugging Face Authentication
Gated models require a Hugging Face token:
```bash
export HUGGING_FACE_HUB_TOKEN=hf_xxx
make up
```
Tokens can also be placed in `./.env` for convenience.

## Notes
- Inspect container logs with `make logs` for additional details.
- The Hugging Face cache lives under `./data/hf`; delete entries if downloads become corrupted.
- Adjusting ports may require updating client configurations pointing at the API.
