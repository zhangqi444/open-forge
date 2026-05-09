---
name: Suwayomi-Server
description: Free and open source manga reader server compatible with Mihon (Tachiyomi) extensions. Runs sources in-browser, auto-downloads chapters, tracks progress via MAL/AniList/MangaUpdates. Single Docker container, Java-based. MIT-licensed.
---

# Suwayomi-Server

Suwayomi-Server is a self-hosted manga server that runs [Mihon (Tachiyomi)](https://mihon.app/) extensions on the server side, making your entire manga library available from any browser or supported client. It's not a fork of Tachiyomi — it's a compatible server-side reimplementation.

What makes Suwayomi distinctive:

- **Tachiyomi extensions** — install the same sources you'd use in the Android app; all run server-side
- **Web UI bundled** — Suwayomi-WebUI and Suwayomi-VUI both ship as auto-updating built-in front-ends
- **OPDS support** — expose your library to any OPDS-compatible reader (`/api/opds/v1.2`)
- **Tracking** — syncs reading progress to MyAnimeList, AniList, MangaUpdates, and more
- **CBZ downloads** — chapters saved to disk in CBZ format for offline reading
- **Tachiyomi backup compatibility** — import/export backups in the standard format
- **FlareSolverr integration** — optional Cloudflare bypass for sources behind Bot-Fight mode

- Upstream repo: <https://github.com/Suwayomi/Suwayomi-Server>
- Docker source: <https://github.com/Suwayomi/docker-tachidesk>
- Container registry: `ghcr.io/suwayomi/suwayomi-server`
- Latest stable: v2.2.2100

## Architecture in one minute

- **Single Java container** — runs on JVM, multi-arch (amd64, arm64, ppc64le, s390x, riscv64)
- Serves the web UI and API on **`:4567`** by default
- Data stored in `/home/suwayomi/.local/share/Tachidesk` inside the container
- Optional **FlareSolverr** sidecar for Cloudflare bypass

## Compatible install methods

| Infra     | Runtime          | Notes                                              |
| --------- | ---------------- | -------------------------------------------------- |
| Single VM | Docker / Compose | **Most common** — official images provided        |
| Any       | Podman Quadlet   | Rootless option, template provided in docker repo |
| Linux     | OS packages      | AUR (Arch), deb (Debian/Ubuntu), NixOS module     |

## Inputs to collect

| Input            | Example                     | Phase       | Notes                                              |
| ---------------- | --------------------------- | ----------- | -------------------------------------------------- |
| Data directory   | `./data`                    | Persistence | Mounted at `/home/suwayomi/.local/share/Tachidesk` |
| Timezone         | `America/New_York`          | Config      | Uses TZ database name                              |
| Auth mode        | `basic_auth` / `ui_login`   | Security    | `none` by default; set before exposing publicly    |
| Auth credentials | username + password         | Security    | Only when AUTH_MODE is not `none`                  |
| Port             | `4567`                      | Network     | Default; override with BIND_PORT                   |
| FlareSolverr URL | `http://flaresolverr:8191`  | Optional    | Needed for some Cloudflare-protected sources       |

## Install via Docker Compose

```yaml
# docker-compose.yml
services:
  suwayomi:
    image: ghcr.io/suwayomi/suwayomi-server:stable
    container_name: suwayomi
    environment:
      - TZ=Etc/UTC
      # Uncomment to enable basic auth:
      # - AUTH_MODE=basic_auth
      # - AUTH_USERNAME=manga
      # - AUTH_PASSWORD=changeme
      # Uncomment to save downloads as CBZ:
      # - DOWNLOAD_AS_CBZ=true
    volumes:
      - ./data:/home/suwayomi/.local/share/Tachidesk
    ports:
      - "4567:4567"
    restart: unless-stopped
```

```bash
docker compose up -d
# Open http://localhost:4567 in your browser
```

## Install with FlareSolverr sidecar

```yaml
# docker-compose.yml
services:
  suwayomi:
    image: ghcr.io/suwayomi/suwayomi-server:stable
    container_name: suwayomi
    environment:
      - TZ=Etc/UTC
      - FLARESOLVERR_ENABLED=true
      - FLARESOLVERR_URL=http://flaresolverr:8191
    volumes:
      - ./data:/home/suwayomi/.local/share/Tachidesk
    ports:
      - "4567:4567"
    restart: unless-stopped

  flaresolverr:
    image: ghcr.io/thephaseless/byparr:latest
    container_name: flaresolverr
    init: true
    environment:
      - TZ=Etc/UTC
    restart: unless-stopped
```

## Post-install steps

1. Open `http://<host>:4567` - the bundled web UI loads automatically
2. Go to **Extensions** and install the sources you want
3. Go to **Sources** and browse or search for manga
4. Add manga to your **Library** and set an update schedule
5. Configure **Tracking** under Settings if you use MAL or AniList

## Key environment variables

| Variable                  | Default   | Description                                          |
| ------------------------- | --------- | ---------------------------------------------------- |
| `TZ`                      | `Etc/UTC` | Container timezone                                   |
| `AUTH_MODE`               | `none`    | `none`, `basic_auth`, `simple_login`, `ui_login`     |
| `AUTH_USERNAME`           | —         | Login username (when AUTH_MODE is set)               |
| `AUTH_PASSWORD`           | —         | Login password (when AUTH_MODE is set)               |
| `DOWNLOAD_AS_CBZ`         | `false`   | Save downloaded chapters as CBZ files                |
| `AUTO_DOWNLOAD_CHAPTERS`  | `false`   | Auto-download new chapters on library update         |
| `EXTENSION_REPOS`         | `[]`      | Extra extension repos (JSON array of URLs)           |
| `FLARESOLVERR_ENABLED`    | `false`   | Enable FlareSolverr for Cloudflare bypass            |
| `FLARESOLVERR_URL`        | —         | URL of the FlareSolverr or Byparr container          |
| `BIND_PORT`               | `4567`    | Port the server listens on                           |

## Notes

- Settings changed via the web UI are persisted in the data directory; environment variables override UI settings on each restart
- `stable` tag is recommended for production use; `preview` receives more frequent updates
- The data directory contains extensions, downloads, the database, and backups — back it up regularly
- Tachiyomi/Mihon mobile app can connect to Suwayomi as a remote source via the Suwayomi extension
