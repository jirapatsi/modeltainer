#!/bin/bash
#SBATCH --job-name=vllm
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%j.log

# Optional: restrict to specific GPU or MIG slice
# export CUDA_VISIBLE_DEVICES=${CUDA_VISIBLE_DEVICES:-0}

module load apptainer

MODEL=${VLLM_MODEL:-NousResearch/Meta-Llama-3-8B-Instruct}
PORT=${VLLM_PORT:-8000}

# Launch vLLM OpenAI-compatible server inside Apptainer
apptainer exec --nv docker://vllm/vllm-openai:latest \
  python3 -m vllm.entrypoints.openai.api_server \
    --model "$MODEL" \
    --host 0.0.0.0 \
    --port "$PORT"
