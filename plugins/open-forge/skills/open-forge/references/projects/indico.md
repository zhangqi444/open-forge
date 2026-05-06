---
name: indico
description: Indico recipe for open-forge. Feature-rich event and conference management system made at CERN — abstracts, registration, timetable, room booking, badges. Python/Docker install. Upstream: https://github.com/indico/indico
---

# indico

Feature-rich event management system, made at CERN. Manage the full lifecycle of conferences, workshops, and meetings — call for abstracts, registration, payments, paper review, timetable, room booking, and badge printing.

2,065 stars · MIT

Upstream: https://github.com/indico/indico
Website: https://getindico.io/
Docs: https://docs.getindico.io/
Demo/Sandbox: https://sandbox.getindico.io/
Docker: https://github.com/indico/indico-docker

## What it is

indico provides a complete conference and event management platform:

- **Event hierarchy** — Organize events under categories (institutes, departments, series)
- **Conference workflow** — Full conference lifecycle management:
  - Call for Abstracts with reviewing and decision workflow
  - Flexible registration form builder with custom fields
  - Payment integrations (PayPal, Stripe, Cern CERN-specific)
  - Paper reviewing workflow
  - Drag-and-drop timetable editor
  - Badge / ticket designer with print support
- **Meeting management** — Agendas, material upload, minutes
- **Room booking** — Reserve rooms tied to your physical location
- **Video conferencing** — Integrations with Zoom, Vidyo, etc.
- **Lecture management** — Simple event type for talks and seminars
- **Full-text search** — Search across abstracts, contributions, and materials
- **Notifications** — Email alerts for registration, abstract decisions, schedule changes
- **Multi-language** — Extensive i18n support
- **REST API** — Programmatic access to events, registrations, contributions
- **Plugin system** — Extensible via Python plugins

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | indico-docker | Official; recommended self-hosted path |
| Bare metal | Python 3.12+ + PostgreSQL + Redis | Manual install on Ubuntu/Debian |

## Inputs to collect

### Phase 1 — Pre-install
- Public URL for the instance (INDICO_BASE_URL)
- PostgreSQL credentials
- Redis host/port
- SMTP credentials for email
- Admin email address

### Phase 2 — Config (indico.conf)
  BASE_URL = 'https://indico.example.com'
  SQLALCHEMY_DATABASE_URI = 'postgresql://indico:pass@localhost/indico'
  REDIS_CACHE_URL = 'redis://localhost:6379/0'
  SMTP_SERVER = ('smtp.example.com', 587)
  SMTP_USE_TLS = True
  SUPPORT_EMAIL = 'admin@example.com'
  PUBLIC_SUPPORT_EMAIL = 'support@example.com'
  NO_REPLY_EMAIL = 'noreply@example.com'
  SECRET_KEY = '<random-64-char-secret>'

## Software-layer concerns

### Docker Compose install (indico-docker)
  git clone https://github.com/indico/indico-docker
  cd indico-docker
  cp docker-compose.yml.sample docker-compose.yml
  # Edit docker-compose.yml: set INDICO_UID, INDICO_GID, INDICO_BASE_URL
  docker compose up -d
  # First-run setup:
  docker compose exec web indico setup wizard   # or indico db prepare

### Config paths (Docker)
- /opt/indico/etc/indico.conf — main configuration (mounted from host)
- /opt/indico/archive/ — uploaded files and materials (persist this volume)
- /opt/indico/custom/ — custom themes/plugins

### Ports
- 59999 — uWSGI HTTP (expose via Nginx reverse proxy)
- PostgreSQL: 5432 (internal)
- Redis: 6379 (internal)

### Reverse proxy (Nginx)
  server {
    listen 443 ssl;
    server_name indico.example.com;
    client_max_body_size 100m;
    location / {
      proxy_pass http://localhost:59999;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
    location /static/assets/ {
      alias /opt/indico/web/static/assets/;
      expires 1d;
    }
  }

### Celery worker (background tasks)
indico requires a Celery worker for async tasks (email sending, scheduled jobs).
In Docker Compose this is a separate worker service.

## Upgrade procedure

1. Backup PostgreSQL: docker exec <db> pg_dump -U indico indico > backup.sql
2. Backup /opt/indico/archive/
3. Update image tag in docker-compose.yml
4. docker compose pull && docker compose up -d
5. Run migrations: docker compose exec web indico db upgrade
6. Reload uWSGI: docker compose exec web touch /opt/indico/web/indico.wsgi

## Gotchas

- Celery worker required — email notifications and scheduled tasks depend on the Celery worker; if it's not running, emails won't send
- PostgreSQL only — indico requires PostgreSQL; MySQL/SQLite are not supported
- File storage — /opt/indico/archive/ stores all uploaded materials; this can grow large; consider S3-compatible storage for large deployments
- SECRET_KEY — must be a long random string; changing it invalidates all sessions
- First-run wizard — after initial deploy, run indico setup wizard or indico db prepare to initialize the database
- Large file uploads — increase client_max_body_size in Nginx for conferences with large presentation uploads
- Room booking module — requires configuring locations and rooms in the admin area before it's useful
- MIT license — permissive; modifications not required to be open-sourced

## Links

- Upstream README: https://github.com/indico/indico/blob/master/README.md
- Documentation: https://docs.getindico.io/
- indico-docker: https://github.com/indico/indico-docker
- Sandbox: https://sandbox.getindico.io/
- Installation guide: https://docs.getindico.io/en/stable/installation/
