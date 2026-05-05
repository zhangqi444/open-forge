---
name: alfio-project
description: Alf.io recipe for open-forge. Covers Docker Compose and Gradle/Java install as documented at https://github.com/alfio-event/alf.io.
---

# Alf.io

Free and open source event attendance management and ticket reservation system. Built for event organizers who care about privacy, security, and fair pricing. Upstream: <https://github.com/alfio-event/alf.io>. Official site: <https://alf.io/>. Demo: <https://demo.alf.io/>.

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker Compose | <https://github.com/alfio-event/alf.io/blob/master/docker-compose.yml> | Recommended for most self-hosters |
| Gradle + Java | <https://github.com/alfio-event/alf.io#run-on-your-machine> | Development or bare-metal installs |

> ⚠️ The `master` branch may contain unstable code. For production, use the [`2.0-M4-maintenance`](https://github.com/alfio-event/alf.io/tree/2.0-M4-maintenance) branch per upstream recommendation.

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which port should Alf.io be accessible on?" | Number (default `8080`) | Maps to container port `8080` |
| db | "PostgreSQL database name?" | String (default `alfio`) | `POSTGRES_ENV_POSTGRES_DB` |
| db | "PostgreSQL username?" | String (default `alfio`) | `POSTGRES_ENV_POSTGRES_USERNAME` |
| db | "PostgreSQL password?" | String | `POSTGRES_ENV_POSTGRES_PASSWORD` — use a strong random value in production |
| db | "PostgreSQL host (if external)?" | Hostname | Leave blank to use the bundled `db` service |

## Docker Compose (from upstream)

```yaml
version: "3.7"
services:
  alfio:
    image: alfio/alf.io
    environment:
      POSTGRES_PORT_5432_TCP_PORT: 5432
      POSTGRES_PORT_5432_TCP_ADDR: db
      POSTGRES_ENV_POSTGRES_DB: alfio
      POSTGRES_ENV_POSTGRES_USERNAME: alfio
      POSTGRES_ENV_POSTGRES_PASSWORD: alfio      # change in production
      SPRING_PROFILES_ACTIVE: dev,jdbc-session
    ports:
      - "8080:8080"
  db:
    image: postgres:10
    environment:
      POSTGRES_DB: alfio
      POSTGRES_USER: alfio
      POSTGRES_PASSWORD: alfio
    ports:
      - target: 5432
        published: 5432
        protocol: tcp
        mode: host
    volumes:
      - data-volume:/var/lib/postgresql/data
volumes:
  data-volume:
```

Access admin at `http://localhost:8080/admin` — default credentials printed to console on first start.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | PostgreSQL ≥ 10 required. The DB user must **not** be a superuser — row-level security policies won't apply otherwise. |
| Admin URL | `/admin` — first-run creates an admin account with a printed password. |
| Spring profiles | `dev,jdbc-session` for Docker. Production should use `prod,jdbc-session`. |
| Session storage | `jdbc-session` profile stores sessions in PostgreSQL. Required for multi-node deployments. |
| Port | App listens on `8080` inside the container. |
| Data volume | PostgreSQL data persisted in `data-volume`. Back up this volume for disaster recovery. |

## Upgrade procedure

Per <https://github.com/alfio-event/alf.io/releases>:

1. Pull the new image: `docker compose pull alfio`
2. Restart: `docker compose up -d alfio`
3. Alf.io applies database migrations automatically on startup via Flyway.
4. Verify admin UI is accessible and check logs: `docker compose logs -f alfio`

## Gotchas

- **PostgreSQL superuser**: do NOT use a superuser account — row-level security (RLS) checks are skipped for superusers, creating a security gap.
- **Production profile**: the upstream docker-compose uses `dev,jdbc-session`. Switch to `prod,jdbc-session` for production to disable dev-only endpoints.
- **Unstable master branch**: upstream explicitly warns that `master` may be unstable. Pin to `alfio/alf.io:2.0-M4` or the `2.0-M4-maintenance` branch tag for stable deploys.
- **SMTP required**: Alf.io sends confirmation emails for ticket purchases. Configure SMTP via environment variables or `config.properties`.
- **Reverse proxy**: run behind Nginx or Caddy for TLS termination — Alf.io does not handle TLS natively.

## Links

- Upstream README: <https://github.com/alfio-event/alf.io>
- Docker Hub: <https://hub.docker.com/r/alfio/alf.io/tags>
- Demo: <https://demo.alf.io/>
- Stable branch: <https://github.com/alfio-event/alf.io/tree/2.0-M4-maintenance>
