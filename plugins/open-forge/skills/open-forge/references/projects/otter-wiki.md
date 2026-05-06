# Otter Wiki (An Otter Wiki)

An Otter Wiki is a simple, lightweight wiki using Markdown for content and Git for version control. Built with Python/Flask, it stores all pages in a Git repository providing full history and change tracking with no external database required.

**Website:** https://otterwiki.com/
**Source:** https://github.com/redimp/otterwiki
**License:** MIT
**Stars:** ~1,411

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | Docker Compose | Recommended |
| Any Linux/VPS | Docker (single container) | Simplest setup |
| Any Linux/VPS | Python (manual) | Flask app |
| Raspberry Pi | Docker | Works on ARM |

---

## Inputs to Collect

### Phase 1 — Planning
- Public URL (e.g. `https://wiki.example.com`)
- Authentication: user accounts, or open/read-only access
- Storage path for wiki content (Git repo)

### Phase 2 — Deployment
- `OTTERWIKI_SETTINGS` or env vars for config
- `SECRET_KEY`: random secret for session security
- `REPOSITORY`: path to git repo inside container
- Email settings (optional, for password reset)

---

## Software-Layer Concerns

### Docker Compose (Recommended)
```yaml
services:
  otterwiki:
    image: redimp/otterwiki:2
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./app-data:/app-data
    environment:
      - SECRET_KEY=change_me_to_a_random_string
```

```bash
docker compose up -d
# Access at http://localhost:8080
# First registered account becomes admin
```

### Single Docker Run
```bash
docker run -d \
  --name otterwiki \
  -p 8080:80 \
  -v $(pwd)/app-data:/app-data \
  -e SECRET_KEY=change_me_random \
  redimp/otterwiki:2
```

### Data Volume
```
app-data/
├── repository/   # Git repo containing all wiki pages (*.md files)
├── config.cfg    # Runtime configuration
└── wiki.db       # SQLite database (users, sessions)
```

All wiki content is stored as Markdown files in a bare Git repository under `app-data/repository/`. This means you can:
```bash
# Clone the wiki content for backup or external editing
git clone app-data/repository/ wiki-backup/
```

### Configuration (config.cfg or env vars)

Key settings available via the admin UI at `/settings` or via environment variables:
```
SECRET_KEY          # Required: random string for session security
REPOSITORY          # Path to git repo (default: /app-data/repository)
SITE_NAME           # Wiki name displayed in header
SITE_LOGO           # URL to custom logo
AUTH_REGISTRATION   # "OPEN" (anyone can register) or "CLOSED"
AUTH_ANONYMOUS_READ # True/False — allow unauthenticated read access
MAIL_SERVER         # SMTP server for password reset emails
MAIL_PORT           # SMTP port
MAIL_USERNAME       # SMTP username
MAIL_PASSWORD       # SMTP password
```

### Reverse Proxy (nginx)
```nginx
server {
    listen 443 ssl;
    server_name wiki.example.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### First-Time Setup
1. Start container
2. Navigate to `http://localhost:8080`
3. Register your first account — it automatically becomes an admin
4. Go to **Admin → Settings** to configure site name, registration policy, etc.

---

## Upgrade Procedure

```bash
# Pull new image
docker compose pull

# Restart
docker compose down && docker compose up -d
```

No database migrations required — content is in Git, schema changes are handled automatically.

---

## Gotchas

- **First user is admin**: The very first account registered gets admin privileges. Register immediately after deployment on public networks.
- **Git-backed storage**: All content is stored in Git. This is great for backups and history but means large binary attachments bloat the repo over time.
- **No built-in reverse proxy**: The container serves on port 80 without TLS; always put a reverse proxy (nginx, Caddy) in front for HTTPS.
- **`SECRET_KEY` is critical**: Use a strong random value. If it changes, all user sessions are invalidated.
- **Experimental Git HTTP server**: The built-in Git HTTP server (for push/pull) is experimental and disabled by default.
- **Attachment storage**: Attachments are stored in the Git repo; large files can slow down page loads and git operations.
- **Search is basic**: Full-text search works but scales poorly for very large wikis.

---

## Links
- Installation Guide: https://otterwiki.com/Installation
- Configuration Guide: https://otterwiki.com/Configuration
- Reverse Proxy Setup: https://otterwiki.com/Installation#reverse-proxy
- Docker Hub: https://hub.docker.com/r/redimp/otterwiki
- Demo: https://demo.otterwiki.com
