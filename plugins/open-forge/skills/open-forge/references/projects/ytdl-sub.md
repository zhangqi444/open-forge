---
name: ytdl-sub
description: "Automates yt-dlp downloads + prepares media for Kodi/Jellyfin/Plex/Emby/music-players. YAML-based subscriptions. yt-dlp under the hood; plex/kodi/jellyfin metadata. GPL. jmbannon maintainer + community. Active; 10/10 pylint."
---

# ytdl-sub

ytdl-sub is **"yt-dlp + metadata-orchestration for media-servers"** — a command-line tool that downloads media via yt-dlp + prepares it for Kodi / Jellyfin / Plex / Emby / modern music players. No additional plugins or external scrapers needed — ytdl-sub formats file-names + metadata + thumbnails to match Plex-TV-show / Plex-Music-Video / Jellyfin-TV / Kodi conventions. YAML-based subscription files; scheduled downloads; automatic metadata; music-tags via **beets** API for SoundCloud/Bandcamp.

Built + maintained by **Jesse Bannon (jmbannon)** + community. License: **GPL** (check repo). Active; 10/10 pylint score; codecov; GitHub Actions; Discord; ReadTheDocs.

Use cases: (a) **YouTube channels as Plex TV-shows** — channel auto-imports as season/episodes (b) **music-video library** — YouTube music-videos → Plex Music Videos library (c) **SoundCloud discography** — download artist's full-SoundCloud → music-tag via beets → Plex Music (d) **Bandcamp artists** — similar (e) **Jellyfin pre-configured content** — no manual metadata entry (f) **Kodi library automation** — pre-formatted for Kodi scrapers (g) **backup YouTube content** — creator content preserved before takedowns (h) **offline viewing** — family trips.

Features (per README):

- **yt-dlp** under the hood
- **Pre-formatted output** for Plex / Jellyfin / Emby / Kodi
- **YouTube-channel-as-TV-show** templates
- **Music videos + concerts** templates
- **SoundCloud + Bandcamp discography** support
- **beets** for music-tags
- **YAML subscription files**
- **Scheduled downloads** (cron / systemd-timer)
- **10/10 pylint** code quality

- Upstream repo: <https://github.com/jmbannon/ytdl-sub>
- Docs: <https://ytdl-sub.readthedocs.io>
- Discord: <https://discord.gg/v8j9RAHb4k>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>

## Architecture in one minute

- **Python** CLI tool
- **yt-dlp** for downloading
- **beets** for music-tag management
- **Resource**: moderate — depends on download volume; CPU for re-encoding
- **Runs on-schedule** — typically cron / systemd-timer / Docker-restart

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream images**                                             | **Primary**                                                                        |
| **pip install**    | Python package                                                                            | CLI                                                                                   |
| Source             | Clone + install                                                                                                             | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Subscription YAML    | Channels / playlists / artists to track                     | Config       | **Core configuration**                                                                                    |
| Output media dir     | Path to Plex/Jellyfin media library                         | Storage      |                                                                                    |
| Schedule             | cron expression                                             | Config       | Avoid over-frequent = rate-limit risk                                                                                    |
| YouTube cookies (opt) | For age-gated content                                      | Auth         | yt-dlp --cookies                                                                                    |
| SponsorBlock (opt)   | Skip sponsor segments                                                                                 | Config       |                                                                                    |
| Beets config (opt)   | For music-tag workflow                                                                                                      | Config       |                                                                                                                                            |
| Proxy (optional)     | If rate-limited by origin                                                                                                            | Network      |                                                                                                                                            |

## Install via Docker

```yaml
services:
  ytdl-sub:
    image: ghcr.io/jmbannon/ytdl-sub:latest        # **pin version**
    volumes:
      - ./config:/config
      - ./media:/media       # Output to Plex/Jellyfin library
    environment:
      PUID: 1000
      PGID: 1000
    restart: unless-stopped
    # Invoke via: docker exec ytdl-sub ytdl-sub sub /config/subscriptions.yaml
```

```yaml
# Example subscription (config/subscriptions.yaml):
---
__preset__:
  output_options:
    output_directory: "/media/YouTube/{tv_show_name}"
    file_name: "{tv_show_name} S{season_number:02d}E{episode_number:02d} - {title}.{ext}"

"My Channel":
  preset: "Jellyfin TV Show"
  overrides:
    tv_show_name: "My Channel"
    url: "https://www.youtube.com/@MyChannel"
```

## First boot

1. Write subscriptions.yaml
2. Run `ytdl-sub sub subscriptions.yaml`
3. Verify first batch downloads to right place
4. Configure cron / systemd-timer / Docker-restart for recurring
5. Integrate with Plex/Jellyfin/Kodi — trigger library-refresh after download

## Data & config layout

- `subscriptions.yaml` — your subscriptions
- `config.yaml` — global defaults
- Output dir — your Plex/Jellyfin library
- State files — what's-already-downloaded tracking

## Backup

```sh
# Configuration:
sudo cp -a config backups/config-$(date +%F)
# Downloaded media: typically not backed up (re-downloadable from source)
```

