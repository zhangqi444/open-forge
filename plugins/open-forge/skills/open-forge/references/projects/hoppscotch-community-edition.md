# Hoppscotch Community Edition

Open-source API development platform and testing tool. Hoppscotch is a fast, web-based alternative to Postman/Insomnia for building, testing, and documenting APIs. Supports REST, GraphQL, WebSocket, MQTT, SSE, and Socket.IO. The self-hosted Community Edition includes team workspaces, shared collections, and an admin dashboard.

**Official site:** https://hoppscotch.io  
**Source:** https://github.com/hoppscotch/hoppscotch  
**Upstream docs:** https://docs.hoppscotch.io/documentation/self-host/community-edition/  
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (profile: default) | All-in-one: app + backend + DB |
| Any Linux host | Docker Compose (profile: default-no-db) | All-in-one without bundled DB |
| Any Linux host | Docker Compose (individual profiles) | Run components separately |

---

## Inputs to Collect

### Required
| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:testpass@hoppscotch-db:5432/hoppscotch` |
| `DATA_ENCRYPTION_KEY` | 32-character encryption key for sensitive DB data | `your-32-char-key-here!!!!!!!!` |
| `JWT_SECRET` | JWT signing secret | random string |
| `SESSION_SECRET` | Session signing secret | random string |

### Frontend URLs (must match your domain)
| Variable | Description | Default |
|----------|-------------|---------|
| `VITE_BASE_URL` | Web app public URL | `http://localhost:3000` |
| `VITE_ADMIN_URL` | Admin dashboard URL | `http://localhost:3100` |
| `VITE_BACKEND_GQL_URL` | GraphQL backend URL | `http://localhost:3170/graphql` |
| `VITE_BACKEND_WS_URL` | WebSocket backend URL | `ws://localhost:3170/graphql` |
| `VITE_BACKEND_API_URL` | REST API backend URL | `http://localhost:3170/v1` |

### Optional — OAuth
| Variable | Description |
|----------|-------------|
| `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET` | Google OAuth login |
| `GITHUB_CLIENT_ID` / `GITHUB_CLIENT_SECRET` | GitHub OAuth login |
| `MICROSOFT_CLIENT_ID` / `MICROSOFT_CLIENT_SECRET` | Microsoft OAuth login |

---

## Software-Layer Concerns

### Docker Compose profiles
Hoppscotch uses Docker Compose profiles to select deployment topology:
- `default` — full stack: app + backend + database (recommended)
- `default-no-db` — full stack without bundled Postgres (bring your own DB)
- `backend` — backend only
- `app` — frontend web app only
- `admin` — admin dashboard only
- `database` — database only

### Quick start (all-in-one)
```sh
git clone https://github.com/hoppscotch/hoppscotch.git
cd hoppscotch
cp .env.example .env
# Edit .env: set DATA_ENCRYPTION_KEY (32 chars), JWT_SECRET, SESSION_SECRET,
#             and all VITE_* URLs to match your domain
docker compose --profile default up -d
```

### Ports
| Service | Port | Description |
|---------|------|-------------|
| Web app | `3000` | Main Hoppscotch app |
| Admin | `3100` | Self-host admin dashboard |
| Backend API | `3170` | REST + GraphQL backend |
| Backend HTTP | `3180` | Additional backend port |

### WHITELISTED_ORIGINS
Set this env var to allow cross-origin communication between services:
```
WHITELISTED_ORIGINS=http://localhost:3170,http://localhost:3000,http://localhost:3100
```
Update these when changing ports or domains.

---

## Upgrade Procedure

1. `git pull` in the hoppscotch directory
2. `docker compose --profile default pull`
3. `docker compose --profile default up -d`
4. Prisma migrations run automatically on backend startup
5. Check release notes: https://github.com/hoppscotch/hoppscotch/releases

---

## Gotchas

- **DATA_ENCRYPTION_KEY must be exactly 32 characters** — shorter or longer keys will cause startup failures
- **All VITE_* URLs are baked in at build time** — if using the pre-built image, set correct URLs in `.env` before first start; changing them later requires a container rebuild
- **Profile conflicts** — `default` and `default-no-db` profiles conflict with individual service profiles; don't mix them in the same `docker compose up` command
- **WHITELISTED_ORIGINS must list all accessing origins** — missing an origin causes CORS errors in the browser
- **Subpath deployment** — set `ENABLE_SUBPATH_BASED_ACCESS=true` if hosting under a URL path (e.g., `example.com/hoppscotch`) instead of a subdomain

---

## Links
- Upstream README: https://github.com/hoppscotch/hoppscotch
- Self-hosting docs: https://docs.hoppscotch.io/documentation/self-host/community-edition/
- .env configuration reference: https://docs.hoppscotch.io/documentation/self-host/community-edition/env-variables
