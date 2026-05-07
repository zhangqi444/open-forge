---
name: seatsurfing
description: Seatsurfing recipe for open-forge. Web app for booking seats, desks, and rooms in offices. Go API + React PWA + PostgreSQL. Docker Compose. Source: https://github.com/seatsurfing/seatsurfing
---

# Seatsurfing

Web application for booking seats, desks, and rooms in offices. Employees use the Progressive Web App (installable on mobile) to find and reserve desks; admins manage floor plans, seat maps, and booking rules via the Admin UI. Go REST API backend + React PWA frontend + PostgreSQL. Docker. GPL-3.0 licensed.

Upstream: <https://github.com/seatsurfing/seatsurfing> | Docs: <https://seatsurfing.io/docs/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Recommended |
| amd64 / arm64 | Docker | Both architectures supported |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | POSTGRES_PASSWORD / DB_PASSWORD | Set a strong random password |
| config | CRYPT_KEY | 32-byte random string for data encryption — generate with `openssl rand -hex 16` |
| config | Port | Default: 8080 |
| config (optional) | Reverse proxy + TLS | Recommended for production |

## Software-layer concerns

### Env vars (server container)

| Var | Description |
|---|---|
| POSTGRES_URL | PostgreSQL DSN: `postgres://seatsurfing:PASSWORD@db/seatsurfing?sslmode=disable` |
| CRYPT_KEY | 32-character random encryption key — required; determines how data is encrypted at rest |

### Data volumes

| Volume | Description |
|---|---|
| db | PostgreSQL data |

## Install — Docker Compose

```yaml
services:
  server:
    image: ghcr.io/seatsurfing/backend
    restart: always
    networks:
      - sql
    ports:
      - 8080:8080
    environment:
      POSTGRES_URL: 'postgres://seatsurfing:DB_PASSWORD@db/seatsurfing?sslmode=disable'
      CRYPT_KEY: 'some-random-32-bytes-long-string'

  db:
    image: postgres:17
    restart: always
    networks:
      - sql
    volumes:
      - db:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: DB_PASSWORD
      POSTGRES_USER: seatsurfing
      POSTGRES_DB: seatsurfing

volumes:
  db:

networks:
  sql:
```

```bash
docker compose up -d
# Access at http://yourserver:8080
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
# Data preserved via named volume
```

## Gotchas

- **CRYPT_KEY must be set and preserved** — changing `CRYPT_KEY` after setup renders all encrypted booking data unreadable. Generate it once, store it safely, never change it.
- **Change DB_PASSWORD** from the example — use a strong random password and keep it consistent between the `POSTGRES_URL` in the server service and `POSTGRES_PASSWORD` in the db service.
- SaaS option available at https://seatsurfing.io/ — free for up to 10 users if self-hosting is too much overhead.
- Microsoft Teams integration is available (via AppSource) for the SaaS version.
- The Booking UI is a PWA — users can install it on iOS/Android from the browser for a native-app-like experience.

## Links

- Source: https://github.com/seatsurfing/seatsurfing
- Documentation: https://seatsurfing.io/docs/
- Docker image: https://github.com/seatsurfing/seatsurfing/pkgs/container/backend
