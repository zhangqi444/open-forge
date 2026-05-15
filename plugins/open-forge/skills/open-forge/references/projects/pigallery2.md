---
name: PiGallery2
description: "Fast directory-first photo gallery optimized for low-resource servers (especially Raspberry Pi). Read-only mount; photos never modified. Node.js + TypeScript. MIT. bpatrik sole. Coveralls-tested."
---

# PiGallery2

PiGallery2 is **"static photo-gallery — but with thumbnails + albums + map + searches — optimized for a Raspberry Pi"** — a **fast directory-first** photo gallery. Mount your photo folder; PiGallery2 shows it **as-is** (folder-structure preserved); **never modifies your files** (read-only). Optimized for Raspberry Pi and low-end hardware.

Built + maintained by **bpatrik** (sole). License: **MIT**. Active; Coveralls test-coverage badge; GitHub Actions Docker-buildx; Render.com live demo; official docs-site on GitHub Pages.

Use cases: (a) **family photo gallery on RPi** — low-end hardware (b) **read-only private photo-share** — link shares (c) **existing-folder-structure photography** — no re-import (d) **budget-home-NAS** photo layer (e) **classroom photo-sharing** (f) **travel-photo archive** (g) **non-AI, no-face-tagging, no-cloud, just-files** minimalist (h) **static-file-backup-compatible** — just files on disk.

Features (per README):

- **Fast** — low-resource
- **Simple** — point at folder
- **Directory-first** — folder structure preserved
- **Read-only** — photos NEVER modified

- Upstream repo: <https://github.com/bpatrik/pigallery2>
- Docs: <http://bpatrik.github.io/pigallery2/>
- Demo: <https://pigallery2.onrender.com/>

## Architecture in one minute

- **Node.js + TypeScript**
- **SQLite** (thumbnails index)
- **Resource**: very-low — designed for RPi (can run with ~200MB RAM)
- **Port**: web UI
- **Thumbnail cache**: on-disk (regeneratable)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream image**                                              | **Primary (recommended)**                                                                        |
| **Native**         | Node.js (unsupported)                                                                                                  | Possible; not recommended                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `photos.example.com`                                        | URL          | TLS                                                                                    |
| Photo directory      | `/media/photos` — READ-ONLY mount                           | Storage      | **Never modified**                                                                                    |
| Config dir           | Persistent                                                  | Storage      | Thumbnails cache                                                                                    |
| Admin / users        | Built-in                                                    | Bootstrap    |                                                                                    |

## Install via Docker

Follow: <http://bpatrik.github.io/pigallery2/setup/docker>

```yaml
services:
  pigallery2:
    image: bpatrik/pigallery2:3.5.2        # **pin version**
    volumes:
      - ./pigallery2-config:/app/data/config
      - ./pigallery2-db:/app/data/db
      - /media/photos:/app/data/images:ro        # **read-only!**
      - ./pigallery2-tmp:/app/data/tmp
    environment:
      NODE_ENV: production
    ports: ["8080:80"]
    restart: unless-stopped
```

## First boot

1. Start; browse web UI
2. Create admin user
3. Scan first album; verify thumbnail generation
4. Test share-link (private/public)
5. Put behind TLS reverse proxy
6. Back up config + DB (thumbnails are regeneratable)

## Data & config layout

- `/app/data/config/` — config
- `/app/data/db/` — SQLite (users, thumbnails index)
- `/app/data/images/` — READ-ONLY source
- `/app/data/tmp/` — thumbnail cache (regeneratable)

## Backup

```sh
sudo tar czf pigallery2-$(date +%F).tgz pigallery2-config/ pigallery2-db/
# Images are the SOURCE — back up independently
```

## Upgrade

1. Releases: <https://github.com/bpatrik/pigallery2/releases>. Active.
2. Docker pull + restart
3. SQLite auto-migrate

## Gotchas

- **130th HUB-OF-CREDENTIALS TIER 3 — MILD**:
  - User accounts + share-links + photo-index (faces optional) + thumbnail cache
  - **130th tool in hub-of-credentials family — Tier 3**
