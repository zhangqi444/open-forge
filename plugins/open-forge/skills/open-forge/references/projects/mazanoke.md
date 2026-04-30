---
name: MAZANOKE
description: "Local-browser image optimizer + converter. Runs 100% in browser; offline-capable PWA. Privacy-first: images never leave device. EXIF-strip. Multi-format convert (JPG/PNG/WebP/ICO from HEIC/AVIF/TIFF/GIF/SVG). civilblur maintainer. Designed to share with family."
---

# MAZANOKE

MAZANOKE is **"TinyPNG / ImageOptim — but 100%-browser + offline + family-friendly + zero-server-side"** — a self-hosted **local image optimizer + converter**. Runs 100% in-browser (client-side); works **offline**; keeps your images private — **never leaves your device**. Adjust quality, target file-size, max dimensions, paste from clipboard. **Convert between JPG/PNG/WebP/ICO**. **Convert from HEIC/AVIF/TIFF/GIF/SVG**. **Removes EXIF data** (location, date, etc.). **No tracking**. **Installable web-app (PWA)**.

Built + maintained by **civilblur**. License: check LICENSE. Active; installable PWA; designed to be "shared with family and friends" (non-tech-user friendly).

Use cases: (a) **family-friendly image-optimizer** — "here Mom, just use this" (b) **privacy-first image-conversion** — HEIC from iPhone → JPG/WebP without cloud (c) **alternative to sketchy online "free" tools** — no ads, no tracking, no uploads (d) **EXIF-stripper before sharing** (location-scrub) (e) **web-publisher image-optimization** — compress before upload to blog/site (f) **HEIC-converter for cross-platform sharing** (g) **bulk-image-processing for parents/non-tech** (h) **offline-usable on plane/travel** — no internet needed.

Features (per README):

- **In-browser processing** (client-side)
- **Offline-capable** PWA
- **Adjust quality / target file-size / max dimensions**
- **Paste from clipboard**
- **Convert to**: JPG, PNG, WebP, ICO
- **Convert from**: HEIC, AVIF, TIFF, GIF, SVG (additional inputs)
- **EXIF-stripping** (privacy)
- **No tracking**
- **PWA-installable**

- Upstream repo: <https://github.com/civilblur/mazanoke>

## Architecture in one minute

- **Pure client-side web-app**
- **Served as static HTML/JS**
- **Resource on server**: MINIMAL — just serves static files
- **Client-side**: Browser's image-processing APIs
- **No DB, no backend, no storage on server**

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker (static)** | **nginx + static HTML**                                        | Self-host                                                                        |
| **Static hosting** | **S3 / Netlify / Vercel / GitHub Pages**                        | **Primary for static apps**                                                                                   |
| **Direct HTML**    | Extract + serve                                                                            | Minimal                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `image.example.com`                                         | URL          | TLS (required for PWA)                                                                                    |
| Static file path     | Build output directory                                      | Static       |                                                                                    |

## Install via Docker (static)

```yaml
services:
  mazanoke:
    image: nginx:alpine
    volumes:
      - ./dist:/usr/share/nginx/html:ro
    ports: ["8080:80"]
    restart: unless-stopped
```

Or any static-site host.

## First boot

1. Deploy static build
2. Ensure TLS (PWA requires HTTPS)
3. Share URL with family
4. Install as PWA on target devices
5. That's it — no admin, no users, no config

## Data & config layout

- **NONE on server** — pure static
- Client-side: browser localStorage (if any user settings)

## Backup

NONE — static files are the tool. Re-deploy from repo anytime.

## Upgrade

1. Releases: <https://github.com/civilblur/mazanoke/releases>. Active.
2. Rebuild + redeploy static output

## Gotchas

- **106th HUB-OF-CREDENTIALS TIER N/A — NEAR-ZERO-RISK POSITIVE-SIGNAL**:
  - **No server-side-data-at-rest** — compromise of server reveals nothing
  - **No user accounts on server** — no credential-hub
  - **Client-side processing** — images never hit network (except CDN for HTML/JS delivery)
  - **ARGUABLY NOT a hub-of-credentials tool** — flagging as "zero-credential-hub"
  - **106th tool in hub-of-credentials family — Tier 4 / ZERO**
  - **NEW category: "Zero-credential-hub tool" (Tier 4 / NULL)** — 1st named (MAZANOKE)
  - **NEW sub-family: "zero-server-side-data-at-rest"** (MAZANOKE 1st) — positive-signal for privacy-first tools
  - Opposite end of spectrum from CROWN-JEWEL Tier 1
  - Only "credential-like" concern: PWA-cache on client devices — standard browser security
