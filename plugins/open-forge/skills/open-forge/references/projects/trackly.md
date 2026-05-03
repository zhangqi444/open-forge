---
name: trackly-project
description: Web app for tracking music releases from artists in a Jellyfin music library, with optional Discord notifications. Upstream: https://github.com/7eventy7/trackly
---

# Trackly

Modern web application for tracking music releases from artists in your Jellyfin music library. Provides a beautiful browsing interface with artist pages, album covers, smart filtering by year, and optional Discord webhook notifications for new releases via MusicBrainz. Upstream: <https://github.com/7eventy7/trackly>.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | [GitHub README](https://github.com/7eventy7/trackly#using-docker-compose-recommended) | ✅ | Recommended |
| Docker build | [GitHub](https://github.com/7eventy7/trackly) | ✅ | Development / custom builds |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which install method?" | options | All |
| config | Path to Jellyfin music directory | path | All |
| config | Path for persistent data storage | path | All |
| config | Discord webhook URL (optional) | URL | Optional |
| config | Discord role ID to mention (optional) | string | Optional |
| config | Update interval cron (default: `0 0 * * *`) | cron | All |

## Required folder structure

Trackly expects Jellyfin's music library layout:

```
/music/
├── Artist1/
│   ├── backdrop.png  # 16:9 aspect ratio
│   ├── cover.png     # square (1:1)
│   ├── Album1/
│   └── Album2/
└── Artist2/
    ├── backdrop.png
    ├── folder.png    # square alternative to cover.png
    └── Album1/
```

Image formats: PNG, JPG, JPEG, or WebP.

## Docker Compose install

Source: <https://github.com/7eventy7/trackly>

```yaml
version: '3.8'
services:
  trackly:
    image: 7eventy7/trackly:latest
    ports:
      - "11888:11888"
    volumes:
      - /path/to/music:/music:ro
      - /path/to/trackly/data:/data
    environment:
      - UPDATE_INTERVAL=0 0 * * *
      - DISCORD_WEBHOOK=https://discord.com/api/webhooks/your-webhook
      - NOTIFY_ON_SCAN=false
      - DISCORD_NOTIFY=true
    restart: unless-stopped
    container_name: trackly
```

## Configuration

| Variable | Default | Description |
|---|---|---|
| `UPDATE_INTERVAL` | `0 0 * * *` | Cron schedule for release checks |
| `DISCORD_NOTIFY` | `true` | Enable Discord notifications during scan |
| `NOTIFY_ON_SCAN` | `false` | Send notification on scan completion |
| `DISCORD_WEBHOOK` | required if notify | Discord webhook URL |
| `DISCORD_ROLE` | optional | Discord role ID to mention |

Volumes:
- `/music` — Jellyfin music directory (mount read-only recommended)
- `/data` — persistent application data

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- Each Trackly container can only track **one** music library. Use separate containers for multiple libraries.
- Artist backdrop images must be 16:9; cover/folder images must be 1:1 (square).
- Supports AMD64 and ARM64 (including Raspberry Pi).

## References

- GitHub: <https://github.com/7eventy7/trackly>
- Docker Hub: <https://hub.docker.com/r/7eventy7/trackly>
