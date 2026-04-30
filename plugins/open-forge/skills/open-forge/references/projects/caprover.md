---
name: CapRover
description: PaaS layer on top of Docker Swarm. Point-and-click deploys for Node/Python/PHP/Ruby/Go/etc., one-click databases (MariaDB/MySQL/MongoDB/Postgres), automatic nginx reverse proxying, Let's Encrypt TLS, NetData dashboards, and a CLI. Self-hosted Heroku. Apache-2.0.
---

# CapRover

CapRover is a self-hosted Platform-as-a-Service: you install CapRover on a Linux VM, point a wildcard DNS record at it, and then deploy apps by `caprover deploy` (CLI), git push (via captain-definition), or one-click installers (from the built-in library of ~200 pre-packaged apps: Postgres, Redis, Ghost, MinIO, WordPress, etc.). Under the hood: Docker Swarm, Nginx, Let's Encrypt, NetData.

Unlike Coolify, Dokploy, or Dokku, CapRover has been stable and production-ready for years and runs on a Swarm cluster for native multi-node scaling.

- Upstream repo: <https://github.com/caprover/caprover>
- Docs: <https://caprover.com/docs/get-started.html>
- One-line install docs: <https://caprover.com/docs/get-started.html#step-1-caprover-installation>

## Architecture in one minute

CapRover **is itself a Docker container** (`caprover/caprover`) that runs on a Docker Swarm node. When you deploy an app through CapRover:

1. The `caprover/caprover` container (the "Captain" control plane) receives the tarball or build instruction
2. It builds a Docker image for your app using your `captain-definition` file
3. It creates a Swarm service + nginx virtual host + optional Let's Encrypt cert
4. Your app runs as a Swarm service, load-balanced by nginx

This means: CapRover manages Docker Swarm for you. You don't run `docker service` commands; the dashboard does.

## Compatible install methods

