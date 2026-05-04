---
name: milvus
description: Milvus recipe for open-forge. Covers Standalone (Docker Compose) and Milvus Lite (embedded Python) deployments. High-performance vector database for AI/RAG applications; supports billion-scale vector search, hybrid search, and GPU acceleration. Sourced from https://github.com/milvus-io/milvus and https://milvus.io/docs/install_standalone-docker.md.
---

# Milvus

High-performance, cloud-native vector database built for AI-scale workloads. Stores and searches billions of vectors with low latency. Supports dense vectors, sparse vectors, hybrid search (vector + scalar filtering), multi-vector, and GPU-accelerated indexing. Upstream: https://github.com/milvus-io/milvus. Docs: https://milvus.io/docs/. By Zilliz (Apache 2.0).

Three deployment modes:
- **Milvus Lite** — embedded Python library, no server; for prototyping
- **Milvus Standalone** — single Docker container with etcd + MinIO; for development and small production
- **Milvus Distributed** — Kubernetes-native, horizontally scalable; for large-scale production

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Milvus Lite (pip) | https://milvus.io/docs/milvus_lite.md | Prototyping in Python; no server needed |
| Standalone (Docker Compose) | https://milvus.io/docs/install_standalone-docker.md | Dev and small production |
| Distributed (Helm/K8s) | https://milvus.io/docs/install_cluster-helm.md | Large-scale production |
| Zilliz Cloud (managed) | https://cloud.zilliz.com | Managed SaaS; out of scope for open-forge |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Milvus Lite, Standalone, or Distributed?" | Drives method |
| storage | "Data volume path for persistence?" | Standalone Docker only |
| auth | "Enable authentication?" | Default: disabled; recommended for production |
| port | "Expose gRPC (19530) and REST (9091) externally?" | Standalone |

## Milvus Lite (embedded Python)

```sh
pip install pymilvus[milvus-lite]
```

```python
from pymilvus import MilvusClient

client = MilvusClient("milvus_demo.db")  # local file; persists to disk
```

No separate server process needed. Good for notebooks and local dev.

## Standalone (Docker Compose)

```sh
# Download the official Compose file
curl -sfL https://raw.githubusercontent.com/milvus-io/milvus/master/scripts/standalone_embed.sh -o standalone_embed.sh
bash standalone_embed.sh start
```

Or manually with Docker Compose:

```yaml
version: "3.8"
services:
  etcd:
    image: quay.io/coreos/etcd:v3.5.18
    environment:
      - ETCD_AUTO_COMPACTION_MODE=revision
      - ETCD_AUTO_COMPACTION_RETENTION=1000
      - ETCD_QUOTA_BACKEND_BYTES=4294967296
      - ETCD_SNAPSHOT_COUNT=50000
    command: etcd -advertise-client-urls=http://etcd:2379 -listen-client-urls=http://0.0.0.0:2379 --data-dir /etcd
    volumes:
      - etcd-data:/etcd

  minio:
    image: minio/minio:RELEASE.2023-03-13T19-46-17Z
    environment:
      MINIO_ACCESS_KEY: minioadmin
      MINIO_SECRET_KEY: minioadmin
    command: server /minio_data --console-address ":9001"
    volumes:
      - minio-data:/minio_data

  standalone:
    image: milvusdb/milvus:latest
    command: milvus run standalone
    environment:
      ETCD_ENDPOINTS: etcd:2379
      MINIO_ADDRESS: minio:9000
    ports:
      - "19530:19530"   # gRPC
      - "9091:9091"     # REST / health
    depends_on:
      - etcd
      - minio
    volumes:
      - milvus-data:/var/lib/milvus

volumes:
  etcd-data:
  minio-data:
  milvus-data:
```

Connect with Python:

```python
from pymilvus import MilvusClient
client = MilvusClient(uri="http://localhost:19530")
```

## Key ports

| Port | Purpose |
|---|---|
| 19530 | gRPC API (primary; used by all SDKs) |
| 9091 | REST API + health check (/healthz) |

## Authentication

Authentication is disabled by default. To enable:

Set `common.security.authorizationEnabled: true` in milvus.yaml, then connect with:
```python
client = MilvusClient(uri="http://localhost:19530", token="username:password")
```

Default root credentials: `root` / `Milvus`.

## Upgrade procedure

```sh
# Standalone: pull new image and recreate
docker compose pull && docker compose up -d

# Milvus Lite
pip install pymilvus[milvus-lite] -U
```

For distributed (Helm): `helm upgrade milvus milvus/milvus -f values.yaml`

## Gotchas

- **etcd and MinIO are required** for Standalone — they are not optional dependencies; Milvus uses etcd for metadata and MinIO for segment storage.
- **Authentication disabled by default** — enable before any network exposure; default root password must be changed immediately after first login.
- **Index must be built before search** — inserting vectors does not auto-index; call `create_index()` after bulk insert or Milvus will do brute-force search.
- **Collection schema is immutable** — fields cannot be added or removed after collection creation; plan schema carefully.
- **GPU indexing** — requires CUDA-capable GPU and the GPU-enabled image (`milvusdb/milvus:latest-gpu`); not needed for most workloads.
- **Milvus Lite vs Standalone** — Lite uses the same pymilvus API but runs in-process; Standalone adds multi-user access and larger dataset support.

## Links

- GitHub: https://github.com/milvus-io/milvus
- Standalone Docker install: https://milvus.io/docs/install_standalone-docker.md
- Milvus Lite: https://milvus.io/docs/milvus_lite.md
- Python SDK: https://github.com/milvus-io/pymilvus
- Docker Hub: https://hub.docker.com/r/milvusdb/milvus
