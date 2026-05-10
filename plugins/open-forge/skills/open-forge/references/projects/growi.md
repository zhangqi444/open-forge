---
name: growi
description: "Team wiki and knowledge-base platform using markdown. Supports simultaneous multi-user editing, LDAP/AD/OAuth/SAML SSO, Slack/Mattermost integration, hierarchical pages, and full-text search via Elasticsearch. Docker Compose with MongoDB + Elasticsearch. MIT license."
---

# GROWI

**Team collaboration wiki built on markdown.** Create hierarchical pages with Markdown, edit simultaneously with multiple people, and search everything with Elasticsearch full-text search. Supports LDAP/Active Directory, OAuth2, and SAML SSO; integrates with Slack and Mattermost; optional PlantUML diagrams and MathJax. MIT license.

- Upstream repo: <https://github.com/growilabs/growi>
- Docs: <https://docs.growi.org>
- Docker Compose repo: <https://github.com/growilabs/growi-docker-compose>
- Docker Hub: <https://hub.docker.com/r/growilabs/growi>
- Latest release: v7.5.2

## Architecture in one minute

- **GROWI app** container (Node.js) — listens on port **3000**
- **MongoDB** — primary datastore for pages, users, settings
- **Elasticsearch** — full-text search index (required for search; can be omitted for minimal setups with degraded search)
- **pdf-converter** sidecar — converts wiki pages to PDF for bulk export
- File uploads: MongoDB GridFS (default), local filesystem, or S3-compatible storage
- Resource: moderate — Elasticsearch alone needs ≥256 MB heap; recommend ≥2 GB RAM total

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| **Docker Compose** | `docker compose up -d` | **Primary** — upstream-maintained compose repo |
| **Helm (Experimental)** | Helm chart | `weseek/helm-charts` — community-maintained, experimental |
| **On-premise (manual)** | Node.js + npm | Ubuntu/CentOS with MongoDB + Elasticsearch installed separately |

## Inputs to collect

| Input | Example | Phase | Notes |
|---|---|---|---|
| App port | `3000` | Network | Host port for GROWI web UI |
| `MONGO_URI` | `mongodb://mongo:27017/growi` | Database | MongoDB connection URI |
| `ELASTICSEARCH_URI` | `http://elasticsearch:9200/growi` | Search | Elasticsearch URI; omit to disable full-text search |
| `PASSWORD_SEED` | (random 32+ chars) | Security | Secret used to hash passwords — **never change after first run** |
| `FILE_UPLOAD` | `mongodb` / `local` / `aws` | Storage | Where file attachments are stored (default: AWS S3 if `AWS_*` vars set) |
| `SECRET_TOKEN` | (random 64 chars) | Security | Express session secret |
| `APP_SITE_URL` | `https://wiki.example.com` | Network | Public URL of the GROWI instance |
| ES memory | `256m`–`512m` | Resources | `ES_JAVA_OPTS` heap size; increase if search is slow |

## Install via Docker Compose

```yaml
# docker-compose.yml — based on upstream growi-docker-compose (v7.x)
# Clone: git clone https://github.com/growilabs/growi-docker-compose
version: '3'

services:
  app:
    image: growilabs/growi:7
    ports:
      - "127.0.0.1:3000:3000"    # bind to localhost; front with a reverse proxy for TLS
    depends_on:
      mongo:
        condition: service_healthy
      elasticsearch:
        condition: service_healthy
    environment:
      - MONGO_URI=mongodb://mongo:27017/growi
      - ELASTICSEARCH_URI=http://elasticsearch:9200/growi
      - BULK_EXPORT_PDF_CONVERTER_URI=http://pdf-converter:3010
      - PASSWORD_SEED=changeme_use_random_string
      # File upload destination (choose one):
      # - FILE_UPLOAD=mongodb    # store in MongoDB GridFS
      # - FILE_UPLOAD=local      # store in local /data volume
    entrypoint: "/docker-entrypoint.sh"
    command: ["npm run migrate && node -r dotenv-flow/config --expose_gc dist/server/app.js"]
    restart: unless-stopped
    volumes:
      - growi_data:/data
      - page_bulk_export_tmp:/tmp/page-bulk-export

  mongo:
    image: mongo:8.2
    restart: unless-stopped
    volumes:
      - mongo_configdb:/data/configdb
      - mongo_db:/data/db
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.runCommand('ping').ok", "--quiet"]
      interval: 10s
      timeout: 5s
      retries: 6

  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:9.3.3
    environment:
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms256m -Xmx256m"
      - LOG4J_FORMAT_MSG_NO_LOOKUPS=true
    ulimits:
      memlock:
        soft: -1
        hard: -1
    restart: unless-stopped
    volumes:
      - es_data:/usr/share/elasticsearch/data
      - ./elasticsearch/v9/config/elasticsearch.yml:/usr/share/elasticsearch/config/elasticsearch.yml
      - ./elasticsearch/v9/config/elasticsearch-plugins.yml:/usr/share/elasticsearch/config/elasticsearch-plugins.yml
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9200"]
      interval: 10s
      timeout: 5s
      retries: 6

  pdf-converter:
    image: growilabs/pdf-converter:1
    restart: unless-stopped
    volumes:
      - page_bulk_export_tmp:/tmp/page-bulk-export

volumes:
  growi_data:
  mongo_configdb:
  mongo_db:
  es_data:
  page_bulk_export_tmp:
```

