---
name: invoice-builder-project
description: Invoice Builder recipe for open-forge. Offline-first invoicing and quoting app for freelancers and small businesses. No accounts, no cloud, no subscriptions. PDF generation, multi-currency, UBL/Peppol/XRechnung e-invoicing export, XLSX import/export, partial payments, quotes, business/client/item management. Node backend + React frontend. Two containers behind nginx. Upstream: https://github.com/piratuks/invoice-builder
---

# Invoice Builder

An offline-first, open-source invoicing and quoting application for freelancers and small businesses. No accounts, no cloud, no subscriptions. Your data stays in a database file you own. Create invoices and quotes with live PDF preview, multi-currency support, UBL 2.1 / Peppol BIS 3.0 / XRechnung XML export for European e-invoicing compliance, XLSX import/export, partial payments, and customizable PDF branding.

Also available as a native desktop app (Windows, macOS, Linux).

Upstream: <https://github.com/piratuks/invoice-builder> | Container: `ghcr.io/piratuks/invoice-builder`

Two containers (backend + frontend) behind nginx. Single image for both services, differentiated by `SERVICE` env var.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Two containers from same image; nginx frontend routes to backend |
| Windows / macOS / Linux | Native desktop app (no Docker needed) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Frontend host port?" | Default: `3001` — nginx web UI |
| config | "Backend URL for frontend?" | `VITE_API_URL`; default `http://localhost:3000` — baked into frontend image at build time; must match where your backend is reachable from the browser |

## Software-layer concerns

### Image

```
ghcr.io/piratuks/invoice-builder:latest
```

Same image runs both backend and frontend, selected by `SERVICE` env var.

### Compose

```yaml
services:
  backend:
    image: ghcr.io/piratuks/invoice-builder:latest
    container_name: backend
    extra_hosts:
      - 'host.docker.internal:host-gateway'
    environment:
      - SERVICE=backend
      - NODE_ENV=docker
      - DB_DIRECTORY=/data
      - PORT=3000
      - DEV_SERVER_URL=0.0.0.0
      - FE_SERVER_URL=http://localhost:3001
      - MIGRATIONS_PATH=/app/dist-be/backend/server/shared/migrations
    volumes:
      - app-data:/data
    healthcheck:
      test:
        [
          'CMD', 'node', '-e',
          "const net=require('net');const c=net.createConnection(3000,'localhost');c.on('connect',()=>{c.destroy();process.exit(0)});c.on('error',()=>process.exit(1))"
        ]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 10s
    restart: unless-stopped

  frontend:
    image: ghcr.io/piratuks/invoice-builder:latest
    container_name: frontend
    ports:
      - '3001:3001'
    environment:
      - SERVICE=frontend
      - NODE_ENV=docker
      - PORT=3001
      - BE_SERVER_URL=http://backend:3000   # internal Docker network address of backend
    depends_on:
      backend:
        condition: service_healthy
    restart: unless-stopped

volumes:
  app-data:
```

> Source: upstream docker-compose.yml — <https://github.com/piratuks/invoice-builder>

### Key environment variables

**Backend (`SERVICE=backend`):**

| Variable | Purpose |
|---|---|
| `DB_DIRECTORY` | Path to database file directory; default `/data` |
| `PORT` | Backend port; default `3000` |
| `DEV_SERVER_URL` | Backend bind address; `0.0.0.0` in Docker |
| `FE_SERVER_URL` | Frontend URL (for CORS); e.g. `http://localhost:3001` |
| `MIGRATIONS_PATH` | Path to DB migration files inside container |

**Frontend (`SERVICE=frontend`):**

| Variable | Purpose |
|---|---|
| `PORT` | Frontend nginx port; default `3001` |
| `BE_SERVER_URL` | Backend URL that nginx proxies to; e.g. `http://backend:3000` |

### `VITE_API_URL` — build-time backend URL

The frontend has `VITE_API_URL` baked in at image build time (default: `http://localhost:3000`). This controls where the browser-side code sends API requests.

**For a local setup where the browser hits `localhost:3000` directly**, the default prebuilt image works fine.

**For a setup with a custom domain or reverse proxy**, build the image yourself:

```bash
docker build \
  --build-arg VITE_API_URL=https://invoices.example.com/api \
  -t invoice-builder .
# Then reference `image: invoice-builder` in your compose
```

### Features

- **Invoices & Quotes** — create, manage, and track status (unpaid/partially paid/paid/closed; open/closed for quotes)
- **Live PDF preview** — A4/Letter, multiple layout presets, color/font/logo customization
- **Multi-currency** — per-document currency selection
- **Discounts** — fixed or percentage
- **Tax** — inclusive/exclusive, per-item or on total, deducted tax
- **Partial payments** — track payment history and balance due
- **UBL / Peppol BIS 3.0 / XRechnung XML export** — for European e-invoicing compliance
- **XLSX import/export** — for businesses, banks, clients, items, categories, currencies
- **Database-file based** — create or open a database anywhere; own your data
- **Invoice translations** — per-document language, independent of app language
- **Offline-first** — works without internet

### Native desktop app

Download from [GitHub Releases](https://github.com/piratuks/invoice-builder/releases): Windows (MSI/NSIS), macOS (DMG), Linux (DEB/AppImage).

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in `app-data` named volume at `/data` in the backend container.

## Gotchas

- **`VITE_API_URL` is baked in at build time** — if your backend URL changes (e.g. you move to a custom domain), you must rebuild the frontend image. The prebuilt image defaults to `http://localhost:3000`.
- **Backend port `3000` is not exposed publicly** — the upstream compose intentionally comments out `ports: ['3000:3000']` for the backend; nginx/frontend proxies to it via the Docker network. Only port `3001` (frontend) is public.
- **`depends_on: condition: service_healthy`** — the frontend waits for the backend healthcheck to pass before starting. If the healthcheck fails repeatedly, check the backend logs.
- **`host.docker.internal`** — the backend compose entry adds `host.docker.internal:host-gateway` for access to host services if needed. Safe to leave in even if unused.
- **No built-in auth on the web UI** — the app is designed for single-user or trusted-LAN use. If exposing to the internet, add a reverse proxy with HTTPS and basic auth.
- **Migration path** — `MIGRATIONS_PATH` must point to the migrations inside the container. Don't change this unless you know what you're doing.

## Links

- Upstream README: <https://github.com/piratuks/invoice-builder>
- Container registry: <https://github.com/piratuks/invoice-builder/pkgs/container/invoice-builder>
- Releases (desktop app): <https://github.com/piratuks/invoice-builder/releases>
