---
name: Damselfly
description: "Server-based digital photograph management w/ AI face+object detection. Folder-based collection, fast search, keyword tags. Desktop client sync. .NET. Webreaper/Damselfly. Picasa-inspired UX."
---

# Damselfly

Damselfly is **"Google Picasa reborn — self-hosted + AI + gigapixel-fast"** — a server-based digital photograph management system for large **folder-based** collections. Features face-detection + facial-recognition + object-detection + image-color-classification. Full-text + visual-similarity search. Basket-based export (Picasa-style). Desktop/client companion for laptop sync.

Built + maintained by **Webreaper**. .NET. Extreme-performance focus (500K-image catalog returns <1s). Docker-deployable. MIT likely.

Use cases: (a) **self-hosted photo library for collectors** (b) **AI-assisted face-tagging workflow** (c) **object-search in photos** (d) **Picasa-replacement** (e) **RAW + modern format support** (f) **large-catalog fast search** (g) **desktop-sync for photo editing** (h) **family-photo archive**.

Features (per README):

- **Formats**: JPG, PNG, HEIC, TIFF, Webp, BMP, DNG/CR2/ORF/NEF (RAW)
- **AI / CV**:
  - **Face detection**
  - **Facial recognition** ("tag once, finds rest")
  - **Object detection + recognition**
  - **Image color classification**
- **Full-text search** with multi-phrase partial-word
- **Image re-organization**: move/copy/delete (trashcan)
- **Advanced search**: date range, objects/faces, camera/lens, file size, orientation, untagged
- **Visual-similarity search**
- **500K-image < 1s** search performance
- **Desktop client** for sync

- Upstream repo: <https://github.com/Webreaper/Damselfly>

## Architecture in one minute

- **.NET** server (Blazor)
- SQLite / PostgreSQL
- ML models for face + object detection (likely ONNX)
- **Resource**: moderate (heavy during initial scan)
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `photos.example.com`                                        | URL          | TLS                                                                                    |
| Photo library path   | `/photos`                                                   | Storage      | **RO mount recommended**                                                                                    |
| Thumbnail cache      | `/thumbs`                                                   | Storage      | Can be substantial                                                                                    |
| Admin                | Bootstrap                                                   | Auth         |                                                                                    |
| ML models            | On-disk                                                     | Assets       | Face + object                                                                                    |

## Install via Docker

Per upstream README:
```yaml
services:
  damselfly:
    image: webreaper/damselfly:latest        # **pin**
    ports: ["6363:6363"]
    volumes:
      - /photos:/pictures:ro        # **RO**
      - ./damselfly-config:/config
      - ./damselfly-thumbs:/thumbs
    restart: unless-stopped
```

## First boot

1. Start; browse UI
2. Configure library + thumbnail path
3. Let initial indexer + AI-scan complete (hours for large libs)
4. Start face-tagging workflow
5. Verify object-detection
6. Install desktop client (optional)
7. Put behind TLS
8. Back up `/config`

## Data & config layout

- `/config/` — DB (tags, faces, metadata)
- `/thumbs/` — thumbnail cache
- `/pictures/` — source (RO)

## Backup

```sh
sudo tar czf damselfly-$(date +%F).tgz damselfly-config/
# Contains face + object + keyword data — IDENTIFIES PEOPLE in your photos
# **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/Webreaper/Damselfly/releases>
2. Docker pull + restart
3. ML models may re-scan

## Gotchas

- **187th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — AI-FACE-RECOGNITION-OVER-FAMILY-PHOTOS**:
  - Holds: face-embeddings for **identified people in your photo library** (family, friends, strangers, kids!), object-detection, keyword tags
  - Face-embeddings + names = HIGH-severity PII
  - Kids' faces = HIGHEST-severity
  - **187th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - Matures sub-cat: **"photo-management + AI-face-recognition-over-family": 2 tools** 🎯 **2-TOOL MILESTONE — MATURED** (Damselfly joins Immich/PhotoPrism-class cluster — first formally 2-tool milestone for this specific combo)
- **CHILD-FACE-RECOGNITION-HIGHEST-SEVERITY**:
  - If photos contain children, their face-embeddings are particularly sensitive
  - **Recipe convention: "child-face-recognition-data-retention-HIGHEST-severity callout"**
  - **NEW recipe convention** (Damselfly 1st formally; HIGHEST-severity)
- **FACE-RECOGNITION-MODEL-BIAS**:
  - ML models have known bias (skin-tone, age)
  - **Recipe convention: "face-recognition-model-bias-awareness callout"**
  - **NEW recipe convention** (Damselfly 1st formally)
- **READ-ONLY-LIBRARY-MOUNT**:
  - Photo library should be RO
  - **Read-only-library-mount-discipline: 5 tools** 🎯 **5-TOOL MILESTONE** (+Damselfly)
- **AI-MODEL-SERVING-TOOL**:
  - **AI-model-serving-tool: 6 tools** (+Damselfly) 🎯 **6-TOOL MILESTONE**
- **DESKTOP-CLIENT-COMPANION**:
  - Separate desktop sync app
  - **Native-mobile-companion-app: 4 tools** (Swing Music + others); plus now "desktop-client-companion" — distinct category
  - **Desktop-client-companion-app: 1 tool** 🎯 **NEW FAMILY** (Damselfly)
- **RAW-FORMAT-SUPPORT**:
  - DNG/CR2/ORF/NEF support
  - **Recipe convention: "RAW-photo-format-support positive-signal"**
  - **NEW positive-signal convention** (Damselfly 1st formally)
- **PICASA-INSPIRED-UX**:
  - Explicit UX pedigree
  - **Recipe convention: "explicit-UX-pedigree-citation positive-signal"**
  - **NEW positive-signal convention** (Damselfly 1st formally)
- **EXTREME-PERFORMANCE-CLAIM**:
  - 500K images <1s search
  - **Recipe convention: "scale-tested-large-catalog positive-signal"**
  - Reinforces Meet (121) scale-tested-large-meetings pattern
- **INSTITUTIONAL-STEWARDSHIP**: Webreaper sole-dev + .NET + extreme-performance focus + Docker + active. **173rd tool — sole-dev-performance-focused-photo-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + releases + Docker + desktop-client. **179th tool in transparent-maintenance family.**
- **PHOTO-MANAGEMENT-CATEGORY:**
  - **Damselfly** — .NET; AI face/object; Picasa UX; desktop-client
  - **Immich** — Go/TS; mobile-first; massive ecosystem
  - **PhotoPrism** — Go; mature; ML features
  - **LibrePhotos** — Python; active ML
  - **Pigallery2** — Node; lightweight
- **ALTERNATIVES WORTH KNOWING:**
  - **Immich** — if you want mobile-first + massive ecosystem
  - **PhotoPrism** — if you want mature + polished
  - **Choose Damselfly if:** you want Picasa-UX + desktop-client + performance focus.
- **PROJECT HEALTH**: active + sole-dev + Docker. Strong.

## Links

- Repo: <https://github.com/Webreaper/Damselfly>
- Immich (alt): <https://github.com/immich-app/immich>
- PhotoPrism (alt): <https://github.com/photoprism/photoprism>
- LibrePhotos (alt): <https://github.com/LibrePhotos/librephotos>
