---
name: dokploy-project
description: Dokploy recipe for open-forge. Apache-2.0 self-hostable Platform-as-a-Service — open-source alternative to Vercel, Heroku, and Netlify. Deploys apps (Node/Go/Python/PHP/Ruby), databases (Postgres/MySQL/Mongo/Mariadb/libsql/Redis), Docker Compose stacks, automated backups, multi-node via Docker Swarm, Traefik integration, CLI + API, one-click templates (Plausible, Pocketbase, Calcom, etc). Install is a single `curl | bash` that spins up Postgres + Redis + Dokploy + Traefik as Docker Swarm services. This is the heavier "run a PaaS on your VPS" tier — NOT a drop-in lightweight tool.
---

# Dokploy

Apache-2.0 self-hostable Platform-as-a-Service. Upstream: <https://github.com/Dokploy/dokploy>. Docs: <https://docs.dokploy.com>. Cloud (managed): <https://app.dokploy.com>.

An open-source alternative to Vercel / Heroku / Netlify / Railway — deploy apps and databases through a web UI with git-based deploys, one-click templates, and a built-in Traefik reverse proxy for TLS + routing.

## Features

- **Applications:** Deploy any language — Node.js, PHP, Python, Go, Ruby, Elixir, Rust, etc. Via Nixpacks (auto-detect), Buildpacks, Dockerfile, or Docker Compose.
- **Databases:** MySQL, PostgreSQL, MongoDB, MariaDB, libSQL, Redis.
- **Backups:** Automated DB backups to S3-compatible storage.
- **Docker Compose:** Native support for multi-service stacks.
- **Multi-node:** Scale to a Docker Swarm cluster.
- **Templates:** One-click deploys for Plausible, Pocketbase, Cal.com, Ghost, Umami, etc.
- **Traefik integration:** Auto TLS via Let's Encrypt, subdomain routing.
- **Monitoring:** CPU / memory / disk / network per resource.
- **CLI / REST API** for scripting.
- **Notifications:** Slack / Discord / Telegram / Email on deploy events.
- **Multi-server:** Deploy from one Dokploy to external servers (via SSH).

## What Dokploy actually installs

The install script (`curl -sSL https://dokploy.com/install.sh | bash`) does **non-trivial things** to your host:

1. Installs Docker (if missing) via the official get.docker.com script, pinned version (currently 28.5.0).
2. Leaves any existing Docker Swarm and **initializes a new single-node Swarm** (`docker swarm init --advertise-addr <auto-detected-private-IP>`).
3. Creates an overlay network `dokploy-network`.
4. Creates `/etc/dokploy/` (with `chmod 777` — note this below).
5. Launches these as **Docker Swarm services**:
   - `dokploy-postgres` (postgres:16) — app DB with auto-generated password stored in a Docker Secret
   - `dokploy-redis` (redis:7) — cache / queue
   - `dokploy` (dokploy/dokploy:<version>) — the controller, with `/var/run/docker.sock` mounted
   - `dokploy-traefik` (traefik:v3.6.7) — the edge proxy, also with Docker socket mounted, publishing `:80`, `:443`, and `:443/udp`
6. Requires ports **80, 443, 3000** all free on install.

