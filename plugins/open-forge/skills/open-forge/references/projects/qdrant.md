---
name: qdrant
description: Qdrant recipe for open-forge. Covers Docker and Docker Compose deployment. High-performance vector similarity search engine written in Rust; supports filtering, payload indexing, named vectors, and sparse vectors for hybrid search. Sourced from https://github.com/qdrant/qdrant and https://qdrant.tech/documentation/guides/installation/.
---

# Qdrant

Vector similarity search engine and database written in Rust. Provides production-ready REST and gRPC APIs for storing, searching, and managing vectors with metadata payloads. Supports extended filtering, multi-vector, sparse vectors (for hybrid dense+sparse search), and on-disk indexing. Upstream: https://github.com/qdrant/qdrant. Docs: https://qdrant.tech/documentation/. Apache 2.0.

Qdrant is distributed as a single binary / Docker image with no external dependencies. Qdrant Cloud (managed, free tier) is also available.

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker (single node) | https://qdrant.tech/documentation/guides/installation/#docker | Dev and production single-node |
| Docker Compose | https://qdrant.tech/documentation/guides/installation/#docker-compose | With persistent storage and custom config |
| Kubernetes (Helm) | https://qdrant.tech/documentation/guides/installation/#kubernetes | Production cluster |
| Binary (Linux/macOS) | https://qdrant.tech/documentation/guides/installation/ | Bare-metal |
| Python in-memory | https://qdrant.tech/documentation/guides/installation/#local-quickstart | Local dev / CI; no server |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Single node or distributed cluster?" | Cluster requires Qdrant distributed mode |
| auth | "Set an API key for authentication?" | Default: no auth — insecure on open networks |
| storage | "Data directory for persistence?" | Mount as volume |
| port | "Expose REST (6333) and gRPC (6334) externally?" | Firewall rules |

## Docker quickstart

```sh
docker run -p 6333:6333 -p 6334:6334 qdrant/qdrant
```

> Caution: starts without authentication, open to all interfaces. Set an API key for any non-localhost use.

With persistence and API key:

```sh
docker run -p 6333:6333 -p 6334:6334 \
  -v qdrant-data:/qdrant/storage \
  -e QDRANT__SERVICE__API_KEY=your-secret-key \
  qdrant/qdrant
```

## Docker Compose

```yaml
version: "3.8"
services:
  qdrant:
    image: qdrant/qdrant:latest
    ports:
      - "6333:6333"   # REST API
      - "6334:6334"   # gRPC
    environment:
      QDRANT__SERVICE__API_KEY: "your-secret-key"
    volumes:
      - qdrant-data:/qdrant/storage

volumes:
  qdrant-data:
```

## Key ports

| Port | Purpose |
|---|---|
| 6333 | REST API + Web UI (/_/ui/) |
| 6334 | gRPC API |

## Python client usage

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams

client = QdrantClient(url="http://localhost:6333", api_key="your-secret-key")

# Create collection
client.create_collection(
    collection_name="my_docs",
    vectors_config=VectorParams(size=1536, distance=Distance.COSINE),
)

# Upsert vectors
client.upsert(
    collection_name="my_docs",
    points=[{"id": 1, "vector": [...], "payload": {"text": "hello"}}],
)

# Search
results = client.search(
    collection_name="my_docs",
    query_vector=[...],
    limit=5,
)
```

## Configuration (config.yaml)

Key settings override via environment variables (QDRANT__SECTION__KEY format):

| Setting | Env var | Default |
|---|---|---|
| API key | QDRANT__SERVICE__API_KEY | (none) |
| gRPC port | QDRANT__SERVICE__GRPC_PORT | 6334 |
| Storage path | QDRANT__STORAGE__STORAGE_PATH | ./storage |
| On-disk vectors | QDRANT__STORAGE__ON_DISK_PAYLOAD | false |
| Max segment size | QDRANT__STORAGE__OPTIMIZERS__MAX_SEGMENT_SIZE | auto |

## Upgrade procedure

```sh
# Docker
docker pull qdrant/qdrant:latest
docker compose up -d

# Helm
helm upgrade qdrant qdrant/qdrant -f values.yaml
```

## Gotchas

- **No auth by default** — QDRANT__SERVICE__API_KEY must be set before exposing to any network; the default Docker run command is intentionally insecure for local dev.
- **Collection schema is fixed** — vector dimensions and distance metric cannot be changed after collection creation; re-create the collection to change them.
- **On-disk vs in-memory** — by default vectors are kept in RAM for speed; set `on_disk: true` in vector config for datasets larger than available RAM.
- **Sparse vectors for hybrid search** — combine dense (semantic) and sparse (BM25-style keyword) vectors in a single collection using named vectors.
- **Snapshot / backup** — use the REST API (`POST /collections/{name}/snapshots`) to create point-in-time snapshots for backup.
- **Distributed mode** — enable with `cluster.enabled: true` in config; requires a consensus mechanism (built into Qdrant, no Zookeeper needed).

## Links

- GitHub: https://github.com/qdrant/qdrant
- Installation guide: https://qdrant.tech/documentation/guides/installation/
- Security guide: https://qdrant.tech/documentation/guides/security/
- Python client: https://github.com/qdrant/qdrant-client
- Docker Hub: https://hub.docker.com/r/qdrant/qdrant
- Benchmarks: https://qdrant.tech/benchmarks/
