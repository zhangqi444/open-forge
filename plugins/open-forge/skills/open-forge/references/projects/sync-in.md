---
name: Sync-in
description: "Self-hosted file storage, sync, and collaboration platform. Docker or npm. Node.js + TypeScript. Sync-in/server. WebDAV, OIDC/LDAP/MFA, full-text search, Collabora/OnlyOffice editing, desktop+CLI client. AGPL."
---

# Sync-in

**Self-hosted file storage, synchronization, and collaboration platform.** Secure file sharing with fine-grained access control, collaborative document editing (Collabora Online + OnlyOffice), full-text search, WebDAV access, OIDC/LDAP/MFA authentication, and a desktop + CLI client. An open-standards alternative to Nextcloud and Seafile.

Built + maintained by **Sync-in team**. AGPL-3.0 license.

- Upstream repo: <https://github.com/Sync-in/server>
- Website + docs: <https://sync-in.com/docs>
- Docker Hub: <https://hub.docker.com/r/syncin/server>
- Desktop + CLI: <https://github.com/Sync-in/desktop>
- Discord: <https://discord.gg/qhJyzwaymT>
- Demo: <https://sync-in.com/docs/demo>

## Architecture in one minute

- **Node.js / TypeScript** backend + web frontend
- **PostgreSQL** database
- Port: configurable (check docs for defaults)
- Docker deploy: see <https://sync-in.com/docs/setup-guide/docker>
- Desktop + CLI client for Windows/macOS/Linux via `Sync-in/desktop`
- Resource: **medium** — Node.js + PostgreSQL + optional office editors

## Compatible install methods

| Infra      | Runtime              | Notes                                                              |
| ---------- | -------------------- | ------------------------------------------------------------------ |
| **Docker** | `syncin/server`      | **Primary** — Docker Hub; see Docker setup guide                   |
| **npm**    | `@sync-in/server`    | npm package; `npx @sync-in/server` or global install               |

Full Docker install guide: <https://sync-in.com/docs/setup-guide/docker>

Full npm install guide: <https://sync-in.com/docs/setup-guide/npm>

## Features overview

| Feature | Details |
|---------|---------|
| File storage | Upload, browse, download, manage files and folders |
| Sync | Desktop + CLI client for continuous file synchronization |
| Spaces + Shares | Fine-grained access control with role-based permissions |
| Collaborative editing | Collabora Online + OnlyOffice integration; multi-editor support |
| Full-text search | Deep document content indexing; multi-format support |
| WebDAV | Native WebDAV support for remote file access |
| OIDC SSO | Federated authentication and Single Sign-On |
| LDAP | Enterprise directory integration |
| MFA | Multi-factor authentication with recovery codes + app passwords |
| File activity | Comments, notifications, activity tracking per file |
| Document management | Storage quotas, file locking, versioning |
| File locking | Prevent concurrent edits with controlled locking |
| Multi-server | Desktop client supports connecting to multiple servers |

## Authentication

Sync-in supports three authentication backends:
- **Local** (built-in users with MFA/TOTP)
- **LDAP** — enterprise directory integration
- **OIDC** — Federated SSO with any OIDC provider (Authentik, Keycloak, etc.)

All three can coexist (unified auth across Web, Desktop, and CLI).

## Collaborative editing

Sync-in integrates with:
- **Collabora Online** — LibreOffice in the browser; open standards (ODF)
- **OnlyOffice** — MS Office-compatible editing (DOCX, XLSX, PPTX)

Both require a separate Collabora/OnlyOffice server. Sync-in auto-selects the editor based on file type when both are configured.

## Desktop + CLI client

The `Sync-in/desktop` package provides:
- Full-featured desktop app (Electron-based) for Windows/macOS/Linux
- CLI for scripting and automation
- Multi-server support
- Cross-device file synchronization

## Gotchas

- **Refer to official docs for current compose.** The install guide is at <https://sync-in.com/docs/setup-guide/docker>; the repo's docker folder may have the most current compose file. Check the docs — setup details evolve as the project matures.
- **Collaborative editing needs separate server.** Collabora Online and OnlyOffice require their own Docker containers (or hosted services). Sync-in provides the integration glue but not the editor server itself.
- **AGPL-3.0 license.** Modifications deployed as a network service must be open-sourced.
- **Early-stage project.** Sync-in is relatively new. Expect active development, potential breaking changes between versions, and evolving documentation. Check the changelog and Discord before upgrading.
- **WebDAV for legacy clients.** Native WebDAV means compatibility with macOS Finder, Windows Explorer, and any WebDAV-compatible tool — without needing the desktop app.

## Backup

```sh
docker compose stop
docker compose exec postgres pg_dump -U postgres syncin > syncin-$(date +%F).sql
sudo tar czf syncin-files-$(date +%F).tgz ./data/   # adjust path per your config
docker compose start
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js/TypeScript development, Docker Hub, npm package, desktop + CLI client, Collabora + OnlyOffice, OIDC + LDAP + MFA, WebDAV, Discord. AGPL-3.0.

## Self-hosted-cloud-family comparison

- **Sync-in** — Node.js, files + collab editing, OIDC+LDAP+MFA, WebDAV, desktop+CLI sync, AGPL
- **Nextcloud** — PHP, massive ecosystem, everything + kitchen sink; most mature
- **ownCloud** — PHP, files focus, lighter than Nextcloud
- **Seafile** — C, very fast sync, no built-in collab editing
- **bewCloud** — Deno, files + CalDAV/CardDAV, simpler scope; no collab editing

**Choose Sync-in if:** you want a self-hosted cloud storage + collaboration platform with Collabora/OnlyOffice editing, OIDC/LDAP, MFA, and a desktop sync client — without the complexity of Nextcloud.

## Links

- Repo: <https://github.com/Sync-in/server>
- Docs: <https://sync-in.com/docs>
- Docker guide: <https://sync-in.com/docs/setup-guide/docker>
- Desktop + CLI: <https://github.com/Sync-in/desktop>
- Discord: <https://discord.gg/qhJyzwaymT>