Translation: Dokploy takes over your entire host — Docker daemon, Swarm mode, ports 80/443/3000. Don't install it next to unrelated Docker workloads on the same VPS.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `install.sh` (canonical) | <https://dokploy.com/install.sh> | ✅ Recommended | Fresh Ubuntu 22.04 / 24.04 / Debian 12 VPS. What 99% of users pick. |
| Manual (Docker Swarm) | Copy commands from `install.sh` | ✅ | If you want to review each step, or you need to customize Swarm init args (`DOCKER_SWARM_INIT_ARGS`). |
| Docker Compose (non-Swarm) | Community only | ❌ Not supported | Upstream requires Swarm mode. Compose-only is NOT supported. |
| Dokploy Cloud | <https://app.dokploy.com> | ✅ | If you don't want to manage the platform itself. Paid tiers. |
| Proxmox LXC | The install script detects LXC and uses `--endpoint-mode dnsrr` automatically | ⚠️ Works but | Proxmox LXC support is present but upstream explicitly warns it may affect service discovery. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Is this a fresh VPS with NO existing Docker workloads?" | Boolean, required | Dokploy reinits Swarm; existing Docker services will be disrupted. |
| preflight | "Are ports 80, 443, and 3000 all free?" | Boolean, required | Install aborts if any are taken. |
| preflight | "Minimum: 2 GB RAM, 1 CPU, 30 GB disk. Do you have that?" | Boolean | Upstream minimums. |
| preflight | "Version channel?" | `AskUserQuestion`: `latest-stable (default)` / `canary` / specific-version | `DOKPLOY_VERSION=canary` or export specific tag before running. |
| dns | "Public domain?" | Free-text | Set in UI after install. Dokploy generates `<app>.<your-domain>` per-app; wildcard DNS recommended. |
| admin | "Initial admin email + password?" | Free-text (sensitive) | Created via web UI after install, at `http://<ip>:3000`. |
| network | "Advertise address for Swarm?" | Free-text, default = auto-detected private IP | Set via `ADVERTISE_ADDR` env var before running install script. Required on multi-NIC or cloud VPCs. |
| network | "Custom Swarm IP pool?" | Free-text, optional | Set via `DOCKER_SWARM_INIT_ARGS="--default-addr-pool 172.20.0.0/16 --default-addr-pool-mask-length 24"` if the default 10.0.0.0/8 overlaps with your VPC. |

## Install — the canonical one-liner

```bash
# 1. On a fresh VPS (Ubuntu 22.04+ / Debian 12+), as root or with sudo
# 2. Ensure a domain points at this VPS (for Traefik + Let's Encrypt later)
# 3. Run:
curl -sSL https://dokploy.com/install.sh | bash

# 4. Open http://<ip>:3000
# 5. Create the first admin account (whoever signs up first = owner)
```

**Before running**, inspect the script — it does a LOT:

```bash
curl -sSL https://dokploy.com/install.sh -o dokploy-install.sh
less dokploy-install.sh
sudo bash dokploy-install.sh
```

### With explicit version pin

```bash
# Production: pin to a specific release
export DOKPLOY_VERSION=v0.27.0  # check current stable at https://github.com/Dokploy/dokploy/releases
curl -sSL https://dokploy.com/install.sh | bash
```

### With custom Swarm settings (to avoid AWS VPC CIDR overlap)

```bash
export ADVERTISE_ADDR=10.0.1.42
export DOCKER_SWARM_INIT_ARGS="--default-addr-pool 172.20.0.0/16 --default-addr-pool-mask-length 24"
curl -sSL https://dokploy.com/install.sh | bash
```

## First-time setup

1. Open `http://<vps-ip>:3000/` (note: port 3000 is the admin panel; apps run on 80/443 via Traefik).
2. **Create the first user.** This first signup is the super-admin. After that, signups require invitation.
3. **Go to Server → Domain** → enter the domain you'll use for Dokploy itself (e.g. `panel.example.com`). Dokploy will issue a Let's Encrypt cert via Traefik and then redirect to HTTPS.
4. **Go to Server → Cluster** → confirm Swarm status.
5. **Projects → New Project** → create a project → add your first application from a Git source / Docker image / template.

## Deploying your first app

```text
Project: "my-site"
  Application: "landing"
    Source: Git → https://github.com/you/landing-page
    Build: Nixpacks (auto-detected) or Dockerfile
    Port: 3000
    Domain: landing.example.com
    Environment:
      NODE_ENV=production
      DATABASE_URL=...
    Deploy → Auto-builds and publishes at https://landing.example.com
```

Traefik automatically generates a Let's Encrypt cert for the domain.

## Upgrading Dokploy

Via the CLI:

```bash
curl -sSL https://dokploy.com/install.sh | bash -s -- update
```

Or via the web UI: **Settings → Dokploy → Check for updates**.

The install script's `update` mode does:

```bash
docker pull dokploy/dokploy:<version>
docker service update --image dokploy/dokploy:<version> dokploy
```

Backup first — see below.

## Data layout

All state is in Docker volumes + bind mounts on the host:

| Location | Content | Backup? |
|---|---|---|
| Docker volume `dokploy-postgres` | Dokploy's own database: users, projects, apps, deploy history | ✅ Critical |
| Docker volume `dokploy-redis` | Cache, queues | ❌ Regenerable |
| Docker volume `dokploy` | Docker creds, buildkit cache | ⚠️ Useful but regenerable |
| `/etc/dokploy/` | Traefik dynamic config, generated compose files, logs | ✅ |
| Docker Secret `dokploy_postgres_password` | DB password | ✅ (cannot recover DB without this) |
| Per-app volumes | Your apps' own data (managed via the UI) | ✅ Per-app |

