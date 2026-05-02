# DollarDollar Bill Y'all (FinPal)

**What it is:** Self-hosted personal finance and expense-tracking web app with multi-currency support, bill-splitting, budgeting with notifications, SimpleFin bank sync, portfolio management, and OIDC authentication. Originally called DollarDollar, now evolving into FinPal under the PalStack umbrella — the original repo is preserved for reference; active development continues in the FinPal Core repo.

**Official URL:** https://github.com/harung1993/dollardollar

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; requires PostgreSQL |
| Unraid | Docker template | Community App template available |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | `DB_USER` | PostgreSQL username |
| Deploy | `DB_PASSWORD` | PostgreSQL password |
| Deploy | `DB_NAME` | PostgreSQL database name |
| Deploy | `SECRET_KEY` | Flask session secret — generate a random string |
| Deploy | Host port | Default `5006` → container `5001` |
| Optional | `MAIL_SERVER` | SMTP server for email notifications |
| Optional | `MAIL_PORT` | SMTP port (default `587`) |
| Optional | `MAIL_USERNAME` / `MAIL_PASSWORD` | SMTP credentials |
| Optional | `MAIL_DEFAULT_SENDER` | From address for emails |
| Optional | `OIDC_ENABLED=True` | Enable OpenID Connect SSO |
| Optional | `OIDC_CLIENT_ID` / `OIDC_CLIENT_SECRET` | OIDC app credentials |
| Optional | `OIDC_DISCOVERY_URL` | OIDC provider discovery endpoint |
| Optional | `SIMPLEFIN_ENABLED` | Enable SimpleFin bank account sync |
| Optional | `INVESTMENT_TRACKING_ENABLED=True` | Enable portfolio tracking |
| Optional | `DISABLE_SIGNUPS=True` | Lock registrations after initial setup |
| Optional | `LOCAL_LOGIN_DISABLE=True` | Force OIDC-only login |

---

## Software-Layer Concerns

### Docker image
```
harung43/dollardollar:latest
```

### docker-compose.yml
```yaml
version: '3'
services:
  app:
    image: harung43/dollardollar:latest
    platform: linux/amd64
    ports:
      - "5006:5001"
    environment:
      - SQLALCHEMY_DATABASE_URI=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      - DEVELOPMENT_MODE=False
      - DISABLE_SIGNUPS=${DISABLE_SIGNUPS:-False}
      - DEBUG=${DEBUG:-False}
      - LOG_LEVEL=${LOG_LEVEL:-INFO}
      - FLASK_APP=app.py
      - SECRET_KEY=${SECRET_KEY}
      - MAIL_SERVER=${MAIL_SERVER}
      - MAIL_PORT=${MAIL_PORT:-587}
      - MAIL_USE_TLS=${MAIL_USE_TLS:-True}
      - MAIL_DEFAULT_SENDER=${MAIL_DEFAULT_SENDER}
      - SIMPLEFIN_ENABLED=${SIMPLEFIN_ENABLED}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - app-network

  db:
    image: postgres:13
    environment:
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
      - POSTGRES_DB=${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped
    networks:
      - app-network

volumes:
  postgres_data:

networks:
  app-network:
    driver: bridge
```

### .env template
Copy `.env.template` (or `.env.example`) from the repo and fill in values before starting.

### Database
- PostgreSQL 13; data persisted in named volume `postgres_data`
- `SQLALCHEMY_DATABASE_URI` must match the `db` service credentials exactly

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

If you encounter errors after updating, run database migrations:
```bash
docker compose exec app flask db migrate
docker compose exec app flask db upgrade
```

---

## Gotchas

- **amd64 only** — image is pinned to `linux/amd64`; ARM hosts (e.g., Raspberry Pi) require building from source
- **`SECRET_KEY` is required** — Flask will refuse to start without it; generate with `openssl rand -hex 32`
- **DB healthcheck** — the app container waits for Postgres to pass its healthcheck before starting; on slow hosts this can delay initial boot by ~30s
- **After updates** — always run `flask db migrate && flask db upgrade` if the app behaves unexpectedly post-update; schema changes are not always applied automatically
- **Active development moved** — the original repo (`harung1993/dollardollar`) is in maintenance mode; new features and bug fixes are in the FinPal Core repo under PalStack

---

## Links

- GitHub: https://github.com/harung1993/dollardollar
- `.env.example`: https://github.com/harung1993/dollardollar/blob/main/.env.example
- FinPal (successor): https://finpal.palstack.io
