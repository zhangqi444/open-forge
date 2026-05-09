---
name: operational
description: Recipe for Operational — open-source event tracking tool for tech products. Monitor signups, webhooks, cron jobs, push notifications. Docker Compose + MySQL. Based on upstream readme.md at https://github.com/operational-co/operational.co (master branch) and docker/docker-compose.yml.
---

# Operational

Open-source event tracking tool for tech products. Track important events (signups, webhooks, cron job runs, errors) and receive push notifications on your device or in the web app. Supports event contexts (events-within-events), action buttons that trigger webhooks, JSON payloads, mobile PWA (with push notifications), and a simple SDK for integration. MIT license (open-source version; Clickhouse analytics is optional). Official site: <https://operational.co/>. Upstream: <https://github.com/operational-co/operational.co>.

Tech stack: Node.js ≥18, MySQL 8.x, Prisma, Express.js 5.x, Vue 3.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host / VM / VPS | Docker Compose | Recommended — app + MySQL in one stack |
| Any host | Node.js + external MySQL | Build from source; monorepo structure |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "MySQL root password?" | Set `MYSQL_ROOT_PASSWORD` (and matching `DATABASE_URL`) |
| db | "MySQL app user password?" | Set `MYSQL_PASSWORD` and `DATABASE_URL` |
| app | "Public URL for the app?" | Set `APP_URL` — used for OAuth callbacks, VAPID push notifications |
| app | "Admin email address?" | Set `ADMIN_EMAIL` — used to create the initial admin account |
| app | "Secret key for session signing?" | Set `SECRET` — generate with `openssl rand -hex 32` |
| push (optional) | "Enable web push notifications?" | Requires VAPID keys — generate with `npx web-push generate-vapid-keys` |
| email (optional) | "Outbound email provider?" | Resend (set `RESEND` API key) or SMTP (`SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`) |

## Software-layer concerns

- **Image**: `ghcr.io/operational-co/operational.co:0.1.7` (GitHub Container Registry). Check releases for the latest tag.
- **Database**: MySQL 8.x. Schema managed via Prisma migrations — run automatically on container start.
- **Ports**:
  - `3000` → frontend (nginx serving the Vue SPA)
  - `4337` → backend API
- **Data directory**: MySQL data volume (`mysql-data`). No other persistent state in the app container.
- **Push notifications**: require VAPID keys (`VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, `VAPID_EMAIL`). Generate with `npx web-push generate-vapid-keys` or the `web-push` npm package.
- **CORS**: `CORS=*` allows all origins (default in compose). Restrict to your frontend domain in production.
- **Clickhouse** (optional, not required for the open-source version): adds analytics; not included in the Docker Compose stack.

## Docker Compose

Based on `docker/docker-compose.yml` in the upstream repo:

```yaml
services:
  mysql:
    image: mysql:8.2
    container_name: operational-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: change_me_root_password
      MYSQL_DATABASE: operational
      MYSQL_USER: operational_user
      MYSQL_PASSWORD: change_me_user_password
    ports:
      - "3307:3306"
    volumes:
      - mysql-data:/var/lib/mysql

  operational:
    image: ghcr.io/operational-co/operational.co:0.1.7
    container_name: operational-app
    depends_on:
      - mysql
    restart: always
    ports:
      - "3000:80"   # Frontend (Vue SPA via nginx)
      - "4337:4337" # Backend API
    environment:
      DATABASE_URL: mysql://operational_user:change_me_user_password@mysql:3306/operational
      APP_URL: http://localhost:3000
      ADMIN_EMAIL: admin@example.com
      SECRET: change_me_secret_key
      # Push notifications (optional — generate with: npx web-push generate-vapid-keys)
      VAPID_EMAIL: ""
      VAPID_PUBLIC_KEY: ""
      VAPID_PRIVATE_KEY: ""
      # Email (optional — use Resend or SMTP)
      RESEND: ""
      SMTP_HOST: ""
      SMTP_PORT: ""
      SMTP_USERNAME: ""
      SMTP_PASSWORD: ""
      # Other
      CORS: "*"
      REMOVE_TEST_EVENTS_AFTER: ""
      PORT: ""

volumes:
  mysql-data:
```

Start:

```bash
docker compose up -d
# Frontend: http://localhost:3000
# API: http://localhost:4337
```

Login with `ADMIN_EMAIL`. On first start, Prisma migrations run automatically to create the schema.

## Integrating with your app

Use the official SDK (npm package `@operational-co/sdk`) or the REST API:

```bash
npm install @operational-co/sdk
```

```js
import Operational from '@operational-co/sdk';
const op = new Operational({ token: 'your-api-token', baseUrl: 'http://your-operational-instance:4337' });

// Track an event
await op.log('User signed up', { email: 'user@example.com' });
```

API tokens are created in the Operational web UI under Settings.

## Upgrade procedure

1. Check the [releases page](https://github.com/operational-co/operational.co/releases) for the latest image tag.
2. Update the image tag in `docker-compose.yml`.
3. Pull and recreate:

```bash
docker compose pull
docker compose up -d
```

Prisma migrations run automatically on startup. Back up the MySQL volume before upgrading across major versions.

## Gotchas

- **MySQL password must match `DATABASE_URL`.** The `MYSQL_PASSWORD` in the `mysql` service and the password in `DATABASE_URL` for the `operational` service must be identical — they are not linked automatically.
- **No TLS built-in.** Deploy behind a reverse proxy (Caddy, Traefik, nginx) for TLS. Set `APP_URL` to the HTTPS URL once TLS is configured.
- **VAPID keys are required for push notifications.** Without them, the push notification feature is disabled. Generate: `npx web-push generate-vapid-keys`.
- **`CORS: "*"` in production.** Change to your frontend domain once deployed: `CORS: "https://operational.yourdomain.com"`.
- **Port 3307 for MySQL.** The compose file maps MySQL to `3307` on the host (not `3306`) to avoid conflicts with any existing local MySQL. Adjust if needed.
- **Prisma migrations.** Run automatically on container start. If the container exits immediately, check logs for migration errors — usually a MySQL connection issue (MySQL may not be ready yet; add a `healthcheck` + `depends_on` condition if needed).
- **Image tag pinning.** The compose file ships with a specific version (`0.1.7`). Pin to a specific tag in production rather than using `:latest` to avoid unexpected schema migrations.

## References

- Upstream README: https://github.com/operational-co/operational.co
- Docker Compose: https://github.com/operational-co/operational.co/blob/master/docker/docker-compose.yml
- Self-hosting docs: https://operational.co/selfhosted/introduction
- SDK (npm): https://www.npmjs.com/package/@operational-co/sdk
