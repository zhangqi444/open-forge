---
name: Deleterr
description: Intelligent media library cleanup for Plex. Uses Radarr, Sonarr, and Tautulli to delete media based on watch history, age, streaming availability (JustWatch), and Trakt lists. MIT licensed.
website: https://rfsbraz.github.io/deleterr/
source: https://github.com/rfsbraz/deleterr
license: MIT
stars: 299
tags:
  - plex
  - media-management
  - automation
  - radarr
  - sonarr
platforms:
  - Python
  - Docker
---

# Deleterr

Deleterr is an intelligent media library cleanup tool for Plex. It connects to Radarr, Sonarr, and Tautulli to identify and delete media files based on configurable criteria: watch history, content age, streaming availability via JustWatch, Trakt list membership, and more. Includes a dry-run mode, smart exclusion rules, and a built-in scheduler.

> ⚠️ **Warning**: Do not use with media you cannot afford to lose. Enable Radarr/Sonarr recycle bin before use.

Source: https://github.com/rfsbraz/deleterr
Docs: https://rfsbraz.github.io/deleterr/
Docker Hub: https://hub.docker.com/r/rfsbraz/deleterr

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VM / VPS | Docker (alongside Plex/Radarr/Sonarr) | Recommended |
| Any Linux | Python 3.9+ | Native install |

## Inputs to Collect

**Phase: Planning**
- Plex URL and token
- Radarr/Sonarr URL(s) and API key(s)
- Tautulli URL and API key (for watch history)
- JustWatch region (optional, for streaming availability checks)
- Trakt credentials (optional)
- Deletion rules (watched, age, size thresholds)
- Schedule for automatic runs

## Software-Layer Concerns

**Docker Compose:**

```yaml
services:
  deleterr:
    image: ghcr.io/rfsbraz/deleterr:latest
    container_name: deleterr
    environment:
      LOG_LEVEL: INFO
    volumes:
      - ./config:/config
    restart: unless-stopped
```

**`config/settings.yaml` (minimal example):**

```yaml
schedule:
  # Run weekly on Sunday at midnight
  cron: "0 0 * * 0"

plex:
  url: "http://plex:32400"
  token: "YOUR_PLEX_TOKEN"

tautulli:
  url: "http://tautulli:8181"
  api_key: "YOUR_TAUTULLI_API_KEY"

radarr:
  - name: movies
    url: "http://radarr:7878"
    api_key: "YOUR_RADARR_API_KEY"
    # Dry run - set to false to enable real deletions
    dry_run: true
    rules:
      - name: "Delete watched movies older than 30 days"
        condition:
          watched: true
          age_days: 30
        action: delete

sonarr:
  - name: tv
    url: "http://sonarr:8989"
    api_key: "YOUR_SONARR_API_KEY"
    dry_run: true
    rules:
      - name: "Delete watched episodes older than 14 days"
        condition:
          watched: true
          age_days: 14
        action: delete
```

**Smart exclusion examples (in rules):**

```yaml
exclude:
  genres:
    - Animation
    - Documentary
  collections:
    - "Marvel Cinematic Universe"
  trakt_lists:
    - "https://trakt.tv/users/me/lists/keep-forever"
  streaming:
    # Don't delete if available on these services
    - Netflix
    - Disney Plus
```

**Dry run first:** Always start with `dry_run: true` to preview what would be deleted, then review logs before enabling real deletions.

**Get Plex token:** https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/

## Upgrade Procedure

1. `docker pull ghcr.io/rfsbraz/deleterr:latest`
2. `docker compose down && docker compose up -d`
3. Check releases: https://github.com/rfsbraz/deleterr/releases

## Gotchas

- **Enable recycle bin**: Turn on Radarr/Sonarr recycle bin before use — deleted files go there for recovery; without it, deletions are permanent
- **Dry run mandatory first**: Always verify with `dry_run: true` before enabling real deletions — a misconfigured rule can delete large amounts of media
- **Tautulli required for watch data**: Watch history rules depend on Tautulli; without it, only age/size rules work
- **JustWatch API**: Streaming availability checks are best-effort; JustWatch data may lag behind actual availability
- **Multiple instances**: Supports multiple Radarr/Sonarr instances (e.g. regular + 4K libraries) — define them as separate list items under `radarr:` / `sonarr:`
- **Leaving Soon**: Deleterr can create Plex collections warning users before removal — see docs for "Leaving Soon" feature configuration

## Links

- Upstream README: https://github.com/rfsbraz/deleterr/blob/main/README.md
- Documentation: https://rfsbraz.github.io/deleterr/
- Configuration reference: https://rfsbraz.github.io/deleterr/CONFIGURATION
- Templates: https://rfsbraz.github.io/deleterr/templates
- Releases: https://github.com/rfsbraz/deleterr/releases
