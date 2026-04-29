---
name: dokku-project
description: Dokku recipe for open-forge. MIT-licensed Docker-powered mini-Heroku — "the smallest PaaS implementation you've ever seen." git-push-to-deploy for any Buildpack / Dockerfile / docker-compose app on a single VPS. Runs on Ubuntu 22.04/24.04 or Debian 11+, installed via bootstrap.sh. Includes plugins for Postgres, MySQL, Redis, MongoDB, Let's Encrypt, reverse-proxy backends (nginx / traefik / Caddy / HAProxy), scheduled jobs, review apps, and 50+ community plugins. Contrasts with Dokploy (web UI / Swarm) and Coolify — Dokku is SSH/CLI-first, single-host, rock stable.
---

# Dokku

MIT-licensed Docker-powered mini-Heroku. Upstream: <https://github.com/dokku/dokku>. Docs: <https://dokku.com/docs/>.

> *Dokku: Docker powered mini-Heroku. The smallest PaaS implementation you've ever seen.*

Install on a fresh VPS → `git push dokku main` → your app builds, deploys, and gets a URL with TLS. Use Heroku Buildpacks (auto-detect language) OR a Dockerfile OR `docker-compose.yml`. Add Postgres with one command. Get a `*.example.com` subdomain for every app automatically.

## What makes Dokku distinctive

vs. **Dokploy / Coolify** — Dokku is **SSH/CLI-first**, not web-UI-first. No admin panel. You manage everything via the `dokku` command over SSH. Trade-off: less friendly for non-devs, more scriptable for devs.

vs. **Heroku** (the real one) — Dokku is self-hosted, single-host, no HA, no autoscaling (without extra work), and way cheaper. No managed services SLAs.

vs. **Kubernetes / K3s** — Dokku is way simpler. Single-node by default. "Just works" on a $5 VPS.

vs. **CapRover** — similar space. CapRover has a web UI; Dokku is CLI. Both are excellent.

## Features

