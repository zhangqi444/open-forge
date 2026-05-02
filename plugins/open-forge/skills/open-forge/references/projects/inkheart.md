# Inkheart

**What it is:** A self-hosted PDF library indexer and reader. Scans a directory of PDFs, generates thumbnails and covers, and provides a web UI with filesystem navigation, an embedded PDF.js reader, reading progress tracking, collections, pinned folders, and basic search. Built with Rust (backend) + Svelte (frontend). Multi-arch (AMD64 + ARM64).

**Official URL:** https://gitlab.com/Nystik/inkheart
**Container:** `nobbe/inkheart:latest`
**License:** See repo
**Stack:** Rust + Svelte + PDF.js; Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended; mount PDF library |
| Raspberry Pi 4+ / ARM64 | Docker | Native ARM64 image available |
| Apple Silicon (via Docker) | Docker | ARM64 image works on M-series Macs |

---

## Inputs to Collect

### Pre-deployment (required)
- `/path/to/media` — host path to your PDF library (mounted as `/media`)
- `/path/to/covers` — persistent cover image cache
- `/path/to/thumbnails` — persistent thumbnail cache
- `/path/to/config` — persistent config directory

### Optional (authentication)
- `FIREBASE_CONFIG_PATH` — path to a Firebase service account JSON for authentication; leave empty to disable auth
- `FIREBASE_WHITELIST` — path to a whitelist file listing allowed Firebase UIDs/emails (default: `/config/whitelist.cfg`)

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  inkheart:
    image: nobbe/inkheart:latest
    container_name: inkheart
    ports:
      - "8080:8080"
    volumes:
      - /path/to/media:/media
      - /path/to/covers:/covers
      - /path/to/config:/config
      - /path/to/thumbnails:/thumbnails
    environment:
      - MEDIA_DIR=/media
      - IMAGE_DIR=/covers
      - THUMBNAIL_DIR=/thumbnails
      - CONFIG_DIR=/config
      - BIND_ADDR=0.0.0.0
      - BIND_PORT=8080
      - SCAN_INTERVAL=600        # seconds between library rescans
      - FIREBASE_CONFIG_PATH=    # leave empty for no auth
      - FIREBASE_WHITELIST=/config/whitelist.cfg
      - TELEMETRY_ENABLED=false  # opt out of usage stats
    restart: always
```

**Default port:** `8080`

**Authentication:** Inkheart uses Firebase Auth (Google's auth service) for optional login. Without `FIREBASE_CONFIG_PATH`, the library is accessible to anyone who can reach the URL — protect with a reverse proxy or VPN if internet-facing.

**Firebase setup (if using auth):**
1. Create a Firebase project at https://console.firebase.google.com
2. Enable Authentication → Sign-in methods (e.g. Google, email/password)
3. Download the service account JSON: Project Settings → Service Accounts → Generate new private key
4. Mount the JSON into the container and set `FIREBASE_CONFIG_PATH`
5. Add allowed user UIDs/emails to the whitelist file at `FIREBASE_WHITELIST`

**Telemetry:** Enabled by default — sends server pings (version, lib size bucket, country, arch) to the author's Plausible instance. Disable with `TELEMETRY_ENABLED=false` or via the in-app Settings → Privacy toggle.

**Library structure:** Any nested folder layout works — Inkheart mirrors your filesystem hierarchy in the UI.

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **No auth by default** — without Firebase, anyone with network access can browse your PDFs; use a reverse proxy + auth or restrict to VPN/LAN
- **Firebase Auth dependency** — if you want login, you need a Google Firebase project (free tier is sufficient for personal use)
- **Telemetry is opt-out** — set `TELEMETRY_ENABLED=false` if you don't want usage data sent to the author
- **Cover/thumbnail generation** — first scan of a large library can take time; ensure the cache volumes are writable
- **Hobby project** — stable and used by the author daily, but new features may be slow to arrive

---

## Links
- GitLab: https://gitlab.com/Nystik/inkheart
- Docker Hub: https://hub.docker.com/r/nobbe/inkheart
