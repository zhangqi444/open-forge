# Aleph

Document and data search platform for investigative journalists and researchers. Aleph lets you ingest documents, emails, databases, and structured data, then search across everything — including OCR'd PDFs and entity cross-referencing across datasets.

**Official site:** https://docs.alephdata.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux VPS / bare metal | Docker Compose | Primary supported deployment method |
| Kubernetes | Helm (community) | Community charts available; not officially maintained |
| Cloud (AWS/GCP) | Docker Compose on VM | Recommended for production with managed PostgreSQL/S3 |

---

## Inputs to Collect

### Phase 1 — Planning
- Storage backend: local filesystem or S3-compatible object storage
- Expected data volume (drives RAM/CPU sizing — Aleph is resource-heavy)
- Whether OCR is needed (requires additional config)
- OAuth provider for login (Google, Keycloak, etc.) or password auth

### Phase 2 — Deployment
- `ALEPH_SECRET_KEY` — random secret for session signing
- `ALEPH_APP_TITLE` — display name for your instance
- `ALEPH_APP_URL` — public URL
- PostgreSQL and Elasticsearch connection strings
- S3 bucket details (if using object storage)
- SMTP config for notifications (optional)

---

## Software-Layer Concerns

### Docker Compose

```yaml
version: "3.2"
services:
  postgres:
    image: postgres:10.0
    volumes:
      - postgres-data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: aleph
      POSTGRES_PASSWORD: aleph
      POSTGRES_DATABASE: aleph

  elasticsearch:
    image: ghcr.io/alephdata/aleph-elasticsearch:latest
    hostname: elasticsearch
    environment:
      - discovery.type=single-node
    volumes:
      - elasticsearch-data:/usr/share/elasticsearch/data

  redis:
    image: redis:alpine
    command: ["redis-server", "--save", "3600", "10"]
    volumes:
      - redis-data:/data

  ingest-file:
    image: ghcr.io/alephdata/ingest-file:latest
    volumes:
      - archive-data:/data
    depends_on:
      - postgres
      - redis
    env_file:
      - aleph.env

  worker:
    image: ghcr.io/alephdata/aleph:latest
    command: aleph worker
    restart: on-failure
    depends_on:
      - postgres
      - elasticsearch
      - redis
    env_file:
      - aleph.env

  api:
    image: ghcr.io/alephdata/aleph:latest
    command: gunicorn -w 4 -b 0.0.0.0:8000 aleph.wsgi:app
    ports:
      - "8000:8000"
    depends_on:
      - postgres
      - elasticsearch
    env_file:
      - aleph.env

volumes:
  postgres-data:
  elasticsearch-data:
  redis-data:
  archive-data:
```

### `aleph.env` Key Variables
| Variable | Purpose |
|----------|---------|
| `ALEPH_SECRET_KEY` | Random secret (use `openssl rand -hex 32`) |
| `ALEPH_APP_TITLE` | Instance name shown in UI |
| `ALEPH_APP_URL` | Public-facing URL |
| `ALEPH_DATABASE_URI` | PostgreSQL connection string |
| `ALEPH_ELASTICSEARCH_URI` | Elasticsearch endpoint |
| `ALEPH_ARCHIVE_TYPE` | `file` (local) or `s3` |
| `ALEPH_ARCHIVE_PATH` | Local path if `ARCHIVE_TYPE=file` |
| `ALEPH_OAUTH_*` | OAuth provider config for login |

### Configuration Paths
- `aleph.env` — main environment file
- `/data/` — document archive (local mode)

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
docker compose exec api aleph upgrade  # runs DB migrations
```

Always check the [changelog](https://github.com/alephdata/aleph/blob/main/CHANGELOG.md) before upgrading — Elasticsearch mappings may need re-indexing.

---

## Gotchas

- **Resource-heavy:** Elasticsearch alone needs 2–4 GB RAM minimum. Plan for 8+ GB total for a small instance.
- **Elasticsearch version is pinned** in the official compose — use the `ghcr.io/alephdata/aleph-elasticsearch` image, not stock Elasticsearch.
- **OCR requires Tesseract** — handled inside the `ingest-file` container; no extra setup needed.
- **Re-indexing after upgrades** can be time-consuming for large datasets: `docker compose exec api aleph reingest`.
- **No built-in reverse proxy** in the compose file — put Nginx/Caddy/Traefik in front.
- **S3 is strongly recommended** for production — local filesystem archive is not HA.

---

## References
- GitHub: https://github.com/alephdata/aleph
- Docs: https://docs.alephdata.org/
- Changelog: https://github.com/alephdata/aleph/blob/main/CHANGELOG.md
- GHCR images: https://github.com/alephdata/aleph/pkgs/container/aleph
