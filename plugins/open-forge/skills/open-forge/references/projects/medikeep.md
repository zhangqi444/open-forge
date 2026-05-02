---
name: medikeep-project
description: MediKeep recipe for open-forge. Personal health records keeper — track medications, appointments, providers, lab results, and medical history. React frontend + FastAPI backend, PostgreSQL, optional SSO/OIDC, report builder, PDF export. Two containers. Upstream: https://github.com/afairgiant/MediKeep
---

# MediKeep

A personal health records manager. Track medications, medical appointments, healthcare providers, lab results, conditions, procedures, and medical history. Includes a report builder for exporting health data to share with providers. React + FastAPI, PostgreSQL, optional SSO/OIDC.

> ⚠️ **Name change:** Formerly known as *Personal-Medical-Records-Keeper*. Docker image moved from `ghcr.io/afairgiant/personal-medical-records-keeper/medical-records` to `ghcr.io/afairgiant/medikeep`. Update existing configs accordingly.

Upstream: <https://github.com/afairgiant/MediKeep> | Wiki: <https://github.com/afairgiant/MediKeep/wiki>

Two containers: combined React+FastAPI app + PostgreSQL.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Two containers (app + PostgreSQL 15) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | `APP_PORT`; default `8005` |
| security | "Database password?" | `DB_PASSWORD` — required; no default |
| security | "SECRET_KEY?" | Required for persistent JWT sessions; generate with `openssl rand -hex 32` |
| config | "Timezone?" | `TZ`; e.g. `America/New_York`; default `America/New_York` |
| config | "Enable SSO?" | `SSO_ENABLED`; default `false`; set `true` + SSO_* vars to enable |
| config (SSO) | "SSO provider type?" | `SSO_PROVIDER_TYPE`; default `oidc` |
| config (SSO) | "SSO client ID, secret, issuer URL, redirect URI?" | Required if `SSO_ENABLED=true` |

## Software-layer concerns

### Image

```
ghcr.io/afairgiant/medikeep:latest
```

GitHub Container Registry — no Docker Hub image.

### .env file

```env
DB_NAME=medical_records
DB_USER=medapp
DB_PASSWORD=changeme        # required — no default
SECRET_KEY=                 # required — generate: openssl rand -hex 32
APP_PORT=8005
TZ=America/New_York
DEBUG=false
ENABLE_API_DOCS=false
LOG_LEVEL=INFO
SSO_ENABLED=false
# SSO (optional):
# SSO_PROVIDER_TYPE=oidc
# SSO_CLIENT_ID=
# SSO_CLIENT_SECRET=
# SSO_ISSUER_URL=
# SSO_REDIRECT_URI=
# SSO_ALLOWED_DOMAINS=[]
```

### Compose

```yaml
services:
  postgres:
    image: postgres:15.8-alpine
    container_name: medical-records-db
    environment:
      POSTGRES_DB: ${DB_NAME:-medical_records}
      POSTGRES_USER: ${DB_USER:-medapp}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./postgres/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U ${DB_USER:-medapp} -d ${DB_NAME:-medical_records}']
      interval: 10s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - medical-records-network

  medical-records-app:
    image: ghcr.io/afairgiant/medikeep:latest
    container_name: medical-records-app
    ports:
      - ${APP_PORT:-8005}:8000
    environment:
      DB_HOST: postgres
      DB_PORT: 5432
      DB_NAME: ${DB_NAME:-medical_records}
      DB_USER: ${DB_USER:-medapp}
      DB_PASSWORD: ${DB_PASSWORD}
      SECRET_KEY: ${SECRET_KEY:?Set SECRET_KEY in .env for persistent JWTs}
      DEBUG: ${DEBUG:-false}
      ENABLE_API_DOCS: ${ENABLE_API_DOCS:-false}
      TZ: ${TZ:-America/New_York}
      LOG_LEVEL: ${LOG_LEVEL:-INFO}
      SSO_ENABLED: ${SSO_ENABLED:-false}
    volumes:
      - app_uploads:/app/uploads
      - app_logs:/app/logs
      - app_backups:/app/backups
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ['CMD', 'curl', '-f', 'http://localhost:8000/health']
      interval: 30s
      timeout: 10s
      retries: 3
    restart: unless-stopped
    networks:
      - medical-records-network

volumes:
  postgres_data:
  app_uploads:
  app_logs:
  app_backups:

networks:
  medical-records-network:
```

