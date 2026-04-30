---
name: MeTube
description: Web UI for yt-dlp. Paste a YouTube / SoundCloud / Vimeo / etc. URL, pick format/quality, and MeTube downloads it to your NAS/server. Supports subscriptions (channels auto-download on new uploads), playlists, format selection, cookies for members-only content. Python + aiohttp + yt-dlp. AGPL-3.0.
---

# MeTube

MeTube is the "bookmarklet for every video on the internet". You open the web UI, paste a URL (YouTube, Twitch VOD, SoundCloud, Vimeo, Twitter, TikTok, Reddit video, a thousand others yt-dlp supports), pick a quality + format, and click Add. The video downloads to your server's disk; a progress bar shows you how far along.

Bigger features:

- **Subscriptions** — paste a channel/playlist; MeTube auto-checks for new uploads and grabs them
- **Custom directory selector** — route different sources to different folders
- **Cookies support** — for login-gated content (YouTube members, Twitter follows)
- **yt-dlp passthrough** — full control over yt-dlp args for advanced use
- **Archive file** — prevents re-downloading the same video
- **HTTPS / auth / reverse proxy** — configurable via env
- **Log streaming** — see yt-dlp's actual output as it downloads

- Upstream repo: <https://github.com/alexta69/metube>
- Docker image: `ghcr.io/alexta69/metube`
- Underlying tool: yt-dlp <https://github.com/yt-dlp/yt-dlp>

## Compatible install methods

| Infra       | Runtime                                             | Notes                                                                 |
| ----------- | --------------------------------------------------- | --------------------------------------------------------------------- |
| Single VM / NAS | Docker (`ghcr.io/alexta69/metube`)              | **Upstream-maintained; only documented path**                          |
| Single VM   | Python from source                                   | `pip install -r requirements.txt` + node build; fiddly                 |
| Kubernetes  | Plain Deployment + PVC for downloads                 | Stateless; works trivially                                             |

## Inputs to collect

| Input                            | Example                   | Phase     | Notes                                                               |
| -------------------------------- | ------------------------- | --------- | ------------------------------------------------------------------- |
| Port                             | `8081:8081`               | Network   | Web UI                                                              |
| `DOWNLOAD_DIR`                   | `/downloads`              | Data      | Where videos land; mount a host dir                                  |
| `STATE_DIR`                      | `/downloads/.metube`      | Data      | Queue/completed/subscriptions JSON; defaults to `DOWNLOAD_DIR/.metube` |
| `AUDIO_DOWNLOAD_DIR`             | `/audio`                  | Data      | Optional separate dir for audio-only                                 |
| `UID`/`GID`                      | `1000`/`1000`             | Runtime   | Ownership of downloaded files                                        |
| `MAX_CONCURRENT_DOWNLOADS`       | `3` (default)             | Runtime   | More = more bandwidth load + more yt-dlp processes                   |
| `YTDL_OPTIONS`                   | `{"cookiefile": "/cookies.txt"}` | Runtime | Global yt-dlp args as JSON                                           |
| `DEFAULT_OPTION_PLAYLIST_ITEM_LIMIT` | `0` (no limit)       | Runtime   | Cap playlist size to avoid 10,000-video dumps                        |
| Cookies file (optional)          | `/cookies.txt`            | Auth      | For members-only YouTube, Twitter follows, etc.                      |

## Install via Docker Compose

Minimal (from upstream README):

```yaml
services:
  metube:
    image: ghcr.io/alexta69/metube:2025-10-26    # pin; upstream uses date-based tags
    container_name: metube
    restart: unless-stopped
    ports:
      - "8081:8081"
    volumes:
      - /mnt/media/youtube:/downloads
      # Optional: cookies file for members-only content
      # - /path/to/cookies.txt:/cookies.txt:ro
    environment:
      - UID=1000
      - GID=1000
      - DARK_MODE=true
```

Browse `http://<host>:8081`.

### With audio-only separate dir + cookies

```yaml
services:
  metube:
    image: ghcr.io/alexta69/metube:2025-10-26
    restart: unless-stopped
    ports: ["8081:8081"]
    volumes:
      - /mnt/media/youtube:/downloads
      - /mnt/media/podcasts:/audio
      - ./cookies.txt:/cookies.txt:ro
    environment:
      - UID=1000
      - GID=1000
      - DOWNLOAD_DIR=/downloads
      - AUDIO_DOWNLOAD_DIR=/audio
      - MAX_CONCURRENT_DOWNLOADS=3
      - YTDL_OPTIONS={"cookiefile":"/cookies.txt"}
      - DEFAULT_OPTION_PLAYLIST_ITEM_LIMIT=100
      - SUBSCRIPTION_DEFAULT_CHECK_INTERVAL=60
      - OUTPUT_TEMPLATE=%(channel)s/%(title)s.%(ext)s
```

## Cookies for members-only content

yt-dlp uses browser cookies to access members-only YouTube videos, locked Patreon media, etc.

```sh
# Export Firefox cookies for youtube.com
yt-dlp --cookies-from-browser firefox --cookies cookies.txt "https://youtube.com"
# Or use a browser extension like "Get cookies.txt LOCALLY" to export manually
```

Then mount `cookies.txt` into the container + point `YTDL_OPTIONS`.

## Behind a reverse proxy

