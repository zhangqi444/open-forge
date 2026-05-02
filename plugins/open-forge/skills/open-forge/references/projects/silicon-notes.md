---
name: silicon-notes
description: Recipe for Silicon Notes — lightweight personal knowledge base with Markdown editing, bi-directional page relationships, full-text search, and page history. Python/Flask, Docker Compose, SQLite-backed.
---

# Silicon Notes

A lightweight, low-friction personal knowledge base. Upstream: https://github.com/cu/silicon

Python/Flask app with Markdown editing, rendered HTML output, bi-directional page relationships, full-text and title search, page history, syntax highlighting, and a table of contents sidebar. No big frameworks — intentionally minimal. Podman-compatible.

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Provided in deploy/docker-local/ — build from source |
| Docker run | docker.io/bityard/silicon (Docker Hub) |
| Python + Gunicorn | Direct install — any standard Flask/Gunicorn deployment |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Port to expose | Default: 5000 |
| preflight | Data volume path | Where the SQLite database and uploads are stored (/home/silicon/instance inside container) |
| security | SECRET_KEY | Random 16+ byte string for session cookies; app auto-generates if omitted (not stable across restarts) |

## Software-layer concerns

**Config:** Environment variables or a `.env` file. Key vars:

| Var | Default | Description |
|---|---|---|
| FLASK_RUN_HOST | 127.0.0.1 | Listen address (set 0.0.0.0 in container) |
| FLASK_RUN_PORT | 5000 | Listen port |
| INSTANCE_PATH | /home/silicon/instance | Where the DB and data files are stored |
| SECRET_KEY | (auto-generated) | Session cookie secret — set explicitly for stability across restarts |
| WERKZEUG_DEBUG_PIN | off | Disable Werkzeug debug PIN when only listening on localhost |

**Data:** SQLite database in INSTANCE_PATH (/home/silicon/instance). Mount a named volume or host path to persist across container restarts.

**Port:** 5000 by default. Bind to `127.0.0.1:5000` for local-only access; use a reverse proxy for remote access.

**No authentication built-in:** Silicon Notes has no user accounts or login. It is designed for personal/trusted-network use. Do not expose it publicly without a reverse proxy + auth layer.

**CodeMirror (optional):** Editor syntax highlighting can be enabled — see upstream docs.

## Docker Compose

```yaml
services:
  silicon:
    image: docker.io/bityard/silicon
    restart: unless-stopped
    ports:
      - "127.0.0.1:5000:5000"
    environment:
      - SECRET_KEY=replace-with-random-string
    volumes:
      - silicon_instance:/home/silicon/instance

volumes:
  silicon_instance:
```

Or build from source (uses the provided compose file):

```bash
git clone https://github.com/cu/silicon.git
cd silicon
cd deploy/docker-local
docker-compose up
```

## Upgrade procedure

```bash
docker compose pull silicon
docker compose up -d silicon
```

Data is in the named volume — preserved across upgrades. Check the releases page for any migration notes.

## Gotchas

- **No built-in auth** — intended for personal or LAN use only. Add a reverse proxy with HTTP basic auth or similar before exposing externally.
- **SECRET_KEY stability** — if not set, the app generates one at startup; this invalidates existing session cookies on each restart. Set a fixed SECRET_KEY in production.
- **Build-from-source compose** — the provided `deploy/docker-local/docker-compose.yaml` builds the image locally (no published image tag is specified in the compose file); use the Docker Hub image `bityard/silicon` for a pre-built option.

## Links

- Upstream repository: https://github.com/cu/silicon
- Docker Hub image: https://hub.docker.com/r/bityard/silicon
- Flask config docs: https://flask.palletsprojects.com/en/stable/config/
- Design rationale blog post: https://blog.bityard.net/articles/2022/December/the-design-of-silicon-notes-with-cartoons
