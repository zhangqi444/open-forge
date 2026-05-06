---
name: espial
description: Espial recipe for open-forge. Open source web-based bookmarking server with multiple account support. Haskell backend with SQLite storage. Supports importing Pinboard and Firefox bookmarks, bookmarklet for quick saving, and tag-based organization. Source: https://github.com/jonschoning/espial
---

# Espial

Open source web-based bookmarking server intended for self-hosting. Stores bookmarks in a SQLite3 database. Supports multiple user accounts, tag-based organization, private/public bookmarks, a browser bookmarklet for quick saving, and importing from Pinboard JSON and Firefox bookmark exports. Simple, lightweight, and easy to deploy via Docker. Upstream: https://github.com/jonschoning/espial. Demo: https://esp.ae8.org/u:demo (username: demo, password: demo).

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker | Linux / macOS | Recommended. Image: jonschoning/espial |
| Docker Compose | Linux / macOS | See espial-docker repo |
| Build from source (Haskell Stack) | Linux / macOS | For development or custom builds |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Port to expose?" | Default: 3000 |
| install | "Data directory?" | Path on host to persist SQLite database |
| auth | "Admin username + password?" | Created via CLI on first run |

## Software-layer concerns

### Docker (recommended)

  # Pull and run:
  docker run -d \
    --name espial \
    --restart unless-stopped \
    -p 3000:3000 \
    -v /opt/espial:/data \
    jonschoning/espial

  # The SQLite database is stored at /data/espial.sqlite3 inside the container.

### Docker Compose (from espial-docker)

  # See: https://github.com/jonschoning/espial-docker

  services:
    espial:
      image: jonschoning/espial
      container_name: espial
      restart: unless-stopped
      ports:
        - "3000:3000"
      volumes:
        - ./data:/data

  docker compose up -d

### Create the database and first user

  # Initialize the database:
  docker exec -it espial espial -- +RTS -N -RTS createdb --conn /data/espial.sqlite3

  # Create a user:
  docker exec -it espial espial -- +RTS -N -RTS createuser \
    --conn /data/espial.sqlite3 \
    --userName yourusername \
    --userPassword yourpassword

  # (Alternatively, run stack exec migration -- createdb / createuser from source)

### Import bookmarks (optional)

  # Import Pinboard JSON export:
  docker exec -it espial espial -- +RTS -N -RTS importbookmarks \
    --conn /data/espial.sqlite3 \
    --userName yourusername \
    --bookmarkFile /path/to/pinboard-export.json

  # Import Firefox bookmarks:
  docker exec -it espial espial -- +RTS -N -RTS importfirefoxbookmarks \
    --conn /data/espial.sqlite3 \
    --userName yourusername \
    --bookmarkFile /path/to/firefox-bookmarks.json

### Browser bookmarklet

  # After logging in, go to Settings page to find the bookmarklet.
  # Drag it to your browser's bookmarks bar for one-click saving.

### Build from source (Haskell Stack)

  # Prerequisites: Haskell Stack (https://tech.fpcomplete.com/haskell/get-started)
  git clone https://github.com/jonschoning/espial.git
  cd espial
  stack build

  # Initialize database:
  stack exec migration -- createdb --conn espial.sqlite3

  # Create user:
  stack exec migration -- createuser \
    --conn espial.sqlite3 \
    --userName myusername \
    --userPassword myuserpassword

  # Start server (default port 3000):
  stack exec espial

### Ports

  3000/tcp   # Web UI (default; configure with PORT env var)

### Nginx reverse proxy

  location / {
      proxy_pass http://127.0.0.1:3000;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
  }

## Upgrade procedure

  # Docker:
  docker pull jonschoning/espial
  docker stop espial && docker rm espial
  # Re-run docker run command (data persists in /opt/espial volume)

  # From source:
  git pull origin main
  stack build
  # Re-run migration if schema changes: stack exec migration -- ...

## Gotchas

- **SQLite3 only**: Espial uses SQLite3 exclusively. No MySQL/PostgreSQL support. For most self-hosted single-user scenarios this is fine — SQLite handles it well. Back up the `.sqlite3` file regularly.
- **Multiple accounts supported but single-server**: Espial supports multiple user accounts, but all share the same server instance. Each user's bookmarks are stored in the same SQLite file with user ownership.
- **Public bookmarks**: bookmarks can be set to public (visible without login) or private. There's no per-user public URL discovery unless explicitly shared.
- **Haskell build time**: if building from source, initial `stack build` downloads and compiles GHC and all dependencies — this can take 15–30 minutes on the first run.
- **Android share app**: there's an Android app for sharing URLs directly to Espial: https://github.com/jonschoning/espial-share-android.

## References

- Upstream GitHub: https://github.com/jonschoning/espial
- Docker setup: https://github.com/jonschoning/espial-docker
- Demo: https://esp.ae8.org/u:demo
- Android share app: https://github.com/jonschoning/espial-share-android
