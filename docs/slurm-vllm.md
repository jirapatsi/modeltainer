# vLLM on Slurm with Apptainer

This guide outlines running the OpenAI‑compatible vLLM server on a Slurm GPU node using [Apptainer](https://apptainer.org/) to pull the upstream Docker image. It covers submitting the batch job, accessing the service port, and running multiple instances on an NVIDIA A100 with MIG.

## Submit the Job

1. Copy or customize [`scripts/slurm/run_vllm.sbatch`](../scripts/slurm/run_vllm.sbatch).
2. Submit to Slurm:

```bash
sbatch scripts/slurm/run_vllm.sbatch
```

The script pulls `docker://vllm/vllm-openai:latest` and launches the server on the port defined by `VLLM_PORT` (default `8000`). Set `VLLM_MODEL` to choose a model.

## Accessing the Service Port

The vLLM server binds to `0.0.0.0` so the port is reachable from the compute node. Common access patterns:

- **SSH tunnel from login node**
  ```bash
  ssh -L 8000:$(squeue -j <jobid> -h -o %N):8000 login.cluster
  curl -sf http://localhost:8000/health
  ```
- **Node proxy / service node** – run a lightweight HTTP proxy (e.g. Nginx) on a trusted node that forwards requests to the compute node.
- **Cluster service** – if the cluster provides an internal load balancer, register the compute node and port so other nodes can reach it directly.

## Running on A100 with MIG

Multiple vLLM services can share a single A100 by exposing MIG devices. Adjust `CUDA_VISIBLE_DEVICES` in the batch script to the MIG slice ID:

```bash
export CUDA_VISIBLE_DEVICES=MIG-GPU-<UUID>/gi0
```

Each job can target a different slice while sharing node resources. Confirm MIG devices with `nvidia-smi -L`.

## Shutdown

Cancel the job when finished:

```bash
scancel <jobid>
```

## Security Notes

- Only forward ports through trusted networks.
- Restrict job runtime and memory to prevent abuse.
- Clear any cached model data between users if using shared scratch storage.
