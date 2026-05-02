# Poznote

**What it is:** Self-hosted personal note-taking and documentation platform. SQLite-backed, single-container deployment. Features Markdown editing, public sharing, git synchronization, MCP server, Chrome extension, PWA support, multi-user, and offline viewing.

**Official site:** https://poznote.com  
**Demo:** https://demo.poznote.com (login: `poznote` / `poznote`)  
**GitHub:** https://github.com/timothepoznanski/poznote  
**Docker image:** `ghcr.io/timothepoznanski/poznote:6`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; single-container |
| Raspberry Pi / ARM64 NAS | Docker Compose | Multi-arch image (amd64 + arm64) |
| Windows (Docker Desktop) | Docker Compose | Supported via Docker Desktop |
| macOS (Docker Desktop) | Docker Compose | Supported |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `HTTP_WEB_PORT` | Host port to expose Poznote (e.g. `8080`) |
| `.env` file | Copy from `.env.template` in the repo |

All configuration is done via the `.env` file (fetched from GitHub on deploy).

---

## Software-Layer Concerns

- **SQLite database** at `/var/www/html/data/database/poznote.db` — mount `./data` volume to persist
- **Image tag `:6`** tracks the 6.x.x release line automatically — update by pulling new image
- **MCP server** sidecar (`ghcr.io/timothepoznanski/poznote-mcp:6`) — optional; enables AI/tool integrations via Model Context Protocol
- **Data directory:** `./data` mounted to `/var/www/html/data` — contains database, uploads, and user files
- **Healthcheck** built into the compose file — checks `/api/health` endpoint

### Features summary

| Feature | Notes |
|---------|-------|
| Markdown editor | Full Markdown support |
| Git synchronization | Sync notes to a git repo |
| Public sharing | Share notes via public URL |
| Multi-user | Each user has isolated notes |
| PWA | Installable on desktop and mobile |
| Offline view | Read notes without connectivity |
| MCP server | AI assistant integration |
| Chrome extension | Browser integration |
| Backup / Export | Built-in backup and export tools |
| API | REST API documented in repo |

---

## Example Docker Compose

```yaml
services:
  webserver:
    image: ghcr.io/timothepoznanski/poznote:6
    restart: always
    env_file: .env
    environment:
      SQLITE_DATABASE: /var/www/html/data/database/poznote.db
    ports:
      - "${HTTP_WEB_PORT}:80"
    volumes:
      - "./data:/var/www/html/data"
    healthcheck:
      test: ["CMD", "wget", "--quiet", "--tries=1", "--timeout=5", "-O", "/dev/null", "http://127.0.0.1/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s

  mcp-server:
    image: ghcr.io/timothepoznanski/poznote-mcp:6
    container_name: poznote-mcp
    # see docker-compose.yml in repo for full mcp config
```

---

## Upgrade Procedure

```bash
# Pull latest compose and env template
curl -o docker-compose.yml https://raw.githubusercontent.com/timothepoznanski/poznote/main/docker-compose.yml
curl -o .env.template https://raw.githubusercontent.com/timothepoznanski/poznote/main/.env.template
# Compare .env with new template and add any new variables
sdiff .env .env.template
# Pull new images and restart
docker compose pull && docker compose up -d
```

> ⚠️ Always compare `.env` with `.env.template` when upgrading — new versions may add required variables.

---

## Gotchas

- **Must update both `docker-compose.yml` and `.env.template`** when upgrading — the `:6` tag pulls new patch releases but new env vars require manual `.env` updates
- **`./data` directory must be writable** by the container user — check permissions if the container fails to start
- No built-in HTTPS — use a reverse proxy (Caddy, Nginx, Traefik) for TLS
- MCP server is optional but required for AI assistant features

---

## Links

- Website: https://poznote.com
- Demo: https://demo.poznote.com
- GitHub: https://github.com/timothepoznanski/poznote
- Docker image: https://github.com/timothepoznanski/poznote/pkgs/container/poznote
