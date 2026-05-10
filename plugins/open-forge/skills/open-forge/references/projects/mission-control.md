---
name: mission-control
description: Recipe for self-hosting Mission Control, an open-source dashboard for AI agent orchestration — dispatch tasks, run multi-agent workflows, monitor spend, and audit agent operations. Based on upstream documentation at https://github.com/builderz-labs/mission-control.
---

# Mission Control

Open-source dashboard for AI agent orchestration. Manage agent fleets, dispatch tasks, track costs and tokens, coordinate multi-agent pipelines, and audit security — all from a single web UI. SQLite-backed, zero external dependencies (no Redis/Postgres required). Integrates with OpenClaw, CrewAI, LangGraph, AutoGen, and Claude SDK gateways. Upstream: <https://github.com/builderz-labs/mission-control>. Stars: 4.7k+. License: MIT.

> **Alpha software** — APIs and database schemas may change between releases. Review security considerations before deploying to production.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker Compose | Zero-config; auto-generates credentials |
| Any Linux host | Docker Compose (hardened) | Read-only filesystem, cap-dropping, HSTS |
| Any host | Node.js (pnpm) | Direct; Node 22+ required |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | OPENCLAW_GATEWAY_HOST | Hostname/IP of OpenClaw gateway (default: host.docker.internal) |
| preflight | OPENCLAW_GATEWAY_PORT | Gateway port (default: 18789) |
| optional | MC_PORT | Web UI port (default: 3000) |
| optional | OPENCLAW_HOME | Path to ~/.openclaw for read-only agent config/memory mount |

## Docker Compose deployment

```bash
git clone https://github.com/builderz-labs/mission-control.git
cd mission-control

# Start (auto-generates credentials on first run)
docker compose up -d
```

Open `http://localhost:3000/setup` to create the admin account.

### Production-hardened deployment

```bash
docker compose -f docker-compose.yml -f docker-compose.hardened.yml up -d
```

Adds: read-only root filesystem, dropped Linux capabilities, HSTS, network isolation.

### Prebuilt GHCR image (no clone)

```bash
docker run --rm -p 3000:3000 ghcr.io/builderz-labs/mission-control:latest
```

## docker-compose.yml (key settings)

```yaml
services:
  mission-control:
    image: ghcr.io/builderz-labs/mission-control:latest
    container_name: mission-control
    ports:
      - "${MC_PORT:-3000}:3000"
    environment:
      # Gateway connection (server-side: MC backend → gateway)
      - OPENCLAW_GATEWAY_HOST=${OPENCLAW_GATEWAY_HOST:-host.docker.internal}
      - OPENCLAW_GATEWAY_PORT=${OPENCLAW_GATEWAY_PORT:-18789}
    volumes:
      - mc-data:/app/.data
      # Optional: mount OpenClaw state directory read-only
      # - ${OPENCLAW_HOME:-~/.openclaw}:/run/openclaw:ro
    extra_hosts:
      - "host.docker.internal:host-gateway"  # Linux: maps host.docker.internal

volumes:
  mc-data:
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| MC_PORT | 3000 | Host port for web UI |
| OPENCLAW_GATEWAY_HOST | host.docker.internal | Hostname of OpenClaw gateway |
| OPENCLAW_GATEWAY_PORT | 18789 | Port of OpenClaw gateway |
| NEXT_PUBLIC_GATEWAY_HOST | (auto) | Browser-visible gateway host (baked at build time — see Gotchas) |

## One-command installer (alternative)

```bash
git clone https://github.com/builderz-labs/mission-control.git
cd mission-control
bash install.sh --docker    # or --local for Node.js direct
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

SQLite DB in `mc-data` volume is preserved across upgrades.

## Gotchas

- **Alpha software** — breaking changes between releases are possible; check the changelog before upgrading in production.
- `NEXT_PUBLIC_GATEWAY_HOST` is **baked into the browser bundle at build time**, not set at runtime. For remote/VPS deployments where the browser needs to reach the gateway at a public hostname, rebuild the image: `NEXT_PUBLIC_GATEWAY_HOST=oc.example.com docker compose build`. Alternatively, use the Advanced Settings on the login page to set the gateway URL — it persists in localStorage.
- On Linux, `extra_hosts: host.docker.internal:host-gateway` is required for the container to reach an OpenClaw gateway running on the Docker host. Docker Desktop on macOS/Windows handles this automatically.
- The app can run in standalone mode (no gateway) by setting `NEXT_PUBLIC_GATEWAY_OPTIONAL=true` — useful for using the dashboard features independently.
- Default SQLite data is in the `mc-data` named volume — do not run `docker compose down -v` without a backup.

## Upstream docs

- README: https://github.com/builderz-labs/mission-control/blob/main/README.md
- Security considerations: https://github.com/builderz-labs/mission-control#security