- **READ-ONLY-DESIGN = EXCELLENT**:
  - Photos NEVER modified by PiGallery2
  - Even if compromised, source-of-truth untouched
  - **Read-only-library-mount-discipline: 4 tools** (Polaris+Kyoo+Stump+PiGallery2) 🎯 **4-TOOL MILESTONE**
  - **Recipe convention: "read-only-source-design-principle positive-signal"** — reinforces
- **DIRECTORY-FIRST-PHILOSOPHY**:
  - Folder-structure = IS the data model
  - Contrast with Immich/PhotoPrism which impose their own model
  - **Recipe convention: "directory-first-data-model positive-signal"**
  - **NEW positive-signal convention** (PiGallery2 1st formally)
- **RASPBERRY-PI-FIRST-CLASS-SUPPORT**:
  - **Raspberry-Pi-first-class-support: 2 tools** (DockSTARTer+PiGallery2) 🎯 **2-TOOL MILESTONE**
- **NO-AI-NO-FACES-NO-CLOUD**:
  - Intentional minimalism
  - Contrast with Immich (cloud-like features)
  - **Recipe convention: "intentional-minimalism positive-signal"**
  - **NEW positive-signal convention** (PiGallery2 1st formally)
- **THUMBNAIL-CACHE-REGENERATABLE**:
  - Cache can be thrown away — rebuilds on next scan
  - Good for ops (tmp dir can be ephemeral)
  - **Recipe convention: "regeneratable-cache-ephemeral-OK positive-signal"**
  - **NEW positive-signal convention** (PiGallery2 1st formally)
- **SHARE-LINK SECURITY**:
  - Share-links can be public or private
  - URL-as-access-credential = see Chitchatter (114) pattern
  - **Recipe convention: "share-link-URL-as-credential callout"**
- **COVERALLS-TEST-COVERAGE BADGE**:
  - Public test-coverage
  - **Recipe convention: "Coveralls-test-coverage-badge positive-signal"**
  - **NEW positive-signal convention** (PiGallery2 1st formally)
- **RENDER.COM DEMO (may-cold-start)**:
  - "First load may take up to 60s while the server boots up"
  - Transparent about free-tier cold-start
  - **Cold-start-latency-UX-tradeoff: 2 tools** (+PiGallery2) 🎯 **2-TOOL MILESTONE**
- **NATIVE-INSTALL EXPLICITLY UNSUPPORTED**:
  - Author-communicated deploy-boundary
  - **Recipe convention: "explicit-unsupported-install-path positive-signal"**
  - **NEW positive-signal convention** (PiGallery2 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: bpatrik sole + docs-site + tests-badge + long-running + MIT + Render-demo. **116th tool — sole-maintainer-with-docs-site sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + Coveralls + docs-site + Render-demo + Docker + releases + star-history chart. **122nd tool in transparent-maintenance family.**
- **PHOTO-GALLERY-CATEGORY:**
  - **PiGallery2** — static-feel; directory-first; RPi-friendly
  - **Immich** — Google-Photos-alternative; feature-heavy
  - **PhotoPrism** — AI-features; Go
  - **Piwigo** — PHP; mature; traditional
  - **Lychee** — PHP; modern-looking; SQLite/PG
  - **Nextcloud Memories/Photos** — Nextcloud-ecosystem
- **ALTERNATIVES WORTH KNOWING:**
  - **Immich** — if you want Google-Photos-replacement features
  - **Piwigo** — if you want mature + traditional
  - **Lychee** — if you want modern UI + PHP
  - **Choose PiGallery2 if:** you want fast + RPi + read-only + directory-first minimalism.
- **PROJECT HEALTH**: active + tested + docs + demo + low-resource-first. Strong for niche.

## Links

- Repo: <https://github.com/bpatrik/pigallery2>
- Docs: <http://bpatrik.github.io/pigallery2/>
- Demo: <https://pigallery2.onrender.com/>
- Immich (alt): <https://github.com/immich-app/immich>
- Piwigo (alt): <https://github.com/Piwigo/Piwigo>
