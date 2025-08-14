# Resource Sizing Cheatsheet

Estimate hardware needs for common model configurations.

| Model | Backend | Precision | Minimum VRAM | Notes |
|-------|---------|-----------|--------------|-------|
| `openai/gpt-oss-20b` | vLLM | mxfp4 | ~24 GB | Single GPU |
| `NousResearch/Meta-Llama-3-8B-Instruct` | vLLM | fp16 | ~16 GB | Single GPU |
| `gpt-oss-20b-mxfp4.gguf` | llama.cpp | mxfp4 | ~10 GB RAM | CPU/ARM |

Adjust `GPU_COUNT` to spread models across multiple GPUs if available.

## Notes
- VRAM estimates assume no other processes share the GPU.
- Higher precision (fp16, fp32) increases memory requirements.
- For custom models, consult their documentation for exact sizing.
