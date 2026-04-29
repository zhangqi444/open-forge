---
name: homepage-project
description: Homepage (gethomepage) recipe for open-forge. GPLv3-licensed modern, static, fast, fully-proxied application dashboard — arrange tiles for every service in your homelab, integrate with 100+ services (Sonarr, Radarr, Plex, Jellyfin, Proxmox, Traefik, Uptime Kuma, Pi-hole, etc.) via first-party widgets, auto-discover Docker containers via labels, info widgets (weather, time, search, bookmarks), i18n in 40+ languages, dark/light theming, YAML-configured. Multi-arch images (amd64, arm64). Covers the canonical Docker Compose deploy (with Docker socket mount for discovery), `HOMEPAGE_ALLOWED_HOSTS` mandatory-as-of-v1.0 security setting, config file layout, reverse proxy + multi-user notes, and the non-root `PUID`/`PGID` pattern.
---

# Homepage (gethomepage)

GPLv3-licensed application dashboard. Upstream: <https://github.com/gethomepage/homepage>. Docs: <https://gethomepage.dev>.

A dashboard that sits on your browser home page / new-tab page. One YAML file describes your services; Homepage renders tiles, pulls live status/stats from each service's API (through a proxy so API keys stay server-side), and displays weather, time, bookmarks, search. Ideal for homelab dashboards where "what's running and is it healthy?" needs to be answerable at a glance.

**Distinguishing features:**

- **Statically generated** — page is built at startup, instant load time.
- **API proxy** — credentials for backend services (Radarr API key, Proxmox token, etc.) never touch the browser.
- **100+ service integrations** — each rendered as a live tile with counts / stats / queue / health.
- **Docker label auto-discovery** — containers with `homepage.*` labels appear automatically.
- **i18n** — 40+ languages.
- **Bookmarks + search** — custom links grouped, and a search bar that posts to configurable search engines.
- **Info widgets** — weather, time, Glances / Peanut / NUT / Open-Meteo, system stats.
- **Themeable** — custom CSS/JS.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker image (`ghcr.io/gethomepage/homepage`) | ✅ Recommended | Most self-hosters. Multi-arch (amd64, arm64). |
| Docker Compose | <https://gethomepage.dev/installation/docker/> | ✅ | Homelab standard. |
| Kubernetes / Helm | <https://gethomepage.dev/installation/k8s/> + community chart | ✅ docs / ⚠️ 3rd-party chart | Clusters. |
| Node.js source | <https://gethomepage.dev/installation/source/> | ✅ | Dev / contributors. No standard binary. |
| Unraid / TrueNAS / CasaOS | Community app stores | ⚠️ | Appliance NAS boxes. |

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `kubernetes` / `source` | Drives section. |
| ports | "HTTP port?" | Default `3000` | Container listens on 3000. |
| dns | "Public hostname(s)?" | Comma-separated list | **REQUIRED as `HOMEPAGE_ALLOWED_HOSTS` since v1.0** — the app refuses connections from non-listed hosts. Include `localhost`, LAN IPs, and the public hostname. |
| storage | "Config directory path?" | Free-text, default `./config` | Bind-mounted at `/app/config`. Will be auto-seeded on first run. |
| auth | "Run as non-root?" | Boolean | Optional; set `PUID`/`PGID` env vars if yes. |
| discovery | "Enable Docker auto-discovery?" | Boolean | If yes → mount `/var/run/docker.sock`. |
| widgets | "Weather / time / search widgets?" | Configured via YAML later; skip for install phase. | Set up in `settings.yaml` / `widgets.yaml`. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `traefik` / `caddy` / `nginx` / `none` | If exposing externally. |

## Install — Docker Compose

```yaml
# compose.yaml — source: https://gethomepage.dev/installation/docker/
services:
  homepage:
    image: ghcr.io/gethomepage/homepage:latest           # pin a version in prod
    container_name: homepage
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./config:/app/config
      # Optional — Docker auto-discovery. Remove this line if not using.
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      # REQUIRED since v1.0. Comma-separated list of hostnames allowed to access Homepage.
      # Include public hostname, LAN IPs, and "localhost".
      HOMEPAGE_ALLOWED_HOSTS: "home.example.com,192.168.1.10:3000,localhost:3000"
      # Optional — run as non-root (uncomment + use env-file for real values)
      # PUID: 1000
      # PGID: 1000
```

Bring up:

```bash
mkdir -p config
docker compose up -d
# → http://localhost:3000/
```

