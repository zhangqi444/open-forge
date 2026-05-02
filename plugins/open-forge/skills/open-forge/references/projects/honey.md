---
name: honey
description: Recipe for Honey — pure static HTML/CSS/JS homeserver dashboard. No backend required, all client-side. Configured via config.json, served via Docker (ghcr.io) or any static file server. Ping monitoring, service bookmarks, dark mode.
---

# Honey

Static homeserver dashboard. Upstream: https://github.com/dani3l0/honey

Pure HTML/CSS/JS — no backend, no server-side processing. All operations are client-side. Add service bookmarks, configure via `config.json`, get ping-dot availability indicators, dark/light mode, custom wallpapers, and animations. Serve via Docker or any static file server.

Live demo: https://honeyy.vercel.app/

## Compatible combos

| Method | Notes |
|---|---|
| Docker | `ghcr.io/dani3l0/honey:latest` — serves static files on port 4173 |
| Static file server | Download release ZIP, extract to webserver root |
| Any HTTP server | nginx, Caddy, Apache, S3 static hosting — just serve the files |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Dashboard name + description | Shown at the main screen and tab title |
| config | Services list | Each service: name, desc, href (URL), icon path |
| config (opt) | Custom icon / wallpaper | Place in config/ dir, reference with /config/ prefix in URLs |

## Software-layer concerns

**Config file:** `config/config.json` — mounted as a volume in Docker or edited directly in the webserver root. Missing config files are created automatically by the Docker container on first start.

**No backend:** Entirely client-side. No database, no server processes, no auth. Anyone who can access the URL can see and use the dashboard. Keep it on a private network or behind a reverse proxy with auth.

**Port:** 4173 in Docker.

**Config structure:**
```json
{
  "ui": {
    "name": "My Dashboard",
    "desc": "Homeserver services",
    "dark_mode": "Auto",
    "open_new_tab": true,
    "ping_dots": true,
    "trusted_domains": ["192.168.1.0/24"]
  },
  "services": [
    {
      "name": "Plex",
      "desc": "Media server",
      "href": "http://192.168.1.10:32400",
      "icon": "/config/icons/plex.png"
    }
  ]
}
```

**Custom icons/wallpapers:** Place files in the mounted `config/` directory and reference them with `/config/` prefix in URLs.

## Docker Compose

```yaml
services:
  honey:
    image: ghcr.io/dani3l0/honey:latest
    restart: unless-stopped
    ports:
      - "4173:4173"
    volumes:
      - ./honey-config:/app/dist/config
```

On first run, missing config files are created in `./honey-config/`. Edit `config.json` there to customize.

## Upgrade procedure

```bash
docker compose pull honey
docker compose up -d honey
```

Config volume is preserved. No state to migrate.

## Gotchas

- **No authentication** — the dashboard is fully public to anyone who can reach the port. Do not expose externally without a reverse proxy with auth (e.g. HTTP Basic Auth via Caddy/nginx).
- **Ping dots use browser-side fetch** — the availability indicator pings services directly from the user's browser, not from the server. Pings may fail for services not reachable from the browser's network.
- **Config edits require browser refresh** — changes to `config.json` take effect on the next page load.
- **Icon paths use /config/ prefix** — custom icons placed in the config dir must be referenced as `/config/icon.png`, not just `icon.png`.

## Links

- Upstream repository: https://github.com/dani3l0/honey
- GitHub Container Registry: https://ghcr.io/dani3l0/honey
- Live demo: https://honeyy.vercel.app/
- Releases: https://github.com/dani3l0/honey/releases
