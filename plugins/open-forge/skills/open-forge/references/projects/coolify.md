---
name: coolify-project
description: Coolify recipe for open-forge. Apache-2.0 self-hostable Heroku/Netlify/Vercel alternative — a web UI that orchestrates Docker / Docker-Compose deploys of your apps + databases, connects to Git (GitHub/GitLab/Bitbucket/Gitea) for CI, manages SSL via Traefik/Caddy, runs on any Linux VM. Single install command: `curl ...install.sh | bash`. This recipe covers the official install.sh (upstream-blessed), self-update semantics, server-addition model (Coolify manages remote servers over SSH), and the footguns around running Coolify itself on the same box it orchestrates.
---

# Coolify

Apache-2.0 self-hosted platform-as-a-service. Web UI that orchestrates Docker + Docker-Compose app deploys, databases, services, Git-triggered CI, TLS via Traefik/Caddy. Upstream: <https://github.com/coollabsio/coolify>. Docs: <https://coolify.io/docs/>.

Think Heroku/Vercel/Netlify, but self-hosted on your own VMs. Coolify is a Laravel app + Horizon queue + Postgres + Redis + Soketi (realtime) that manages deploys on target "servers" (either localhost or remote hosts via SSH).

## What you're deploying

The installer writes a stack under `/data/coolify/`:

