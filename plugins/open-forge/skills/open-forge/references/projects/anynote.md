---
name: anynote
description: AnyNote recipe for open-forge. Covers Docker backend deployment based on https://github.com/ychisbest/AnyNote README.
---

# AnyNote

Open-source, self-hosted, cross-platform note-taking application with a WYSIWYG Markdown editor, real-time sync, and AI-assisted features. The backend is self-hosted via Docker; clients (desktop apps) are downloaded from GitHub Releases. Upstream: <https://github.com/ychisbest/AnyNote>. Website: <https://anynote.online>.

The AnyNote backend listens on port `8080` and stores data in a `/data` volume. Clients connect to your self-hosted backend using a URL and secret you configure.

## Compatible install methods

Verified against the upstream README.md.

| Method | Upstream | When to use |
|---|---|---|
| Docker (backend) | README.md §Backend Deployment | Standard self-hosted deployment |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| secret | "Choose a secret key for the AnyNote backend (used to secure the instance)" | String | Any strong random string; share with client users |
| volume | "Path on the host to persist AnyNote data?" | Host path | E.g. /srv/anynote or ~/anynote-data |
| port | "Which host port should AnyNote listen on?" | Number | Default 8080 |
| tls | "Front AnyNote with a reverse proxy for HTTPS?" | Yes / No | Recommended for remote access |

## Software-layer concerns

### Data directory

AnyNote stores all data under `/data` inside the container. Mount a persistent host directory at `/data` to preserve notes across container restarts.

### Environment variables

| Var | Description | Example |
|---|---|---|
| `secret` | Authentication secret; must match what you configure in the client app | `mysecretvalue` |

### Client setup

After deploying the backend:
1. Download the desktop/mobile client from GitHub Releases: <https://github.com/ychisbest/AnyNote/releases>
2. In the client, point it to your backend URL: `http://<host>:<port>` (or `https://` if behind a reverse proxy)
3. Enter the `secret` you configured on the server

## Method — Docker

> **Source:** <https://github.com/ychisbest/AnyNote> README.md §Getting Started

### Quick start

```bash
docker run -d \
  -p <host_port>:8080 \
  -e secret=<YOUR_SECRET> \
  -v <path_to_data>:/data \
  anynoteofficial/anynote:latest
```

Replace:
- `<host_port>` — port to expose on the host (e.g. `8080`)
- `<YOUR_SECRET>` — your chosen secret key
- `<path_to_data>` — host path for data persistence

### Docker Compose

```yaml
services:
  anynote:
    image: anynoteofficial/anynote:latest
    restart: unless-stopped
    ports:
      - "${ANYNOTE_PORT:-8080}:8080"
    environment:
      secret: "${ANYNOTE_SECRET}"
    volumes:
      - "${ANYNOTE_DATA_PATH:-/srv/anynote}:/data"
```

`.env` file:
```
ANYNOTE_SECRET=change-me-to-a-strong-random-string
ANYNOTE_PORT=8080
ANYNOTE_DATA_PATH=/srv/anynote
```

```bash
docker compose up -d
docker compose logs -f anynote
```

### Verify

The backend does not have a standalone web UI — access is through the desktop/mobile clients. After starting, confirm the container is running:

```bash
docker ps
curl http://localhost:8080/
```

## Upgrade procedure

```bash
docker pull anynoteofficial/anynote:latest
docker compose down && docker compose up -d
# Or for plain docker run: stop, remove, and re-run with the same flags
```

## Gotchas

- **Secret must be consistent.** The `secret` env var must match what is entered in the client app. Changing the secret after deployment will lock out existing client sessions.
- **No web UI.** AnyNote does not provide a browser-based UI — it is a backend API consumed by native desktop and mobile clients downloaded from GitHub Releases.
- **No built-in TLS.** For remote access, front the backend with a reverse proxy (Caddy, nginx, Traefik) that terminates HTTPS.
- **Data is entirely in `/data`.** Backup this volume to preserve notes.
- **Cross-platform clients.** Desktop and mobile clients are available from GitHub Releases; update them independently of the server.

## Links

- GitHub: <https://github.com/ychisbest/AnyNote>
- Releases (client downloads): <https://github.com/ychisbest/AnyNote/releases>
- Website: <https://anynote.online>
