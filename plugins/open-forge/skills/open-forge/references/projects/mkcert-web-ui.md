# mkcert Web UI

Modern web interface for generating and managing local development SSL certificates using the [mkcert](https://github.com/FiloSottile/mkcert) CLI tool. Supports multiple certificate formats (PEM, CRT, PFX/PKCS#12), SCEP for device auto-enrollment, flexible auth (basic auth or OIDC SSO), email notifications for expiring certs, and certificate monitoring.

- **Upstream repo:** <https://github.com/jeffcaldwellca/mkcertWeb>
- **Docker Hub:** `jeffcaldwellca/mkcertweb`
- **License:** Check repo for license details

---

## Compatible Combos

| Infra      | Runtime        | Notes                                      |
|------------|----------------|--------------------------------------------|
| Any Linux  | Docker Compose | Official path; compose file in repo root   |
| Any Linux  | Docker (single) | Works standalone                          |
| Local dev  | Node.js        | `npm install && npm start` (requires mkcert + OpenSSL) |

---

## Inputs to Collect

**Phase: Pre-deploy**
- `AUTH_USERNAME` / `AUTH_PASSWORD` — basic auth credentials (change from defaults)
- `SESSION_SECRET` — random secret string for session signing
- `ENABLE_AUTH` — set `true` in production (default is `false`)

**Phase: Optional**
- OIDC SSO: `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_CALLBACK_URL`
- Email notifications: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `EMAIL_FROM`, `EMAIL_TO`
- HTTPS: `ENABLE_HTTPS=true`, `HTTPS_PORT=3443`, `SSL_DOMAIN`

---

## Software-Layer Concerns

**Quick start:**
```bash
git clone https://github.com/jeffcaldwellca/mkcertWeb.git
cd mkcertWeb
docker-compose up -d
# Access at http://localhost:3000
```

**Ports:**
- `3000` — HTTP
- `3443` — HTTPS (if `ENABLE_HTTPS=true`)

**Data volumes:**
- `mkcert_certificates:/app/certificates` — generated certs (persist this)
- `mkcert_data:/app/data` — app data

**Rate limiting defaults (configurable):**
- CLI operations: 10 per 15 min window
- API requests: 100 per 15 min window
- Auth attempts: 5 per 15 min window

**Security features built in:**
- Command injection protection
- Path traversal prevention
- Rate limiting on all endpoints

---

## Upgrade Procedure

```bash
docker-compose pull
docker-compose up -d
```

Check [Docker Hub tags](https://hub.docker.com/r/jeffcaldwellca/mkcertweb/tags) for latest version. Tag in default compose is pinned (`3.1.2` as of writing) — update the tag in `docker-compose.yml` when upgrading.

---

## Gotchas

- **Enable auth in production** — `ENABLE_AUTH` defaults to `false` and `AUTH_PASSWORD` defaults to `admin`. Always set these before exposing to a network.
- **`SESSION_SECRET` must be changed** — the default value `mkcert-web-ui-secret-key-change-in-production` is public; generate a random string.
- **mkcert is for local/internal CAs only** — certificates generated are trusted by devices that have installed your local CA. Not a replacement for Let's Encrypt for public-facing services.
- **SCEP support** — useful for automatically enrolling mobile devices or network equipment; see upstream docs.
- **Image tag pinned** — the default docker-compose pins a specific version tag; pull the latest tag consciously rather than assuming `:latest` is available.

---

## Links

- Upstream README: <https://github.com/jeffcaldwellca/mkcertWeb#readme>
- DOCKER.md: <https://github.com/jeffcaldwellca/mkcertWeb/blob/main/DOCKER.md>
- Docker Hub: <https://hub.docker.com/r/jeffcaldwellca/mkcertweb>
- mkcert (upstream CLI): <https://github.com/FiloSottile/mkcert>
