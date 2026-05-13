---
name: actual-project
description: Actual Budget recipe for open-forge. Local-first personal finance and budgeting tool. Covers Docker Compose (primary self-hosted method), environment configuration, data persistence, and upgrade procedure. Derived from https://actualbudget.org/docs/install/docker and https://github.com/actualbudget/actual-server.
---

# Actual Budget

Local-first personal finance tool built on Node.js. Upstream: <https://github.com/actualbudget/actual>. Server repo: <https://github.com/actualbudget/actual-server> (read-only since Feb 2025 — merged into main repo under `packages/sync-server`). Documentation: <https://actualbudget.org/docs/install/docker/>.

Actual is 100% free and open-source. It uses envelope budgeting and syncs changes across devices via the Actual Server component. All data is stored locally on the server — no cloud dependency required.

## Compatible install methods

| Method | Upstream URL | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://actualbudget.org/docs/install/docker/> | yes | Recommended self-hosted method. Single container, minimal dependencies. |
| Fly.io managed | <https://actualbudget.org/docs/install/fly/> | yes | Low-cost managed host (~$1.50/mo). Out of scope for open-forge. |
| PikaPods | <https://www.pikapods.com/pods?run=actual> | upstream-recommended | Managed hosting (~$1.40/mo). Out of scope for open-forge. |
| Local desktop apps | <https://actualbudget.org/download/> | yes | Windows/Mac/Linux apps for single-user offline use. No server needed. |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| preflight | "What port should Actual run on?" | Integer default 5006 | Maps to 5006:5006 in docker-compose. |
| preflight | "Where should budget data be stored on the host?" | Path default ./actual-data | Mounted to /data inside container. |
| config | "Enable HTTPS with your own certificate?" | Yes / No | Set ACTUAL_HTTPS_KEY and ACTUAL_HTTPS_CERT env vars if yes. |
| config | "Upload file sync size limit (MB)?" | Integer default 20 | ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB |
| config | "Encrypted upload file sync size limit (MB)?" | Integer default 50 | ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB |

## Docker Compose install

Upstream: <https://actualbudget.org/docs/install/docker/>

### docker-compose.yml

```yaml
services:
  actual_server:
    image: docker.io/actualbudget/actual-server:latest
    ports:
      - '5006:5006'
    environment:
      # - ACTUAL_HTTPS_KEY=/data/selfhost.key
      # - ACTUAL_HTTPS_CERT=/data/selfhost.crt
      # - ACTUAL_PORT=5006
      # - ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB=20
      # - ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB=50
      # - ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB=20
    volumes:
      - ./actual-data:/data
    healthcheck:
      test: ["CMD-SHELL", "node src/scripts/health-check.js"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 20s
    restart: unless-stopped
```

### Deploy steps

```bash
mkdir actual-data
docker compose up -d
```

Access at http://localhost:5006. On first launch, create a password to protect the server.

### Data directory

Container writes all budget files to /data, mapped to ./actual-data on the host. Back this directory up regularly — it contains all budget databases.

## Software-layer concerns

### Configuration (environment variables)

Remove the environment: block entirely if not using any variables — leaving it empty can cause parse warnings.

| Variable | Default | Description |
|---|---|---|
| ACTUAL_PORT | 5006 | Port the server listens on inside the container |
| ACTUAL_HTTPS_KEY | (none) | Path to TLS key inside container e.g. /data/selfhost.key |
| ACTUAL_HTTPS_CERT | (none) | Path to TLS cert inside container e.g. /data/selfhost.crt |
| ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB | 20 | Max unencrypted sync file size |
| ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB | 50 | Max encrypted sync file size |
| ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB | 20 | Max upload file size |

Full config reference: <https://actualbudget.github.io/docs/Installing/Configuration>

### Ports

| Port | Use |
|---|---|
| 5006 | Web UI and sync API (HTTP or HTTPS) |

### Data directories (inside container)

| Path | Contents |
|---|---|
| /data | Budget databases, uploaded files, server state |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Actual Server uses rolling releases. The latest tag is updated frequently. Data in /data is preserved across upgrades.

## Gotchas

- Remove unused env block: The upstream docker-compose warns to remove the environment: key entirely if no variables are set.
- No external database: Actual uses its own file-based storage under /data. There is no PostgreSQL or MySQL dependency.
- Reverse proxy + HTTPS: For production use behind NGINX/Caddy, handle TLS at the proxy level or supply ACTUAL_HTTPS_KEY/ACTUAL_HTTPS_CERT pointing to certs mounted into the container.
- Port conflicts: Port 5006 must be free on the host. Change the left side of 5006:5006 to remap.
- Migration: Actual can import Mint, YNAB4, and nYNAB exports. See <https://actualbudget.org/docs/migration/>.

## Links

- GitHub (app): <https://github.com/actualbudget/actual>
- GitHub (server, read-only since Feb 2025): <https://github.com/actualbudget/actual-server> — merged into main repo; see `packages/sync-server`
- Install docs: <https://actualbudget.org/docs/install/docker/>
- Configuration reference: <https://actualbudget.github.io/docs/Installing/Configuration>
- Docker Hub: <https://hub.docker.com/r/actualbudget/actual-server>
