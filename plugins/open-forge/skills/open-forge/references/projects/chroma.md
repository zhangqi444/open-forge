---
name: chroma
description: Chroma recipe for open-forge. Covers client-server Docker deployment and embedded Python mode. Open-source AI-native vector database with a simple 4-function API; supports automatic embedding, metadata filtering, and multi-modal data. Sourced from https://github.com/chroma-core/chroma and https://docs.trychroma.com/.
---

# Chroma

Open-source AI-native vector database (embedding store) focused on developer simplicity. Core API is 4 functions: create collection, add documents, query, and delete. Handles tokenization and embedding automatically (or accepts pre-computed embeddings). Supports metadata filtering, multi-modal data, and persistent storage. Upstream: https://github.com/chroma-core/chroma. Docs: https://docs.trychroma.com/. Apache 2.0.

Two usage modes:
- **Embedded** — runs in-process with Python; zero infrastructure
- **Client-server** — HTTP server (`chroma run`) accessed by any language client

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Embedded (pip) | https://docs.trychroma.com/docs/overview/getting-started | Python dev; no server needed |
| Client-server (Docker) | https://docs.trychroma.com/production/containers/docker | Persistent, multi-client server |
| Docker Compose | https://docs.trychroma.com/production/containers/docker | Recommended for self-hosting |
| Kubernetes (Helm) | https://docs.trychroma.com/production/cloud-providers/gcp | Production scale |
| Chroma Cloud | https://trychroma.com/signup | Managed; free tier |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| preflight | "Embedded Python or client-server?" | Drives method |
| auth | "Enable authentication (token or basic auth)?" | Default: no auth |
| storage | "Persistent data path?" | Client-server only |
| port | "Custom port?" | Default: 8000 |

## Embedded Python mode

```sh
pip install chromadb
```

```python
import chromadb

# In-memory (no persistence):
client = chromadb.Client()

# Persistent (saves to disk):
client = chromadb.PersistentClient(path="/path/to/chroma_db")

collection = client.get_or_create_collection("my_docs")

collection.add(
    documents=["Hello world", "Vector databases are great"],
    ids=["id1", "id2"],
)

results = collection.query(query_texts=["what is a vector DB?"], n_results=1)
```

## Client-server (Docker)

```sh
docker run -p 8000:8000 \
  -v chroma-data:/chroma/chroma \
  chromadb/chroma:latest
```

With authentication (token):

```sh
docker run -p 8000:8000 \
  -v chroma-data:/chroma/chroma \
  -e CHROMA_SERVER_AUTHN_CREDENTIALS="your-token" \
  -e CHROMA_SERVER_AUTHN_PROVIDER="chromadb.auth.token_authn.TokenAuthenticationServerProvider" \
  chromadb/chroma:latest
```

## Docker Compose

```yaml
version: "3.8"
services:
  chroma:
    image: chromadb/chroma:latest
    ports:
      - "8000:8000"
    environment:
      IS_PERSISTENT: "TRUE"
      PERSIST_DIRECTORY: /chroma/chroma
      CHROMA_SERVER_AUTHN_CREDENTIALS: "your-token"
      CHROMA_SERVER_AUTHN_PROVIDER: "chromadb.auth.token_authn.TokenAuthenticationServerProvider"
    volumes:
      - chroma-data:/chroma/chroma

volumes:
  chroma-data:
```

Connect from Python:

```python
import chromadb
from chromadb.config import Settings

client = chromadb.HttpClient(
    host="localhost",
    port=8000,
    settings=Settings(chroma_client_auth_provider="chromadb.auth.token_authn.TokenAuthenticationClientProvider",
                      chroma_client_auth_credentials="your-token")
)
```

## Key environment variables (server mode)

| Variable | Purpose |
|---|---|
| IS_PERSISTENT | Set TRUE to persist data to PERSIST_DIRECTORY |
| PERSIST_DIRECTORY | Data path (default: /chroma/chroma) |
| CHROMA_SERVER_AUTHN_CREDENTIALS | Token or htpasswd string for auth |
| CHROMA_SERVER_AUTHN_PROVIDER | Auth provider class |
| CHROMA_SERVER_CORS_ALLOW_ORIGINS | Allowed CORS origins (JSON array) |

## Upgrade procedure

```sh
docker pull chromadb/chroma:latest
docker compose up -d

# pip embedded
pip install chromadb -U
```

## Gotchas

- **No auth by default** — the server accepts all connections without credentials; always set CHROMA_SERVER_AUTHN_CREDENTIALS before exposing to any network.
- **Embedded mode is single-process** — only one Python process can open the persistent database at a time; use client-server mode for multi-process or multi-language access.
- **Auto-embedding requires internet** — default embedding function downloads a model from HuggingFace on first use; for air-gapped environments, pass pre-computed embeddings instead.
- **Collection names are case-sensitive** — "MyDocs" and "mydocs" are different collections.
- **Chroma is schemaless** — documents, metadatas, and embeddings can vary per record; no upfront schema definition required.
- **Releases on Mondays** — the project cuts new pypi/npm releases weekly; pin a version tag in Docker/pip for production stability.

## Links

- GitHub: https://github.com/chroma-core/chroma
- Docs: https://docs.trychroma.com/
- Docker guide: https://docs.trychroma.com/production/containers/docker
- Docker Hub: https://hub.docker.com/r/chromadb/chroma
- Python client: https://pypi.org/project/chromadb/
