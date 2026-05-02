---
name: specifically-clementines
description: Specifically Clementines recipe for open-forge. Self-hosted grocery list app with real-time multi-user sync via CouchDB. Based on upstream docs at https://davideshay.github.io/groceries/.
---

# Specifically Clementines (Groceries)

Self-hosted grocery list app focused on reliable real-time sync across multiple devices and users. Supports multiple lists, list groups (shop multiple stores in one trip), offline mode, category/aisle sorting, and recipe integration (including Tandoor import). Upstream: <https://github.com/davideshay/groceries>. Docs: <https://davideshay.github.io/groceries/>.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Docker host (VPS, home server) | Docker Compose (simple) | Uses `docker-simple.tar.gz` from upstream — CouchDB + backend + nginx |
| Any Docker host with domain + TLS | Docker Compose (full, with Caddy) | Uses `docker-full.tar.gz` from upstream — adds Caddy reverse proxy for HTTPS |

> **Note:** Mobile clients (Android/iOS) require `COUCHDB_URL` to be set to a hostname or IP reachable from the device — `localhost` will not work for mobile sync.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Simple (localhost only) or full (with domain + HTTPS)?" | Determines which compose tarball to use |
| network | "CouchDB URL reachable by mobile devices?" | e.g. `http://192.168.1.100:5984` or `https://db.example.com` — must be routable from the phone |
| security | "CouchDB admin password?" | Change from default in `admin.ini` and `docker-compose.yml` |
| security | "HMAC key for JWT (base64 encoded)?" | Set in `jwt.ini` — generate with `openssl rand -base64 32` |
| smtp | "SMTP host/port/user/pass for password reset emails?" | Optional but recommended |
| smtp | "From email address?" | Used for password reset and notifications |

## Software-layer concerns

**Config files** (from upstream docker-simple / docker-full archives):

| File | Purpose |
|---|---|
| `docker-compose.yml` | Service definitions (CouchDB + groceries backend + nginx/Caddy) |
| `dbetclocal/admin.ini` | CouchDB admin username/password |
| `dbetclocal/jwt.ini` | HMAC key for JWT auth (`hmac:_default = <base64-key>`); also sets `single_node` to auto-create system DBs |
| `groceries-web.conf` | nginx config for the frontend/proxy |

**Data directories / volumes:**

| Host path | Purpose |
|---|---|
| `./dbdata` | CouchDB database files |
| `./dbetclocal` | CouchDB config files (`admin.ini`, `jwt.ini`) |

**Key env vars** (in compose `CHANGEME` sections):

| Variable | Purpose |
|---|---|
| `COUCHDB_URL` | URL the backend uses to reach CouchDB |
| `COUCHDB_ADMIN_PASSWORD` | Must match `admin.ini` |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASSWORD` | Email config for password reset |

**Ports:**
- `8100` — Groceries web app (Ionic/Capacitor PWA)
- `5984` — CouchDB admin UI (restrict in production)

## Upgrade procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose down && docker compose up -d`
3. CouchDB data is persisted in `./dbdata` — no migration steps documented for minor upgrades.
4. Check CouchDB admin UI at `http://localhost:5984/_utils` to verify system databases exist after upgrade.

## Gotchas

- CORS must be open in CouchDB for mobile clients — the compose setup configures this automatically, but verify after changes.
- The `single_node` setting in `jwt.ini` triggers CouchDB to auto-create `_users` and `_replicator` on first start — required for the app to function.
- Changing the HMAC key invalidates all active sessions — do it once during initial setup.
- Changing the CouchDB admin password: either edit `admin.ini` (config-as-code) or change via CouchDB admin UI; then update `COUCHDB_ADMIN_PASSWORD` in compose and restart.
- Mobile apps require HTTPS if accessing over the internet; for LAN-only use, HTTP + local IP is sufficient.

## Links

- GitHub: <https://github.com/davideshay/groceries>
- Full docs: <https://davideshay.github.io/groceries/>
- Installation guide: <https://davideshay.github.io/groceries/installation/installation/>
- Docker setup: <https://davideshay.github.io/groceries/installation/docker-setup/>
