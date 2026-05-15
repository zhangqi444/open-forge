---
name: Homer
description: Ultra-lightweight static HTML/JS dashboard for launching self-hosted services. Single YAML file configures cards for your apps, with smart live-status icons for common tools. No backend. Nginx-served static files. Apache-2.0.
---

# Homer

Homer is the original "yaml-driven self-hosted dashboard" — a plain static website (HTML + JS + CSS) that reads a single `config.yml` and renders clickable cards pointing to your services. No backend, no database, no containers-managing-containers. Just a nginx serving static files.

- **YAML-only config** — edit `assets/config.yml`, reload, done
- **Smart cards** for ~30 popular apps (Sonarr, Radarr, Proxmox, Pi-hole, Uptime Kuma, Portainer, Jellyfin, ...) showing live status/stats
- **Themes** — default light/dark + community themes
- **PWA installable** — put on phone home screen
- **Fuzzy search** across all services
- **Multi-page** — organize services into tabs
- **Keyboard shortcuts**
- **i18n** — 15+ languages

- Upstream repo: <https://github.com/bastienwirtz/homer>
- Demo: <https://homer-demo.netlify.app>
- Docker Hub: <https://hub.docker.com/r/b4bz/homer>
- Docs: <https://github.com/bastienwirtz/homer/tree/main/docs>

## Architecture in one minute

- **Static site** — plain nginx serving HTML/JS/CSS
- **Vue.js frontend** (builds to static at image-build time)
- **Single YAML config** mounted at `/www/assets/config.yml`
- **Custom assets** — icons, logos, CSS themes — in the same directory
- **No backend** — "smart cards" poll your services *directly from the browser* (CORS rules apply)

Memory footprint: ~10-30 MB. One of the lightest dashboards.

## Compatible install methods

| Infra       | Runtime                                             | Notes                                                              |
| ----------- | --------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM / home | Docker (`b4bz/homer`)                           | **Most common**; multi-arch (amd64/arm64/armv7)                      |
| Single VM   | Docker Compose                                        | Upstream-documented                                                  |
| Kubernetes  | Any webserver Deployment + ConfigMap                  | <https://github.com/bastienwirtz/homer/blob/main/docs/kubernetes.md> |
| Static host | nginx / Caddy / Apache                                | Copy the release zip to any webserver                                |
| Netlify     | Just upload build output                              | Zero-cost public dashboards possible                                 |

## Inputs to collect

| Input                 | Example                                 | Phase     | Notes                                                    |
| --------------------- | --------------------------------------- | --------- | -------------------------------------------------------- |
| Config dir            | `/opt/homer/config`                      | Filesystem | Bind-mounted to `/www/assets`                              |
| Service list          | titles, URLs, icons                      | Config    | In `config.yml`                                            |
| Icons / logos         | PNG/SVG for each service                 | Assets    | Drop into config dir under `icons/` or `tools/`            |
| PUID/PGID             | UID/GID matching config dir owner        | Security  | Default 1000:1000                                          |
| Reverse proxy domain  | `dash.example.com`                       | DNS       | For TLS                                                    |

## Install via Docker

```sh
# Make sure config dir exists and has correct permissions
mkdir -p /opt/homer/config
chown -R 1000:1000 /opt/homer/config

docker run -d --name homer \
  -p 8080:8080 \
  --mount type=bind,source=/opt/homer/config,target=/www/assets \
  --restart unless-stopped \
  b4bz/homer:latest
```

On first boot, Homer creates a default `config.yml` in the bind-mounted directory. Edit to taste + browser refresh.

## Install via Docker Compose

```yaml
services:
  homer:
    image: b4bz/homer:v26.4.2       # pin; check Docker Hub tags
    container_name: homer
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - /opt/homer/config:/www/assets
    environment:
      # Drop privileges
      INIT_ASSETS: 1       # 1 = ensure default config exists on first run
    user: 1000:1000
```

## Config essentials (`config.yml`)

```yaml
title: Home
subtitle: My Stack
logo: "assets/logo.png"
header: true
theme: default      # default | sui | neon
columns: auto       # 1-4 or auto

links:
  - name: Docs
    icon: fas fa-book
    url: https://docs.example.com
    target: _blank

services:
  - name: Media
    icon: fas fa-film
    items:
      - name: Jellyfin
        logo: assets/tools/jellyfin.png
        subtitle: Media server
        url: https://jellyfin.example.com
        target: _blank
        # Smart card for Jellyfin:
        type: "Jellyfin"
        apikey: "YOUR_JELLYFIN_API_KEY"
      - name: Sonarr
        logo: assets/tools/sonarr.png
        url: https://sonarr.example.com
        type: "Sonarr"
        apikey: "YOUR_SONARR_API_KEY"
```