**Backup the whole platform:**

```bash
# 1. Postgres
docker exec $(docker ps -q -f name=dokploy-postgres) \
    pg_dump -U dokploy dokploy | gzip > dokploy-$(date +%F).sql.gz

# 2. Secret (can't export from Docker Swarm directly — save when first generated)
#    Alternative: note the DB password at install time, recreate the secret on restore.

# 3. /etc/dokploy
sudo tar -czf etc-dokploy-$(date +%F).tar.gz /etc/dokploy/
```

## Gotchas

- **`install.sh` is destructive of existing Docker state.** It runs `docker swarm leave --force` and reinitializes Swarm. Any pre-existing Swarm services are lost. Do NOT run this on a host with other Docker workloads unless you're sure.
- **`/etc/dokploy` is created with `chmod 777`.** The install script does this intentionally (so non-root agents can write). If that offends you, `chmod 755 /etc/dokploy` after install and see if anything breaks. Upstream won't change this.
- **Docker socket mount = full root on host.** Both `dokploy` and `dokploy-traefik` containers mount `/var/run/docker.sock`, giving them unrestricted Docker API access. If either container is compromised, the host is compromised. This is inherent to any self-hosted PaaS, but noteworthy.
- **First-user-wins admin signup.** Port 3000 is unauthenticated until the first signup. Between install and your signup, anyone who can reach `:3000` can claim your instance. Firewall 3000 during install or sign up IMMEDIATELY.
- **Ports 80 + 443 captured by Traefik.** You can no longer run other web servers directly on this host. Route everything through Dokploy.
- **Swarm CIDR can collide with cloud VPC CIDR.** Default Swarm pool is 10.0.0.0/8; AWS default VPC is 172.31.0.0/16. Usually OK but if you run in 10/8 (e.g. some AWS private subnets), set `DOCKER_SWARM_INIT_ARGS` explicitly.
- **Single-node Swarm = no HA.** If the host dies, Dokploy dies. Adding a second node makes Dokploy multi-node, but the `dokploy` service itself is constrained to a manager node — plan for cold-standby DR, not hot failover.
- **Backups of apps must be set up per-app.** Dokploy configures backups for databases it manages, but your custom app volumes are NOT auto-backed-up. Configure each manually.
- **Templates are community-contributed compose files.** The "one-click Plausible" etc. templates are Dokploy's wrappers around upstream composes. If upstream changes, the template may drift — check last update date.
- **Traefik v3.6.7 is pinned by `install.sh`.** If a newer Traefik has a CVE fix, the install script doesn't auto-update. You need to manually `docker service update` or wait for a new Dokploy release.
- **`dokploy-traefik` runs as `docker run` not `docker service create`.** So Swarm doesn't manage it; killing the container directly kills Traefik. This is documented in install.sh comments as "optional: use docker service create instead." The `docker run` path is the default.
- **Resource limits are NOT enforced by default** on app containers. A single runaway app can OOM-kill the host. Configure CPU/RAM limits per-app in the UI's Advanced settings.
- **"Advertise address" for Swarm is auto-detected** from `ifconfig`-style enumeration of private ranges. On hosts with multiple private IPs (e.g. overlay networks, VPN interfaces), it may pick the wrong one. Set `ADVERTISE_ADDR` explicitly.
- **Proxmox LXC containers need `--endpoint-mode dnsrr`** — the install script detects this and adjusts. On Proxmox KVM VMs, no special config needed.
- **Cannot run on ARM32.** Dokploy's images are built for linux/amd64 and linux/arm64. 32-bit Raspberry Pi OS is unsupported; use 64-bit RPi OS on Pi 4 / Pi 5 / CM4.

## Links

- Upstream repo: <https://github.com/Dokploy/dokploy>
- Docs: <https://docs.dokploy.com>
- Install script (read before running): <https://dokploy.com/install.sh>
- Releases: <https://github.com/Dokploy/dokploy/releases>
- Templates repository: <https://github.com/Dokploy/templates>
- Discord: <https://discord.gg/2tBnJ3jDJc>
- Dokploy Cloud: <https://app.dokploy.com>
- Sponsors: <https://github.com/sponsors/Siumauricio>
