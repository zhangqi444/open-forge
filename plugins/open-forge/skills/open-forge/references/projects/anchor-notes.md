---
name: Anchor
description: "Offline-first self-hosted note-taking app. Node.js + SQLite/PostgreSQL. ZhFahim/anchor. Rich text editor, offline sync, note sharing, tags, attachments, OIDC SSO, admin panel, mobile + web. AGPL-3.0."
---

# Anchor

**Offline-first, self-hosted note-taking application.** Notes are stored locally and work fully offline, then sync across devices when online. Rich text editing, tags, attachments (images and audio), note sharing, OIDC SSO, and an admin panel for managing users.

Built + maintained by **ZhFahim**. AGPL-3.0.

- Upstream repo: <https://github.com/ZhFahim/anchor>
- Docker image: `ghcr.io/zhfahim/anchor`
- Discord: <https://discord.gg/KbyUEvTTQ>

## Architecture in one minute

- **Node.js** backend + web + mobile frontend
- **SQLite** (embedded, default) or external **PostgreSQL** — set `PG_HOST` to switch
- Port **3000** (internal and default external)
- Data volume: `/data` — SQLite DB, uploads, app data
- Resource: **low** — Node.js + SQLite; very lightweight

## Compatible install methods

| Infra | Runtime | Notes |
|-------|---------|-------|
| **Docker** | `ghcr.io/zhfahim/anchor` + SQLite | **Simplest** — single container, no external DB |
| Docker | `ghcr.io/zhfahim/anchor` + PostgreSQL | For larger or multi-user deployments |

## Install via Docker Compose (SQLite, recommended for most users)

```yaml
services:
  anchor:
    image: ghcr.io/zhfahim/anchor:latest
    container_name: anchor
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - anchor_data:/data

volumes:
  anchor_data:
```

```bash
docker compose up -d
```

Visit `http://localhost:3000` and create your admin account.

## With external PostgreSQL

```yaml
services:
  db:
    image: postgres:16
    restart: unless-stopped
    volumes:
      - pg_data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: anchor
      POSTGRES_USER: anchor
      POSTGRES_PASSWORD: changeme

  anchor:
    image: ghcr.io/zhfahim/anchor:latest
    container_name: anchor
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "3000:3000"
    volumes:
      - anchor_data:/data
    environment:
      PG_HOST: db
      PG_PORT: "5432"
      PG_USER: anchor
      PG_PASSWORD: changeme
      PG_DATABASE: anchor

volumes:
  pg_data:
  anchor_data:
```

## Environment variables

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `APP_URL` | No | `http://localhost:3000` | Base URL where Anchor is served |
| `JWT_SECRET` | No | auto-generated | Auth token secret — set a stable value to keep sessions across restarts |
| `PG_HOST` | No | (empty) | External Postgres host; leave empty for embedded SQLite |
| `PG_PORT` | No | `5432` | Postgres port |
| `PG_USER` | No | `anchor` | Postgres username |
| `PG_PASSWORD` | No | `password` | Postgres password |
| `PG_DATABASE` | No | `anchor` | Database name |
| `USER_SIGNUP` | No | admin-controlled | `disabled`, `enabled`, or `review` |
| `OIDC_ENABLED` | No | — | Enable OIDC SSO |
| `OIDC_PROVIDER_NAME` | No | `"OIDC Provider"` | Login button display name |
| `OIDC_ISSUER_URL` | If OIDC | — | Base URL of your OIDC provider |
| `OIDC_CLIENT_ID` | If OIDC | — | OIDC client ID |
| `OIDC_CLIENT_SECRET` | No | — | OIDC client secret (omit for public/PKCE clients) |
| `DISABLE_INTERNAL_AUTH` | No | `false` | Hide local login when OIDC is enabled (OIDC-only mode) |

## Features

- **Rich text editor** — bold, italic, underline, headings, lists, checkboxes
- **Offline first** — all edits work offline with local database; sync when online
- **Note sharing** — share notes with other users as viewer or editor
- **Tags** — organize notes with custom tags and colors
- **Attachments** — attach images and audio to notes
- **Note backgrounds** — customize with solid colors and patterns
- **Pin + archive** — pin important notes; archive for later
- **Search** — search by title or content (local)
- **Trash** — soft-delete with recovery period
- **Auto sync** — sync across devices when online
- **Admin panel** — user management, registration control, system statistics
- **OIDC auth** — Pocket ID, Authelia, Keycloak, and other providers

## Gotchas

- **`JWT_SECRET` stability.** Auto-generated on startup means all users are logged out on container restart. Set a stable value.
- **`APP_URL` must match.** Set to the URL you actually use to access Anchor; incorrect values break API calls, links, and OIDC callbacks.
- **SQLite default.** Perfectly fine for single-user or small teams. Switch to PostgreSQL only if you need more concurrent write throughput.
- **AGPL-3.0.** If you deploy modified Anchor as a network service, you must publish your modifications under AGPL-3.0.
- **Mobile app.** Anchor has a companion mobile app (React Native / Expo) — see the repo for build/install instructions; it is not yet on app stores.

## Backup

```sh
# Named volume — find mount point
docker volume inspect anchor_data
# Or if using bind mount:
tar czf anchor-backup-$(date +%F).tar.gz ./data
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Note-taking-family comparison

- **Anchor** — Node.js/SQLite, offline-first, rich text, sync, OIDC; AGPL-3.0
- **Memos** — Go/SQLite, micro-blog style notes, tags, Markdown; MIT
- **Joplin** — Electron/React Native, Markdown, sync via Nextcloud/WebDAV; AGPL-3.0
- **AppFlowy** — Rust/Flutter, Notion-like blocks, docs + databases; AGPL-3.0
- **Notesnook** — TypeScript, E2E encrypted, cross-platform; GPL-3.0

**Choose Anchor if:** you want a clean offline-first note-taking app with rich text editing, note sharing between users, and OIDC SSO — simpler than Notion alternatives but more capable than plain Markdown editors.

## Links

- Repo: <https://github.com/ZhFahim/anchor>
- Discord: <https://discord.gg/KbyUEvTTQ>
