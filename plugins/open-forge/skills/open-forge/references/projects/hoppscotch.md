---
name: Hoppscotch
description: "Open-source API development ecosystem — a fast, browser-based alternative to Postman/Insomnia. Supports REST, GraphQL, WebSocket, SSE, Socket.IO, and MQTT. Self-host the Community Edition with Docker + PostgreSQL. MIT license for CE."
---

# Hoppscotch

**What it is:** Lightweight, web-based API client for building, testing, and sharing API requests. Community Edition is fully self-hostable and MIT-licensed. Supports REST, GraphQL, WebSocket, SSE, Socket.IO, and MQTT in a single interface. Includes team workspaces, collections, environments, and history.

**Official site:** https://hoppscotch.io
**Docs (self-host):** https://docs.hoppscotch.io/documentation/self-host/community-edition/install-and-build
**GitHub:** https://github.com/hoppscotch/hoppscotch
**License:** MIT (Community Edition)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker Compose | Any Linux host | Recommended; all-in-one profile |
| Docker Compose | External PostgreSQL | Use `default-no-db` profile |
| Kubernetes / Helm | Any cluster | Helm chart available |

---

## Inputs to Collect

### Required
- `DATABASE_URL` — PostgreSQL connection string (e.g. `postgresql://postgres:pass@hoppscotch-db:5432/hoppscotch`)
- `DATA_ENCRYPTION_KEY` — exactly 32 characters; used to encrypt secrets stored in DB
- `VITE_BASE_URL` — public URL where the app will be served (e.g. `https://hopp.example.com`)
- `VITE_ADMIN_URL` — public URL for the admin dashboard (e.g. `https://hopp-admin.example.com`)
- `VITE_BACKEND_GQL_URL` — backend GraphQL URL (e.g. `https://hopp-api.example.com/graphql`)
- `VITE_BACKEND_WS_URL` — backend WebSocket URL (e.g. `wss://hopp-api.example.com/graphql`)
- `VITE_BACKEND_API_URL` — backend REST URL (e.g. `https://hopp-api.example.com/v1`)

### Auth providers (at least one required for login)
- Google OAuth: `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_CALLBACK_URL`
- GitHub OAuth: `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `GITHUB_CALLBACK_URL`
- Microsoft OAuth: `MICROSOFT_CLIENT_ID`, `MICROSOFT_CLIENT_SECRET`, `MICROSOFT_CALLBACK_URL`
- Email/password: `MAILER_SMTP_URL`, `MAILER_ADDRESS_FROM` (enables magic-link login)

### Optional
- `WHITELISTED_ORIGINS` — comma-separated allowed CORS origins
- `TRUST_PROXY` — set `true` when behind a reverse proxy
- `ENABLE_SUBPATH_BASED_ACCESS` — set `true` for subpath routing (e.g. `/app`, `/admin`)

---

## Software-Layer Concerns

### Docker Compose profiles
| Profile | What runs |
|---------|-----------|
| `default` | All-in-one app + backend + admin + DB + auto-migration |
| `default-no-db` | Same but without the bundled Postgres |
| `backend` | Backend API only |
| `app` | Frontend app + webapp server |
| `admin` | Admin dashboard only |

### Services and ports (default profile)
| Service | Port |
|---------|------|
| Hoppscotch app | 3000 |
| Backend API | 3170 |
| Admin dashboard | 3100 |
| PostgreSQL | internal |

### Data volume
- `postgres-data` — PostgreSQL data

### Config file
- `.env` — copy from `.env.example` in the repo root

---

## Deployment Steps

```bash
mkdir -p ~/docker-apps/hoppscotch && cd ~/docker-apps/hoppscotch

# Download compose file and env example
curl -O https://raw.githubusercontent.com/hoppscotch/hoppscotch/main/docker-compose.yml
curl -o .env https://raw.githubusercontent.com/hoppscotch/hoppscotch/main/.env.example

# Edit .env — minimum required changes:
#   DATABASE_URL, DATA_ENCRYPTION_KEY (32 chars), VITE_BASE_URL,
#   VITE_ADMIN_URL, VITE_BACKEND_GQL_URL, VITE_BACKEND_WS_URL,
#   VITE_BACKEND_API_URL, and at least one auth provider

# Generate a 32-char encryption key:
openssl rand -base64 24 | head -c 32

# Start with the all-in-one profile (includes DB + migrations)
docker compose --profile default up -d

# App:   http://localhost:3000
# API:   http://localhost:3170
# Admin: http://localhost:3100
```

---

## Upgrade Procedure

```bash
cd ~/docker-apps/hoppscotch
docker compose --profile default pull
docker compose --profile default up -d
# DB migrations run automatically on backend startup
```

---

## Gotchas

- **VITE_ vars are build-time** — Frontend URLs (`VITE_*`) are baked into the app bundle at build time. If you change the public URL after deployment you must rebuild/repull the image.
- **Exactly 32-char encryption key** — `DATA_ENCRYPTION_KEY` must be exactly 32 characters. Shorter/longer values cause startup errors.
- **Auth required** — There is no built-in username/password login; you must configure at least one OAuth provider or enable magic-link email auth.
- **Email auth needs SMTP** — Magic-link login requires a working SMTP relay (`MAILER_SMTP_URL`).
- **Admin dashboard is separate** — The admin panel runs on port 3100 and must be configured as a separate virtual host if using a reverse proxy.
- **Don't mix profiles** — `default` and `default-no-db` conflict with individual service profiles on ports. Use one profile set consistently.
- **Self-signed TLS upstream** — Set `TRUST_PROXY=true` when terminating TLS at a reverse proxy like Nginx/Caddy.

---

## Links
- GitHub: https://github.com/hoppscotch/hoppscotch
- Self-host CE docs: https://docs.hoppscotch.io/documentation/self-host/community-edition/install-and-build
- `.env.example`: https://raw.githubusercontent.com/hoppscotch/hoppscotch/main/.env.example
- Docker Hub: https://hub.docker.com/r/hoppscotch/hoppscotch
