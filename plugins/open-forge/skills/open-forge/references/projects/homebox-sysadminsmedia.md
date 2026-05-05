---
name: homebox-sysadminsmedia
description: HomeBox (SysAdminsMedia) recipe for open-forge. Inventory and organization system for the home user. Single-container Docker deploy with SQLite. Upstream: https://homebox.software/
---

# HomeBox (SysAdminsMedia)

Inventory and organization system built for the home user. Track items, locations, categories, warranties, documents, and maintenance schedules. Written in Go with SQLite — minimal resources, portable, and easy to back up.

6,022 stars · AGPL-3.0

Note: This is the **SysAdminsMedia fork** (active, https://github.com/sysadminsmedia/homebox), which continues development after the original hay-kot/homebox was archived. The slug `homebox-sysadminsmedia` distinguishes it from the archived original.

Upstream: https://github.com/sysadminsmedia/homebox
Website: https://homebox.software/
Docs: https://homebox.software/en/
Demo: https://demo.homebox.software

## What it is

HomeBox provides a simple home inventory system:

- Organize items into locations, categories, and tags
- Custom fields per item
- Image attachments
- Document and warranty tracking
- Purchase date, price, and maintenance schedule tracking
- Powerful search
- Responsive web UI (works on phone/tablet/desktop)
- REST API

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Docker run | https://homebox.software/en/quick-start/ | Primary — single container, zero external dependencies |
| Docker Compose | https://homebox.software/en/quick-start/ | When composing with a reverse proxy |
| Go binary (build from source) | https://github.com/sysadminsmedia/homebox | Advanced — no Docker required |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| network | "What port to expose HomeBox on the host?" | All Docker installs (default: 3100) |
| storage | "Where should HomeBox data be stored on the host?" | All Docker installs |
| timezone | "What timezone?" | All (affects display and logs) |
| access | "Allow public registration, or lock it down after setup?" | All |

## Docker run (primary)

Upstream: https://homebox.software/en/quick-start/

    docker run -d \
      --name homebox \
      --restart unless-stopped \
      --publish 3100:7745 \
      --env TZ=America/New_York \
      --volume /opt/homebox/data:/data \
      ghcr.io/sysadminsmedia/homebox:latest

Container port is 7745; host port 3100 is conventional (change to taste).

Data directory `/data` holds the SQLite database and all uploaded images/documents.

### Image variants

| Tag | Notes |
|---|---|
| `latest` | Standard image, runs as root inside container |
| `latest-rootless` | Runs as uid 65532 — better security |
| `latest-hardened` | Hardened rootless image |

For rootless or hardened images, ensure the host data directory is owned by uid 65532:

    mkdir -p /opt/homebox/data
    chown 65532:65532 /opt/homebox/data

## Docker Compose

    services:
      homebox:
        image: ghcr.io/sysadminsmedia/homebox:latest
        container_name: homebox
        restart: unless-stopped
        ports:
          - "3100:7745"
        environment:
          - TZ=America/New_York
          - HBOX_LOG_LEVEL=info
          - HBOX_OPTIONS_ALLOW_REGISTRATION=false
        volumes:
          - homebox-data:/data

    volumes:
      homebox-data:

## Configuration (environment variables)

All config via `HBOX_` prefixed environment variables:

| Variable | Default | Notes |
|---|---|---|
| `HBOX_WEB_PORT` | `7745` | Internal container port |
| `HBOX_STORAGE_DATA` | `/data` | Data directory inside container |
| `HBOX_LOG_LEVEL` | `info` | debug / info / warn / error |
| `HBOX_LOG_FORMAT` | `text` | text or json |
| `HBOX_OPTIONS_ALLOW_REGISTRATION` | `true` | Set `false` to prevent new account creation |
| `TZ` | — | Timezone string (e.g. `America/New_York`) |

Full env var reference: https://homebox.software/en/configure/

## Upgrade

    docker pull ghcr.io/sysadminsmedia/homebox:latest
    docker stop homebox && docker rm homebox
    # Re-run the same docker run command

Or with Compose:

    docker compose pull
    docker compose up -d

HomeBox uses SQLite with built-in migrations — no manual DB migration steps required.

## Backup

The entire state is in `/data`. Back it up with:

    docker stop homebox
    tar -czf homebox-backup-$(date +%F).tar.gz /opt/homebox/data
    docker start homebox

Or copy the SQLite file live (SQLite allows hot reads but stop for consistency):

    cp /opt/homebox/data/homebox.db homebox-$(date +%F).db

## Gotchas

- **Active fork**: hay-kot/homebox is archived. Always use `sysadminsmedia/homebox` (ghcr.io/sysadminsmedia/homebox).
- **SQLite only**: No PostgreSQL support. For large households this is fine; for multi-user teams it may be limiting.
- **Data volume is everything**: Losing `/data` means losing all inventory. Back it up.
- **Rootless image uid**: `latest-rootless` and `latest-hardened` run as uid 65532 — host directory must be owned by that uid or the container will fail to write.
- **Registration control**: Default allows open registration. Set `HBOX_OPTIONS_ALLOW_REGISTRATION=false` after creating your account to lock down the instance.
- **Port**: Default internal port is 7745, not 80 or 8080. Don't forget to map it.

## Links

- GitHub: https://github.com/sysadminsmedia/homebox
- Website: https://homebox.software/
- Docs: https://homebox.software/en/
- Quick Start: https://homebox.software/en/quick-start/
- Config reference: https://homebox.software/en/configure/
- Demo: https://demo.homebox.software
