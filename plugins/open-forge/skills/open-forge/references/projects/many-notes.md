---
name: Many Notes
description: "Self-hosted Markdown note-taking web app with vault-based organisation. Docker. PHP (Laravel) + SQLite. brufdev/many-notes. Multiple vaults per user, OAuth, real-time collaboration, full-text search (Typesense), backlinks, tags, templates, PWA. MIT."
---

# Many Notes

**Self-hosted Markdown note-taking with vault organisation.** Create vaults (collections of notes), write Markdown with an advanced editor, and organise notes with links, backlinks, and tags. Multi-user with OAuth support, real-time collaboration via broadcasting, fast typo-tolerant search powered by Typesense. Files are also stored on the filesystem — full portability. PWA support over HTTPS.

Built + maintained by **brufdev**. MIT license.

- Upstream repo: <https://github.com/brufdev/many-notes>
- Docker Hub: `brufdev/many-notes`

## Architecture in one minute

- **PHP 8.4** (Laravel) backend + server-side rendered frontend
- **SQLite** default database (stored in a volume)
- **Typesense** — fast full-text search with typo tolerance
- **Nginx** (serversideup PHP image)
- Files also written to **filesystem** (in addition to DB) — portable vaults
- Port **80** → container port 8080
- Resource: **low-medium** — PHP + SQLite + Typesense search
- Requires building a custom image to set correct file permissions (PUID/PGID)

## Compatible install methods

| Infra      | Runtime                   | Notes                                              |
| ---------- | ------------------------- | -------------------------------------------------- |
| **Docker** | Custom build from `brufdev/many-notes` | **Primary** — requires Dockerfile for PUID/PGID |

> Many Notes requires a custom build step to embed your host user/group IDs (PUID/PGID). This is a one-time Dockerfile wrapping the upstream image.

## Install via Docker

### 1. Create directory structure

```
many-notes/
├── database/
├── logs/
├── private/
├── typesense/
├── Dockerfile
└── compose.yaml
```

### 2. Dockerfile

```dockerfile
FROM brufdev/many-notes:latest
USER root
ARG UID
ARG GID
RUN docker-php-serversideup-set-id www-data $UID:$GID && \
    docker-php-serversideup-set-file-permissions --owner $UID:$GID --service nginx
USER www-data
```

### 3. compose.yaml

```yaml
services:
  php:
    build:
      context: .
      args:
        UID: 1000   # match your host user ID (run: id -u)
        GID: 1000   # match your host group ID (run: id -g)
    restart: unless-stopped
    environment:
      - APP_URL=http://localhost   # set to your actual public URL
    volumes:
      - ./database:/var/www/html/database/sqlite
      - ./logs:/var/www/html/storage/logs
      - ./private:/var/www/html/storage/app/private
      - ./typesense:/var/www/html/typesense
    ports:
      - "80:8080"
```

```bash
docker compose up -d
```

Visit `http://localhost` → register your account.

## Environment variables

| Variable | Required | Notes |
|----------|----------|-------|
| `APP_URL` | ✅ | Full public URL (protocol + domain/IP) — used for links and OAuth callbacks |
| `APP_KEY` | Auto | Laravel app key — auto-generated on first boot if not set |
| `DB_CONNECTION` | Optional | `sqlite` (default) or `mysql`/`postgres` (set additional DB vars) |
| `MAIL_*` | Optional | SMTP config for email notifications |
| OAuth variables | Optional | Set per provider (Google, GitHub, etc.) — see README |

> Additional settings (locale, debug, cache, queue) can be set via `.env` — see `.env.example` in the repo.

## Features overview

| Feature | Details |
|---------|---------|
| Vaults | Storage containers for notes; one or many per user |
| Multiple users | Authentication; each user manages their own vaults |
| Vault collaboration | Invite other users to access your vaults |
| OAuth authentication | Authenticate via supported OAuth providers |
| Markdown editor | Advanced editor with syntax highlighting, shortcuts |
| Automatic saving | Notes save automatically as you type |
| Links & backlinks | Link notes together; see what links back |
| Tags | Categorise notes with tags |
| Templates | Reusable note templates for consistent formatting |
| Full-text search | Fast, typo-tolerant search powered by Typesense |
| Tree view explorer | File-tree navigation with context menu |
| Real-time collaboration | Live-updating UI via broadcasting |
| Filesystem storage | Notes stored on filesystem too — portable; no lock-in |
| SQLite default | No external database required by default |
| PWA support | Install as a Progressive Web App (requires HTTPS) |
| Light/dark theme | UI theme support |

## Gotchas

- **Custom Docker build required.** Unlike most apps, Many Notes requires wrapping the upstream image in a Dockerfile to set correct PUID/PGID. The official image runs as an unprivileged user — the build step bakes in your host user IDs so file permissions work correctly.
- **Use `id -u` and `id -g` for your IDs.** Run these on your host to get the correct UID/GID values for the `args` in compose.
- **PWA requires HTTPS.** PWA installation and clipboard access from code blocks require serving over HTTPS. Use a reverse proxy (Caddy, Nginx, Traefik) with a TLS certificate.
- **Typesense volume required.** The Typesense search index is stored in `/var/www/html/typesense` — mount this as a volume or search data is lost on container restart.
- **Upgrading.** Check `UPGRADING.md` in the repo before upgrading — some versions require migration steps.
- **MIT license.** Free to use, modify, redistribute.

## Backup

```sh
# SQLite database + notes + typesense index
tar -czf many-notes-$(date +%F).tar.gz ./database ./private ./typesense
```

## Upgrade

```sh
# Pull latest, rebuild with same UID/GID args
docker compose build --pull && docker compose up -d
```

Check `UPGRADING.md` before upgrading for any required migration steps.

## Project health

Active PHP 8.4/Laravel development, MIT license, Typesense search, real-time collaboration.

## Notes-family comparison

- **Many Notes** — PHP/Laravel/SQLite, vaults, OAuth, Typesense search, real-time collaboration, backlinks, MIT
- **Obsidian** — Electron app (not self-hosted server), local vaults, plugin ecosystem
- **Joplin Server** — Node.js, Markdown notes, sync server for Joplin clients; AGPL-3.0
- **Memos** — Go/SQLite, microblog-style quick notes; MIT
- **Outline** — Node.js/Postgres, team wiki/docs with Markdown; BSL

**Choose Many Notes if:** you want a self-hosted Markdown note-taking app with vault organisation, full-text search, backlinks, multi-user OAuth, and real-time collaboration — with files also stored on the filesystem for full portability.

## Links

- Repo: <https://github.com/brufdev/many-notes>
- Docker Hub: <https://hub.docker.com/r/brufdev/many-notes>
- Upgrading guide: <https://github.com/brufdev/many-notes/blob/main/UPGRADING.md>
