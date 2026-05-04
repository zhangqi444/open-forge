---
name: mlflow
description: MLflow recipe for open-forge. Open-source AI engineering platform for tracking ML experiments, managing models, evaluating LLMs, and serving models. 60M+ monthly downloads.
---

# MLflow

Open-source AI engineering platform for the full ML and GenAI lifecycle. Tracks experiments (parameters, metrics, artifacts), manages model versions in a registry, evaluates LLMs, provides LLM observability/tracing, manages prompts, and serves models. 60M+ monthly PyPI downloads. Apache 2.0. Upstream: <https://github.com/mlflow/mlflow>. Docs: <https://mlflow.org/docs/latest>.

## Compatible install methods

| Method | When to use |
|---|---|
| `pip install mlflow` + `mlflow server` | Dev / single-machine; quickest start |
| Docker / Docker Compose | Containerized team server |
| Kubernetes / Helm | Production; persistent backend |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Backend store?" | Local filesystem (dev), PostgreSQL/MySQL (production) |
| preflight | "Artifact store?" | Local path (dev), S3/GCS/Azure Blob/MinIO (production) |
| preflight | "Domain for MLflow UI?" | For reverse-proxy TLS |

## Docker Compose example (with PostgreSQL + MinIO)

```yaml
version: "3.9"
services:
  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_DB: mlflow
      POSTGRES_USER: mlflow
      POSTGRES_PASSWORD: changeme
    volumes:
      - mlflow-db:/var/lib/postgresql/data

  minio:
    image: minio/minio:latest
    restart: unless-stopped
    command: server /data --console-address ":9001"
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: minioadmin
      MINIO_ROOT_PASSWORD: minioadmin
    volumes:
      - minio-data:/data

  mlflow:
    image: ghcr.io/mlflow/mlflow:latest
    restart: unless-stopped
    depends_on:
      - db
      - minio
    ports:
      - "5000:5000"
    command: >
      mlflow server
      --backend-store-uri postgresql://mlflow:changeme@db:5432/mlflow
      --default-artifact-root s3://mlflow-artifacts/
      --host 0.0.0.0
      --port 5000
    environment:
      MLFLOW_S3_ENDPOINT_URL: http://minio:9000
      AWS_ACCESS_KEY_ID: minioadmin
      AWS_SECRET_ACCESS_KEY: minioadmin

volumes:
  mlflow-db:
  minio-data:
```

Create `mlflow-artifacts` bucket in MinIO before first use.

## Quick local start

```bash
pip install mlflow
mlflow server --host 0.0.0.0 --port 5000
# UI: http://localhost:5000
```

## Logging an experiment (Python)

```python
import mlflow

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("my-experiment")

with mlflow.start_run():
    mlflow.log_param("learning_rate", 0.01)
    mlflow.log_metric("accuracy", 0.95)
    mlflow.log_artifact("model.pkl")
```

## LLM tracing (GenAI)

```python
import mlflow
import openai

mlflow.openai.autolog()   # auto-traces all OpenAI calls

client = openai.OpenAI()
response = client.chat.completions.create(model="gpt-4o", messages=[...])
# Trace automatically sent to MLflow UI
```

## Software-layer concerns

- Port `5000`: MLflow tracking UI + REST API
- Container image: `ghcr.io/mlflow/mlflow` (GHCR) or install via pip
- Backend store: SQLite (default, dev only), PostgreSQL/MySQL (production)
- Artifact store: local filesystem (dev), S3/GCS/Azure/MinIO (production)
- Model Registry: register, version, and stage models (Staging → Production)
- MLflow AI Gateway: proxy for LLM providers with rate limiting and cost tracking

## Upgrade procedure

```bash
pip install --upgrade mlflow
# Or for Docker:
docker compose pull mlflow && docker compose up -d mlflow
```

Check migration guide for backend schema changes: <https://mlflow.org/docs/latest/tracking/backend-stores#upgrading>

## Gotchas

- Default SQLite + local filesystem backend is NOT suitable for multi-user or production use
- Artifact store must be accessible from both the MLflow server and your training machines
- `mlflow db upgrade` command required after upgrading MLflow with PostgreSQL backend
- LLM tracing (`mlflow.openai.autolog()`) is a newer feature — check version ≥ 2.14 for best coverage

## Links

- GitHub: <https://github.com/mlflow/mlflow>
- Docs: <https://mlflow.org/docs/latest>
- LLM tracing: <https://mlflow.org/llm-tracing>
- GHCR: <https://github.com/mlflow/mlflow/pkgs/container/mlflow>
