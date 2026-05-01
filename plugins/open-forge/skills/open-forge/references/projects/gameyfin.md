---
name: Gameyfin
description: "Self-hosted game library manager. Docker/JVM. Kotlin/Spring Boot + React + H2. gameyfin/gameyfin. Auto-scan game folders, download metadata/covers, web UI browser, direct downloads, SSO/OIDC, plugin system. AGPL-3.0."
---

# Gameyfin

**Self-hosted video game library manager.** Point Gameyfin at your game folders and it automatically scans, downloads metadata and cover art, and presents your collection as a beautiful web UI. Browse and download games directly from the browser. Share with friends and family. SSO/OIDC integration. Extensible via plugins (metadata sources).

Built + maintained by **gameyfin team**. AGPL-3.0 license.

- Upstream repo: <https://github.com/gameyfin/gameyfin>
- Website + docs: <https://gameyfin.org>
- Docker image: `ghcr.io/gameyfin/gameyfin`

## Architecture in one minute

- **Kotlin / Spring Boot 3** backend
- **React** (Vaadin Hilla) frontend
- **H2** embedded database (zero-config)
- **PF4J** plugin system for metadata providers
- Port **configurable** (see docs)
- Resource: **low-medium** — JVM; 256 MB+ RAM

## Compatible install methods

| Infra      | Runtime                    | Notes                                         |
| ---------- | -------------------------- | --------------------------------------------- |
| **Docker** | `ghcr.io/gameyfin/gameyfin` | **Primary** — multi-arch; GHCR               |
| **JVM**    | `.jar` release             | Any system with JVM; no Docker required        |

Full install guide: <https://gameyfin.org/installation>

## Install via Docker

```bash
docker run -d \
  --name gameyfin \
  -p 8080:8080 \
  -v /your/games:/games:ro \
  -v gameyfin_data:/data \
  ghcr.io/gameyfin/gameyfin:latest
```

Or Docker Compose — see <https://gameyfin.org/installation> for the canonical compose snippet.

## First boot

1. Visit `http://localhost:8080` after starting.
2. Complete the setup wizard (admin account, site name).
3. Go to **Admin → Plugins** — enable a metadata plugin (e.g. IGDB, RAWG) and enter its API key.
4. Go to **Libraries → Add Library** — point to a game folder path.
5. Trigger a **scan** — Gameyfin indexes game files and downloads metadata + cover art.
6. Browse your library from the web UI; download games directly.
7. (Optional) Set up SSO/OIDC in Admin settings.
8. Put behind TLS for sharing externally.

## Features overview

| Feature | Details |
|---------|---------|
| Auto-scan | Scans configured game folders; matches files to game titles |
| Metadata download | Downloads descriptions, cover art, release dates, genres |
| Web browser UI | Beautiful grid/list view; filter, search, sort |
| Direct download | Download game files directly from the browser |
| Library sharing | Share library access with other users |
| User management | Multiple user accounts with roles |
| SSO/OIDC | Integrate with Authentik, Keycloak, Authelia, etc. (`username_claim` configurable) |
| Plugin system | Metadata plugins (IGDB, RAWG, etc.); extensible |
| Themes | Multiple themes including colorblind support |
| LAN-friendly | Metadata/assets cached locally; only metadata queries go out |
| H2 database | Zero-config embedded database; no external DB needed |

## Gotchas

- **Metadata plugins need API keys.** Gameyfin fetches metadata from external sources (IGDB, RAWG, etc.). Each plugin requires its own API key from the respective service. Enable and configure at least one metadata plugin before scanning — without one, files are indexed but no metadata or covers are downloaded.
- **File matching is heuristic.** Gameyfin matches filenames to game titles using fuzzy matching. Complex filenames (with tags, version strings, scene release names) may not match correctly. You can manually correct matches from the UI.
- **AGPL-3.0 license.** If you modify Gameyfin and offer it as a network service, you must publish your changes under AGPL-3.0.
- **H2 database.** The embedded H2 DB is fine for most use cases. For very large libraries or concurrent multi-user access, check the docs for PostgreSQL migration options if available.

## Backup

```sh
# Back up the data volume (contains H2 DB + assets)
docker run --rm -v gameyfin_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/gameyfin-$(date +%F).tgz /data
```

## Upgrade

```sh
docker pull ghcr.io/gameyfin/gameyfin:latest
docker stop gameyfin && docker rm gameyfin
docker run -d --name gameyfin -p 8080:8080 \
  -v /your/games:/games:ro -v gameyfin_data:/data \
  ghcr.io/gameyfin/gameyfin:latest
```

## Project health

Active Kotlin/Spring Boot development, v2 release, OIDC SSO, PF4J plugin system, H2 embedded database, AGPL-3.0.

## Game-library-family comparison

- **Gameyfin** — Kotlin/Spring Boot, game library, metadata+covers, web UI, direct downloads, OIDC, AGPL-3.0
- **Playnite** — Windows desktop app; not a server; not self-hosted
- **RetroArch** — emulator frontend; different scope
- **Romm** — Python, ROM-focused with IGDB metadata; emulator-oriented; different scope
- **Ludusavi** — Rust CLI for game save backups; different scope entirely

**Choose Gameyfin if:** you want a self-hosted web UI to browse and download PC games from your file server, with automatic metadata/cover art scraping and OIDC SSO.

## Links

- Repo: <https://github.com/gameyfin/gameyfin>
- Docs + install: <https://gameyfin.org>