| Infra            | Runtime                                                           | Notes                                                   |
| ---------------- | ----------------------------------------------------------------- | ------------------------------------------------------- |
| Single Ubuntu 22.04 VM | Docker 25+ (from Docker's official repo, **not** snap) | **Recommended.** Minimum 1 GB RAM                        |
| Multi-node Swarm | Docker 25+ on each node                                           | CapRover manages the cluster via its Cluster tab         |
| DigitalOcean     | One-click marketplace app                                          | Easiest — pre-installs Docker + CapRover                 |
| AWS / GCP / Hetzner / Vultr | Fresh Ubuntu → install Docker → `docker run caprover/caprover` | Standard path                                        |
| Local laptop     | via `caprover serversetup` against localhost                      | Works for testing, needs port-forwarding for public apps |
| Kubernetes       | ❌ Not supported                                                  | CapRover is explicitly Swarm-based                       |

## Inputs to collect

| Input                      | Example                                              | Phase    | Notes                                                                     |
| -------------------------- | ---------------------------------------------------- | -------- | ------------------------------------------------------------------------- |
| Root domain                | `apps.example.com`                                   | DNS      | **Wildcard** `*.apps.example.com` must point to server IP (A record)      |
| Server public IP           | `203.0.113.42`                                       | DNS      | Wildcard A record target                                                   |
| Firewall ports             | 80, 443, 3000, 996, 7946, 4789, 2377                 | Network  | 80/443 = app traffic; 3000 = dashboard; rest = Swarm overlay              |
| Admin password             | change from default `captain42`                      | Bootstrap | **Default is `captain42` — change immediately**                            |
| Email for Let's Encrypt    | `you@example.com`                                    | TLS      | Used for LE account + cert expiry notifications                           |
| CLI (optional)             | `npm install -g caprover`                            | Bootstrap | Recommended for initial setup via `caprover serversetup`                   |

## Install (upstream one-liner)

From <https://caprover.com/docs/get-started.html>:

```sh
# On a fresh Ubuntu 22.04 or 24.04 VM with Docker 25+ installed:

# Open firewall (if ufw is on):
sudo ufw allow 80,443,3000,996,7946,4789,2377/tcp
sudo ufw allow 7946,4789,2377/udp

# Install CapRover:
docker run -d --name caprover --restart always \
  -p 80:80 -p 443:443 -p 3000:3000 \
  -e ACCEPTED_TERMS=true \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /captain:/captain \
  caprover/caprover

# Do NOT change port mappings — CapRover is hardcoded to these ports.
```

Wait for the bootstrap log to stabilize (~60 s), then visit `http://<server-ip>:3000` and log in with password `captain42`.

### Point a wildcard DNS record

Create at your DNS provider:

- **Type:** A
- **Host:** `*.apps` (or whatever subdomain you picked)
- **Points to:** server public IP
- **TTL:** anything (300 s while testing is fine)

Confirm propagation: `dig random-test.apps.example.com +short` should return your IP.

### Finalize setup via CLI (recommended)

```sh
# On your laptop (needs Node 18+):
npm install -g caprover

caprover serversetup
# Prompts for: CapRover IP (from step above)
#              root domain (e.g. apps.example.com)
#              new admin password
#              email for Let's Encrypt
#              whether to force HTTPS
```

After this: the dashboard is reachable at `https://captain.apps.example.com`. HTTPS is on and forced. Default password is changed.

## Deploying an app

From <https://caprover.com/docs/deployment-methods.html>:

```sh
# Inside your app's git repo (must contain a captain-definition file):
caprover deploy
# Prompts for app name (create it first in the dashboard)
```

A minimal `captain-definition`:

```json
{ "schemaVersion": 2, "templateId": "node/20" }
```

Or with a `Dockerfile`:

```json
{
  "schemaVersion": 2,
  "dockerfilePath": "./Dockerfile"
}
```

## Data & config layout

On the host:

- `/captain/` — **the sacred directory.** Contains everything CapRover needs to reconstruct state:
  - `data/` — app configs, captain-definition hashes, SSL certs
  - `generated/` — built Docker images metadata, nginx configs
  - `temp/` — build artifacts (can be cleaned)
- `/var/run/docker.sock` — bind-mounted in, gives CapRover control of Swarm

Your app's persistent data lives in named Docker volumes CapRover manages (configure per-app in dashboard → "Persistent Directories").

## Backup

```sh
# Stop CapRover briefly, archive /captain, restart:
docker stop caprover
sudo tar czf caprover-backup-$(date +%F).tgz -C / captain
docker start caprover

# Or the built-in snapshot tool (dashboard → Cluster → Create Backup)
# produces a tarball you can move to another host and restore with
# the restore flag on the caprover/caprover image.
```

The dashboard's backup is the supported path — it produces a tar that can be `caprover/caprover --caproverConfig=restore` on a new server.

## Upgrade

1. Releases: <https://github.com/caprover/caprover/releases>.
2. Dashboard → Settings → "Check for Updates" → one-click update.
3. Or manually: `docker pull caprover/caprover && docker stop caprover && docker rm caprover && <re-run the docker run command with same args>` (the `/captain` volume persists state).
4. Upgrade Docker engine separately (CapRover requires 25+; newer is fine).
5. Upgrade individual one-click apps via the dashboard — each app shows a version + Upgrade button if the one-click template published a new version.

## Gotchas

- **Default password `captain42` is well-known.** First action after port 3000 is reachable: change it via `caprover serversetup` or dashboard.
- **Snap Docker is broken for CapRover.** Upstream explicitly says: *"AVOID snap installation — snap installation of Docker is buggy."* Use `apt install docker-ce` from Docker's repo or the `get.docker.com` script.
- **Port mappings cannot be changed.** CapRover is hardcoded to 80/443/3000. If port 80 is occupied, CapRover will error on startup; if 3000 is exposed publicly, your dashboard is reachable by anyone (post-setup, this becomes `captain.root-domain` via nginx, but during bootstrap port 3000 is direct).
- **Cloudflare proxy mode breaks CapRover's DNS verification.** The docs are explicit: *"CapRover does not officially support such use cases."* Set Cloudflare DNS records to "DNS only" (grey cloud), not "Proxied" (orange cloud). Or use Cloudflare Tunnels outside of CapRover.
- **Wildcard DNS must be A records.** CNAME wildcards are often unreliable (DNS spec limitation); stick with A records pointing to the server IP. If you renumber, every app follows — but a pool of floating IPs with LB in front is a valid alternative.
- **512 MB RAM is not enough.** Build processes (especially Node/webpack apps) OOM with half a GB. 1 GB is the practical minimum; 2 GB for serious use.
- **Self-building apps use the server's CPU/RAM.** If you `caprover deploy` a large Rails app, CapRover's build consumes the same server running your existing apps. For bigger deployments, use CI (GitHub Actions) to build the Docker image externally, then deploy via image name.
- **One-click apps from the Apps tab are community-maintained.** <https://github.com/caprover/one-click-apps> — review the YAML before clicking install. Bad config in a one-click app = bad config in your stack.
- **Docker Swarm is in maintenance mode.** Docker has de-emphasized Swarm in favor of Kubernetes. CapRover depends on Swarm heavily; the risk of Swarm EOL is real but has not materialized as of 2025. Consider this in long-term planning.
- **HTTPS is not optional for production.** CapRover expects TLS. If you disable forced HTTPS, the dashboard warns you on every login.
- **`/captain/` is the single point of state.** Lose it, lose every app config + cert + one-click-install memory. Back it up often; a nightly tar is sufficient.
- **Multi-node Swarm setup requires identical Docker versions.** Adding a node via Cluster tab: the node must have Docker 25+ and be reachable on Swarm overlay ports (2377, 7946, 4789) from the manager.
- **NetData dashboard** runs alongside CapRover on port 19999 (by default internal); exposed via `monitor.<root-domain>` after initial setup. Don't expose publicly without auth.
- **CapRover CLI is the "power user" path.** Everything in the dashboard can be scripted via the CLI; CI/CD integrations should use `caprover deploy --caproverUrl ... --caproverPassword ... --appName ...` with a deploy token.
- **`captain-definition` is a JSON file, not YAML.** Lives at repo root. Version `schemaVersion: 2` is current.
- **Service restart is fast but not instant.** On new deploy, CapRover does rolling update via Swarm; downtime is seconds, not zero. Multi-instance + healthcheck avoids noticeable downtime.

## Links

- Repo: <https://github.com/caprover/caprover>
- Website + docs: <https://caprover.com/>
- Getting started: <https://caprover.com/docs/get-started.html>
- CLI commands: <https://caprover.com/docs/cli-commands.html>
- captain-definition: <https://caprover.com/docs/captain-definition-file.html>
- Deployment methods: <https://caprover.com/docs/deployment-methods.html>
- One-click apps: <https://github.com/caprover/one-click-apps>
- Firewall guide: <https://caprover.com/docs/firewall.html>
- Releases: <https://github.com/caprover/caprover/releases>
- Docker Hub: <https://hub.docker.com/r/caprover/caprover>
