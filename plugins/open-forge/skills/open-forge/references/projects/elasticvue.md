---
name: elasticvue
description: Elasticvue is a self-hosted web UI for Elasticsearch and OpenSearch clusters — browse indices, run queries, view documents and cluster stats without the Kibana stack. Available as Docker container, desktop app, and browser extension. Upstream: https://github.com/cars10/elasticvue
---

# Elasticvue

Elasticvue is a browser-based GUI for [Elasticsearch](https://www.elastic.co/elasticsearch) and [OpenSearch](https://opensearch.org/) clusters. It lets you browse indices, run queries, inspect documents, view cluster health, and manage aliases — without installing Kibana or OpenSearch Dashboards. Runs as a self-hosted Docker container (nginx serving a static Vue.js app), desktop app, or browser extension. Upstream: <https://github.com/cars10/elasticvue>.

Latest stable release: **v1.14.0** (check <https://github.com/cars10/elasticvue/releases> for latest).  
Docker Hub: <https://hub.docker.com/r/cars10/elasticvue> | GHCR: `ghcr.io/cars10/elasticvue`

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS / bare-metal | Docker (single container) | nginx + static app. No database required. |
| Docker Compose alongside Elasticsearch | Docker Compose | Add to existing ES/OpenSearch Compose stack. |
| Raspberry Pi (ARM64) | Docker | Multi-arch image available. |

Elasticvue **only provides the UI** — it connects to an existing Elasticsearch or OpenSearch cluster. The cluster must either be on the same network or reachable from the browser (CORS required for browser-to-cluster calls).

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Elasticsearch / OpenSearch cluster URL?" | e.g. `http://elasticsearch:9200` (same Docker network) or `https://es.example.com:9200`. |
| preflight | "Cluster username and password?" | If security is enabled (recommended). Leave blank for local dev clusters. |
| optional | "Pre-seed cluster connection in the container?" | Avoids manual entry on every launch. See `ELASTICVUE_CLUSTERS` env var below. |

## Software-layer concerns

Elasticvue is a **stateless** UI container — it stores cluster connections in the browser's localStorage. There are no app-side config files or databases to back up. The only persistent concern is the optional pre-seeded cluster config.

### CORS requirement

**For Docker and browser-based deployments**, Elasticsearch must have CORS enabled — otherwise the browser's requests to the cluster are blocked by the same-origin policy. The desktop app and browser extensions bypass CORS.

Add to `elasticsearch.yml` (or via env var `ES_JAVA_OPTS`):

```yaml
http.cors.enabled: true
http.cors.allow-origin: "http://localhost:8080"    # or your Elasticvue external URL
http.cors.allow-methods: OPTIONS, HEAD, GET, POST, PUT, DELETE
http.cors.allow-headers: X-Requested-With,Content-Type,Content-Length,Authorization
```

For clusters with basic auth / security enabled:

```yaml
http.cors.allow-credentials: true
```

OpenSearch uses the same CORS configuration keys.

### Pre-seeding cluster connections

Set `ELASTICVUE_CLUSTERS` to a JSON array to auto-import connections when the container starts:

```json
[{"name": "my-cluster", "uri": "http://elasticsearch:9200", "username": "elastic", "password": "changeme"}]
```

Or mount a JSON config file as a volume:

```bash
echo '[{"name": "my-cluster", "uri": "http://elasticsearch:9200"}]' > /opt/elasticvue/default_clusters.json
# mount to: /usr/share/nginx/html/api/default_clusters.json
```

## Docker run (quick start)

```bash
# Docker Hub image
docker run -p 8080:8080 --name elasticvue -d cars10/elasticvue

# GHCR image
docker run -p 8080:8080 --name elasticvue -d ghcr.io/cars10/elasticvue

# With pre-seeded cluster (no manual setup)
docker run -p 8080:8080 -d \
  -e ELASTICVUE_CLUSTERS='[{"name": "local", "uri": "http://elasticsearch:9200"}]' \
  --name elasticvue \
  cars10/elasticvue

# Access at http://localhost:8080
```

## Docker Compose (with Elasticsearch)

```yaml
# docker-compose.yml
services:
  elasticsearch:
    image: elasticsearch:8.13.0
    container_name: elasticsearch
    restart: unless-stopped
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false    # disable for local dev; enable in production
      - http.cors.enabled=true
      - http.cors.allow-origin=http://localhost:8080
      - http.cors.allow-headers=X-Requested-With,Content-Type,Content-Length,Authorization
    ports:
      - "9200:9200"
    volumes:
      - es_data:/usr/share/elasticsearch/data
    networks:
      - esnet

  elasticvue:
    image: ghcr.io/cars10/elasticvue:latest
    container_name: elasticvue
    restart: unless-stopped
    ports:
      - "8080:8080"
    environment:
      - ELASTICVUE_CLUSTERS=[{"name":"local","uri":"http://elasticsearch:9200"}]
    depends_on:
      - elasticsearch
    networks:
      - esnet

volumes:
  es_data:

networks:
  esnet:
```

```bash
docker compose up -d
# Access elasticvue at http://localhost:8080
```

## Upgrade procedure

```bash
# Docker run
docker stop elasticvue && docker rm elasticvue
docker pull cars10/elasticvue
docker run -p 8080:8080 --name elasticvue -d cars10/elasticvue

# Docker Compose
docker compose pull elasticvue
docker compose up -d elasticvue
```

No data to migrate — elasticvue is stateless (cluster connections are in browser localStorage).

## Gotchas

- **CORS is mandatory for Docker/web deployments.** The browser makes direct API calls to Elasticsearch from `http://localhost:8080`. Without CORS headers on Elasticsearch, every operation fails with a network error. The desktop app and browser extensions are exempt — they bypass CORS via browser extension permissions or native HTTP.
- **Security-enabled clusters need `http.cors.allow-credentials: true`.** If your cluster has basic auth, also set this flag; otherwise the `Authorization` header is stripped.
- **`allow-origin` must match exactly.** Using `"*"` works for public clusters but is not compatible with `allow-credentials: true` (browsers block credential + wildcard CORS). Set the exact Elasticvue URL instead.
- **Elasticvue does not manage Elasticsearch** — it is read/write UI only. Cluster config, index lifecycle policies, and user management (beyond what the query editor supports) still require Kibana, OpenSearch Dashboards, or direct REST calls.
- **Connection config lives in browser localStorage.** Clearing browser data removes saved clusters. Use `ELASTICVUE_CLUSTERS` env var or the JSON volume mount to restore connections automatically on next container start.
- **Elasticsearch 8.x defaults to TLS + security enabled.** Local dev setups should set `xpack.security.enabled=false` and `xpack.security.http.ssl.enabled=false` to avoid TLS cert errors when connecting from the UI. In production, configure the cluster cert and use `https://` in the cluster URI.

## Upstream docs

README and full feature overview: <https://github.com/cars10/elasticvue>  
Docker Hub: <https://hub.docker.com/r/cars10/elasticvue>  
Building for self-hosting: <https://github.com/cars10/elasticvue/wiki/Building-Elasticvue>
