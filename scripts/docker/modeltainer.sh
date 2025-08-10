#!/usr/bin/env bash

# Build and run NVIDIA Docker images for vLLM and llama.cpp models.
#
# Usage:
#   modeltainer.sh build <vllm|llama> <model>
#   modeltainer.sh run   <vllm|llama> <model> [port]
#   modeltainer.sh stop  <vllm|llama> <model> [port]
#
# The NVIDIA Docker base image version is read from config/docker.yaml
# under the key `nvidia_docker_version`.

set -euo pipefail

ACTION=${1:-}
ENGINE=${2:-}
MODEL=${3:-}
PORT=${4:-8000}

if [[ -z "$ACTION" || -z "$ENGINE" || -z "$MODEL" ]]; then
  echo "Usage: $0 <build|run|stop> <vllm|llama> <model> [port]" >&2
  exit 1
fi

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG_FILE="$ROOT_DIR/../config/docker.yaml"
NVIDIA_VERSION=$(python3 - <<'PY'
import yaml,sys
from pathlib import Path
cfg = Path(sys.argv[1])
if cfg.is_file():
    data = yaml.safe_load(cfg.read_text()) or {}
    print(data.get("nvidia_docker_version", "latest"))
else:
    print("latest")
PY
"$CONFIG_FILE")

IMAGE_NAME="modeltainer-${ENGINE}-$(echo "$MODEL" | tr '/' '-')"
TAG="$NVIDIA_VERSION"
CONTAINER_NAME="$IMAGE_NAME-$PORT"

build_image() {
  if docker image inspect "$IMAGE_NAME:$TAG" >/dev/null 2>&1; then
    echo "Image $IMAGE_NAME:$TAG already exists; skipping build"
    return
  fi
  tmpdir=$(mktemp -d)
  case "$ENGINE" in
    vllm)
      cat >"$tmpdir/Dockerfile" <<EOF_DOCKER
FROM vllm/vllm-openai:$NVIDIA_VERSION
RUN pip install --no-cache-dir huggingface_hub && \\
    python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(repo_id="$MODEL", local_dir="/models/$MODEL")
PY
ENV PORT=8000
CMD bash -lc 'python3 -m vllm.entrypoints.openai.api_server --model /models/$MODEL --host 0.0.0.0 --port $PORT'
EOF_DOCKER
      ;;
    llama)
      cat >"$tmpdir/Dockerfile" <<EOF_DOCKER
FROM ghcr.io/ggerganov/llama.cpp:server
RUN pip install --no-cache-dir huggingface_hub && \\
    python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(repo_id="$MODEL", local_dir="/models/$MODEL")
PY
ENV PORT=8000
CMD bash -lc 'MODEL_FILE=$(find /models/$MODEL -name "*.gguf" | head -n 1); \ \
  exec /usr/local/bin/server -m "$MODEL_FILE" -p $PORT --host 0.0.0.0'
EOF_DOCKER
      ;;
    *)
      echo "Unknown engine: $ENGINE" >&2
      exit 1
      ;;
  esac
  echo "Building Docker image $IMAGE_NAME:$TAG"
  docker build -t "$IMAGE_NAME:$TAG" "$tmpdir"
  rm -rf "$tmpdir"
}

run_image() {
  echo "Starting $IMAGE_NAME:$TAG on port $PORT"
  docker run --gpus all -d --rm \
    -p "$PORT:$PORT" \
    --name "$CONTAINER_NAME" \
    -e PORT="$PORT" \
    "$IMAGE_NAME:$TAG" >/dev/null
  echo "Container $CONTAINER_NAME started"
}

stop_image() {
  if docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    docker stop "$CONTAINER_NAME" >/dev/null
    echo "Stopped $CONTAINER_NAME"
  else
    echo "No running container named $CONTAINER_NAME" >&2
  fi
}

case "$ACTION" in
  build)
    build_image
    ;;
  run)
    build_image
    run_image
    ;;
  stop)
    stop_image
    ;;
  *)
    echo "Unknown action: $ACTION" >&2
    exit 1
    ;;
ESAC
