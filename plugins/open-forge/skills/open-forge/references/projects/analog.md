---
name: analog
description: ANALOG recipe for open-forge. Minimal self-hosted analytics tool tracking events over a 10-30 day rolling window. Supports Redis, PostgreSQL, MongoDB, SQLite. Source: https://github.com/orangecoloured/analog
---

# ANALOG

A minimal self-hosted analytics tool. Tracks named events and displays them over a configurable 10–30 day rolling window. Node.js backend with multiple database backends (Redis, PostgreSQL, MongoDB, SQLite). MIT licensed. Upstream: <https://github.com/orangecoloured/analog>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux VPS | Docker Compose | PostgreSQL | Recommended for persistent self-hosted |
| Any Linux VPS | Docker Compose | SQLite | Simplest; single-file DB |
| Any Linux VPS | Docker Compose | Redis | Fast; data expires naturally |
| Any Linux VPS | Node.js native | Any supported | Build from source |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Which database backend?" | redis / postgresql / mongodb / sqlite | Drives connection config |
| "Database connection URL?" | URL string | e.g. postgresql://user:pass@host:5432/analog |
| "Optional: auth token to protect the API?" | String (sensitive) | Leave empty for open access |
| "Time range to display (10-30 days)?" | Number | Default 30 |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Page title for the dashboard?" | String | Shown in browser tab |
| "Port to expose the server on?" | Number | Default from ANALOG_PORT_SERVER |
| "Reverse proxy / domain?" | FQDN or skip | For HTTPS |

## Software-Layer Concerns

- **Two processes**: Node.js API server + Vite-built frontend (static). Set ANALOG_STATIC_SERVER=true for the Node server to also serve the frontend.
- **Environment variables**: All config via env vars; VITE_-prefixed vars are baked into the frontend at build time.
- **Rolling window only**: ANALOG does NOT store historical data beyond the configured time range (10–30 days). Not suitable for long-term analytics.
- **Cleanup**: Set VITE_ANALOG_API_GET_REQUEST_CLEAN_UP=true (default) to purge old events on GET requests. Alternatively, schedule the cleanUp function.
- **SQLite with libsql**: Uses Turso's libsql client; local file path is file:./path/to/db.sqlite — note the file: prefix.
- **PostgreSQL**: Upstream recommends using a transaction pooler connection URL.
- **No user auth by default**: Set ANALOG_TOKEN and ANALOG_PROTECT_POST=true to require a token for event submission.

## Deployment

### Docker Compose (PostgreSQL)

```yaml
services:
  analog:
    image: ghcr.io/orangecoloured/analog:latest
    ports:
      - "3000:3000"
    environment:
      ANALOG_DATABASE_PROVIDER: postgresql
      ANALOG_POSTGRESQL_URL: postgresql://user:pass@db:5432/analog
      ANALOG_STATIC_SERVER: "true"
      ANALOG_TOKEN: ""  # set to protect API
      ANALOG_PROTECT_POST: "false"
      VITE_ANALOG_TIME_RANGE: "30"
      VITE_ANALOG_PAGE_TITLE: "Analytics"
      VITE_ANALOG_API_GET_REQUEST_QUEUE: "true"
      VITE_ANALOG_API_GET_REQUEST_CLEAN_UP: "true"
    restart: unless-stopped

  db:
    image: postgres:16
    environment:
      POSTGRES_DB: analog
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
    volumes:
      - pg_data:/var/lib/postgresql/data

volumes:
  pg_data:
```

### Tracking Events

```javascript
// POST an event from your app
fetch('https://your-analog-host/api/event', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    // 'Authorization': 'Bearer your-token'  // if ANALOG_TOKEN set
  },
  body: JSON.stringify({ name: 'page_view' })
})
```

## Upgrade Procedure

1. Pull new image: docker compose pull && docker compose up -d
2. Note: VITE_-prefixed env vars are baked at build time — if the image doesn't rebuild on pull, custom VITE_ values may not take effect without a manual rebuild.

## Gotchas

- **VITE_ vars are build-time**: If you're building from source, changes to VITE_-prefixed vars require a frontend rebuild (npm run build).
- **No long-term history**: Data older than the configured time range is deleted. This is by design — not a bug.
- **Minimal feature set**: No sessions, no user tracking, no funnels — just named event counts. Choose a heavier tool (Matomo, Plausible) for richer analytics.
- **Scheduling cleanUp on Netlify/Vercel**: The cron schedule may not work reliably on serverless platforms due to runtime limitations (per upstream README).
- **Database setup**: You must create the database/schema before first run — ANALOG does not run migrations automatically (check upstream README for init steps).

## Links

- Source: https://github.com/orangecoloured/analog
- Releases: https://github.com/orangecoloured/analog/releases
