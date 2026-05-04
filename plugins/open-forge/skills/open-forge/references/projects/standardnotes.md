---
name: standardnotes
description: Standard Notes recipe for open-forge. End-to-end encrypted note-taking app with self-hosted server support. Clients available for web, desktop, iOS, and Android.
---

# Standard Notes

End-to-end encrypted note-taking application for professionals. Only you can read your notes. Supports unlimited devices, extensions/editors, cross-platform sync, and self-hosted server deployment.

Upstream: <https://github.com/standardnotes/app>. Self-hosting guide: <https://standardnotes.com/help/self-hosting/getting-started>. Server repo: <https://github.com/standardnotes/server>.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose — server | Self-hosted sync server; clients connect to it |
| Static web app (served) | Host the web client separately (optional) |

## Architecture

Standard Notes is split into two parts:
1. **Server** — handles account creation, E2EE encrypted sync, and file storage (`standardnotes/server`)
2. **Clients** — web, desktop (Electron), iOS, Android — all connect to either Standard Notes cloud or your self-hosted server

You self-host the server; clients are downloaded separately by users.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Domain for your Standard Notes server?" | Used in `PUBLIC_URL` / reverse proxy config |
| preflight | "Email for first admin account?" | Created via server API after first run |
| preflight | "SMTP credentials for account verification emails?" | Required for account creation flow |

## Docker Compose example

```yaml
version: "3.9"
services:
  db:
    image: mysql:8
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: changeme
      MYSQL_DATABASE: standardnotes
      MYSQL_USER: sn
      MYSQL_PASSWORD: changeme
    volumes:
      - db-data:/var/lib/mysql

  cache:
    image: redis:7-alpine
    restart: unless-stopped

  server:
    image: standardnotes/server:latest
    restart: unless-stopped
    depends_on:
      - db
      - cache
    ports:
      - "3000:3000"
      - "3125:3125"
    environment:
      DB_HOST: db
      DB_PORT: 3306
      DB_DATABASE: standardnotes
      DB_USERNAME: sn
      DB_PASSWORD: changeme
      REDIS_URL: redis://cache
      PUBLIC_URL: https://sn.example.com
      AUTH_JWT_SECRET: change-this-secret
      VALET_TOKEN_SECRET: change-this-secret
      # SMTP for account emails:
      MAIL_SMTP_HOST: smtp.example.com
      MAIL_SMTP_PORT: 587
      MAIL_SMTP_USERNAME: user@example.com
      MAIL_SMTP_PASSWORD: changeme
      MAIL_FROM_ADDRESS: noreply@example.com

volumes:
  db-data:
```

## Software-layer concerns

- Server exposes port `3000` (API) and `3125` (files service)
- `AUTH_JWT_SECRET` and `VALET_TOKEN_SECRET` must be strong random strings; rotate requires all users to re-login
- Database: MySQL 8 (MariaDB not officially supported)
- Redis required for session management and background jobs
- File attachments stored in server container (or configure S3-compatible storage via env vars)
- Clients point to your server by entering your `PUBLIC_URL` during account creation

## Upgrade procedure

1. `docker compose pull server`
2. `docker compose up -d` — server runs DB migrations automatically on startup
3. Test login before removing old image

## Gotchas

- **Changing `AUTH_JWT_SECRET`** invalidates all active sessions — all users must re-login
- SMTP is required for the account registration flow (verification email); without it, account creation fails
- Self-hosting does not include premium features (Advanced editors, Super editor, etc.) unless you also run the subscription service or use a subscription workaround
- The web app client can be self-hosted separately (`yarn build:web`) but most users just use the desktop/mobile clients pointed at your server URL
- File attachments require the files service (port `3125`) to be reachable from clients

## Links

- App (clients) GitHub: <https://github.com/standardnotes/app>
- Server GitHub: <https://github.com/standardnotes/server>
- Self-hosting guide: <https://standardnotes.com/help/self-hosting/getting-started>
- Docker Hub: <https://hub.docker.com/r/standardnotes/server>