- **Buildpacks** (Heroku, Cloud Native Buildpacks/paketo, Herokuish) — auto-detect language and build.
- **Dockerfile** — bring your own image recipe.
- **docker-compose.yml** — multi-container apps.
- **Plugins** — official + community. Databases (Postgres, MySQL, MariaDB, MongoDB, Redis, Elasticsearch, Memcached, Rabbitmq, Meilisearch, etc.), TLS (Let's Encrypt), proxies (nginx default, also traefik, Caddy, HAProxy), scheduled tasks, review apps, etc.
- **Scaling** — `dokku ps:scale web=3 worker=2`. Single-host only by default; multi-host via the [Dokku Pro](https://pro.dokku.com) commercial plan or manual orchestration.
- **Zero-downtime deploys** via the zero-downtime checks plugin.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| `bootstrap.sh` one-liner | <https://dokku.com/install/> | ✅ Recommended | Fresh Ubuntu 22.04/24.04 or Debian 11+. 99% of users. |
| `apt` / `dnf` package | <https://packagecloud.io/dokku/dokku> | ✅ | If you want distro-style install without `curl | bash`. |
| Arch Linux AUR | <https://aur.archlinux.org/packages/dokku> | ⚠️ Community | Arch users. |
| Unattended install | <https://dokku.com/docs/getting-started/install/debian/#unattended-installation> | ✅ | Cloud-init / CI provisioning. |
| Vagrant / VMs | <https://dokku.com/docs/getting-started/install/vagrant/> | ✅ | Local testing. |
| Dokku Pro (commercial) | <https://pro.dokku.com> | ✅ | Paid add-on with web UI, multi-host, advanced features. |

## Prerequisites (from upstream)

- **Fresh VM** running one of:
  - Ubuntu 22.04 / 24.04 (amd64 / arm64)
  - Debian 11+ (amd64 / arm64)
- **SSH keypair** you can deploy from (imported on install OR added later via `dokku ssh-keys:add`).
- **Minimum 1 GB RAM** (1-2 small apps). **2+ GB recommended** for real use. Buildpack-based apps can spike RAM during build.
- **Public IP + domain** (for Let's Encrypt). Can use `nip.io` / `sslip.io` for testing without DNS.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Is this a FRESH Ubuntu 22.04/24.04 or Debian 11+ VM?" | Boolean, required | Dokku installs a bunch of system stuff (Docker, nginx, plugins). Don't install on a host with competing services. |
| preflight | "Installing latest stable release version?" | Default: latest, OR specify a pinned version | Upstream's install URL pattern: `https://dokku.com/install/v<version>/bootstrap.sh` |
| dns | "Global domain?" | Free-text, e.g. `example.com` | Apps become `<app>.example.com`. Set via `dokku domains:set-global example.com`. Without wildcard DNS, each app needs its own domain. |
| dns | "Wildcard DNS configured?" | Boolean | `*.example.com → <server-IP>` enables instant per-app subdomains. Without it, set per-app domains manually. |
| admin | "SSH public key to add for deploys?" | File path or paste | Added via `dokku ssh-keys:add <name> <file>`. This keypair becomes the "git push" user. |
| proxy | "Reverse proxy backend?" | `AskUserQuestion`: `nginx (default)` / `traefik` / `caddy` / `haproxy` / `openresty` | Default `nginx` is fine. Traefik / Caddy have nicer cert automation for some use cases. |
| tls | "Let's Encrypt email?" | Free-text | Required for automatic Let's Encrypt cert issuance via `dokku-letsencrypt`. |

## Install — bootstrap.sh

Pin a specific version (check <https://github.com/dokku/dokku/releases> for current stable):

```bash
# On a fresh Ubuntu 22.04 / Debian 12 VM, as root or a sudoer:
wget -NP . https://dokku.com/install/v0.37.10/bootstrap.sh
sudo DOKKU_TAG=v0.37.10 bash bootstrap.sh
```

The script installs:

- Docker (via Docker's official install script)
- Dokku's own APT repo + the `dokku` package
- Default plugins: `letsencrypt`, `postgres`, etc. (actually: most plugins are installed-on-demand; see <https://dokku.com/docs/community/plugins/> for the core list)
- nginx (or whichever proxy you pick)

## Post-install setup

```bash
# 1. Set the global domain (apps get <app>.example.com)
sudo dokku domains:set-global example.com

# 2. Add your SSH public key (you'll use this to git push)
cat ~/.ssh/id_ed25519.pub | ssh root@dokku-host 'dokku ssh-keys:add admin'

# 3. Install a database plugin (e.g. Postgres)
sudo dokku plugin:install https://github.com/dokku/dokku-postgres.git postgres

# 4. Install Let's Encrypt plugin
sudo dokku plugin:install https://github.com/dokku/dokku-letsencrypt.git
sudo dokku letsencrypt:set --global email admin@example.com
sudo dokku letsencrypt:cron-job --add
```

## Deploying your first app

```bash
# On your LOCAL machine:
cd my-app/
git init
git add .
git commit -m "initial"

# Add dokku as a remote (on the server side, no app creation needed first — 
# git push triggers creation)
git remote add dokku dokku@dokku-host:my-app
git push dokku main
```

Dokku detects the language (Procfile + requirements.txt / package.json / Gemfile / pom.xml / etc.), builds via buildpack, deploys, and prints:

```
=====> Application deployed: https://my-app.example.com
```

### Add a database

```bash
# Server side:
sudo dokku postgres:create my-app-db
sudo dokku postgres:link my-app-db my-app
# This sets DATABASE_URL as an env var on my-app and restarts it
```

### Enable HTTPS

```bash
sudo dokku letsencrypt:enable my-app
# Issues cert, configures nginx for HTTPS, enables auto-renewal via the cron job
```

## Deploying with Docker / docker-compose

**Dockerfile:**

```bash
# If your repo has a Dockerfile, Dokku uses it instead of buildpacks:
git push dokku main    # Detects Dockerfile, builds + runs
```

**docker-compose.yml:**

```bash
# Requires the "app-json" plugin convention. See https://dokku.com/docs/deployment/builders/dockerfiles/
# OR deploy via `dokku apps:create` + `dokku git:from-image` for a pre-built image
```

## Scaling

```bash
sudo dokku ps:scale my-app web=2           # 2 web instances
sudo dokku ps:scale my-app web=2 worker=1  # 2 web + 1 worker (defined in Procfile)
sudo dokku ps:restart my-app
sudo dokku ps:stop my-app
sudo dokku ps:start my-app
```

Single-host only — scaling means multiple containers on the same host, routed by the proxy.

## Environment variables

```bash
sudo dokku config:set my-app KEY=value ANOTHER=thing
sudo dokku config:get my-app KEY
sudo dokku config:unset my-app KEY
```

## Upgrade procedure

Upstream's upgrade docs: <https://dokku.com/docs/getting-started/upgrading/>.

```bash
# Check current version
dokku version

# Upgrade the Dokku package
sudo apt update
sudo apt install dokku

# Upgrade plugins (separately managed)
sudo dokku plugin:update
```

**Major version upgrades** (e.g. 0.30 → 0.37) may deprecate commands or require data migration for specific plugins. Read release notes: <https://github.com/dokku/dokku/releases>.

## Data layout

| Path | Content |
|---|---|
| `/home/dokku/` | Per-app git repos + cached state |
| `/home/dokku/<app>/` | App config, Procfile-defined worker counts, custom nginx includes |
| `/var/lib/dokku/data/storage/` | Mounted volumes for apps (if using `dokku storage:mount`) |
| `/var/lib/dokku/services/<plugin>/<service-name>/data/` | Plugin-managed services (e.g. `/var/lib/dokku/services/postgres/mydb/data/`) |
| `/etc/nginx/conf.d/` | Generated nginx includes per-app |
| `/etc/ssl/certs/` + Let's Encrypt's own dirs | TLS certs |
| `~/.dokkurc` (root) | Dokku runtime config |

**Backup** = tar `/home/dokku/` + `/var/lib/dokku/` + `/etc/nginx/` while apps are stopped. Or use per-plugin backup:

```bash
sudo dokku postgres:export my-app-db > my-app-db-$(date +%F).sql
```

## Gotchas

- **"Fresh VM" means fresh.** Installing Dokku on a host with existing services is asking for conflicts (nginx ports, Docker daemon settings, SSH authorized_keys manipulation). Use a dedicated VM.
- **Single-host by default = no HA.** If the VPS dies, all apps are down. For HA, use Dokku Pro's multi-host feature, or manually replicate across multiple Dokku hosts behind a load balancer.
- **git push auth is via SSH keys only.** No password auth. Lose your private key = can't deploy until you SSH in via a different key and re-add.
- **`dokku` command needs `sudo` on older versions** when run from a non-dokku user; on newer versions (0.30+) you can run as the deploy user via SSH. Docs cover both patterns.
- **Buildpack builds are slow the first time** (minutes). Subsequent deploys cached. Buildpack cache lives on the host — disk can fill up over time. `dokku cleanup` or periodic prune.
- **Default nginx proxy is fine for most.** If you switch to Traefik or Caddy proxy backend AFTER deploying apps, each app needs to be reconfigured — don't switch casually.
- **Let's Encrypt rate limits.** 50 certs/week/domain. If you have many apps on many subdomains, you can hit this during mass deploys. Use the staging env first (`dokku letsencrypt:set my-app dokku-letsencrypt-server https://acme-staging-v02.api.letsencrypt.org/directory`).
- **No rolling deploys by default.** `git push` → old container stops, new one starts. There's a gap. Install the `zero-downtime-checks` plugin for rolling deploys with HTTP healthchecks.
- **Plugins are 3rd-party code running as root on your host.** Read the code of community plugins before installing. Official plugins (github.com/dokku/*) are maintained by the team; community ones vary.
- **`dokku-postgres` is NOT a production-grade Postgres.** It's a single container with data in a volume. For critical data, use managed Postgres (RDS / Neon / Cloud SQL) and set `DATABASE_URL` manually.
- **`docker-compose.yml` deploys** require the project to be set up in specific ways — simpler to just commit a Dockerfile if possible.
- **Procfile + buildpacks only parse `Procfile` — not `Procfile.dev` or other variants.** Typos in process types (e.g. `web:` vs `Web:`) cause silent deploy-but-don't-run failures.
- **Apps use the host's Docker daemon.** If Docker's out of space / out of memory, all apps suffer. Monitor Docker disk usage and run `docker system prune` (or `dokku cleanup`) periodically.
- **Logs go to syslog by default.** `dokku logs my-app` tails them. For long-term log storage, ship to ELK / Loki / hosted log service — Dokku itself doesn't archive.
- **Reviewing + reverting.** `dokku git:report my-app` shows deployed SHA. `git push dokku :main && git push dokku <older-sha>:main` rolls back. No first-class rollback button.
- **The first `git push` takes a full rebuild** — Buildpacks download base images + dependencies fresh. ~5-15 min depending on language. Subsequent pushes with cached layers are seconds.
- **Resource limits not enforced by default.** A runaway app can OOM-kill the host. Set per-app: `sudo dokku resource:limit --memory 512M my-app`.
- **Dokku is single-maintainer-team-led.** Jose Diaz-Gonzalez + contributors; very stable, consistent, long-lived. But the pace is "steady" not "racing" — if you need bleeding-edge K8s-style features, look elsewhere.

## Links

- Upstream repo: <https://github.com/dokku/dokku>
- Docs: <https://dokku.com/docs/>
- Getting started: <https://dokku.com/docs/getting-started/installation/>
- Install script: <https://dokku.com/install/>
- Plugins registry: <https://dokku.com/docs/community/plugins/>
- Releases: <https://github.com/dokku/dokku/releases>
- Slack: <https://slack.dokku.com/>
- Dokku Pro (commercial): <https://pro.dokku.com>
- Packagecloud APT repo: <https://packagecloud.io/dokku/dokku>
- Sponsors / donations: <https://opencollective.com/dokku>
