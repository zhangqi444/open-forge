# Redirecterr

**What it is:** An Overseerr webhook listener that automatically routes media requests to the correct Radarr/Sonarr instance and quality profile based on configurable filter rules (content rating, keywords, 4K flag, requester, season count, etc.). Eliminates manual approval and re-routing of media requests.

**Official URL:** https://github.com/varthe/Redirecterr
**Docker Hub:** `varthe/redirecterr`
**License:** MIT
**Stack:** Python; Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; sidecar to Overseerr/*arr stack |
| Homelab | Docker | Lightweight; minimal resource use |

---

## Inputs to Collect

### Pre-deployment
- `config.yaml` — main config file (see below)
- Overseerr URL + API token
- Radarr/Sonarr instance URLs + API keys
- Log directory path

### Runtime config (`config.yaml`)
```yaml
overseerr_url: "http://overseerr:5055"
overseerr_api_token: "your-api-token"
approve_on_no_match: true  # Auto-approve if no rule matches

instances:
  radarr:
    server_id: 0           # Position in Overseerr > Settings > Services (0-indexed, left to right)
    root_folder: /mnt/movies
    # quality_profile_id: 1    # Optional override
    # approve: false           # Optional: disable auto-approval for this instance

  radarr_anime:
    server_id: 1
    root_folder: /mnt/anime-movies

  sonarr_4k:
    server_id: 0
    root_folder: /mnt/tv-4k

filters:
  - media_type: movie
    conditions:
      keywords:
        include: ["anime", "animation"]
      contentRatings:
        exclude: [12, 16]
    apply: radarr_anime

  - media_type: movie
    is_4k: true
    conditions:
      requestedBy_username: admin
    apply: radarr_4k
```

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  redirecterr:
    image: varthe/redirecterr:latest
    container_name: redirecterr
    hostname: redirecterr
    ports:
      - 8481:8481
    volumes:
      - /path/to/config.yaml:/config/config.yaml
      - /path/to/logs:/logs
    environment:
      - LOG_LEVEL=info
```

**Default port:** `8481`

**Overseerr webhook setup:**
1. Go to **Overseerr → Settings → Notifications → Webhook**
2. ⚠️ **Disable automatic request approval** for your users first
3. Set **Webhook URL**: `http://redirecterr:8481/webhook`
4. Enable notification type: **Request Pending Approval**
5. Use the JSON payload template from the README (includes `notification_type`, `media`, `request`, `{{extra}}`)

**Filter conditions available:** `keywords.include/exclude`, `contentRatings.include/exclude`, `requestedBy_username`, `is_4k`, `max_seasons`

**`server_id`:** Matches the left-to-right order of services in Overseerr Settings → Services. First service = 0.

**Quality profile ID:** Get from `http://<arr-url>/api/v3/qualityProfile?apiKey=<api-key>`

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Disable Overseerr auto-approval first** — if auto-approval is on, requests are approved before Redirecterr can intercept them
- **`server_id` is position-based** — if you reorder services in Overseerr UI, update your `server_id` values
- **`approve_on_no_match: true`** — with this on, unmatched requests go to Overseerr's default instance; set to `false` to hold them for manual review
- **Overseerr only** — does not support Jellyseerr or other request managers without modification
- **No HTTPS** — designed to run inside a Docker network alongside Overseerr; not meant to be internet-facing

---

## Links
- GitHub: https://github.com/varthe/Redirecterr
- Docker Hub: https://hub.docker.com/r/varthe/redirecterr