## Upgrade

1. Releases: <https://github.com/jmbannon/ytdl-sub/releases>. Active.
2. Docker pull OR `pip install -U ytdl-sub`
3. **yt-dlp updates frequently** — stay current to follow YouTube API changes

## Gotchas

- **YT-DLP DEPENDENCY + YOUTUBE API CAT-AND-MOUSE**:
  - yt-dlp maintains compatibility with YouTube by reverse-engineering
  - YouTube actively works to break download tools
  - yt-dlp updates = ytdl-sub must follow
  - **Recipe convention: "yt-dlp-API-drift-risk" callout**
  - **NEW recipe convention** (ytdl-sub 1st, also applies to YouTubeDL-Material 97)
- **COPYRIGHT + TOS**:
  - YouTube TOS prohibits downloading most content
  - Using for personal offline viewing = gray but widespread
  - REDISTRIBUTING downloaded content = copyright infringement
  - **Recipe convention: "YouTube-TOS-download-restriction" callout**
  - **Recipe convention: "copyright-content-hosting-risk"** applies (Grimmory 105 precedent) — 3rd ebook/media tool with this callout
- **RATE-LIMITING + IP BANS**:
  - Too-frequent downloads → YouTube rate-limits your IP
  - Use `--sleep-subtitles` + `--sleep-interval` + reasonable cron-frequency
  - Consider: residential-proxy OR geographic-diversity
  - **Recipe convention: "media-scraping-rate-limit" callout**
- **COOKIES FOR AGE-GATED CONTENT**:
  - yt-dlp accepts browser-cookies for auth'd content
  - **LEAK-RISK**: cookies = Google-account-login-equivalent
  - Don't commit cookies-file to git
  - **Recipe convention: "browser-cookie-login-credential-risk" callout**
  - **NEW recipe convention**
- **HUB-OF-CREDENTIALS TIER 2/3**:
  - YouTube cookies (if used) = Google-account-access = HIGH sensitivity
  - Without cookies: Tier 3 (no credentials)
  - **80th tool in hub-of-credentials family — Tier 2** (when cookies used)
- **STORAGE REQUIREMENTS**:
  - YouTube subscriptions can be TBs
  - Plan storage + retention
  - **Recipe convention: "TB-scale-storage-requirement"** extended (Steam Headless 104 precedent); now 2 tools
- **METADATA-FORMATTING = KEY VALUE**:
  - ytdl-sub's value: Plex/Jellyfin-compatible metadata
  - Without ytdl-sub: manual Plex metadata editing
  - **Recipe convention: "metadata-scraping-format-adapter positive-signal"**
- **10/10 PYLINT = QUALITY SIGNAL**:
  - Pylint 10/10 is rare (extreme cleanliness)
  - **Recipe convention: "pylint-10-code-quality positive-signal"**
  - **NEW positive-signal convention** (ytdl-sub 1st)
- **CODECOV + CI**:
  - Strong engineering discipline
- **SPONSORBLOCK INTEGRATION**:
  - Skip sponsor-segments on download
  - Community-maintained
  - **Recipe convention: "SponsorBlock-integration positive-signal"** for YouTube-tools
- **INSTITUTIONAL-STEWARDSHIP**: jmbannon + community + Discord. **66th tool — sole-maintainer-with-community sub-tier (31st tool in sub-tier).**
- **TRANSPARENT-MAINTENANCE**: active + pylint-10 + codecov + CI + Discord + ReadTheDocs + releases. **74th tool in transparent-maintenance family.**
- **YOUTUBE-DL-CATEGORY:**
  - **ytdl-sub** — YAML + metadata for media-servers
  - **YouTubeDL-Material** (batch 97) — web UI for yt-dlp
  - **PinchFlat** — similar space; Elixir
  - **tubesync** — similar; Django
  - **metube** — Docker yt-dlp wrapper
  - **jellyfin-plugin-ytdl** — plugin; less feature-rich
  - **yt-dlp CLI direct** — without wrappers
- **ALTERNATIVES WORTH KNOWING:**
  - **tubesync** — if you want Django web UI
  - **PinchFlat** — if you want Elixir
  - **YouTubeDL-Material** — if you want web UI
  - **Choose ytdl-sub if:** you want YAML-driven + Plex/Jellyfin metadata + music-videos + SoundCloud.
- **PROJECT HEALTH**: active + pylint-10 + codecov + Discord + ReadTheDocs. Excellent signals.

## Links

- Repo: <https://github.com/jmbannon/ytdl-sub>
- Docs: <https://ytdl-sub.readthedocs.io>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>
- YouTubeDL-Material (batch 97): <https://github.com/Tzahi12345/YoutubeDL-Material>
- PinchFlat: <https://github.com/kieraneglin/pinchflat>
- tubesync: <https://github.com/meeb/tubesync>
- metube: <https://github.com/alexta69/metube>
- beets: <https://beets.io>
- SponsorBlock: <https://sponsor.ajay.app>
