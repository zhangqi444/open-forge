# Artalk

Self-hosted commenting system built with Go on the backend and vanilla JavaScript on the frontend (~40 KB). Designed to be embedded into any blog, website, or web app. Supports Markdown, email notifications, spam moderation, social login, multi-site management, and page view tracking.

**Official site:** https://artalk.js.org

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended; SQLite by default (zero external deps) |
| Any Linux host | Binary | Single Go binary, no runtime dependencies |
| Any platform | Docker (standalone) | `artalk/artalk-go` image |

---

## Inputs to Collect

### Phase 1 — Planning
- Default site name and URL (used in comment notifications and admin panel)
- Database backend: SQLite (default) or MySQL/PostgreSQL
- Email/SMTP config (for comment reply notifications)
- Locale (`en`, `zh-CN`, `zh-TW`, `ja`, `fr`, `ko`, `ru`)

### Phase 2 — Deployment
- Data directory (bind-mount to `/data` — stores SQLite DB, uploads, config)
- Exposed port (internal `23366`, map to any external port)
- `ATK_SITE_DEFAULT` — name of your first site
- `ATK_SITE_URL` — public URL of your site

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  artalk:
    image: artalk/artalk-go
    container_name: artalk
    restart: unless-stopped
    ports:
      - 8080:23366
    volumes:
      - ./data:/data
    environment:
      - TZ=UTC
      - ATK_LOCALE=en
      - ATK_SITE_DEFAULT=My Blog
      - ATK_SITE_URL=https://example.com
```

### Key Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ATK_LOCALE` | `zh-CN` | UI language |
| `ATK_SITE_DEFAULT` | — | Name of the default site (created on first launch) |
| `ATK_SITE_URL` | — | Public URL of your site |
| `TZ` | `Asia/Shanghai` | Container timezone |

### Config File (`/data/artalk.yml`)

For advanced config (database, email, captcha, trusted proxy, etc.), edit `/data/artalk.yml`. Full reference:

```yaml
host: "0.0.0.0"
port: 23366
app_key: ""          # JWT signing key — generate a random string
locale: en
timezone: UTC
site_default: My Blog
site_url: https://example.com

db:
  type: sqlite        # sqlite | mysql | pgsql | mssql
  file: ./data/artalk.db

http:
  proxy_header: X-Forwarded-For  # set if behind reverse proxy
```

### Embedding in Your Site

Add to your page HTML:
```html
<div id="Comments"></div>
<script src="https://your-artalk-host/dist/Artalk.js"></script>
<link rel="stylesheet" href="https://your-artalk-host/dist/Artalk.css">
<script>
Artalk.init({
  el: '#Comments',
  server: 'https://your-artalk-host',
  site: 'My Blog',
  pageKey: location.pathname,
  pageTitle: document.title,
})
</script>
```

### Data Directory
| Path | Contents |
|------|---------|
| `/data/artalk.db` | SQLite database (comments, users, settings) |
| `/data/artalk.yml` | Application config |
| `/data/public/` | Uploaded images and static assets |

---

## Upgrade Procedure

```bash
docker compose pull artalk
docker compose up -d artalk
```

Config and data in `/data` persist across upgrades. Check the [changelog](https://github.com/ArtalkJS/Artalk/blob/master/CHANGELOG.md) for breaking changes.

---

## Gotchas

- **Default timezone is `Asia/Shanghai`** — set `TZ=UTC` or your local timezone to avoid timestamp confusion in notifications.
- **`app_key` must be set** for JWT authentication; without it a random key is generated each startup (invalidating all sessions on restart).
- **Admin account** — created via the web UI on first visit; no default credentials.
- **Reverse proxy** — set `proxy_header: X-Forwarded-For` in config when behind Nginx/Traefik to get real client IPs for spam filtering.
- **Multi-site** — one Artalk instance can serve multiple sites; each site is isolated with its own comment threads and admin settings.
- **Email notifications** — configure SMTP in `artalk.yml` under the `email` section; without it, reply notifications are not sent.
- Static assets (the embeddable JS/CSS) are served by the Artalk server itself from the `/dist/` path.

---

## References
- GitHub: https://github.com/ArtalkJS/Artalk
- Documentation: https://artalk.js.org/en/guide/deploy.html
- Docker Hub: https://hub.docker.com/r/artalk/artalk-go
- Config reference: https://artalk.js.org/en/guide/backend/config.html
