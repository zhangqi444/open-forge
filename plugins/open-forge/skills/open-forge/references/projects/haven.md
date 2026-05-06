---
name: haven
description: Haven recipe for open-forge. Private blog application built with Ruby on Rails. Write for friends and family with markdown, built-in RSS reader, image/video/audio support, and private RSS feeds. Docker-deployable. Source: https://github.com/havenweb/haven
---

# Haven

Private blogging system built with Ruby on Rails. Write what you want for a specific audience — create accounts for the people you want to share with, post with markdown and live preview, share images/videos/audio, and follow each other via built-in RSS. No self-signup (you invite people), no ads, no trackers. Designed for friends and family, not public publishing. Docker image: `ghcr.io/havenweb/haven`. Upstream: https://github.com/havenweb/haven. Live demo: https://havenweb.org/demo.html.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose (prebuilt image) | Linux | Recommended; uses ghcr.io/havenweb/haven |
| Docker Compose (build from source) | Linux | Builds image locally from Dockerfile |
| PikaPods | Managed hosting | Easiest managed option |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| admin | "Admin email?" | HAVEN_USER_EMAIL — initial admin account |
| admin | "Admin password?" | HAVEN_USER_PASS — change immediately after first login |
| db | "Database password?" | HAVEN_DB_PASSWORD — for PostgreSQL container |
| port | "Host port?" | Default: 3000 |

## Software-layer concerns

### docker-compose.yml (production — prebuilt image)

  version: '3.7'
  services:
    haven:
      image: ghcr.io/havenweb/haven:latest
      restart: unless-stopped
      depends_on:
        - postgresql
      ports:
        - "3000:3000"
      volumes:
        - haven_storage:/app/storage
      tmpfs:
        - /tmp/pids/
      environment:
        - PIDFILE=/tmp/pids/server.pid
        - RAILS_ENV=production
        - HAVEN_DB_HOST=postgresql
        - HAVEN_DB_NAME=haven
        - HAVEN_DB_ROLE=haven
        - HAVEN_DB_PASSWORD=supersecretrandomstring   # change this
        - HAVEN_USER_EMAIL=changeme@havenweb.org       # change this
        - HAVEN_USER_PASS=ChangeMeN0W                  # change this

    postgresql:
      image: postgres:13.2-alpine
      restart: unless-stopped
      environment:
        - POSTGRES_DB=haven
        - POSTGRES_USER=haven
        - POSTGRES_PASSWORD=supersecretrandomstring    # match above
      volumes:
        - haven_db:/var/lib/postgresql/data

  volumes:
    haven_storage:
    haven_db:

### First run

  docker compose up -d
  # Haven listens on port 3000
  # Log in with HAVEN_USER_EMAIL / HAVEN_USER_PASS
  # Change the password immediately via Account Settings

### Environment variables

  HAVEN_USER_EMAIL   Initial admin email
  HAVEN_USER_PASS    Initial admin password (min 12 chars recommended)
  HAVEN_DB_HOST      PostgreSQL host (service name in compose)
  HAVEN_DB_NAME      Database name (default: haven)
  HAVEN_DB_ROLE      Database user (default: haven)
  HAVEN_DB_PASSWORD  Database password
  RAILS_ENV          Must be "production"

### Storage

  haven_storage volume  — uploaded images, videos, audio files
  haven_db volume       — PostgreSQL data

  # Images are auto-downscaled on upload to reduce page load times.

### Ports

  3000/tcp   # Web UI (configurable via host port mapping)

### Reverse proxy (nginx)

  server {
      listen 443 ssl;
      server_name haven.example.com;

      location / {
          proxy_pass http://127.0.0.1:3000;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          client_max_body_size 50M;   # for media uploads
      }
  }

## Upgrade procedure

  docker compose pull
  docker compose up -d
  # Rails migrations run automatically on startup.

## Gotchas

- **No self-signup**: Haven has no public registration page by design. You create accounts for your guests manually via the admin UI. This is a feature, not a bug.
- **Change credentials before exposing publicly**: The default `HAVEN_USER_EMAIL`/`HAVEN_USER_PASS` in the compose file are placeholders. Update them before first run.
- **DB password must match**: `HAVEN_DB_PASSWORD` in the `haven` service and in the `postgresql` service must be identical.
- **client_max_body_size**: If you upload large videos, nginx will reject the request unless `client_max_body_size` is raised.
- **HTTPS recommended**: Haven doesn't enforce HTTPS internally; put it behind a reverse proxy with TLS (Caddy, nginx + Let's Encrypt).
- **RSS feeds are private**: Each user gets a secret RSS feed URL. Share it only with people you trust.
- **Built-in RSS reader**: Haven includes a reader for following other Haven blogs (or any RSS feed) — no need for a separate reader app.

## References

- Upstream GitHub: https://github.com/havenweb/haven
- Website: https://havenweb.org
- Docker image: https://github.com/havenweb/haven/pkgs/container/haven
- Live demo: https://havenweb.org/demo.html
- PikaPods managed hosting: https://www.pikapods.com/pods?run=haven
