---
name: vouchervault-project
description: VoucherVault recipe for open-forge. Django web app for storing and managing vouchers, coupons, gift cards, and loyalty cards. Multi-user, OIDC SSO, QR/barcode support, expiry notifications via Apprise, PWA. SQLite or PostgreSQL. Upstream: https://github.com/l4rm4nd/VoucherVault
---

# VoucherVault

A Django web application for storing and managing vouchers, coupons, gift cards, and loyalty cards digitally. Features QR/barcode display, expiry notifications via Apprise, multi-user support, OIDC SSO, and a PWA-capable mobile-optimized interface.

Upstream: <https://github.com/l4rm4nd/VoucherVault> | Wiki: <https://github.com/l4rm4nd/VoucherVault/wiki>

Runs as the `www-data` user (UID/GID 33). **Volume permissions must be set to UID/GID 33 before first start.**

## Compatible combos

| Infra | DB | Notes |
|---|---|---|
| Any Linux host | SQLite (default) | Single container; simplest setup |
| Any Linux host | PostgreSQL | Multi-container compose with separate Postgres service |
| Unraid | SQLite or PostgreSQL | Supported via Unraid Community Apps |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "FQDN or IP where VoucherVault will be served?" | `DOMAIN` env var; used for Django `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS` |
| preflight | "Using a reverse proxy with TLS?" | Set `SECURE_COOKIES=True` if yes |
| preflight | "Timezone?" | `TZ` env var; e.g. `Europe/Berlin`, `America/New_York` |
| config | "Days before expiry to send Apprise notification?" | `EXPIRY_THRESHOLD_DAYS`; default 30; also `EXPIRY_LAST_NOTIFICATION_DAYS` (default 7) |
| config (OIDC) | "Enable OIDC SSO?" | Set `OIDC_ENABLED=True` + provide OIDC endpoints/client |
| security | "Fix volume ownership?" | Run `sudo chown -R 33:33 ./volume-data` before first start |

## Software-layer concerns

### Image

```
l4rm4nd/vouchervault:v1.27.8
```

Docker Hub: <https://hub.docker.com/r/l4rm4nd/vouchervault>

> Pinning to a minor version series (e.g. `1.27.x`) is recommended over `latest` — you still get patch fixes but avoid unexpected breaking changes.

### Pre-flight: fix volume permissions

```bash
mkdir -p ./volume-data/database
sudo chown -R 33:33 volume-data/
```

The container runs as `www-data` (UID/GID 33). Without correct ownership the app fails to start.

### Compose (SQLite)

```yaml
services:
  app:
    image: l4rm4nd/vouchervault:v1.27.8
    container_name: vouchervault
    restart: unless-stopped
    environment:
      - DOMAIN=vouchervault.example.com    # your FQDN or IP
      - SECURE_COOKIES=False               # set True if behind TLS reverse proxy
      - EXPIRY_THRESHOLD_DAYS=90
      - TZ=Europe/Berlin
    ports:
      - "8000:8000"
    volumes:
      - ./volume-data/database:/opt/app/database

  redis:
    image: redis:7-alpine
    container_name: vouchervault-redis
    restart: unless-stopped
```

> Source: upstream `docker/docker-compose-sqlite.yml` — <https://github.com/l4rm4nd/VoucherVault/blob/main/docker/docker-compose-sqlite.yml>

### Default credentials

- Username: `admin`
- Password: **auto-generated** — retrieve from container logs on first run:
  ```bash
  docker compose logs -f app
  ```

### Key environment variables

