# vLLM Multi-GPU Notes

vLLM scales across multiple GPUs via tensor and pipeline parallelism. When using Docker Compose you can reserve more than one GPU and pass the appropriate arguments to the server.

## Reserving GPUs
Set the `GPU_COUNT` environment variable before starting the service:

```bash
GPU_COUNT=2 docker compose -f vllm/compose.yaml --profile cuda up -d
```

On ROCm hardware use the `rocm` profile instead of `cuda`.

## Configuring vLLM
vLLM requires an explicit tensor-parallel or pipeline-parallel size to leverage multiple devices. Provide it via `VLLM_ARGS` and append to the command:

```bash
GPU_COUNT=2 VLLM_ARGS="--tensor-parallel-size 2" \
  docker compose -f vllm/compose.yaml --profile cuda up -d
```

For large models that do not fit on a single GPU, enable parallelism that matches `GPU_COUNT`.

## Notes
- Ensure all GPUs are of the same model and have high-speed interconnects.
- NCCL is used for communication on NVIDIA; ROCm uses RCCL.
- Distributed setups across multiple hosts are out of scope for this compose file.
