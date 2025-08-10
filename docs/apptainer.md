# Apptainer workflow

ModelTainer can package each model into an [Apptainer](https://apptainer.org) image.
The resulting `.sif` files are portable and can be shared with other
machines without rebuilding.

## Build an image with a model

```bash
scripts/apptainer/modeltainer.sh build vllm openai/gpt-oss-20b-it
```

The first run downloads the model and produces
`images/vllm-openai_gpt-oss-20b-it.sif`.

## Run the model API

```bash
scripts/apptainer/modeltainer.sh run vllm openai/gpt-oss-20b-it 8000
```

The API is now reachable on `http://localhost:8000`.
Use different ports to start multiple models concurrently.

## Stop a running model

```bash
scripts/apptainer/modeltainer.sh stop vllm openai/gpt-oss-20b-it
```

Stopping frees GPU memory. Restarting the same model later does not
require a rebuild.

## Share the image

Copy the generated `.sif` file from `images/` to another host and run it
with the same script. No source repository or internet access is required
on the target machine.

