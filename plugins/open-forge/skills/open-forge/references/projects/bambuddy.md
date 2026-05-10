---
name: bambuddy
description: Recipe for self-hosting Bambuddy, a self-hosted command center for Bambu Lab 3D printers — print archive, queue management, multi-printer monitoring, and remote proxy mode without cloud dependency. Based on upstream documentation at https://github.com/maziggy/bambuddy.
---

# Bambuddy

Self-hosted command center for Bambu Lab 3D printers. Manages print history locally, queues prints, monitors multiple printers, provides remote access via Proxy Mode (end-to-end TLS), and eliminates dependency on Bambu Cloud. Scales from a single printer to a 40-printer farm. Upstream: <https://github.com/maziggy/bambuddy>. Wiki: <https://wiki.bambuddy.cool>. Stars: 1.2k+. License: MIT.

**Requirement:** Bambu Lab printer with **Developer Mode** enabled and "Store sent files on external storage" turned on in Bambu Studio/OrcaSlicer.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux host (same local network as printer) | Docker Compose (host network) | Recommended; enables printer auto-discovery |
| macOS / Windows | Docker Compose (port-mapped) | Printer discovery disabled; add printers manually by IP |
| Raspberry Pi 4/5 | Docker Compose | Multi-arch: linux/amd64, linux/arm64 |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Printer IP address | Required if not on Linux host network (auto-discover won't work on Mac/Win) |
| preflight | Printer access code | From printer display or Bambu app |
| optional | TZ | Timezone (default: Europe/Berlin) |
| optional | PORT | Web UI port (default: 8000) |
| optional | DATABASE_URL | External PostgreSQL URL (default: SQLite) |

## Docker Compose deployment

```bash
# Option A: Use upstream compose file (recommended)
curl -O https://raw.githubusercontent.com/maziggy/bambuddy/main/docker-compose.yml
docker compose up -d

# Option B: Build from source
git clone https://github.com/maziggy/bambuddy.git
cd bambuddy
docker compose up -d --build
```

Web UI: http://localhost:8000

## docker-compose.yml (key settings)

```yaml
services:
  bambuddy:
    image: ghcr.io/maziggy/bambuddy:latest
    container_name: bambuddy
    user: "${PUID:-1000}:${PGID:-1000}"
    cap_add:
      - NET_BIND_SERVICE   # Required for Proxy Mode (FTP/RTSP on privileged ports)
    network_mode: host     # Linux: enables printer auto-discovery
    # macOS/Windows: comment out network_mode and uncomment ports:
    #ports:
    #  - "${PORT:-8000}:8000"
    #  - "3000:3000"    # Virtual printer
    #  - "8883:8883"    # MQTT proxy
    #  - "990:990"      # FTP control
    volumes:
      - bambuddy_data:/app/data
      - bambuddy_logs:/app/logs
    environment:
      - TZ=${TZ:-Europe/Berlin}
      - PORT=${PORT:-8000}
      # Optional: external PostgreSQL (SQLite used by default)
      # - DATABASE_URL=postgresql+asyncpg://bambuddy:password@db:5432/bambuddy
    restart: unless-stopped

volumes:
  bambuddy_data:
  bambuddy_logs:
```

## Environment variables

| Variable | Default | Description |
|---|---|---|
| TZ | Europe/Berlin | Timezone for timestamps |
| PORT | 8000 | Web UI port |
| PUID / PGID | 1000 | User/group ID for volume permissions |
| DATABASE_URL | (SQLite) | External PostgreSQL connection string |
| VIRTUAL_PRINTER_PASV_ADDRESS | (unset) | Docker host IP for FTP passive mode in bridge/port-mapped mode |

## Data volumes

| Volume | Contents |
|---|---|
| bambuddy_data | SQLite database, print archives, virtual printer certs, backups |
| bambuddy_logs | Application logs |

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Database migrations run automatically on startup.

## Remote access (Proxy Mode)

Proxy Mode turns Bambuddy into a secure relay between your slicer and printer, enabling remote printing without Bambu Cloud:
- Proxies FTP, MQTT, camera, and file transfer with TLS using the printer's real certificate
- Requires VPN (Tailscale or WireGuard) for full end-to-end encryption
- The slicer connects to your Bambuddy host instead of the printer directly

See the [Proxy Mode setup guide](https://wiki.bambuddy.cool/features/virtual-printer/#proxy-mode-new-in-017).

## Gotchas

- **Developer Mode must be enabled on each Bambu printer.** This is a setting on the printer itself; check your printer's settings menu or the Bambu documentation.
- **host network mode required for auto-discovery on Linux.** On macOS/Windows, Docker Desktop doesn't support host mode — comment it out and uncomment the `ports:` section, then add printers manually by IP.
- `NET_BIND_SERVICE` capability is required for the FTP (port 990) and RTSP (port 322) proxies in Proxy Mode. Without it, virtual printer features silently fail.
- SQLite is the default database and suitable for most single-user setups. For multi-user farms or higher write volume, set `DATABASE_URL` to an external PostgreSQL instance.
- Print archives and virtual printer certificates are stored in `bambuddy_data` — do not run `docker compose down -v` without backing up first.

## Upstream docs

- README: https://github.com/maziggy/bambuddy/blob/main/README.md
- Wiki: https://wiki.bambuddy.cool
- Proxy Mode: https://wiki.bambuddy.cool/features/virtual-printer/
