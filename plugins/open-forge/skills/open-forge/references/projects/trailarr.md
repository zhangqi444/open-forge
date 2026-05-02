# Trailarr

A Docker application to automatically download and manage trailers for your Radarr and Sonarr media libraries. Detects existing trailers, downloads new ones via yt-dlp, and organizes them following Plex naming conventions. Works with Plex, Emby, Jellyfin, and other media servers. Built with Python/FastAPI backend and Angular frontend.

- **Official site / docs:** https://nandyalu.github.io/trailarr/
- **GitHub:** https://github.com/nandyalu/trailarr
- **Docker image:** `nandyalu/trailarr:latest`
- **License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | Docker Compose | Single container; requires volume mapping to match Radarr/Sonarr paths |
| Linux/macOS/Windows | Direct install | systemd/launchd/Task Scheduler service with GPU HW accel support |

---

## Inputs to Collect

### Deploy Phase
| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `TZ` | Yes | — | Your timezone (e.g. `America/New_York`) |

All other configuration (Radarr/Sonarr connection, API keys, download profiles) is done through the Trailarr web UI after first launch.

### Volume Mapping (Critical)
Trailarr must share the same volume paths as Radarr/Sonarr to be able to write trailer files into your media folders. Map each media root the same way:

```yaml
volumes:
  - /path/to/config:/config
  - /your/movies/path:/media/movies   # must match Radarr's volume mapping
  - /your/tv/path:/media/tv           # must match Sonarr's volume mapping
```

See the [volumes documentation](https://nandyalu.github.io/trailarr/getting-started/01-first-things/radarr-sonarr-volumes/) for detailed guidance on mapping multiple Radarr/Sonarr instances.

---

## Software-Layer Concerns

### Config
- Trailarr config, database, and logs stored in `/config`
- All connection settings managed via web UI (no config file to hand-edit)
- Configurable download profiles (resolution, format, naming, Plex integration)

### Data Directories
- `/config` — Trailarr database, logs, settings (must be persisted)
- Media paths — must match Radarr/Sonarr volume layout exactly

### Ports
- `7889` — Web UI (configurable host port)

### Dependencies
- Radarr and/or Sonarr instances (adds connections via web UI)
- Optional: Plex Media Server (for Plex trailer detection and library scan integration)

---

## Minimal docker-compose.yml

```yaml
services:
  trailarr:
    image: nandyalu/trailarr:latest
    container_name: trailarr
    environment:
      - TZ=America/New_York
    volumes:
      - ./config:/config
      - /your/movies:/media/movies
      - /your/tv:/media/tv
    ports:
      - "7889:7889"
    restart: unless-stopped
```

---

## Upgrade Procedure

```bash
docker compose pull trailarr
docker compose up -d trailarr
```

Trailarr has internal health checks and will restart automatically when Docker detects issues (`restart: unless-stopped` or `always` required for this to work).

---

## Gotchas

- **Volume paths are critical:** Trailarr must see media files at the same paths Radarr/Sonarr use — mismatched paths will prevent trailer files from being saved; read the volumes docs carefully
- **`restart` policy required:** Internal health-check mechanism only triggers Docker restarts when `restart` is set to `unless-stopped` or `always`
- **Multiple *arr instances:** Add additional volume mappings for each Radarr/Sonarr instance; paths on the right must match what those apps use internally
- **Plex integration (v0.9+):** Optional; enables Plex trailer detection, skip-if-Plex-has-trailer profile setting, and post-download library scan
- **Direct install users upgrading to v0.9:** Must uninstall and reinstall (data is preserved when you choose to keep the data directory during uninstall)
- **Port 7889:** Choose a different host port if occupied — change the LEFT side only: `8115:7889`

---

## References
- Documentation: https://nandyalu.github.io/trailarr/
- Getting started: https://nandyalu.github.io/trailarr/getting-started/
- GitHub: https://github.com/nandyalu/trailarr
- Docker Hub: https://hub.docker.com/r/nandyalu/trailarr/