**Recommended quickstart via upstream compose repo:**

```bash
git clone https://github.com/growilabs/growi-docker-compose
cd growi-docker-compose
# Edit docker-compose.yml: set PASSWORD_SEED to a random string
docker compose up -d
```

Visit `http://localhost:3000`. GROWI redirects to the setup wizard on first boot.

## First boot

1. Navigate to `http://localhost:3000` — GROWI shows the initial setup wizard.
2. Create the first admin account.
3. Configure site title, file upload method, and optional SSO/OAuth settings.
4. Rebuild the Elasticsearch index after the first content is added: **Admin → Search → Normalize indices**.

## Software-layer concerns

### Key environment variables

| Variable | Default | Description |
|---|---|---|
| `MONGO_URI` | (required) | MongoDB connection string |
| `ELASTICSEARCH_URI` | (optional) | Elasticsearch URI; omit to disable full-text search |
| `PASSWORD_SEED` | (required) | Password hash salt — set once at install and never change |
| `SECRET_TOKEN` | auto-generated | Express session secret |
| `FILE_UPLOAD` | `aws` (if S3 vars set) | `mongodb`, `local`, `aws`, or `gcs` |
| `APP_SITE_URL` | (optional) | Canonical URL; required for OAuth callback URLs to work |
| `FORCE_WIKI_MODE` | unset | `public` or `private`; forces all pages to be one mode |
| `MATHJAX` | `0` | Set to `1` to enable MathJax math rendering |
| `PLANTUML_URI` | points to public plantuml.com | Override to use a self-hosted PlantUML server |

### Data directories (inside container)

| Path | Contents |
|---|---|
| `/data` | GROWI app data (file uploads when `FILE_UPLOAD=local`, exports) |
| `/tmp/page-bulk-export` | Temporary PDF export files (shared with pdf-converter) |

### MongoDB

GROWI's primary datastore. Collections include: pages, users, groups, configs, revisions, comments, tags. The `mongo` volume (`/data/db`) is the critical backup target.

### Elasticsearch

Full-text search index. The index is **rebuilt automatically** from MongoDB data; the ES volume (`es_data`) does not need to be in backups (but losing it means a slow re-index on restore). Elasticsearch 8.x and 9.x are both supported; see compose config for version-specific config file paths.

Required Elasticsearch plugins (auto-installed via `elasticsearch-plugins.yml`):
- `analysis-kuromoji` (Japanese morphological analysis)
- `analysis-icu` (Unicode normalization)

These plugins are required regardless of language settings.

## Upgrade

```bash
# From the growi-docker-compose directory:
docker compose pull
docker compose up -d
```

GROWI auto-runs database migrations on startup (`npm run migrate` in the entrypoint command). Check the [changelog](https://github.com/growilabs/growi/releases) before major version upgrades.

When upgrading Elasticsearch to a new major version (e.g., 8.x → 9.x):
1. Update the image tag in `docker-compose.yml`
2. Update the config file mount path (`./elasticsearch/v9/` vs `./elasticsearch/v8/`)
3. Rebuild the search index after the upgrade: **Admin → Search → Normalize indices**

## Gotchas

- **`PASSWORD_SEED` is write-once**: changing it after users exist will invalidate all stored password hashes — every user will need to reset their password. Set it to a random string before the first run.
- **Elasticsearch plugins are required**: `analysis-kuromoji` and `analysis-icu` must be installed. The upstream `elasticsearch-plugins.yml` handles this automatically if mounted correctly; if you skip the mount, search will fail at index creation.
- **`bootstrap.memory_lock: true` requires `ulimits.memlock: -1`**: without the ulimits block, Elasticsearch will fail to start with a "Unable to lock JVM memory" error.
- **Port 3000 is bound to `127.0.0.1` in the upstream compose file**: GROWI is designed to sit behind a reverse proxy (nginx, Caddy, Traefik). Change to `0.0.0.0:3000:3000` only if you're adding a proxy layer in front.
- **Full-text search index needs to be rebuilt after initial data import**: GROWI doesn't automatically re-index when pages are imported via bulk restore; trigger re-index from **Admin → Search**.
- **Helm chart is experimental**: the `weseek/helm-charts` Helm chart is community-maintained and may lag behind upstream releases.

## Links

- Upstream README: <https://github.com/growilabs/growi/blob/master/README.md>
- Admin guide (EN): <https://docs.growi.org/en/admin-guide/>
- Environment variables reference: <https://docs.growi.org/en/admin-guide/admin-cookbook/env-vars.html>
- Docker Compose repo: <https://github.com/growilabs/growi-docker-compose>
