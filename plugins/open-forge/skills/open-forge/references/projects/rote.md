---
name: Rote
description: Minimalist self-hosted note-taking app with an open API, iOS client, and separated frontend/backend architecture. Low-friction capture, Markdown article support, and full data ownership. PostgreSQL-backed, Docker Compose deploy. MIT-licensed.
---

# Rote

Rote is a self-hosted micro-note platform designed to minimize the mental burden of capturing thoughts. Compared to heavier tools like Notion or Obsidian, it prioritizes simplicity and frictionless interaction over feature breadth.

What makes Rote distinctive:

- **Restrained UI** — deliberately minimal; quick capture without friction
- **Open API** — every action is available via a REST API + API Keys, so you can post notes from any context (CLI, shortcuts, bots)
- **Separated frontend/backend** — deploy only what you need; backend is the API, frontend is a PWA
- **Markdown Articles** — standalone articles alongside short notes; good for longer writing
- **iOS client** — native app that connects to your self-hosted backend
- **Full data export** — no vendor lock-in; export everything
- **MCP server** — AI integration via the community rote-toolkit package

- Upstream repo: <https://github.com/Rabithua/Rote>
- Docker Hub: `rabithua/rote-backend`, `rabithua/rote-frontend`
- Latest release: v1.7.1
- Demo: <https://demo.rote.ink/>

## Architecture in one minute

- **rote-backend** — Bun/Node.js API server on port `3000` (mapped to `18000` in compose)
- **rote-frontend** — Nginx-served React PWA on port `80` (mapped to `18001` in compose)
- **PostgreSQL 17** — database; auto-migrations run at startup
- `VITE_API_BASE` must be set to the public URL of the backend (used at build/serve time by the frontend)

## Compatible install methods

| Infra     | Runtime         | Notes                                           |
| --------- | --------------- | ----------------------------------------------- |
| Single VM | Docker Compose  | **Recommended** — official multi-arch images    |
| Any       | Dokploy         | One-click template available in the platform    |

## Inputs to collect

| Input             | Example                          | Phase       | Notes                                            |
| ----------------- | -------------------------------- | ----------- | ------------------------------------------------ |
| Backend public URL | `http://192.168.1.10:18000`     | Config      | Used by frontend to reach the API                |
| Postgres password | `changeme_strong_password`       | Security    | Stored in `POSTGRES_PASSWORD`                    |
| Backend port      | `18000`                          | Network     | Host port for the API                            |
| Frontend port     | `18001`                          | Network     | Host port for the web UI                         |
| Image tag         | `latest` / `v1.7.1`             | Optional    | Pin to a release for reproducibility             |

## Install via Docker Compose

```yaml
# docker-compose.yml
services:
  rote-backend:
    image: rabithua/rote-backend:latest
    container_name: rote-backend
    environment:
      - POSTGRESQL_URL=postgresql://rote:${POSTGRES_PASSWORD:-rote_password_123}@rote-postgres:5432/rote
    ports:
      - "18000:3000"
    depends_on:
      rote-postgres:
        condition: service_healthy
    restart: unless-stopped
    command:
      - sh
      - -c
      - sleep 15 && bun run dist/scripts/runMigrations.js && bun run dist/server.js

  rote-frontend:
    image: rabithua/rote-frontend:latest
    container_name: rote-frontend
    ports:
      - "18001:80"
    depends_on:
      - rote-backend
    environment:
      - VITE_API_BASE=${VITE_API_BASE:-http://localhost:18000}
    restart: unless-stopped

  rote-postgres:
    image: postgres:17
    container_name: rote-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: rote
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-rote_password_123}
      POSTGRES_DB: rote
    volumes:
      - rote-postgres-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U rote -d rote"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 30s

volumes:
  rote-postgres-data:

networks:
  default:
    name: rote-network
    driver: bridge
```

Create a `.env` file alongside `docker-compose.yml`:

```bash
POSTGRES_PASSWORD=your_strong_password
VITE_API_BASE=http://YOUR_SERVER_IP:18000
```

```bash
docker compose up -d
# Frontend: http://localhost:18001
# API: http://localhost:18000
```

## Post-install steps

1. Open `http://<host>:18001` and register your account
2. Go to **Settings → API Keys** to generate a key for CLI or integration use
3. To connect the iOS app: tap the logo on the login screen multiple times to reveal the backend URL field, then enter your `VITE_API_BASE` URL

## Notes

- `VITE_API_BASE` must be the URL your **browser** can reach the backend at — not the internal Docker hostname
- If you use a reverse proxy, set `VITE_API_BASE` to the proxied backend URL
- The backend runs database migrations automatically on startup (`sleep 15` ensures Postgres is ready first)
- Data lives entirely in the `rote-postgres-data` volume — back it up with `pg_dump`
