---
name: Black Candy
description: "Self-hosted personal music streaming server — a Plex-for-music alternative. Web UI + native iOS + Android mobile apps. Scan local music library, stream to browser and phone. Rails + Docker. MIT."
---

# Black Candy

Black Candy is **"your personal music center"** — a self-hosted music streaming server. Point it at your music library (FLAC/MP3/OGG/etc.), let it scan + extract metadata + album art, then stream to your browser or to **official native iOS + Android mobile apps** (F-Droid + App Store). Think "Plex-but-music-only" without the transcoding + ecosystem weight.

Built + maintained by **blackcandy-org** — small OSS team. Written in **Ruby on Rails** with PostgreSQL. MIT-licensed. Demo site at <https://demo.blackcandy.org>.

Use cases: (a) own-your-music streaming — Spotify without cloud (b) legal rips of your own CDs + bandcamp buys + losslessly-purchased albums (c) mobile access to your home music library without hauling terabytes on your phone (d) family shared music with per-user accounts.

Features:

- **Music streaming** via web + mobile apps
- **Library scanning** — scan local music directory
- **Metadata extraction** (ID3 tags, FLAC comments, album art)
- **Native mobile apps** (iOS App Store + Android F-Droid + APK)
- **Playlists** + favorites
- **Multi-user** with admin account
- **Docker-first** — single-container deploy
- **Internal DB**: PostgreSQL bundled
- **Queue worker** for scanning via Sidekiq

- Upstream repo: <https://github.com/blackcandy-org/blackcandy>
- iOS app: <https://github.com/blackcandy-org/ios> → <https://apps.apple.com/app/blackcandy/id6444304071>
- Android app: <https://github.com/blackcandy-org/android> → F-Droid + GitHub Releases APK
- Demo: <https://demo.blackcandy.org> (email: admin@admin.com / pass: foobar — read-only account)
- Docker images:
  - `ghcr.io/blackcandy-org/blackcandy`
  - `blackcandy/blackcandy` (Docker Hub)
- Upgrade guide: <https://github.com/blackcandy-org/blackcandy/blob/master/docs/upgrade.md>

## Architecture in one minute

- **Rails** backend + embedded Postgres (bundled) or external
- **Sidekiq** worker (Redis) for background scans
- **Exposes port 80** inside container (map to host)
- **Resource**: moderate — 500MB-1GB RAM; scales with library size (metadata indexing)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`ghcr.io/blackcandy-org/blackcandy`**                        | **Upstream-primary**                                                               |
| Docker Compose     | Compose example in repo                                                    | External Postgres recommended for production                                                 |
| Kubernetes         | Standard Docker deploy                                                                                 | Community                                                                                              |
| Raspberry Pi       | ARM images via multi-arch manifest                                                                                      | Works on ARM64                                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `music.example.com`                                             | URL          | TLS strongly recommended (mobile apps expect HTTPS usually)                                                                                    |
| Media path (`MEDIA_PATH`) | `/media/music`                                                          | Storage      | Read-only mount of your music library                                                                                  |
| Data volume          | Postgres + config + scans                                                            | Storage      | Persistent volume                                                                                          |
| `SECRET_KEY_BASE`    | Rails secret — random 64+ hex                                                              | Secret       | **Immutable** — rotating breaks session cookies + encrypted fields                                                               |
| Admin creds          | First-run email + pass                                                                              | Bootstrap    | Default `admin@admin.com` / `foobar` — **CHANGE IMMEDIATELY**                                                                          |
| External DB (opt)    | Postgres connection string                                                                                      | DB           | For production; bundled Postgres fine for homelab                                                                                                    |
| External Redis (opt) | Redis connection string                                                                                                      | Cache/Jobs   | Bundled Redis OK; external for scaling                                                                                                                |

## Install via Docker Compose

```yaml
services:
  blackcandy:
    image: ghcr.io/blackcandy-org/blackcandy:latest   # pin version in prod
    restart: unless-stopped
    ports: ["3000:80"]
    volumes:
      - ./blackcandy-data:/app/storage
      - /mnt/music:/media/music:ro                    # read-only music library
    environment:
      MEDIA_PATH: /media/music
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      # Optional external DB:
      # DATABASE_URL: postgres://user:pass@db:5432/blackcandy
```

## First boot

1. Deploy with `SECRET_KEY_BASE` set
2. Login with `admin@admin.com` / `foobar` → **IMMEDIATELY** change email + password
3. Navigate to Settings → Media Management → trigger library scan
4. Wait for scan to complete (minutes to hours depending on size)
5. Verify albums + artwork appear
6. Create additional user accounts for family
7. Install mobile apps → configure server URL → login
8. Put behind TLS reverse proxy
9. Back up data volume + DB

## Data & config layout

- `/app/storage/` — uploaded avatars + scan-cache + bundled Postgres
- `MEDIA_PATH` — your music library (read-only mount)
- Config via env vars

## Backup

```sh
# If bundled Postgres:
docker compose exec blackcandy pg_dump -U <user> blackcandy > blackcandy-db-$(date +%F).sql
sudo tar czf blackcandy-storage-$(date +%F).tgz blackcandy-data/
# Music library: back up separately at the storage layer; typically source of truth is your NAS/backup
```

