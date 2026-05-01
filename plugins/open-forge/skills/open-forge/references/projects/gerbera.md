---
name: Gerbera
description: "UPnP/DLNA media server for home network streaming. C++. Docker + packages. gerbera/gerbera. Web UI, inotify rescans, transcoding scripts, Last.fm scrobbling, SQLite/MariaDB/PostgreSQL."
---

# Gerbera

**UPnP/DLNA media server** — stream your digital media through your home network to any UPnP/DLNA-compatible device (smart TVs, AV receivers, game consoles, mobile players). Web UI with database tree view, metadata extraction from audio/video/images, flexible transcoding via scripts, automatic inotify directory rescans, user-defined server layouts, Last.fm scrobbling, and external URL support.

Fork of MediaTomb. Maintained by the **Gerbera community**.

- Upstream repo: <https://github.com/gerbera/gerbera>
- Docs: <https://docs.gerbera.io>
- Docker Hub: <https://hub.docker.com/r/gerbera/gerbera>
- IRC: `#gerbera` on libera.chat

## Architecture in one minute

- **C++** binary (compiled)
- **SQLite 3** (default DB), optional MySQL/MariaDB or PostgreSQL
- Web UI on port **49152** (default UPnP); configurable
- UPnP discovery via SSDP multicast — needs host network or SSDP relay for Docker
- Metadata extraction via TagLib, libexif, libmatroska, ffmpeg (optional)
- Transcoding: FFmpeg via external scripts
- Resource: **low** — compiled C++ binary, efficient for media streaming

## Compatible install methods

| Infra             | Runtime                  | Notes                                                                                     |
| ----------------- | ------------------------ | ----------------------------------------------------------------------------------------- |
| **Docker**        | `gerbera/gerbera`        | **Easiest** — Docker Hub; multi-arch (amd64, arm64, arm/v7)                               |
| **Package**       | distro packages          | Available in most Linux distros via repology; often an older version                      |
| **Source**        | CMake + C++              | Latest features; see docs for compile dependencies                                        |
| **Unraid/Synology** | Community packages     | Available for NAS platforms                                                               |

## Inputs to collect

| Input                    | Example                           | Phase    | Notes                                                                                      |
| ------------------------ | --------------------------------- | -------- | ------------------------------------------------------------------------------------------ |
| Media library path       | `/media`                          | Storage  | Mount into container; Gerbera scans and serves this                                        |
| Config dir               | `./config:/var/run/gerbera`       | Config   | Persistent config + SQLite DB                                                              |
| UID/GID                  | `1000:1000`                       | Security | Run container as media-owner user; use `PGID/PUID` or `--user`                            |
| Network mode             | `host` or macvlan                 | Network  | UPnP SSDP multicast doesn't cross Docker bridge; host networking recommended               |

## Install via Docker

```yaml
services:
  gerbera:
    image: gerbera/gerbera:latest
    container_name: gerbera
    network_mode: host           # required for UPnP SSDP discovery
    volumes:
      - ./gerbera-config:/var/run/gerbera    # config + SQLite DB
      - /path/to/media:/media:ro             # your media library (read-only)
    environment:
      - PGID=1000
      - PUID=1000
    restart: unless-stopped
```

Visit `http://<host>:49152` (default Gerbera web UI port).

## First boot

1. Deploy container.
2. Visit the web UI → first run wizard sets up:
   - Friendly server name (shown to UPnP clients)
   - Database path (auto-created SQLite by default)
3. Add media directories: Web UI → Database → Filesystem → navigate to `/media` → right-click → Add to Autoscan.
4. Configure autoscan mode: **Inotify** (real-time; recommended on Linux) or **Timed** (periodic).
5. Run initial scan → content appears in the database.
6. Open a UPnP client (TV, VLC, Kodi, etc.) on the same network → discover Gerbera → browse and play.
7. Optionally configure transcoding (for devices that can't play certain formats natively).
8. Optionally enable Last.fm scrobbling in `config.xml`.

## Data & config layout

- `./gerbera-config/config.xml` — main config (server name, scan dirs, transcoding, Last.fm)
- `./gerbera-config/gerbera.db` — SQLite media database (or MySQL/PG if configured)
- Media files: read from mounted volumes; not copied

## Backup

```sh
docker compose stop gerbera
sudo tar czf gerbera-$(date +%F).tgz gerbera-config/
docker compose start gerbera
```

Contents: config + media database (metadata/scan state). The media files themselves live in your library and are backed up separately.

## Upgrade

1. Releases: <https://github.com/gerbera/gerbera/releases>
2. `docker compose pull && docker compose up -d`

## Gotchas

- **`network_mode: host` is essential for UPnP.** UPnP uses SSDP multicast (`239.255.255.250:1900`) for device discovery. Docker bridge mode blocks multicast — devices on your LAN won't find Gerbera. Use `network_mode: host` or configure a macvlan network with a dedicated LAN IP.
- **Inotify rescans need kernel inotify support.** On most Linux hosts this is available; inside containers, `/proc/sys/fs/inotify/max_user_watches` may need increasing if you have large libraries (`echo 524288 > /proc/sys/fs/inotify/max_user_watches` on the host).
- **UID/GID must match media file ownership.** If your media files are owned by UID 1000 on the host, the Gerbera container must run as that UID or files will be inaccessible. Set `PUID`/`PGID` in environment.
- **First-run config.xml is generated automatically.** If `config.xml` doesn't exist, Gerbera creates one with defaults. Edit it for advanced settings (database type, transcoding profiles, Last.fm credentials). The web UI also exposes most settings.
- **Transcoding is via external scripts + ffmpeg.** Install ffmpeg in the image (or use the `gerbera/gerbera:ffmpeg` tag if available) and configure transcoding profiles in `config.xml`. Profiles convert e.g. FLAC → MP3 for devices that can't play FLAC natively.
- **MySQL/PostgreSQL.** Supported and recommended for large libraries or shared installs. Set `<database driver="mysql">` in `config.xml`.
- **External URLs** — add internet streams (radio, podcasts) as virtual items in the Gerbera database, served to UPnP clients as if they were local files.
- **Fork of MediaTomb.** If you're migrating from MediaTomb, config files are largely compatible. MediaTomb is unmaintained.
- **Port 49152 is the default UPnP HTTP port.** It's configurable in `config.xml` — change if another service conflicts.

## Project health

Active C++ development, Docker Hub (multi-arch), packages in major Linux distros, repology tracking, CI (GitHub Actions). Community-maintained; GPL license.

## UPnP-media-server-family comparison

- **Gerbera** — C++, UPnP/DLNA, inotify, transcoding scripts, Last.fm, Docker + packages
- **Jellyfin** — .NET, full media server + client apps, transcoding, multi-user; more features but heavier
- **Plex** — proprietary, media server + client ecosystem, cloud features; account required
- **Emby** — .NET, similar to Jellyfin (Jellyfin is the OSS fork of Emby)
- **MiniDLNA (ReadyMedia)** — C, minimal UPnP/DLNA server; no web UI; simpler
- **Kodi** — media player with UPnP server mode; client-first, not a headless server

**Choose Gerbera if:** you want a mature, dedicated UPnP/DLNA media server for streaming to smart TVs and AV receivers on your LAN, without the overhead of Jellyfin/Plex.

## Links

- Repo: <https://github.com/gerbera/gerbera>
- Docs: <https://docs.gerbera.io>
- Docker Hub: <https://hub.docker.com/r/gerbera/gerbera>
- Jellyfin (feature-richer alt): <https://jellyfin.org>
- MiniDLNA (minimal alt): <https://sourceforge.net/projects/minidlna/>
