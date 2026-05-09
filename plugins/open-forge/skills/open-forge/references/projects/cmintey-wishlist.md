---
name: cmintey-wishlist
description: Wishlist recipe for open-forge. Self-hosted sharable wishlist application for friends and family. MIT license. Docker Compose deploy — single container with SQLite. Upstream: https://github.com/cmintey/wishlist
---

# Wishlist (cmintey)

Self-hosted sharable wishlist app. Lets users build personal wishlists that friends and family can browse, claim items from, and check off as purchased. Supports multiple groups, a Registry Mode (single public list, no login required for claimers), and OAuth/OIDC authentication. MIT license. Upstream: <https://github.com/cmintey/wishlist>.

## Compatible install methods

| Method | Upstream source | When to use |
|---|---|---|
| Docker Compose (single container) | <https://github.com/cmintey/wishlist#getting-started> | Recommended. Single container, SQLite database, zero external deps. |
| Kubernetes (Helm chart) | <https://github.com/mddeff/wishlist-charts> | Community-maintained Helm chart — not first-party. |

## Requirements

- Docker + Docker Compose
- Domain or LAN IP for `ORIGIN` env var (required)

## Method — Docker Compose

> **Source:** <https://github.com/cmintey/wishlist#getting-started>

### 1 — Create `docker-compose.yml`

```yaml
services:
  wishlist:
    container_name: wishlist
    image: ghcr.io/cmintey/wishlist:latest
    ports:
      - "3280:3280"
    volumes:
      - ./uploads:/usr/src/app/uploads   # user image uploads
      - ./data:/usr/src/app/data         # SQLite database
    environment:
      ORIGIN: http://192.168.1.10:3280   # URL users connect to — must include port if using IP
      # ORIGIN: https://wishlist.example.com
      TOKEN_TIME: 72    # hours until signup/password-reset tokens expire
    restart: unless-stopped
```

> **Important:** `ORIGIN` must exactly match the URL users browse to. If set to an IP address it must include the exposed port. Incorrect `ORIGIN` causes CSRF/cookie failures.

### 2 — Start

```bash
docker compose up -d
```

Access at `http://<host>:3280` (or your configured domain). The first-run wizard creates the admin account.

### 3 — Optional environment variables

| Variable | Default | Notes |
|---|---|---|
| `ORIGIN` | *(required)* | Full URL users will use, e.g. `https://wishlist.example.com`. |
| `TOKEN_TIME` | `72` | Signup/password-reset token TTL in hours. |
| `DEFAULT_CURRENCY` | *(none)* | ISO currency code, e.g. `USD`, `EUR`. Per-item override still available. |
| `MAX_IMAGE_SIZE` | `5000000` | Max upload size in bytes (default 5 MB). |

### Updating

```bash
docker compose pull && docker compose up -d
```

## Reverse proxy notes

Wishlist does **not** support running on a subpath (e.g. `https://domain.com/wishlist`) — must be at a root path.

**NGINX / Synology NAS:** Known issue with buffering. Add to NGINX config:
```nginx
proxy_buffer_size   128k;
proxy_buffers       4 256k;
proxy_busy_buffers_size 256k;
```

## Features overview

- **Wishlist groups** — multiple groups (friends vs. family), separate item pools.
- **Registry Mode** — single-list mode with a shareable public link; claimers don't need an account.
- **Item auto-fill** — paste a URL to auto-fetch product name, price, and image.
- **Suggestions** — add items to someone else's list (Approval Required / Auto Approval / Surprise Me modes).
- **SMTP** — optional; enables email invites and password-reset flow. Without SMTP, invite links are generated manually.
- **OAuth (OIDC)** — authenticate via Authelia, Authentik, Keycloak, Google, etc. Configure in the admin panel (Issuer URL + Client ID + Secret). First user must be created via the setup wizard with credentials.
- **PWA** — installable as a Progressive Web App on mobile.

## SMTP configuration (optional)

Configure in the admin panel under Settings → SMTP, or set environment variables:

```
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=user@example.com
SMTP_PASS=secret
SMTP_FROM=wishlist@example.com
```

Without SMTP, invite links and password-reset links are generated in the admin panel for manual sharing.

## Ports

| Port | Service |
|---|---|
| 3280 | Wishlist web UI (HTTP) |

## License

MIT — <https://github.com/cmintey/wishlist/blob/main/LICENSE>
