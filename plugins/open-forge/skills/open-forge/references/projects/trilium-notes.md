---
name: trilium-notes-project
description: Trilium Notes recipe for open-forge. AGPL-3.0 hierarchical note-taking + personal knowledge base app. The active fork is **TriliumNext** (github.com/TriliumNext/Trilium); the original `zadam/trilium` project was archived in early 2024. Single-container Node.js app with embedded SQLite — no external DB. Covers Docker Compose (upstream-recommended), native install, desktop clients, sync-server topology (server + desktop clients), and the `trilium-data` / uploaded-attachments backup strategy.
---

# Trilium Notes

AGPL-3.0 hierarchical note-taking + knowledge-base app. Upstream (active fork): <https://github.com/TriliumNext/Trilium>. Docs: <https://docs.triliumnotes.org/>.

**⚠️ `zadam/trilium` is sunset.** The original Trilium project was archived by its author in early 2024. TriliumNext is the **community-maintained successor**, same codebase, same data format. If the user says "Trilium," confirm they mean TriliumNext before proceeding. Migration from archived `zadam/trilium` to TriliumNext is drop-in (same SQLite schema).

## What it is

- Single Node.js app backed by embedded SQLite — no Postgres/MySQL/Redis
- Tree-structured notes (clone-able into multiple parents), rich WYSIWYG editor, code notes, relation maps, canvas (Excalidraw), mind maps (Mind Elixir)
- Built-in sync server: run one instance as server, point desktop clients at it
- OIDC + TOTP MFA built in
- Web clipper for browsers
- Desktop apps for macOS / Linux / Windows (Electron) + mobile-friendly web UI

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose (`triliumnext/trilium:latest`) | <https://github.com/TriliumNext/Trilium/blob/main/docker-compose.yml> | ✅ Recommended | Most self-hosted deploys land here. |
| Docker `docker run` | Same image | ✅ | Quick test. |
| Desktop app (Electron) | <https://github.com/TriliumNext/Trilium/releases> | ✅ | Local-only notes OR desktop client syncing to self-hosted server. |
| Source install (`pnpm install && pnpm run electron-rebuild`) | <https://docs.triliumnotes.org/user-guide/setup/server/installation> | ✅ | Contributors / custom builds. |
| Nightly image | `triliumnext/trilium:nightly` | ✅ | Test unreleased features; **not for production**. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `desktop-only` / `source` | Drives section. |
| preflight | "Use as sync server or local-only?" | `AskUserQuestion` | Sync-server = Docker/native install accessed by desktop clients. Local-only = just the desktop app. |
| storage | "Host path for trilium-data?" | Free-text, default `~/trilium-data` | Mounted at `/home/node/trilium-data`. Contains DB + attachments + config. |
| dns | "Public domain for sync-server access?" | Free-text | Sync needs HTTPS (cert validation on client). |
| tls | "Reverse proxy? (Caddy / nginx / Traefik)" | `AskUserQuestion` | Trilium does not terminate TLS itself. |
| auth | "Initial admin password?" | Free-text (sensitive) | Set during first web login. No default credentials shipped — you define them. |
| auth | "Enable OIDC?" | Boolean | Configured via env vars; see docs. |
| version | "Image tag (pin or `latest`)?" | `AskUserQuestion`: `latest` / pin-specific-tag | Pinning recommended — auto-update can break sync compatibility between server and clients. |

## Install — Docker Compose (upstream)

```yaml
# docker-compose.yml — from TriliumNext/Trilium on main
services:
  trilium:
    image: triliumnext/trilium:latest     # pin a version like v0.90.3 for production
    restart: unless-stopped
    environment:
      - TRILIUM_DATA_DIR=/home/node/trilium-data
    ports:
      - '8080:8080'
    volumes:
      - ${TRILIUM_DATA_DIR:-~/trilium-data}:/home/node/trilium-data
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
```

Bring up:

```bash
mkdir -p ~/trilium-data
docker compose up -d
docker compose logs -f trilium
# Access at http://<host>:8080/
```

On first visit, Trilium walks through an initial setup (set password, choose sync mode: server / client, or standalone).

### One-liner `docker run`

```bash
docker run -d \
  --name trilium \
  -p 8080:8080 \
  -v ~/trilium-data:/home/node/trilium-data \
  -v /etc/timezone:/etc/timezone:ro \
  -v /etc/localtime:/etc/localtime:ro \
  --restart unless-stopped \
  triliumnext/trilium:latest
```

## Install — Desktop app

Download from <https://github.com/TriliumNext/Trilium/releases/latest>:

- macOS: `.dmg`
- Linux: `.AppImage`, `.deb`, `.rpm`
- Windows: `.exe` installer

The desktop app can run standalone (local SQLite) OR as a client that syncs to your Docker-hosted server. Configure via **Options → Sync** inside the app.

## Sync-server topology

The common self-host shape is:

1. **Server**: Docker-hosted Trilium at `https://trilium.example.com` (behind a reverse proxy, public HTTPS).
2. **Clients**: Desktop apps on your laptop/phone/etc., each configured to sync with the server.
3. **Browser**: Log in via web UI at the same URL as the clients.

Each client keeps a local SQLite copy and syncs deltas over HTTPS. If the server goes down, clients keep working offline and sync when it returns.

### Client setup

In the desktop app: **Options → Sync → Sync server URL** = `https://trilium.example.com`. Log in with the same password you set on the server. On first sync, the client pulls the full DB.

## Reverse proxy (Caddy)

```caddy
trilium.example.com {
    reverse_proxy trilium:8080
}
```

