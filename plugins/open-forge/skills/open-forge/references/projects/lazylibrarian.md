# LazyLibrarian

LazyLibrarian is a program to follow authors and automatically grab metadata and books for all your digital reading needs. It uses a combination of Goodreads, Librarything, and optionally Google Books as sources for author and book info, and integrates with Calibre for ebook management and conversion.

- **Official site / docs:** https://lazylibrarian.gitlab.io/
- **GitLab:** https://gitlab.com/LazyLibrarian/LazyLibrarian
- **Docker image:** `lscr.io/linuxserver/lazylibrarian:latest` (LinuxServer.io maintained)
- **License:** Open-source

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | LinuxServer.io image; amd64 + arm64 |
| Any Docker host | docker run | Single container; same params |

---

## Inputs to Collect

### Deploy Phase
| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `PUID` | Yes | `1000` | UID of user to run as (for file permissions) |
| `PGID` | Yes | `1000` | GID of user to run as |
| `TZ` | Yes | `Etc/UTC` | Timezone (e.g. `America/New_York`) |
| `DOCKER_MODS` | No | — | Optional mods: `linuxserver/mods:universal-calibre` for Calibredb; `linuxserver/mods:lazylibrarian-ffmpeg` for audiobook conversion |

### Volume Mounts
| Path | Required | Description |
|------|----------|-------------|
| `/config` | Yes | LazyLibrarian config and database |
| `/downloads` | Yes | Download destination directory |
| `/books` | No | Books library directory |

---

## Software-Layer Concerns

### Config
- All config done through the web UI at `http://<host>:5299/home`
- Config file stored in `/config`
- Optional Calibredb integration: enable `DOCKER_MODS=linuxserver/mods:universal-calibre`, then set calibredb path to `/usr/bin/calibredb` in Settings > Processing

### Data Directories
- `/config` — LazyLibrarian config, database, logs (must be persisted)
- `/downloads` — Where books are downloaded before import
- `/books` — (Optional) Your existing books library

### Ports
- `5299` — Web UI

---

## Minimal docker-compose.yml

```yaml
services:
  lazylibrarian:
    image: lscr.io/linuxserver/lazylibrarian:latest
    container_name: lazylibrarian
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      # Optional mods (uncomment as needed):
      # - DOCKER_MODS=linuxserver/mods:universal-calibre|linuxserver/mods:lazylibrarian-ffmpeg
    volumes:
      - ./config:/config
      - ./downloads:/downloads
      - ./books:/books  # optional
    ports:
      - 5299:5299
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
docker compose pull lazylibrarian
docker compose up -d lazylibrarian
```

Config and database persist in the `/config` volume.

---

## Gotchas

- **PUID/PGID matter:** Set these to match the owner of your books and downloads directories; mismatches cause permission errors on download/import
- **Calibredb integration (64-bit only):** The `universal-calibre` mod adds Calibre CLI tools; not available on arm platforms; set the path in Settings > Processing > Calibredb import program > `/usr/bin/calibredb`
- **ffmpeg for audiobooks:** Add `linuxserver/mods:lazylibrarian-ffmpeg` mod and enable in Settings > Processing > External Programs > ffmpeg path = `ffmpeg`
- **API key setup:** LazyLibrarian needs API keys for Goodreads, Google Books, and/or LibraryThing to search book metadata — configure in the web UI under Settings > Searching
- **Download client required:** LazyLibrarian requires a connected download client (NZBGet, SABnzbd, qBittorrent, etc.) and indexer (NZBHydra, Jackett, Prowlarr, etc.) to actually download books
- **Initial author scan:** On first run, add your existing `/books` path in settings and run "Scan Books Folder" to import existing library

---

## References
- LinuxServer.io image docs: https://github.com/linuxserver/docker-lazylibrarian
- LazyLibrarian docs: https://lazylibrarian.gitlab.io/
- LinuxServer.io Docker guide: https://docs.linuxserver.io/general/docker-compose
