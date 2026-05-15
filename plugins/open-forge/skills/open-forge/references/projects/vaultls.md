---
name: vaultls-project
description: VaulTLS recipe for open-forge. Modern mTLS and TLS certificate management platform for home labs. Centralised web UI for generating, managing, and distributing X.509 and SSH certificates. Built with Rust + Vue.js. Upstream: https://github.com/7ritn/VaulTLS
---

# VaulTLS

A modern, centralised platform for managing mTLS (mutual TLS) and TLS X.509/SSH certificates — built for home labs that need an overview of certificate lifetimes and want to avoid raw OpenSSL scripts. Upstream: <https://github.com/7ritn/VaulTLS>.

Built with Rust (backend) + Vue.js (frontend). Container image available via GitHub Container Registry. Persistent data stored in a single SQLite database.

## Features

- X.509 TLS certificate management (CAs, server certs, client certs)
- SSH certificate management
- OIDC authentication support
- Email notifications for certificate expiration
- RESTful API for automation
- mTLS — the CA cert at `/app/data/ca/ca.cert` can be integrated directly into reverse proxies

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker / Podman | Primary deployment path |
| Podman-first | Containerfile | Upstream uses `Containerfile` (Podman convention) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Public URL where VaulTLS will be served?" | Required as `VAULTLS_URL` — e.g. `https://vaultls.example.com/` |
| preflight | "Which host port to bind to?" | Default: `5173` (maps container `:80`) |
| security | "Generate a 256-bit base64 API secret?" | Run `openssl rand -base64 32`; required as `VAULTLS_API_SECRET` |
| security | "Encrypt the database at rest?" | Optional; set `VAULTLS_DB_SECRET` (256-bit base64) — irreversible once set |
| auth | "Use OIDC authentication?" | Optional — configure via env vars or the web UI after first run |
| auth (if OIDC) | "OIDC auth URL, callback URL, client ID, client secret?" | See OIDC table below |
| smtp | "Email for certificate expiration notifications?" | Configured via the web UI under Settings after first run |

## Software-layer concerns

### Image

```
ghcr.io/7ritn/vaultls:v1.1.1
```

### Compose

```yaml
services:
  vaultls:
    image: ghcr.io/7ritn/vaultls:v1.1.1
    restart: unless-stopped
    ports:
      - "5173:80"
    volumes:
      - vaultls-data:/app/data
    environment:
      - VAULTLS_API_SECRET=<openssl rand -base64 32>
      - VAULTLS_URL=https://vaultls.example.com/
      # Optional:
      # - VAULTLS_DB_SECRET=<openssl rand -base64 32>
      # - VAULTLS_INSECURE=true            # only if NOT using HTTPS
      # - VAULTLS_LOG_LEVEL=info           # trace/debug/info/warn/error

volumes:
  vaultls-data:
```

> Source: upstream README — <https://github.com/7ritn/VaulTLS>

### Key environment variables

| Variable | Required | Purpose |
|---|---|---|
| `VAULTLS_API_SECRET` | ✅ | 256-bit base64 secret for API signing (`openssl rand -base64 32`) |
| `VAULTLS_URL` | ✅ | Public URL VaulTLS is served on (include trailing slash) |
| `VAULTLS_DB_SECRET` | Optional | Encrypts the SQLite database at rest (irreversible) |
| `VAULTLS_INSECURE` | Optional | Set `true` to allow non-HTTPS access (dev/LAN only) |
| `VAULTLS_LOG_LEVEL` | Optional | Log verbosity: `trace`, `debug`, `info`, `warn`, `error` |
| `VAULTLS_OIDC_AUTH_URL` | OIDC only | Auth provider URL |
| `VAULTLS_OIDC_CALLBACK_URL` | OIDC only | `https://vaultls.example.com/api/auth/oidc/callback` |
| `VAULTLS_OIDC_ID` | OIDC only | OIDC client ID |
| `VAULTLS_OIDC_SECRET` | OIDC only | OIDC client secret |

### Container secrets support

Sensitive env vars can be supplied as container secrets (read from `/run/secrets/<ENV_NAME>`):
- `VAULTLS_API_SECRET`
- `VAULTLS_DB_SECRET`
- `VAULTLS_OIDC_SECRET`

### OIDC setup (example: Authelia)

```yaml
- client_id: "<client_id>"
  client_name: "vaultls"
  client_secret: "<client_secret_hash>"
  public: false
  authorization_policy: "one_factor"
  pkce_challenge_method: "S256"
  redirect_uris:
    - "https://vaultls.example.com/api/auth/oidc/callback"
  scopes:
    - "openid"
    - "profile"
    - "email"
  userinfo_signed_response_alg: "none"
```

VaulTLS env vars for OIDC:

| Variable | Value |
|---|---|
| `VAULTLS_OIDC_AUTH_URL` | `https://auth.example.com` |
| `VAULTLS_OIDC_CALLBACK_URL` | `https://vaultls.example.com/api/auth/oidc/callback` |
| `VAULTLS_OIDC_ID` | `<client_id>` |
| `VAULTLS_OIDC_SECRET` | `<client_secret>` |

On first OIDC login, VaulTLS matches the email to existing users. If no match, a new user is created.

### Data paths inside the container

| Path | Purpose |
|---|---|
| `/app/data` | All persistent data (SQLite DB, CA cert, private keys) |
| `/app/data/ca/ca.cert` | Current CA certificate — integrate this into your reverse proxy for mTLS |

### Reverse proxy / mTLS integration

VaulTLS should run **behind** a reverse proxy that terminates TLS. The generated CA cert at `/app/data/ca/ca.cert` can be mounted into your reverse proxy to enable mTLS for downstream services.

API documentation is available at `/api` once running.

### Certificate download format

Client certificates are downloaded as PKCS#12 bundles (public cert + private key). Password requirements for PKCS#12 files can be configured in the VaulTLS Settings page:

- No password (default)
- Optional password
- Required password

### User access model

- Regular users see only their own certificates
- Admins can create certificates for any user
- Users log in via password or OIDC
- First-run creates a CA automatically; no OIDC password setup required if OIDC is configured

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data in the named volume `/app/data` persists across upgrades.

## Gotchas

- **`VAULTLS_API_SECRET` is required** — the container will not start without it. Generate with `openssl rand -base64 32`.
- **`VAULTLS_URL` must include the trailing slash** — e.g. `https://vaultls.example.com/` not `https://vaultls.example.com`.
- **`VAULTLS_DB_SECRET` is irreversible** — once the database is encrypted, it cannot be un-encrypted. Treat this secret like a backup key and store it securely.
- **HTTPS is required by default** — set `VAULTLS_INSECURE=true` only for local development or LAN deployments where HTTPS is not available.
- **Must run behind a reverse proxy** — VaulTLS does not handle TLS itself. Use Caddy, Traefik, or nginx with Let's Encrypt for the public-facing HTTPS.
- **CA cert location** — the current CA at `/app/data/ca/ca.cert` is what you add to your browser/reverse proxy trust store for mTLS to work. Access it also via API: `GET /api/certificates/ca/download`.
- **For bug reports, use `VAULTLS_LOG_LEVEL=trace`** — note that trace logs contain secrets; don't share them publicly.
- **Podman-first** — the upstream uses a `Containerfile` and Podman examples, but standard Docker/Docker Compose works identically.

## Links

- Upstream README: <https://github.com/7ritn/VaulTLS>
- API docs: served at `/api` on your running instance
