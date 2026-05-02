# Pixelfin

**What it is:** A lightweight Flask web app that generates HTML artwork galleries and ZIP archives from your Jellyfin photo library. Shows which image types (Primary, Backdrop, ClearArt, Logo, etc.) are present, missing, or below a minimum resolution — making it easy to spot and fix gaps in your media artwork. Also supports restoring images from a ZIP backup with dry-run and comparison modes.

**Official URL:** https://github.com/nothing2obvi/pixelfin
**Container:** `ghcr.io/nothing2obvi/pixelfin:latest`
**License:** MIT
**Stack:** Python (Flask) + Pillow; minimal resource footprint

> ⚠️ **Security Notice:** Pixelfin is not designed for public exposure. Run it on your local network or behind a trusted VPN only.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Homelab / local machine | Docker Compose | Recommended; persists output and cache |
| Local machine | Python (no Docker) | Quick start; requires Python 3.9+ and pip |

---

## Inputs to Collect

### Runtime (configured via web UI)
- Jellyfin server URL
- Jellyfin API key
- Library name to inspect
- Gallery colors, image types to include
- Minimum resolution threshold for low-res detection

### Pre-deployment
- `TZ` — timezone (e.g. `America/Phoenix`) for correct timestamps
- `CACHE_DIR` — path inside container for image cache

---

## Software-Layer Concerns

**Docker Compose:**
```yaml
services:
  pixelfin:
    image: ghcr.io/nothing2obvi/pixelfin:latest
    container_name: pixelfin
    ports:
      - "1280:1280"
    volumes:
      - ./output:/app/output
      - ./data:/app/data
    restart: unless-stopped
    environment:
      - TZ=America/Phoenix
      - CACHE_DIR=/app/data/cache
```

**Default port:** `1280` (also try `http://<local-ip>:1280` if localhost doesn't work)

**Without Docker:**
```bash
pip install Flask pillow requests
python app.py
# Open http://localhost:1280
```

**Gallery features:**
- Summary table at top — click item title to jump to its entry
- Each entry shows all image types in two columns (Primary/Thumb/ClearArt/Menu | Backdrop/Banner/Box/BoxRear/Disc/Logo)
- Item titles link directly to the media item in Jellyfin
- Highlights missing images and low-resolution images per your threshold
- Light / dark / auto theme

**Output formats:**
- **HTML** — scrollable gallery; optionally embeds images directly for a portable self-contained file
- **ZIP** — bundles selected images; useful for backup or migrating artwork between libraries

**Restore from ZIP:**
- Restores library images from a Pixelfin-generated ZIP
- Dry-run mode for safe preview
- Configurable matching threshold
- Manual confirm for matches below threshold
- Optional comparison HTML (before/after view)

**Upgrade procedure:**
1. `docker compose pull`
2. `docker compose up -d`

---

## Gotchas

- **Do not expose to the internet** — no authentication; designed for LAN/trusted network use only
- **Generation time scales with library size** — large libraries can take a while; keep the tab open
- **Vibe-coded project** — created by the author with zero coding experience via ChatGPT; functional and actively used, but not polished code; contributions welcome
- **If localhost fails, use local IP** — `http://<local-ip>:1280` works when `localhost:1280` does not (common on Docker installs)
- **Cache dir** — set `CACHE_DIR` to a persisted volume path to avoid re-downloading image cache on each restart

---

## Links
- GitHub: https://github.com/nothing2obvi/pixelfin
- Container: ghcr.io/nothing2obvi/pixelfin:latest
