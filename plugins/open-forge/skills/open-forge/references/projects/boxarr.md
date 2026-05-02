---
name: boxarr
description: Recipe for Boxarr — automatically tracks weekly box office charts and adds trending movies to Radarr. Python + Docker, no external DB, web UI setup wizard.
---

# Boxarr

Automatically track and add trending box office movies to your Radarr library. Upstream: https://github.com/iongpt/boxarr

Python app that monitors weekly box office charts (Box Office Mojo) and seamlessly integrates with Radarr to add mainstream hits automatically. No user requests needed — runs silently in the background on a weekly schedule. GPL v3.

Full documentation: https://github.com/iongpt/boxarr/wiki

## Prerequisites

- Radarr v3.0+
- Network access to Box Office Mojo (for chart data)
- Radarr API key

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Recommended — single container, config persisted in volume |
| Docker run | Supported |
| Python 3.10+ | Direct install without Docker (see wiki) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Radarr URL | e.g. http://radarr:7878 or http://192.168.1.x:7878 |
| preflight | Radarr API key | Settings → General → API Key in Radarr |
| preflight | Timezone | e.g. America/New_York — for scheduled update timing |
| config | Genre-based root folders | Optional: map genres to different library paths |
| config | Filters | Genre exclusions, min rating, min release year |

All configuration is done through the built-in web setup wizard at http://localhost:8888 after first launch.

## Software-layer concerns

**Config:** Web-based setup wizard on first launch — no manual config file editing required. Settings saved to the /config volume.

**Data:** SQLite or file-based config in /config. Mount a persistent volume to preserve settings across upgrades.

**Port:** Container on 8888.

**Scheduling:** Runs weekly box office checks on a configurable schedule. No cron needed externally.

**Radarr integration:** Uses the Radarr API to check existing movies before adding (deduplication). Genre-based root folders let you route different genres to different library paths.

**No external DB:** Single container, self-contained.

## Docker Compose

```yaml
services:
  boxarr:
    image: ghcr.io/iongpt/boxarr:latest
    container_name: boxarr
    restart: unless-stopped
    ports:
      - "8888:8888"
    volumes:
      - ./config:/config
    environment:
      - TZ=America/New_York
```

After starting, open http://localhost:8888 and complete the setup wizard to connect Radarr and configure filters.

## Upgrade procedure

```bash
docker compose pull boxarr
docker compose up -d boxarr
```

Config is preserved in the ./config volume. Check the wiki for any migration notes between versions.

## Gotchas

- **Complements, not replaces, Seerr** — Boxarr is for automatic mainstream coverage; Seerr handles user-driven requests. Use both together.
- **Box Office Mojo access required** — Boxarr fetches chart data from Box Office Mojo; outbound access must be allowed from the container.
- **Radarr must be reachable** — container networking must allow Boxarr to reach Radarr's API port.
- **Genre root folders are optional** — skip during setup if you use a single library path.

## Links

- Upstream repository + wiki: https://github.com/iongpt/boxarr/wiki
- Installation guide: https://github.com/iongpt/boxarr/wiki/Installation-Guide
- Configuration guide: https://github.com/iongpt/boxarr/wiki/Configuration-Guide
- GitHub Container Registry: https://ghcr.io/iongpt/boxarr