> Source: upstream README — <https://github.com/afairgiant/MediKeep>

### Key environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `DB_PASSWORD` | ✅ | — | PostgreSQL password |
| `SECRET_KEY` | ✅ | — | JWT signing key — `openssl rand -hex 32` |
| `APP_PORT` | — | `8005` | Host port for web UI |
| `TZ` | — | `America/New_York` | Timezone for dates/times |
| `DEBUG` | — | `false` | Enable debug mode |
| `ENABLE_API_DOCS` | — | `false` | Expose FastAPI /docs endpoint |
| `LOG_LEVEL` | — | `INFO` | App log level |
| `SSO_ENABLED` | — | `false` | Enable SSO/OIDC login |
| `SSO_PROVIDER_TYPE` | — | `oidc` | SSO provider type |
| `SSO_CLIENT_ID` | SSO only | — | OIDC client ID |
| `SSO_CLIENT_SECRET` | SSO only | — | OIDC client secret |
| `SSO_ISSUER_URL` | SSO only | — | OIDC issuer URL |
| `SSO_REDIRECT_URI` | SSO only | — | OIDC redirect URI |
| `SSO_ALLOWED_DOMAINS` | — | `[]` | Restrict SSO to specific email domains |

### Features

- **Dashboard** — overview of health records and recent activity
- **Medications** — track medications, dosages, schedules, and refills
- **Appointments** — log medical appointments with notes
- **Providers** — manage healthcare providers and contacts
- **Lab results** — record and track lab test results over time
- **Conditions** — document medical conditions and diagnoses
- **Procedures** — log medical procedures
- **Medical history** — comprehensive health history tracking
- **Report builder** — generate custom health reports; export for sharing with providers
- **PDF export** — export reports and records as PDFs
- **SSO/OIDC** — optional single sign-on (disable local accounts if using SSO exclusively)
- **API docs** — FastAPI auto-docs at `/docs` (disabled by default; enable with `ENABLE_API_DOCS=true`)

### init.sql

The compose mounts `./postgres/init.sql` into the database container. Get it from the upstream repo:

```bash
mkdir -p postgres
curl -o postgres/init.sql \
  https://raw.githubusercontent.com/afairgiant/MediKeep/HEAD/docker/postgres/init.sql
```

Or create an empty file if it's not required for your version:
```bash
mkdir -p postgres && touch postgres/init.sql
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in named volumes (`postgres_data`, `app_uploads`, `app_logs`, `app_backups`).

> Check the [releases page](https://github.com/afairgiant/MediKeep/releases) for migration notes before major version upgrades.

## Gotchas

- **Image renamed** — old image `ghcr.io/afairgiant/personal-medical-records-keeper/medical-records` is deprecated. Use `ghcr.io/afairgiant/medikeep:latest`.
- **`SECRET_KEY` required** — without it, JWTs are signed with a random key that changes on restart, logging everyone out. Generate once and store safely.
- **`DB_PASSWORD` has no default** — the compose uses `${DB_PASSWORD}` with no fallback. Starting without it set will fail.
- **`init.sql` must exist** — the postgres service bind-mounts `./postgres/init.sql`. If the file doesn't exist, the container may fail to start. Create it (even if empty) before first run.
- **`ENABLE_API_DOCS=false` by default** — the FastAPI `/docs` endpoint is disabled in production. Enable only on trusted networks.
- **Health data is sensitive** — do not expose MediKeep publicly without HTTPS and strong access control. Use a reverse proxy with TLS, and consider enabling SSO with MFA.
- **SSO doesn't auto-disable local auth** — with `SSO_ENABLED=true`, both local and SSO login may be available. Check the wiki for how to restrict to SSO-only.

## Links

- Upstream README: <https://github.com/afairgiant/MediKeep>
- Wiki (User/Admin/Developer guides): <https://github.com/afairgiant/MediKeep/wiki>
- Releases: <https://github.com/afairgiant/MediKeep/releases>