| Variable | Default | Required | Purpose |
|---|---|---|---|
| `DOMAIN` | `localhost` | ✅ | FQDN(s) for `ALLOWED_HOSTS`/`CSRF_TRUSTED_ORIGINS`; comma-separate multiple |
| `SECURE_COOKIES` | `False` | | Set `True` behind TLS — enables secure cookie flag and HSTS |
| `TZ` | `Europe/Berlin` | | Django timezone |
| `SECRET_KEY` | auto-generated | | Fixed Django secret key; set to prevent session invalidation on restart |
| `PORT` | `8000` | | Only needed if serving on a non-standard port (not 80/443/8000) |
| `SESSION_EXPIRE_AT_BROWSER_CLOSE` | `True` | | Set `False` to persist sessions |
| `SESSION_COOKIE_AGE` | `30` | | Max session duration (minutes) |
| `EXPIRY_THRESHOLD_DAYS` | `30` | | Days before expiry to trigger first Apprise notification |
| `EXPIRY_LAST_NOTIFICATION_DAYS` | `7` | | Days before expiry to trigger final Apprise notification |
| `REDIS_URL` | `redis://redis:6379/0` | | Redis URL for Celery task processing |
| `CSP_FRAME_ANCESTORS` | `'none'` | | CSP frame-ancestors directive (e.g. set to your dashboard origin for iframe embedding) |
| `OIDC_ENABLED` | `False` | | Enable OIDC SSO |
| `OIDC_AUTOLOGIN` | `False` | | Auto-redirect to OIDC on login page |
| `OIDC_CREATE_USER` | `True` | | Create new users on first OIDC login |
| `OIDC_RP_SIGN_ALGO` | `HS256` | | OIDC signing algorithm (`HS256` or `RS256`) |
| `OIDC_OP_JWKS_ENDPOINT` | — | RS256 | JWKS endpoint URL (required for RS256) |
| `OIDC_RP_CLIENT_ID` | — | OIDC | OIDC client ID |
| `OIDC_RP_CLIENT_SECRET` | — | OIDC | OIDC client secret |
| `OIDC_OP_AUTHORIZATION_ENDPOINT` | — | OIDC | Authorization endpoint URL |
| `OIDC_OP_TOKEN_ENDPOINT` | — | OIDC | Token endpoint URL |
| `OIDC_OP_USER_ENDPOINT` | — | OIDC | Userinfo endpoint URL |

### Expiry notifications (Apprise)

Configure notification URLs in the VoucherVault UI under **Settings → Notifications**. Apprise supports 80+ services (Telegram, email, Slack, Gotify, Pushover, etc.).

Notifications are sent `EXPIRY_THRESHOLD_DAYS` before expiry and again `EXPIRY_LAST_NOTIFICATION_DAYS` before expiry.

### REST API

VoucherVault exposes a REST API with item stats for Home Assistant and other dashboards. API documentation is accessible from within the running app.

### Barcode / QR scanning

Client-side 1D/2D barcode scanning is supported during item creation — use the device camera or upload an image. Type is auto-detected (QR, EAN, Code128, etc.).

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

The database volume (`./volume-data/database`) persists across upgrades.

> Back up the `database` directory before major version upgrades.

## Gotchas

- **Volume permissions must be set before first start** — run `sudo chown -R 33:33 volume-data/` or the container will fail silently.
- **Retrieve the auto-generated password from logs** — `docker compose logs -f app` on first run; there is no fixed default password.
- **Redis is required** — the compose file includes a Redis service for Celery task processing (expiry notification scheduling). Do not omit it.
- **`DOMAIN` must match where you serve VoucherVault** — Django's `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS` are set from this value. A mismatch causes CSRF errors and 400s.
- **`SECURE_COOKIES=True` requires HTTPS** — only set this when behind a TLS-terminating reverse proxy; setting it on plain HTTP breaks logins.
- **`SECRET_KEY` should be set explicitly** — without it, a new key is generated on every container restart, invalidating all existing sessions.
- **Pin to a minor version tag** — `latest` may include breaking changes between major/minor versions. `1.27.x` gives you patches without unexpected upgrades.
- **`PORT` env var is only for non-standard ports** — if you map 8000:8000, you don't need to set `PORT`. Only set it if you change the container's exposed port (e.g. 9000:8000 with `PORT=9000`).

## Links

- Upstream README: <https://github.com/l4rm4nd/VoucherVault>
- Installation wiki: <https://github.com/l4rm4nd/VoucherVault/wiki/01-%E2%80%90-Installation>
- Docker Hub: <https://hub.docker.com/r/l4rm4nd/vouchervault>
- Unraid installation: <https://github.com/l4rm4nd/VoucherVault/wiki/01-%E2%80%90-Installation#unraid-installation>
