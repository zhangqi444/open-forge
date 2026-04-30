---
name: Ampache
description: "Web-based audio/video streaming server + personal music library + Subsonic API compatibility. Long-running project (20+ years). PHP + MySQL/MariaDB. AGPL-3.0. Self-hosted Spotify-for-your-own-collection with mobile-app ecosystem via Subsonic API."
---

# Ampache

Ampache is **"your personal Spotify — streaming the music you actually own"** — a PHP web application that scans your music + video library, extracts metadata from tags, and serves streams to any device via web UI or a huge ecosystem of Subsonic-API-compatible mobile/desktop apps. One of the oldest still-active self-hosted music servers (active since ~2001); ecosystem of mature mobile clients (DSub, Ultrasonic, Substreamer, Symfonium, play:Sub, etc.).

Built + maintained by **Ampache org** (community; active re-engagement per 2025 README "INCREASED CONTRIBUTIONS" notice; Ampache 8 in development). **AGPL-3.0**. Stable release: release6; Ampache 7 on PHP 8.4 released; Ampache 8 planned.

Use cases: (a) **self-hosted music streaming** for personal library (b) **audio book server** (c) **podcast library** self-host (d) **family music sharing** — multiple users each with their library access (e) **Subsonic-API-compatible backend** to use alongside existing mobile clients (f) **DJ library management** + preview streaming.

Features:

- **Music + video streaming** from local filesystem
- **Subsonic API** — compat with DSub, Ultrasonic, play:Sub, Substreamer, Symfonium, Audinaut, Jamstash, etc.
- **Playlists** — manual + smart (rule-based)
- **Multi-user** with per-user library access
- **Transcoding** — serve various formats per-client
- **Cataloging** — scan folders; handles metadata refresh
- **Scrobbling** — Last.fm / Libre.fm
- **Podcasts** — subscribe + download
- **Radio station links**
- **Album art management**
- **Plugins** — LyricFind, Flickr, etc.
- **LDAP auth**
- **REST + XML APIs** for integrations

- Upstream repo: <https://github.com/ampache/ampache>
- Homepage: <https://ampache.org>
- Docs: <https://ampache.org/docs/>
- Installation guide: <https://ampache.org/docs/installation/>
- API docs: <https://ampache.org/api/>
- Docker: <https://hub.docker.com/r/ampache/ampache>
- Troubleshooting: <https://ampache.org/docs/help/troubleshooting/>

## Architecture in one minute

- **PHP 8.2+ / 8.3 / 8.4 / 8.5** — modern release requirements
- **MySQL 5.7+ / MariaDB** — metadata DB (library catalog, playlists, users, scrobble history)
- **Apache / nginx / lighttpd** — web server
- **ImageMagick** for album art; **ffmpeg** for transcoding (optional but recommended)
- **Resource**: moderate — 512MB-2GB RAM; DB scales with library size; disk dominated by your music
- **Port 80/443** via web server

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`ampache/ampache`** (multi-arch)                              | **Simplest path**                                                               |
| Bare-metal         | Apache/nginx + PHP + MariaDB                                              | Traditional LAMP install                                                                   |
| Release tarball    | Download `release6` or release7 tarball → extract → web server                 | Classic path                                                                               |
| FreeBSD / OpenBSD  | Supported; extra PHP modules required (see README)                                      | Non-Linux environments                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `music.example.com`                                         | URL          | TLS required                                                                                    |
| DB                   | MySQL/MariaDB with dedicated user                                       | DB           | UTF-8 charset                                                                                    |
| Admin user + password | At installer                                                    | Bootstrap    | **Strong password**                                                                                    |
| Music directory      | `/mnt/music` or volume mount                                                    | Storage      | Read access for Ampache                                                                                                      |
| Catalog root path    | Configured in web UI                                                                                   | Config       | Can have multiple catalogs                                                                                                              |
| Transcoding          | `ffmpeg` path + presets                                                                                       | Config       | Optional but recommended                                                                                                                  |

## Install via Docker

```yaml
services:
  ampache-db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: ampache
      MARIADB_USER: ampache
      MARIADB_PASSWORD: ${DB_PASSWORD}
      MARIADB_ROOT_PASSWORD: ${DB_ROOT_PASSWORD}
    volumes:
      - ./ampache-db:/var/lib/mysql

  ampache:
    image: ampache/ampache:release6    # **pin tag** — release6 / release7 / etc.
    restart: unless-stopped
    depends_on: [ampache-db]
    volumes:
      - /mnt/music:/media:ro           # your music (READ-ONLY)
      - ./ampache-config:/config
    ports: ["8080:80"]
    environment:
      - TZ=UTC
```

## First boot

1. Browse `http://host:8080` → installer wizard
2. Configure DB connection
3. Create admin user — **strong password**
4. Add your first catalog: path to music directory
5. Trigger catalog scan (can take HOURS for large libraries)
6. Browse → confirm tracks appear with correct metadata
7. Test Subsonic API: install DSub / Ultrasonic / Substreamer / Symfonium → log in with Ampache user + password
8. Put behind TLS reverse proxy
9. Back up DB + `/config`

## Data & config layout

- `/config` — Ampache configuration (ampache.cfg.php etc.)
- **MariaDB** — library metadata, playlists, users, scrobble history, preferences
- **Music directory** — your actual files (MOUNT READ-ONLY where possible)
- Album art cache

## Backup

