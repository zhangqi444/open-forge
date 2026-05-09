---
name: traefik-manager
description: Traefik Manager is a self-hosted web UI for managing Traefik reverse proxy — add routes, manage middlewares, monitor services, and view TLS certificates without editing YAML by hand. Upstream: https://github.com/chr0nzz/traefik-manager
---

# Traefik Manager

Traefik Manager is a clean, self-hosted web UI for [Traefik](https://traefik.io/) reverse proxy. It reads Traefik's API in real-time and lets you browse routes, middlewares, services, and TLS certificates across any Traefik provider (Docker, Kubernetes, Swarm, File, etc.) — no YAML editing required. Optional static config editor with Monaco (VS Code) engine, TOTP 2FA, OIDC/SSO, per-device API keys, and a companion mobile app. Upstream: <https://github.com/chr0nzz/traefik-manager>.

Latest stable release: **v1.0.4** (check <https://github.com/chr0nzz/traefik-manager/releases> for latest).

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS / bare-metal | Docker + Docker Compose | Single container (Python/Flask + Gunicorn, Alpine). |
| Raspberry Pi (ARM64) | Docker + Docker Compose | Multi-arch image. |
| Podman (rootless) | Podman + Quadlet/systemd | SELinux labels supported. See upstream Podman guide. |
| Native Linux | Python 3.11 + systemd | No container required. See upstream Linux guide. |

Traefik Manager connects to Traefik via the Traefik REST API — it does **not** need Docker socket access for basic read-only operation.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Traefik API URL?" | e.g. `http://traefik:8080` (if on same Docker network) or `http://traefik-host:8080`. |
| preflight | "Traefik API username/password?" | If Traefik's dashboard has basic auth enabled. Leave blank if unauthenticated. |
| preflight | "Path to Traefik dynamic config file?" | Optional. Only needed for static config editor feature. e.g. `/path/to/traefik/dynamic.yml`. |
| security | "Enable HTTPS / TLS for Traefik Manager itself?" | Set `COOKIE_SECURE=true` when serving over HTTPS. |
| optional | "Enable OIDC/SSO?" | If yes, collect OIDC issuer URL, client ID, client secret. |

## Software-layer concerns

### Config paths

| Path in container | What |
|---|---|
| `/app/config/` | App config (`manager.yml`), dynamic.yml (if mounted), backups. Mount as bind-mount. |
| `/app/backups/` | Auto-generated config backups before edits. Mount separately for retention. |
| `/app/config/dynamic.yml` | Traefik dynamic config file — mount the **real** Traefik file here for editing. |

### Key environment variables

| Variable | Default | Notes |
|---|---|---|
| `COOKIE_SECURE` | `false` | Set to `true` when serving over HTTPS (required for secure session cookies). |
| `CONFIG_DIR` | `/app/config` | Override config directory path. |
| `CONFIG_PATHS` | Auto | Override paths to `acme.json`, access log, static config via Settings UI or env. |
| `SECRET_KEY` | Auto-generated | Flask session secret. Set explicitly for stable sessions across restarts. |

The setup wizard configures Traefik API URL, credentials, and feature toggles interactively at first launch. Alternatively set these via `manager.yml` (see <https://traefik-manager.xyzlab.dev/manager-yml.html>).

### Auto-generated password

On first start, an admin password is auto-generated and printed to container logs:

```bash
docker compose logs traefik-manager | grep -i "password\|generated"
```

Change it immediately via **Settings → Account** or CLI:

```bash
docker exec -it traefik-manager flask reset-password
```

## Docker Compose

```yaml
# docker-compose.yml
services:
  traefik-manager:
    image: ghcr.io/chr0nzz/traefik-manager:latest
    container_name: traefik-manager
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      - COOKIE_SECURE=false          # set true if behind HTTPS proxy
    volumes:
      # Bind-mount your Traefik dynamic config for the static config editor:
      - /path/to/traefik/dynamic.yml:/app/config/dynamic.yml
      # Persistent app config + backups:
      - ./traefik-manager/config:/app/config
      - ./traefik-manager/backups:/app/backups
```

```bash
docker compose up -d

# Check auto-generated admin password:
docker compose logs traefik-manager | grep -i password

# Access at http://your-server:5000
# Setup wizard guides you through Traefik API URL configuration.
```

### Connecting to Traefik on the same Docker host

If Traefik and Traefik Manager run in the same Compose project or on a shared network, connect via the container/service name:

```yaml
services:
  traefik-manager:
    # ...
    networks:
      - traefik_network   # same network as your Traefik container
    environment:
      - COOKIE_SECURE=false
```

In the setup wizard, set the Traefik API URL to `http://traefik:8080` (replace `traefik` with your Traefik container name).

## Upgrade procedure

```bash
docker compose pull
docker compose up -d   # config volume untouched
```

Check release notes at <https://github.com/chr0nzz/traefik-manager/releases> — major versions may require running the one-liner installer to update the full stack.

## Gotchas

- **Traefik API must have `api.insecure: true` or dashboard auth configured.** By default Traefik disables its REST API. Add `api.insecure: true` to `traefik.yml` (or enable the dashboard with auth) so Traefik Manager can connect.
- **Static config editor requires mounting `dynamic.yml` read-write.** If the file is mounted read-only, the editor loads but cannot save. Mount the actual Traefik dynamic config with write access and ensure the container user can write to it.
- **`COOKIE_SECURE=true` requires HTTPS.** If you set `COOKIE_SECURE=true` but Traefik Manager is served over plain HTTP, session cookies will never be sent and you cannot log in. Only set this when behind an HTTPS reverse proxy.
- **Traefik restart method (socket proxy vs poison pill).** When the static config editor restarts Traefik, it uses whichever restart method is configured — socket proxy (sidecar with minimal socket exposure) is the most secure. Direct Docker socket access is supported but exposes the full socket. See <https://traefik-manager.xyzlab.dev/security.html>.
- **Provider tabs show "no data" if Traefik API is unreachable.** Verify the API URL in Settings → Configuration. The Docker tab specifically reflects live containers via the Traefik Docker provider — not direct Docker socket.

## Upstream docs

Full documentation: <https://traefik-manager.xyzlab.dev/>  
Docker deployment guide: <https://traefik-manager.xyzlab.dev/docker.html>  
Environment variables: <https://traefik-manager.xyzlab.dev/env-vars.html>  
Security hardening: <https://traefik-manager.xyzlab.dev/security.html>
