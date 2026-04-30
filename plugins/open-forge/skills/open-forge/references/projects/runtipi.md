---
name: Runtipi
description: "Personal homeserver orchestrator — Docker-based app-store UI for installing 200+ self-hosted apps with one click. Handles networking, reverse proxy (Traefik), TLS, backups. Built for hobbyists without DevOps experience. Node/TypeScript/NestJS/React. GPL-3.0."
---

# Runtipi

Runtipi is a "personal homeserver in a box" — a web UI that makes installing and managing self-hosted apps on a Linux machine feel like an iPhone App Store. Instead of writing docker-compose files, you browse the Runtipi App Store, click "Install" on Nextcloud (or Immich, Home Assistant, Jellyfin, Paperless-ngx, Vaultwarden, 200+ others), fill in a few config fields, and Runtipi orchestrates the Docker containers + Traefik reverse proxy + TLS + networking for you.

Target audience: hobbyists with a home server or Pi who want self-hosted apps but don't want to become DevOps engineers.

**⚠️ Status warning** (from upstream README): "Runtipi is built and maintained by volunteers. There is no guarantee of support or security when you use Runtipi. While the system is considered stable, it is still in active development and may contain bugs."

Core features:

- **One-click app install** from official App Store (200+ apps)
- **Community App Stores** — add third-party catalogs
- **Automatic Traefik routing** — subdomain or path-based; LE certs handled
- **Local HTTPS** via mkcert (for `*.tipi.local`)
- **Backups** — manual + scheduled; per-app
- **Updates** — one-click app updates + Runtipi itself
- **User management** — multi-user with roles
- **2FA (TOTP)** — for Runtipi login
- **CLI** — manage via shell if you prefer
- **Docker / Docker Compose based** — understandable under the hood

- Upstream repo: <https://github.com/runtipi/runtipi>
- Official App Store: <https://github.com/runtipi/runtipi-appstore>
- Website: <https://www.runtipi.io>
- Docs: <https://www.runtipi.io/docs/introduction>
- Forum: <https://forums.runtipi.io>
- Discord: <https://discord.gg/Bu9qEPnHsc>
- Demo: <https://demo.runtipi.io> (user `user@runtipi.io` / password `password`)

## Architecture in one minute

- **Runtipi CLI** (Node/TS/NestJS) — orchestrates Docker and manages apps
- **Traefik** — reverse proxy in front of all apps; routes by hostname
- **App Store** — git repo of YAML + compose definitions; cloned + pulled on updates
- **SQLite** — Runtipi's own state (users, installed apps, backups)
- **Docker Compose** under the hood — Runtipi writes compose files + calls docker
- **Host-level installation** — not a Docker container; runs directly on the host to manage Docker

Target OS: Ubuntu 22.04+, Debian 12+ (primary); other Linux distros usually OK.

## Compatible install methods

| Infra       | Runtime                                       | Notes                                                            |
| ----------- | --------------------------------------------- | ---------------------------------------------------------------- |
| Single VM   | **Host install script** (Linux)                  | **The way** — `curl -L ... \| bash`                                 |
| Raspberry Pi | Official Pi images / script                       | Pi 4 (4 GB+) recommended                                              |
| NAS         | Synology/QNAP via SSH                                | Supported but needs Docker enabled                                        |
| Bare metal  | Ubuntu/Debian native                                  | The upstream-recommended path                                                |

## Inputs to collect

| Input              | Example                           | Phase     | Notes                                                             |
| ------------------ | --------------------------------- | --------- | ----------------------------------------------------------------- |
| Server IP / domain  | `192.168.1.50` / `tipi.example.com` | DNS       | Public access needs public DNS + port 80/443 forwarded                   |
| Local TLD          | `*.tipi.local` (default)            | DNS       | Runtipi generates self-signed CA for local HTTPS                                 |
| Public domain (opt) | `apps.example.com`                   | DNS       | For external access + Let's Encrypt                                                 |
| Admin user         | first-run wizard                     | Bootstrap | Local account or SSO                                                                         |
| Reverse proxy      | embedded Traefik                      | Network   | Managed by Runtipi                                                                                 |
| Data dir           | `/var/lib/runtipi` (default)           | Storage   | All app data lives under here                                                                                  |

## Install

On a fresh Ubuntu 22.04+ or Debian 12+ VM:

```sh
curl -L https://setup.runtipi.io | sudo bash
```

