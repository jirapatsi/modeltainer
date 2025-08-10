# syntax=docker/dockerfile:1
ARG BASE_IMAGE=vllm/vllm-openai:latest
FROM ${BASE_IMAGE}

ENV HF_HOME=/data/hf

ENTRYPOINT ["python", "-m", "vllm.entrypoints.openai.api_server"]
