#!/usr/bin/env bash

# Build and run model containers via Apptainer or Docker.
#
# Usage:
#   modeltainer.sh --engine <apptainer|docker> <build|run|stop> <vllm|llama> <model> [port]

set -euo pipefail

usage() {
  echo "Usage: $0 --engine <apptainer|docker> <build|run|stop> <vllm|llama> <model> [port]" >&2
  exit 1
}

CONTAINER_ENGINE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --engine)
      CONTAINER_ENGINE="${2:-}"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

ACTION=${1:-}
MODEL_ENGINE=${2:-}
MODEL=${3:-}
PORT=${4:-8000}

if [[ -z "$CONTAINER_ENGINE" || -z "$ACTION" || -z "$MODEL_ENGINE" || -z "$MODEL" ]]; then
  usage
fi

case "$CONTAINER_ENGINE" in
  apptainer)
    IMAGE_DIR="${IMAGE_DIR:-images}"
    RUN_DIR="${RUN_DIR:-run}"
    mkdir -p "$IMAGE_DIR" "$RUN_DIR"

    SIF="$IMAGE_DIR/${MODEL_ENGINE}-$(echo "$MODEL" | tr '/' '_').sif"
    PID_FILE="$RUN_DIR/$(basename "$SIF").pid"
    LOG_FILE="$RUN_DIR/$(basename "$SIF").log"

    build_image() {
      if [[ -f "$SIF" ]]; then
        echo "Image $SIF already exists; skipping build"
        return
      fi

      tmpdef=$(mktemp)
      case "$MODEL_ENGINE" in
        vllm)
          cat > "$tmpdef" <<EOF_DEF
Bootstrap: docker
From: vllm/vllm-openai:latest

%post
    pip install --no-cache-dir huggingface_hub
    python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(repo_id="$MODEL", local_dir="/models/$MODEL")
PY

%startscript
    PORT=\${PORT:-8000}
    exec python3 -m vllm.entrypoints.openai.api_server \\
        --model "/models/$MODEL" \\
        --host 0.0.0.0 \\
        --port "\$PORT"
EOF_DEF
          ;;
        llama)
          cat > "$tmpdef" <<EOF_DEF
Bootstrap: docker
From: ghcr.io/ggerganov/llama.cpp:server

%post
    pip install --no-cache-dir huggingface_hub
    python3 - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download(repo_id="$MODEL", local_dir="/models/$MODEL")
PY

%startscript
    PORT=\${PORT:-8000}
    MODEL_FILE=\$(find /models/$MODEL -name '*.gguf' | head -n 1)
    exec /usr/local/bin/server -m "\$MODEL_FILE" -p "\$PORT" --host 0.0.0.0
EOF_DEF
          ;;
        *)
          echo "Unknown engine: $MODEL_ENGINE" >&2
          exit 1
          ;;
      esac

      echo "Building Apptainer image $SIF"
      apptainer build "$SIF" "$tmpdef"
      rm -f "$tmpdef"
    }

    run_image() {
      echo "Starting $SIF on port $PORT"
      apptainer run --nv --env PORT=$PORT "$SIF" >"$LOG_FILE" 2>&1 &
      echo $! > "$PID_FILE"
      echo "PID $(cat $PID_FILE)"
    }

    stop_image() {
      if [[ -f "$PID_FILE" ]]; then
        kill $(cat "$PID_FILE") && rm -f "$PID_FILE"
        echo "Stopped $(basename "$SIF")"
      else
        echo "No running process for $(basename "$SIF")" >&2
      fi
    }
    ;;
  docker)
    SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
    CONFIG_FILE="$SCRIPT_DIR/../config/docker.yaml"
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

    IMAGE_NAME="modeltainer-${MODEL_ENGINE}-$(echo "$MODEL" | tr '/' '-')"
    TAG="$NVIDIA_VERSION"
    CONTAINER_NAME="$IMAGE_NAME-$PORT"

    build_image() {
      if docker image inspect "$IMAGE_NAME:$TAG" >/dev/null 2>&1; then
        echo "Image $IMAGE_NAME:$TAG already exists; skipping build"
        return
      fi
      tmpdir=$(mktemp -d)
      case "$MODEL_ENGINE" in
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
CMD bash -lc 'MODEL_FILE=$(find /models/$MODEL -name "*.gguf" | head -n 1); \\
  exec /usr/local/bin/server -m "$MODEL_FILE" -p $PORT --host 0.0.0.0'
EOF_DOCKER
          ;;
        *)
          echo "Unknown engine: $MODEL_ENGINE" >&2
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
    ;;
  *)
    echo "Unknown container engine: $CONTAINER_ENGINE" >&2
    exit 1
    ;;
esac

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
esac

