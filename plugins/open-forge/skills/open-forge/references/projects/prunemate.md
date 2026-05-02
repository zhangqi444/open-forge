---
name: prunemate-project
description: PruneMate recipe for open-forge. Scheduled Docker resource cleanup tool (images, containers, networks, volumes, build cache). Web UI, multi-host via docker-socket-proxy, prune preview, notifications (Gotify/ntfy/Discord/Telegram), Homepage integration. Python/Flask. Upstream: https://github.com/anoniemerd/PruneMate
---

# PruneMate

A web UI for scheduled Docker resource cleanup. Automatically prune unused images, containers, networks, volumes, and build cache on daily/weekly/monthly schedules — or manually with a preview of exactly what will be deleted first. Supports multiple Docker hosts via docker-socket-proxy and push notifications via Gotify, ntfy.sh, Discord, or Telegram.

Upstream: <https://github.com/anoniemerd/PruneMate> | Website: <https://prunemate.org>

Built with Python (Flask) + APScheduler + Docker SDK. AMD64 and ARM64 images. AGPLv3.

> ⚠️ **PruneMate uses Docker's native `prune` commands.** It removes containers, images, networks, and volumes that Docker considers "unused." Volumes may contain important data — review what will be pruned before enabling automated schedules.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host (AMD64/ARM64) | Single container; mounts Docker socket |
| Multi-host setup | Add remote hosts via docker-socket-proxy on each remote |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port for web UI?" | Default: `7676` (host) → container `8080` |
| preflight | "Timezone?" | `PRUNEMATE_TZ` — e.g. `America/New_York`; default `UTC` |
| preflight | "12 or 24-hour time display?" | `PRUNEMATE_TIME_24H=true` (24h) or `false` (12h AM/PM) |
| config | "Enable authentication?" | Set `PRUNEMATE_AUTH_PASSWORD_HASH` (enables auth); optional `PRUNEMATE_AUTH_USER` |
| config (auth) | "Generate password hash?" | `docker run --rm anoniemerd/prunemate python prunemate.py --gen-hash "yourpassword"` |

## Software-layer concerns

### Image

```
anoniemerd/prunemate:latest
```

Docker Hub: <https://hub.docker.com/r/anoniemerd/prunemate>

### Compose

```yaml
services:
  prunemate:
    image: anoniemerd/prunemate:latest
    container_name: prunemate
    restart: unless-stopped
    ports:
      - "7676:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./logs:/var/log
      - ./config:/config
    environment:
      - PRUNEMATE_TZ=America/New_York
      - PRUNEMATE_TIME_24H=true
      # Optional auth — enable by setting the hash:
      # - PRUNEMATE_AUTH_USER=admin
      # - PRUNEMATE_AUTH_PASSWORD_HASH=<base64-encoded-hash>
```

> Source: upstream README — <https://github.com/anoniemerd/PruneMate>

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `PRUNEMATE_TZ` | `UTC` | Timezone for scheduling and timestamps |
| `PRUNEMATE_TIME_24H` | `true` | `true` for 24-hour, `false` for 12-hour display |
| `PRUNEMATE_CONFIG` | `/config/config.json` | Path to config file inside container |
| `PRUNEMATE_AUTH_USER` | `admin` | Username (only used when auth is enabled) |
| `PRUNEMATE_AUTH_PASSWORD_HASH` | — | Base64-encoded scrypt hash — **setting this enables auth** |

### Enabling authentication

Auth is opt-in — triggered only when `PRUNEMATE_AUTH_PASSWORD_HASH` is set.

**Generate a password hash:**

```bash
docker run --rm anoniemerd/prunemate python prunemate.py --gen-hash "yourpassword"
```

Copy the output Base64 string into `PRUNEMATE_AUTH_PASSWORD_HASH`.

> **Why Base64?** Raw scrypt hashes contain `$` characters that Docker Compose interprets as variable substitution. Base64-encoding produces an alphanumeric string that YAML handles safely.

> **Homepage/API integration:** For Basic Auth clients (e.g., Homepage dashboard widget), use your **actual password** (not the hash) in Basic Auth headers.

### Schedule options

Configure in the web UI: Daily, Weekly, Monthly, or Manual-only (schedule toggle). Set the time and day of week/month per cleanup type.

### What gets pruned

Configure selectively in the web UI:
- **Containers** — stopped containers
- **Images** — dangling and unused images
- **Networks** — unused networks
- **Volumes** — unused volumes (⚠️ may contain data — review carefully)
- **Build cache** — Docker builder cache (often recovers 10 GB+)

### Prune preview

Before any manual prune, use the Preview button to see exactly which resources will be deleted. Scheduled runs execute without preview — rely on the manual preview to confirm behavior before enabling schedules.

### Multi-host setup

To manage remote Docker hosts, run [docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy) on each remote host:

```yaml
# On the remote host:
services:
  socket-proxy:
    image: tecnativa/docker-socket-proxy
    environment:
      - CONTAINERS=1
      - IMAGES=1
      - NETWORKS=1
      - VOLUMES=1
      - POST=1     # required for prune operations
      - BUILD=1    # required for build cache pruning
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "2375:2375"
```

Then add the remote host in PruneMate UI → Docker Hosts with URL `tcp://<remote-ip>:2375`.

> ⚠️ `BUILD=1` is required on the proxy for build cache pruning. Without it, build cache prune returns 403.
> ⚠️ `POST=1` is required for any prune operation (all prune commands use POST requests).

### Notifications

Configure in Settings: Gotify, ntfy.sh, Discord webhook, or Telegram bot. Test from the UI before relying on notifications.

### Statistics

PruneMate tracks cumulative space reclaimed and resources deleted across all runs. Stats survive container restarts via the `./config` volume mount.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Config and logs in `./config` and `./logs` persist across upgrades.

## Gotchas

- **Volume pruning is destructive** — Docker's volume prune removes any volume not attached to a running container. A stopped container's volumes are considered "unused." Review carefully before enabling volume prune in automated schedules.
- **`POST=1` required on docker-socket-proxy** — all Docker prune operations use HTTP POST. Without it, every prune attempt on a remote host fails with permission denied.
- **`BUILD=1` required for build cache pruning** — separately gated on the proxy. Missing it causes 403 on build cache prune.
- **Base64-encode the password hash** — raw scrypt hashes contain `$` characters that YAML/Docker Compose misinterprets. Always use the `--gen-hash` command which outputs Base64.
- **Auth is all-or-nothing** — once `PRUNEMATE_AUTH_PASSWORD_HASH` is set, all UI access requires login. There is no per-feature auth granularity.
- **Schedule runs without preview** — unlike manual prune (which shows a preview), scheduled runs execute immediately. Use the manual preview flow first to confirm expected behavior.
- **Timezone must be set** — `PRUNEMATE_TZ=UTC` is the default but schedules may run at unexpected local times. Always set your actual timezone.

## Links

- Upstream README: <https://github.com/anoniemerd/PruneMate>
- Website: <https://prunemate.org>
- Docker Hub: <https://hub.docker.com/r/anoniemerd/prunemate>
- docker-socket-proxy: <https://github.com/Tecnativa/docker-socket-proxy>
