---
name: manticore-search
description: Recipe for Manticore Search — open-source, fast search database and Elasticsearch alternative with SQL-first interface.
---

# Manticore Search

Open-source search database designed for speed and ease of use. SQL-first (MySQL protocol compatible). Claimed to be significantly faster than Elasticsearch for search and log analytics workloads. Supports full-text search, vector search (hybrid search), columnar storage for large datasets, and real-time inserts. Good alternative to Elasticsearch/OpenSearch for self-hosted search. Upstream: <https://github.com/manticoresoftware/manticoresearch>. Docs: <https://manual.manticoresearch.com>. License: GPL-3.0+. ~10K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/manticoresearch/manticore> | Yes | Recommended |
| Docker Compose | <https://manual.manticoresearch.com/Installation/Docker> | Yes | Production setup with persistent storage |
| Linux packages (deb/rpm) | <https://manticoresearch.com/install/> | Yes | Bare-metal installs |
| Helm chart | <https://artifacthub.io/packages/helm/manticoresearch/manticoresearch> | Community | Kubernetes |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for MySQL protocol (SQL queries)? | Port (default 9306) | All |
| infra | Port for HTTP/JSON API? | Port (default 9308) | All |
| infra | Port for binary protocol? | Port (default 9312) | Optional |
| software | Data directory? | Absolute path | Required for persistence |
| software | Log directory? | Absolute path | Optional |

## Software-layer concerns

### Docker run (quickstart)

```bash
docker run -d \
  --name manticore \
  -p 9306:9306 \
  -p 9308:9308 \
  -v manticore-data:/var/lib/manticore \
  --restart unless-stopped \
  manticoresearch/manticore
```

### Docker Compose

```yaml
services:
  manticore:
    image: manticoresearch/manticore:latest
    container_name: manticore
    restart: unless-stopped
    ports:
      - "9306:9306"   # MySQL protocol (connect with any MySQL client)
      - "9308:9308"   # HTTP JSON API
    volumes:
      - manticore-data:/var/lib/manticore
      - manticore-logs:/var/log/manticore
      - ./manticore.conf:/etc/manticoresearch/manticore.conf:ro
    ulimits:
      nproc: 65535
      nofile:
        soft: 65535
        hard: 65535

volumes:
  manticore-data:
  manticore-logs:
```

### manticore.conf

```conf
searchd {
    listen = 9306:mysql41    # MySQL protocol
    listen = 9308:http       # HTTP JSON API
    listen = 9312:binary     # Binary protocol
    
    log = /var/log/manticore/searchd.log
    pid_file = /var/run/manticore/searchd.pid
    data_dir = /var/lib/manticore
}
```

### Connecting and creating tables

```sql
-- Connect with any MySQL client
mysql -h 127.0.0.1 -P 9306

-- Create a real-time table
CREATE TABLE products (
  id BIGINT,
  title TEXT,
  description TEXT,
  price FLOAT,
  category STRING,
  embedding FLOAT VECTOR KNN_TYPE='hnsw' KNN_DIMS='1536' HNSW_SIMILARITY='L2'
) engine='rowwise';

-- Insert
INSERT INTO products VALUES (1, 'Widget Pro', 'A great widget', 9.99, 'tools', ...);

-- Full-text search
SELECT id, title, WEIGHT() AS score FROM products WHERE MATCH('great widget') ORDER BY score DESC;

-- Hybrid search (full-text + vector)
SELECT id, title FROM products
  WHERE MATCH('widget') 
  AND KNN(embedding, 5, (0.1, 0.2, ...));
```

### HTTP JSON API

```bash
# Search
curl -X POST http://localhost:9308/search \
  -H 'Content-Type: application/json' \
  -d '{"index": "products", "query": {"match": {"title": "widget"}}}'

# Insert
curl -X POST http://localhost:9308/insert \
  -H 'Content-Type: application/json' \
  -d '{"index": "products", "doc": {"id": 1, "title": "Widget Pro"}}'
```

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

Manticore handles data format upgrades automatically on first start with a new version. Check release notes for breaking config changes: <https://github.com/manticoresoftware/manticoresearch/releases>

## Gotchas

- MySQL protocol, not MySQL: you connect with a MySQL client, but Manticore is not MySQL — many MySQL-specific SQL extensions don't work.
- `ulimits`: Manticore needs high file descriptor limits. Set `nofile: 65535` in Docker or systemd for production workloads.
- No ACID transactions: Manticore is a search engine, not a general-purpose database. It lacks transactions and relational constraints.
- Columnar storage: for datasets too large for RAM, use `engine='columnar'` instead of `rowwise`. Columnar is better for aggregations on large datasets.
- Vector search: HNSWLib-based vector index is built in. Combine with full-text search for hybrid retrieval.
- Elasticsearch API compatibility: Manticore supports a subset of the Elasticsearch JSON API, making some ES client libraries work with minimal changes.

## Links

- GitHub: <https://github.com/manticoresoftware/manticoresearch>
- Docs: <https://manual.manticoresearch.com>
- Docker Hub: <https://hub.docker.com/r/manticoresearch/manticore>
- Install guide: <https://manticoresearch.com/install/>
- Benchmarks: <https://db-benchmarks.com>
