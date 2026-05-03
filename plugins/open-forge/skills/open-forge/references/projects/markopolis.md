# Markopolis

> Self-hosted Obsidian Publish alternative — point it at a folder of Markdown files and it serves them as a website with full-text search, a REST API for programmatic access, and support for Obsidian-flavored syntax (callouts, equations, code highlighting).

**URL:** https://markopolis.app
**Source:** https://github.com/rishikanthc/markopolis
**License:** MIT

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker Compose | Official image: `ghcr.io/rishikanthc/markopolis:latest`; includes built-in PocketBase DB |
| Any   | Python (pip) | CLI only — upload tool; requires server already running |

## Inputs to Collect

### Provision phase
- Domain / public URL (for the frontend)
- Admin email and password for PocketBase

### Deploy phase
- `API_KEY` — secret key protecting the REST API endpoints (required; generate a strong random value)
- `POCKETBASE_ADMIN_EMAIL` — admin email for the embedded PocketBase database UI
- `POCKETBASE_ADMIN_PASSWORD` — admin password for PocketBase
- `TITLE` — site title displayed in the UI
- Optional: `CAP1` / `CAP2` / `CAP3` — subtitle/caption lines below the site title
- `POCKETBASE_URL` — **do not change**; must be `http://127.0.0.1:8080`

## Software-layer Concerns

### Docker Compose
```yaml
services:
  markopolis:
    image: ghcr.io/rishikanthc/markopolis:latest
    restart: unless-stopped
    ports:
      - "8080:8080"   # PocketBase admin UI
      - "3000:3000"   # Web frontend
    environment:
      - POCKETBASE_URL=http://127.0.0.1:8080   # DO NOT CHANGE
      - API_KEY=your-strong-api-key-here
      - POCKETBASE_ADMIN_EMAIL=admin@example.com
      - POCKETBASE_ADMIN_PASSWORD=changeme
      - TITLE=My Notes
      - CAP1=Published from Obsidian
      - CAP2=
      - CAP3=
    volumes:
      - ./pb_data:/app/db
```

### CLI (upload tool — runs on your local machine)
```bash
pip install markopolis

# Set once (add to shell profile):
export MARKOPOLIS_DOMAIN=https://markopolis.example.com
export MARKOPOLIS_API=your-strong-api-key-here

# Publish notes from a directory:
markopolis publish /path/to/vault
```

### Config / env vars
| Variable | Required | Description |
|----------|----------|-------------|
| `POCKETBASE_URL` | Yes | **Must be** `http://127.0.0.1:8080` — internal DB URL |
| `API_KEY` | Yes | Secret key for REST API authentication |
| `POCKETBASE_ADMIN_EMAIL` | Yes | PocketBase admin login email |
| `POCKETBASE_ADMIN_PASSWORD` | Yes | PocketBase admin login password |
| `TITLE` | No | Site title (default `Markopolis`) |
| `CAP1` / `CAP2` / `CAP3` | No | Caption lines below site title |

### Data dirs
- `./pb_data` → `/app/db` — PocketBase database and uploaded notes

### Ports
- `8080` — PocketBase admin UI (restrict access in production)
- `3000` — Markopolis web frontend

## Upgrade Procedure
```bash
docker compose pull
docker compose up -d
```
Back up `./pb_data` before upgrading. Versions follow semantic versioning; a v2.0.0 reset the image versioning — check the [changelog](https://markopolis.app/changelog) for breaking changes.

## Gotchas
- **`POCKETBASE_URL` must not be changed** — the backend and frontend communicate over localhost inside the container; changing this URL breaks the app.
- **API key is required** — most REST endpoints are protected; the CLI upload tool needs `MARKOPOLIS_API` set to the same value.
- **PocketBase port exposed** — port `8080` exposes the PocketBase admin panel; restrict this behind a firewall or reverse proxy in production.
- **Notes are uploaded via CLI** — there is no file-picker in the web UI; use `pip install markopolis` and `markopolis publish` to push files from your vault.
- **Obsidian syntax only** — designed for Obsidian-flavored Markdown; standard Markdown works but features like wikilinks and callouts are Obsidian-specific.
- **v2.0.0 separated backend and frontend** into distinct services (both inside the same image); the docker versioning was fast-forwarded to match the Python package version.
- The live docs site at `https://markopolis.app` is itself hosted with Markopolis and serves as a live demo.

## Links
- [README](https://github.com/rishikanthc/markopolis/blob/main/README.md)
- [Documentation / live demo](https://markopolis.app)
- [Changelog](https://markopolis.app/changelog)
- [GitHub Container Registry image](https://github.com/rishikanthc/markopolis/pkgs/container/markopolis)
