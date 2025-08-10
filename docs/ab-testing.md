# A/B Testing with Multiple Models

ModelTainer routes requests based on the `model` field. By defining distinct model IDs in `config/models.yaml`, multiple backends can run side by side to support A/B experiments. Start each backend independently in Docker or Apptainer and expose unique ports before launching the gateway with the multi-model configuration.

## Example Configuration
```yaml
models:
  test-model-a:
    backend: vllm
    backend_url: http://localhost:8001
  test-model-b:
    backend: vllm
    backend_url: http://localhost:8003
  embedding-model:
    backend: llamacpp
    backend_url: http://localhost:8002
    embeddings: true
```

Each logical model name (`test-model-a`, `test-model-b`) points to a different backend process and port.

## Sending Requests
Switch models by changing the `model` field in the request body:

```bash
curl -s -X POST http://localhost:8080/v1/chat/completions \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $API_KEY" \
  -d '{"model": "test-model-a", "messages": [{"role": "user", "content": "hi"}]}'

curl -s -X POST http://localhost:8080/v1/chat/completions \
  -H 'Content-Type: application/json' -H "Authorization: Bearer $API_KEY" \
  -d '{"model": "test-model-b", "messages": [{"role": "user", "content": "hi"}]}'
```

Responses stream independently, enabling head-to-head comparison of the two model variants.