```yaml
services:
  metube:
    image: ghcr.io/alexta69/metube:2025-10-26
    restart: unless-stopped
    environment:
      - URL_PREFIX=/metube/        # for path-prefixed proxy
```

nginx:

```nginx
location /metube/ {
    proxy_pass http://metube:8081/metube/;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

Add basic auth via nginx or oauth2-proxy / Authelia in front — **MeTube has no auth of its own**.

## Data & config layout

Inside `/downloads` (or `DOWNLOAD_DIR`):

- `<title>.mp4` / `.webm` / `.mkv` — actual video files
- `.metube/` — state files (hidden)
  - `queue.json` — in-progress downloads
  - `pending.json` — waiting-to-start downloads
  - `completed.json` — history (visible in UI's Completed panel)
  - `subscriptions.json` — saved channel subscriptions + last-seen video IDs

`STATE_DIR` defaults to `/downloads/.metube` but can be moved (useful if `/downloads` is a read-only NFS share from a different host — rare).

## Backup

Videos themselves: backup policy is your choice (often they're the backup — re-downloadable).

State:

```sh
docker cp metube:/downloads/.metube ./metube-state-$(date +%F)/
```

Losing state = subscriptions forget what they've seen (re-download everything) and completed history resets (no re-download protection until archive file is populated).

## Upgrade

1. Releases: <https://github.com/alexta69/metube/releases>. Date-tagged (e.g., `2025-10-26`).
2. `docker compose pull && docker compose up -d`.
3. yt-dlp inside the image updates with each release — often the reason to upgrade is a yt-dlp fix for a broken site.
4. **Upgrade cadence matters.** YouTube changes its player JS regularly; yt-dlp patches it; MeTube bundles new yt-dlp every 1-2 weeks. Stale MeTube = 403s from YouTube after a few months.

## Gotchas

- **No authentication built in.** Anyone who can reach port 8081 can queue downloads on your server — potential DoS on your bandwidth + disk. Put behind oauth2-proxy / Authelia / basic auth / VPN.
- **yt-dlp breakage is frequent.** YouTube routinely changes something; yt-dlp routinely catches up; MeTube rebuilds. Stale images → 403s. Subscribe to MeTube or yt-dlp releases for early warning.
- **Playlist blowouts.** Pasting a 10,000-video channel URL with no cap = fills your disk. Set `DEFAULT_OPTION_PLAYLIST_ITEM_LIMIT` or `MAX_DOWNLOADS` per yt-dlp options.
- **YouTube "SABR" rollout.** Ongoing transition where YouTube requires proof-of-origin for playback. yt-dlp is adapting; occasionally downloads fail with "Requested format is not available" until yt-dlp/MeTube catches up.
- **Cookies go stale.** Exported cookies.txt expires; re-export periodically or use `--cookies-from-browser` via a mounted browser profile.
- **Subscriptions ≠ real RSS.** MeTube polls each subscription every `SUBSCRIPTION_DEFAULT_CHECK_INTERVAL` minutes (default 60). Too-frequent polling of many channels = YouTube rate-limits your IP.
- **`SUBSCRIPTION_MAX_SEEN_IDS`** caps memory — after 50k videos it forgets old IDs and may re-download. Adjust for high-volume subscriptions.
- **Audio-only option** uses yt-dlp format selection; default is `bestaudio` → `m4a`/`opus`/`mp3`. Set `AUDIO_FORMAT` env to pin.
- **`CUSTOM_DIRS`** allows users to type free-form paths in the UI — potential for directory traversal if enabled publicly.
- **Filename templating** via `OUTPUT_TEMPLATE` (yt-dlp template syntax). Default keeps title only; `%(channel)s/%(title)s.%(ext)s` groups by channel.
- **Disk exhaustion** is the #1 issue. No built-in quota; monitor the mount.
- **Subtitle download** — set yt-dlp options to fetch subs: `{"writesubtitles": true, "subtitleslangs": ["en"]}`.
- **Legal context**: downloading copyrighted material you don't have rights to is a YouTube ToS violation and may be illegal in your jurisdiction. MeTube makes the technical act easy; the legal question is on you.
- **Platform support** follows yt-dlp's supported sites list (~1000+).
- **HTTPS mode** works via `HTTPS=true` + cert volume. Usually easier to terminate TLS at nginx/Caddy in front.
- **Resource use** per concurrent download: modest (~100 MB RAM + one yt-dlp process + ffmpeg for transcode).
- **Alternatives worth knowing:**
  - **yt-dlp CLI** — the underlying tool, no UI, scriptable
  - **Tube Archivist** — heavier, channel-archival-focused, uses Elasticsearch
  - **Tubesync** — subscription-focused; Plex/Jellyfin integration
  - **Jellyfin + media plugins** — for actually playing the archive
  - **Pinchflat** — similar to Tube Archivist but Elixir-based
  - **NewPipe** (Android) — for mobile watching, not server-side

## Links

- Repo: <https://github.com/alexta69/metube>
- Docker image: <https://github.com/alexta69/metube/pkgs/container/metube>
- Releases: <https://github.com/alexta69/metube/releases>
- Environment variables: <https://github.com/alexta69/metube#configuration-via-environment-variables>
- Cookies doc: <https://github.com/yt-dlp/yt-dlp/wiki/FAQ#how-do-i-pass-cookies-to-yt-dlp>
- yt-dlp options: <https://github.com/yt-dlp/yt-dlp#usage-and-options>
- yt-dlp supported sites: <https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>
