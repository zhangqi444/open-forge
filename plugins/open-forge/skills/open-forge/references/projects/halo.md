---
name: halo-project
description: Halo recipe for open-forge. Covers Docker single-container and Docker Compose install as documented at https://docs.halo.run.
---

# Halo

Powerful, open source CMS and website builder. Supports blogs, knowledge bases, portfolios, and online stores. Built on Java/Spring Boot with a plugin/theme ecosystem. Upstream: <https://github.com/halo-dev/halo>. Official site: <https://www.halo.run/>. Docs: <https://docs.halo.run/> (primarily Chinese). Demo: <https://demo.halocms.site/console> (user: `demo`, password: `P@ssw0rd123..`).

## Compatible install methods

| Method | Upstream reference | When to use |
|---|---|---|
| Docker (single container) | <https://docs.halo.run/getting-started/install/docker> | Quick start with embedded H2 database |
| Docker Compose | <https://docs.halo.run/getting-started/install/docker-compose> | Recommended for production — adds PostgreSQL or MySQL |
| 1Panel | <https://docs.halo.run/getting-started/install/1panel> | Chinese Linux server management panel with one-click deploy |
| Helm (Kubernetes) | <https://docs.halo.run/getting-started/install/helm> | Kubernetes deployments |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which Halo version?" | Tag e.g. `2.23` | Use `halohub/halo:<version>` |
| preflight | "Which port should Halo be accessible on?" | Number (default `8090`) | |
| data | "Where should Halo data be persisted?" | Host path | Mounted at `/root/.halo2` inside container |
| db (production) | "Use PostgreSQL or MySQL for production?" | Choice: PostgreSQL / MySQL / H2 (default, dev only) | H2 is embedded; use PostgreSQL or MySQL for production |
| db | "Database URL?" | JDBC URL | e.g. `r2dbc:pool:postgresql://<host>:5432/<db>` |

## Docker quick-start (from upstream README)

```bash
docker run -d \
  --name halo \
  -p 8090:8090 \
  -v ~/.halo2:/root/.halo2 \
  halohub/halo:2.23
```

Visit `http://localhost:8090/console` to complete setup.

## Docker Compose with PostgreSQL (recommended production)

```yaml
version: "3"
services:
  halo:
    image: halohub/halo:2.23
    restart: on-failure:3
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./halo2:/root/.halo2
    ports:
      - "8090:8090"
    environment:
      SPRING_R2DBC_URL: r2dbc:pool:postgresql://db/halo
      SPRING_R2DBC_USERNAME: halo
      SPRING_R2DBC_PASSWORD: yourpassword
      SPRING_SQL_INIT_PLATFORM: postgresql
  db:
    image: postgres:15-alpine
    restart: on-failure:3
    volumes:
      - ./pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: halo
      POSTGRES_USER: halo
      POSTGRES_PASSWORD: yourpassword
    healthcheck:
      test: ["CMD", "pg_isready", "-U", "halo", "-d", "halo"]
      interval: 10s
      timeout: 5s
      retries: 5
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Data dir | `/root/.halo2` — stores all site data, attachments, plugins, and themes. **Must be persisted.** |
| Port | Default `8090`. Override with `-p <host-port>:8090`. |
| Admin panel | `http://<host>:8090/console` — created on first-run via setup wizard |
| Database | H2 (embedded, default) for dev only. PostgreSQL or MySQL for production — configure via `SPRING_R2DBC_*` env vars. |
| Plugins | Installed via admin panel; stored in `/root/.halo2/plugins/`. Extensive plugin marketplace at <https://halo.run/store/apps>. |
| Themes | Stored in `/root/.halo2/themes/`. Marketplace at <https://halo.run/store/themes>. |
| Multi-instance | Not supported with H2 — use PostgreSQL or MySQL and a shared storage layer for attachments. |
| Reverse proxy | Run behind Nginx/Caddy for TLS. Set `server.forward-headers-strategy=native` env var when behind a proxy. |

## Upgrade procedure

Per <https://docs.halo.run/getting-started/upgrade>:

1. Back up data: `cp -r ~/.halo2 ~/.halo2.backup` (or back up the Docker volume)
2. Pull new image: `docker pull halohub/halo:<new-version>`
3. Stop old container, start new one with the same volume mount.
4. Halo runs database migrations automatically on startup.
5. Verify at `/console` — check version in footer.

## Gotchas

- **H2 in production**: H2 is single-process and not suitable for production. Switch to PostgreSQL or MySQL for any real deployment.
- **Data volume required**: without bind-mounting `/root/.halo2`, all data (posts, plugins, themes) is lost on container restart.
- **Chinese-language docs**: official docs at <https://docs.halo.run> are primarily in Chinese. Use browser translation or the GitHub README for English context.
- **Reverse proxy headers**: behind Nginx/Caddy, add `server.forward-headers-strategy=native` (env: `SERVER_FORWARD_HEADERS_STRATEGY=native`) to get correct client IPs and redirect URLs.
- **Plugin compatibility**: plugins are version-specific. After major upgrades, check plugin compatibility before enabling them.

## Links

- Upstream README: <https://github.com/halo-dev/halo>
- Documentation: <https://docs.halo.run/>
- Docker Hub: <https://hub.docker.com/r/halohub/halo/tags>
- Demo: <https://demo.halocms.site>
- Plugin/theme marketplace: <https://halo.run/store/apps>
