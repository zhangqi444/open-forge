---
name: thanos
description: Thanos recipe for open-forge. CNCF project that adds highly-available, long-term storage and global query view on top of existing Prometheus deployments.
---

# Thanos

CNCF Incubating project that extends Prometheus with unlimited long-term metric storage (via object storage), global query view across multiple Prometheus instances, and HA deduplication. Drop-in sidecar for existing Prometheus setups. Upstream: <https://github.com/thanos-io/thanos>. Docs: <https://thanos.io/tip/thanos/getting-started.md/>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (sidecar pattern) | Single-cluster; Thanos sidecar per Prometheus instance |
| Helm (kube-thanos) | Kubernetes; production multi-cluster |
| Binary | Bare-metal / custom orchestration |

## Architecture overview

Thanos is a set of composable components:

| Component | Role |
|---|---|
| `sidecar` | Runs next to Prometheus; uploads blocks to object storage |
| `store` | Serves historical data from object storage |
| `query` | Global PromQL query frontend across sidecars + store |
| `compactor` | Compacts and downsamples old blocks in object storage |
| `ruler` | Evaluates recording/alerting rules globally |
| `receive` | Accepts remote_write; enables push-based ingestion |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Object storage provider?" | S3, GCS, Azure Blob, MinIO, etc. |
| preflight | "S3 bucket name / endpoint / credentials?" | For sidecar + store + compactor config |
| preflight | "Existing Prometheus endpoint(s)?" | Sidecar attaches to each Prometheus instance |

## Docker Compose (sidecar + query + store)

```yaml
version: "3.9"
services:
  prometheus:
    image: prom/prometheus:latest
    command:
      - --storage.tsdb.min-block-duration=2h
      - --storage.tsdb.max-block-duration=2h   # required for Thanos sidecar
      - --web.enable-lifecycle
    volumes:
      - prom-data:/prometheus
      - ./prometheus.yml:/etc/prometheus/prometheus.yml

  thanos-sidecar:
    image: quay.io/thanos/thanos:v0.41.0
    command:
      - sidecar
      - --tsdb.path=/prometheus
      - --prometheus.url=http://prometheus:9090
      - --objstore.config-file=/etc/thanos/bucket.yml
    volumes:
      - prom-data:/prometheus
      - ./bucket.yml:/etc/thanos/bucket.yml

  thanos-store:
    image: quay.io/thanos/thanos:v0.41.0
    command:
      - store
      - --objstore.config-file=/etc/thanos/bucket.yml
      - --data-dir=/var/thanos/store
    volumes:
      - ./bucket.yml:/etc/thanos/bucket.yml
      - thanos-store-data:/var/thanos/store

  thanos-query:
    image: quay.io/thanos/thanos:v0.41.0
    command:
      - query
      - --store=thanos-sidecar:10901
      - --store=thanos-store:10901
    ports:
      - "10902:10902"

  thanos-compactor:
    image: quay.io/thanos/thanos:v0.41.0
    command:
      - compactor
      - --objstore.config-file=/etc/thanos/bucket.yml
      - --data-dir=/var/thanos/compactor
      - --wait
    volumes:
      - ./bucket.yml:/etc/thanos/bucket.yml
      - thanos-compactor-data:/var/thanos/compactor

volumes:
  prom-data:
  thanos-store-data:
  thanos-compactor-data:
```

### S3/MinIO bucket.yml example

```yaml
type: S3
config:
  bucket: thanos
  endpoint: minio:9000
  access_key: minioadmin
  secret_key: minioadmin
  insecure: true
```

## Software-layer concerns

- Docker image: `quay.io/thanos/thanos` (quay.io, not Docker Hub)
- Prometheus **must** have `--storage.tsdb.min-block-duration=2h` and `--storage.tsdb.max-block-duration=2h` for sidecar block upload to work
- Thanos Query port: `10902` (HTTP UI + PromQL), `10901` (gRPC store API)
- Compactor must run as a **singleton** — running multiple compactors against the same bucket corrupts data
- Downsampling: compactor generates 5m and 1h resolution blocks for fast long-range queries

## Upgrade procedure

1. Pull new images: `docker compose pull`
2. Update sidecar + Prometheus together (sidecar version must match or exceed Prometheus version)
3. Compactor handles block migration automatically on next run

## Gotchas

- **Prometheus block duration**: must be exactly 2h for sidecar; changing after data exists requires re-ingestion
- **Single compactor**: only one compactor instance per bucket — use Kubernetes job or cron, not a long-running replica set > 1
- Object storage costs add up with high-cardinality metrics — enable downsampling and retention policies in compactor
- `quay.io/thanos/thanos` is the canonical image; Docker Hub mirror (`thanosio/thanos`) is secondary

## Links

- GitHub: <https://github.com/thanos-io/thanos>
- Getting started: <https://thanos.io/tip/thanos/getting-started.md/>
- Design: <https://thanos.io/tip/thanos/design.md/>
