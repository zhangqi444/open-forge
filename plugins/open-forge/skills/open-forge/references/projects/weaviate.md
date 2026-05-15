---
name: weaviate
description: Weaviate recipe for open-forge. Covers Docker and Docker Compose deployment. Cloud-native vector database with built-in vectorization, hybrid search (BM25 + vector), multi-tenancy, RAG, and reranking. Sourced from https://github.com/weaviate/weaviate and https://docs.weaviate.io/deploy/installation-guides/docker-installation.
---

# Weaviate

Open-source cloud-native vector database that stores both objects and vectors. Supports semantic search, hybrid search (BM25 + vector), RAG (retrieval-augmented generation), multi-tenancy, replication, and RBAC. Built-in model integrations with OpenAI, Cohere, HuggingFace, and others for automatic vectorization at import. Upstream: https://github.com/weaviate/weaviate. Docs: https://docs.weaviate.io/. BSD 3-Clause.

Weaviate is available as self-hosted Docker/K8s or managed via Weaviate Cloud (free sandbox tier).

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker Compose | https://docs.weaviate.io/deploy/installation-guides/docker-installation | Dev and production single-node |
| Kubernetes (Helm) | https://docs.weaviate.io/deploy/installation-guides/k8s-installation | Production cluster |
| Embedded (Python) | https://docs.weaviate.io/deploy/installation-guides/embedded | Notebooks / local dev |
| Weaviate Cloud | https://console.weaviate.cloud | Managed SaaS; out of scope for open-forge |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Which vectorizer modules to enable?" | text2vec-openai, text2vec-cohere, text2vec-huggingface, or bring-your-own vectors |
| auth | "Enable API key authentication?" | Default: no auth |
| storage | "Persistent data path?" | Mount volume |
| port | "Expose REST (8080) and gRPC (50051) externally?" | Firewall rules |

## Docker Compose (with local embedding model)

```yaml
version: "3.8"
services:
  weaviate:
    image: cr.weaviate.io/semitechnologies/weaviate:1.37.4
    ports:
      - "8080:8080"    # REST + GraphQL
      - "50051:50051"  # gRPC
    environment:
      QUERY_DEFAULTS_LIMIT: "20"
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: "false"
      AUTHENTICATION_APIKEY_ENABLED: "true"
      AUTHENTICATION_APIKEY_ALLOWED_KEYS: "your-api-key"
      AUTHENTICATION_APIKEY_USERS: "admin"
      PERSISTENCE_DATA_PATH: "/var/lib/weaviate"
      ENABLE_MODULES: "text2vec-model2vec"
      MODEL2VEC_INFERENCE_API: "http://text2vec-model2vec:8080"
    volumes:
      - weaviate-data:/var/lib/weaviate
    depends_on:
      - text2vec-model2vec

  text2vec-model2vec:
    image: cr.weaviate.io/semitechnologies/model2vec-inference:minishlab-potion-base-32M

volumes:
  weaviate-data:
```

## Without auto-vectorization (bring your own vectors)

```yaml
version: "3.8"
services:
  weaviate:
    image: cr.weaviate.io/semitechnologies/weaviate:1.37.4
    ports:
      - "8080:8080"
      - "50051:50051"
    environment:
      AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED: "true"
      PERSISTENCE_DATA_PATH: "/var/lib/weaviate"
      DEFAULT_VECTORIZER_MODULE: "none"
    volumes:
      - weaviate-data:/var/lib/weaviate

volumes:
  weaviate-data:
```

## Key ports

| Port | Purpose |
|---|---|
| 8080 | REST API + GraphQL + Web UI |
| 50051 | gRPC API (faster for batch operations) |

## Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED | true | Set false to require API key |
| AUTHENTICATION_APIKEY_ALLOWED_KEYS | - | Comma-separated API keys |
| ENABLE_MODULES | - | Comma-separated module names |
| PERSISTENCE_DATA_PATH | /var/lib/weaviate | Data directory |
| DEFAULT_VECTORIZER_MODULE | text2vec-contextionary | Module used when none specified per collection |
| CLUSTER_HOSTNAME | node1 | Node name for distributed mode |

## Python client usage

```python
import weaviate
from weaviate.auth import AuthApiKey

client = weaviate.connect_to_local(
    port=8080,
    auth_credentials=AuthApiKey("your-api-key"),
)

# Create collection
from weaviate.classes.config import Configure, Property, DataType
client.collections.create(
    name="Article",
    properties=[Property(name="content", data_type=DataType.TEXT)],
    vector_config=Configure.Vectors.text2vec_model2vec(),
)

# Insert
articles = client.collections.get("Article")
articles.data.insert({"content": "Hello, Weaviate!"})

# Semantic search
results = articles.query.near_text(query="vector databases", limit=5)
```

## Upgrade procedure

```sh
# Pin version tag in docker-compose.yml, then:
docker compose pull && docker compose up -d
```

Check migration notes before upgrading: https://docs.weaviate.io/weaviate/more-resources/migration

## Gotchas

- **Anonymous access is enabled by default** — set AUTHENTICATION_ANONYMOUS_ACCESS_ENABLED=false and configure API keys before network exposure.
- **Image registry** — Weaviate images are on `cr.weaviate.io` (not Docker Hub); use `cr.weaviate.io/semitechnologies/weaviate:VERSION`.
- **Module selection at startup** — modules enabled via ENABLE_MODULES cannot be changed without restarting; plan which vectorizer modules are needed upfront.
- **Vectorizer API keys** — for cloud vectorizer modules (OpenAI, Cohere), the API key is passed per-request from the client, not stored server-side.
- **Multi-tenancy** — enable per-collection; once enabled, all operations require a tenant name; cannot be toggled after data is inserted.
- **gRPC is faster** — use the gRPC port (50051) for bulk inserts and batch operations; REST is fine for low-volume use.
- **Data migration** — Weaviate stores data in its own format; migrating between major versions may require re-importing data from scratch.

## Links

- GitHub: https://github.com/weaviate/weaviate
- Docker installation: https://docs.weaviate.io/deploy/installation-guides/docker-installation
- Python client: https://docs.weaviate.io/weaviate/client-libraries/python
- Module providers: https://docs.weaviate.io/weaviate/model-providers
- Image registry: https://console.cloud.google.com/artifacts (cr.weaviate.io)
