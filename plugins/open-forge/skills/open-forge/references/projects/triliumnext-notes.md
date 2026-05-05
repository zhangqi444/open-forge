---
name: triliumnext-notes
description: TriliumNext Notes recipe for open-forge. Covers Docker Compose (recommended server install) and Node.js direct server. Based on upstream docs at https://docs.triliumnotes.org/ and the TriliumNext/Trilium repo.
---

# TriliumNext Notes

Cross-platform hierarchical note-taking application with focus on building large personal knowledge bases. A community-maintained fork of the original Trilium Notes, under active development. Upstream: <https://github.com/TriliumNext/Trilium>. Docs: <https://docs.triliumnotes.org/>.

TriliumNext is a Node.js app listening on port `8080` by default. All notes live in a single SQLite database file. The Docker install is the simplest server deployment — mount one volume for the data directory.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | https://docs.triliumnotes.org/user-guide/setup/server/installation/docker | Yes | Recommended server install. Single container, simple volume mount. |
| Node.js server | https://docs.triliumnotes.org/user-guide/setup/server/installation/manually | Yes | When Docker is unavailable. Requires Node.js 20+. |
| Desktop app | https://github.com/TriliumNext/Trilium/releases/latest | Yes | Local personal use only — not a server. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | Which install method? | Choose from table above | Drives which section loads |
| data | Where should TriliumNext store its data? (host path, e.g. /opt/trilium-data) | Free-text path | Docker + Node installs |
| network | Which host port? (default: 8080) | Integer | Docker install |
| auth | Set up a reverse proxy with HTTPS? | Yes/No | All server installs |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Data directory | /home/node/trilium-data inside container. Mount a host path here. Contains SQLite DB, attachments, and backups. |
| Database | Single SQLite file at <data-dir>/document.db. Back this up regularly. |
| Default port | 8080 |
| Env var | TRILIUM_DATA_DIR overrides the data directory path inside the container. |
| Auto-backups | TriliumNext auto-creates backups in <data-dir>/backup/ on a schedule. |
| Sync server | Supports optional sync between desktop and server instances. |
| OIDC / TOTP | Supported for stronger login auth — configure under Settings -> Authentication. |
| Timezone | Mount /etc/timezone and /etc/localtime read-only for correct timestamps. |

## Method — Docker Compose (recommended)

Source: https://docs.triliumnotes.org/user-guide/setup/server/installation/docker

docker-compose.yml:

    services:
      trilium:
        image: triliumnext/trilium:latest
        restart: unless-stopped
        environment:
          - TRILIUM_DATA_DIR=/home/node/trilium-data
        ports:
          - '8080:8080'
        volumes:
          - ${TRILIUM_DATA_DIR:-~/trilium-data}:/home/node/trilium-data
          - /etc/timezone:/etc/timezone:ro
          - /etc/localtime:/etc/localtime:ro

Start:

    export TRILIUM_DATA_DIR=/opt/trilium-data
    mkdir -p "$TRILIUM_DATA_DIR"
    docker compose up -d

On first launch visit http://<host>:8080 to complete setup wizard (set admin password, optional sync config).

## Method — Node.js server

Source: https://docs.triliumnotes.org/user-guide/setup/server/installation/manually

    # Requires Node.js 20+
    VERSION=$(curl -s https://api.github.com/repos/TriliumNext/Trilium/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
    curl -L "https://github.com/TriliumNext/Trilium/releases/download/${VERSION}/TriliumNextNotes-${VERSION}-server-linux-x64.tar.xz" \
      -o trilium.tar.xz
    tar -xf trilium.tar.xz
    cd TriliumNextNotes-*-server-linux-x64
    ./trilium.sh

Data dir defaults to ~/.local/share/trilium-data. Override with TRILIUM_DATA_DIR env var.

## Upgrade procedure

Docker:

    docker compose pull && docker compose up -d

Node.js:
1. Back up $TRILIUM_DATA_DIR (especially document.db).
2. Download new release tarball.
3. Stop running instance.
4. Extract new tarball, restart. TriliumNext runs DB migrations on startup automatically.

Upstream upgrade docs: https://docs.triliumnotes.org/user-guide/setup/upgrading

## Gotchas

- Single SQLite DB: all notes and attachments are in document.db. If lost without backup, all data is gone. Use built-in auto-backups AND an external backup.
- Pin version in production: use triliumnext/trilium:v0.102.2 (or current) instead of :latest to avoid surprise upgrades.
- First user = owner: the first person to complete setup wizard becomes the owner. Don't leave setup open on a public-facing server.
- Desktop <-> server sync: conflicts from offline edits can create duplicates. Review the sync panel conflict log.
- OIDC/TOTP is opt-in: default login is username/password only. Enable TOTP or OIDC under Settings -> Authentication for stronger auth.
- Fork status: the original zadam/trilium is unmaintained. TriliumNext/Trilium is the active community fork. Do not use the old Docker image for new deployments.

## Links

- Install overview: https://docs.triliumnotes.org/user-guide/setup
- Docker setup: https://docs.triliumnotes.org/user-guide/setup/server/installation/docker
- Upgrading: https://docs.triliumnotes.org/user-guide/setup/upgrading
- Sync: https://docs.triliumnotes.org/user-guide/setup/synchronization
- GitHub: https://github.com/TriliumNext/Trilium
