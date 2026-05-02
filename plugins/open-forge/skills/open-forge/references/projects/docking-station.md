---
name: docking-station-project
description: Docking Station recipe for open-forge. Self-hosted Docker container update manager webapp. Monitor all stacks for image updates, show update maturity period, one-click stack updates via docker compose pull+up, discovery via labels or opt-in/opt-out strategy, DockerHub API caching, remote Docker hosts via SSH/TCP, settings.yml config, Swagger UI. Next.js + FastAPI. Docker socket required. Upstream: https://github.com/LooLzzz/docking-station
---

# Docking Station

A self-hosted web app for monitoring and updating Docker containers. Shows all your stacks with their current image versions and available updates. Supports one-click stack updates (runs `docker compose up --pull always` on the target stack's compose file). Includes an update maturity period (inspired by dockcheck) so you can wait for new images to "settle" before applying. Connects to remote Docker hosts via SSH or TCP. DockerHub API results are cached to avoid rate limits.

Built with Next.js (frontend) and FastAPI (backend). Requires Docker socket access.

Upstream: <https://github.com/LooLzzz/docking-station> | Docker Hub: `loolzzz/docking-station`

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Requires Docker socket access; can also connect to remote Docker hosts via SSH/TCP |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Web UI port; no default in compose -- choose one (e.g. `3000`) |
| preflight | "Compose files location?" | Mount path for your docker-compose files; must match inside/outside the container |
| config | "Remote Docker hosts?" | `settings.yml` -- optional SSH or TCP remote hosts |
| config | "Discovery strategy?" | `opt-out` (default, all stacks included unless excluded) or `opt-in` (only labeled stacks) |

## Software-layer concerns

### Image

```
loolzzz/docking-station:latest
```

Docker Hub. (No official GHCR mirror listed.)

### Compose

```yaml
services:
  docking-station:
    image: loolzzz/docking-station
    container_name: docking-station
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # Mount your compose files directory -- left path MUST equal right path
      - /mnt/compose-files:/mnt/compose-files
      - ./settings.yml:/app/settings.yml:ro
```

Source: upstream README -- https://github.com/LooLzzz/docking-station

> **Important**: The compose files volume mount path must be the **same on host and inside the container** (left == right). Docking Station reads the `config_files` label from running containers to locate their compose files and passes that absolute path directly to `docker compose`. If the paths differ, it won't find the files.

### settings.yml

Create a `settings.yml` file in your deployment directory (copy from `settings.template.yml` in the repo):

```yaml
server:
  cache_control_max_age: 1d
  discovery_strategy: opt-out   # opt-out (default) or opt-in
  docker_hosts:
    - localhost
    # - ssh://user@remote-host
    # - tcp://10.0.0.5:2375
  dryrun: false
  ignore_compose_stack_name_keywords:
    - devcontainer
  time_until_update_is_mature: 1w  # updates shown as "mature" after this period

auto_updater:
  enabled: false      # auto-update is NOT recommended (experimental, untested)
  interval: 1d
  max_concurrent: 1
```

Full settings reference: upstream `settings.template.yml` -- <https://github.com/LooLzzz/docking-station/blob/main/settings.template.yml>

### Discovery strategies

| Strategy | Behavior |
|---|---|
| `opt-out` | All stacks are monitored unless labeled `com.loolzzz.docking-station.enabled=false` |
| `opt-in` | Only stacks labeled `com.loolzzz.docking-station.enabled=true` are monitored |

### Update flow

1. Docking Station reads the `config_files` Docker label on each container to find its compose file path
2. On update: runs `docker compose -f <config_file> up --pull always`
3. If a `.env` file exists alongside the compose file, it is automatically used

### Maturity period

New image versions are flagged but not highlighted until `time_until_update_is_mature` has passed since the image was pushed. This gives time for post-release issues to surface before you apply the update.

### Remote Docker hosts

Add SSH or TCP hosts to `settings.yml`:

```yaml
docker_hosts:
  - localhost
  - ssh://user@192.168.1.100
  - tcp://10.0.0.5:2375
```

For SSH, the container must have SSH keys set up with access to the remote host.

### Swagger UI

API documentation is available at `/docs`.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No persistent data beyond `settings.yml` (stateless; reads Docker state on each request).

## Gotchas

- **Compose file path must match exactly** -- the host path and container path for your compose files must be identical (`/mnt/compose-files:/mnt/compose-files`). A mismatch means Docking Station can't invoke `docker compose` on the right files.
- **Docker socket required** -- the container needs read access to `/var/run/docker.sock`. Use `:ro` for safety; the update action is triggered via the API which calls back out through the socket.
- **Auto-updater is experimental** -- the README explicitly warns it is untested. Leave `auto_updater.enabled: false` unless you understand the risks.
- **DockerHub rate limits** -- results are cached (configurable via `cache_control_max_age`). If you hit rate limits, increase the cache duration.
- **`config_files` label** -- stacks managed by Docker Compose automatically get this label set to the compose file path. Manually-run containers without compose won't be updatable (only monitorable).
- **`dryrun: true`** -- set this to preview what would be updated without actually running any `docker compose` commands. Useful for testing the setup.

## Links

- Upstream README: <https://github.com/LooLzzz/docking-station>
- Settings template: <https://github.com/LooLzzz/docking-station/blob/main/settings.template.yml>
- Docker Hub: <https://hub.docker.com/r/loolzzz/docking-station>
