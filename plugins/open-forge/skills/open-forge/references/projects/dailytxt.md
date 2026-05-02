---
name: dailytxt-project
description: DailyTxT recipe for open-forge. Encrypted diary/journal web app with markdown, tags, search, map, file uploads, image gallery, templates, multi-user, and export. Built with Svelte + Go. Upstream: https://github.com/PhiTux/DailyTxT
---

# DailyTxT

An encrypted diary/journal web app. Everything you write — text, files, images — is encrypted client-side before it reaches the server. Even the server admin cannot read entries. Supports markdown, tags, search, a location map, file uploads, image galleries, custom templates, multi-user accounts, and HTML export.

Upstream: <https://github.com/PhiTux/DailyTxT> | Demo: <https://dailytxt.phitux.de>

Built with Svelte (frontend) and Go (backend). AMD64 and ARM64 Docker images. PWA-capable.

> ⚠️ **Migrating from v1?** Read the [Migration Instructions](https://github.com/PhiTux/DailyTxT#migration-instructions) before upgrading. Version 2 has breaking changes from 1.0.15.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host (AMD64/ARM64) | Docker Compose | Single container; data in bind-mount |
| Sub-path deployment | Docker Compose | Set `BASE_PATH` env var |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port to bind DailyTxT on?" | Default: `8000` (host); container port `80`; bind to `127.0.0.1` for reverse-proxy-only access |
| security | "Generate a SECRET_TOKEN?" | Run `openssl rand -base64 32`; required |
| security | "Set an ADMIN_PASSWORD?" | Required for the admin panel |
| config | "Allow new user registrations?" | `ALLOW_REGISTRATION=true` for initial setup; disable after first user |
| config | "Sub-path deployment?" | Set `BASE_PATH=/yourpath` (e.g. `/dailytxt`) |
| config | "Session cookie lifetime?" | `LOGOUT_AFTER_DAYS` — default: `40` |

## Software-layer concerns

### Image

```
phitux/dailytxt:2.x.x
```

Docker Hub: <https://hub.docker.com/r/phitux/dailytxt>

> Pin to a minor version series (e.g. `2.x.x`). Avoid `-testing.N` tags in production — those are explicitly unstable.

### Compose

```yaml
services:
  dailytxt:
    image: phitux/dailytxt:2.x.x
    container_name: dailytxt
    restart: unless-stopped
    volumes:
      - ./data:/data
    environment:
      # Required: generate with `openssl rand -base64 32`
      - SECRET_TOKEN=your_secret_token_here

      # Admin panel password
      - ADMIN_PASSWORD=your_admin_password

      # Pretty-print stored JSON files (optional; remove line to disable)
      - INDENT=4

      # Allow new registrations — disable after first user setup
      - ALLOW_REGISTRATION=true

      # Session cookie lifetime in days
      - LOGOUT_AFTER_DAYS=40

      # Sub-path (only if running under a prefix, e.g. /dailytxt)
      # - BASE_PATH=/dailytxt
    ports:
      # Bind to 127.0.0.1 for reverse-proxy-only access (recommended)
      - "127.0.0.1:8000:80"
```

> Source: upstream docker-compose.yml — <https://github.com/PhiTux/DailyTxT/blob/main/docker-compose.yml>

### Key environment variables

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `SECRET_TOKEN` | ✅ | — | JWT signing secret; generate with `openssl rand -base64 32` |
| `ADMIN_PASSWORD` | ✅ | — | Password for the admin panel |
| `ALLOW_REGISTRATION` | | `false` | Set `true` to allow new sign-ups (disable after initial setup) |
| `LOGOUT_AFTER_DAYS` | | `40` | Login cookie lifetime (days) |
| `INDENT` | | — | JSON indentation level for stored files (omit for minified) |
| `BASE_PATH` | | — | Sub-path prefix if running under a directory (e.g. `/dailytxt`) |

### Data directory

All data is stored in `/data` inside the container. Bind-mount a host path:

```yaml
volumes:
  - ./data:/data
```

The data directory contains encrypted journal entries, uploaded files, and user accounts. Back it up regularly.

### Encryption model

All content is encrypted client-side in the browser using a key derived from the user's password. The server stores and serves only ciphertext. This means:
- Lost password = lost data (no password recovery)
- Each user account has its own independent encryption key
- Admin can manage users but cannot read any entries

### Admin panel

Access at `/admin` (or `<BASE_PATH>/admin`). Capabilities:
- Create/manage user accounts
- Temporarily enable registration for 5 minutes
- Other server management tasks

### Reverse proxy

DailyTxT has no built-in TLS. Front it with Caddy, Traefik, or nginx. The compose file binds to `127.0.0.1:8000` by default — only the reverse proxy can reach it externally.

If serving under a sub-path (e.g. `https://example.com/dailytxt/`), set `BASE_PATH=/dailytxt`.

### Export

Users can export all their entries (including uploaded files) to a self-contained HTML archive from the Settings panel.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

> **Migrating from v1 to v2:** Follow the [migration guide](https://github.com/PhiTux/DailyTxT#migration-instructions) before pulling `2.x.x`. Do not skip this step — v2 has a different data format.

Data in the `./data` bind-mount persists across upgrades. Back up before any major version bump.

## Gotchas

- **`SECRET_TOKEN` is required** — without it the container will not start. Generate with `openssl rand -base64 32`.
- **Password loss = data loss** — encryption keys are derived from user passwords. There is no server-side recovery.
- **Disable registration after setup** — `ALLOW_REGISTRATION=true` should only be set for initial user creation. Disable it (or manage via the admin panel's 5-minute temp-enable) to prevent unauthorized accounts.
- **v1 → v2 migration is mandatory** — do not just pull `2.x.x` over v1 data without following the migration guide.
- **Avoid `-testing.N` tags** — these are explicitly unstable pre-release builds. Stick to `2.x.x` for production.
- **Bind to `127.0.0.1`** — the upstream compose exposes port `8000` to all interfaces without TLS; binding to localhost and using a reverse proxy for HTTPS is strongly recommended.
- **`INDENT` is cosmetic** — it pretty-prints the server-stored JSON. Encrypted data is identical either way; omit for smaller files.

## Links

- Upstream README + migration instructions: <https://github.com/PhiTux/DailyTxT>
- Docker Hub: <https://hub.docker.com/r/phitux/dailytxt>
- Demo: <https://dailytxt.phitux.de>
