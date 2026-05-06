# Nefarious

Nefarious is a web application that automatically downloads Movies and TV Shows. It uses Jackett for torrent indexing and Transmission for downloading, providing a unified interface for media acquisition with quality profiles, auto-renaming, subtitle downloads, and notification support.

**Website:** https://lardbit.github.io/nefarious/
**Source:** https://github.com/lardbit/nefarious
**License:** GPL-3.0
**Stars:** ~1,234

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | Docker Compose | Recommended (bundles Jackett + Transmission) |
| Raspberry Pi / SBC | Docker Compose | See SBC.md in repo |
| Any | VPN integration | Optional; see VPN.md in repo |

---

## Inputs to Collect

### Phase 1 — Planning
- `HOST_DOWNLOAD_PATH`: local path where downloaded media will be stored (required)
- VPN (optional): WireGuard or OpenVPN config if routing through VPN
- Notification services (optional): uses Apprise for Slack, Discord, email, etc.
- OpenSubtitles API credentials (optional, for auto subtitle downloads)
- TMDB API key (optional, for enhanced metadata)

### Phase 2 — Deployment
- `HOST_DOWNLOAD_PATH`: absolute path on host for media downloads
- `HOST_MEDIA_PATH`: (optional) separate path for organized media library
- `JACKETT_API_KEY`: retrieved from Jackett after first start
- Torrent indexers to configure in Jackett

---

## Software-Layer Concerns

### Quick Start
```bash
git clone https://github.com/lardbit/nefarious.git
cd nefarious

# Copy env template
cp env.template .env

# Edit .env — at minimum set:
# HOST_DOWNLOAD_PATH=/path/to/your/downloads
nano .env

# Start all services
docker compose up -d
```

**Note:** First start may take a few minutes to pull images and initialize.

### Service URLs (default)
| Service | URL | Purpose |
|---------|-----|---------|
| Nefarious | http://localhost:8000 | Main web UI |
| Jackett | http://localhost:9117 | Torrent indexer |
| Transmission | http://localhost:9091 | Download client |

### Key `.env` Variables
```bash
# Required
HOST_DOWNLOAD_PATH=/data/downloads

# Optional: separate organized library path
HOST_MEDIA_PATH=/data/media

# App settings
NEFARIOUS_PORT=8000
JACKETT_PORT=9117
TRANSMISSION_PORT=9091

# Transmission auth (optional)
TRANSMISSION_USERNAME=
TRANSMISSION_PASSWORD=

# Notifications (Apprise format, optional)
APPRISE_NOTIFICATION_URL=slack://token/channel

# Subtitles (optional)
OPENSUBTITLES_USERNAME=
OPENSUBTITLES_PASSWORD=

# TMDB key (optional - enhances metadata)
TMDB_API_KEY=
```

### Post-Start Configuration (Part 2)
1. Log in to Nefarious at `http://localhost:8000` with `admin` / `admin`
2. You'll be directed to Settings — configure:
   - **Jackett Host**: `jackett` (keep as-is), Port: `9117`
   - **Jackett API Token**: Copy from `http://localhost:9117` → API Key (top right)
   - **Transmission**: Host `transmission`, Port `9091`
3. Add torrent indexers in Jackett (`http://localhost:9117`) — click "+ Add indexer"
4. Test indexers in Jackett to ensure they're working
5. Save & Verify Settings in Nefarious

### Quality Profiles
Configure preferred quality per media type in Settings:
- Movies: 1080p, 4K, etc.
- TV Shows: 720p, 1080p, etc.
- Subtitle preferences (hardcoded, SRT, none)

### VPN Integration
See [VPN.md](https://github.com/lardbit/nefarious/blob/master/docs/VPN.md) for routing Transmission through VPN:
```bash
# Edit .env to set VPN provider and credentials
VPN_ENABLED=yes
VPN_PROVIDER=private internet access
VPN_USERNAME=user
VPN_PASSWORD=pass
```

### Auto-Updates
Nefarious self-updates automatically when new versions are released (checks and pulls new Docker images). If the `docker-compose.yml` itself changes, re-run setup:
```bash
git pull
docker compose up -d
```

---

## Upgrade Procedure

```bash
cd nefarious
git pull

# Pull latest images and recreate
docker compose pull
docker compose up -d

# Data is persisted in Docker volumes — no data loss on update
```

---

## Gotchas

- **Never edit docker-compose.yml directly**: All config is via `.env` by design. Editing `docker-compose.yml` directly will be overwritten on `git pull`.
- **Jackett API key required**: The most common setup issue is not copying the Jackett API key into Nefarious settings after first start.
- **Indexer quality varies**: Some torrent indexers are unreliable or require accounts. Add multiple indexers in Jackett for better coverage.
- **Transmission no default auth**: Default Transmission has no username/password; add credentials in both `transmission-settings.json` and the Nefarious settings if desired.
- **Download path permissions**: The `HOST_DOWNLOAD_PATH` must be writable by the Docker containers (owned by UID 1000 or world-writable).
- **Auto-rename depends on TMDB**: Automatic media renaming uses TMDB metadata; a TMDB API key improves accuracy.
- **Low-powered hardware**: Raspberry Pi and similar SBCs work but transcoding/high-speed downloads may be slow. See [SBC.md](https://github.com/lardbit/nefarious/blob/master/docs/SBC.md).

---

## Links
- Docs / Wiki: https://lardbit.github.io/nefarious/
- VPN Setup: https://github.com/lardbit/nefarious/blob/master/docs/VPN.md
- SBC Guide: https://github.com/lardbit/nefarious/blob/master/docs/SBC.md
- Docker Hub: https://hub.docker.com/r/lardbit/nefarious
- Troubleshooting: https://github.com/lardbit/nefarious/blob/master/docs/TROUBLESHOOTING.md
