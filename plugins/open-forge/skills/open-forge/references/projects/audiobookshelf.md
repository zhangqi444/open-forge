---
name: Audiobookshelf
description: Self-hosted audiobook + podcast server. Stream any audio format, auto-detect library changes, multi-user with per-user progress sync, native Android + iOS apps, Chromecast + Sonos support. Node.js server + SQLite, single container. MIT.
---

# Audiobookshelf

Audiobookshelf is the Plex-for-audiobooks. Point it at folders of MP3/M4B/FLAC/OGG files on disk; it detects metadata from Audible/Google Books/iTunes, offers a polished web reader + native Android + iOS apps (with offline sync), tracks per-user reading position across devices, auto-discovers new files, and also does podcasts (subscribe, auto-download, episode-level progress).

Trade-offs:

- ✅ Native mobile apps (beta but stable) — sync progress + download for offline
- ✅ Chromecast, Sonos (via API), CarPlay, Android Auto
- ✅ Podcasts included — not a separate install
- ✅ ePub + PDF reader for e-books (basic)
- ❌ Not a file organizer — relies on your existing directory structure following a naming convention
- ❌ Metadata editing is per-title via UI (no batch bulk-edit workflow)

- Upstream repo: <https://github.com/advplyr/audiobookshelf>
- Website: <https://audiobookshelf.org>
- Docs: <https://audiobookshelf.org/docs>
- User guides: <https://audiobookshelf.org/guides>
- Mobile apps: <https://github.com/advplyr/audiobookshelf-app>
- Subreddit: <https://www.reddit.com/r/audiobookshelf/>

## Architecture in one minute

- **Single Node.js service** + **SQLite** DB (v2+; previous versions used JSON files — migrated automatically)
- **Library folders** on disk — Audiobookshelf indexes them, generates metadata + covers, stores them in a metadata dir
- **Native apps** (Android, iOS) talk to the same HTTP API + WebSocket for real-time progress sync
- **WebSocket required** — reverse proxies must support WS upgrades (biggest footgun)

## Compatible install methods

| Infra       | Runtime                                                | Notes                                                                    |
| ----------- | ------------------------------------------------------ | ------------------------------------------------------------------------ |
| Single VM   | Docker (`ghcr.io/advplyr/audiobookshelf:<VERSION>`)    | **Recommended**                                                           |
| Single VM   | Docker Compose with bind mounts                         | For controllable library paths                                            |
| Single VM   | Native (Node.js) — Ubuntu/Debian packages              | `audiobookshelf` apt/deb packages                                          |
| NAS         | Synology / QNAP / Unraid / TrueNAS apps                 | Official + community packages                                             |
| Kubernetes  | Community Helm chart (Truecharts / home-operations)     | Not upstream-maintained                                                   |

## Inputs to collect

| Input            | Example                               | Phase     | Notes                                                         |
| ---------------- | ------------------------------------- | --------- | ------------------------------------------------------------- |
| Port             | `13378:80`                            | Network   | Container listens on 80 internally                              |
| Config dir       | `/abs-config`                         | Storage   | SQLite DB + settings                                            |
| Metadata dir     | `/abs-metadata`                       | Storage   | Covers, cache, generated thumbs                                 |
| Library dirs     | `/audiobooks`, `/podcasts`            | Storage   | Your actual media; mount read-only if you don't want edits      |
| Public URL       | `https://audiobookshelf.example.com`  | DNS       | Proxy must forward WebSockets                                   |
| First admin      | set via web UI on first visit         | Bootstrap | `root` is the first user created                                |

## Install via Docker Compose

```yaml
services:
  audiobookshelf:
    image: ghcr.io/advplyr/audiobookshelf:2.27.0    # pin; avoid :latest
    container_name: audiobookshelf
    restart: unless-stopped
    ports:
      - "13378:80"
    environment:
      - TZ=America/New_York
    volumes:
      - /path/to/audiobooks:/audiobooks
      - /path/to/podcasts:/podcasts
      - ./config:/config
      - ./metadata:/metadata
```

Image: <https://github.com/advplyr/audiobookshelf/pkgs/container/audiobookshelf>.

## Directory structure

Audiobookshelf **relies on your directory structure** for parsing:

```
/audiobooks/
  Author Name/
    Series Name/
      1 - Book Title/
        Book Title.m4b
      2 - Another Book/
        Another Book.mp3
    Standalone Book/
      Standalone Book.m4b
```

Or flatter:

```
/audiobooks/
  Book Title/
    Book Title.m4b
```

Details: <https://audiobookshelf.org/docs#book-directory-structure>.

For **podcasts**, Audiobookshelf auto-creates folders under the library dir as you subscribe; no manual layout.

## WebSocket reverse proxy (biggest footgun)

Audiobookshelf requires WebSockets for real-time UI updates + mobile progress sync. Every reverse proxy config **must** forward WS:

### nginx

```nginx
location / {
    proxy_pass http://127.0.0.1:13378;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 3600s;
}
```

### Caddy

```
audiobookshelf.example.com {
    reverse_proxy 127.0.0.1:13378
}
```

