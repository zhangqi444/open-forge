# Deluge

Lightweight, cross-platform BitTorrent client with a daemon/client architecture. Deluge separates the backend daemon (`deluged`) from the UI — clients connect via GTK UI, a web UI (port 8112), or a console UI. Ideal for headless servers where you manage torrents remotely via the web interface.

**Official site:** https://deluge-torrent.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose (`linuxserver/deluge`) | Most common self-hosted approach |
| Any Linux host | pip / system package + systemd | Native daemon with web UI |
| Raspberry Pi / ARM | Docker | ARM64 image in linuxserver |
| NAS (Synology, QNAP) | Docker | Use linuxserver image |

---

## Inputs to Collect

### Phase 1 — Planning
- Download directory path (where torrents save to)
- Watch directory for auto-add `.torrent` files (optional)
- Web UI port (default `8112`)
- VPN/network interface binding (optional, for kill-switch setups)

### Phase 2 — Deployment
- `PUID` / `PGID` — Linux user/group ID for file permission alignment
- `TZ` — timezone
- Volume paths for config and downloads

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  deluge:
    image: lscr.io/linuxserver/deluge:latest
    container_name: deluge
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - DELUGE_LOGLEVEL=error   # optional
    volumes:
      - ./config:/config
      - /data/downloads:/downloads
    ports:
      - "8112:8112"     # Web UI
      - "6881:6881"     # BitTorrent port (TCP)
      - "6881:6881/udp" # BitTorrent port (UDP)
    restart: unless-stopped
```

> **Note:** The `linuxserver/deluge` image is the de-facto standard for Docker deployments — it includes the web UI and daemon in a single container with proper PUID/PGID support.

### Environment Variables
| Variable | Default | Purpose |
|----------|---------|---------|
| `PUID` | `1000` | User ID for file ownership |
| `PGID` | `1000` | Group ID for file ownership |
| `TZ` | `Etc/UTC` | Timezone |
| `DELUGE_LOGLEVEL` | — | Log level: `info`, `warning`, `error`, `debug` |

### Native Install (Ubuntu/Debian)

```bash
sudo apt-get install deluged deluge-web

# Start daemon and web UI
deluged
deluge-web --fork

# Web UI available at http://localhost:8112
# Default password: deluge (change on first login)
```

### Systemd Units

```ini
# /etc/systemd/system/deluged.service
[Unit]
Description=Deluge Bittorrent Daemon
After=network.target

[Service]
User=debian-deluged
ExecStart=/usr/bin/deluged -d
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Config Paths (Docker)
- `/config/` — Deluge config files, session state, plugins
- `/downloads/` — download destination directory

### Web UI Access
- URL: `http://localhost:8112`
- Default password: `deluge` — **change on first login**

---

## Upgrade Procedure

**Docker:** `docker compose pull && docker compose up -d`

**pip:** `pip3 install --upgrade deluge`

**System package:** `sudo apt-get update && sudo apt-get upgrade deluge`

---

## Gotchas

- **Default password is `deluge`** — change it immediately in the web UI Preferences.
- **BitTorrent port forwarding:** Forward TCP+UDP port 6881 (or your configured port) on your router for optimal connectivity.
- **PUID/PGID must match** the owner of your download directory — otherwise Deluge can't write files.
- **Plugin compatibility:** Plugins must match the Deluge version; check compatibility when upgrading.
- **VPN binding:** To bind Deluge to a VPN interface, set the incoming interface in Preferences → Network → Interface.
- **Remote daemon connection:** To connect from a desktop GTK client, enable the daemon's remote connections in preferences and allow the port (default 58846) through the firewall.

---

## References
- GitHub: https://github.com/deluge-torrent/deluge
- Official site: https://deluge-torrent.org/
- linuxserver image: https://docs.linuxserver.io/images/docker-deluge/
- Docs: https://deluge.readthedocs.io/
