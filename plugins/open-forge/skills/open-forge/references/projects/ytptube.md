---
name: YTPTube
description: "Web-based GUI for yt-dlp. Python + Docker. arabcoders/ytptube. Download videos, playlists, and live streams from 1000+ sites; schedule channel/playlist downloads; built-in video player; notifications via Apprise; presets system. MIT."
---

# YTPTube

**Web-based GUI for [yt-dlp](https://github.com/yt-dlp/yt-dlp)** — makes downloading videos from 1000+ platforms easy and user-friendly. Download individual videos, playlists, full channels, and live streams. Includes scheduling, notifications via Apprise, a built-in video player with subtitle support, and a powerful presets system.

Built + maintained by **arabcoders**. MIT.

- Upstream repo: <https://github.com/arabcoders/ytptube>
- Docker image: `ghcr.io/arabcoders/ytptube`
- Discord: <https://discord.gg/G3GpVR8xpb>
- API docs: <https://github.com/arabcoders/ytptube/blob/dev/API.md>

## Architecture in one minute

- **Python** backend (yt-dlp + supporting tools)
- **SQLite** — built-in, no external DB required
- Port **8081** internal
- Volumes: `/config` (DB, settings, presets) + `/downloads` (downloaded media)
- Includes `curl-cffi` (Cloudflare bypass) and `pot provider plugin` (cookie/token handling) — Docker only
- Auto-updates yt-dlp and custom pip packages on startup — Docker only
- Resource: **medium** — Python + ffmpeg; CPU spikes during download + mux

## Compatible install methods

| Infra | Runtime | Notes |
|-------|---------|-------|
| **Docker** | `ghcr.io/arabcoders/ytptube` | **Recommended** — bundled ffmpeg, yt-dlp, curl-cffi |
| Bare metal | Python venv + ffmpeg | Manual; loses Docker-only features (curl-cffi, auto-updates) |
| Windows/macOS/Linux | Bundled executable | From GitHub releases — macOS untested |
| Unraid | Community Applications | Pre-configured template available |

## Install via Docker Compose

```yaml
services:
  ytptube:
    user: "${UID:-1000}:${UID:-1000}"   # Change to your UID:GID
    image: ghcr.io/arabcoders/ytptube:v2.5.2
    container_name: ytptube
    restart: unless-stopped
    environment:
      - YTP_TEMP_PATH=/downloads/tmp
      - YTP_DOWNLOAD_PATH=/downloads/files
    ports:
      - "8081:8081"
    volumes:
      - ./config:/config:rw
      - ./downloads:/downloads:rw
```

```bash
mkdir -p ./{config,downloads/files,downloads/tmp}
docker compose up -d
```

Visit `http://localhost:8081`.

## Key environment variables

| Variable | Default | Notes |
|----------|---------|-------|
| `YTP_DOWNLOAD_PATH` | `/downloads/files` | Where completed downloads are saved |
| `YTP_TEMP_PATH` | `/downloads/tmp` | Temp dir during download + mux |
| `YTP_CONFIG_PATH` | `/config` | Config, DB, presets |
| `YTP_HOST` | `0.0.0.0` | Bind address |
| `YTP_PORT` | `8081` | Bind port |
| `YTP_AUTH_USERNAME` | — | Enable basic auth — set both username and password |
| `YTP_AUTH_PASSWORD` | — | Basic auth password |
| `YTP_YTDLP_UPDATE` | `true` | Auto-update yt-dlp on startup (Docker only) |
| `YTP_TEMP_KEEP` | `false` | Keep temp files after download |

## Features

- **Multi-download support** — queue multiple URLs simultaneously
- **Live + upcoming streams** — handles live broadcasts and premiere streams
- **Dual UI** — regular (technical) and simple mode for non-technical users
- **Scheduled downloads** — schedule channels or playlists for automatic download; supports custom RSS-style feeds for unsupported sites
- **Notifications** — send alerts on events via [Apprise](https://github.com/caronc/apprise) (supports 80+ services: Discord, Slack, Telegram, email, etc.)
- **Per-link options** — override yt-dlp options per URL
- **Presets system** — save and reuse yt-dlp option sets; includes pre-made preset for media server (Plex/Jellyfin/Emby) users
- **File browser** — browse and manage downloaded files in the UI
- **Built-in video player** — plays downloads in-browser with sidecar external subtitle support (requires ffmpeg)
- **Basic auth** — password-protect the web UI
- **Browser extensions + bookmarklets + iOS shortcuts** — send URLs directly to YTPTube from your browser or phone
- **flaresolverr support** — bypass Cloudflare protections via [flaresolverr](https://github.com/FlareSolverr/FlareSolverr)
- **Podman compatible** — use the same compose file with `user: "0:0"`

## Gotchas

- **`user` line must match your UID:GID.** Run `id -u && id -g` to get your UID/GID. If the container runs as a different user than the volume owner, download writes will fail with permission errors.
- **Docker-only features.** `curl-cffi` (Cloudflare bypass), bundled `pot provider plugin` (for PO token handling), and auto-updating yt-dlp are only available in the Docker image.
- **ffmpeg in path required for video player.** The built-in player's subtitle support needs ffmpeg — bundled in Docker.
- **yt-dlp auto-updates.** By default, yt-dlp updates itself on each container start (`YTP_YTDLP_UPDATE=true`). Set to `false` to pin the bundled version.
- **Not for piracy.** Downloading copyrighted content without authorization may be illegal in your jurisdiction. Respect content creators and platform terms of service.
- **Solo project.** Maintained by one person; PRs may be declined if they don't align with the maintainer's vision.

## Backup

```sh
# Config + DB
tar czf ytptube-config-$(date +%F).tar.gz ./config
# Downloads are large — back up selectively
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

yt-dlp also updates automatically on startup (disable with `YTP_YTDLP_UPDATE=false`).

## yt-dlp-GUI-family comparison

- **YTPTube** — Python, scheduling, Apprise notifications, presets, file browser, video player; MIT
- **Metube** — Python, simple queue, basic UI, aria2 support; AGPL-3.0
- **Tubesync** — Python/Django, YouTube channel sync, Plex/Jellyfin integration; MIT
- **Pinchflat** — Elixir, YouTube subscriptions, media server integration; AGPL-3.0

**Choose YTPTube if:** you want a full-featured yt-dlp web GUI with scheduling, notifications, presets, and a built-in video player — more capable than Metube, less specialized than channel-sync tools.

## Links

- Repo: <https://github.com/arabcoders/ytptube>
- API docs: <https://github.com/arabcoders/ytptube/blob/dev/API.md>
- FAQ: <https://github.com/arabcoders/ytptube/blob/dev/FAQ.md>
- Discord: <https://discord.gg/G3GpVR8xpb>