"Smart card types" supported include: Sonarr, Radarr, Lidarr, Prowlarr, Readarr, Jellyfin, Emby, Plex, Pi-hole, AdGuard, Proxmox, Portainer, Uptime Kuma, Nextcloud, Synology, Medusa, SABnzbd, Gotify, qBittorrent, Transmission, and more.

## Data & config layout

Inside `/www/assets/` (your mounted dir):

- `config.yml` — everything
- `config.yml.dist` — the bundled sample (don't overwrite)
- `logo.png` — your site logo
- `icons/` — custom icons
- `tools/` — per-service icons (convention)
- `themes/*.css` — custom CSS themes (optional)

## Backup

```sh
tar czf homer-config-$(date +%F).tgz -C /opt/homer/config .
```

That's it — single directory.

## Upgrade

1. Releases: <https://github.com/bastienwirtz/homer/releases>. Infrequent.
2. `docker compose pull && docker compose up -d`.
3. Config format is very stable; breaking changes flagged in release notes.

## Gotchas

- **Smart cards poll from the browser** — this means your **browser** must be able to reach each service's API endpoint. That can require CORS on the target service (Pi-hole, Sonarr, etc. support enabling CORS). Check browser DevTools → Network tab if status isn't showing.
- **API keys live in `config.yml` → served to browser** — anyone who loads your Homer page sees them. **Do NOT expose Homer on the internet without auth.** Use reverse proxy basic auth, Authelia, or keep it on tailscale/VPN.
- **Service URLs in `config.yml`** should be the URLs that YOUR BROWSER uses — typically external/public URLs, not `http://sonarr:8989` Docker internal names.
- **PWA install** only works over HTTPS (standard browser requirement).
- **First-run empty config** — if you mount an empty dir, Homer creates a default. If you mount a file permissions-issue dir, Homer fails silently. Check container logs.
- **PUID/PGID** matters — the container's nginx runs as 1000; bind-mounted dir should be `chown 1000:1000`.
- **"Custom services" / community-contributed card types** — easy to add by copying JS templates in upstream docs.
- **Dark theme** — set `theme: "sui"` in config (or community themes: neon, glass, etc.).
- **Responsive design** — looks good on phone/tablet.
- **No backend** means no auth in Homer itself. Auth is always via reverse proxy.
- **Icon libraries**: Font Awesome 5 (all free icons) + Material Design Icons are bundled. Use `icon: fas fa-<name>` or `icon: mdi-<name>`.
- **Page layout** — `columns: 1-4` for fixed columns, `auto` for responsive.
- **Multi-page** setup: <https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md#additional-pages>
- **Alternative if you want server-side smart cards** (auth'd from server, not browser): use **Dashy** or **Homepage (gethomepage/homepage)** — they proxy API calls server-side, so CORS + API key exposure isn't an issue.
- **Apache-2.0 license** — use freely in commercial/private contexts.
- **Alternatives worth knowing:**
  - **Homepage** (gethomepage/homepage) — Next.js, server-side widgets, Docker/Kubernetes autodiscovery, the current "hot" dashboard
  - **Dashy** — more feature-heavy, Vue.js, server-side API calls
  - **Heimdall** — long-running, classic, PHP
  - **Organizr** — tabbed wrapping of other apps; SSO-ish
  - **Flame** — similar minimalism, more dynamic
  - **Homarr** — modern Mantine UI, drag-and-drop config
  - **Homer** is best if you want **absolute minimum** footprint + static-file deployability

## Links

- Repo: <https://github.com/bastienwirtz/homer>
- Demo: <https://homer-demo.netlify.app>
- Docker Hub: <https://hub.docker.com/r/b4bz/homer>
- Configuration reference: <https://github.com/bastienwirtz/homer/blob/main/docs/configuration.md>
- Customization (themes / icons): <https://github.com/bastienwirtz/homer/blob/main/docs/customservices.md>
- Kubernetes: <https://github.com/bastienwirtz/homer/blob/main/docs/kubernetes.md>
- Tips & tricks: <https://github.com/bastienwirtz/homer/blob/main/docs/tips-and-tricks.md>
- Releases: <https://github.com/bastienwirtz/homer/releases>
