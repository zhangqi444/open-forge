# Typesense

Fast, typo-tolerant, open-source search engine written in C++. A self-hostable alternative to Algolia. Designed for sub-50ms search latency on even billion-record datasets. Single binary with no external dependencies. 25K+ GitHub stars. Upstream: <https://github.com/typesense/typesense>. Docs: <https://typesense.org/docs/>.

Typesense listens on port `8108` by default. Single binary or Docker container. Data persists to a configurable data directory.

## Compatible install methods

Verified against upstream README at <https://github.com/typesense/typesense#install>.

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | `docker run -p 8108:8108 typesense/typesense:27.1` | ✅ | Simplest self-hosted path. |
| Docker Compose | See below | ✅ | Persistent production deployment. |
| Binary packages | <https://typesense.org/downloads> | ✅ | Linux/macOS bare-metal installs. |
| DEB/RPM packages | <https://typesense.org/downloads> | ✅ | Systemd-managed Linux service. |
| Typesense Cloud | <https://cloud.typesense.org> | ✅ (hosted) | Managed cluster — no infra to manage. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| api_key | "Typesense API key (used to authenticate all requests)?" | Free-text (sensitive) | All — **required** |
| port | "Port for Typesense?" | Number (default `8108`) | All |
| data_dir | "Data directory path?" | Free-text (default `/data`) | All |

## Software-layer concerns

### Docker quickstart

```bash
docker run -d \
  -p 8108:8108 \
  -v /path/to/typesense-data:/data \
  typesense/typesense:27.1 \
  --data-dir /data \
  --api-key=your-api-key-here \
  --enable-cors
```

### Docker Compose

```yaml
services:
  typesense:
    image: typesense/typesense:27.1
    restart: unless-stopped
    ports:
      - "8108:8108"
    volumes:
      - typesense_data:/data
    command: >
      --data-dir /data
      --api-key=${TYPESENSE_API_KEY}
      --enable-cors

volumes:
  typesense_data:
```

### Key flags / environment

Typesense is configured via CLI flags (passed to the binary or Docker command):

| Flag | Purpose | Notes |
|---|---|---|
| `--api-key` | Admin API key | **Required.** All requests authenticated with this. |
| `--data-dir` | Directory for data storage | **Required.** |
| `--listen-port` | Port to listen on | Default: `8108` |
| `--listen-address` | Bind address | Default: `0.0.0.0` |
| `--enable-cors` | Allow cross-origin requests | Needed for browser-side SDK |
| `--cors-domains` | Restrict CORS to specific domains | e.g. `https://myapp.com` |
| `--log-dir` | Directory for log files | Optional |
| `--ssl-certificate` | Path to TLS cert | For HTTPS termination at the binary |
| `--ssl-certificate-key` | Path to TLS key | For HTTPS termination at the binary |
| `--num-collections-parallel-load` | Parallel collection loading threads | For faster startup with many collections |

Alternatively, set flags as `TYPESENSE_*` environment variables:

```bash
TYPESENSE_API_KEY=your-key
TYPESENSE_DATA_DIR=/data
TYPESENSE_ENABLE_CORS=true
```

### Core concepts

| Concept | Description |
|---|---|
| **Collection** | A table/index — defines schema (field names + types) |
| **Document** | A record in a collection |
| **Search key** | A scoped read-only API key for client-side use (never expose admin key in frontend) |

### Quick API example

```bash
API_KEY="your-api-key"
BASE_URL="http://localhost:8108"

# Create a collection
curl -X POST "$BASE_URL/collections" \
  -H "X-TYPESENSE-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"products","fields":[{"name":"name","type":"string"},{"name":"price","type":"float"}],"default_sorting_field":"price"}'

# Index a document
curl -X POST "$BASE_URL/collections/products/documents" \
  -H "X-TYPESENSE-API-KEY: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name":"Widget","price":9.99}'

# Search
curl "$BASE_URL/collections/products/documents/search?q=widget&query_by=name" \
  -H "X-TYPESENSE-API-KEY: $API_KEY"
```

### Client libraries

Official clients: JavaScript, Python, PHP, Ruby, Go, Java, Swift, Dart.

```bash
npm install typesense           # JavaScript/TypeScript
pip install typesense           # Python
composer require php-http/guzzle7-adapter typesense/typesense-php  # PHP
```

### Typesense InstantSearch adapter

Drop-in replacement for Algolia's InstantSearch UI library:

```bash
npm install typesense-instantsearch-adapter
```

### High availability (cluster)

Run multiple Typesense nodes for HA using the Raft consensus protocol. Configure with `--nodes` pointing at peer nodes. See: <https://typesense.org/docs/guide/high-availability.html>.

### Data directories

| Path | Contents |
|---|---|
| `--data-dir` | Collection schemas, indexed documents, WAL |

## Upgrade procedure

1. Stop current container
2. Start new container with updated image tag, same `--data-dir`
3. Typesense migrates data automatically on startup

> **Note:** Check the migration guide for each major version: <https://typesense.org/docs/guide/updating-typesense.html>

## Gotchas

- **Admin API key ≠ search key.** Never expose the admin key in frontend code. Create scoped search-only API keys for client-side use: `POST /keys`.
- **Schema changes require re-indexing.** Adding/modifying fields on an existing collection requires dropping and re-creating it (or using the `alter` endpoint for compatible changes in v0.25+).
- **`--enable-cors` needed for browser SDKs.** Without it, browser-side API calls will be blocked by CORS.
- **Single binary, no external deps.** Unlike Elasticsearch, Typesense requires no JVM, no Kafka, no ZooKeeper. Just the binary and a data dir.
- **Port 8108 — memorable.** The default port `8108` is intentional — it's the year the first search engine was invented.
- **License: GPL v3** (self-hosted). Typesense Cloud uses a commercial license.

## Links

- Upstream: <https://github.com/typesense/typesense>
- Docs: <https://typesense.org/docs/>
- Downloads: <https://typesense.org/downloads>
- InstantSearch adapter: <https://github.com/typesense/typesense-instantsearch-adapter>
- High availability guide: <https://typesense.org/docs/guide/high-availability.html>
- API keys guide: <https://typesense.org/docs/latest/api/api-keys.html>
