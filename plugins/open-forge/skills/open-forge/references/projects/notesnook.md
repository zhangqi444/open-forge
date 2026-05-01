# Notesnook Sync Server

**Self-hosted sync server for the Notesnook end-to-end encrypted note-taking app.**
Official site: https://notesnook.com
GitHub: https://github.com/streetwriters/notesnook-sync-server

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Multi-service stack (API + Identity + SSE + MongoDB + MinIO) |

---

## Inputs to Collect

### All phases
- `INSTANCE_NAME` — name for this instance
- `NOTESNOOK_API_SECRET` — shared secret for API auth
- `DISABLE_SIGNUPS` — `true` or `false`
- `SMTP_USERNAME`, `SMTP_PASSWORD`, `SMTP_HOST`, `SMTP_PORT` — email server for account verification
- `AUTH_SERVER_PUBLIC_URL` — public URL of the identity server
- `NOTESNOOK_APP_PUBLIC_URL` — public URL of the Notesnook app
- `MONOGRAPH_PUBLIC_URL` — public URL of the monograph server
- `ATTACHMENTS_SERVER_PUBLIC_URL` — public URL for S3/MinIO attachments
- `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD` — MinIO credentials (default: `minioadmin`)

---

## Software-Layer Concerns

### Config
- All config in a `.env` file at the project root
- A `validate` container checks all required env vars are set before services start
- Client apps must be configured to point to self-hosted server URLs (Notesnook v3.0.18+)

### Data
- MongoDB 7.0 with replica set for note/sync data (volume: `dbdata`)
- MinIO for S3-compatible attachment storage (volume: `s3data`)

### Services and Ports
- `5264` — Notesnook API server
- `8264` — Identity server (auth/accounts)
- `7264` — SSE server (real-time events)
- `6264` → `3000` — Monograph server (published notes)
- `9000` — MinIO (internal S3)

---

## Upgrade Procedure

1. `docker compose pull`
2. `docker compose up -d`
3. Check logs: `docker compose logs -f`

---

## Gotchas

- Self-hosting is functional but **officially unsupported** — documentation is still in progress as of the README
- All required env vars must be set or the stack will refuse to start (enforced by the `validate` service)
- MongoDB runs as a replica set — required for Notesnook's transactional operations
- `autoheal` container automatically restarts unhealthy services
- Notesnook client apps need v3.0.18+ to support custom server URLs

---

## References
- [Official Self-Hosting Docs (in progress)](https://notesnook.com)
- [GitHub README](https://github.com/streetwriters/notesnook-sync-server#readme)
