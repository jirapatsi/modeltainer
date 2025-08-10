# NVIDIA Docker workflow

ModelTainer can also package each model into a standalone NVIDIA Docker image.
The resulting images can be transferred to other machines with compatible
GPU drivers.

## Build an image with a model

```bash
scripts/docker/modeltainer.sh build vllm openai/gpt-oss-20b-it
```

The script reads `config/docker.yaml` to determine the base image tag. The
default version is `v0.10.0`, but you can adjust it:

```yaml
# config/docker.yaml
nvidia_docker_version: "v0.10.0"
```

## Run the model API

```bash
scripts/docker/modeltainer.sh run vllm openai/gpt-oss-20b-it 8000
```

The API is now reachable on `http://localhost:8000`.
Use different ports to start multiple models concurrently.

## Stop a running model

```bash
scripts/docker/modeltainer.sh stop vllm openai/gpt-oss-20b-it 8000
```

Stopping frees GPU memory. Restarting the same model later does not
require a rebuild.

## Share the image

Copy the generated Docker image with `docker save` and load it on another
host. The `nvidia_docker_version` in `config/docker.yaml` ensures the correct
base image is used when rebuilding.
