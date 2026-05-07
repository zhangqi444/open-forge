---
name: mymangadb
description: MyMangaDB recipe for open-forge. Manga collection manager with automatic metadata fetching, MyAnimeList import, statistics, and RBAC. Docker + Traefik. Source: https://github.com/FabianRolfMatthiasNoll/MyMangaDB
---

# MyMangaDB

A self-hosted manga collection manager. Automatically fetches metadata (authors, genres, descriptions, cover art) from external APIs. Supports MyAnimeList import, collection statistics, role-based access control (Admin/Guest), and a responsive UI. GPL-3.0 licensed. Upstream: <https://github.com/FabianRolfMatthiasNoll/MyMangaDB>

> ℹ️ **Note**: Depends on third-party APIs (Jikan/MyAnimeList and Manga Passion) for metadata — requires internet access from the server.

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker Compose + Traefik | Upstream-provided compose file; requires two domains (frontend + backend) |
| Any Linux VPS | Docker Compose (without Traefik) | Use a standard reverse proxy instead |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Frontend domain?" | FQDN | e.g. manga.example.com — public UI |
| "Backend domain?" | FQDN | e.g. manga-api.example.com — API endpoint |
| "Email for Let's Encrypt (Traefik)?" | Email | For SSL cert expiry notifications |
| "API token?" | String (sensitive) | Shared between frontend and backend; set to a random string |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Language preference?" | en / de | English and German supported |
| "Admin account details?" | username + password | Created on first run |

## Software-Layer Concerns

- **Split frontend/backend**: Frontend (Vite/React) and backend are separate services. VITE_API_URL and VITE_API_KEY are baked into the frontend at build time.
- **API_TOKEN / VITE_API_KEY must match**: Set both to the same value — the frontend uses it to authenticate against the backend.
- **Third-party API dependencies**: Metadata fetched from Jikan API (global) and Manga Passion (German releases). No internet = no metadata fetching.
- **Database**: SQLite-backed; stored in a Docker volume at `/app/data`.
- **RBAC**: Admin role (full access) and Guest role (read-only). Manage users in the admin UI.
- **MyAnimeList import**: Upload your MAL export XML in the admin panel to migrate existing collection data.
- **Build-time env vars**: VITE_API_URL and VITE_API_KEY are embedded at Docker build time — changing them requires rebuilding the frontend image.

## Deployment

### Docker Compose (with Traefik)

Clone the repo and edit `docker-compose.yml`:

```bash
git clone https://github.com/FabianRolfMatthiasNoll/MyMangaDB.git
cd MyMangaDB
```

Edit `docker-compose.yml`:
- Replace `<FrontendDomain>` with your frontend domain (e.g. manga.example.com)
- Replace `<BackendDomain>` with your backend domain (e.g. manga-api.example.com)
- Replace `<MyEmail>` with your email for Let's Encrypt
- Set `API_TOKEN` (in a `.env` file or directly)

```bash
echo "API_TOKEN=your-random-secret-here" > .env
docker compose up -d
```

### Docker Compose (without Traefik)

Build frontend with env vars, then expose via your own NGINX/Caddy reverse proxy:

```yaml
services:
  frontend:
    build:
      context: ./frontend/
      args:
        VITE_API_URL: https://manga-api.example.com
        VITE_API_KEY: your-api-token
    ports:
      - "3000:80"

  backend:
    build:
      context: ./backend/
    ports:
      - "8080:8080"
    environment:
      API_TOKEN: your-api-token
      FRONTEND_URL: https://manga.example.com
    volumes:
      - database:/app/data

volumes:
  database:
```

## Upgrade Procedure

1. `git pull` in the MyMangaDB directory.
2. Rebuild images: `docker compose build && docker compose up -d`
3. Data volume persists through upgrades.
4. Note: VITE_ env vars require a rebuild to take effect — not just a container restart.

## Gotchas

- **Two domains required**: The upstream Traefik setup uses separate domains for frontend and backend. You can use path-based routing with a custom NGINX config if you want a single domain.
- **VITE_API_KEY is build-time**: Changing the API token requires rebuilding the frontend image.
- **Internet required for metadata**: Jikan API and Manga Passion must be reachable from the server for automatic metadata fetching to work.
- **HEIC/unusual formats**: Manga cover images come from external APIs — no control over format compatibility.
- **No pre-built images**: Must build from source (docker compose build) — no official Docker Hub image.

## Links

- Source: https://github.com/FabianRolfMatthiasNoll/MyMangaDB
- Jikan API (data provider): https://jikan.moe/
- Manga Passion (German data provider): https://manga-passion.de/
- Releases: https://github.com/FabianRolfMatthiasNoll/MyMangaDB/releases
