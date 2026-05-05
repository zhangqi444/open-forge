---
name: Runtipi
description: "One-command homeserver manager with a simple web UI and one-click app store — install and manage self-hosted apps on your server without touching Docker or config files. Shell/TypeScript. GPL-3.0."
---

# Runtipi (Tipi)

Runtipi is a personal homeserver orchestrator that makes running self-hosted apps easy. Install Runtipi with a single command, then use its web UI to discover and install apps from an app store — no Docker knowledge, no manual config file editing required.

Maintained by a volunteer community. Active development; v4.x series.

Use cases: (a) non-technical users who want to self-host without learning Docker (b) home lab operators who want a GUI for managing many apps (c) Raspberry Pi or cheap VPS homeserver management (d) quick evaluation of self-hosted apps before committing to manual setup.

Features:

- **One-command install** — single shell script sets up the entire system
- **App store** — browse and install 200+ popular self-hosted apps (Nextcloud, Jellyfin, Immich, Vaultwarden, etc.)
- **Web UI** — manage all installed apps; start/stop/restart; view logs
- **Custom app stores** — add third-party or personal app stores
- **Docker-based** — all apps run as Docker containers; Runtipi manages compose files
- **Automatic updates** — update apps from the UI
- **Reverse proxy** — built-in Traefik; automatic subdomain routing per app
- **SSL** — automatic Let's Encrypt certificates via Traefik
- **User management** — single-user or multi-user setup
- **App settings** — configure apps through UI forms (no manual env file editing)

- Upstream repo: https://github.com/runtipi/runtipi
- Homepage: https://runtipi.io/
- Docs: https://runtipi.io/docs/introduction
- App store repo: https://github.com/runtipi/runtipi-appstore
- Demo: https://demo.runtipi.io (user@runtipi.io / password)

## Architecture

- **Runtipi core** — TypeScript (NestJS backend + React frontend)
- **Docker** — all apps run as containers managed by Runtipi
- **Traefik** — reverse proxy; automatic SSL + subdomain routing
- **PostgreSQL** — Runtipi's own state database
- **Redis** — used internally by Runtipi
- Runtipi itself runs as Docker containers (meta-level)

## System requirements

- Linux (Ubuntu 20.04+ / Debian 11+ / Fedora 38+ recommended)
- Docker installed and running
- 2 GB RAM minimum (4 GB+ recommended with apps)
- 10 GB free disk space minimum
- 64-bit system (ARM64 supported for Raspberry Pi)

## Install

```sh
curl -fsSL https://setup.runtipi.io | sudo bash
```

This downloads and runs the Runtipi setup script, which:
1. Installs Docker if not present
2. Pulls Runtipi Docker images
3. Starts Runtipi on port 80 (HTTP) and 443 (HTTPS)

Open `http://your-server-ip` to complete initial setup.

See https://runtipi.io/docs/getting-started/installation for full instructions.

## Post-install setup

1. Create admin account on first visit
2. Set your domain name (required for SSL and app subdomains)
3. Browse the App Store → find an app → click Install
4. Fill in any required settings (e.g., admin email for Nextcloud)
5. App is installed and accessible at `appname.yourdomain.com`

## App management

```
# Update all apps
→ Dashboard → Updates available → Update All

# View app logs
→ App → Logs tab

# Stop/start an app
→ App → Stop / Start button

# Change app settings
→ App → Settings tab → modify → Save & Restart
```

## Custom app stores

Add a custom app store URL in Settings → App Stores. Format follows the runtipi-appstore spec. Community app stores list: https://runtipi.io/docs/guides/custom-app-store

## Data layout

- **`/runtipi/`** — default installation directory (created by installer)
  - `apps/` — installed app data and compose overrides
  - `app-data/` — persistent app data volumes
  - `logs/` — Runtipi and app logs
  - `traefik/` — Traefik config and certs

## Upgrade Runtipi

```sh
cd /runtipi
sudo ./runtipi-cli update
```

## Gotchas

- **Port 80/443 must be available** — Runtipi uses Traefik on ports 80 and 443. If another web server (nginx, Apache) is running, either stop it or reconfigure Runtipi's ports. Conflicts are a common first-run issue.
- **Domain required for SSL and app subdomains** — without a domain, apps are accessible by IP + port only. SSL and subdomain routing require a domain with DNS pointing to your server.
- **Raspberry Pi: 64-bit OS required** — Runtipi requires a 64-bit OS (Ubuntu 22.04 64-bit for Pi). 32-bit Raspberry Pi OS is not supported.
- **Not all app settings are exposed via UI** — Runtipi exposes common settings per app in its UI. Advanced configurations may require editing the app's Docker env file manually in `/runtipi/apps/<app>/`.
- **App store updates are community-maintained** — apps in the official store are kept reasonably up to date but may lag behind upstream releases. Check the app's own update frequency.
- **Resource contention** — running many apps on a single machine is easy with Runtipi but watch your RAM and CPU. 10 apps on 2 GB RAM will struggle; plan capacity.
- **Compared to Portainer** — Portainer gives you full Docker management (more powerful). Runtipi gives you a simpler, opinionated experience (easier). Portainer for power users; Runtipi for simplicity.
- **Alternatives:** Portainer (full Docker management), Umbrel (similar concept, different app store), CasaOS (similar, Chinese-developed), Yunohost (Debian-based, app packaging system), HomelabOS, manual Docker Compose.

## Links

- Repo: https://github.com/runtipi/runtipi
- Homepage: https://runtipi.io/
- Documentation: https://runtipi.io/docs/introduction
- App store: https://github.com/runtipi/runtipi-appstore
- Community forum: https://forums.runtipi.io/
- Discord: https://discord.gg/Bu9qEPnHsc
- Demo: https://demo.runtipi.io
