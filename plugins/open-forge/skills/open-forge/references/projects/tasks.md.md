---
name: tasks.md
description: Tasks.md recipe for open-forge. Covers Docker install. Tasks.md is a self-hosted, file-based Kanban task management board where each card is a Markdown file stored on disk.
---

# Tasks.md

Self-hosted, file-based Kanban task management board. Each card is a Markdown file stored directly on disk — no database required. Supports lanes, tags, and rich Markdown editing. Themes include Adwaita, Nord, and Catppuccin. Supports reverse-proxy subpath deployments and can be installed as a PWA. Upstream: <https://github.com/BaldissaraMatheus/Tasks.md>.

**License:** MIT · **Language:** JavaScript (Node.js) · **Default port:** 8080 · **Stars:** ~2,100

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://hub.docker.com/r/baldissaramatheus/tasks.md> | ✅ | **Recommended** — single container, no external dependencies. |
| Docker Compose | See below | ✅ | Compose-managed deployment. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| tasks_dir | "Directory on host to store task files? (e.g. /opt/tasks/tasks)" | Free-text | All methods. |
| config_dir | "Directory on host for config/state? (e.g. /opt/tasks/config)" | Free-text | All methods. |
| port | "Port to expose? (default: 8080)" | Free-text | All methods. |
| puid_pgid | "User/Group ID (PUID/PGID) for file ownership? (default: 1000/1000)" | Free-text | Optional. |

## Install — Docker

```bash
docker run -d \
  --name tasks.md \
  -e PUID=1000 \
  -e PGID=1000 \
  -p 8080:8080 \
  -v /opt/tasks/tasks:/tasks \
  -v /opt/tasks/config:/config \
  --restart unless-stopped \
  baldissaramatheus/tasks.md
```

Access the UI at `http://localhost:8080`.

## Install — Docker Compose

```bash
mkdir tasks-md && cd tasks-md
mkdir -p tasks config

cat > docker-compose.yml << 'COMPOSE'
services:
  tasks-md:
    image: baldissaramatheus/tasks.md:latest
    container_name: tasks-md
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      # Optional:
      # - TITLE=My Tasks
      # - BASE_PATH=/tasks   # Only if running under a subpath
    ports:
      - "8080:8080"
    volumes:
      - ./tasks:/tasks
      - ./config:/config
COMPOSE

docker compose up -d
```

## Environment variables

| Variable | Description | Default |
|---|---|---|
| `PUID` | UID that owns task files on disk | (runs as root if unset) |
| `PGID` | GID that owns task files on disk | (runs as root if unset) |
| `TITLE` | Board title shown in the header and browser tab | (none) |
| `BASE_PATH` | Subpath for reverse-proxy deployments (e.g. `/tasks`) | `/` |
| `LOCAL_IMAGES_CLEANUP_INTERVAL` | Minutes between cleanup of orphaned local images | `1440` (24h). Set to `0` to disable. |

## Subpath deployment (reverse proxy)

Set `BASE_PATH` and configure your reverse proxy:

```yaml
environment:
  - BASE_PATH=/tasks
```

> **Note:** PWA installation does **not** work when `BASE_PATH` is set to anything other than `/`.

nginx example:

```nginx
location /tasks/ {
    proxy_pass http://localhost:8080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
}
```

## Data structure

Task files are stored as plain Markdown in the `/tasks` volume:

```
/tasks/
  board.json          ← Board structure (lanes, tags)
  My First Task.md    ← Each card = one .md file
  Another Task.md
/config/
  settings.json       ← Theme and preferences
```

Since everything is plain files, you can edit tasks with any text editor, back up with rsync, and version control with git.

## Software-layer concerns

| Concern | Detail |
|---|---|
| No database | All data is plain Markdown files + JSON config. No PostgreSQL/MySQL/SQLite required. |
| No user auth | Tasks.md has no built-in authentication. Expose it only on a LAN or behind a reverse proxy with auth (e.g., nginx basic auth, Authelia, Cloudflare Access). |
| Single board | Currently a single-board application — all lanes and cards share one board per instance. Run multiple containers for multiple boards. |
| Multi-user | Multiple browser clients can access the same board. There is no conflict resolution — last write wins. Not suitable for high-concurrent collaborative use. |
| PUID/PGID | Set these to your user's UID/GID to avoid root-owned files on the host. Find yours with `id` on Linux (usually 1000). |
| PWA | Installable as a Progressive Web App from a browser when served at the root path (`BASE_PATH=/`). |
| Upgrade notes | v2 → v3 requires a migration step — see the [migration guide](https://github.com/BaldissaraMatheus/Tasks.md/blob/main/migration-guide.md). |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the release notes for migration steps before upgrading major versions: <https://github.com/BaldissaraMatheus/Tasks.md/releases>

## Gotchas

- **No authentication:** Tasks.md ships with zero auth. Anyone who can reach the port can read and edit all tasks. Always put it behind a reverse proxy with auth if accessible outside your LAN.
- **Single board per instance:** If you need separate boards for different projects or teams, run separate containers with different port mappings and data directories.
- **v2 → v3 migration:** If upgrading from version 2.x, you must follow the migration guide or your existing tasks will not load correctly.
- **PWA + subpath:** Installing as a PWA only works at root path. If you set `BASE_PATH`, PWA install will not function correctly.
- **File ownership:** Forgetting to set `PUID`/`PGID` means task files are written as root on the host. Set them to avoid permission headaches.

## Upstream links

- GitHub: <https://github.com/BaldissaraMatheus/Tasks.md>
- Docker Hub: <https://hub.docker.com/r/baldissaramatheus/tasks.md>
- Migration guide (v2 → v3): <https://github.com/BaldissaraMatheus/Tasks.md/blob/main/migration-guide.md>
- Releases: <https://github.com/BaldissaraMatheus/Tasks.md/releases>