**Read the script** (<https://setup.runtipi.io>) before piping to root bash. It:

1. Installs Docker + Docker Compose plugin
2. Clones `runtipi` repo into `/opt/runtipi`
3. Generates self-signed CA for `*.tipi.local`
4. Starts Runtipi's services

After install, browse `http://<server-ip>` → Runtipi UI → create admin user.

## First use

1. Browse server IP (or `https://tipi.local` if you've set up hostfile/DNS)
2. Create admin account
3. (Optional) Add public domain + Let's Encrypt under Settings → Network
4. App Store → browse → click "Install" on an app
5. App becomes available at `app-name.tipi.local` or `app-name.yourdomain.com`
6. Repeat — Runtipi handles the networking + TLS for each app

## Public access

For external access with Let's Encrypt:

1. **Domain** — point `*.apps.example.com` (wildcard) A record at your server's public IP
2. **Port forwarding** — forward 80 + 443 from your router to the server
3. **Runtipi settings** → set domain + toggle "Use HTTPS"
4. Apps installed after this get `app-name.apps.example.com` with automatic Let's Encrypt

For home-only (LAN) without port forwarding:

- Use Tailscale / ZeroTier / WireGuard to reach the server remotely
- Or skip TLS + use `http://app.tipi.local` on LAN

## Data & config layout

Under `/var/lib/runtipi` (or wherever you installed it):

- `apps/` — installed apps; each with its own subdir + Docker Compose
- `app-data/` — persistent data for each app
- `backups/` — app backups
- `logs/` — Runtipi + Traefik logs
- `traefik/` — Traefik config + ACME certs
- `state/` — Runtipi's SQLite + state JSON

## Backup

```sh
# Everything: shut down Runtipi, rsync /var/lib/runtipi to backup target
sudo ./runtipi-cli stop
sudo rsync -aAXv /var/lib/runtipi/ /backups/runtipi-$(date +%F)/
sudo ./runtipi-cli start

# Or per-app backup via Runtipi UI (Settings → Backups)
```

**Some apps** have their own DB (e.g., Nextcloud, Paperless-ngx) — Runtipi's backup captures the raw volume; for consistency, stop the app before backup.

## Upgrade

### Runtipi itself

```sh
cd /opt/runtipi
sudo ./runtipi-cli update
```

### An installed app

UI → Apps → the app → Update button (only appears if an update is available).

### App Store definitions

Auto-pulled periodically. Force refresh via UI.

## Gotchas

- **"No guarantee of support or security"** (upstream warning) — Runtipi is volunteer-maintained. It's stable enough for home use but I wouldn't bet a production-critical service on it without additional backups + monitoring.
- **Host install, not containerized** — Runtipi itself runs on the host. This is deliberate (it needs to run `docker` commands) but means it's more intrusive than a pure-Docker app.
- **Port conflicts** — if your host already runs nginx/Apache/Docker-with-existing-containers, Runtipi's Traefik binding 80/443 will conflict. Either stop existing services or configure Runtipi to use alternate ports.
- **Wildcard DNS simplifies everything** — `*.apps.example.com` A record at your server's IP means every app auto-gets a working hostname. Without it, you need per-app DNS.
- **Let's Encrypt via HTTP-01 challenge** requires port 80 open from the internet. Corporate NAT = use DNS-01 challenge (Cloudflare plugin etc.) — consult docs.
- **App Store apps are YAML-defined** — if an official app you want is missing, you can write a definition yourself or find it in a community store.
- **Community app stores** — add multiple; priority matters. Known community catalogs: "MeienbergerAppStore", various hobby catalogs. Review code before installing random apps.
- **App updates can break** — the App Store pins versions, but when an app maintainer updates their recipe to a new version with a breaking schema change, your data may need migration. Back up before updates.
- **Resource consumption scales with apps** — each app is 1-N containers. 10 apps can easily hit 4-8 GB RAM. Plan host sizing.
- **SSH access is still essential** — Runtipi handles the app layer; host-level tasks (disk monitoring, OS updates, SSH key management, firewall) are still yours.
- **Not a Kubernetes replacement** — for multi-node or HA, use K3s + Helm. Runtipi is single-host.
- **CasaOS, Umbrel, TrueCharts, YunoHost** are competitors — pick the aesthetic/philosophy you like. Runtipi is closer to "Docker-focused + transparent" than Umbrel's more managed approach. YunoHost is Debian-package-centric and supports email more seriously.
- **Backup hygiene**: test restores. An untested backup is a hope, not a backup.
- **Apps behind auth-proxies** (Authelia, Authentik) — possible but requires manual edits to Traefik config; not a first-class feature yet.
- **Runtipi CLI** lives at `/opt/runtipi/runtipi-cli` — `start`, `stop`, `restart`, `update`, `reset-password`, etc.
- **GPL-3.0 license** — copyleft.
- **Alternatives worth knowing:**
  - **CasaOS** — more polished UX; smaller catalog; Go (separate recipe)
  - **Umbrel** — originally Bitcoin-node focused; now general; slick UX (separate recipe)
  - **YunoHost** — Debian-native; email-stack bundled; more sysadmin-oriented
  - **TrueNAS SCALE** — NAS-first; K8s under the hood; heavier
  - **Yacht** — simpler Docker compose UI; no app store
  - **Portainer** — Docker management; not an app store; no Traefik integration
  - **Cosmos Cloud** — newer; fewer apps; bigger feature set
  - **Unraid** — commercial; NAS + apps; popular
  - **Choose Runtipi if:** you want a Docker-transparent app store for a single-host Linux server, with Traefik + TLS automation.
  - **Choose CasaOS if:** you prioritize polish + ease over Linux-native config transparency.
  - **Choose YunoHost if:** you want email + LDAP + apps bundled, Debian-native.
  - **Choose Umbrel if:** you want the most iPhone-like UX + OK with less "power user" flexibility.

## Links

- Repo: <https://github.com/runtipi/runtipi>
- Official App Store: <https://github.com/runtipi/runtipi-appstore>
- Website: <https://www.runtipi.io>
- Docs: <https://www.runtipi.io/docs/introduction>
- Install: <https://www.runtipi.io/docs/getting-started/installation>
- Demo: <https://demo.runtipi.io>
- Forums: <https://forums.runtipi.io>
- Discord: <https://discord.gg/Bu9qEPnHsc>
- Translations: <https://crowdin.com/project/runtipi>
- Gurubase (AI Q&A): <https://gurubase.io/g/tipi>
- Runtipi CLI flags: <https://www.runtipi.io/docs/reference/runtipi-cli>
- Community app stores list: <https://www.runtipi.io/docs/community-app-stores>
- Releases: <https://github.com/runtipi/runtipi/releases>
