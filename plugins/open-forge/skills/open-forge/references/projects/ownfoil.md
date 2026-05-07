---
name: ownfoil
description: Ownfoil recipe for open-forge. Nintendo Switch library manager and self-hosted Tinfoil/Sphaira shop. Manages NSP/XCI/NSZ files, identifies missing updates/DLC, serves to Switch clients. AGPL-3.0, Docker. Source: https://github.com/a1ex4/ownfoil
---

# Ownfoil

A Nintendo Switch library manager and self-hosted shop server. Scans your local collection of NSP/XCI/NSZ game files, identifies titles and missing updates/DLCs, organizes the library automatically, and serves it as a shop to Nintendo Switch clients (Tinfoil, Sphaira, CyberFoil). Multi-user authentication, web UI, and shop customization included. AGPL-3.0 licensed, Python + Docker. Source: <https://github.com/a1ex4/ownfoil>

> **Legal note**: Ownfoil manages backup files. Ensure you own original copies of any games in your library as required by your local laws.

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Docker (single container) | Official image: `a1ex4/ownfoil` — recommended |
| Any Linux | Docker Compose | For persistent config/data management |
| Any Linux | Python (direct) | Requires Python; less convenient than Docker |
| ARM (Pi) | Docker | amd64, arm64/v8, arm/v7, arm/v6 images available |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Game library directory?" | Path | e.g. `/mnt/games` — directory containing NSP/XCI/NSZ files |
| "Port?" | Number | Default 8465 |
| "Admin username and password?" | credentials | Set via env vars or web UI on first run |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Console keys file?" | Path | Optional — enables content identification by decryption rather than filename |
| "Reverse proxy for HTTPS?" | Yes / No | Needed for external access; Tinfoil supports both HTTP and HTTPS |
| "PUID/PGID?" | UID:GID | Match to owner of game files for read access |

## Software-Layer Concerns

- **Game file access**: The container must be able to read your game files — mount the game directory as `/games` and set `PUID`/`PGID` to match file ownership.
- **Content identification**: Without console keys (`prod.keys`), Ownfoil identifies titles by filename (`[TITLEID][vVERSION]` format). With keys, it decrypts NCA headers for reliable identification.
- **Watchdog**: Ownfoil watches mounted library directories for changes — adding/removing/renaming files is reflected automatically without a manual rescan.
- **Multi-user**: Admin and guest users managed via Settings → Users or via `USER_ADMIN_NAME`/`USER_ADMIN_PASSWORD` env vars at startup.
- **Shop authentication**: Tinfoil/Sphaira connect with username+password. Ownfoil must have auth enabled (requires at least one admin user created).
- **Shop customization**: MOTD, theme, encrypted shop toggle all configurable in Settings → Shop.
- **No external dependencies**: Single container, SQLite database — no separate DB required.

## Deployment

### Docker Compose (recommended)

```yaml
services:
  ownfoil:
    container_name: ownfoil
    image: a1ex4/ownfoil
    restart: unless-stopped
    ports:
      - "8465:8465"
    environment:
      - PUID=1000        # match owner of /your/game/directory
      - PGID=1000
      - USER_ADMIN_NAME=admin
      - USER_ADMIN_PASSWORD=changeme
      # optional: pre-create a guest user
      # - USER_GUEST_NAME=guest
      # - USER_GUEST_PASSWORD=guestpass
    volumes:
      - /your/game/directory:/games
      - ./data:/app/data
      - ./config:/app/config
```

```bash
docker compose up -d
# Web UI: http://localhost:8465
```

### Docker run

```bash
docker run -d -p 8465:8465 \
  -v /your/game/directory:/games \
  -v ./config:/app/config \
  -v ./data:/app/data \
  -e PUID=1000 -e PGID=1000 \
  -e USER_ADMIN_NAME=admin \
  -e USER_ADMIN_PASSWORD=changeme \
  --name ownfoil \
  a1ex4/ownfoil
```

### Connect Tinfoil on Switch

1. On Switch, open Tinfoil → File Browser → New Shop
2. Protocol: `http` (or `https` if behind reverse proxy)
3. Host: `<your-server-ip>` (or domain)
4. Port: `8465`
5. Path: `/`
6. Username: (your admin/guest username)
7. Password: (your password)
8. Title: anything

### NGINX reverse proxy (for HTTPS)

```nginx
server {
    listen 443 ssl;
    server_name shop.example.com;

    location / {
        proxy_pass http://127.0.0.1:8465;
        proxy_set_header Host $host;
        proxy_buffering off;
    }
}
```

## Upgrade Procedure

1. `docker compose pull && docker compose up -d`
2. Data in `./data` and `./config` volumes persists across upgrades.

## Gotchas

- **Only download from the official GitHub repo**: The README explicitly warns against downloading executables from anywhere other than https://github.com/a1ex4/ownfoil.
- **File naming matters without keys**: Without `prod.keys`, files must be named `[TITLEID][vVERSION]` (e.g. `[0100ABC001234000][v0].nsp`) for reliable identification.
- **PUID/PGID must match file ownership**: If the container user can't read game files, the library scan will find nothing.
- **Admin user must be created before auth works**: Authentication is disabled until at least one admin user exists — create via env vars or Settings page on first run.
- **Multi-directory libraries**: Add multiple game directories in Settings → Library — each directory is scanned and watched separately.

## Links

- Source: https://github.com/a1ex4/ownfoil
- Docker Hub: https://hub.docker.com/r/a1ex4/ownfoil
- Tinfoil client: https://tinfoil.io/Download
- Sphaira client: https://github.com/ITotalJustice/sphaira
