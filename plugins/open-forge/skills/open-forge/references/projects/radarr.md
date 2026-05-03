---
name: Radarr
description: Smart PVR for movies. Sister project to Sonarr (TV shows); monitors indexers for movies you track, grabs them via your download client, renames + sorts into your library. Part of the "arr" stack. .NET, cross-platform. GPL-3.0.
---

# Radarr

Radarr is the movie-half of the "arr" stack. Same core codebase lineage as Sonarr (Radarr was forked from Sonarr ~2017). You add movies you want, Radarr monitors indexers (Usenet + torrent) via Prowlarr or direct integrations, grabs them via your download client (SABnzbd, NZBGet, qBittorrent, Deluge, Transmission), then renames + moves to your library, and pokes Plex/Jellyfin/Kodi to refresh.

Typically deployed together with: **Sonarr** (TV), **Prowlarr** (indexers), **Bazarr** (subtitles), **qBittorrent** or **SABnzbd** (download client), **Plex/Jellyfin** (media server), **Overseerr/Jellyseerr** (request UI).

- Upstream repo: <https://github.com/Radarr/Radarr>
- Website: <https://radarr.video>
- Wiki: <https://wiki.servarr.com/radarr>
- FAQ: <https://wiki.servarr.com/radarr/faq>
- API docs: <https://radarr.video/docs/api>
- Forums: <https://forums.sonarr.tv/c/radarr/22>  (shared with Sonarr)

**Upstream does not publish an official Docker image.** Same ecosystem norm as Sonarr — use LinuxServer.io or Hotio.

## Compatible install methods

| Infra       | Runtime                                                     | Notes                                                                     |
| ----------- | ----------------------------------------------------------- | ------------------------------------------------------------------------- |
| Single VM   | Docker (`lscr.io/linuxserver/radarr`)                       | **De-facto standard**                                                      |
| Single VM   | Docker (`ghcr.io/hotio/radarr`)                             | Community alt                                                              |
| Single VM   | `.deb` from Radarr repo                                     | <https://radarr.video/#download>                                           |
| Single VM   | macOS app / Windows binary                                  | Upstream native                                                            |
| Kubernetes  | Community charts (truecharts, k8s-at-home)                  | Home-lab K8s setups                                                        |
| NAS         | Synology / QNAP / Unraid                                    | Unraid template highly maintained                                          |

## Inputs to collect

