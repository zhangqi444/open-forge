# 4ga Boards

**Real-time Kanban project management**
Official site: https://4gaboards.com

4ga Boards is a straightforward Kanban-style boards system with real-time updates, advanced markdown editing, SSO (Google/GitHub/Microsoft/OIDC), multi-level hierarchy (projects → boards → lists → cards → tasks), export/import, and multi-language support. Built with Node.js and PostgreSQL.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | Single app container + Postgres |
| Kubernetes | Helm / manifests | See upstream k8s docs |
| TrueNAS | Community app | Available in TrueNAS app catalog |

## Inputs to Collect

### Phase: Pre-deployment (required)
- `BASE_URL` — public URL of the instance (e.g. `http://boards.example.com:3000`)
- `SECRET_KEY` — random secret for session signing (`openssl rand -hex 64`)
- `POSTGRES_PASSWORD` — PostgreSQL password (replace `notpassword`)
- `DATABASE_URL` — PostgreSQL connection string (update password to match)

## Software-Layer Concerns

**Docker image:** `ghcr.io/rargames/4gaboards:latest`

**Volumes:**
- `user-avatars:/app/public/user-avatars`
- `project-background-images:/app/public/project-background-images`
- `attachments:/app/private/attachments`
- `db-data:/var/lib/postgresql/data`

**Port:** `3000` → container's `1337`

**Key env vars:**
| Variable | Purpose |
|----------|---------|
| `BASE_URL` | Public URL — used for links and redirects |
| `SECRET_KEY` | Session/auth signing key |
| `DATABASE_URL` | PostgreSQL connection string |
| `NODE_ENV` | Set to `production` |

**PostgreSQL image:** `postgres:16-alpine` with `POSTGRES_INITDB_ARGS: '-A scram-sha-256'` (stronger auth)

**Health check:** Postgres service has a built-in healthcheck; app waits for `service_healthy` before starting.

## Upgrade Procedure

1. Pull latest images: `docker-compose pull`
2. Recreate: `docker-compose up -d`
3. Database migrations run automatically on startup
4. Attachment and avatar volumes persist across upgrades
5. Check [release notes](https://github.com/RARgames/4gaBoards/releases) before major upgrades

## Gotchas

- **Change default credentials** — `docker-compose.yml` ships with `notpassword` and `notsecretkey`; must be replaced before deployment
- **`BASE_URL` must match actual URL** — SSO redirects and internal links depend on this; mismatch causes auth failures
- **`SECRET_KEY` must stay consistent** — changing it after first run invalidates all existing sessions
- **SCRAM-SHA-256 auth** — the `POSTGRES_INITDB_ARGS` flag uses stronger password hashing; ensure `DATABASE_URL` credentials match exactly
- **Real-time via WebSocket** — ensure your reverse proxy passes WebSocket upgrades (`Upgrade` header) for live updates to work

## References
- Upstream README: https://github.com/RARgames/4gaBoards/blob/main/README.md
- Docker Compose: https://github.com/RARgames/4gaBoards/blob/main/docker-compose.yml
- Full docs: https://docs.4gaboards.com
