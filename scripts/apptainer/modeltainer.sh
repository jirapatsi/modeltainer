#!/usr/bin/env bash

# Build and run Apptainer images for vLLM and llama.cpp models.
#
# Usage:
#   modeltainer.sh build <vllm|llama> <model>
#   modeltainer.sh run   <vllm|llama> <model> [port]
#   modeltainer.sh stop  <vllm|llama> <model>
#
# Images are stored under ./images and can be copied to other machines
# for reuse. Running models keep PID files under ./run so they can be
# stopped later.

set -euo pipefail

ACTION=${1:-}
ENGINE=${2:-}
MODEL=${3:-}
PORT=${4:-8000}

if [[ -z "$ACTION" || -z "$ENGINE" || -z "$MODEL" ]]; then
  echo "Usage: $0 <build|run|stop> <vllm|llama> <model> [port]" >&2
  exit 1
fi

IMAGE_DIR="${IMAGE_DIR:-images}"
RUN_DIR="${RUN_DIR:-run}"
mkdir -p "$IMAGE_DIR" "$RUN_DIR"

SIF="$IMAGE_DIR/${ENGINE}-$(echo "$MODEL" | tr '/' '_').sif"
PID_FILE="$RUN_DIR/$(basename "$SIF").pid"
LOG_FILE="$RUN_DIR/$(basename "$SIF").log"

build_image() {
  if [[ -f "$SIF" ]]; then
    echo "Image $SIF already exists; skipping build"
    return
  fi

  tmpdef=$(mktemp)
  case "$ENGINE" in
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
      echo "Unknown engine: $ENGINE" >&2
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


