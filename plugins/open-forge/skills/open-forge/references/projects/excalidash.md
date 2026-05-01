---
name: ExcaliDash
description: "Self-hosted dashboard and organizer for Excalidraw with real-time collaboration. Docker. Node.js + SQLite/PostgreSQL. ZimengXiong/ExcaliDash. Persistent drawing storage, version history, OIDC SSO, scoped sharing, collections. MIT."
---

# ExcaliDash

**Self-hosted Excalidraw dashboard with collaboration and version history.** Organize all your Excalidraw drawings in one place — collections, search, drag-and-drop management. Real-time multi-user collaboration baked in. Version history with preview and restore. Scoped sharing (internal vs external links). OIDC SSO for team deployments.

Built + maintained by **ZimengXiong**. MIT license.

- Upstream repo: <https://github.com/ZimengXiong/ExcaliDash>
- Docker Hub: check repo for image location

## Architecture in one minute

- **Node.js** backend
- **SQLite** (default) or **PostgreSQL** database
- Embeds the full **Excalidraw** editor with collaboration server
- Port **3000** (configurable)
- Resource: **low-medium** — Node.js + SQLite (or PostgreSQL)

## Compatible install methods

| Infra              | Runtime                | Notes                                      |
| ------------------ | ---------------------- | ------------------------------------------ |
| **Docker Compose** | ExcaliDash image       | **Primary** — see repo for compose         |

## Install

```bash
git clone https://github.com/ZimengXiong/ExcaliDash.git
cd ExcaliDash
# Configure .env
cp .env.example .env
docker compose up -d
```

Visit `http://localhost:3000`.

## Inputs to collect

| Input | Phase | Notes |
|-------|-------|-------|
| Database path or `DATABASE_URL` | DB | SQLite path or PostgreSQL URL |
| Auth secret | Auth | Session/JWT secret |
| OIDC credentials (optional) | SSO | For OIDC provider login |

## Features overview

| Feature | Details |
|---------|---------|
| Drawing management | Dashboard with all drawings; rename, delete, organize |
| Collections | Drag-and-drop drawings into labeled collections |
| Real-time collaboration | Multi-user live editing (WebSocket-based) |
| Version history | Auto-snapshots; preview any past version in-editor; restore |
| Scoped sharing | Internal link (requires account) vs external public link |
| Search | Full-text search across drawing names and canvas content |
| OIDC SSO | Sign in with any OIDC provider (Google, Keycloak, Authentik, etc.) |
| Admin dashboard | User management, admin bootstrap on first run |
| Export/Import | Backup in plain `.excalidraw` format (non-proprietary) |
| Update notifier | In-app GitHub Releases check (disable for air-gapped deploys) |

## First boot

1. Configure `.env` (database, auth secret, public URL).
2. `docker compose up -d`.
3. Visit the URL.
4. **Admin bootstrap** — first user becomes admin; set admin credentials.
5. Log in → create your first drawing.
6. (Optional) Configure OIDC for team sign-in.
7. Invite other users (admin panel).
8. Put behind TLS for collaboration (WebSockets over HTTPS).

## Gotchas

- **Air-gapped deployments.** ExcaliDash checks GitHub Releases for updates via an outbound request. Disable this with `UPDATE_CHECKER_ENABLED=false` (or equivalent env var — check the repo) if outbound internet is not permitted.
- **Collaboration requires reachable WebSockets.** For real-time collaboration to work, WebSocket connections (ws:// or wss://) must be reachable. Ensure your reverse proxy (Caddy, Nginx, Traefik) forwards WebSocket upgrades.
- **Export format is plain `.excalidraw`.** Drawings export as standard Excalidraw JSON files — no vendor lock-in. You can open exports directly in Excalidraw.com.
- **Version history auto-snapshots.** Snapshots are created automatically. Older snapshots may be pruned. Configure retention settings if you need long-term history.
- **OIDC is optional.** Local account registration works out of the box. OIDC is additive for team setups with SSO.

## Backup

```sh
# SQLite
cp excalidash.db excalidash-$(date +%F).db
# PostgreSQL
docker compose exec postgres pg_dump -U excalidash > excalidash-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, real-time collaboration, version history, OIDC SSO, MIT license.

## Excalidraw-hosting-family comparison

- **ExcaliDash** — Node.js dashboard + Excalidraw, version history, OIDC, scoped sharing, MIT
- **Excalidraw** (self-hosted) — official Docker image; editor only; no drawing management/SSO/history
- **Excalidraw+** — official plus.excalidraw.com; SaaS; teams; not self-hosted
- **Huly** — Rust/TS open project management; embeds Excalidraw-like whiteboard; much broader scope

**Choose ExcaliDash if:** you want a self-hosted dashboard around Excalidraw with multi-user collaboration, version history, OIDC SSO, collections, and scoped sharing.

## Links

- Repo: <https://github.com/ZimengXiong/ExcaliDash>
- Releases: <https://github.com/ZimengXiong/ExcaliDash/releases>