On first launch Homepage auto-seeds the `config/` directory with example YAML files: `services.yaml`, `settings.yaml`, `widgets.yaml`, `bookmarks.yaml`, `docker.yaml`, `kubernetes.yaml`, `custom.css`, `custom.js`.

## Install — Docker run (one-liner)

```bash
docker run -d \
  --name homepage \
  --restart unless-stopped \
  -p 3000:3000 \
  -v ./config:/app/config \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -e HOMEPAGE_ALLOWED_HOSTS="home.example.com,localhost:3000" \
  ghcr.io/gethomepage/homepage:latest
```

## Install — Kubernetes (Helm — community)

See <https://github.com/jameswynn/helm-charts/tree/main/charts/homepage>. (No first-party Helm chart; community chart is the standard.) Homepage's docs include the raw manifests as an alternative: <https://gethomepage.dev/installation/k8s/>.

## Configuration files (the Homepage YAML schema)

All in `./config/`:

| File | Content |
|---|---|
| `settings.yaml` | Title, theme, layout, background, default language, auth (header-based), version display, cardBlur, etc. |
| `services.yaml` | Groups and tiles — `name`, `icon`, `href`, `description`, plus service-specific widget (`widget: type: radarr, url: …, key: …`). |
| `widgets.yaml` | Top-bar info widgets (weather, time, search, logo). |
| `bookmarks.yaml` | External link tiles (GitHub, Reddit, etc.). |
| `docker.yaml` | Docker daemon(s) for auto-discovery (local socket or TCP). |
| `kubernetes.yaml` | K8s cluster(s) for auto-discovery. |
| `custom.css` / `custom.js` | Custom styling. |

Reference: <https://gethomepage.dev/configs/>.

### Minimal `services.yaml`

```yaml
# config/services.yaml
- Media:
    - Plex:
        icon: plex.png
        href: http://plex.lan:32400
        description: Media streaming
        widget:
          type: plex
          url: http://plex.lan:32400
          key: "{{HOMEPAGE_VAR_PLEX_TOKEN}}"
    - Jellyfin:
        icon: jellyfin.png
        href: http://jellyfin.lan:8096
        widget:
          type: jellyfin
          url: http://jellyfin.lan:8096
          key: "{{HOMEPAGE_VAR_JELLYFIN_KEY}}"

- Infra:
    - Traefik:
        icon: traefik.png
        href: https://traefik.lan
        widget:
          type: traefik
          url: https://traefik.lan
          username: "{{HOMEPAGE_VAR_TRAEFIK_USER}}"
          password: "{{HOMEPAGE_VAR_TRAEFIK_PASS}}"
```

### Environment-substituted secrets

Homepage substitutes `{{HOMEPAGE_VAR_XXX}}` with env var `HOMEPAGE_VAR_XXX`, and `{{HOMEPAGE_FILE_XXX}}` with the contents of the file at path `HOMEPAGE_FILE_XXX` — useful for Docker secrets / k8s secrets.

```yaml
# compose.yaml (fragment)
environment:
  HOMEPAGE_VAR_PLEX_TOKEN: xxxxxxxx
  HOMEPAGE_VAR_JELLYFIN_KEY: yyyyyyyy
  HOMEPAGE_FILE_TRAEFIK_PASS: /run/secrets/traefik_pass
```

## Docker auto-discovery

If you mount the Docker socket and add labels, services appear automatically:

```yaml
# any service in any compose file
services:
  radarr:
    image: linuxserver/radarr
    labels:
      homepage.group: Media
      homepage.name: Radarr
      homepage.icon: radarr.png
      homepage.href: http://radarr.lan:7878
      homepage.description: Movies
      homepage.widget.type: radarr
      homepage.widget.url: http://radarr:7878
      homepage.widget.key: ${RADARR_API_KEY}
```

See <https://gethomepage.dev/configs/docker/>.

## Reverse proxy (Caddy example)

```caddy
home.example.com {
    reverse_proxy homepage:3000
}
```

Homepage doesn't do any internal TLS; terminate at the proxy.

## Data layout

| Path | Content |
|---|---|
| `./config/*.yaml` | All configuration — versionable in git (keep secrets out via env vars). |
| `./config/custom.css` + `custom.js` | Custom UI code. |
| `./config/logs/` | App logs (if configured). |

No database; all state is in YAML files + env vars.

