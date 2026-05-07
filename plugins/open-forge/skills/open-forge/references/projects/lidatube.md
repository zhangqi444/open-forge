---
name: lidatube
description: LidaTube recipe for open-forge. Finds and fetches missing Lidarr albums from YouTube via yt-dlp. Integrates with Lidarr library to auto-fill gaps. Docker. Source: https://github.com/TheWicklowWolf/LidaTube
---

# LidaTube

Tool for finding and fetching missing Lidarr albums via yt-dlp. Compares your Lidarr music library against YouTube and downloads missing albums directly into Lidarr's expected path. Supports scheduled sync, match ratio tuning, codec selection, and optional Lidarr import triggering. Docker only. GPL-3.0 licensed. Depends on yt-dlp (third-party).

Upstream: <https://github.com/TheWicklowWolf/LidaTube>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Requires existing Lidarr instance |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Lidarr installed and running | LidaTube calls Lidarr API |
| config | lidarr_address | URL of Lidarr instance, e.g. http://192.168.1.2:8686 |
| config | lidarr_api_key | Lidarr API key (Settings → General) |
| config | Downloads path | Where LidaTube writes downloaded audio files |
| config (optional) | sync_schedule | Comma-separated hours for auto-sync, e.g. `2, 20` |
| config (optional) | minimum_match_ratio | Match threshold 0-100; default 90 |
| config (optional) | preferred_codec | Default: mp3 |

## Software-layer concerns

### Env vars

| Var | Description | Default |
|---|---|---|
| PUID | User ID to run as | 1000 |
| PGID | Group ID to run as | 1000 |
| lidarr_address | Lidarr URL | http://192.168.1.2:8686 |
| lidarr_api_key | Lidarr API key | (empty) |
| lidarr_api_timeout | Lidarr API call timeout (seconds) | 120 |
| thread_limit | Max download threads | 1 |
| sleep_interval | Sleep between downloads | 0 |
| fallback_to_top_result | Use top YouTube result if no match | False |
| library_scan_on_completion | Trigger Lidarr library scan after downloads | True |
| sync_schedule | Hours to auto-sync (comma-separated, 24hr) | (disabled) |
| minimum_match_ratio | Match confidence threshold | 90 |
| secondary_search | Secondary search method (YTS or YTDLP) | YTS |
| preferred_codec | Audio codec | mp3 |
| attempt_lidarr_import | Trigger Lidarr import per song | False |

### Data dirs

| Host path | Container path | Description |
|---|---|---|
| /path/to/config | /lidatube/config | Config + cookies.txt |
| /data/media/lidatube | /lidatube/downloads | Downloaded audio files |

## Install — Docker Compose

```yaml
services:
  lidatube:
    image: thewicklowwolf/lidatube:latest
    container_name: lidatube
    environment:
      - lidarr_address=http://your-lidarr:8686
      - lidarr_api_key=your-api-key
      - sync_schedule=2, 20
      - minimum_match_ratio=90
      - preferred_codec=mp3
      - PUID=1000
      - PGID=1000
    volumes:
      - /path/to/config:/lidatube/config
      - /data/media/lidatube:/lidatube/downloads
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 5000:5000
    restart: unless-stopped
```

Access the web UI at http://yourserver:5000 to trigger manual syncs and view status.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

## Gotchas

- yt-dlp is a third-party dependency (`depends_3rdparty: true`) — YouTube changes can break downloads between updates. Keep the container updated.
- YouTube cookies file: if you're hitting rate limits or geo-restrictions, place a `cookies.txt` (exported from your browser) in the config folder. LidaTube will use it automatically.
- `minimum_match_ratio` defaults to 90 — lower it if legitimate albums are being skipped; raise it if wrong albums are being downloaded.
- `sync_schedule` has up to 10 minutes deadband — actual sync may start up to 10 minutes after the scheduled hour.
- Downloads go to `/lidatube/downloads` — make sure this path is accessible to Lidarr if you want Lidarr to import the files.

## Links

- Source: https://github.com/TheWicklowWolf/LidaTube
- DockerHub: https://hub.docker.com/r/thewicklowwolf/lidatube
