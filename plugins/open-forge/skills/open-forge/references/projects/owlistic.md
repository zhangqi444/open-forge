---
name: owlistic-project
description: Owlistic recipe for open-forge. Real-time collaborative note-taking and todo app. Notebooks/notes tree, WYSIWYG editor, inline todos, real-time sync, JWT auth, RBAC, trash, dark/light mode, markdown import. Go backend + NATS + PostgreSQL + React frontend. 4-container stack. Upstream: https://github.com/owlistic-notes/owlistic
---

# Owlistic

An open-source real-time note-taking and to-do app. Organized as notebooks → notes with a WYSIWYG rich text editor, inline todo items, real-time sync across sessions via NATS, JWT-based auth, role-based access control, trash bin, dark/light mode, and Markdown import.

> ⚠️ Still under active development — expect bugs and breaking changes.

Upstream: <https://github.com/owlistic-notes/owlistic> | Docs: <https://owlistic-notes.github.io/owlistic/docs/category/overview>

4-container stack: Go backend + React frontend + PostgreSQL + NATS.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | 4 containers; NATS for real-time event bus; PostgreSQL for persistence |
| ARM (Raspberry Pi etc.) | Build from source with `TARGETARCH=arm64` |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Frontend port?" | Default `80` (nginx) |
| preflight | "Backend port?" | Default `8080` — typically internal-only; frontend proxies to it |
| config | "Database password?" | `DB_PASSWORD`; default in upstream compose is `admin` — **change this** |
| config | "Allowed origins?" | `APP_ORIGINS`; comma-separated; include your domain(s) |

## Software-layer concerns

### Images

Prebuilt images are in GitHub Container Registry:

```
ghcr.io/owlistic-notes/owlistic:latest       # backend
ghcr.io/owlistic-notes/owlistic-app:latest   # frontend
```

Note: upstream compose comments out the `image:` lines and uses `build:` by default. Uncomment the `image:` lines to use prebuilt images instead of building from source.

### Compose

```yaml
version: '3.8'

services:
  owlistic:
    image: ghcr.io/owlistic-notes/owlistic:latest
    # build:
    #   context: ./src/backend
    #   dockerfile: Dockerfile
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - nats
    environment:
      - APP_ORIGINS=http://localhost,http://localhost:80,https://notes.example.com
      - BROKER_ADDRESS=nats:4222
      - DB_HOST=postgres
      - DB_PORT=5432
      - DB_USER=owlistic
      - DB_PASSWORD=changeme    # change this
      - DB_NAME=owlistic
    networks:
      - server
      - events
      - db
    restart: unless-stopped

  owlistic-app:
    image: ghcr.io/owlistic-notes/owlistic-app:latest
    # build:
    #   context: ./src/frontend
    #   dockerfile: Dockerfile
    ports:
      - "80:80"
    depends_on:
      - owlistic
    restart: unless-stopped

  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: owlistic
      POSTGRES_PASSWORD: changeme    # match DB_PASSWORD above
      POSTGRES_DB: owlistic
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - db
    restart: unless-stopped

  nats:
    image: nats
    command:
      - --http_port
      - "8222"
      - -js
      - -sd
      - /var/lib/nats/data
    volumes:
      - nats_data:/var/lib/nats/data
    networks:
      - events
    restart: unless-stopped

volumes:
  postgres_data:
  nats_data:

networks:
  server:
  events:
  db:
```

> Source: upstream docker-compose.yml — <https://github.com/owlistic-notes/owlistic>

### Key environment variables (backend)

| Variable | Default | Purpose |
|---|---|---|
| `APP_ORIGINS` | `http://localhost*,...` | CORS allowed origins — include your frontend URL |
| `BROKER_ADDRESS` | `nats:4222` | NATS address for real-time events |
| `DB_HOST` | `postgres` | PostgreSQL host |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_USER` | `admin` | Database user |
| `DB_PASSWORD` | `admin` | Database password — **change this** |
| `DB_NAME` | `postgres` | Database name |

### Architecture

- **owlistic** (Go): REST API + real-time event publisher
- **owlistic-app** (React + nginx): Web UI; proxies API calls to the backend
- **postgres**: Persistent note/user storage
- **nats**: Pub/sub event bus; enables real-time sync across browser sessions (JetStream enabled with `-js`)

### Building from source (ARM / custom)

```bash
git clone https://github.com/owlistic-notes/owlistic.git
cd owlistic
TARGETARCH=arm64 docker compose build
docker compose up -d
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in `postgres_data` and `nats_data` named volumes. Check [releases](https://github.com/owlistic-notes/owlistic/releases) for breaking changes before upgrading.

## Gotchas

- **Upstream compose uses `build:` by default** — the `image:` lines are commented out. Either uncomment them (for prebuilt images) or keep the build workflow and run `docker compose build` before `up -d`.
- **Default credentials are `admin`/`admin`** — change `DB_PASSWORD` and `POSTGRES_PASSWORD` before first run.
- **`APP_ORIGINS` must include your actual domain** — if you're behind a reverse proxy at `https://notes.example.com`, add that URL. A mismatch will cause CORS errors in the browser.
- **NATS JetStream** — the `-js` flag enables JetStream (persistent messaging). The `-sd /var/lib/nats/data` flag sets the storage directory. Mount a volume here or NATS events won't survive restarts.
- **Active development** — the project warns of potential breaking changes. Pin image versions for production; use `:latest` only in dev/test.
- **No built-in TLS** — front `owlistic-app` (port 80) with Caddy or nginx for HTTPS.

## Links

- Upstream README: <https://github.com/owlistic-notes/owlistic>
- Documentation: <https://owlistic-notes.github.io/owlistic/docs/category/overview>
- Quick Start: <https://owlistic-notes.github.io/owlistic/docs/overview/quick-start>
- Installation guide: <https://owlistic-notes.github.io/owlistic/docs/category/installation>
- FAQ: <https://owlistic-notes.github.io/owlistic/docs/troubleshooting/faq>
- Releases: <https://github.com/owlistic-notes/owlistic/releases>
