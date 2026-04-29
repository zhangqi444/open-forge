---
name: Dockge
description: Fancy, easy-to-use Docker Compose stack manager with web UI — edit compose.yaml in-browser, see real-time logs, converts `docker run` to compose. By the author of Uptime Kuma.
---

# Dockge

Dockge is a web UI for managing Docker Compose stacks on a single host. Unlike Portainer it is compose-native: it stores every stack as a plain `compose.yaml` in a host directory you control, so you can `git` your stacks and still edit/apply them through the UI.

- Upstream repo: <https://github.com/louislam/dockge>
- Image: `louislam/dockge` on Docker Hub
- Author: Louis Lam (also: Uptime Kuma)

## Compatible install methods

| Infra          | Runtime             | Notes                                                              |
| -------------- | ------------------- | ------------------------------------------------------------------ |
| Any Linux host | Docker + Compose    | The only supported install path; needs Docker socket access        |
| macOS          | Docker Desktop      | Works; path quoting of `/opt/stacks` may need adjusting            |
| Windows        | Docker Desktop WSL2 | Supported; use WSL Linux paths, not `C:\…`                         |

Not supported: running Dockge itself without access to the Docker daemon — by design it drives `docker compose`.

## Inputs to collect

| Input                  | Example            | Phase   | Notes                                                                               |
| ---------------------- | ------------------ | ------- | ----------------------------------------------------------------------------------- |
| Listen port            | `5001`             | Runtime | Container's UI port                                                                  |
| Stacks directory       | `/opt/stacks`      | Host    | **Must be identical on host and inside container**; Dockge passes this path to `docker compose` which runs **on the host** |
| Docker socket          | `/var/run/docker.sock` | Host | Must be mountable; grants full root-equivalent access over the daemon              |
| Dockge data dir        | `./data`           | Runtime | Stores the user DB, settings, 2FA secrets                                            |
| Admin password         | set on first boot  | Runtime | No default; you create it in the setup wizard                                        |

## Install via Docker Compose

Upstream's canonical compose (verbatim at <https://github.com/louislam/dockge/blob/master/compose.yaml>):

```yaml
services:
  dockge:
    image: louislam/dockge:1   # pins to the 1.x line; last GA tag is 1.5.0 at time of writing
    restart: unless-stopped
    ports:
      - 5001:5001
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/app/data
      # Stacks Directory — ⚠️ left path MUST equal right path
      - /opt/stacks:/opt/stacks
    environment:
      - DOCKGE_STACKS_DIR=/opt/stacks
```

Steps:

```sh
mkdir -p /opt/stacks
mkdir -p /opt/dockge && cd /opt/dockge
curl -fsSL https://raw.githubusercontent.com/louislam/dockge/master/compose.yaml -o compose.yaml
docker compose up -d
```

Open `http://<host>:5001` and create the admin account. Each stack you create drops a folder under `/opt/stacks/<stackname>/` containing `compose.yaml` + `.env` — you can edit these outside Dockge and they'll appear in the UI.

## Data & config layout

- `./data/` → `/app/data` — Dockge's own SQLite DB (users, 2FA seeds, settings)
- `/opt/stacks/<stack>/compose.yaml` — each stack's compose file
- `/opt/stacks/<stack>/.env` — optional env file per stack
- Dockge does NOT own the stack volumes; those live wherever the stack's compose says

Back up `./data/` plus the entire stacks tree.

## Upgrade

1. Check releases: <https://github.com/louislam/dockge/releases>.
2. `docker compose pull && docker compose up -d` (image tag `1` floats within 1.x; for stricter pinning use a specific version tag like `1.5.0`).
3. DB migrations run automatically on start.

## Gotchas

- **"Left path must equal right path" for `/opt/stacks`.** Dockge stores `compose.yaml` at `/opt/stacks/foo/compose.yaml` inside the container, then shells out to `docker compose -f /opt/stacks/foo/compose.yaml up -d` on the host via the socket. The host sees the same path. If you mount `/opt/stacks:/data/stacks` Dockge will write to a path that doesn't exist on the host and every `up` will fail. This is the single most common install mistake.
- **`/var/run/docker.sock` = root on the host.** Anyone with UI access effectively has root on the box. Treat Dockge like you'd treat a sudoers-grant tool: strong password, 2FA, and do not expose `5001` publicly without an auth-aware reverse proxy.
- **No built-in TLS.** Front with Caddy/Traefik/nginx if exposing beyond localhost.
- **Stacks created outside `/opt/stacks` are invisible** to Dockge; it only manages its configured stacks directory.
- **Compose v2 only.** Old `docker-compose` (v1 python) is not supported; the host must run Docker 20.10+ with `docker compose`.
- **Agent mode (manage remote hosts) is experimental.** Upstream's agent feature lets one Dockge UI drive other hosts over websockets; treat as beta and read <https://github.com/louislam/dockge#agent-mode>.
- **Private registries need `/root/.docker/` (or equivalent) mounted** so the container can read auth. The sample compose has this commented out.
- **No RBAC.** Dockge has one admin account. Multi-user teams should look at Portainer instead.
- **SQLite DB can be corrupted by forceful restart.** Use `docker compose stop` rather than `kill`.

## Links

- Repo: <https://github.com/louislam/dockge>
- Sample compose: <https://github.com/louislam/dockge/blob/master/compose.yaml>
- Docker Hub: <https://hub.docker.com/r/louislam/dockge>
- Releases: <https://github.com/louislam/dockge/releases>
- Discord: <https://discord.gg/jn3abHRuzQ>
