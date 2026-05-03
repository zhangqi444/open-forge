# Eonvelope

> Self-hostable email archive — continuously fetches and preserves emails from IMAP, POP, Exchange, or JMAP accounts with search, filtering, import/export, and integrations with Paperless-ngx, Searxng, and Grafana.

**URL:** https://dacid99.gitlab.io/eonvelope
**Source:** https://github.com/Dacid99/Eonvelope (mirror) / https://gitlab.com/Dacid99/eonvelope (canonical)
**License:** AGPL-3.0-or-later (code); CC BY-SA 4.0 (docs)

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker Compose | Official image: `dacid99/eonvelope:latest`; requires MariaDB |
| Any   | Podman | Same compose file, replace `docker` with `podman` |
| Kubernetes | Kubernetes manifests | Example cluster config in `docker/kubernetes/minimal/` |

## Inputs to Collect

### Provision phase
- Domain / public URL (for `ALLOWED_HOSTS`)
- MariaDB credentials

### Deploy phase
- `SECRET_KEY` — Django secret key (generate with `openssl rand -base64 50`; required)
- `DJANGO_SUPERUSER_PASSWORD` — initial admin password
- `ALLOWED_HOSTS` — comma-separated hostnames/IPs the app is served from (e.g. `localhost,eonvelope.example.com`)
- `DATABASE` / `DATABASE_USER` / `DATABASE_PASSWORD` — must match MariaDB config
- Email account credentials (configured after deployment via the web UI or API)

## Software-layer Concerns

### Docker Compose (minimal)
```yaml
services:
  db:
    image: mariadb:latest
    container_name: eonvelope-db
    restart: unless-stopped
    volumes:
      - ./mysql:/var/lib/mysql
    environment:
      - MARIADB_DATABASE=email_archive_django
      - MARIADB_USER=user
      - MARIADB_PASSWORD=passwd
      - MARIADB_ROOT_PASSWORD=example
    healthcheck:
      test: ["CMD-SHELL", "mariadb -u$$MARIADB_USER -p$$MARIADB_PASSWORD -e 'SELECT 1'"]
      interval: 10s
      timeout: 5s
      retries: 12
      start_period: 10s

  web:
    image: dacid99/eonvelope:latest
    container_name: eonvelope-web
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "1122:443"
    volumes:
      - ./archive:/mnt/archive
      - ./log:/var/log/eonvelope
    environment:
      - DATABASE=email_archive_django
      - DATABASE_USER=user
      - DATABASE_PASSWORD=passwd
      - DJANGO_SUPERUSER_PASSWORD=CHANGE_ME
      - SECRET_KEY=PLEASE_REPLACE_WITH_RANDOM_VALUE
      - ALLOWED_HOSTS=localhost,eonvelope.example.com
```

### Config / env vars
- `SECRET_KEY`: Django secret key (required; generate securely)
- `DJANGO_SUPERUSER_PASSWORD`: initial superuser password
- `ALLOWED_HOSTS`: comma-separated allowed hostnames
- `DATABASE` / `DATABASE_USER` / `DATABASE_PASSWORD`: MariaDB connection details (must match `db` service)
- Advanced config and all options: [ReadTheDocs](https://eonvelope.readthedocs.io/latest/)

### Data dirs
- `./mysql` → `/var/lib/mysql` — MariaDB database
- `./archive` → `/mnt/archive` — archived email storage
- `./log` → `/var/log/eonvelope` — application logs

### Default ports
- `1122` (host) → `443` (container HTTPS) — the container serves HTTPS with a default self-signed certificate

## Upgrade Procedure
```bash
docker compose pull
docker compose up -d
```
Back up the MariaDB volume and archive directory before upgrading.

## Gotchas
- **HTTPS only** — the container exposes port 443 (HTTPS) with a built-in default certificate; access via `https://` not `http://`.
- **Service name `db` must not change** — the `web` service connects to `db` by name; renaming the database service will break connectivity.
- **`db:` key is fixed** — the compose file requires the database service to be named exactly `db`.
- Email accounts are added via the web UI after initial deploy; credentials are NOT set via environment variables.
- Supports IMAP, POP, Exchange (EWS), and JMAP mail protocols.
- **Slim mode** available for low-spec systems (see docs).
- Django `SECRET_KEY` must be a long random string; never reuse across instances or commit to version control.
- Integrates with Paperless-ngx, Searxng, and Grafana (see docs for connector configuration).

## Links
- [README](https://github.com/Dacid99/Eonvelope/blob/main/README.md)
- [Full documentation (ReadTheDocs)](https://eonvelope.readthedocs.io/latest/)
- [Docker Compose — minimal](https://github.com/Dacid99/Eonvelope/blob/main/docker/docker-compose.minimal.yml)
- [Kubernetes example](https://github.com/Dacid99/Eonvelope/tree/main/docker/kubernetes/minimal)
- [Docker Hub — dacid99/eonvelope](https://hub.docker.com/r/dacid99/eonvelope)
