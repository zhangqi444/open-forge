# Dockman

**What it is:** Docker management tool that gives users unfiltered access to their Docker Compose files. Browse, edit, and manage compose stacks directly through a web UI — designed for users who want full control without abstraction.

**Official URL:** https://dockman.radn.dev  
**GitHub:** https://github.com/RA341/dockman  
**Stars:** 612

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host with Docker | Docker Compose | Recommended persistent setup |
| Any Linux host with Docker | Docker Run | Quick test only — data lost on stop |

---

## Inputs to Collect

### Before deploying
- Absolute path to your compose stacks directory (e.g., `/opt/stacks`) — **must be identical** in the env var, host mount, and container mount
- Path for Dockman config persistence (e.g., `/opt/dockman/config`)

---

## Software-Layer Concerns

- **Docker socket access required:** Must mount `/var/run/docker.sock` into the container
- **Stacks path consistency:** The `DOCKMAN_COMPOSE_ROOT` env var, the host-side volume path, and the container-side volume path must all be the **same absolute path** — this is a hard requirement for Dockman to locate compose files
- **Config persistence:** Mount `/config` to preserve auth settings, preferences, and state across container restarts
- **Default port:** `8866`

### docker-compose.yaml

```yaml
services:
  dockman:
    container_name: dockman
    image: ghcr.io/ra341/dockman:latest
    environment:
      - DOCKMAN_COMPOSE_ROOT=/path/to/stacks    # 1️⃣ must match below
    volumes:
      - /path/to/stacks:/path/to/stacks          # 2️⃣ & 3️⃣ same path on both sides
      - /path/to/dockman/config:/config
      - /var/run/docker.sock:/var/run/docker.sock
    ports:
      - "8866:8866"
    restart: always
```

---

## Upgrade Procedure

1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- The triple-path consistency rule (`DOCKMAN_COMPOSE_ROOT`, host mount, container mount) is the most common setup mistake — all three must be the same absolute path
- Do not use `docker run --rm` for production; it deletes all data when the container stops
- Dockman manages compose stacks via the Docker socket — treat it as a privileged service; restrict network access accordingly

---

## References

- Full documentation: https://dockman.radn.dev/docs/category/install
- GitHub releases: https://github.com/RA341/dockman/releases
