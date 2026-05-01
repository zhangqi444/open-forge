---
name: DumbAssets
description: "Self-hosted simple asset and inventory tracking tool. Docker. Node.js. DumbWareio/DumbAssets. Track physical items with photos, custom fields, QR code labels, CSV export, auth, no frills. MIT."
---

# DumbAssets

**Simple self-hosted asset and inventory tracking.** The DumbWare philosophy: do one thing, do it well, stay simple. Track physical assets — equipment, tools, devices, household items — with photos, custom fields, and QR code labels. No frills, no bloat. Part of the DumbWare ecosystem of intentionally simple self-hosted tools.

Built + maintained by **DumbWareio**. MIT license.

- Upstream repo: <https://github.com/DumbWareio/DumbAssets>
- Website: <https://dumbware.io>
- Docker Hub: <https://hub.docker.com/r/dumbwareio/dumbassets>

## Architecture in one minute

- **Node.js** backend + web frontend
- File-based storage (JSON) — no external database
- Port **3000**
- Data in `./config/` volume
- Auth: optional PIN or password protection
- Resource: **tiny** — Node.js + flat files

## Compatible install methods

| Infra      | Runtime                        | Notes                                  |
| ---------- | ------------------------------ | -------------------------------------- |
| **Docker** | `dumbwareio/dumbassets`        | **Primary** — Docker Hub; multi-arch   |

## Inputs to collect

| Input          | Example         | Phase  | Notes                                     |
| -------------- | --------------- | ------ | ----------------------------------------- |
| `DUMB_PASSWORD`| strong pin/pass | Auth   | Optional; protects the UI with a password |
| `TZ`           | `UTC`           | Config | Timezone for timestamps                   |

## Install via Docker Compose

```yaml
services:
  dumbassets:
    image: dumbwareio/dumbassets:latest
    container_name: dumbassets
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./config:/app/config
    environment:
      - TZ=UTC
      # - DUMB_PASSWORD=your_password  # optional
```

Visit `http://localhost:3000`.

## First boot

1. `docker compose up -d`.
2. Visit `http://localhost:3000`.
3. If `DUMB_PASSWORD` is set, log in.
4. Add your first asset:
   - Name, description, category
   - Upload a photo
   - Add custom fields (serial number, purchase date, location, etc.)
5. Print / scan QR code label for the asset.
6. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| Asset tracking | Name, description, category, photo per asset |
| Custom fields | Add any fields you need per asset |
| QR codes | Generate printable QR code labels for assets |
| Search + filter | Search by name, category, fields |
| CSV export | Export all assets as a CSV file |
| Authentication | Optional PIN/password protection |
| File-based storage | JSON files — no database to manage |
| Multi-arch Docker | amd64, arm64, arm/v7 |

## Gotchas

- **File-based storage means no concurrent writes.** DumbAssets stores data as JSON files — fine for personal/single-user use, but not designed for simultaneous edits from multiple users. Use one user at a time or assets may conflict.
- **No user accounts / roles.** DumbAssets has a single optional password protecting the whole UI. There's no multi-user system with individual accounts. Everyone with the password sees all assets.
- **Backups are easy.** Since everything is in `./config/`, just `tar czf backup.tgz config/` and you have a complete backup. No database dumps required.
- **Part of the DumbWare ecosystem.** DumbWare builds intentionally simple tools (DumbDrop, DumbPad, DumbAssets, etc.). If you want more features (multi-user, complex queries, equipment maintenance scheduling), use Snipe-IT instead.

## Backup

```sh
sudo tar czf dumbassets-$(date +%F).tgz config/
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active Node.js development, Docker Hub (multi-arch), part of DumbWare ecosystem. MIT license.

## Asset-tracking-family comparison

- **DumbAssets** — Node.js, flat-file JSON, QR labels, CSV export, single-user, MIT; intentionally simple
- **Snipe-IT** — PHP, full ITAM (IT Asset Management), multi-user, check-in/out, licenses, LDAP; enterprise scope
- **Grocy** — PHP, household + consumable tracking; different focus
- **Netbox** — Python, DCIM/IPAM; infrastructure assets; complex

**Choose DumbAssets if:** you want a simple, no-database, self-hosted asset inventory with QR code labels and photo support — without the complexity of Snipe-IT.

## Links

- Repo: <https://github.com/DumbWareio/DumbAssets>
- Docker Hub: <https://hub.docker.com/r/dumbwareio/dumbassets>
- DumbWare ecosystem: <https://dumbware.io>
