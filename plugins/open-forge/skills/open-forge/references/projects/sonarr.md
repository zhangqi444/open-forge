---
name: Sonarr
description: Smart PVR for TV shows. Monitors RSS feeds, detects new episodes of your tracked series, grabs them from Usenet (SABnzbd/NZBGet) or torrents (qBittorrent/Deluge/Transmission), renames + sorts into your library, notifies Plex/Jellyfin/Kodi. Part of the "arr" stack. .NET, cross-platform. GPL-3.0.
---

# Sonarr

Sonarr is the TV-show half of the "arr" stack (Radarr=movies, Lidarr=music, Readarr=books, Prowlarr=indexer aggregator). You add shows, Sonarr monitors RSS feeds from your indexers, and when new episodes appear that match your quality profile, it sends them to your download client (SABnzbd, NZBGet, qBittorrent, Deluge, Transmission, …), then renames + moves files to your library per your naming scheme, and notifies Plex/Jellyfin/Emby/Kodi.

Not a downloader itself; orchestrates indexers + download clients + media servers. Common in `arr` stacks alongside Radarr + Prowlarr + qBittorrent + Plex.

- Upstream repo: <https://github.com/Sonarr/Sonarr>
- Website: <https://sonarr.tv>
- Wiki: <https://wiki.servarr.com/sonarr>
- FAQ: <https://wiki.servarr.com/sonarr/faq>
- API docs: <https://sonarr.tv/docs/api>
- Forums: <https://forums.sonarr.tv>

