---
name: dumbassets
description: DumbAssets is a stupid-simple self-hosted asset tracker for physical items — track models, serials, warranties, maintenance events, and components with photo/receipt uploads. Node.js + SQLite, single Docker container. Upstream: https://github.com/DumbWareio/DumbAssets
---

# DumbAssets

DumbAssets is a **"stupid simple asset tracker"** for keeping track of physical assets — computers, appliances, vehicles, tools — along with their components, warranties, maintenance schedules, and receipts. No accounts system: secured by a PIN. Runs as a single Docker container with a file-based SQLite database.

Upstream: <https://github.com/DumbWareio/DumbAssets>  
Demo: <https://dumbassets.dumbware.io>  
Docker Hub: `dumbwareio/dumbassets`  
License: GPL-3.0

## What it does

- **Asset tracking** — model, serial number, purchase date, price, description per asset
- **Component tree** — add sub-components and nested hierarchies to any asset
- **Photo + receipt uploads** — attach images and document scans to assets
- **Warranty tracking** — expiration dates with configurable notifications
- **Maintenance events** — log and schedule routine maintenance with notifications
- **Tags** — flexible tagging for organization and filtering
- **Search** — find by name, model, serial, or description
- **Apprise notifications** — built-in integration for Discord, ntfy, Telegram, etc. (no separate Apprise service required)
- **Currency configuration** — ISO 4217 currency codes + locale formatting
- **PIN authentication** with brute-force protection
- **Light / dark mode**

## Architecture

- **Single container** — Node.js ≥ 20 backend + embedded SQLite
- **Port**: `3000`
- **Storage**: `/app/data` volume (SQLite DB + uploaded files)
- **Resource footprint**: very low

## Compatible install methods

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux host | Docker (single container) | Primary method. |
| Any Linux host | Docker Compose | Recommended for environment variable management. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port to expose DumbAssets on?" | Default `3000`. |
| preflight | "Data path on host?" | e.g. `/opt/dumbassets/data`. Mounted at `/app/data`. |
| security | "PIN for access control?" | 4+ digits. Optional — omit to leave open (LAN-only use). |
| optional | "Apprise URL for notifications?" | e.g. `discord://webhook-token/channel-id`. Enables warranty + maintenance alerts. |
| optional | "Currency code + locale?" | e.g. `EUR` / `de-DE`. Defaults: `USD` / `en-US`. |

## Docker run (quick start)

```bash
docker run -d \
  --name dumbassets \
  --restart unless-stopped \
  -p 3000:3000 \
  -v ./data:/app/data \
  dumbwareio/dumbassets:latest
```

## Docker Compose

```yaml
# compose.yaml
services:
  dumbassets:
    image: dumbwareio/dumbassets:latest
    container_name: dumbassets
    restart: unless-stopped
    ports:
      - "${DUMBASSETS_PORT:-3000}:3000"
    volumes:
      - ${DUMBASSETS_DATA_PATH:-./data}:/app/data
    environment:
      NODE_ENV: production
      BASE_URL: ${DUMBASSETS_BASE_URL:-http://localhost:3000}
      DUMBASSETS_PIN: ${DUMBASSETS_PIN:-}          # leave empty for no PIN
      APPRISE_URL: ${DUMBASSETS_APPRISE_URL:-}     # leave empty to disable notifications
      CURRENCY_CODE: ${DUMBASSETS_CURRENCY_CODE:-USD}
      CURRENCY_LOCALE: ${DUMBASSETS_CURRENCY_LOCALE:-en-US}
      TZ: ${TZ:-UTC}
```

```bash
docker compose up -d
```

## Environment variables reference

| Variable | Default | Description |
|---|---|---|
| `PORT` | `3000` | Container listen port |
| `BASE_URL` | `http://localhost:3000` | Canonical URL (used in notification links) |
| `DUMBASSETS_PIN` | _(none)_ | PIN for access control (4+ digits). Omit to disable PIN. |
| `APPRISE_URL` | _(none)_ | Apprise notification URL for warranty/maintenance alerts |
| `CURRENCY_CODE` | `USD` | ISO 4217 currency code |
| `CURRENCY_LOCALE` | `en-US` | Locale for currency formatting |
| `TZ` | `America/Chicago` | Container timezone |
| `SITE_TITLE` | `DumbAssets` | Browser tab + header title |
| `DEMO_MODE` | `false` | Read-only mode |

## Reverse proxy

DumbAssets serves plain HTTP. For HTTPS, front with Caddy, Traefik, or nginx. Set `BASE_URL` to the public HTTPS URL so notification links resolve correctly.

**Caddy example:**

```caddyfile
assets.example.com {
    reverse_proxy localhost:3000
}
```

## Upgrade

```bash
docker compose pull && docker compose up -d
```

## Backup

All data (SQLite database + uploaded photos) lives in the mounted `/app/data` directory:

```bash
tar czf dumbassets-backup-$(date +%Y%m%d).tar.gz ./data
```

## Gotchas

- **`BASE_URL` must match your public URL** — notification messages include direct asset links; an incorrect `BASE_URL` generates broken links.
- **Apprise is built-in** — no need to run a separate Apprise container; pass any Apprise-compatible URL directly via `APPRISE_URL`.
- **PIN is optional** — without a PIN the app is wide open; deploy behind a VPN or authenticated reverse proxy if running on the public internet.
- **`DEMO_MODE=true`** enables a fully read-only view — useful for sharing without allowing edits.