```sh
docker compose exec ampache-db mariadb-dump -uampache -p${DB_PASSWORD} ampache > ampache-$(date +%F).sql
sudo tar czf ampache-config-$(date +%F).tgz ampache-config/
# Music is YOUR backup responsibility — separate from Ampache
```

## Upgrade

1. Releases: <https://github.com/ampache/ampache/releases>. Active again per 2025 notice.
2. Between major versions: read [upgrade guide](https://ampache.org/docs/installation/upgrading).
3. DB schema migrations auto-run on first startup of new version.
4. Back up DB FIRST.
5. **PHP version requirements shift** with major versions — Ampache 7 requires PHP 8.2+; ensure your PHP is current.

## Gotchas

- **Metadata quality = experience quality**. Ampache quote: *"Ampache is not a media organiser; it is meant to be a tool which presents an already organised collection in a useful way."* **Poor ID3 tags → messy Ampache library.** Use Picard / beets / MusicBrainz tools to clean tags BEFORE importing. This is the #1 new-user stumble for every music server (Jellyfin, Navidrome, Plex, Ampache).
- **Music licensing**: ripping music you own is legally complex per jurisdiction. Streaming YOUR OWN ripped library to YOUR OWN devices is typically fine; streaming to OTHERS legally requires licenses if the music is copyrighted. **Same legal framework as AzuraCast (batch 87)** but less public-broadcast-centric. **8th tool in network-service-legal-risk family** (borderline — personal vs distribution).
- **Subsonic API compat = mobile-app ecosystem**: Ampache's Subsonic API compat is arguably its biggest asset in 2026. You get mature iOS/Android clients (DSub, Ultrasonic, play:Sub, Substreamer, Symfonium) that work against Ampache without Ampache building its own mobile apps. **Same pattern as yarr's Fever API compat (batch 87)** — piggyback on legacy-but-widely-supported standards to inherit an ecosystem.
- **Navidrome** is Ampache's modern competitor (Go, smaller, Subsonic-focused, single-binary). Ampache's advantages: longer history, video support, fuller PHP ecosystem integration, richer admin UI. Navidrome's: lighter, faster, easier to deploy. Evaluate both.
- **Initial catalog scan is SLOW** — large libraries (50k+ tracks) can take hours. Subsequent incremental scans are fast.
- **Transcoding CPU**: on-the-fly transcoding to opus/mp3/aac for mobile clients burns CPU. For many concurrent clients, pre-transcode or scale up the host.
- **Read-only music mount**: mount your library READ-ONLY to Ampache. Protects against accidental deletion from UI + scans. **Same discipline as every media server.**
- **User-creds DB = hub-of-credentials** — family membership but LIGHT. Users + Subsonic API passwords + Last.fm tokens + LDAP bind creds. Not as extreme as Guacamole (batch 87) but still sensitive. **12th tool in hub-of-credentials family.**
- **Project health note**: upstream README explicitly mentions **"INCREASED CONTRIBUTIONS"** + Ampache 8 work starting — this is a *transparent maintenance-status signal* (good) after a slower period. **7th tool in transparent-status/honest-maintenance family.** Classify: "health-re-energized, active-again".
- **LDAP auth**: works; useful for company/family shared instance with existing directory.
- **API KEY CAUTION** — Ampache exposes API endpoints with user-level tokens. Treat tokens as passwords. Revoke old tokens periodically.
- **Multi-user privacy**: per-user library visibility works but shares one DB. Not tenant-isolated at DB level; users can't see each other's playlists but admin sees all. Fine for family; wrong for multi-tenant-commercial.
- **Historic cruft**: 20+-year codebase has legacy patterns. Ampache 7+ has substantially modernized. Ampache 8 will continue that.
- **AGPL-3.0** for a self-hosted media server is fine; you don't distribute modified Ampache to streaming clients (they're API clients, not redistributing the server code).
- **Video support** is present but less polished than audio. For video-primary use: Jellyfin is usually the better pick.
- **Alternatives worth knowing:**
  - **Navidrome** (Go + Subsonic) — modern + minimal + fast; music-only; the current competitor
  - **Jellyfin** — full media server (music + video + books + photos); broader scope, heavier
  - **Plex** — commercial + freemium; best polish; closed-source
  - **Subsonic / Airsonic / Madsonic** — the Subsonic-lineage tools
  - **Funkwhale** — federated music sharing (ActivityPub)
  - **Owntone / DAAP** — Apple-ecosystem-friendly
  - **Choose Ampache if:** you want mature PHP/MariaDB stack + audio+video + Subsonic API + long-history.
  - **Choose Navidrome if:** you want modern + minimal + music-only + Go-single-binary.
  - **Choose Jellyfin if:** you want unified music+video+books.

## Links

- Repo: <https://github.com/ampache/ampache>
- Homepage: <https://ampache.org>
- Docs: <https://ampache.org/docs/>
- Install: <https://ampache.org/docs/installation/>
- API: <https://ampache.org/api/>
- Docker: <https://hub.docker.com/r/ampache/ampache>
- Navidrome (alt): <https://www.navidrome.org>
- Jellyfin (alt): <https://jellyfin.org>
- Funkwhale (alt, federated): <https://funkwhale.audio>
- Picard (tag editor, companion): <https://picard.musicbrainz.org>
- beets (tag CLI, companion): <https://beets.io>
- DSub (Android Subsonic client): <https://play.google.com/store/apps/details?id=github.daneren2005.dsub>
- Symfonium (Android): <https://symfonium.app>
- play:Sub (iOS): <https://michaelsapps.dk/playsubapp/>
