---
name: zincsearch
description: ZincSearch recipe for open-forge. Lightweight full-text search engine with an Elasticsearch-compatible API. Single Go binary, no external dependencies, built-in web UI. Focused on app search (adding search to your application or site) — not log analytics.
---

# ZincSearch

Lightweight full-text search engine with an Elasticsearch-compatible API. Written in Go, using bluge as the indexing library. Upstream: <https://github.com/zincsearch/zincsearch>. Docs: <https://zincsearch-docs.zinc.dev/>.

ZincSearch is a single binary with no external dependencies (storage is local disk), a built-in Vue.js web UI, and built-in authentication. It is schema-less — no index mapping needs to be defined before ingesting documents. The API is compatible with Elasticsearch single-record and bulk ingestion endpoints, making it a drop-in for apps already using Elasticsearch client libraries.

> **Scope:** ZincSearch is an **app search** tool — it's designed for adding search to a website or application. For **log search / observability** (structured log ingestion, dashboards, alerting), use OpenObserve or Grafana Loki instead.

> ⚠️ **Maintenance status**: ZincSearch latest release is **v0.4.10 (January 2024)**. The project appears to be in low-activity / maintenance mode. For new projects, evaluate alternatives. Existing deployments continue to work.

| | |
|---|---|
| **License** | Apache 2.0 |
| **Stars** | ~16 K |
| **GitHub** | <https://github.com/zincsearch/zincsearch> |
| **Docs** | <https://zincsearch-docs.zinc.dev/> |

## Compatible install methods

| Method | Upstream docs | First-party? | When to use |
|---|---|---|---|
| Docker (single container) | <https://zincsearch-docs.zinc.dev/> | ✅ | Easiest path. One command, persistent volume. |
| Docker Compose | <https://zincsearch-docs.zinc.dev/> | ✅ | Preferred for production — explicit volume and restart policy. |
| Binary (Linux/macOS) | <https://zincsearch-docs.zinc.dev/> | ✅ | Bare-metal or VM installs without Docker. |

## Inputs to collect

Phase-keyed prompts. Ask at the phase where each is needed.

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | Options: `Docker Compose` / `Docker (single container)` / `Binary` | Drives which method section loads. |
| infra | "Where should ZincSearch store its index data? (default: `/var/lib/zincsearch`)" | Free-text | All methods. Set as `ZINC_DATA_PATH`. |
| software | "Admin username for ZincSearch?" | Free-text | All methods. Set as `ZINC_FIRST_ADMIN_USER` on first run. |
| software | "Admin password for ZincSearch? (min 8 chars, must be complex)" | Free-text (sensitive) | All methods. Set as `ZINC_FIRST_ADMIN_PASSWORD` on first run. Note: these vars only take effect on first start — see Gotchas. |
| software | "HTTP port? (default: 4080)" | Free-text | All methods. Set as `ZINC_SERVER_PORT`. |

After each prompt, write the value into the state file under `inputs.*`.

## Software-layer concerns

### Key ports

| Port | Protocol | Purpose |
|---|---|---|
| 4080 | TCP | HTTP — web UI and REST API (default) |

### Key environment variables

| Variable | Description | Default |
|---|---|---|
| `ZINC_FIRST_ADMIN_USER` | Admin username — **only read on first run** | (none) |
| `ZINC_FIRST_ADMIN_PASSWORD` | Admin password — **only read on first run** | (none) |
| `ZINC_DATA_PATH` | Directory where index data is stored | `/var/lib/zincsearch` |
| `ZINC_SERVER_PORT` | HTTP port | `4080` |
| `GIN_MODE` | Set to `release` to disable debug logging in production | `debug` |

### Data directory

ZincSearch stores all index data in `ZINC_DATA_PATH`. No external database or cache is required.

### Web UI

Accessible at `http://<host>:4080` after startup.

### API endpoints (Elasticsearch-compatible)

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/<index>/_doc` | POST | Index a single document |
| `/api/<index>/_bulk` | POST | Bulk ingest documents |
| `/api/<index>/_search` | GET / POST | Search an index |

### Docker (single container)

```bash
docker run -d \
  -p 4080:4080 \
  -e ZINC_FIRST_ADMIN_USER=admin \
  -e ZINC_FIRST_ADMIN_PASSWORD=Complexpass#123 \
  -v /tmp/zincsearch:/var/lib/zincsearch \
  --name zincsearch \
  public.ecr.aws/zinclabs/zincsearch:0.4.10
```

### Docker Compose

```yaml
services:
  zincsearch:
    image: public.ecr.aws/zinclabs/zincsearch:0.4.10
    ports:
      - "4080:4080"
    environment:
      ZINC_FIRST_ADMIN_USER: admin
      ZINC_FIRST_ADMIN_PASSWORD: Complexpass#123
      ZINC_DATA_PATH: /var/lib/zincsearch
    volumes:
      - zincsearch-data:/var/lib/zincsearch
    restart: unless-stopped

volumes:
  zincsearch-data:
```

## Upgrade procedure

**Docker Compose:**

```bash
docker pull public.ecr.aws/zinclabs/zincsearch:0.4.10
docker compose up -d
```

Index data in the named volume persists across image updates.

## Gotchas

- **`ZINC_FIRST_ADMIN_USER` and `ZINC_FIRST_ADMIN_PASSWORD` only take effect on first run.** These environment variables are read once when ZincSearch initialises an empty data directory. If you change them after the first start, nothing happens — the original credentials remain. To change the admin password after first run, use the web UI's admin settings.
- **Image is on AWS ECR, not Docker Hub.** The registry is `public.ecr.aws/zinclabs/zincsearch` — not `zincsearch/zincsearch` or `docker.io/zinclabs/zincsearch`. Pull works without credentials (`docker pull public.ecr.aws/zinclabs/zincsearch:0.4.10`), but tooling that assumes Docker Hub by default will fail unless you specify the full registry prefix.
- **Single-node only — no clustering or HA.** ZincSearch has no distributed mode. All data lives on one node. For high-availability or distributed search requirements, use Elasticsearch or OpenSearch instead.
- **Designed for app search, not log analytics.** ZincSearch is optimised for document search (product catalogs, site search, knowledge bases). It is not designed for high-volume structured log ingestion, time-series queries, or observability dashboards. For log search, use OpenObserve or Grafana Loki.
- **No persistent query history or saved searches in the UI.** Searches in the web UI are ephemeral — there is no saved-search or query-history feature. Results disappear on page refresh.

## Links

- GitHub: <https://github.com/zincsearch/zincsearch>
- Docs: <https://zincsearch-docs.zinc.dev/>
- Docker image (AWS ECR): `public.ecr.aws/zinclabs/zincsearch:0.4.10`
- Elasticsearch bulk API (compatible): <https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html>
- OpenObserve (log search alternative): <https://github.com/openobserve/openobserve>