## Upgrade

1. Upgrade guide (mandatory read): <https://github.com/blackcandy-org/blackcandy/blob/master/docs/upgrade.md>
2. `docker pull` + `docker compose down && up`
3. **Breaking changes common between major versions.** Read changelog + upgrade notes.
4. Migrations auto-run.
5. **Back up first** — especially DB.

## Gotchas

- **Default admin credentials are PUBLIC.** `admin@admin.com` / `foobar` is documented in the README → scanners scanning for default creds hit Black Candy instances constantly. **Change on first login, not later.** Same class as any admin-default-credential tool.
- **Bundled Postgres inside the container** = simple for homelab but bad for production upgrades. If the container's Postgres binary version changes between releases, you may need to run `pg_upgrade` manually. Running **external Postgres** from day 1 removes this risk.
- **`SECRET_KEY_BASE` immutability (Rails class)** — rotating invalidates session cookies + any encrypted fields. Set once; store in secrets manager. Same pattern as Statamic APP_KEY (batch 77), FreeScout APP_KEY (batch 82), Fider JWT_SECRET (batch 82). **Immutability-of-secrets family continues.**
- **"Your music" = legal files.** Don't host pirated music accessible to the public Internet. Streaming unlicensed music = copyright infringement + DMCA takedowns + potential civil suits. Private instance for your OWN-ripped/purchased music = fine.
- **Mobile apps need reachable URL.** iOS and Android apps expect your server on a public domain with valid TLS (most mobile OS versions refuse self-signed). Options:
  - Tailscale/WireGuard VPN to reach from phone
  - Cloudflare Tunnel or Tailscale Funnel for public access
  - Reverse proxy with Let's Encrypt
- **Library scan performance**: large libraries (10K+ tracks) take time. First scan can be hours. Subsequent incremental scans are faster but still touch every modified file. Run overnight; monitor via UI or logs.
- **Transcoding** — check current Black Candy version. Historically direct-streams original file format; some clients may not support FLAC → may need transcoding layer. For universal compat, re-encode to AAC/MP3 externally.
- **Metadata quality = scan quality.** If your tags are inconsistent (artist name varies, no album art), Black Candy will reflect that. Clean tags first with **MusicBrainz Picard** → then scan.
- **No transcoding ecosystem like Plex.** Black Candy is music-only; no video; no subtitles. If you want one tool for music + movies + TV + photos, Plex/Jellyfin/Emby. If you want a lightweight music-only tool, Black Candy fits.
- **No DLNA / UPnP**: doesn't broadcast to smart speakers via uPnP. Pair with Squeezebox/Snapcast/LMS stack if you want multi-room audio.
- **No casting yet** (Chromecast/AirPlay) — check current version for Chromecast support; historically limited.
- **F-Droid distribution for Android** — good privacy signal (no Google Play tracking). APK direct from GitHub also works.
- **MIT license** — maximally permissive. Fork-friendly.
- **Bus-factor**: small team; steady releases; mobile apps maintained separately. Risk of slowdown exists; permissive license + Rails stack = forkable.
- **Project health**: demo + mobile apps + active repo. Healthy small project.
- **Alternatives worth knowing:**
  - **Navidrome** — Go-based; Subsonic-API-compatible (works with 20+ client apps); very popular; probably the strongest default
  - **Airsonic-Advanced** — Java; Subsonic-fork; mature
  - **Jellyfin** (music section) — full media server; covers more than music
  - **Plex** (music) — commercial; broader
  - **LMS (Lyrion Music Server)** — legacy Squeezebox ecosystem; multi-room audio
  - **Ampache** — classic PHP music streamer
  - **Funkwhale** — federated music (ActivityPub)
  - **Mopidy** — library-agnostic music server with plugins
  - **Choose Black Candy if:** clean modern UI + official Black-Candy-branded mobile apps + Rails stack.
  - **Choose Navidrome if:** want Subsonic-API compatibility → widest third-party client ecosystem (DSub, play:Sub, Ultrasonic, Symfonium, Substreamer, etc.).
  - **Choose LMS if:** multi-room Squeezebox hardware.
  - **Choose Funkwhale if:** federation + discover-music-across-instances matters.

## Links

- Repo: <https://github.com/blackcandy-org/blackcandy>
- Docker Hub: <https://hub.docker.com/r/blackcandy/blackcandy>
- GHCR: <https://github.com/blackcandy-org/blackcandy/pkgs/container/blackcandy>
- iOS app repo: <https://github.com/blackcandy-org/ios>
- Android app repo: <https://github.com/blackcandy-org/android>
- Android on F-Droid: <https://f-droid.org/packages/org.blackcandy.android/>
- iOS on App Store: <https://apps.apple.com/app/blackcandy/id6444304071>
- Demo: <https://demo.blackcandy.org>
- Upgrade guide: <https://github.com/blackcandy-org/blackcandy/blob/master/docs/upgrade.md>
- Releases: <https://github.com/blackcandy-org/blackcandy/releases>
- Navidrome (alt): <https://www.navidrome.org>
- Jellyfin (alt): <https://jellyfin.org>
- Ampache (alt): <https://ampache.org>
- Funkwhale (alt): <https://funkwhale.audio>
- LMS (alt): <https://lyrion.org>
