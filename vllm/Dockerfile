# syntax=docker/dockerfile:1
ARG BASE_IMAGE=vllm/vllm-openai:v0.10.0
FROM ${BASE_IMAGE}

ENV HF_HOME=/data/hf

ENTRYPOINT ["python", "-m", "vllm.entrypoints.openai.api_server"]
