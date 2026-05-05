# Buku

Privacy-aware, command-line bookmark manager with an optional web UI (Bukuserver). Buku stores bookmarks in a portable SQLite database, auto-fetches titles and descriptions, supports regex search, browser import, and tag management. No tracking, no analytics, no external dependencies by default.

**Official site:** https://github.com/jarun/buku

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux / macOS host | pip / pipx (CLI) | Primary use case |
| Any Linux host | Docker Compose (Bukuserver) | `bukuserver/bukuserver` image for web UI |
| Raspberry Pi / ARM | pip or Docker | Lightweight; runs well on Pi |
| NAS / headless server | Docker Compose | Bukuserver exposes HTTP API for browser extensions |

---

## Inputs to Collect

### Phase 1 — Planning
- Primary interface: CLI only or web UI (Bukuserver)
- Database location (default `~/.local/share/buku/bookmarks.db`)
- Whether to use browser extension (bukubrow) for sync
- HTTPS/auth setup if exposing Bukuserver over the network

### Phase 2 — Deployment
- Port for Bukuserver (default `5001`)
- `BUKUSERVER_SECRET_KEY` for session security
- Volume path for the bookmarks database

---

## Software-Layer Concerns

### Docker Compose (Bukuserver Web UI)

```yaml
services:
  bukuserver:
    image: bukuserver/bukuserver
    restart: unless-stopped
    environment:
      - BUKUSERVER_PER_PAGE=100
      - BUKUSERVER_OPEN_IN_NEW_TAB=true
      - BUKUSERVER_SECRET_KEY=change-me-to-random-string
    ports:
      - "5001:5001"
    volumes:
      - ./data:/root/.local/share/buku

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./data/nginx:/etc/nginx/conf.d
      - ./data/basic_auth:/basic_auth
```

> **Note:** The database is stored in `./data/bookmarks.db` (bind-mounted into the container). The Nginx service is optional but recommended for adding HTTP basic auth before exposing Bukuserver.

### Environment Variables (Bukuserver)
| Variable | Default | Purpose |
|----------|---------|---------|
| `BUKUSERVER_PER_PAGE` | `10` | Results per page in web UI |
| `BUKUSERVER_OPEN_IN_NEW_TAB` | `false` | Open bookmark links in new tab |
| `BUKUSERVER_SECRET_KEY` | (random) | Flask session secret key |
| `BUKUSERVER_URL_RENDER_MODE` | `full` | URL display mode |
| `BUKUSERVER_DISABLE_FAVICON` | `false` | Disable favicon fetching |

### pip / pipx Install

```bash
# CLI only
pip3 install buku

# Web UI (Bukuserver)
pip3 install "buku[server]"

# Or via pipx
pipx install "buku[server]"

# Start Bukuserver
bukuserver run --host 0.0.0.0 --port 5001
```

### Basic CLI Usage

```bash
# Add a bookmark
buku -a https://example.com "Example Site" tag1,tag2

# Search bookmarks
buku -s keyword
buku --sreg "regex-pattern"     # regex search

# Import from browser
buku --import bookmarks.html    # Firefox/Chrome HTML export

# Open bookmark #5 in browser
buku -o 5

# List all
buku -p

# Export to HTML
buku --export bookmarks.html
```

### Database Path
Default: `~/.local/share/buku/bookmarks.db` — portable SQLite file, easy to sync or back up.

---

## Upgrade Procedure

**pip:** `pip3 install --upgrade buku`

**pipx:** `pipx upgrade buku`

**Docker:** `docker compose pull && docker compose up -d`

---

## Gotchas

- **Bukuserver has no built-in auth** — always put it behind Nginx with HTTP basic auth or restrict to localhost; do not expose port 5001 directly to the internet.
- **CLI and Bukuserver share the same DB file** — they can run simultaneously as long as you mount the same database path.
- **Browser import is one-way** — buku imports from a browser HTML export; use the [bukubrow](https://github.com/nicholasgasior/bukubrow) browser extension for live sync.
- **Encryption:** Use `buku -l` to lock (encrypt) the database with a password; run `buku -k` to unlock. Encrypted DB cannot be used by Bukuserver.
- **Clipboard support** requires `xsel`/`xclip` (Linux X11), `pbcopy` (macOS), or `wl-copy` (Wayland).
- **No multi-user support** in Bukuserver — it's designed for single-user personal use.

---

## References
- GitHub: https://github.com/jarun/buku
- Bukuserver README: https://github.com/jarun/buku/tree/master/bukuserver
- Docker Hub: https://hub.docker.com/r/bukuserver/bukuserver
- Docs: https://buku.readthedocs.io/
- Browser extension (bukubrow): https://github.com/nicholasgasior/bukubrow
