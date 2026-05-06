---
name: posio
description: Recipe for Posio — a self-hosted multiplayer geography game. Players compete to click on a map to identify cities or countries. Built with Django/GeoDjango, HTMX, and Redis. Docker supported.
---

# Posio

Self-hosted multiplayer geography game. Players join rounds and compete by clicking on a map to identify cities or countries (flags mode). Real-time gameplay via Django Channels and Redis. Built with GeoDjango, HTMX, and Leaflet. Upstream: <https://github.com/abrenaut/posio>. Live demo: <https://posio.abrenaut.com/>.

License: MIT. Platform: Python 3.12, Redis, Docker. Stars: ~677. Low recent activity (stable).

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose | Recommended |
| Python/Django native | For development |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| network | "Host port to expose the web UI on?" | Default `8000` |
| storage | "Host path for the SQLite/Spatialite database?" | Mount to `/app/db` for persistence |

## Docker Compose (recommended)

```bash
git clone https://github.com/abrenaut/posio.git
cd posio

# Initialize database and create game data
docker compose run web manage.py migrate
docker compose run web manage.py createcitiesgame
docker compose run web manage.py createflagsgame

# Start
docker compose up -d
```

`docker-compose.yml` (from the repo):
```yaml
x-app: &default-app
  build:
    context: "."
  depends_on:
    - redis
  volumes:
    - .:/app
    - spatialite:/app/db
  environment:
    - REDIS_HOST=redis

services:
  redis:
    image: redis:7.2.4-bookworm
    volumes:
      - redis:/data

  web:
    <<: *default-app
    ports:
      - "8000:8000"
    command: ["manage.py", "runserver", "0.0.0.0:8000"]

  gameloops:
    <<: *default-app
    command: ["manage.py", "startgameloops"]

volumes:
  spatialite: {}
  redis: {}
```

Web UI at `http://your-host:8000`.

## Native Python install

```bash
# Prerequisites: Python 3.12, Redis, GeoDjango system deps (GDAL, GEOS, SpatiaLite)
# Ubuntu/Debian:
sudo apt install python3 python3-venv redis-server \
  binutils libproj-dev gdal-bin libgdal-dev libsqlite3-mod-spatialite

git clone https://github.com/abrenaut/posio.git
cd posio

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

mkdir -p db
./manage.py migrate
./manage.py createcitiesgame
./manage.py createflagsgame

# Start web server
./manage.py runserver

# In a separate terminal: start game loops
./manage.py startgameloops
```

## Architecture

| Service | Role |
|---|---|
| `web` | Django web server (ASGI via Daphne) — serves the UI |
| `gameloops` | Background process managing game rounds and timing |
| `redis` | Channel layer for real-time WebSocket communication |

Both `web` and `gameloops` must run simultaneously for gameplay to work.

## Software-layer concerns

| Concern | Detail |
|---|---|
| Database | SpatiaLite (SQLite with spatial extension) — stored in `db/` |
| Cache/channels | Redis (required for real-time WebSocket gameplay) |
| Default port | `8000` |
| Game modes | Cities game and Flags game — both created via management commands |
| No auth | Open to all visitors; no user accounts or login |

## Upgrade procedure

```bash
git pull
docker compose build
docker compose run web manage.py migrate
docker compose up -d
```

## Gotchas

- **`gameloops` service is required**: Without the gameloops process, game rounds never start. Both `web` and `gameloops` containers must be running.
- **GeoDjango dependencies**: The native install requires GDAL, GEOS, and SpatiaLite system libraries. These can be tricky to install on non-Debian systems. The Docker image handles this automatically.
- **`createcitiesgame` and `createflagsgame` are one-time setup**: Only run these once after initial migration. Running them again may create duplicate game entries.
- **No authentication**: The game is open to anyone who can reach the URL. Use a reverse proxy with IP allowlisting or HTTP basic auth if you want to restrict access.
- **Low activity**: The project is stable but not under active development. It works as-is for a fun self-hosted game.

## Upstream links

- Source: <https://github.com/abrenaut/posio>
- Live demo: <https://posio.abrenaut.com/>
