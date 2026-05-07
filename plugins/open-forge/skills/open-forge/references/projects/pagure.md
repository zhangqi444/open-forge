---
name: pagure
description: Pagure recipe for open-forge. Self-hosted Git forge written in Python/Flask with issues, pull requests, and CI hooks. GPL-2.0. Source: https://pagure.io/pagure
---

# Pagure

A lightweight, self-hosted Git forge written in Python (Flask). Provides Git repository hosting, issue tracking, pull requests, project wikis, and webhook/CI integrations. Used by the Fedora Project as its primary forge. GPL-2.0 licensed. Source: <https://pagure.io/pagure>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Fedora / RHEL / CentOS | RPM + systemd | Primary supported platform; packages in Fedora repos |
| Any Linux | Docker Compose | Community Docker setup available |
| Any Linux | Python venv + systemd | Manual install via pip |

> The Fedora/RPM path is the most thoroughly tested and documented upstream.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. git.example.com |
| "Admin email?" | Email | Used for account registration |
| "PostgreSQL or SQLite?" | postgres / sqlite | Postgres recommended for production |
| "Database host/name/user/pass?" | Strings | If PostgreSQL chosen |
| "Git repos storage path?" | Path | Where bare repositories are stored; default `/var/lib/pagure/repos` |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Secret key?" | Random string | Flask `SECRET_KEY` — generate with `python3 -c "import secrets; print(secrets.token_hex(32))"` |
| "Email (SMTP) host?" | Hostname | For notifications; can use localhost |
| "TLS?" | Yes / No | Handled by NGINX |
| "Enable Gitolite?" | Yes / No | Optional; provides SSH-based git push |

## Software-Layer Concerns

- **Python/Flask application**: Runs as a WSGI app behind Apache mod_wsgi or NGINX + uWSGI/gunicorn.
- **Database**: SQLite for dev/testing; PostgreSQL strongly recommended for multi-user production.
- **Alembic migrations**: Schema migrations run via `pagure-admin clean-pushes` and alembic — must be run after upgrades.
- **Redis required**: Pagure uses Redis for task queues (worker celery tasks) — install and run Redis before starting.
- **Celery workers**: Background task workers (`pagure_worker`) process webhooks, emails, and CI hooks — must be running alongside the web process.
- **Git repos directory**: Pagure manages bare Git repos on the filesystem; ensure the path is on a volume with sufficient space.
- **Secret key**: Must be set in `pagure.cfg`; losing it invalidates all sessions.
- **SMTP**: Used for email notifications; configure `SMTP_SERVER` in `pagure.cfg`.

## Deployment

### Fedora / RHEL (RPM — recommended)

```bash
# Install Pagure and dependencies
dnf install pagure pagure-ev pagure-milters pagure-webhook redis postgresql-server

# Initialize PostgreSQL
postgresql-setup --initdb
systemctl enable --now postgresql

# Create database
sudo -u postgres psql -c "CREATE USER pagure WITH PASSWORD 'changeme';"
sudo -u postgres psql -c "CREATE DATABASE pagure OWNER pagure;"

# Configure Pagure
cp /etc/pagure/pagure.cfg.sample /etc/pagure/pagure.cfg
vim /etc/pagure/pagure.cfg
# Set: DB_URL, SECRET_KEY, APP_URL, SMTP_SERVER, EVENTSOURCE_SOURCE, etc.

# Initialize database schema
pagure-admin setup-db

# Enable and start all services
systemctl enable --now redis
systemctl enable --now pagure pagure_worker pagure_ev
```

### Docker Compose (community)

```yaml
version: "3.8"
services:
  pagure:
    image: quay.io/pagure/pagure:latest
    environment:
      APP_URL: "https://git.example.com"
      SECRET_KEY: "changeme-use-random"
      DB_URL: "postgresql://pagure:changeme@db/pagure"
      REDIS_URL: "redis://redis:6379"
    ports:
      - "5000:5000"
    volumes:
      - pagure-repos:/var/lib/pagure/repos
      - pagure-docs:/var/lib/pagure/docs
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    environment:
      POSTGRES_USER: pagure
      POSTGRES_PASSWORD: changeme
      POSTGRES_DB: pagure
    volumes:
      - pg-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine

volumes:
  pagure-repos:
  pagure-docs:
  pg-data:
```

```bash
docker compose up -d
docker compose exec pagure pagure-admin setup-db
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name git.example.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Upgrade Procedure

### RPM

```bash
dnf upgrade pagure
systemctl stop pagure pagure_worker pagure_ev
# Run any pending Alembic migrations:
cd /usr/lib/python3*/site-packages/pagure && alembic upgrade head
systemctl start pagure pagure_worker pagure_ev
```

### Docker

```bash
docker compose pull
docker compose up -d
docker compose exec pagure alembic upgrade head
```

## Gotchas

- **Redis is mandatory**: Pagure will fail to start without Redis running; ensure it starts before Pagure.
- **Celery workers required**: Without `pagure_worker` running, webhooks, emails, and pull request actions silently fail.
- **Alembic migrations after upgrades**: Forgetting to run `alembic upgrade head` after a version bump causes database errors and 500s.
- **Gitolite for SSH push**: HTTP(S) push works out of the box; SSH push requires Gitolite to be configured separately — a significant additional setup step.
- **EVENTSOURCE_SOURCE**: Must be set to your server-sent events URL for live UI updates; typically `https://git.example.com/_evs/`.
- **PostgreSQL auth**: Ensure `pg_hba.conf` allows password auth for the `pagure` user (`md5` or `scram-sha-256`).
- **File upload size**: Pagure defaults to limiting attachment sizes; adjust `MAX_CONTENT_LENGTH` in `pagure.cfg` if needed.
- **Fedora-centric upstream**: Upstream testing primarily targets Fedora; non-RPM installs may encounter undocumented path differences.

## Links

- Homepage & source: https://pagure.io/pagure
- Documentation: https://docs.pagure.org/pagure/
- Docker setup: https://pagure.io/pagure/blob/master/f/docker
