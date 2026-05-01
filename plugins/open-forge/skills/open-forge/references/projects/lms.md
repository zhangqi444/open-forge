---
name: LMS (Lightweight Music Server)
description: "Self-hosted music streaming server with web UI. C++/Wt. Docker + Debian packages + source. epoupon/lms. Subsonic/OpenSubsonic API, MusicBrainz, ListenBrainz, recommendations, transcoding."
---

# LMS — Lightweight Music Server

**Self-hosted music streaming software** — access your music collection from anywhere via a web interface. C++ server built on the Wt web toolkit. Full Subsonic/OpenSubsonic API support (works with any Subsonic-compatible client). Rich metadata: multi-valued tags, MusicBrainz IDs, release groups, artist relationships. Recommendation engine, radio mode, transcoding, podcast support, jukebox mode.

Built + maintained by **Emeric Poupon (epoupon)**. Demo at [lms-demo.poupon.dev](http://lms-demo.poupon.dev) (admin settings not available in demo).

- Upstream repo: <https://github.com/epoupon/lms>
- Docker Hub: <https://hub.docker.com/r/epoupon/lms>
- Install docs: <https://github.com/epoupon/lms/blob/master/INSTALL.md>
- Subsonic API details: <https://github.com/epoupon/lms/blob/master/SUBSONIC.md>

## Architecture in one minute

- **C++ / Wt** web server (single binary, low resource usage)
- **SQLite** database (default; handles large libraries well)
- Port **5082** (Docker default)
- Subsonic/OpenSubsonic API → compatible with all Subsonic clients (DSub, Symfonium, Navidrome apps, etc.)
- Audio transcoding via **ffmpeg**
- Authentication backends: internal, PAM, HTTP headers (SSO)
- Jukebox mode: direct audio output via PulseAudio from the server

## Compatible install methods

| Infra              | Runtime                      | Notes                                                             |
| ------------------ | ---------------------------- | ----------------------------------------------------------------- |
| **Docker**         | `epoupon/lms`                | **Easiest** — see Docker Hub for compose snippet                  |
| **Debian package** | `apt install lms`            | Trixie (Debian 13) packages for amd64; custom apt repo            |
| **Source**         | CMake + C++20                | For other distros; requires Wt4 + ffmpeg + several libs           |

## Inputs to collect

| Input                     | Example                          | Phase    | Notes                                                                                   |
| ------------------------- | -------------------------------- | -------- | --------------------------------------------------------------------------------------- |
| Music library path        | `/music`                         | Storage  | Mount into container; LMS scans this dir recursively                                    |
| Domain                    | `music.example.com`              | URL      | Reverse proxy + TLS                                                                     |
| Admin credentials         | username + password              | Auth     | Set on first-run wizard                                                                 |
| Timezone                  | `America/New_York`               | Config   | For scheduler / timestamps                                                              |
| Transcoding codec         | `mp3`, `opus`, `aac`             | Config   | Admin settings; requires ffmpeg in image (included in Docker)                           |

## Install via Docker

Per [Docker Hub — epoupon/lms](https://hub.docker.com/r/epoupon/lms):

```yaml
services:
  lms:
    image: epoupon/lms:latest
    container_name: lms
    ports:
      - "5082:5082"
    volumes:
      - ./lms-data:/var/lms        # DB + config
      - /path/to/music:/music:ro   # music library (read-only)
    environment:
      - TZ=America/New_York
    restart: unless-stopped
```

Visit `http://<host>:5082`.

## Install via Debian package (Trixie/amd64)

```sh
# Add upstream apt repo
wget --backups=1 https://debian.poupon.dev/apt/debian/epoupon.gpg -P /usr/share/keyrings
echo "deb [signed-by=/usr/share/keyrings/epoupon.gpg] https://debian.poupon.dev/apt/debian trixie main" \
  > /etc/apt/sources.list.d/epoupon.list

apt update && apt install lms
# Service starts automatically as 'lms' system user
```

Config: `/etc/lms.conf`. Data: `/var/lms/`. Logs: systemd journal (`journalctl -u lms`).

## First boot

1. Deploy (Docker or package).
2. Open the web UI → first-run wizard creates admin user.
3. Add your music library path in Settings → Libraries.
4. Trigger an initial scan (Admin → Database → Scan).
5. Enable **transcoding** profiles if needed (Admin → Transcoding).
6. Add other users; set their access level.
7. Configure **Subsonic API** if you want to use external clients (DSub, Symfonium, etc.): Admin → API.
8. Set up **ListenBrainz** scrobbling if desired (Settings → ListenBrainz).
9. Put behind TLS.
10. Back up `/var/lms/` (contains DB + config — not the music itself).

## Data & config layout

- `/var/lms/` — SQLite DB + LMS config
- Music library: externally managed; LMS scans it, does not modify files

## Backup

```sh
docker compose stop lms
sudo tar czf lms-$(date +%F).tgz lms-data/
docker compose start lms
# The music itself is on your NAS/mount — back it up separately
```

## Upgrade

1. Releases: <https://github.com/epoupon/lms/releases>
2. Docker: `docker compose pull && docker compose up -d`
3. Debian: `apt update && apt upgrade lms`

## Gotchas

- **Subsonic API is the primary client integration.** LMS's web UI is good for discovery/browsing, but most users pair it with a Subsonic-compatible mobile app (DSub, Symfonium, Foobar2000 with plugin, etc.). Configure API credentials in Admin → API.
- **Tag quality matters a lot.** LMS relies heavily on file tags (MusicBrainz IDs, multi-valued tags, release types). A well-tagged library (via Picard or beets) unlocks artist relationships, release groups, and accurate recommendations. A mess of poorly-tagged rips will produce a mess in LMS.
- **Initial scan can be slow for large libraries.** Tens of thousands of tracks take minutes to hours for the first full scan. Subsequent incremental scans are fast.
- **Recommendation engine can slow the UI on large libraries / low-spec hardware.** Disable in Admin settings if the UI feels sluggish.
- **Wt4 is not Debian-packaged.** Upstream packages handle this; building from source on non-Debian distros means compiling Wt4 yourself (not trivial — ~200MB+ of dependencies). Use Docker unless you're on Debian Trixie.
- **ffmpeg is required for transcoding.** The official Docker image bundles it. If installing the Debian package, `apt install ffmpeg` separately.
- **PAM + HTTP-header auth backends.** For SSO integrations (Authelia, Authentik, etc.), the HTTP-header backend is the pragmatic path — configure your reverse proxy to inject the user header.
- **Jukebox mode** plays audio out of the server machine's sound card (PulseAudio). Useful for a dedicated music box / Pi; irrelevant for remote streaming.
- **Artist information folder** (Kodi-format `artist.nfo` + `artist.jpg`): LMS supports it for biography + artwork. Place under a root-level `ArtistInfo/` directory in your library.
- **ListenBrainz scrobbling** is per-user in Settings. Last.fm scrobbling is not built-in — use a Subsonic client that supports it (many do).
- **SQLite scales well** — LMS is optimized for it; no need to migrate to Postgres.

## Project health

Active C++ development, Docker Hub, Debian apt repo, Subsonic API, demo instance, discussion forum. Solo-maintained by Emeric Poupon.

## Music-server-family comparison

- **LMS** — C++, Subsonic API, strong metadata/MusicBrainz integration, recommendation engine, low resource
- **Navidrome** — Go, Subsonic API, simpler, more widely deployed, better Subsonic client compatibility
- **Jellyfin** — .NET, multi-media (video + music + photos), heavier
- **Plex** — proprietary, music + video, account required
- **Ampache** — PHP, long-established, complex
- **Funkwhale** — Python, federated (ActivityPub), social features

**Choose LMS if:** you want a low-resource C++ music server with deep MusicBrainz/metadata support, Subsonic API, and a recommendation engine.

## Links

- Repo: <https://github.com/epoupon/lms>
- Docker Hub: <https://hub.docker.com/r/epoupon/lms>
- Install docs: <https://github.com/epoupon/lms/blob/master/INSTALL.md>
- Subsonic API: <https://github.com/epoupon/lms/blob/master/SUBSONIC.md>
- Demo: <http://lms-demo.poupon.dev>
- Navidrome (alt): <https://www.navidrome.org>