**Upstream does not publish an official Docker image.** The de-facto standard is [LinuxServer.io's `lscr.io/linuxserver/sonarr`](https://docs.linuxserver.io/images/docker-sonarr/), used by nearly every "arr stack" tutorial.

## Compatible install methods

| Infra       | Runtime                                                     | Notes                                                                |
| ----------- | ----------------------------------------------------------- | -------------------------------------------------------------------- |
| Single VM   | Docker (`lscr.io/linuxserver/sonarr`)                       | **De-facto standard.** `PUID`/`PGID` for host permissions             |
| Single VM   | Docker (`ghcr.io/hotio/sonarr`)                             | Community alt; different conventions                                  |
| Single VM   | `.deb` from Sonarr v4/v5 repo                               | Upstream deb repo: <https://sonarr.tv/#downloads-v5>                  |
| Single VM   | macOS app / Windows binary                                  | Upstream native builds                                                |
| Kubernetes  | Community charts (truecharts, k8s-at-home)                  | Popular in home-lab K8s setups                                        |
| NAS         | Synology / QNAP / Unraid packages                           | Unraid apps template is highly maintained                             |

## Inputs to collect

| Input              | Example                                           | Phase     | Notes                                                             |
| ------------------ | ------------------------------------------------- | --------- | ----------------------------------------------------------------- |
| `PUID` / `PGID`    | `1000` / `1000`                                   | Runtime   | UID/GID inside container matches host owner of mounted dirs        |
| `TZ`               | `America/New_York`                                | Runtime   | Affects log timestamps + scheduled tasks                           |
| Port               | `8989:8989`                                       | Network   | Web UI                                                             |
| Config volume      | `/config`                                         | Data      | sonarr.db (SQLite), backups, logs, naming rules                    |
| TV library         | `/tv:/tv` (read/write)                            | Data      | Where renamed episodes land                                        |
| Downloads volume   | `/downloads:/downloads`                           | Data      | **Must be same path inside + mapped clients** for atomic moves     |
| Indexers           | via Prowlarr or manual                            | Config    | NZB indexers (NZBgeek, DrunkenSlug) or torrent (1337x, etc.)       |
| Download clients   | SABnzbd/NZBGet/qBittorrent/Deluge/Transmission    | Config    | Configured in Settings → Download Clients                          |

## Install via Docker (LinuxServer.io)

```yaml
services:
  sonarr:
    image: lscr.io/linuxserver/sonarr:4.0.17.2952-ls311    # pin; or use :latest for stable
    container_name: sonarr
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - ./config:/config
      - /mnt/media/tv:/tv
      - /mnt/downloads:/downloads   # MUST match path inside qBittorrent/etc.
    ports:
      - 8989:8989
```

Browse `http://<host>:8989`. Initial setup wizard:

1. Set a username/password + auth method (Forms is fine for LAN; use External auth behind Authelia/oauth2-proxy for internet-facing)
2. Pick "/tv" as root folder
3. Add a quality profile (HDTV-720p, WEBDL-1080p, Bluray-1080p, …)
4. Add download client (Settings → Download Clients → qBittorrent/SABnzbd)
5. Add indexers (Settings → Indexers) — easier via Prowlarr integration

## Path mapping — the #1 gotcha for "arr" stacks

Sonarr must see download paths **identically** to the download client. If qBittorrent writes to `/downloads/Show.S01E01/` inside its container, Sonarr must also see that file at `/downloads/Show.S01E01/`. Otherwise Sonarr does a slow copy across filesystems instead of an atomic rename.

Solution: use the same host path mapped to the same container path in both services:

```yaml
services:
  sonarr:
    volumes:
      - /mnt/downloads:/downloads       # same path as qbit
      - /mnt/media/tv:/tv
  qbittorrent:
    volumes:
      - /mnt/downloads:/downloads       # same path
```

Servarr docs on this: <https://wiki.servarr.com/sonarr/installation/docker>.

## Sonarr v4 vs v5

As of mid-2026, **v4 is stable and widely deployed**; **v5 is in `develop` branch** (hence `v5-develop` default branch on GitHub) with ongoing changes. v4 → v5 upgrade is automatic once v5 is promoted to stable; database migration runs on first startup.

Upstream wiki track: <https://wiki.servarr.com/sonarr/installation>.

## Data & config layout

Inside `/config`:

- `sonarr.db` — SQLite DB of series, episodes, history, queue
- `config.xml` — main settings (API key, auth, branch)
- `logs/` — rolling logs
- `Backups/` — scheduled automatic backups
- `naming.xml` (settings → media management) — file naming rules

Library (outside `/config`): Sonarr moves renamed files to `/tv/<Show Name (Year)>/Season N/<Show Name> - S01E01 - <Episode Title> <Quality>.ext`.

## Backup

Sonarr auto-backs up to `/config/Backups/` daily by default (configurable in Settings → General).

```sh
# Full config backup (includes sonarr.db + config.xml + custom scripts)
docker run --rm -v sonarr_config:/src -v "$PWD":/backup alpine \
  tar czf /backup/sonarr-config-$(date +%F).tgz -C /src .
```

Note: SQLite corrupts if copied while being written. Use Sonarr's built-in backup (System → Backup) or stop the container first.

## Upgrade

1. Releases: <https://github.com/Sonarr/Sonarr/releases>.
2. Docker (LSIO): `docker compose pull && docker compose up -d`.
3. Sonarr's internal updater is disabled in Docker images (image tag drives version).
4. **Branch setting in Settings → General → Branch** determines update channel: `main` (stable), `develop` (beta). Match your image tag.
5. **v4 → v5 migration** happens on first startup of the v5 image. Back up `sonarr.db` first.
6. Database migration is one-way; can't downgrade without the pre-migration backup.

## Gotchas

- **No official Docker image.** LinuxServer.io is de-facto standard. Hotio is a solid alternative. Never use random community images for a service that handles your API keys + indexer creds.
- **Path mapping matters.** Sonarr + download client must see downloads at the same path or "move after import" becomes a slow copy + doubles disk use during imports.
- **Hardlinks require same filesystem + same mount.** Sonarr can hardlink from `/downloads/` to `/tv/` only if both are on the same filesystem and the container sees both. Otherwise it copies, doubling disk usage during import.
- **API key in `/config/config.xml`.** Don't commit it to git. Prowlarr, Overseerr, Jellyseerr, Homepage, etc., need it — treat as a password.
- **Default authentication is OFF.** First-boot wizard nags you to set it. **Do it before exposing to internet.** There are bots scanning for unauthenticated arr instances.
- **Indexer search = rate-limited.** Most Usenet indexers throttle 5-20 API calls per day on free tier. Don't hit "Interactive Search" in a loop; use RSS instead.
- **Quality profiles + release profiles are different.** Quality = "I want 1080p Bluray". Release profile = "prefer REMUX, reject CAM, require HDR10". Both matter for sane selection.
- **Anime is weird.** Enable "Anime" series type for absolute-numbered releases (Sonarr handles AniDB IDs + absolute numbering).
- **Default SQLite is fine up to ~500 series.** Larger libraries benefit from WAL mode + periodic vacuum.
- **Logs grow.** Set log rotation (Settings → General → Logging).
- **"Unable to grab release"** is often a path-mapping or permission issue. Check `PUID`/`PGID` + that container user can write to `/downloads` + `/tv`.
- **Notifications** (Plex library update, Discord, Pushover) are per-show and global; configure both.
- **Custom scripts** run on events (`on-grab`, `on-download`, `on-rename`) — great for automation; bad if they're slow or flaky (they block the event).
- **Backup restore** is a drop-in replace of `/config` contents. Stop the container, swap, start.
- **Proxy Sonarr behind a URL base** if sharing a domain with other services. Set `urlBase` in Settings → General, update nginx `location /sonarr/ { proxy_pass http://sonarr:8989; }`.
- **Sonarr does NOT download anything itself.** It delegates to SABnzbd/qBittorrent/etc. Sonarr logs "grabbed" = handed off to client; check the client for actual download progress.
- **Alternatives worth knowing:**
  - **Radarr** — movies; same codebase fork
  - **Lidarr** (music) / **Readarr** (books) / **Whisparr** (adult) — other arrs
  - **Bazarr** — subtitle fetcher, pairs with Sonarr/Radarr
  - **Prowlarr** — one-stop indexer management for all arrs
  - **Jellyfin** / **Plex** / **Emby** — media servers downstream
  - **Overseerr** / **Jellyseerr** — user-facing "request a show" UI in front of Sonarr

## Links

- Repo: <https://github.com/Sonarr/Sonarr>
- Website: <https://sonarr.tv>
- Wiki: <https://wiki.servarr.com/sonarr>
- Docker install (wiki): <https://wiki.servarr.com/sonarr/installation/docker>
- LinuxServer image: <https://docs.linuxserver.io/images/docker-sonarr/>
- Hotio image: <https://hotio.dev/containers/sonarr/>
- API docs: <https://sonarr.tv/docs/api>
- FAQ: <https://wiki.servarr.com/sonarr/faq>
- Releases: <https://github.com/Sonarr/Sonarr/releases>
- Download (v5): <https://sonarr.tv/#downloads-v5>
- Forums: <https://forums.sonarr.tv>
- Subreddit: <https://reddit.com/r/sonarr>
