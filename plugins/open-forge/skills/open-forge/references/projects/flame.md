---
name: flame
description: Flame recipe for open-forge. Self-hosted startpage/dashboard with app tiles, bookmarks, weather widget, and a simple admin UI.
---

# Flame

Self-hosted startpage and personal dashboard. Provides app tiles, bookmarks, a weather widget (OpenWeatherMap), and a built-in admin UI for managing items. Upstream: <https://github.com/pawelmalak/flame>. Docker Hub: `pawelmalak/flame`.

> ⚠️ **Maintenance status:** Flame has seen minimal activity since 2022 (last meaningful release ~v2.3.1, last commit April 2024). It remains functional but is not actively developed. Consider [Homarr](https://homarr.dev/) or [Homer](https://github.com/bastienwirtz/homer) as more actively maintained alternatives.

## Compatible install methods

| Method | When to use |
|---|---|
| Docker Compose (recommended) | Standard self-hosted deployment |
| Standalone Docker | Quick test / single-container setups |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Admin password for Flame?" | Set via `PASSWORD` env var |
| optional | "OpenWeatherMap API key?" | Required for weather widget; free tier at openweathermap.org |

## Docker Compose example

```yaml
version: "3.9"
services:
  flame:
    image: pawelmalak/flame:latest
    container_name: flame
    restart: unless-stopped
    ports:
      - "5005:5005"
    volumes:
      - flame-data:/app/data
      - /var/run/docker.sock:/var/run/docker.sock:ro   # optional: Docker integration
    environment:
      PASSWORD: changeme

volumes:
  flame-data:
```

## Software-layer concerns

- Default port: `5005`
- Data directory: `/app/data` — persist this volume to retain your apps, bookmarks, and settings
- `PASSWORD` env var sets the admin UI password; required to make changes
- `/var/run/docker.sock` mount (read-only) enables automatic Docker label integration — Flame can auto-discover containers with `flame.type=app` labels
- Weather widget requires an [OpenWeatherMap API key](https://openweathermap.org/api) (free tier available); configure in Settings → Weather

## Docker label integration (optional)

Flame can auto-add running containers to the dashboard using labels:

```yaml
labels:
  - flame.type=app          # or "bookmark"
  - flame.name=My App
  - flame.url=https://myapp.example.com
  - flame.icon=docker       # icon name from SimpleIcons or a URL
```

Requires the `/var/run/docker.sock` mount on the Flame container.

## Upgrade procedure

1. Pull new image: `docker compose pull flame`
2. Restart: `docker compose up -d flame`
3. Data in `/app/data` persists across upgrades

## Gotchas

- **Low maintenance** — no active development; no guarantee of upstream fixes for new bugs
- Weather widget is broken without a valid OpenWeatherMap API key
- No built-in TLS — put behind a reverse proxy (Caddy / Traefik / NGINX) for HTTPS
- Docker socket mount is optional but gives convenient auto-discovery; use `:ro` (read-only) for safety
- If migrating away: Homarr and Homer both support manual app/bookmark lists; no automatic import from Flame

## Links

- GitHub: <https://github.com/pawelmalak/flame>
- Docker Hub: <https://hub.docker.com/r/pawelmalak/flame>