**Backup** = tar `./config/`. Tiny.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker compose logs -f homepage
```

Read the release notes before upgrading — occasional YAML schema renames happen. Upstream: <https://github.com/gethomepage/homepage/releases>.

**Major breakage to watch for**: v1.0 (2025) introduced the `HOMEPAGE_ALLOWED_HOSTS` requirement. Pre-1.0 instances without it will fail to load after upgrade until the env var is set.

## Gotchas

- **`HOMEPAGE_ALLOWED_HOSTS` is mandatory since v1.0.** Without it (or with a value that doesn't include the hostname you're accessing from), Homepage returns a 400/403. Include EVERY way you might reach it: `home.example.com`, `192.168.1.10:3000`, `localhost:3000`, `homelab.local:3000`, etc. Supports wildcard: `HOMEPAGE_ALLOWED_HOSTS=*` to disable (NOT recommended for public instances).
- **Docker socket mount is a security surface.** `/var/run/docker.sock` grants Homepage (or anything that compromises Homepage) effective root on the host. If exposed publicly, use a socket proxy (`tecnativa/docker-socket-proxy`) to restrict API surface.
- **PUID/PGID + Docker socket conflict.** Running non-root means the user needs to be in the `docker` group to read the socket. Usually easier to just run as root for simple setups.
- **Widgets make HTTP requests FROM the Homepage container** — network reachability matters. Widget `url` must be resolvable from inside the container. For services on the same Docker network, use service names; for services on the host, use `host.docker.internal` or the host's LAN IP.
- **API keys in `services.yaml` leak into git if not careful.** Use `{{HOMEPAGE_VAR_XXX}}` + env vars, or `{{HOMEPAGE_FILE_XXX}}` + Docker/k8s secrets.
- **The config dir is auto-seeded on first run.** If you bind-mount an empty dir, Homepage populates example YAML on startup. Good for discoverability; confusing if you expected Homepage to use an existing config that was mounted wrong.
- **Large services.yaml = slow rebuilds.** Homepage rebuilds on every config change; 200+ tiles noticeable pause. Split into groups, and consider using Docker discovery to keep `services.yaml` lean.
- **Weather widget needs Open-Meteo or OpenWeatherMap key.** Open-Meteo is keyless + free + recommended; OpenWeatherMap requires a free account + API key. Configure in `widgets.yaml`.
- **Docker discovery can collide with manual YAML entries.** If you have a `Radarr` tile in `services.yaml` AND a Radarr container with `homepage.*` labels, both appear (duplicate). Choose one source of truth.
- **No built-in auth.** Homepage has no login. Put it behind a reverse proxy with auth (Authelia, Authentik, oauth2-proxy) OR only expose on a trusted LAN / VPN.
- **Bookmark "icons" are from dashboard-icons project** (<https://github.com/walkxcode/dashboard-icons>). Reference them by filename (`radarr.png`) or URL. If an icon is missing upstream, it silently falls back to a placeholder.
- **`i18n` depends on Crowdin translations.** If your chosen language is partially translated, you'll see English strings mixed with translations. Patch upstream via Crowdin.
- **API proxy hides the real backend URL from the browser** — if a tile "can't connect," debug from the Homepage container (`docker exec homepage curl <backend-url>`), not from your browser devtools.
- **HTTPS behind Cloudflare Tunnel / reverse proxy** needs `HOMEPAGE_ALLOWED_HOSTS` to match whatever Cloudflare / the proxy forwards as the `Host` header. Mismatch = 400 errors visible only in logs.
- **Home Assistant widget** requires a long-lived access token from your HA instance with appropriate scope. Default scopes expose state of all entities; scope down if you want granular access.
- **Custom CSS can break after updates.** The DOM class names aren't a public API. Test custom styling after each upgrade.
- **Kubernetes discovery** pulls from the cluster API — Homepage needs a ServiceAccount with read access to services / pods / ingresses. See <https://gethomepage.dev/configs/kubernetes/>.

## Links

- Upstream repo: <https://github.com/gethomepage/homepage>
- Docs site: <https://gethomepage.dev>
- Installation (Docker): <https://gethomepage.dev/installation/docker/>
- Service widgets reference: <https://gethomepage.dev/widgets/>
- Info widgets reference: <https://gethomepage.dev/widgets/info/>
- Docker auto-discovery: <https://gethomepage.dev/configs/docker/>
- Kubernetes integration: <https://gethomepage.dev/configs/kubernetes/>
- Environment vars + secrets: <https://gethomepage.dev/installation/docker/#using-environment-secrets>
- Releases: <https://github.com/gethomepage/homepage/releases>
- Discord: <https://discord.gg/k4ruYNrudu>
- dashboard-icons (icon set): <https://github.com/walkxcode/dashboard-icons>
