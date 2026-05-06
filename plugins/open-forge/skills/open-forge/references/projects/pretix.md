---
name: pretix
description: Pretix recipe for open-forge. Open-source ticket sales platform for events — customizable registration, payment processing, check-in apps, box office. Python/Docker install. Upstream: https://github.com/pretix/pretix
---

# Pretix

Open-source ticket sales platform for events. Sell tickets online with customizable registration forms, multiple payment providers, attendee check-in apps, and box office support. Used by hundreds of events worldwide including large conferences.

2,386 stars · AGPL-3.0

Upstream: https://github.com/pretix/pretix
Website: https://pretix.eu/
Docs: https://docs.pretix.eu/
Docker Hub: https://hub.docker.com/r/pretix/standalone

## What it is

Pretix provides a complete event ticketing platform:

- **Flexible ticket types** — Free, paid, donation, variation-based (e.g. T-shirt size + ticket tier)
- **Customizable forms** — Build registration forms with custom questions per product
- **Multiple payment providers** — Stripe, PayPal, bank transfer, and 30+ community plugins
- **Multilingual** — 30+ languages; each event can be in a different language
- **Vouchers** — Single-use, multi-use, percentage/fixed discounts, access codes
- **Waiting lists** — Automatic waiting list management with notifications
- **Print-at-home tickets** — PDF ticket generation with barcodes/QR codes
- **Check-in** — Android/iOS apps for door scanning; offline-capable
- **Box office** — Sell tickets at the door via web interface
- **Seating plans** — Reserved seating with visual layout editor
- **Organizer portal** — Manage multiple events under one account
- **REST API** — Full programmatic access for custom integrations
- **Plugins** — Extensible via Python plugins (social auth, shipping, etc.)
- **Multi-event shop** — One shop URL for all events under an organizer

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | pretix/standalone | Recommended self-hosted method |
| Bare metal | Python 3.11+ + PostgreSQL + Redis | Manual install from pip |

## Inputs to collect

### Phase 1 — Pre-install
- Domain name for the pretix instance
- SMTP credentials for transactional emails
- Database credentials (PostgreSQL recommended)
- Redis host for task queue
- Payment provider credentials (Stripe secret key, etc.)

### Phase 2 — Config file (pretix.cfg)
  [pretix]
  instance_name=My Event Platform
  url=https://tickets.example.com
  currency=EUR
  datadir=/data/pretix
  registration=off

  [database]
  backend=postgresql
  name=pretix
  user=pretix
  password=secret
  host=db

  [mail]
  from=tickets@example.com
  host=smtp.example.com
  port=587
  user=user@example.com
  password=yourpassword
  tls=on

  [redis]
  location=redis://redis:6379/0
  sessions=true

  [celery]
  backend=redis://redis:6379/1
  broker=redis://redis:6379/2

## Software-layer concerns

### Ports
- 80 — HTTP (pretix/standalone listens on 80; use reverse proxy for HTTPS)

### Config paths
- /etc/pretix/pretix.cfg — main configuration (mount into container)
- /var/pretix/data/ — uploaded files, plugins, logs (mount as volume)

### Worker process
Pretix requires a Celery worker for background tasks (email sending, PDF generation, etc.).
The standalone Docker image runs both the web server and worker.

## Docker Compose install

  version: '3'
  services:
    pretix:
      image: pretix/standalone:stable
      restart: unless-stopped
      ports:
        - "80:80"
      volumes:
        - pretix_data:/var/pretix/data
        - ./pretix.cfg:/etc/pretix/pretix.cfg:ro
      environment:
        - PRETIX_CONFIG=/etc/pretix/pretix.cfg
      depends_on:
        - db
        - redis

    db:
      image: postgres:16-alpine
      restart: unless-stopped
      environment:
        POSTGRES_DB: pretix
        POSTGRES_USER: pretix
        POSTGRES_PASSWORD: secret
      volumes:
        - pgdata:/var/lib/postgresql/data

    redis:
      image: redis:7-alpine
      restart: unless-stopped
      volumes:
        - redisdata:/data

  volumes:
    pretix_data:
    pgdata:
    redisdata:

After first start, create superuser:
  docker compose exec pretix pretix createsuperuser

Access at http://localhost (or your domain via reverse proxy)

## Upgrade procedure

1. Backup PostgreSQL: docker exec <db> pg_dump -U pretix pretix > backup.sql
2. Backup /var/pretix/data/ volume
3. Pull new image: docker pull pretix/standalone:stable
4. Restart: docker compose up -d --force-recreate pretix
5. Run migrations: docker compose exec pretix pretix migrate
6. Rebuild static files: docker compose exec pretix pretix rebuild

## Gotchas

- pretix.cfg required — the standalone image needs a config file mounted; it won't start without one
- Celery worker essential — background jobs (emails, PDF generation) depend on the worker; standalone image includes it, but split installs need a separate worker container
- AGPL-3.0 — running a modified pretix as a public service requires open-sourcing your changes; offering hosting commercially requires a commercial license (contact pretix.eu)
- Stripe SCA — for European events, Stripe requires 3DS/SCA; pretix handles this correctly via its Stripe plugin
- Plugin installation — install plugins inside the container or mount a plugins directory; restart required after installing
- Large events — for events with 10k+ attendees, tune PostgreSQL and consider separate Celery worker containers
- Check-in apps — download pretixSCAN from app stores; connect via REST API URL + device token configured in organizer settings

## Links

- Upstream: https://github.com/pretix/pretix
- Documentation: https://docs.pretix.eu/
- Docker Hub: https://hub.docker.com/r/pretix/standalone
- Plugins: https://pretix.eu/about/en/plugins
- Community forum: https://community.pretix.eu/
