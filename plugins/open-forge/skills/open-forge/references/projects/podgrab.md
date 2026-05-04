---
name: podgrab
description: Recipe for Podgrab — self-hosted podcast manager and archiver that auto-downloads episodes as they go live.
---

# Podgrab

Self-hosted podcast manager, downloader, and archiver. Subscribe to podcasts via RSS; episodes are automatically downloaded as they become available. Includes an integrated web-based player. Single Go binary with a built-in web UI. Upstream: <https://github.com/akhilrex/podgrab>. License: GPL-3.0.

> **Note:** Podgrab has been in low-maintenance mode since 2023 (last commit April 2024). It remains functional but consider actively maintained alternatives such as [Audiobookshelf](https://www.audiobookshelf.org) (which now supports podcasts) or [Podfetch](https://github.com/SamTV12345/PodFetch) for new deployments.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker | <https://github.com/akhilrex/podgrab#using-docker> | Yes | Recommended |
| Docker Compose | <https://github.com/akhilrex/podgrab#using-docker-compose> | Yes | Standard compose deployment |
| Binary | <https://github.com/akhilrex/podgrab/releases> | Yes | Bare-metal |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Port for Podgrab UI? | Port (default 8080) | All |
| software | Host data directory for downloads? | Absolute path | Required; where episode files are stored |
| software | Check interval (minutes)? | Integer (default 30) | How often to check feeds for new episodes |
| software | Password (optional)? | String | Optional; enables basic auth |

## Software-layer concerns

### Docker run

```bash
docker run -d \
  --name podgrab \
  -p 8080:8080 \
  -v /path/to/config:/config \
  -v /path/to/assets:/assets \
  --restart unless-stopped \
  akhilrex/podgrab
```

### Docker Compose

```yaml
services:
  podgrab:
    image: akhilrex/podgrab:latest
    container_name: podgrab
    environment:
      - CHECK_FREQUENCY=30       # minutes between feed checks
      - PASSWORD=                # leave blank to disable auth
    ports:
      - "8080:8080"
    volumes:
      - podgrab-config:/config   # SQLite DB + settings
      - podgrab-assets:/assets   # downloaded episode files
    restart: unless-stopped

volumes:
  podgrab-config:
  podgrab-assets:
```

### Key environment variables

| Variable | Default | Description |
|---|---|---|
| CHECK_FREQUENCY | 30 | Minutes between RSS feed checks |
| PASSWORD | (empty) | Enable basic auth with this password (username: admin) |

### Data volumes

| Volume | Purpose |
|---|---|
| `/config` | SQLite database, app settings |
| `/assets` | Downloaded podcast episode MP3/audio files |

### Adding podcasts

Via the web UI at http://localhost:8080:
1. Search by podcast name or paste an RSS feed URL
2. Choose which episodes to download (all, latest N, or just new ones)
3. Podgrab checks the feed at `CHECK_FREQUENCY` intervals and downloads new episodes automatically

## Upgrade procedure

```bash
docker compose pull && docker compose up -d
```

## Gotchas

- Low maintenance: the project has not been actively developed since 2023. Known issues may not be fixed.
- Asset directory: bind-mount `/assets` to a host directory to access downloaded files from other apps (e.g. music players, Jellyfin).
- Storage: podcasts accumulate quickly. Monitor disk usage and consider setting retention policies (not built-in; prune manually or via cron).
- Basic auth only: Podgrab's authentication is a single global password. There is no multi-user support.

## Alternatives (actively maintained)

- **Audiobookshelf** — supports both audiobooks and podcasts: <https://www.audiobookshelf.org>
- **PodFetch** — modern podcast manager: <https://github.com/SamTV12345/PodFetch>
- **Pinepods** — podcast manager with multi-user support: <https://github.com/madeofpendletonwool/PinePods>

## Links

- GitHub: <https://github.com/akhilrex/podgrab>
- Docker Hub: <https://hub.docker.com/r/akhilrex/podgrab>
