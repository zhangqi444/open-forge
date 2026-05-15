---
name: waline
description: Recipe for self-hosting Waline, a simple and safe comment system with backend support — an alternative to Disqus, designed for static sites and blogs. Based on upstream documentation at https://waline.js.org/en/guide/deploy/vps.html.
---

# Waline

Simple, safe, self-hosted comment system with a backend. Embeds in any static site or blog via a JavaScript client. Supports Markdown, email/Telegram/WeChat notifications, Akismet spam filtering, user login, comment management, and multiple database backends (SQLite, MySQL, PostgreSQL, MongoDB). Upstream: <https://github.com/walinejs/waline>. Stars: 3k+. License: GPL-2.0.

## Compatible combos

| Infra | Runtime | Storage | Notes |
|---|---|---|---|
| Any Linux host | Docker Compose | SQLite (local file) | Simplest self-host; all-in-one |
| Any Linux host | Docker Compose | MySQL / PostgreSQL / MongoDB | External DB; production recommended |
| Any Linux host | Node.js direct | Any supported DB | Lightweight alternative to Docker |
| Vercel / Railway / Netlify | Managed | LeanCloud / TiDB / Supabase | Cloud deploy — not covered here |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| required | JWT_TOKEN | Secure random string for session signing |
| required | SITE_URL | The URL of the site embedding Waline (e.g. https://example.com) |
| required | SITE_NAME | Display name of the site |
| optional | AUTHOR_EMAIL | Admin email; comments from this address are auto-approved |
| optional | SECURE_DOMAINS | Comma-separated domains allowed to embed Waline |
| optional | Database credentials | If using MySQL/PostgreSQL instead of SQLite |
| optional | SMTP credentials | For email notifications |
| optional | AKISMET_KEY | Spam filtering (set to `false` to disable) |

## Docker Compose deployment (SQLite)

```yaml
services:
  waline:
    image: lizheming/waline:1.39.3
    container_name: waline
    restart: always
    ports:
      - "127.0.0.1:8360:8360"
    volumes:
      - ./data:/app/data
    environment:
      TZ: America/New_York
      SQLITE_PATH: /app/data
      JWT_TOKEN: your-secure-random-token
      SITE_NAME: My Blog
      SITE_URL: https://example.com
      SECURE_DOMAINS: example.com
      AUTHOR_EMAIL: admin@example.com
```

```bash
mkdir -p data
docker compose up -d
```

Waline admin UI: http://localhost:8360/ui/register (first user becomes admin).

## Docker Compose deployment (MySQL/PostgreSQL)

For MySQL, replace the SQLite environment variables with:

```yaml
environment:
  JWT_TOKEN: your-secure-random-token
  SITE_NAME: My Blog
  SITE_URL: https://example.com
  MYSQL_HOST: db
  MYSQL_PORT: 3306
  MYSQL_DB: waline
  MYSQL_USER: waline
  MYSQL_PASSWORD: your-db-password
```

For PostgreSQL, use `PG_HOST`, `PG_PORT`, `PG_DB`, `PG_USER`, `PG_PASSWORD` instead.

## Embedding in a static site

Add to your HTML (replace the serverURL with your Waline instance):

```html
<div id="waline"></div>
<script type="module">
  import { init } from 'https://unpkg.com/@waline/client@latest/dist/waline.mjs';
  init({
    el: '#waline',
    serverURL: 'https://waline.yourdomain.com',
  });
</script>
```

## Nginx reverse proxy

```nginx
server {
    listen 80;
    server_name waline.yourdomain.com;
    location / {
        proxy_pass http://127.0.0.1:8360;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

## Data directory

SQLite database and uploads are stored in `./data` (mapped to `/app/data` in the container). Back up this directory.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Database migrations run automatically on startup.

## Gotchas

- **First registered user becomes admin.** Register at `/ui/register` immediately after deployment to claim the admin account.
- `SECURE_DOMAINS` restricts which sites can use your Waline instance — set it to your blog domain to prevent abuse.
- By default Waline listens on `127.0.0.1:8360` (loopback only) — use a reverse proxy for external access.
- Akismet spam filtering is enabled by default. Set `AKISMET_KEY=false` to disable, or provide a real Akismet API key.
- SQLite is stored in the Docker volume — do not run `docker compose down -v` or you'll lose all comments.
- The `TZ` environment variable must match your server timezone for correct comment timestamps.

## Upstream docs

- VPS / Docker deploy guide: https://waline.js.org/en/guide/deploy/vps.html
- Database configuration: https://waline.js.org/en/guide/database.html
- Environment variables reference: https://waline.js.org/en/reference/server/env.html
- Client embed guide: https://waline.js.org/en/guide/get-started/
