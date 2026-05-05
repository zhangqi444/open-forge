# Aptabase

Open-source, privacy-first analytics platform built for mobile, desktop, and web apps. An alternative to Firebase Analytics / Google Analytics with a focus on minimal data collection (no unique identifiers), GDPR/CCPA/PECR compliance, and a simple built-in dashboard. Uses ClickHouse for event storage and PostgreSQL for metadata.

**Official site:** https://aptabase.com

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; PostgreSQL + ClickHouse + app container |
| VPS / cloud VM | Docker Compose + reverse proxy | Expose via Nginx/Traefik with HTTPS |

---

## Inputs to Collect

### Phase 1 — Planning
- Public-facing base URL (`BASE_URL`) — used in activation emails and SDK config
- Strong random secret for `AUTH_SECRET`
- SMTP credentials (optional — activation links logged to console if omitted)

### Phase 2 — Deployment
- PostgreSQL password for `aptabase` user
- ClickHouse password for `aptabase` user
- External port mapping (default: host `8000` → container `8080`)

---

## Software-Layer Concerns

### Docker Compose (`docker-compose.yml`)

```yaml
services:
  aptabase_db:
    container_name: aptabase_db
    image: postgres:15-alpine
    restart: always
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: aptabase
      POSTGRES_PASSWORD: change-me-strong-password

  aptabase_events_db:
    container_name: aptabase_events_db
    image: clickhouse/clickhouse-server:23.8.4.69-alpine
    restart: always
    volumes:
      - events-db-data:/var/lib/clickhouse
    environment:
      CLICKHOUSE_USER: aptabase
      CLICKHOUSE_PASSWORD: change-me-strong-password
    ulimits:
      nofile:
        soft: 262144
        hard: 262144

  aptabase:
    container_name: aptabase_app
    image: ghcr.io/aptabase/aptabase:main
    restart: always
    depends_on:
      - aptabase_events_db
      - aptabase_db
    ports:
      - 8000:8080
    environment:
      BASE_URL: http://localhost:8000        # set to your public URL
      AUTH_SECRET: change-me-random-secret   # use randomkeygen.com or openssl
      DATABASE_URL: Server=aptabase_db;Port=5432;User Id=aptabase;Password=change-me-strong-password;Database=aptabase
      CLICKHOUSE_URL: Host=aptabase_events_db;Port=8123;Username=aptabase;Password=change-me-strong-password

volumes:
  db-data:
  events-db-data:
```

### Key Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `BASE_URL` | Yes | Public-facing URL (used in emails and SDK) |
| `AUTH_SECRET` | Yes | Random secret for session signing |
| `DATABASE_URL` | Yes | PostgreSQL ADO.NET connection string |
| `CLICKHOUSE_URL` | Yes | ClickHouse connection string |
| `SMTP_*` | No | Email settings for account activation (optional) |

### First Login

There is **no default admin account**. After starting:
1. Navigate to `http://localhost:8000`
2. Register a new account
3. The activation link is printed in the container logs (`docker compose logs aptabase_app`)
4. Follow the link to activate your account

### Integrating Your App

After setup, create an App in the dashboard to get an App Key, then integrate an SDK:
```bash
# Example: Python SDK
pip install aptabase-python
```

SDKs available for Swift, Kotlin, Flutter, React Native, Electron, Python, and more.

---

## Upgrade Procedure

```bash
docker compose pull aptabase
docker compose up -d aptabase
```

PostgreSQL and ClickHouse data persist in named volumes. Review [releases](https://github.com/aptabase/aptabase/releases) for migration notes before upgrading.

---

## Gotchas

- **ClickHouse `ulimits`** — the `nofile: 262144` ulimit is required; ClickHouse fails to start without it.
- **No default admin** — account creation requires following an activation link from the container logs; SMTP is optional (link goes to logs).
- **`BASE_URL` must be correct** — activation emails and SDK callbacks use this URL; wrong value breaks account activation.
- **PostgreSQL connection string format** — uses ADO.NET syntax (`Server=host;Port=...`), not the standard PostgreSQL URI format.
- **ClickHouse memory** — ClickHouse is memory-hungry; allocate at least 2 GB RAM for the host.
- **Image tag `main`** — the compose file uses `ghcr.io/aptabase/aptabase:main` (latest main branch); pin to a specific release tag for production stability.
- Privacy design: Aptabase does not collect device IDs or PII by default; analytics are session-based.

---

## References
- GitHub (app): https://github.com/aptabase/aptabase
- Self-hosting guide: https://github.com/aptabase/self-hosting
- docker-compose.yml: https://github.com/aptabase/self-hosting/blob/main/docker-compose.yml
- SDK list: https://aptabase.com/for-mobile
