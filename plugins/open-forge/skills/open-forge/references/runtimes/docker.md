---
name: docker-runtime
description: Cross-cutting runtime module for Docker-based deployments. Loaded whenever the user picks Docker as the runtime, regardless of where (Lightsail, EC2, Hetzner, DO, GCP, BYO VPS, localhost). Owns Docker install on the host + docker-compose lifecycle. Project recipes own their own image / compose file / app-specific env.
---

# Docker runtime

Reusable across every infra. The project recipe specifies *what* to run (image, docker-compose file, env vars); this module specifies *how* — install Docker, manage the container lifecycle, troubleshoot common Docker issues.

## When this module is loaded

User answered the **how** question with anything Docker-based:

- "EC2 + Docker", "Lightsail Ubuntu + Docker", "Hetzner CX + Docker"
- "BYO VPS + Docker"
- "localhost + Docker Desktop / colima / OrbStack"

Skipped when the runtime is bundled by the infra (EKS = Kubernetes, ECS Fargate = serverless containers, vendor blueprints).

## Host requirements

- Linux: kernel ≥ 4.x, systemd, `curl`, `bash`. ARM and x86_64 both supported.
- macOS / Windows (only valid for `infra/localhost.md`): Docker Desktop, colima, or OrbStack.
- Disk: ≥ 20 GB free (image cache + volumes).
- RAM: at least 2 GB free for the most lightweight projects; 4 GB for anything that builds source via `pnpm install` / `npm install` / `cargo build` (build OOMs are common on smaller hosts).

## Install Docker on the host

For Linux infras (Lightsail Ubuntu, EC2, Hetzner, DO, BYO VPS), Claude runs the install script after announcing it:

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker "$USER"           # log out + back in for group change
docker compose version                     # confirm Compose v2 plugin present
```

Verify after install:

```bash
docker run --rm hello-world                # pulls the image, runs, exits 0 on success
```

For `infra/localhost.md`, ask the user which Docker distribution they have (Docker Desktop / colima / OrbStack) and verify with `docker compose version` instead of installing.

## Compose file conventions

Projects ship their own `docker-compose.yml`. The runtime module assumes the project recipe handed Claude a path. Generic patterns:

```bash
cd "$PROJECT_DIR"

# Bring up
docker compose up -d <service-name>

# Live logs
docker compose logs -f <service-name>

# Restart after config change
docker compose restart <service-name>

# Stop everything
docker compose down

# Run a one-off command in a service container
docker compose run --rm <service-name> <command>

# Exec inside a running container
docker compose exec <service-name> <command>

# Health probe (most projects expose /healthz)
docker compose exec <service-name> sh -c 'curl -sf http://127.0.0.1:<port>/healthz'
```

## Persistence — bind mounts vs named volumes

Project recipes pick one. Defaults:

- **Bind mount** (`/host/path:/container/path`) for config + data the user wants to inspect on the host (most cases). Survives container recreate and host reboot. Permissions can be tricky — see *Gotchas* below.
- **Named volume** (`volume-name:/container/path`) for opaque state Docker manages. Cleaner permissions. Less inspectable.

## Upgrades

Generic pattern (specific commands in the project recipe):

```bash
cd "$PROJECT_DIR"
git pull                               # if the recipe is a cloned repo
docker compose pull                    # if using a pinned registry image
docker compose build                   # if building locally
docker compose up -d --force-recreate  # apply
```

Persistent state in bind mounts / named volumes survives.

## Sandbox / Docker-in-Docker

Some projects (OpenClaw is one) optionally run additional containers from inside their main container, requiring access to the host's Docker socket. When enabled:

- Mount `/var/run/docker.sock:/var/run/docker.sock` into the project container
- Pass `DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)` so the container's group permissions line up

Project recipe owns whether this is on. Confirm with the user before enabling — it's a meaningful trust escalation (the container can launch sibling containers as root on the host).

## Firewall

Project recipes specify which ports they expose. Open them at the *infra* layer (e.g. `aws lightsail put-instance-public-ports` for Lightsail; `ufw allow` on a generic VPS; provider firewall UI elsewhere). Default: keep app ports closed to the public internet and reach via SSH tunnel.

For infras that already have a reverse proxy (`infra/aws/lightsail-blueprint.md` for vendor blueprints with bundled Apache), the project listens on `127.0.0.1` and the proxy forwards from `:443`.

## Common gotchas

- **Build OOM** during `pnpm install` / `npm install`: peak memory often exceeds 1 GB. On a 2 GB VPS the OOM killer terminates the build with `signal: killed` or exit 137. Mitigations: `NODE_OPTIONS=--max-old-space-size=2048`, swap file, or resize the VPS.
- **Bind-mount permissions**: container's app user (often `node` uid 1000 or `www-data` uid 33) may not be able to write to a host directory the user created. Fix: either `chown` to the matching uid, or run a one-shot root container to chown (`docker compose run --rm --user root --entrypoint sh <svc> -c 'chown -R 1000:1000 /mounted/path'`). On rootless Docker / NFS mounts this can still fail — document per-project.
- **Compose v1 vs v2**: this module assumes v2 (`docker compose ...` with a space). v1 (`docker-compose ...` with a hyphen) is deprecated and missing some features. If `docker compose version` fails, the user has v1 only and needs to upgrade.
- **`docker.sock` exposure**: only mount when the project genuinely needs sandbox/sibling-container support. Anyone in the container with socket access has root-equivalent on the host.
- **Image pull bandwidth**: first deploy on a fresh VPS pulls hundreds of MB. Tell the user to expect 5–10 min on residential ISPs / small VPS networks.
- **Cache eviction**: `docker compose build` reuses BuildKit cache. Clean up with `docker builder prune` or `docker system prune` if disk fills up.

## Reference

- Docker official install: <https://docs.docker.com/engine/install/>
- Compose v2 reference: <https://docs.docker.com/compose/>
