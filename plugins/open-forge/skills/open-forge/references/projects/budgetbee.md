# BudgetBee

**What it is:** Open-source, self-hosted personal finance manager. Track income, expenses, and transfers across multiple accounts; set budgets per category; monitor net worth; schedule recurring expenses; view rich charts and reports. Multi-user and multi-currency support.

**Official site:** https://budgetbee.github.io/budgetbee/  
**GitHub:** https://github.com/budgetbee/budgetbee  
**Docker images:** `ghcr.io/budgetbee/budgetbee/{proxy,api,web}:latest`

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Recommended; 4-container stack |
| Bare metal | Docker Compose | Same |

---

## Stack Components

| Container | Image | Role |
|-----------|-------|------|
| `nginx` | `ghcr.io/budgetbee/budgetbee/proxy:latest` | Reverse proxy / entry point |
| `webserver` | `ghcr.io/budgetbee/budgetbee/api:latest` | Laravel PHP API backend |
| `web` | `ghcr.io/budgetbee/budgetbee/web:latest` | React + Vite frontend |
| `db` | `mysql:8.2.0` | MySQL 8 database |

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `APP_PORT` | Host port to expose the app (e.g. `80`) |
| `DB_DATABASE` | MySQL database name (e.g. `budgetbee`) |
| `DB_USERNAME` | MySQL app user |
| `DB_PASSWORD` | Password for the MySQL app user — use a strong value |
| `DB_ROOT_PASSWORD` | MySQL root password — keep secret |

---

## Software-Layer Concerns

- **Four-container stack**: nginx proxy → frontend + API backend → MySQL
- **First-run registration:** If no users exist, the app redirects to a registration page to create the first admin account
- **MySQL 8.2.0** with `mysql_native_password` auth plugin — required for Laravel compatibility
- **Data volume:** `db_data` named volume for MySQL persistence — back up regularly
- **API access:** REST API secured with API keys — available for programmatic access
- **Import/Export:** Excel and JSON import for migrating existing records
- **Multi-currency:** Supported natively — suitable for international users

---

## Example Docker Compose

```yaml
version: '3.8'
services:
  nginx:
    image: ghcr.io/budgetbee/budgetbee/proxy:latest
    ports:
      - "${APP_PORT}:80"
    depends_on: [webserver, web]
    restart: unless-stopped
    networks: [skynet]
  webserver:
    image: ghcr.io/budgetbee/budgetbee/api:latest
    command: sh entrypoint.sh
    environment:
      DB_HOST: db
      DB_DATABASE: ${DB_DATABASE}
      DB_USERNAME: ${DB_USERNAME}
      DB_PASSWORD: ${DB_PASSWORD}
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks: [skynet]
  web:
    image: ghcr.io/budgetbee/budgetbee/web:latest
    restart: unless-stopped
    networks: [skynet]
  db:
    image: mysql:8.2.0
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DB_DATABASE}
      MYSQL_USER: ${DB_USERNAME}
      MYSQL_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/mysql
    networks: [skynet]
    restart: unless-stopped
networks:
  skynet:
volumes:
  db_data:
```

---

## Upgrade Procedure

1. Pull new images: `docker compose pull`
2. Restart: `docker compose up -d`
3. Laravel migrations run automatically via `entrypoint.sh`

---

## Gotchas

- `DB_ROOT_PASSWORD` and `DB_PASSWORD` must be set before first run — MySQL won't re-initialize if the volume already exists
- **All four containers must be on the same Docker network** (`skynet`) — the nginx proxy routes between them
- The `db` container uses a healthcheck before `webserver` starts — allow extra startup time on slow hosts
- No built-in HTTPS — put behind a reverse proxy (Caddy, Nginx, Traefik) for TLS termination
- New account creation is self-serve on first run; lock it down via admin settings after initial setup

---

## Links

- Website: https://budgetbee.github.io/budgetbee/
- GitHub: https://github.com/budgetbee/budgetbee
