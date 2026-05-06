---
name: headphones
description: Headphones recipe for open-forge. Automated music downloader for NZB and Torrent — auto-fetch albums by artist, integrates with SABnzbd, NZBget, Transmission, Deluge. Python install. Upstream: https://github.com/rembo10/headphones
---

# Headphones

Automated music downloader for NZB and Torrent. Add artists and Headphones automatically searches, downloads, and organizes their music — integrates with SABnzbd, NZBget, Transmission, µTorrent, Deluge, and Blackhole. Written in Python.

3,745 stars · GPL-3.0

Upstream: https://github.com/rembo10/headphones
Docs: https://github.com/rembo10/headphones/wiki

Note: Low commit activity since 2025 — check repository status before deploying in production.

## What it is

Headphones automates the full music acquisition pipeline:

- **Artist monitoring** — Add artists; Headphones tracks their discography via MusicBrainz
- **Auto-search** — Periodically searches NZB indexers and torrent sites for new releases
- **Download integration** — Sends downloads to SABnzbd, NZBget, Transmission, µTorrent, Deluge, or Blackhole
- **Post-processing** — Moves and renames downloaded files to your music library
- **Artist recommendations** — LastFM-powered "you might also like" suggestions
- **Quality settings** — Configure preferred formats (FLAC, MP3), bitrates
- **MusicBrainz integration** — Accurate artist and album metadata
- **LastFM scrobbling** — Optional scrobbling support
- **Web UI** — Browser-based interface for managing artists and downloads
- **API** — JSON API for automation

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | Python container | Community Docker images available |
| Bare metal | Python 2/3 | Git clone + direct run |
| Linux service | systemd / init.d | Run as background service |

## Inputs to collect

### Phase 1 — Pre-install
- NZB indexer API keys (NZBgeek, DogNZB, Newznab-compatible, etc.)
- Download client type and connection details (SABnzbd API key, Transmission host/port/credentials)
- Music library path
- Download directory path
- LastFM API key (optional, for scrobbling and recommendations)

### Phase 2 — Config
- HTTP port (default: 8181)
- Authentication (username / password for web UI)
- Quality preferences (format, bitrate)

## Software-layer concerns

### Config paths
- config.ini — main configuration file (auto-created on first run)
- headphones.db — SQLite database (artist/album/download tracking)
- Default data dir: ~/.headphones/ or specified via --datadir flag

### Key config.ini settings
  [General]
  http_port = 8181
  http_username = admin
  http_password = yourpassword
  music_dir = /music
  download_dir = /downloads

  [SABnzbd]
  sab_host = http://localhost:8080
  sab_apikey = REPLACE_ME

  [Transmission]
  transmission_host = localhost
  transmission_port = 9091
  transmission_username = admin
  transmission_password = password

### Docker install (community image)
  docker run -d \
    --name headphones \
    -p 8181:8181 \
    -v /path/to/config:/config \
    -v /path/to/music:/music \
    -v /path/to/downloads:/downloads \
    -e PUID=1000 \
    -e PGID=1000 \
    linuxserver/headphones:latest

Or via Docker Compose:
  version: '3'
  services:
    headphones:
      image: linuxserver/headphones:latest
      container_name: headphones
      restart: unless-stopped
      ports:
        - "8181:8181"
      environment:
        - PUID=1000
        - PGID=1000
        - TZ=America/New_York
      volumes:
        - ./config:/config
        - /path/to/music:/music
        - /path/to/downloads:/downloads

### Bare metal install
  git clone https://github.com/rembo10/headphones.git
  cd headphones
  pip install -r requirements.txt
  python Headphones.py --datadir /path/to/datadir --port 8181

Access at http://localhost:8181

## Upgrade procedure

1. Stop Headphones
2. git pull (for bare metal) or docker pull / docker compose up -d (for Docker)
3. Restart; database migrations apply automatically if needed
4. Verify artist list and download queue intact

## Gotchas

- Low maintenance activity — minimal commits since mid-2025; may not support newer Python versions or indexer API changes; evaluate alternatives (Lidarr) for active development
- NZB indexer required — Headphones searches NZB indexers; you need a paid or free Newznab-compatible indexer subscription
- MusicBrainz rate limiting — MusicBrainz API has rate limits; adding many artists rapidly may trigger throttling
- Post-processing permissions — the download client must write files that Headphones can read; align PUID/PGID with your download client
- Python 2 legacy — original code targeted Python 2; community forks and Docker images typically modernize this
- Lidarr alternative — Lidarr (lidarr.audio) is the actively maintained alternative with similar features and better indexer support
- Download client firewall — Headphones must reach your download client's API port; check firewall rules for SABnzbd/Transmission

## Links

- Upstream README: https://github.com/rembo10/headphones/blob/master/README.md
- Installation wiki: https://github.com/rembo10/headphones/wiki/Installation
- Usage guide: https://github.com/rembo10/headphones/wiki/Usage-guide
- LinuxServer Docker image: https://hub.docker.com/r/linuxserver/headphones
- Lidarr (active alternative): https://lidarr.audio
