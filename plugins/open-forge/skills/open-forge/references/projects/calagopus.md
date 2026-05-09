---
name: calagopus
description: Recipe for Calagopus — a Rust-based game server management platform with a Docker-native panel and optional Wings daemon.
---

# Calagopus

Rust-based game server management platform. Provides a web panel for creating, managing, and monitoring game servers via a Wings daemon that runs on each node. Supports single-node All-in-One (AIO) deployments and multi-node setups with separate Panel and Wings containers. Upstream: https://github.com/calagopus/panel. Official site and docs: https://calagopus.com/

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Single Linux host | Docker Compose (AIO image) | Recommended for most users. Panel + Wings in one container. Image tag: calagopus/panel:aio. No separate node registration needed. |
| Multiple Linux hosts | Docker Compose (Panel standalone + Wings standalone) | Panel on one host (calagopus/panel:latest), Wings on each game-server node (separate Wings image). |
| Single host with extensions | Docker Compose (AIO heavy image) | Use calagopus/panel:heavy-aio only if installing extensions that require build tooling. |

## Image variants

| Tag | Use case |
|---|---|
| :aio | All-in-One (Panel + Wings) — recommended single-node path |
| :heavy-aio | AIO with extension build tooling |
| :latest | Panel only (multi-node, Panel on separate host) |
| :heavy | Panel only with extension build tooling |
| :nightly-aio | Nightly AIO builds (unstable) |
| :nightly | Nightly Panel-only builds (unstable) |

Current stable release: release-1.0.4

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Single node (Panel + Wings on same host) or multi-node?" | Choice: single / multi | Single → AIO image. Multi → standalone Panel + separate Wings nodes. |
| preflight | "Public URL where the Panel will be reachable?" | URL | Required for agent communication and browser access. |
| preflight | "Do you need extensions (e.g. from the extensions marketplace)?" | Yes/No | Yes → use a :heavy variant for build tooling. |
| wings | "Wings node hostname/IP?" | Free-text | Required for multi-node: each Wings node needs a reachable address. |

## Software-layer concerns

### Wings config file (IMPORTANT — must pre-create before docker compose up)

The AIO and standalone compose files mount ./wings-config.yml into the container as a file. If this file does not exist on the host before running docker compose up, Docker will create it as a directory, breaking the container.

```bash
touch wings-config.yml
```

Do this before the first docker compose up.

### Key config locations (inside container)

- Panel config: managed via environment variables and the web UI
- Wings config: /etc/wings/config.yml (mapped from ./wings-config.yml on host)
- Panel database: stored in the container's data volume

### Ports

- Panel web UI: typically 80/443 behind a reverse proxy, or a custom port
- Wings daemon: 443 (default, for Panel-to-Wings communication)
- Game server ports: allocated dynamically per game server configuration

## Deploy (AIO — single node, recommended)

```bash
# 1. Pre-create wings-config.yml (mandatory)
touch wings-config.yml

# 2. Download the AIO compose file from upstream documentation
# (The docker-compose.yml in the repo root defaults to building from source)
# Use the AIO image directly:
cat > docker-compose.yml << 'EOF'
services:
  calagopus:
    image: calagopus/panel:aio
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
      - "2022:2022"
    volumes:
      - calagopus-data:/app/data
      - ./wings-config.yml:/etc/wings/config.yml
    environment:
      - APP_URL=https://panel.example.com

volumes:
  calagopus-data:
EOF

# 3. Start
docker compose up -d

# 4. View logs for setup instructions
docker compose logs -f calagopus
```

See the full Docker installation guide at https://calagopus.com/docs/panel/installation/docker for the complete and up-to-date compose file and environment variables. The upstream docs are the authoritative reference.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

The container handles database migrations on startup.

## Gotchas

- wings-config.yml MUST be pre-created as a file before docker compose up — if it doesn't exist, Docker creates it as a directory and the container fails to start. Run: touch wings-config.yml
- AIO vs standalone — the AIO image wires up Wings to the Panel automatically. For multi-node deployments, use separate Panel and Wings images and register each Wings node manually in the Panel.
- :heavy variants only needed for extensions — the heavy image includes Rust build tooling. It has a larger footprint; use the non-heavy image unless you plan to install extensions.
- Nightly tags are unstable — :nightly and :nightly-aio receive unreviewed commits. Use :aio or :latest for production.
- Public URL must be set before initialization — the APP_URL environment variable must match the URL you'll use to access the Panel. Changing it after first start may require additional config updates.
- Refer to upstream docs for the current compose file — the docker-compose.yml in the GitHub repo root is set up for building from source. Use the compose file from the documentation at https://calagopus.com/docs/panel/installation/docker for a pull-based deploy.

## Links

- GitHub repo: https://github.com/calagopus/panel
- Official docs: https://calagopus.com/docs/panel/installation/docker
- Wings Docker install: https://calagopus.com/docs/wings/installation/docker
- Panel overview and requirements: https://calagopus.com/docs/panel/overview
- Extensions: https://calagopus.com/docs/panel/extensions
