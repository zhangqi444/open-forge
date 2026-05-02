# Lidify

**What it is:** Music discovery tool that provides artist recommendations based on your existing Lidarr library, using Last.fm as the data source. Suggests new artists similar to ones you already have, and can automatically add them to Lidarr.

**GitHub:** https://github.com/TheWicklowWolf/Lidify  
**Docker Hub:** `thewicklowwolf/lidify`

> ⚠️ **Spotify support removed (Nov 2024):** Changes to the Spotify API prevent its use. This app now exclusively supports Last.fm. See [issue #24](https://github.com/TheWicklowWolf/Lidify/issues/24).

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | Docker Compose | Single container |
| Raspberry Pi / ARM | Docker | Multi-arch support |

---

## Prerequisites

- A running **Lidarr** instance with an API key
- A **Last.fm** account with an API key and secret (free — create at https://www.last.fm/api/account/create)

---

## Inputs to Collect

### Phase: Deploy

| Variable | Description |
|----------|-------------|
| `last_fm_api_key` | Last.fm API key (from last.fm/api/account/create) |
| `last_fm_api_secret` | Last.fm API secret |
| `mode` | Must be `LastFM` (Spotify no longer supported) |
| `lidarr_address` | URL of your Lidarr instance (default `http://192.168.1.2:8686`) |
| `lidarr_api_key` | Lidarr API key |
| `root_folder_path` | Root music folder path in Lidarr (default `/data/media/music/`) |

### Phase: Optional

| Variable | Description |
|----------|-------------|
| `PUID` / `PGID` | User/group ID to run as (default `1000`) |
| `fallback_to_top_result` | Use top result if no exact match found (default `False`) |
| `lidarr_api_timeout` | Lidarr API call timeout in seconds (default `120`) |
| `quality_profile_id` | Lidarr quality profile ID for new artists (default `1`) |
| `metadata_profile_id` | Lidarr metadata profile ID for new artists (default `1`) |
| `search_for_missing_albums` | Trigger album search when adding new artists (default `False`) |

---

## Software-Layer Concerns

- **Config volume** at `/lidify/config` — stores settings and state; persist this
- **Localtime** — mount `/etc/localtime:/etc/localtime:ro` for correct scheduling
- All Lidarr and Last.fm settings can also be configured from within the app UI after deployment

---

## Example Docker Compose

```yaml
services:
  lidify:
    image: thewicklowwolf/lidify:latest
    container_name: lidify
    volumes:
      - /path/to/config:/lidify/config
      - /etc/localtime:/etc/localtime:ro
    ports:
      - 5000:5000
    environment:
      last_fm_api_key: your_lastfm_api_key
      last_fm_api_secret: your_lastfm_api_secret
      mode: LastFM
      lidarr_address: http://lidarr:8686
      lidarr_api_key: your_lidarr_api_key
      root_folder_path: /data/media/music/
    restart: unless-stopped
```

---

## Upgrade Procedure

1. Pull new image: `docker compose pull`
2. Restart: `docker compose up -d`
3. Config persists in the mounted volume

---

## Gotchas

- **Spotify is no longer supported** — do not configure Spotify credentials; use Last.fm only
- Last.fm API key is free but requires account creation at https://www.last.fm/api/account/create
- `quality_profile_id` and `metadata_profile_id` default to `1` — verify these match your Lidarr profile IDs
- `search_for_missing_albums` defaults to `False` — enable to immediately trigger Lidarr searches for newly added artists

---

## Links

- GitHub: https://github.com/TheWicklowWolf/Lidify
- Docker Hub: https://hub.docker.com/r/thewicklowwolf/lidify
- Last.fm API: https://www.last.fm/api/account/create
