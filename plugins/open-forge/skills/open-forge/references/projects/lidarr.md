---
name: Lidarr
description: "Music collection manager for Usenet + BitTorrent — the *arr app for music. Auto-monitors RSS feeds for new tracks from favorite artists, grabs/sorts/renames, auto-upgrades quality. Full SABnzbd/NZBGet/qBittorrent integration + Plex/Kodi. .NET. GPL-3.0."
---

# Lidarr

Lidarr is **the music member of the \*arr family** (Sonarr for TV / Radarr for movies / Readarr for books / Bazarr for subtitles / Prowlarr for indexers / Whisparr for adult). Auto-watches your favorite artists, grabs new releases as they appear on your Usenet or torrent indexers, sorts + renames by configurable templates, auto-upgrades to better formats (MP3 → FLAC) when available, integrates with Plex/Jellyfin/Kodi/Emma for media-server notifications + library updates.

Developed by the **Lidarr team** — part of the **Servarr ecosystem** (shared tooling, shared docs, shared installer patterns).

> **⚠️ Active upstream notice (from README):**
>
> *"The Lidarr Metadata Server is recovering and rebuilding the cache which is impacting adding artists, library imports, etc. Please follow [GHI 5498](https://github.com/Lidarr/Lidarr/issues/5498) or see Discord for details."*
>
> Metadata server health varies; Lidarr relies on this central service for artist/album info. Occasional outages affect new-artist adds.

Features:

- **Cross-platform**: Windows, Linux, macOS, FreeBSD, Raspberry Pi
- **RSS monitoring** — new track detection from indexers
- **Library scan** + download missing tracks
- **Quality upgrade** — auto re-grab when better format appears
- **Automatic failure handling** — try another release if current fails
- **Manual search** — see all available releases + choose
- **Fully configurable renaming** — with templates
- **Usenet**: SABnzbd + NZBGet
- **Torrent**: qBittorrent, Transmission, Deluge, rTorrent, ruTorrent
- **Media server integrations**: Kodi, Plex, Jellyfin, Emby — notifications + library updates
- **Specials + multi-album** support
- **Beautiful modern UI**

- Upstream repo: <https://github.com/Lidarr/Lidarr>
- Docs / Wiki: <https://wiki.servarr.com/lidarr>
- Discord: <https://lidarr.audio/discord>
- LinuxServer.io image: `lscr.io/linuxserver/lidarr`
- Hotio image: `hotio.dev/lidarr`

## Architecture in one minute