- **coolify** — main Laravel app + web UI (Nginx + PHP-FPM container)
- **coolify-db** — Postgres (Coolify's own DB, not user app DBs)
- **coolify-redis** — cache/queue
- **coolify-proxy** — Traefik v3 (manages ingress + Let's Encrypt for user apps)
- **coolify-realtime** — Soketi (websocket UI updates)

Default UI port `:8000` (or your custom `COOLIFY_FQDN` + Traefik auto-TLS). SSH port for orchestration: `:22` (Coolify adds itself to `authorized_keys`).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Install script (`cdn.coollabs.io/coolify/install.sh`) | <https://coolify.io/docs/installation> · source: `scripts/install.sh` on `main` | ✅ ONLY supported method | The upstream-blessed path. Writes to `/data/coolify/`, sets up Docker if missing. |
| Manual Docker run | Not documented upstream | ❌ Not supported | Upstream explicitly directs users to the install script. |

**Upstream docs call out install.sh as the only way** — there is no "Helm chart" or "manual Docker Compose" path that upstream supports. The install script IS the install.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Target OS?" | Free-text | Officially supported: Debian 11/12, Ubuntu 20.04/22.04/24.04, CentOS 8+, Fedora 36+, Raspberry Pi OS 64-bit, Rocky Linux 8/9, Arch, Alma Linux 8/9. Script uses `/etc/os-release` for detection. |
| preflight | "VM specs?" | Free-text | Upstream minimum: 2 CPU + 2 GB RAM + 30 GB disk. Add headroom for user apps running on the same host. |
| dns | "FQDN for the Coolify UI?" | Free-text (e.g. `coolify.example.com`) | Set post-install via Settings → Global Settings → Instance's Domain. Auto-TLS via Traefik. |
| admin | "Root user email + password?" | Free-text (sensitive) | Can be preset via `ROOT_USERNAME` / `ROOT_USER_EMAIL` / `ROOT_USER_PASSWORD` env vars at install time; otherwise set via first-run web flow. |
| registry | "Custom Docker registry?" | Free-text | `REGISTRY_URL` env var at install. Default `ghcr.io`. |
| network | "Custom Docker address pool?" | Free-text | `DOCKER_ADDRESS_POOL_BASE` / `DOCKER_ADDRESS_POOL_SIZE`. Only needed if default `10.0.0.0/8` clashes with your internal network. |
| autoupdate | "Disable auto-updates?" | Boolean → `AUTOUPDATE=false` | Coolify ships an auto-updater by default. |

## Install — upstream one-liner

```bash
# MUST run as root (installer exits if EUID != 0)
# Review the script first — it installs Docker and writes to /data/coolify/
curl -fsSL https://cdn.coollabs.io/coolify/install.sh -o /tmp/coolify-install.sh
less /tmp/coolify-install.sh   # audit
sudo bash /tmp/coolify-install.sh
```

Or the truly one-liner flavour (the docs' official form):

```bash
curl -fsSL https://cdn.coollabs.io/coolify/install.sh | sudo bash
```

### Pre-seeding admin + config via env vars

```bash
sudo \
  ROOT_USERNAME="admin" \
  ROOT_USER_EMAIL="admin@example.com" \
  ROOT_USER_PASSWORD="$(openssl rand -hex 16)" \
  AUTOUPDATE="false" \
  bash /tmp/coolify-install.sh
```

### What the installer does

1. Detects OS from `/etc/os-release`. Bails on unsupported distros.
2. Installs Docker if missing (uses upstream Docker packages, NOT the distro's).
3. Configures Docker's `daemon.json` address pool.
4. Creates `/data/coolify/` with `source/` (compose) + `ssh/` (SSH keys) + `applications/` + `databases/` + `services/` subdirs.
5. Downloads `docker-compose.yml` + `.env` from CDN.
6. Generates random secrets and backfills into `.env`.
7. Runs `docker compose up -d` from `/data/coolify/source/`.
8. Installs systemd unit + cron job for auto-update.
9. Prints the UI URL.

### Post-install first-run

Visit `http://<host-ip>:8000` (or your FQDN if DNS is configured). Register the first admin account (this becomes the root user) — or log in with the credentials you pre-seeded. Coolify then drops into the dashboard.

Key post-install tasks:

1. **Settings → Global Settings**: set Instance's Domain, toggle auto-update, configure SMTP for transactional emails.
2. **Sources**: connect GitHub/GitLab/Bitbucket/Gitea (OAuth flow — Coolify registers a GitHub App on first connect).
3. **Servers**: your install host shows up as "localhost" by default. Add remote servers via SSH (Coolify generates an SSH key and you paste the public key into `authorized_keys` on the remote).
4. **Projects** → **Resources**: deploy apps/databases/services.

## Upgrade procedure

Coolify auto-updates by default via a systemd timer. To trigger manually:

- **Web UI**: Settings → Global Settings → Update → click "Update Instance."
- **CLI**:
  ```bash
  cd /data/coolify/source
  bash upgrade.sh
  ```

If auto-update is on and you want to pin a version, set `AUTOUPDATE=false` in `/data/coolify/source/.env` and restart the stack.

**Backup before upgrading.** `/data/coolify/source/.env` holds generated secrets that MUST survive the upgrade. Back up:

```bash
sudo tar -czf /root/coolify-config-$(date +%F).tar.gz /data/coolify/source/.env
# Plus the Postgres DB:
docker exec coolify-db pg_dumpall -U coolify > /root/coolify-db-$(date +%F).sql
```

## Data layout

| Path | Content |
|---|---|
| `/data/coolify/source/` | Compose file + `.env` + install scripts. Source of truth for the Coolify stack itself. |
| `/data/coolify/ssh/` | SSH keys Coolify uses to connect to managed remote servers. |
| `/data/coolify/applications/` | Per-app source clones + build context. |
| `/data/coolify/databases/` | Persistent volumes for user databases Coolify provisions. |
| `/data/coolify/services/` | Persistent volumes for one-click services. |
| `/data/coolify/proxy/` | Traefik dynamic config + `acme.json` (Let's Encrypt certs). |
| `/data/coolify/webhooks-during-maintenance/` | Buffered webhook deliveries during upgrades. |

## Server-addition model

Coolify manages multiple "servers" from one Coolify install. The Coolify host is one server (localhost); remote servers are added by:

1. Settings → Servers → Add New Server
2. Paste hostname + IP + user (usually `root`).
3. Coolify shows the public key from `/data/coolify/ssh/keys/<hash>.pub` — paste it into the remote's `/root/.ssh/authorized_keys`.
4. Coolify connects, installs its CLI helper on the remote, spins up Traefik on the remote.

Remote servers don't need a Coolify install — just Docker + SSH + the helper script (Coolify installs this automatically).

## Gotchas

- **MUST run install as root.** The script `exit`s if `$EUID != 0`. Use `sudo bash` even inside an already-root shell; `sudo` ensures env + path.
- **Ports 80, 443, 8000, 6001, 6002 must be free.** Traefik binds 80/443 for apps, Coolify UI on 8000, Soketi on 6001/6002. If anything else holds these, the stack boot-loops.
- **Ports 22 + SSH keys.** Coolify adds its own public key to `authorized_keys` of the root user. If you use key-only SSH with a locked-down `authorized_keys`, be aware Coolify manages entries here.
- **Docker address pool `10.0.0.0/8` default.** Clashes with many corporate VPN networks. Override `DOCKER_ADDRESS_POOL_BASE` at install time. Changing it later requires restarting Docker + recreating all containers.
- **Auto-update can break things.** The default is ON. If you're running production workloads on Coolify, turn auto-update OFF (`AUTOUPDATE=false`) and upgrade manually after reading release notes.
- **Self-hosting Coolify on the SAME box it orchestrates = single-point-of-failure.** If you nuke a deploy or run out of disk, the Coolify UI goes down with it. For production, the common pattern is Coolify on a small dedicated VM + managed apps on larger target servers.
- **GitHub App registration is per-domain.** If you rename Coolify's FQDN later, the GitHub webhook URLs break. Re-create the source connection.
- **Backups of user databases are an opt-in feature.** Coolify can schedule backups to S3-compatible storage per-DB. If you don't configure this, your app's Postgres/MySQL volumes are only as safe as the host disk.
- **Paid Pro features.** Coolify Core is AGPL/Apache (open-source, all features free). Coolify Cloud is a paid hosted version. Some "enterprise" features (SSO, audit logs at scale) may move behind a paywall in the future — check the license of any new feature you rely on.
- **Log storage can balloon.** Build logs for every deploy live under `/data/coolify/`. Prune old projects or mount `/data/coolify/` on a separate disk with headroom.
- **Traefik config lives in files, not a database.** If Traefik's config gets corrupted, `/data/coolify/proxy/` holds the state — delete the dynamic config and Coolify will regenerate on the next sync.
- **Arm64 works but not all user app images do.** Coolify itself has arm64 images (Raspberry Pi 4/5 supported). If you deploy an app whose image is amd64-only, builds fail with a helpful error.
- **No native Kubernetes target.** Coolify only orchestrates Docker / Docker Compose. If the user needs K8s, it's the wrong tool.

## Links

- Upstream repo: <https://github.com/coollabsio/coolify>
- Docs: <https://coolify.io/docs/>
- Install guide: <https://coolify.io/docs/installation>
- Install script source: <https://github.com/coollabsio/coolify/blob/main/scripts/install.sh>
- Admin of servers: <https://coolify.io/docs/knowledge-base/server/add-new-server>
- Resources overview: <https://coolify.io/docs/resources/introduction>
- Upgrade docs: <https://coolify.io/docs/knowledge-base/upgrade>
- Discord: <https://coollabs.io/discord>
- Releases: <https://github.com/coollabsio/coolify/releases>