| Input              | Example                                           | Phase     | Notes                                                             |
| ------------------ | ------------------------------------------------- | --------- | ----------------------------------------------------------------- |
| `PUID` / `PGID`    | `1000` / `1000`                                   | Runtime   | Container UID/GID matches host owner of mounts                     |
| `TZ`               | `America/New_York`                                | Runtime   | For log timestamps + scheduled tasks                               |
| Port               | `7878:7878`                                       | Network   | Web UI (Sonarr's is 8989)                                          |
| Config volume      | `/config`                                         | Data      | radarr.db, backups, logs                                           |
| Movies library     | `/movies`                                         | Data      | Where renamed files land                                           |
| Downloads volume   | `/downloads:/downloads`                           | Data      | **Must match the same path inside download client container**      |
| Indexers           | via Prowlarr (recommended) or direct Torznab       | Config    | Newznab (Usenet) + Torznab (torrents)                              |
| Download client    | SAB/NZBGet/qBit/Deluge/Transmission                | Config    | Settings → Download Clients                                        |

## Install via Docker (LinuxServer.io)

```yaml
services:
  radarr:
    image: lscr.io/linuxserver/radarr:6.1.1.10360-ls301   # pin; check https://github.com/linuxserver/docker-radarr/releases
    container_name: radarr
    restart: unless-stopped
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
    volumes:
      - ./config:/config
      - /mnt/media/movies:/movies
      - /mnt/downloads:/downloads         # MUST match qBittorrent's container path
    ports:
      - 7878:7878
```

Browse `http://<host>:7878`. First-run wizard:

1. **Pick an auth method** — Forms + strong password minimum; External for Authelia/oauth2-proxy
2. Add **Root Folder** = `/movies`
3. Add **Download Client** — Settings → Download Clients → qBittorrent (or whatever)
4. Add **Indexers** — easier via **Prowlarr → Applications → Radarr**; otherwise Settings → Indexers
5. **Quality Profile** — e.g. "Bluray-1080p" with Bluray/WEBDL-1080p included, lower rejected
6. Start adding movies

## Path mapping (the arr-stack gotcha)

Same rule as Sonarr: Radarr + download client must see download paths **identically** so atomic move + hardlinks work. Example:

```yaml
services:
  radarr:
    volumes:
      - /mnt/downloads:/downloads        # same path as qBit
      - /mnt/media/movies:/movies
  qbittorrent:
    volumes:
      - /mnt/downloads:/downloads        # same path as Radarr
```

Without same-path: "import" does a slow copy, doubling disk use during the copy. Hardlinks fail silently → library uses 2× storage.

See <https://wiki.servarr.com/radarr/installation/docker>.

## Data & config layout

Inside `/config`:

- `radarr.db` — SQLite (movies, history, queue)
- `config.xml` — main settings (API key, auth, branch)
- `logs/` — rolling logs
- `Backups/` — scheduled auto-backups
- `naming.xml` (via UI) — file naming rules

Default naming template: `{Movie Title} ({Release Year})/{Movie Title} ({Release Year}) {Edition-{Edition Tags}} [{Quality Title}].{ext}`.

## Backup

Auto-backup to `/config/Backups/` daily by default.

```sh
# Full config volume backup
docker run --rm -v radarr_config:/src -v "$PWD":/backup alpine \
  tar czf /backup/radarr-config-$(date +%F).tgz -C /src .
```

SQLite corrupts if copied mid-write — prefer Radarr's built-in **System → Backup** or stop the container first.

## Upgrade

1. Releases: <https://github.com/Radarr/Radarr/releases>.
2. Docker (LSIO): `docker compose pull && docker compose up -d`. The internal updater is disabled; image tag drives version.
3. **Branch** setting (Settings → General → Branch) = `master` (stable), `develop`, `nightly`. Match your image tag.
4. **Radarr v4 → v5 migration** happens on first startup of v5 image. Back up `radarr.db` first.
5. DB migration is one-way; no downgrade without the pre-migration backup.
6. Frequent point releases (often weekly). Plan a review cadence.

## Gotchas

- **No official Docker image.** LinuxServer.io is default; Hotio is the alternative.
- **Path mapping is the #1 mistake.** Same path inside both containers or no hardlinks + slow copies.
- **Hardlinks need same filesystem + same mount**. If `/downloads` and `/movies` are on different filesystems, Radarr can't hardlink; it copies.
- **API key in `/config/config.xml`** — treat as a password; used by Prowlarr, Overseerr, Homepage.
- **Auth is OFF by default.** Set it in the first-run wizard BEFORE exposing. Bots scan for unauth'd arr instances.
- **Custom Formats** (v4+) are Radarr's richer replacement for "release profiles". Use them to prefer REMUX over WEBDL, reject CAM, require HDR, etc.
- **TMDB is the default metadata source.** TMDB API is free but rate-limited; occasional "failed to import movie" = retry later.
- **Movie renaming is disabled by default.** Enable in Settings → Media Management → "Rename Movies" if you want Radarr to organize.
- **Minimum Availability** setting (per movie) controls when Radarr searches: Announced, In Cinemas, Released, TBA. Wrong = Radarr searches too early (nothing to find) or too late.
- **Collection support** (since v4): Radarr can track whole movie collections (e.g., all MCU films) — enable at Settings → Profiles.
- **Stand-alone movies search vs RSS**. RSS is the normal path (indexers push new releases as they appear). Manual search = immediate, but burns indexer API calls — rate-limited.
- **Notifications** (Plex/Jellyfin library refresh, Discord, Telegram) are configured per-connection in Settings → Connect.
- **Custom scripts on events** (`on-grab`, `on-download`) are powerful but block the event loop if slow.
- **`Lock` on a movie** prevents quality upgrades — useful when you've got the best you'll ever have.
- **Default SQLite is fine up to ~5000 movies.** Larger libraries benefit from WAL mode + periodic VACUUM.
- **Queue stuck on "waiting"?** Usually a download-client connection issue or a category mismatch. Check Settings → Download Clients → Test.
- **URL base** for reverse-proxy setups: Settings → General → URL Base = `/radarr`, then nginx `location /radarr/ { proxy_pass http://radarr:7878; }`.
- **v6 is the current stable branch** (v5 promoted to stable, then v6 followed). Migration from prior versions is automatic on first boot; can't downgrade.
- **Radarr doesn't actually download anything.** It tells the download client to grab a release. Download progress = check your client, not Radarr.
- **Alternatives worth knowing:**
  - **Sonarr** — TV shows (same ecosystem)
  - **Lidarr/Readarr/Whisparr** — other content types
  - **Watcher3** — less popular movie PVR
  - **CouchPotato** — DEAD; do not use
  - **Stash** — for adult content (separate from Whisparr)
- **License**: GPL-3.0.

## Links

- Repo: <https://github.com/Radarr/Radarr>
- Website: <https://radarr.video>
- Wiki: <https://wiki.servarr.com/radarr>
- Docker install (wiki): <https://wiki.servarr.com/radarr/installation/docker>
- LinuxServer image: <https://docs.linuxserver.io/images/docker-radarr/>
- Hotio image: <https://hotio.dev/containers/radarr/>
- API docs: <https://radarr.video/docs/api>
- Custom Formats: <https://wiki.servarr.com/radarr/settings#custom-formats>
- Trash Guides (recommended custom formats): <https://trash-guides.info/Radarr/>
- Releases: <https://github.com/Radarr/Radarr/releases>
- Download: <https://radarr.video/#download>
- Forums: <https://forums.sonarr.tv/c/radarr/22>
- Subreddit: <https://reddit.com/r/radarr>
