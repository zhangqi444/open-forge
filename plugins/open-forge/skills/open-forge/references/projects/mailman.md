---
name: mailman
description: Mailman recipe for open-forge. GNU Mailman 3 — manage electronic mail discussion and e-newsletter lists. GPL-3.0 licensed. Source: https://gitlab.com/mailman/
---

# Mailman (GNU Mailman 3)

The classic open-source mailing list manager, now in version 3. Mailman 3 is a three-component suite: Mailman Core (the list engine), Postorius (web UI for list management), and HyperKitty (web archive). The recommended Docker deployment wraps all three. GPL-3.0 licensed. Source: <https://gitlab.com/mailman/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Docker Compose | Recommended — 3-container stack |
| Any Linux | pip / virtualenv | Manual install for advanced setups |
| Any Linux | System packages | Ubuntu has `mailman3` package |

> Docker Compose is the officially supported path for new deployments.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Mail domain?" | Domain | e.g. lists.example.com |
| "Admin email?" | Email | Superuser account |
| "HYPERKITTY_API_KEY?" | Random string | Shared secret between Core and HyperKitty |
| "Database password?" | String | For Postgres |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "MTA?" | Postfix / Exim4 / other | Must be configured to deliver to Mailman's LMTP port 8024 |
| "TLS?" | Yes / No | Via reverse proxy (NGINX/Caddy) |

## Software-Layer Concerns

- **Three-component suite**: Mailman Core (port 8001 API, port 8024 LMTP), Mailman Web/Postorius (port 8000 HTTP), Postgres.
- **HYPERKITTY_API_KEY**: Must match between Core and Web containers — change from default `someapikey`.
- **MTA integration**: Your MTA must be configured to pipe incoming list mail to Mailman's LMTP (port 8024). Postfix uses `transport_maps` + `relay_domains` pointing to `mailman-core:8024`.
- **Data volumes**: `/opt/mailman/core` (Core data), `/opt/mailman/web` (Web static/media), `/opt/mailman/database` (Postgres data).
- **Explicit version tags**: Image tag `latest` is no longer published — always pin `0.4.x` or `0.4`.
- **Email aliases**: Mailman generates `/opt/mailman/core/var/data/postfix_lmtp` — Postfix must include this with `hash:`.
- **SECRET_KEY**: Django secret key for Mailman Web — must be set and kept stable.
- **SERVE_FROM_DOMAIN**: Set to your web UI domain in mailman-web container for correct email links.

## Deployment

### 1. Prepare directories

```bash
mkdir -p /opt/mailman/{core,web,database}
```

### 2. docker-compose.yaml

```yaml
version: '2'

services:
  mailman-core:
    image: maxking/mailman-core:0.4
    container_name: mailman-core
    hostname: mailman-core
    restart: unless-stopped
    volumes:
      - /opt/mailman/core:/opt/mailman/
    stop_grace_period: 30s
    depends_on:
      database:
        condition: service_healthy
    environment:
      - DATABASE_URL=postgresql://mailman:CHANGE_ME@database/mailmandb
      - DATABASE_TYPE=postgres
      - DATABASE_CLASS=mailman.database.postgresql.PostgreSQLDatabase
      - HYPERKITTY_API_KEY=CHANGE_THIS_API_KEY
    ports:
      - "127.0.0.1:8001:8001"  # REST API
      - "127.0.0.1:8024:8024"  # LMTP (incoming mail)
    networks:
      mailman:

  mailman-web:
    image: maxking/mailman-web:0.4
    container_name: mailman-web
    hostname: mailman-web
    restart: unless-stopped
    depends_on:
      database:
        condition: service_healthy
    volumes:
      - /opt/mailman/web:/opt/mailman-web-data
    environment:
      - DATABASE_TYPE=postgres
      - DATABASE_URL=postgresql://mailman:CHANGE_ME@database/mailmandb
      - HYPERKITTY_API_KEY=CHANGE_THIS_API_KEY
      - SECRET_KEY=CHANGE_THIS_DJANGO_SECRET
      - SERVE_FROM_DOMAIN=lists.example.com
      - DJANGO_ALLOWED_HOSTS=lists.example.com
      - MAILMAN_ADMIN_USER=admin
      - MAILMAN_ADMIN_EMAIL=admin@example.com
    ports:
      - "127.0.0.1:8000:8000"  # Gunicorn HTTP
    networks:
      mailman:

  database:
    image: postgres:12-alpine
    environment:
      - POSTGRES_DB=mailmandb
      - POSTGRES_USER=mailman
      - POSTGRES_PASSWORD=CHANGE_ME
    volumes:
      - /opt/mailman/database:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready --dbname mailmandb --username mailman"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      mailman:

networks:
  mailman:
    driver: bridge
```

### 3. Start

```bash
docker compose up -d
# Wait ~60s for first-run DB setup
docker compose logs -f mailman-core
```

### 4. Configure Postfix integration

```bash
# /etc/postfix/main.cf additions
transport_maps = hash:/opt/mailman/core/var/data/postfix_lmtp
local_recipient_maps = proxy:unix:passwd.byname $alias_maps hash:/opt/mailman/core/var/data/postfix_lmtp
relay_domains = $mydestination hash:/opt/mailman/core/var/data/postfix_domains

# Run after Mailman generates the maps:
postmap /opt/mailman/core/var/data/postfix_lmtp
postmap /opt/mailman/core/var/data/postfix_domains
systemctl reload postfix
```

### 5. Reverse proxy (NGINX)

```nginx
server {
    listen 443 ssl;
    server_name lists.example.com;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /static/ {
        alias /opt/mailman/web/static/;
    }
}
```

## Upgrade Procedure

1. `docker compose pull` — pull new images
2. `docker compose up -d` — recreate containers
3. Check `docker compose logs mailman-web` for DB migration output

## Gotchas

- **Tag `latest` not published**: Always use explicit version tags like `0.4` or `0.4.5`.
- **HYPERKITTY_API_KEY must match**: If Core and Web have different keys, HyperKitty archiving silently fails.
- **Postfix map regeneration**: Mailman regenerates `postfix_lmtp` on list creation — run `postmap` + `postfix reload` or use a cron job.
- **SECRET_KEY stability**: Changing Django's SECRET_KEY invalidates all user sessions and password reset tokens.
- **MTA required**: Mailman is not an MTA — it needs Postfix/Exim to receive and relay mail.
- **LMTP not SMTP**: Incoming list mail goes to port 8024 (LMTP), not a standard SMTP port.
- **Initial admin password**: Set via `MAILMAN_ADMIN_USER` + `MAILMAN_ADMIN_EMAIL` env vars on first run; password reset via email.

## Links

- Website: https://www.list.org/
- Source: https://gitlab.com/mailman/
- Docker deployment: https://github.com/maxking/docker-mailman
- Postorius (web UI): https://gitlab.com/mailman/postorius
- HyperKitty (archive): https://gitlab.com/mailman/hyperkitty