WebSockets used for live updates need pass-through; Caddy handles this by default. For nginx, ensure `proxy_set_header Upgrade $http_upgrade` and `Connection "upgrade"`.

## Data layout

Everything lives in the `trilium-data` directory:

| File | Content |
|---|---|
| `document.db` | Main SQLite — notes, attributes, relations, user accounts |
| `document.db-shm` / `document.db-wal` | SQLite WAL files (live — DO NOT copy while running for backups) |
| `backup/` | Automatic daily backups of `document.db` |
| `log/` | Server logs |
| `config.ini` | Low-level config |
| `sessions/` | Session store |
| `oauth-config.json` | OIDC config (if used) |

**Backup options:**

1. **Built-in automatic backups** (recommended) — enabled by default. Trilium snapshots `document.db` daily into `trilium-data/backup/`. Retention configurable in Options → Backup.
2. **Stop + tar** — stop the container, tar the whole `trilium-data/` dir, start again.
3. **Online snapshot** — use SQLite's `.backup` command while running:
   ```bash
   docker exec trilium sqlite3 /home/node/trilium-data/document.db ".backup '/home/node/trilium-data/backup/manual-$(date +%s).db'"
   ```

## Configuration

Trilium is configured mostly through the web UI (**Options** panel). Environment variables control a few top-level knobs:

| Var | Purpose |
|---|---|
| `TRILIUM_DATA_DIR` | Data directory path inside container (set to `/home/node/trilium-data`). |
| `TRILIUM_PORT` | Port to bind (default 8080). |
| `TRILIUM_HOST` | Bind address (default 0.0.0.0). |
| `TRILIUM_SYNC_SERVER_HOST` | For multi-tenant setups (rare). |
| `TRILIUM_OPEN_NOTE_CONTEXTS_FILE` | Custom note-contexts config. |

Most day-to-day config (backup retention, sync settings, MFA, OIDC providers, themes, keyboard shortcuts) lives in the **Options** dialog inside the app.

## Upgrade procedure

### Docker Compose

```bash
# 1. Let the built-in backup run first OR do a manual snapshot
# 2. Pull + restart
docker compose pull
docker compose up -d
docker compose logs -f trilium
```

Schema migrations run automatically on startup. **Read release notes at <https://github.com/TriliumNext/Trilium/releases> before upgrading** — TriliumNext is still under active post-fork development and occasional one-way schema migrations happen.

### Sync-server + clients: upgrade ordering

Upgrade the **server first**, then desktop clients. Clients detect server version mismatch and prompt to upgrade. Old clients hitting a newer server may sync in compatibility mode or refuse; newer clients hitting older servers fail sync.

### Desktop app

Built-in update check. In-app prompt on new release.

## Gotchas

- **zadam/trilium is archived.** If a user's docker-compose references `zadam/trilium:latest`, migrate to `triliumnext/trilium:latest` — same data dir format, drop-in replacement. Don't leave them on an unmaintained image.
- **No default credentials shipped.** First visit asks you to set a password. Before that screen, the instance is unlocked — anyone with network access during the first few seconds can claim admin. Firewall the port until you've completed first-run setup, or run first-run on localhost only.
- **SQLite single-writer.** Single user on the server is fine; multi-user write contention is not the target workload. For a team knowledge base, use Trilium as personal notes + BookStack / Outline as the shared KB.
- **Sync uses HTTPS with cert validation.** Plain-HTTP sync is blocked by default on desktop clients. Deploy behind Caddy / Let's Encrypt; self-signed works but requires a toggle in client options.
- **WebSocket upgrades needed.** Reverse proxies that strip `Upgrade` headers break live-sync. Caddy and modern Traefik handle this out of the box; nginx needs explicit `proxy_set_header Upgrade $http_upgrade; Connection "upgrade";`.
- **Attachments and images store inside the DB, not the filesystem.** `document.db` grows with every image you paste. A 5 GB SQLite is normal for heavy users with image-heavy notes. Don't be surprised.
- **Protected notes use client-side encryption** with a separate password — if you forget it, the notes are unrecoverable. Trilium can't reset protected-note passwords.
- **Version lock between server and clients.** Clients one minor version behind usually work; two+ minor versions behind tend to refuse sync. Upgrade clients after the server.
- **Default `TRILIUM_DATA_DIR=/home/node/trilium-data` requires UID 1000 ownership.** If you bind-mount a dir owned by a different host user, the container errors on startup. `sudo chown -R 1000:1000 ~/trilium-data` fixes it.
- **Nightly tag = unstable.** Handy for testing fixes but you will hit bugs. Stick to tagged releases for real data.
- **Sharing ("Publish") notes puts them on your public URL.** Anyone with the share URL can read them. There's no per-share password; use caution with sensitive content.
- **Evernote import is lossy.** Complex notebooks, nested stacks, and some metadata (reminders, custom templates) don't round-trip perfectly. Inspect a few notes after import before nuking the source.

## Links

- Upstream (active fork): <https://github.com/TriliumNext/Trilium>
- Legacy upstream (archived): <https://github.com/zadam/trilium>
- Docs: <https://docs.triliumnotes.org/>
- Installation / Docker: <https://docs.triliumnotes.org/user-guide/setup/server/installation/docker>
- Sync setup: <https://docs.triliumnotes.org/user-guide/setup/synchronization>
- MFA / OIDC: <https://docs.triliumnotes.org/user-guide/setup/server/mfa>
- Upgrading: <https://docs.triliumnotes.org/user-guide/setup/upgrading>
- Releases: <https://github.com/TriliumNext/Trilium/releases>
- Docker image: <https://hub.docker.com/r/triliumnext/trilium>
