---
name: geeftlist
description: Geeftlist recipe for open-forge. Collaborative gift list management app — share and reserve gifts among friends and family without spoiling surprises. GPL-3.0, PHP + Docker. Source: https://codeberg.org/nanawel/geeftlist
---

# Geeftlist

A collaborative web application for managing, sharing, and reserving gifts among friends and family — solving the classic Christmas coordination problem without ruining surprises. Users create wish lists; others can view and reserve items without the list owner seeing who reserved what. 8 years in private use before open-sourcing. GPL-3.0 licensed, PHP backend with Docker-only supported deployment. Source: <https://codeberg.org/nanawel/geeftlist>. Docker Hub: <https://hub.docker.com/r/nanawel/geeftlist>

## Compatible Combos

| Infra | Runtime | Database | Notes |
|---|---|---|---|
| Any Linux | Docker Compose | MariaDB + Redis | Only officially supported deployment method |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. gifts.example.com |
| "Database password?" | string | For MariaDB container |
| "App secret key?" | string | Random string for session signing |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "SMTP for email notifications?" | host:port + credentials | Optional — for reservation notifications |
| "Reverse proxy?" | NGINX / Caddy / Traefik | Geeftlist listens on port 8080; put HTTPS in front |

## Software-Layer Concerns

- **Docker-only support**: The official deployment method is Docker Compose — direct PHP installs are not supported by the project.
- **Stack**: PHP webapp + MariaDB (database) + Redis (cache/sessions) — all included in the Compose stack.
- **Port 8080**: The webapp container listens on port 8080 internally; expose via reverse proxy on 443.
- **Prometheus metrics**: Available at `{base_url}/system/healthcheck` for monitoring.
- **Fat Free Framework**: Built on the Fat Free Framework PHP micro-framework.
- **`docker-compose.override.yml`**: Recommended way to customize config without touching the base `docker-compose.yml`.
- **Gift reservations are private**: Reservations are visible to everyone except the list owner — enforced by the app logic.

## Deployment

### Docker Compose

```bash
# Get the production Docker Compose files
git clone https://codeberg.org/nanawel/geeftlist.git
cd geeftlist/support/docker/production/

# Copy and edit env file
cp .env.dist .env
# Edit .env: set DB_PASSWORD, APP_SECRET, etc.

docker compose up -d
# App available at http://localhost:8080
```

### Minimal `.env`

```env
DB_PASSWORD=changeme
APP_SECRET=your-random-secret-string-here
APP_ENV=prod
```

### `docker-compose.override.yml` for customization

```yaml
# Create docker-compose.override.yml alongside docker-compose.yml
services:
  webapp:
    environment:
      - MAILER_DSN=smtp://user:pass@smtp.example.com:587
    ports:
      - "8080:80"
```

### NGINX reverse proxy

```nginx
server {
    listen 443 ssl;
    server_name gifts.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## Upgrade Procedure

1. `git pull` in the geeftlist directory.
2. `docker compose pull && docker compose up -d`.
3. Check release notes at https://codeberg.org/nanawel/geeftlist/releases for migration steps.
4. Database schema migrations run automatically on startup.

## Gotchas

- **Docker-only**: Direct PHP/Apache installs are not supported — use the provided Compose stack.
- **Use `docker-compose.override.yml` for changes**: Keeps your customizations separate from the base config, simplifying future upgrades.
- **Redis required**: Sessions and caching use Redis — don't remove it from the Compose stack.
- **French-origin project**: Some UI elements and documentation may default to French — check locale settings in the app config.
- **Reverse proxy required for HTTPS**: The webapp container has no TLS — put NGINX/Caddy in front for production use.
- **Prometheus endpoint**: `GET /system/healthcheck` returns health metrics — useful for uptime monitoring.

## Links

- Source: https://codeberg.org/nanawel/geeftlist
- Docker Hub: https://hub.docker.com/r/nanawel/geeftlist
- Production Docker docs: https://codeberg.org/nanawel/geeftlist/src/branch/main/support/docker/production
- Releases: https://codeberg.org/nanawel/geeftlist/releases
