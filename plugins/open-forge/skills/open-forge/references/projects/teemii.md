---
name: teemii-project
description: Teemii recipe for open-forge. Self-hosted manga reading and management webapp. In-browser CBZ/CBR reader, metadata aggregation from AniList/MAL/MangaDex/etc., chapter fetching from multiple sources, Kitsu/AniList scrobbling, recommendations. Two containers (frontend + backend). Upstream: https://github.com/dokkaner/teemii
---

# Teemii

A self-hosted manga reading and management web application. Read manga in-browser, manage your collection, fetch chapters from multiple online sources, aggregate metadata from AniList, MAL, MangaDex, and others, and scrobble reading progress to Kitsu and AniList.

Upstream: <https://github.com/dokkaner/teemii> | Docs: <https://docs.teemii.io>

Two containers: a Vue frontend and an Express backend. All configuration via a first-run setup wizard.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Two containers (frontend + backend); data in named volume |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port for web UI?" | Default: `8080` (host) → container port `80` |
| config (wizard) | "Database path?" | First-run wizard; default inside container data volume |
| config (wizard) | "Storage path for manga images/covers?" | First-run wizard; default inside container data volume |
| config (wizard) | "Preferred languages?" | Chapter language priority |

## Software-layer concerns

### Images

```
dokkaner/teemii-frontend:latest
dokkaner/teemii-backend:latest
```

### Compose

```yaml
services:
  teemii-frontend:
    image: dokkaner/teemii-frontend:latest
    restart: unless-stopped
    ports:
      - "8080:80"
    networks:
      - teemii-network
    environment:
      - VITE_APP_TITLE=Teemii
      - VITE_APP_PORT=80

  teemii-backend:
    image: dokkaner/teemii-backend:latest
    restart: unless-stopped
    volumes:
      - teemii-data:/data
    networks:
      - teemii-network
    environment:
      - EXPRESS_PORT=3000
      - SOCKET_IO_PORT=1555

networks:
  teemii-network:
    driver: bridge

volumes:
  teemii-data:
    name: teemii-data
```

> Source: upstream docker-compose.yml — <https://github.com/dokkaner/teemii>

> ⚠️ **Use a named Docker volume** for `teemii-data` to ensure manga data persists across container replacements. Bind-mounts work but require correct permissions.

### First-run setup wizard

On first access, Teemii presents a 3-step wizard:
1. **Database path** — where manga metadata/info is stored (default in volume)
2. **Storage path** — where images, covers, and chapter files are stored (default in volume)
3. **Preferred languages** — chapter language priority for fetching

After the wizard, add your first manga to start building your collection.

### Features

- **In-browser reader** — CBZ and CBR format support; no extra software needed
- **Chapter fetching** — automated chapter downloads from Bato, MangaDex, MangaKakalot, MangaPill, ComickFun, and others
- **Metadata aggregation** — pulls from AniList, MyAnimeList, MangaDex, MangaUpdates, Kitsu, Goodreads, Nautiljon, AniBrainAI
- **Scrobbling** — sync reading progress to Kitsu and AniList
- **Recommendations** — personalized suggestions based on reading history
- **Progress tracking** — automatic tracking of what you've read
- **Dark mode** — toggle in settings

### Metadata sources

Teemii aggregates metadata from: AniList, MyAnimeList (MAL), MangaDex, MangaUpdates, Kitsu, Goodreads, Nautiljon, ComickFun, AniBrainAI. Sources are queried automatically when you add manga — no API keys required for most.

### Scrobbling setup

Configure Kitsu and/or AniList credentials in Settings after first run to enable progress sync.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

The `teemii-data` named volume persists all manga data, metadata, and images across upgrades.

## Gotchas

- **Named volume is strongly recommended** — using a bind-mount without correct permissions can cause the backend to fail writing data. Named volumes are managed by Docker and avoid permission issues.
- **Frontend communicates with backend via Docker network** — both services must be on the same Docker network (`teemii-network`). Do not remove the `networks` block.
- **No auth by default** — Teemii has no built-in authentication in the base setup. Front with a reverse proxy with auth (Authelia, Traefik ForwardAuth, nginx basic auth) if exposing outside your LAN.
- **Chapter sources may change** — upstream chapter fetching sources (Bato, MangaKakalot, etc.) can break if scraped sites change their structure. Check GitHub issues if fetching stops working.
- **Storage path can grow large** — manga image files accumulate quickly. Ensure the volume or bind-mount has sufficient space (plan for GBs per series).
- **Setup wizard runs once** — paths set during the wizard are persisted. To change them later, edit the config directly or reinitialize (which clears data).

## Links

- Upstream README: <https://github.com/dokkaner/teemii>
- Documentation: <https://docs.teemii.io>
- Quick Start: <https://docs.teemii.io/Quick-Start/>
- Deployment Guide: <https://docs.teemii.io/Quick-Start/Installation/>
- GitHub Discussions: <https://github.com/dokkaner/teemii/discussions>
