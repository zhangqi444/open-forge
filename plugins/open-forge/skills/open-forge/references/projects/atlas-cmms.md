# Atlas CMMS

**What it is:** Open-source Computerized Maintenance Management System (CMMS) for enterprise maintenance tracking — work orders, asset management, preventive maintenance scheduling, parts inventory, and analytics.

**Official site:** https://atlas-cmms.com  
**GitHub:** https://github.com/Grashjs/cmms  
**Docker Hub:** `intelloop/atlas-cmms-backend`, `intelloop/atlas-cmms-frontend`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended path; four-container stack |
| Bare metal | Docker Compose | Same as above |

---

## Stack Components

The Compose file spins up four containers:

| Container | Image | Default Port |
|-----------|-------|-------------|
| `atlas_db` | `postgres:16-alpine` | 5432 |
| `atlas-cmms-backend` | `intelloop/atlas-cmms-backend` | 8080 |
| `atlas-cmms-frontend` | `intelloop/atlas-cmms-frontend` | 3000 |
| `atlas_minio` | `minio/minio` (2025-04-22) | 9000 / 9001 |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `POSTGRES_USER` | PostgreSQL username |
| `POSTGRES_PWD` | PostgreSQL password |
| `PUBLIC_API_URL` | Public URL of the backend API (e.g. `http://your-domain:8080`) |
| `PUBLIC_FRONT_URL` | Public URL of the frontend (e.g. `http://your-domain:3000`) |
| `JWT_SECRET_KEY` | Secret for JWT token signing — generate a strong random string |
| `MINIO_USER` | MinIO root username |
| `MINIO_PASSWORD` | MinIO root password |

### Phase: Optional / Advanced

| Variable | Description |
|----------|-------------|
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PWD`, `SMTP_FROM` | Email for notifications |
| `MAIL_RECIPIENTS` | Default notification recipients |
| `GCP_BUCKET_NAME`, `GCP_JSON`, `GCP_PROJECT_ID` | Google Cloud Storage (alternative to MinIO) |
| `GOOGLE_KEY`, `GOOGLE_TRACKING_ID` | Google Maps / Analytics integrations |
| `INVITATION_VIA_EMAIL` | `true` to enable email-based user invitations |
| `ENABLE_SSO`, `OAUTH2_PROVIDER` | SSO/OAuth2 support |
| `LDAP_URL`, `LDAP_BASE_DN`, etc. | LDAP/AD integration |
| `SPRING_PROFILES_ACTIVE` | Spring Boot profile (e.g. `prod`) |

---

## Software-Layer Concerns

- **Config paths / volumes:**
  - `./logo` → `/app/static/images` — custom logo for the instance
  - `./config` → `/app/static/config` — static config overrides
  - `postgres_data` named volume — database persistence
  - `minio_data` named volume — file/attachment storage
- **MinIO is the default file store.** GCP Storage is available as an alternative via env vars.
- **API URL must be reachable from the browser** — `PUBLIC_API_URL` is embedded into the frontend at build time.
- **JWT_SECRET_KEY** must be set before first boot and kept stable; rotating it invalidates all active sessions.
- **LDAP sync** is off by default (`LDAP_SYNC_ENABLED=false`).

---

## Upgrade Procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Check backend logs for any migration output: `docker compose logs atlas-cmms-backend`

---

## Gotchas

- Both `PUBLIC_API_URL` and `PUBLIC_FRONT_URL` must use publicly-reachable URLs — localhost won't work if accessed from other machines.
- MinIO console is exposed on port 9001 — restrict or proxy if exposing to the internet.
- The `GOOGLE_KEY` / `GOOGLE_TRACKING_ID` vars default to a single space (`" "`) — leave them blank or set real values.
- `SPRING_PROFILES_ACTIVE` controls backend profile; leaving it unset defaults to the embedded default profile.

---

## Links

- Docs / Website: https://atlas-cmms.com
- GitHub: https://github.com/Grashjs/cmms