- **.NET (C#)** backend — Mono/.NET runtime
- **SQLite** by default (MariaDB option for scale)
- **React frontend**
- **Communicates with indexers** (RSS + search APIs) + **download clients** (Usenet/torrent) + **media servers** (Plex/etc.)
- **Metadata server** — centrally hosted (not user-deployable); Lidarr queries for artist/album info
- **Resource**: 300-500 MB RAM; heavier during library scans

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker (`lscr.io/linuxserver/lidarr` or `hotio/lidarr`)**        | **Most popular**                                                                   |
| Raspberry Pi       | arm32/arm64 Docker                                                         | Works; library scans can be slow                                                                       |
| Bare-metal         | .NET runtime + release tarball + systemd                                                      | Supported                                                                                               |
| Windows            | .exe installer                                                                                | First-party                                                                                                              |
| Unraid / Synology / QNAP | Docker packages                                                                                          | Wide ecosystem support                                                                                                                       |
| Kubernetes         | Community manifests (k8s-at-home / bjw-s)                                                                                          | Popular for homelab K8s                                                                                                                                      |

## Inputs to collect

| Input                      | Example                                                 | Phase        | Notes                                                                    |
| -------------------------- | ------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain                     | `lidarr.home.lan`                                            | URL          | Reverse proxy optional                                                           |
| Music library path         | `/music`                                                     | Storage      | Where Lidarr organizes your library                                                      |
| Download client            | SABnzbd / qBittorrent etc.                                             | Download     | Already configured + running                                                                             |
| Indexers                   | via **Prowlarr** (recommended)                                                     | Indexers     | Prowlarr syncs indexers across all *arr apps                                                                             |
| Plex/Jellyfin              | Media server URL + API key                                                                | Integration  | For post-import library refresh                                                                                                         |
| Admin                      | first-run sets Form Auth                                                                          | Auth         | Strong password                                                                                                                         |

## Install via Docker (LinuxServer.io image)

```yaml
services:
  lidarr:
    image: lscr.io/linuxserver/lidarr:latest            # pin specific version in prod
    container_name: lidarr
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Los_Angeles
    volumes:
      - ./config:/config
      - /data/music:/music
      - /data/downloads:/downloads
    ports:
      - "8686:8686"
```

Browse `http://<host>:8686/` → first-run wizard → set authentication.

## First boot

1. Enable authentication (default: Forms). **Don't skip** — even on LAN.
2. Media management → set music folder + naming templates
3. Download clients → add SABnzbd / qBittorrent (same network, same user)
4. Indexers → **best practice: deploy Prowlarr** and let it push indexers to all *arr apps
5. Metadata → verify MusicBrainz sync
6. Add first artist → verify add works + first track triggers
7. Integrate Plex/Jellyfin for library refresh
8. Put behind reverse proxy if exposing

## Data & config layout

- `/config/` — Lidarr's config + SQLite DB + logs + backups
- `/music/` — your library
- `/downloads/` — download client's download path (shared with Lidarr so atomic moves work)

**Critical**: download client + Lidarr **must share the same mount path** for atomic (rename not copy) imports. If `/downloads` on Lidarr != `/downloads` on SABnzbd, imports fall back to slow file copies.

## Backup

- **Lidarr config**: built-in backup feature (Settings → System → Backup); also just tar `/config/`
- **Music library**: separate (much larger); your standard file backup

```sh
sudo tar czf lidarr-config-$(date +%F).tgz config/
```

## Upgrade

1. Releases: <https://github.com/Lidarr/Lidarr/releases>. Active.
2. Docker: bump tag → restart → migrations auto.
3. Hotio uses `nightly`/`testing`/`latest` channels; LSIO uses `latest`/`nightly`.
4. **Back up `/config/` before major upgrades** — Lidarr's internal backup feature also fine.

## Gotchas

- **Metadata-server outages** (current per README) — Lidarr depends on a centrally-hosted metadata service for artist/album data. When it's down, new-artist adds and library imports may fail. This isn't your problem to fix; wait for upstream notice. Watch <https://github.com/Lidarr/Lidarr/issues/5498>.
- **MusicBrainz + metadata quality**: music metadata is messier than TV/movies. Live versions, remasters, remixes, multiple pressings — Lidarr does best-effort but expect to manually correct edge cases.
- **Download-path shared volume** (same as all *arr apps): for atomic imports (move not copy), Lidarr + download client must see the same path at the same mount point. Misconfiguration = 30GB FLAC albums getting double-copied.
- **Prowlarr is strongly recommended**: managing indexers per-*arr-app is tedious + error-prone. Prowlarr is the centralized indexer manager; set up indexers once, pushes to Lidarr/Sonarr/Radarr/etc.
- **Usenet vs Torrent**: Usenet (SABnzbd/NZBGet) is faster + more reliable for commonly-available releases; requires paid provider + indexer subscription. Torrent is free but you seed + need working seeders. Many users do both.
- **Quality profiles**: define what formats you want (MP3 320 / FLAC / etc.) + upgrade order. Mis-configured = grabbing too many dupes or too few.
- **Legal disclaimer**: (same as Sonarr/Radarr/Readarr etc.) downloading copyrighted music you don't own is copyright infringement in most jurisdictions. Lidarr is a tool; use responsibly.
- **VPN recommended for torrents**: privacy on torrents = VPN on download client container (Gluetun is a popular choice). Doesn't apply to Usenet.
- **Free indexers vs paid**: paid Usenet providers and paid torrent trackers typically have far better availability. Free indexers = fill-in.
- **Python/Mono history**: Lidarr runs on .NET Core / .NET 6+ now; historical reference to Mono is obsolete. Current releases use modern .NET.
- **Community support**: Discord is more active than GitHub Issues (GH is explicitly bugs+features only per README).
- **NAS integration**: LSIO images + PUID/PGID make NAS deployment smooth.
- **License**: **GPL-3.0** (all Servarr apps).
- **Alternatives worth knowing:**
  - **Headphones** — older Python alternative; largely abandoned
  - **beets** — CLI music organizer (no auto-download; pairs well with manual sourcing)
  - **Navidrome** — subsonic music server; not a collection manager
  - **SoulseekQt** / **Nicotine+** — P2P music search; manual
  - **Plex + Tidabl / PlexAmp** — streaming-subscription integration
  - **Choose Lidarr if:** *arr ecosystem + auto-download + integrated with Plex/Jellyfin + quality upgrade.
  - **Choose beets if:** CLI power-user + tagging/organizing + manual sourcing.

## Links

- Repo: <https://github.com/Lidarr/Lidarr>
- Wiki: <https://wiki.servarr.com/lidarr>
- Discord: <https://lidarr.audio/discord>
- Releases: <https://github.com/Lidarr/Lidarr/releases>
- LinuxServer image: <https://docs.linuxserver.io/images/docker-lidarr/>
- Hotio image: <https://hotio.dev/containers/lidarr/>
- Prowlarr (indexer manager): <https://github.com/Prowlarr/Prowlarr>
- MusicBrainz: <https://musicbrainz.org>
- beets (alt): <https://beets.io>
- Navidrome (music server): <https://www.navidrome.org>
- Audiobookshelf: <https://www.audiobookshelf.org>
