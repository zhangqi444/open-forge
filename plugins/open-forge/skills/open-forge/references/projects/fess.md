---
name: fess
description: Fess recipe for open-forge. Powerful and easily deployable Enterprise Search Server. Based on OpenSearch/Elasticsearch with a built-in crawler for web, filesystem, and data store sources. Administration GUI, API, and embeddable site search widget. Source: https://github.com/codelibs/fess
---

# Fess

Powerful and easily deployable Enterprise Search Server built on OpenSearch. Includes a crawler that indexes web pages, file systems, and data stores (databases, CSV, S3, etc.). Ships with an administration GUI for configuration, a search UI, and a REST/JSON API. Supports many document formats (PDF, Office, etc.). Can replace Google Site Search (FSS JS Generator embeds search into external sites). Docker Compose deployment uses separate OpenSearch and Fess containers. Upstream: https://github.com/codelibs/fess. Website: https://fess.codelibs.org/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose | Linux | Recommended. Fess + OpenSearch as separate services. |
| ZIP distribution | Linux / macOS / Windows | Java 21+ required. Unzip and run. |
| DEB / RPM package | Debian / Ubuntu / RHEL | From GitHub releases |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Java version?" | Java 21+ required (ZIP/package installs) |
| deploy | "Memory for OpenSearch?" | Default: 1 GB JVM heap. Increase for large indexes. |
| config | "Web crawl target URLs?" | Configured in Admin UI after install |
| config | "File system paths to crawl?" | Configured in Admin UI |
| optional | "LLM for AI/RAG chat?" | Optional: Ollama (local), Gemini, or OpenAI via compose overlays |

## Software-layer concerns

### Docker Compose (recommended)

  # Get the compose files from the docker-fess repository:
  git clone https://github.com/codelibs/docker-fess.git
  cd docker-fess/compose

  # Start Fess with OpenSearch 3:
  docker compose -f compose.yaml -f compose-opensearch3.yaml up -d

  # compose.yaml — Fess application:
  #   image: ghcr.io/codelibs/fess:15.6.1
  #   port: 8080:8080
  #   env: SEARCH_ENGINE_HTTP_URL=http://search01:9200

  # compose-opensearch3.yaml — OpenSearch backend:
  #   image: ghcr.io/codelibs/fess-opensearch:3.6.0
  #   port: 9200:9200
  #   JVM heap: 1 GB (set via OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g)

  # With Dashboards (OpenSearch visualization):
  docker compose -f compose.yaml -f compose-opensearch3.yaml -f compose-dashboards3.yaml up -d

  # With MinIO (object storage crawling):
  docker compose -f compose.yaml -f compose-opensearch3.yaml -f compose-minio.yaml up -d

  # With Ollama LLM (AI/RAG Chat, requires NVIDIA GPU):
  docker compose -f compose.yaml -f compose-opensearch3.yaml -f compose-ollama.yaml up -d
  docker exec -it ollama01 ollama pull gemma4:e4b

  # With Google Gemini (cloud LLM for AI/RAG):
  docker compose -f compose.yaml -f compose-opensearch3.yaml -f compose-gemini.yaml up -d

  # With OpenAI (cloud LLM for AI/RAG):
  docker compose -f compose.yaml -f compose-opensearch3.yaml -f compose-openai.yaml up -d

### ZIP distribution install

  # Prerequisites: Java 21+
  java -version

  # Download from: https://github.com/codelibs/fess/releases
  unzip fess-15.6.x.zip
  cd fess-15.6.x

  # Start (also starts embedded OpenSearch):
  ./bin/fess

  # Access at: http://localhost:8080/

### Browser access

  Search UI:  http://localhost:8080/
  Admin UI:   http://localhost:8080/admin/
  # Default admin credentials: admin / admin (change immediately!)

### Configure crawling (Admin UI)

  # After logging in to Admin UI:
  # 1. Web Crawling → Web Config → add target URLs
  # 2. File Crawling → File Config → add filesystem paths
  # 3. Scheduler → run "Default Crawler" to start indexing
  # 4. Crawling Jobs can be scheduled (cron syntax) or triggered manually

### Key environment variables (Docker)

  SEARCH_ENGINE_HTTP_URL   URL of OpenSearch (default: http://search01:9200)
  FESS_DICTIONARY_PATH     Path to OpenSearch dictionary files
  FESS_PLUGINS             Space-separated list of plugins to install on startup
                           e.g. "fess-webapp-semantic-search:15.6.0"

### OpenSearch memory

  # Edit compose-opensearch3.yaml to increase heap for large deployments:
  OPENSEARCH_JAVA_OPTS=-Xms2g -Xmx2g

  # Required ulimits (already set in compose):
  memlock: -1 / -1
  nofile: 65535 / 65535

### Embed Fess search in external sites (FSS)

  # Use the Fess Site Search (FSS) JavaScript generator:
  # https://fss-generator.codelibs.org/
  # Generates a snippet you embed in any HTML page to add Fess-powered search.

## Upgrade procedure

  # Docker Compose: update image tag in compose.yaml, then:
  docker compose -f compose.yaml -f compose-opensearch3.yaml pull
  docker compose -f compose.yaml -f compose-opensearch3.yaml up -d

  # ZIP: download new release, unzip alongside old, copy config:
  # cp old-fess/app/WEB-INF/classes/fess*.xml new-fess/app/WEB-INF/classes/
  # Then start new version.

## Gotchas

- **Change default admin password immediately**: the Admin UI defaults to `admin/admin`. Change it under Admin → General → Admin Password before exposing to any network.
- **OpenSearch memory lock**: the compose file sets `bootstrap.memory_lock=true` for OpenSearch. The host must allow unlimited memlock via ulimits (already set in compose).
- **Slow first startup**: OpenSearch takes 60–120 seconds to initialize on first run. Fess waits for it via healthcheck; the compose `depends_on` handles this automatically.
- **Security plugin disabled**: the compose file sets `DISABLE_SECURITY_PLUGIN=true` for OpenSearch — fine for LAN deployments but means no TLS between Fess and OpenSearch. For internet-exposed setups, enable the security plugin and use TLS.
- **Fess version ≠ OpenSearch version**: Fess has its own version (15.x) and requires a compatible OpenSearch version. Use the paired images from `docker-fess` compose files rather than mixing versions.
- **Dictionary files shared**: `FESS_DICTIONARY_PATH` must be the same volume path on both the Fess and OpenSearch containers. The compose files set this up correctly.

## References

- Upstream GitHub: https://github.com/codelibs/fess
- Docker compose repo: https://github.com/codelibs/docker-fess
- Website + documentation: https://fess.codelibs.org/
- Installation guide: https://fess.codelibs.org/15.6/install/index.html
- FSS site search generator: https://fss-generator.codelibs.org/
- Releases: https://github.com/codelibs/fess/releases
