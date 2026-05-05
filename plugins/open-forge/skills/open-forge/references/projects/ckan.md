# CKAN

The world's leading open-source data portal platform. CKAN makes it easy to publish, share and work with open data — providing dataset cataloging, metadata management, a rich search interface, data preview, and a full REST API. Used by governments, NGOs, and research institutions worldwide.

**Official site:** https://ckan.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (ckan-docker) | Recommended; official ckan-docker repo |
| Ubuntu 20.04/22.04 | Native package install | Official DEB packages available |
| Kubernetes | Helm (community) | Community Helm charts available |
| Cloud VPS | Docker Compose | Standard production deployment |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain name and TLS config (Nginx included in ckan-docker)
- PostgreSQL — bundled in compose or external managed DB
- Solr — bundled in compose (CKAN uses a custom Solr schema)
- File storage: local or cloud (S3/Azure Blob via ckanext-cloudstorage)
- SMTP config for user registration and notifications

### Phase 2 — Deployment
- `CKAN_SITE_URL` — public-facing URL
- `CKAN_SYSADMIN_NAME` / `CKAN_SYSADMIN_PASSWORD` / `CKAN_SYSADMIN_EMAIL`
- PostgreSQL connection string
- `CKAN_SECRET_KEY` — random secret for session signing
- `TZ` — timezone

---

## Software-Layer Concerns

### Docker Compose (ckan-docker)

```bash
git clone https://github.com/ckan/ckan-docker.git
cd ckan-docker
cp .env.example .env
# Edit .env with your settings, then:
docker compose up -d --build
```

The stack includes: CKAN, PostgreSQL, Solr (custom schema), Redis, DataPusher, and Nginx.

### Key `.env` Variables
| Variable | Purpose |
|----------|---------|
| `CKAN_SITE_URL` | Public URL (e.g. `https://data.example.com`) |
| `CKAN_SYSADMIN_NAME` | Admin username |
| `CKAN_SYSADMIN_PASSWORD` | Admin password |
| `CKAN_SYSADMIN_EMAIL` | Admin email |
| `CKAN_SECRET_KEY` | Session secret (use `openssl rand -hex 32`) |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | DB credentials |
| `NGINX_SSLPORT_HOST` | Host port for HTTPS (default `8443`) |
| `DATAPUSHER_VERSION` | DataPusher image tag |
| `TZ` | Container timezone |

### Services in the Compose Stack
| Service | Purpose |
|---------|---------|
| `ckan` | Main application (Python/Flask) |
| `db` | PostgreSQL database |
| `solr` | Search index (custom CKAN schema) |
| `redis` | Task queue backend |
| `datapusher` | Pushes tabular data to DataStore |
| `nginx` | Reverse proxy with SSL termination |

### Configuration Paths
- `/etc/ckan/default/ckan.ini` — main CKAN config (inside container)
- `/var/lib/ckan/` — file uploads storage
- Extensions installed via pip into the container

---

## Upgrade Procedure

```bash
# Pull latest images
docker compose pull
docker compose up -d --build

# Run DB migrations (inside ckan container)
docker compose exec ckan ckan db upgrade
docker compose exec ckan ckan search-index rebuild
```

Always review the [CKAN changelog](https://docs.ckan.org/en/latest/changelog.html) before upgrading — major versions may require schema migrations and Solr reindex.

---

## Gotchas

- **Custom Solr schema required** — CKAN uses its own Solr schema; do not use a stock Solr image. The `ckan-docker` compose uses `ckan/ckan-solr` which includes the correct schema.
- **DataPusher is separate** — tabular data preview (`DataStore` extension) requires the DataPusher service to be running.
- **Extensions installed at build time** — the standard workflow is to add extensions to `ckan/docker/preinstall.sh` and rebuild the image.
- **File uploads need persistent volume** — map `/var/lib/ckan/` to a named volume or bind mount.
- **First-run setup:** After `docker compose up`, the sysadmin account is created automatically from `.env` variables.
- **Port exposure:** Nginx listens on `NGINX_SSLPORT_HOST` (default 8443) — change to 443 for production.

---

## References
- GitHub: https://github.com/ckan/ckan
- ckan-docker: https://github.com/ckan/ckan-docker
- Docs: https://docs.ckan.org/
- Extensions: https://extensions.ckan.org/
- Changelog: https://docs.ckan.org/en/latest/changelog.html
