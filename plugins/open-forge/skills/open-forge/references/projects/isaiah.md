---
name: isaiah
description: Isaiah recipe for open-forge. Self-hostable web-based Docker fleet manager — a browser-based clone of lazydocker. Manage containers, images, volumes, networks, and stacks from any browser. Built in Go + Vanilla JS. Upstream: https://github.com/will-moss/isaiah
---

# Isaiah

A self-hostable web application for managing Docker resources from the browser — a feature-complete recreation of [lazydocker](https://github.com/jesseduffield/lazydocker) as a web UI. Manage containers, images, volumes, networks, and Compose stacks; open live shells into containers; stream logs; and bulk-update images — all over WebSocket from any browser. Upstream: <https://github.com/will-moss/isaiah>. License: MIT.

Isaiah is a single Go binary (or a ~4 MB Docker image) that mounts the Docker socket and exposes a WebSocket-driven terminal-style interface on a configurable port. No database required.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Recommended — socket-mounted single container. |
| Any Linux host | Docker run | Quick single-command start. |
| Any Linux host | Standalone binary | Pre-built binary from GitHub Releases; no Docker required. |
| Multi-node | Docker Compose (Master + Agents) | One Master instance, one Agent per additional host. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "Which port should Isaiah be accessible on?" | Integer | Default `3000`; change `SERVER_PORT` env var. |
| preflight | "Master password to secure Isaiah?" | Secret string | Set as `AUTHENTICATION_SECRET`. Required — default is well-known; must be changed. |
| preflight (optional) | "Put the password as a sha256 hash instead of plaintext?" | Boolean | Use `AUTHENTICATION_HASH` instead of `AUTHENTICATION_SECRET` if yes. |
| preflight (optional) | "Enable SSL / HTTPS inside the container?" | Boolean | Set `SSL_ENABLED=True` and mount `certificate.pem` + `key.pem`. Skip if behind a TLS-terminating reverse proxy. |
| preflight (optional) | "Path to directory for storing Compose stack files?" | Directory path | Maps to `STACKS_DIRECTORY`. Required if using the stack create/edit feature. |

## Software-layer concerns

### Key environment variables

| Variable | Purpose | Default |
|---|---|---|
| `SERVER_PORT` | Port Isaiah listens on | `3000` |
| `AUTHENTICATION_ENABLED` | Require password to log in | `True` |
| `AUTHENTICATION_SECRET` | Master password (plaintext) | `one-very-long-and-mysterious-secret` |
| `AUTHENTICATION_HASH` | Master password as sha256 hex — use instead of `AUTHENTICATION_SECRET` | empty |
| `SSL_ENABLED` | Terminate TLS inside the container | `False` |
| `STACKS_DIRECTORY` | Directory for generated `docker-compose.yml` files | `.` (container root) |
| `CONTAINER_LOGS_TAIL` | Number of log lines to load | `50` |
| `TABS_ENABLED` | Comma-separated list of tabs to show | `stacks,containers,images,volumes,networks` |
| `SERVER_ROLE` | `Master` or `Agent` (multi-node deployments only) | `Master` |

Full reference: <https://github.com/will-moss/isaiah#configuration>

### docker-compose.yml (from upstream examples)

```yaml
# compose.yml — simple single-host setup
# Source: https://github.com/will-moss/isaiah/blob/main/examples/docker-compose.simple.yml
services:
  isaiah:
    image: mosswill/isaiah:latest
    # Also mirrored at: ghcr.io/will-moss/isaiah:latest
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      SERVER_PORT: "80"
      AUTHENTICATION_SECRET: "your-very-long-and-mysterious-secret"
```

Source: <https://github.com/will-moss/isaiah/blob/main/examples/docker-compose.simple.yml>

> **Warning:** Mounting `/var/run/docker.sock` gives the container full Docker daemon access. Do not expose Isaiah on a public IP without authentication and a TLS-terminating reverse proxy.

### Quick start

```bash
# Minimal one-liner (change the password first)
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -p 3000:3000 \
  -e AUTHENTICATION_SECRET="my-strong-password" \
  mosswill/isaiah

# With Docker Compose (edit password before running)
curl -LO https://raw.githubusercontent.com/will-moss/isaiah/main/examples/docker-compose.simple.yml
docker compose -f docker-compose.simple.yml up -d
```

### Multi-node deployment

To manage Docker resources on multiple hosts from a single Isaiah instance, run one Master and one Agent per additional host.

**Agent (each additional host):**

```yaml
services:
  isaiah-agent:
    image: mosswill/isaiah:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      SERVER_ROLE: "Agent"
      MASTER_HOST: "master.example.com:3000"    # Master's host:port
      MASTER_SECRET: "your-master-password"      # Same as Master's AUTHENTICATION_SECRET
      AGENT_NAME: "my-secondary-host"
```

Agents register automatically with the Master; they appear as switchable contexts in the Isaiah web UI.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d --force-recreate
```

Isaiah is stateless — no data volume to migrate. All configuration lives in environment variables.

## Gotchas

- **Change the default password immediately** — the default `AUTHENTICATION_SECRET` value (`one-very-long-and-mysterious-secret`) is public knowledge. Override it before any network exposure.
- **Docker 23.0.0+ required; Stacks tab needs Docker 26.0.0+** — older Docker versions may fail at startup or lose Stacks functionality.
- **`SSL_ENABLED=False` when behind a reverse proxy** — enabling `SSL_ENABLED=True` while a proxy (Nginx/Caddy/Traefik) already handles TLS causes double-TLS and connection failures.
- **`STACKS_DIRECTORY` must exist and be writable** — if set to a non-existent or read-only path, the stack editor will error on save. Mount a host directory as a volume and set the path accordingly.
- **Docker socket is write access** — the `:ro` flag in the example compose restricts to read-only, which breaks most management operations. Use `:rw` (no flag needed — rw is default) for full control, or `:ro` for monitoring-only.
- **Multi-node message size** — in large multi-node setups, the default 100 KB WebSocket message limit may be too small. Increase `SERVER_MAX_READ_SIZE` on the Master if connections drop unexpectedly.
- **Forward proxy authentication** — Isaiah supports header-based SSO (e.g. Authelia). Set `FORWARD_PROXY_AUTHENTICATION_ENABLED=True` and configure `FORWARD_PROXY_AUTHENTICATION_HEADER_KEY` / `_HEADER_VALUE` accordingly.

## Upstream docs

- GitHub: <https://github.com/will-moss/isaiah>
- Docker Hub: <https://hub.docker.com/r/mosswill/isaiah>
- GitHub Container Registry: <https://ghcr.io/will-moss/isaiah>
- Examples: <https://github.com/will-moss/isaiah/tree/main/examples>