- **PURE-STATIC-SITE = MINIMAL-ATTACK-SURFACE**:
  - No runtime code execution on server
  - No database
  - No auth
  - No user-data
  - **Recipe convention: "pure-static-site-minimal-attack-surface" positive-signal** (reinforces EventCatalog 108 + extends to even-more-static MAZANOKE)
  - **Static-site-generated-no-runtime-vulnerabilities: 2 tools** (EventCatalog + MAZANOKE) 🎯 **2-TOOL MILESTONE**
- **OFFLINE-CAPABLE PWA**:
  - Service-worker caches app
  - Works without network
  - **Recipe convention: "offline-capable-PWA positive-signal"** extended
- **CLIENT-SIDE-ONLY PROCESSING**:
  - Browser does all work
  - Privacy-first by architecture
  - **Recipe convention: "client-side-only-processing privacy-architecture" positive-signal**
  - **NEW positive-signal convention** (MAZANOKE 1st)
- **EXIF-STRIPPING BY DEFAULT**:
  - Location + date + camera-model removed on optimize
  - Good privacy-default
  - **Recipe convention: "EXIF-stripping-privacy-default positive-signal"**
  - **NEW positive-signal convention** (MAZANOKE 1st)
- **DESIGNED-TO-BE-SHARED-WITH-FAMILY**:
  - Deliberate non-tech-user accessibility
  - Alternative to "questionable free online tools"
  - **Recipe convention: "self-host-for-family-and-friends positive-signal"**
  - **NEW positive-signal convention** (MAZANOKE 1st formally; very aligned with AGENTS.md family ethos)
- **NO TRACKING**:
  - Explicit design commitment
  - **Recipe convention: "no-tracking-explicit-commitment positive-signal"**
- **ZERO-LOCK-IN**:
  - Output is standard image formats
  - No proprietary DB or formats
  - **Zero-lock-in: 7 tools** (prior 6 + **MAZANOKE**) 🎯 **7-TOOL MILESTONE**
- **STATELESS**:
  - **Stateless-tool-rarity: 9 tools** (+MAZANOKE) 🎯 **9-TOOL MILESTONE**
- **HEIC CONVERSION**:
  - HEIC is Apple-specific; non-Apple devices often can't open
  - MAZANOKE converts HEIC → JPG/PNG/WebP locally
  - **Solves practical daily frustration** (receiving HEIC from iPhone users)
- **IMAGE-OPTIMIZER-CATEGORY:**
  - **MAZANOKE** — client-side + PWA + offline
  - **TinyPNG** (commercial web-service) — server-side
  - **ImageOptim** (Mac desktop) — native
  - **Squoosh** (Google; client-side, similar approach)
  - **ShrinkMe** / similar
  - **ImgBot** — Git-commit automation
- **SQUOOSH COMPARISON**:
  - Google Squoosh is similar (client-side) but hosted by Google
  - MAZANOKE lets you self-host the concept (and TRUST your own deployment)
  - **Recipe convention: "trust-your-deployment-not-vendor positive-signal"**
  - **NEW positive-signal convention** (MAZANOKE 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: civilblur sole-maintainer + family-and-friends-focus. **92nd institutional-stewardship + sole-maintainer-with-community sub-tier.**
- **TRANSPARENT-MAINTENANCE**: active + PWA + static-site + OSS + screenshots + docs. **100th tool in transparent-maintenance family** 🎯 **100-TOOL MILESTONE**.
- **ALTERNATIVES WORTH KNOWING:**
  - **Squoosh** — if you don't want to self-host (Google-hosted)
  - **ImageMagick** — if you want CLI batch-processing
  - **Sharp / pngquant / mozjpeg** — if you want programmatic
  - **Choose MAZANOKE if:** you want self-hosted + client-side + PWA + family-friendly.
- **PROJECT HEALTH**: active + sole-maintainer + PWA + family-friendly-ethos + static-site. Strong; very low operational burden.

## Links

- Repo: <https://github.com/civilblur/mazanoke>
- Squoosh (alt): <https://squoosh.app>
- ImageOptim (Mac desktop): <https://imageoptim.com>
- TinyPNG (commercial web): <https://tinypng.com>
