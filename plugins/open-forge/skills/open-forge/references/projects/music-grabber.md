# Music Grabber

**What it is:** A self-hosted music acquisition service for single tracks. Search YouTube, SoundCloud, MP3Phoenix, and optional Soulseek in parallel, tap a result, and it downloads the best-quality audio straight into your music library. Designed for the "I want one song, not an entire album" use case — complementing Lidarr rather than replacing it.

**Official URL:** https://gitlab.com/g33kphr33k/musicgrabber
**License:** AGPLv3
**Stack:** Python + SQLite; requires Chromium (bundled) for headless browser

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; build from source |
| Homelab (NAS with x86) | Docker Compose | Needs `shm_size: 2gb` for Chromium |

> **Note:** No pre-built image on Docker Hub — build locally from the GitLab repo.

---

## Inputs to Collect

### Pre-deployment
- `MUSIC_DIR` — path inside container to your music library (e.g. `/music`)
- `DB_PATH` — path for the SQLite job database (e.g. `/data/music_grabber.db`)
- `PUID` / `PGID` — optional; run as specific user for NAS/SMB share compatibility

### Optional integrations (configured via Settings UI — no restart needed)
- **Navidrome:** URL + user/pass → auto-triggers library rescan after downloads
- **Jellyfin:** URL + API key → same
- **Soulseek:** `SLSKD_URL` + credentials + `SLSKD_DOWNLOADS_PATH`
- **Notifications:** Apprise URL (covers Gotify, ntfy, Discord, Pushover, Slack, ~50 others), Telegram webhook, or SMTP email
- **Spotify playlists:** upload browser cookies from `open.spotify.com` in Settings
- **YouTube cookies:** upload browser cookies in Settings to bypass bot detection

---

## Software-Layer Concerns

**Build and run:**
```bash
git clone https://gitlab.com/g33kphr33k/musicgrabber.git
cd musicgrabber
docker compose up -d
```

**`docker-compose.yml` key config:**
```yaml
services:
  music-grabber:
    build: .
    container_name: music-grabber
    restart: unless-stopped
    shm_size: '2gb'   # Required for Chromium headless
    ports:
      - "38274:8080"
    volumes:
      - /mnt/music:/music
      - ./data:/data
      - /mnt/music/downloads:/downloads   # For Soulseek
    environment:
      - MUSIC_DIR=/music
      - DB_PATH=/data/music_grabber.db
      # Optional:
      # - PUID=1000
      # - PGID=1000
      # - SLSKD_DOWNLOADS_PATH=/downloads
      # - ROOT_PATH=/musicgrabber  # For reverse-proxy subpath
```

**Default port:** `38274`

**Settings UI:** All integrations (Navidrome, Jellyfin, Soulseek, notifications, cookies, min bitrate, output format) are configured in the Settings tab — no `docker-compose.yml` editing needed after initial deploy.

**Output formats:** FLAC (default), Opus, or MP3 ~192 kbps VBR. FLAC is for standardization, not quality improvement.

**File organization:** `Singles/Artist/Title.flac` (or flat layout with "Organise by Artist" off). Optional track-number prefix.

**Upgrade procedure:**
1. `git pull`
2. `docker compose build --pull`
3. `docker compose up -d`

---

## Gotchas

- **Build required** — no pre-built Docker image; must clone and `docker compose up --build`
- **`shm_size: 2gb` required** — Spotify playlists over 100 tracks will fail without this; general Chromium instability without it
- **Not a music manager or streaming server** — it downloads files to disk only; pair with Navidrome/Jellyfin for playback
- **AGPL-3.0** — modifications must be open-sourced if deployed publicly
- **Soulseek requires slskd** — install slskd separately; configure its URL in Settings
- **Duplicate detection** — checks local filesystem + optional Navidrome Subsonic API; prevents re-downloading existing tracks
- **Trash bin** — failed/rejected downloads go to `.trash/` for review, not permanent deletion
- **Multi-user support** — each user gets their own queue, playlists, and watched artists; admins manage global settings

---

## Links
- GitLab: https://gitlab.com/g33kphr33k/musicgrabber
- Ko-fi: https://ko-fi.com/geekphreek
