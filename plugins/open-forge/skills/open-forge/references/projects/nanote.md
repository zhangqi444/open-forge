# Nanote

**What it is:** A lightweight self-hosted note-taking app with filesystem-based storage. No database — notes are just folders and Markdown files on disk, fully portable and editable with any text editor. Built with Nuxt 4 and TypeScript, with full-text search, file uploads, and a mobile-friendly UI.

**Official URL:** https://github.com/omarmir/nanote
**Docker Hub:** `omarmir/nanote`
**License:** MIT
**Stack:** Nuxt 4 (TypeScript/Vue.js) + flat-file (Markdown) storage; requires `ugrep` for fast search

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Homelab | Docker Compose | Lightweight, no database |

---

## Inputs to Collect

### Pre-deployment
- `SECRET_KEY` — session signing secret; change from default `nanote` before exposing publicly
- `NOTES_PATH` — path inside container where notes (markdown files) are stored
- `UPLOAD_PATH` — path inside container for uploaded files/images
- `CONFIG_PATH` — path inside container for app config
- Host volume mount — single directory covering all three paths (e.g. `/path/to/nanote-data`)

### Runtime
- Notes organized as notebooks (directories) containing `.md` files
- Files accessible directly on the host filesystem alongside the Docker volume

---

## Software-Layer Concerns

**Docker Compose (`compose.yaml`):**
```yaml
version: "3.8"
services:
  nanote:
    image: omarmir/nanote:latest
    ports:
      - "3030:3000"
    environment:
      - NOTES_PATH=/nanote/notes
      - UPLOAD_PATH=/nanote/uploads
      - CONFIG_PATH=/nanote/config
      - SECRET_KEY=change-this-secret
    volumes:
      - /path/to/local/nanote:/nanote
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
```

**Default port:** `3030` (maps to internal `3000`)

**Pre-create directories** before first run (or notes will land in the app's root directory):
```bash
mkdir -p /path/to/local/nanote/{notes,uploads,config}
```

**Markdown directives** (typed inline in notes):
- `::file` / `::fileBlock` — inline file/image picker
- `::today` / `::tomorrow` / `::yesterday` / `::now` / `::time` — date/time insertion

**Search:** Uses `ugrep` for fast full-text search across notes. The Docker image includes ugrep; for manual installs, `ugrep` must be on the PATH.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`
3. Notes and uploads are on the host volume — unaffected by upgrades

---

## Gotchas

- **Pre-create volume subdirs** — if `notes/`, `uploads/`, and `config/` don't exist in the volume, Nanote creates notes in the container root (lost on container removal)
- **Default `SECRET_KEY` is `nanote`** — change it before exposing to a network; all sessions will be invalidated when changed
- **No built-in auth beyond the secret key** — put behind a reverse proxy with authentication for internet-facing deployments
- **Flat-file = full portability** — notes are plain `.md` files; edit them with any editor, sync with Syncthing, version with git
- **Planned features not yet shipped** — archive, checklist rollup, and encryption are on the roadmap but not implemented yet

---

## Links
- GitHub: https://github.com/omarmir/nanote
- Docker Hub: https://hub.docker.com/r/omarmir/nanote
