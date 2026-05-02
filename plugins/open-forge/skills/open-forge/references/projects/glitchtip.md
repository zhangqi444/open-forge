# GlitchTip

A self-hosted, open-source application monitoring platform compatible with Sentry's client SDKs. Collect JavaScript, Python, Ruby, Go, and other error events using any Sentry SDK — just point it at your GlitchTip instance. Also includes uptime monitoring and basic performance monitoring. Multi-user, multi-team, multi-project. Backed by PostgreSQL and Redis. Distributed via Docker.

- **GitLab (backend):** https://gitlab.com/glitchtip/glitchtip-backend
- **Docker Hub:** https://hub.docker.com/r/glitchtip/glitchtip
- **Docs:** https://glitchtip.com/documentation
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Requires PostgreSQL + Redis |

---

## Inputs to Collect

### Required environment variables
| Variable | Description |
|----------|-------------|
| SECRET_KEY | Random secret key — generate with: `openssl rand -hex 32` |
| GLITCHTIP_DOMAIN | Full public URL (e.g. https://glitchtip.example.com) |
| DATABASE_URL | PostgreSQL DSN (e.g. postgresql://user:pass@postgres/glitchtip) |
| REDIS_URL | Redis DSN (e.g. redis://redis) |
| DEFAULT_FROM_EMAIL | From address for notification emails |

### Optional environment variables
| Variable | Description |
|----------|-------------|
| EMAIL_URL | SMTP DSN (e.g. smtp://user:pass@host:587) — required for invites and alerts |
| ENABLE_OPEN_USER_REGISTRATION | Set False to disable public registration (default: True) |
| GLITCHTIP_MAX_EVENT_LIFE_DAYS | Days to retain events (default: 90) |
| CELERY_WORKER_CONCURRENCY | Celery worker concurrency (default: 2) |

---

## Software-Layer Concerns

### Architecture
- **web** — Django REST API + serves frontend (single image: `glitchtip/glitchtip`)
- **worker** — Celery task worker (same image, different command)
- **migrate** — runs DB migrations on startup (same image, one-shot)
- **postgresql** — PostgreSQL database
- **redis** — Redis for task queue and caching

### Ports
- 8000 — Web UI and API

### Volumes
| Volume | Contents |
|--------|----------|
| uploads | File attachments on error events |

---

## docker-compose.yml

```yaml
x-environment: &default-environment
  DATABASE_URL: postgresql://glitchtip:glitchtip@postgres/glitchtip
  SECRET_KEY: changeme-use-openssl-rand-hex-32
  GLITCHTIP_DOMAIN: https://glitchtip.example.com
  DEFAULT_FROM_EMAIL: glitchtip@example.com
  EMAIL_URL: smtp://user:pass@mail:587
  REDIS_URL: redis://redis
  ENABLE_OPEN_USER_REGISTRATION: "False"

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_DB: glitchtip
      POSTGRES_USER: glitchtip
      POSTGRES_PASSWORD: glitchtip
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis
    restart: unless-stopped

  web:
    image: glitchtip/glitchtip
    depends_on:
      - postgres
      - redis
    ports:
      - "8000:8000"
    environment: *default-environment
    volumes:
      - uploads:/code/uploads
    restart: unless-stopped

  worker:
    image: glitchtip/glitchtip
    command: ./bin/run-celery-with-beat.sh
    depends_on:
      - postgres
      - redis
    environment: *default-environment
    volumes:
      - uploads:/code/uploads
    restart: unless-stopped

  migrate:
    image: glitchtip/glitchtip
    depends_on:
      - postgres
    command: ./manage.py migrate
    environment: *default-environment

volumes:
  postgres-data:
  uploads:
```

After `docker compose up -d`, create admin:
```bash
docker compose run --rm web ./manage.py createsuperuser
```

---

## Upgrade Procedure

```bash
docker compose pull
docker compose run --rm migrate
docker compose up -d
```

---

## Gotchas

- **Sentry SDK compatibility:** GlitchTip accepts events from any Sentry client SDK — point the SDK's `dsn` at your GlitchTip instance; the DSN format is the same
- **Celery worker required:** Error processing, alerts, and uptime checks all run through Celery; the `worker` service must be running
- **`migrate` service is a one-shot:** Run it once on first deploy and again after each upgrade; it exits after migrations complete — it's not a long-running service
- **GLITCHTIP_DOMAIN must be exact:** This URL is used in email links and SDK DSNs; get it wrong and SDK errors won't route correctly
- **Email required for teams/alerts:** Invitation emails, alert notifications, and password resets all need EMAIL_URL configured
- **Disable open registration for private installs:** Set ENABLE_OPEN_USER_REGISTRATION=False unless you want anyone to register

---

## References
- Documentation: https://glitchtip.com/documentation
- Self-hosting guide: https://glitchtip.com/documentation/install
- GitLab: https://gitlab.com/glitchtip/glitchtip-backend
- Docker Hub: https://hub.docker.com/r/glitchtip/glitchtip
