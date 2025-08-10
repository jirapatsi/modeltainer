FROM python:latest

WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt \
    && useradd -m appuser \
    && chown -R appuser /app
COPY . /app
USER appuser
ENV MODELS_CONFIG=/app/../config/models.yaml
CMD ["uvicorn", "api.server:app", "--host", "0.0.0.0", "--port", "8080"]
