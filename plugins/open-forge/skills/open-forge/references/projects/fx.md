---
name: fx
description: fx recipe for open-forge. Minimalist self-hosted microblogging platform. Write posts in Markdown, syntax highlighting, LaTeX math, file/image uploads, RSS (publish + follow), POSSE-friendly. SQLite, tiny memory footprint. Docker. Source: https://github.com/rikhuijzer/fx
---

# fx

Minimalist self-hosted Twitter/Bluesky-like microblogging service. Write posts in Markdown with built-in syntax highlighting and LaTeX math rendering. Publish and edit from desktop or mobile. Upload files and images. RSS feed for syndication (POSSE). Follow RSS feeds from other sites. Automatic backup to plain text files. SQLite — tiny memory footprint (a few MB). Docker. MIT licensed.

Demo: <https://fx-demo.huijzer.xyz> (resets hourly) | Upstream: <https://github.com/rikhuijzer/fx>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Recommended |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | FX_USERNAME | Login username |
| config | FX_PASSWORD | Login password (store in FX_PASSWORD.env file, not compose) |
| config | FX_DOMAIN | Your site's domain, e.g. example.com (used in links and RSS) |
| config | Port | Default: 3000 |

## Software-layer concerns

### Env vars

| Var | Description |
|---|---|
| FX_USERNAME | Admin login username |
| FX_PASSWORD | Admin login password |
| FX_DOMAIN | Site domain (used in links, RSS feed) |

> **Security**: Store `FX_PASSWORD` in a separate `.env` file (`FX_PASSWORD.env`) — not directly in docker-compose.yml — to avoid committing credentials to version control.

### Data

- SQLite database stored in `/data` volume
- Automatic backup to plain text files on a schedule (via GitHub Actions or cron)

## Install — Docker Compose

```yaml
# docker-compose.yml
services:
  fx:
    image: 'rikhuijzer/fx:1'
    container_name: 'fx'
    environment:
      FX_USERNAME: 'youruser'
      FX_DOMAIN: 'example.com'
    env_file:
      - 'FX_PASSWORD.env'
    ports:
      - '3000:3000'
    volumes:
      - './data:/data:rw'
    healthcheck:
      test: ['CMD', '/fx', 'check-health']
    logging:
      driver: 'json-file'
      options:
        max-size: '5m'
        max-file: '10'
    restart: 'unless-stopped'
```

```bash
# Create password env file
echo 'FX_PASSWORD="your-secure-password"' > FX_PASSWORD.env

docker compose up -d
```

Access at http://localhost:3000 (or your domain via reverse proxy).

## Backup

fx supports automatic backup of posts to plain text files. Set up a daily cron job or GitHub Actions workflow using the backup API:

```bash
# Backup script (run as cron job)
curl -u youruser:yourpassword http://localhost:3000/api/backup > backup-$(date +%Y%m%d).tar.gz
```

## Upgrade procedure

```bash
# Pull new image (fx:1 is the latest v1 track)
docker compose pull
docker compose up -d
# SQLite data in ./data is preserved via volume
```

## Gotchas

- **Docker Compose does not restart containers on failed health checks** — the health check detects failures but won't auto-restart. Use [autoheal](https://github.com/willfarrell/docker-autoheal) or a systemd service wrapper to auto-restart on health check failure.
- `FX_PASSWORD.env` should not be committed to version control — keep it gitignored or use Docker secrets.
- Single-user by design — fx is built for personal/individual publishing, not multi-user teams.
- `FX_DOMAIN` affects generated links and the RSS feed — set it to your actual public domain for correct URLs in RSS readers and when sharing links.

## Links

- Source: https://github.com/rikhuijzer/fx
- Demo: https://fx-demo.huijzer.xyz
- DockerHub: https://hub.docker.com/repository/docker/rikhuijzer/fx
- Example sites: https://huijzer.xyz