(Caddy handles WebSockets automatically.)

### NGINX Proxy Manager

Toggle **"Websockets Support"** ON in the proxy host settings.

### Cloudflare Tunnel

Enable **WebSocket** in the tunnel config for the hostname (enabled by default for newer tunnels).

## Subpath hosting

Supported with **one** fixed path: `/audiobookshelf`. Not changeable. See <https://github.com/advplyr/audiobookshelf/discussions/3535>.

```nginx
location /audiobookshelf {
    proxy_pass http://127.0.0.1:13378/audiobookshelf;
    # ... same WS headers
}
```

## Data & config layout

Inside container:

- `/config/`
  - `absdatabase.sqlite` — primary DB (users, libraries, books, podcast state, progress)
  - `backups/` — auto-generated daily backups (configurable in UI)
  - `logs/` — structured logs
- `/metadata/`
  - `items/<book-id>/cover.jpg` — cover art
  - `cache/` — generated artwork, audio preview waveforms
- Your library dirs — read by Audiobookshelf, optionally written if you enable "Embed metadata" or "Write OPF"

## Backup

Audiobookshelf has **built-in daily auto-backups** (Settings → Backups). Backups include the DB + settings (NOT your media files — those stay on disk). Default path: `/metadata/backups/`.

```sh
# On top of built-in backups, protect the full config dir:
tar czf abs-backup-$(date +%F).tgz config/ metadata/
```

Restore: Settings → Backups → upload a backup `.audiobookshelf` file.

## Upgrade

1. Releases: <https://github.com/advplyr/audiobookshelf/releases>. Roughly monthly.
2. `docker compose pull && docker compose up -d`. Auto-migration on startup (takes 10-60s on large libs).
3. **Always back up before major version jumps** (v2.0 introduced SQLite migration from JSON — handled auto but irreversible).
4. Read changelog for breaking changes (occasional directory-parser tweaks).

## Gotchas

- **WebSocket support in reverse proxies is mandatory.** Without, the UI appears to work but progress doesn't save, and mobile apps fail to sync. Single most common support issue.
- **Subpath is fixed to `/audiobookshelf`.** Don't try to rename it — hardcoded in the frontend.
- **Directory structure matters.** Poorly named folders = metadata lookups fail. Run Library → Scan Tools → Re-scan after reorganizing.
- **First user = root admin.** Subsequent user invites via admin panel; no self-signup by default.
- **Mobile apps connect via URL + username + password.** Remote access needs the URL reachable externally (Cloudflare Tunnel / Tailscale / public domain).
- **Mobile app auto-downloads** respect the user's "download over cellular" setting — default is Wi-Fi only.
- **Podcast episode cleanup** is a user setting per podcast (how many to keep). Disable for "keep all episodes ever".
- **Transcoding** — Audiobookshelf **does not transcode**; it streams files as-is. Most clients handle MP3/M4B/FLAC natively.
- **Chromecast**: web UI + Android app support it; iOS app support is in beta.
- **Sonos integration** via an API wrapper (not upstream); community solutions exist.
- **ePub reader** is basic — use for fallback only if you're serious about e-books; pair with Kavita / Komga for dedicated e-book mgmt.
- **Comic support is minimal** — better tools: Komga, Kavita, Kavita-CBR.
- **Audible "AAX" files require decryption** before import (removal of DRM); Audiobookshelf does NOT decrypt. Tools like `audible-cli` + `ffmpeg` handle this offline.
- **Performance**: 10 k+ audiobooks = indexing takes minutes on first scan; subsequent incremental scans are fast.
- **Native apps are beta** — stable in practice but occasional bugs around sleep timer, bookmarks.
- **Ad-free FOSS.** No telemetry, no cloud dependency, no account lock-in.
- **Library permissions** — per-user lib access, per-tag filters, per-user podcast subs.
- **Alternatives worth knowing:**
  - **Booksonic-air** — older Subsonic fork, simpler UI
  - **Plex / Emby / Jellyfin** — general media servers with audiobook support (basic)
  - **Kavita / Komga** — e-book-focused; overlap on ePub
  - **Jellyfin + Finamp** (iOS) — Finamp is audiobook-aware
  - **Librivox + your own folder** — if you only need public-domain catalogs, Librivox's native apps suffice

## Links

- Repo: <https://github.com/advplyr/audiobookshelf>
- Website: <https://audiobookshelf.org>
- Docs: <https://audiobookshelf.org/docs>
- User guides: <https://audiobookshelf.org/guides>
- Releases: <https://github.com/advplyr/audiobookshelf/releases>
- Docker image: <https://github.com/advplyr/audiobookshelf/pkgs/container/audiobookshelf>
- Mobile app (GitHub): <https://github.com/advplyr/audiobookshelf-app>
- Android app: <https://play.google.com/store/apps/details?id=com.audiobookshelf.app>
- iOS app: <https://apps.apple.com/us/app/audiobookshelf/id1610296661>
- Discord: <https://discord.gg/HQgCbd6E75>
- Subreddit: <https://www.reddit.com/r/audiobookshelf/>
