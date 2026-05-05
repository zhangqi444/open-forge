---
name: conduit-project
description: Conduit recipe for open-forge. Lightweight Matrix homeserver written in Rust. Docker or single binary. Upstream: https://gitlab.com/famedly/conduit
---

# Conduit

A lightweight Matrix homeserver written in Rust. Easy to set up on low-power hardware (Raspberry Pi, small VPS). Suitable for hosting Matrix for a family, small team, or organization. Beta status — most Matrix features work; some federation edge cases and E2EE emoji comparison are still in progress. Upstream: https://gitlab.com/famedly/conduit. Docs: https://famedly.gitlab.io/conduit

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS/bare-metal | Docker (single container) | Recommended; official Docker images on GitLab Registry and Docker Hub |
| Any Linux VPS/bare-metal | Docker Compose + Traefik | Upstream provides compose files for Traefik setups |
| Any Linux VPS/bare-metal | Native binary | Single Rust binary; minimal dependencies |
| Raspberry Pi | Docker or native binary | Upstream explicitly supports low-power hardware |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Matrix server name (e.g. matrix.example.com) | Set as CONDUIT_SERVER_NAME; used in Matrix IDs (@user:server.name) |
| preflight | Public domain for the homeserver | Must be internet-accessible for federation |
| preflight | Allow registration? (true/false) | CONDUIT_ALLOW_REGISTRATION — disable after initial setup for invite-only |
| preflight | Allow federation? (true/false) | CONDUIT_ALLOW_FEDERATION — disable for isolated/private installs |
| tls | Reverse proxy choice (Traefik / nginx / Caddy / other) | Conduit itself runs on port 6167; TLS terminated by proxy |
| advanced | Max request size in bytes | CONDUIT_MAX_REQUEST_SIZE, default 20000000 (20MB) |
| advanced | Trusted Matrix servers | CONDUIT_TRUSTED_SERVERS, default ["matrix.org"] |

## Software-layer concerns

### Docker run (quick start)

```bash
docker run -d -p 8448:6167 \
  -v db:/var/lib/matrix-conduit/ \
  -e CONDUIT_SERVER_NAME="your.server.name" \
  -e CONDUIT_DATABASE_BACKEND="rocksdb" \
  -e CONDUIT_ALLOW_REGISTRATION=true \
  -e CONDUIT_ALLOW_FEDERATION=true \
  -e CONDUIT_MAX_REQUEST_SIZE="20000000" \
  -e CONDUIT_TRUSTED_SERVERS='["matrix.org"]' \
  -e CONDUIT_MAX_CONCURRENT_REQUESTS="100" \
  -e CONDUIT_PORT="6167" \
  --name conduit \
  registry.gitlab.com/famedly/conduit/matrix-conduit:latest
```

### Docker images

| Registry | Image | Tag |
|---|---|---|
| GitLab Registry | registry.gitlab.com/famedly/conduit/matrix-conduit | :latest (stable), :next (dev) |
| Docker Hub | docker.io/matrixconduit/matrix-conduit | :latest (stable), :next (dev) |

### Docker Compose

Upstream provides multiple compose files depending on proxy setup:

- docker-compose.yml — generic reverse proxy
- docker-compose.for-traefik.yml — existing Traefik instance
- docker-compose.with-traefik.yml — includes Traefik

Get compose files from: https://gitlab.com/famedly/conduit/-/tree/next

```bash
docker compose up -d
```

### Configuration

Conduit can be configured via a conduit.toml file or environment variables (CONDUIT_* prefix).

Key config options (env var form):

- CONDUIT_SERVER_NAME — Matrix server name used in user IDs
- CONDUIT_DATABASE_BACKEND — rocksdb (recommended) or sqlite
- CONDUIT_DATABASE_PATH — /var/lib/matrix-conduit/ (default in container)
- CONDUIT_PORT — internal listen port (default: 6167)
- CONDUIT_MAX_REQUEST_SIZE — max body size in bytes
- CONDUIT_ALLOW_REGISTRATION — true/false
- CONDUIT_ALLOW_FEDERATION — true/false
- CONDUIT_TRUSTED_SERVERS — JSON array of trusted Matrix servers
- CONDUIT_CONFIG — set to "" to use env vars only (no toml file)

Config file example: https://gitlab.com/famedly/conduit/-/blob/next/conduit-example.toml

### Data directories

- /var/lib/matrix-conduit/ — RocksDB database (mount as volume)

### Reverse proxy requirement

Conduit must be behind a reverse proxy for TLS. The Matrix spec requires ports 443 (client API) and optionally 8448 (federation). Example nginx delegation block for .well-known/matrix:

See upstream docs: https://famedly.gitlab.io/conduit/deploying/generic.html

### Port reference

- 6167 — Conduit internal port (inside container)
- 8448 — Matrix federation port (map container 6167 to host 8448)
- 443 — Client API (handled by reverse proxy)

## Upgrade procedure

```bash
# Docker
docker pull registry.gitlab.com/famedly/conduit/matrix-conduit:latest
docker compose up -d
# or for bare docker run: docker stop conduit && docker rm conduit && re-run docker run with new image

# Check release notes before upgrading:
# https://gitlab.com/famedly/conduit/-/releases
```

Conduit uses RocksDB which handles upgrades without manual migration in most cases.

## Gotchas

- Server name is permanent — CONDUIT_SERVER_NAME is embedded in all Matrix IDs (@user:server.name). Changing it after accounts exist breaks federation and identity. Choose carefully.
- Disable open registration after setup — CONDUIT_ALLOW_REGISTRATION=true is needed for the first admin account; set to false (or use registration tokens) afterward to prevent spam accounts.
- Federation requires correct .well-known or SRV DNS records — see Matrix spec and Conduit deployment docs for well-known/matrix/server and well-known/matrix/client delegation setup.
- Beta status — most rooms work; some advanced E2EE features (emoji SAS verification over federation) and outgoing read receipts/typing/presence over federation are not yet complete.
- RocksDB volume must be persisted — losing the /var/lib/matrix-conduit/ volume loses all data. Use a named Docker volume or bind mount.
- Port 8448 for federation — some Matrix servers try federation on port 8448; ensure this is accessible if CONDUIT_ALLOW_FEDERATION=true.

## Links

- Upstream (GitLab): https://gitlab.com/famedly/conduit
- Documentation: https://famedly.gitlab.io/conduit
- Docker deployment guide: https://famedly.gitlab.io/conduit/deploying/docker.html
- Generic deployment guide: https://famedly.gitlab.io/conduit/deploying/generic.html
- Matrix.org ecosystem clients: https://matrix.org/ecosystem/clients
- Community Matrix room: #conduit:ahimsa.chat
