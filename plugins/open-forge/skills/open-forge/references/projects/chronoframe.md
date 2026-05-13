---
name: ChronoFrame
description: "Smooth self-hosted personal photo gallery w/ map-explore + EXIF-parse + HDR + large-size rendering. Stable + nightly branches. HelloGitHub + ProductHunt featured. MIT. Discord. HoshinoSuzumi/chronoframe."
---

# ChronoFrame

ChronoFrame is **"personal photographer portfolio gallery — Apple-style smooth + self-hosted"** — a smooth photo display + management application supporting multiple formats + large-size rendering. **Explore on map**, **smart EXIF parsing** (capture time, geo, camera params), HDR, fluid zoom. Designed for photographers' portfolios.

Built + maintained by **HoshinoSuzumi**. MIT. Dual branches (stable + nightly). EN + 中文. Discord. **HelloGitHub + Product Hunt featured**. Live demo at lens.bh8.ga.

Use cases: (a) **photographer's online portfolio** (b) **family photo display (emphasis display)** (c) **map-explore of captured locations** (d) **EXIF-forward metadata browsing** (e) **beautiful slide-show for archived photos** (f) **large-image / HDR rendering** (g) **public-facing personal memo** (h) **minimal-admin gallery**.

Features (per README):

- **Smooth web-UI** for browse
- **Explore on map** (geo-metadata)
- **Smart EXIF** (capture time, geolocation, camera params)
- **Large-size + HDR** rendering
- **Dual-branch** (stable + nightly)
- **Multi-lingual** (EN + 中文)
- **MIT**
- **Live demo**
- **HelloGitHub + Product Hunt featured**

- Upstream repo: <https://github.com/HoshinoSuzumi/chronoframe>
- Live demo: <https://lens.bh8.ga>
- Discord: <https://discord.gg/MM4ZK4Ed7s>

## Architecture in one minute

- Nuxt/Vue likely
- SQLite default
- Docker-first
- **Resource**: low-moderate
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream (stable + nightly)                                                                                            | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `lens.example.com`                                          | URL          | TLS (public-facing typical)                                                                                    |
| Photo upload path    |  `/app/data`                                                   | Storage      |                                                                                    |
| Admin                | Bootstrap                                                   | Auth         |                                                                                    |

## Install via Docker

See README. Typical:
```yaml
services:
  chronoframe:
    image: ghcr.io/hoshinosuzumi/chronoframe:latest        # **pin** — use stable not nightly
    ports: ["3000:3000"]
    volumes:
      - ./chronoframe-data:/app/data
    restart: unless-stopped
```

## First boot

1. Start
2. Create admin
3. Upload photos
4. Verify EXIF + map
5. Customize theme
6. Put behind TLS
7. Back up `/app/data`

## Data & config layout

- `/app/data/` — DB + uploaded photos + cache

## Backup

```sh
sudo tar czf chronoframe-$(date +%F).tgz chronoframe-data/
# Contains: uploaded photos + geo-EXIF (photo-location-PII)
# **ENCRYPT**
```

## Upgrade

1. Stable channel recommended for prod; nightly for testing
2. Docker pull + restart

## Gotchas

- **188th HUB-OF-CREDENTIALS Tier 3 — PERSONAL-GALLERY-PHOTOS + EXIF-GEO**:
  - Holds: uploaded photos, EXIF geo-data (can reveal home-location of photographer), camera models
  - Distinct from Damselfly — this is **display-focused** not management-focused
  - **188th tool in hub-of-credentials family — Tier 3**
- **EXIF-GEO-HOME-LOCATION-DISCLOSURE**:
  - Photos taken at home have geo-EXIF
  - Public gallery + geo-EXIF = home-address disclosure
  - **Recipe convention: "EXIF-strip-home-geo-before-public-share callout"**
  - **NEW recipe convention** (ChronoFrame 1st formally; HIGH-severity for public-facing galleries)
- **PUBLIC-GALLERY-TYPICAL-DEPLOYMENT**:
  - Usually deployed public-facing
  - Different threat model than private
  - **Recipe convention: "public-facing-gallery-default-threat-model neutral-signal"**
  - **NEW neutral-signal convention** (ChronoFrame 1st formally)
- **DUAL-BRANCH-STABLE-NIGHTLY**:
  - Clear release-channel discipline
  - **Recipe convention: "stable-plus-nightly-dual-branch positive-signal"**
  - Reinforces Tracearr (126) nightly-CI pattern
- **PRODUCT-HUNT-FEATURED**:
  - External validation
  - **Recipe convention: "Product-Hunt-launch-featured neutral-signal"**
  - **NEW neutral-signal convention** (ChronoFrame 1st formally)
  - **Product-Hunt-featured: 1 tool** 🎯 **NEW FAMILY** (ChronoFrame)
- **HELLOGITHUB-FEATURED**:
  - Chinese OSS showcase
  - **HelloGitHub-featured: 1 tool** 🎯 **NEW FAMILY** (ChronoFrame)
- **MULTI-LINGUAL-EN-ZH**:
  - Bilingual README
  - **Recipe convention: "bilingual-README-EN-ZH positive-signal"**
  - **NEW positive-signal convention** (ChronoFrame 1st formally)
- **FREE-SUBDOMAIN-DEMO (bh8.ga)**:
  - .ga free-TLD for demo
  - **Recipe convention: "free-TLD-for-demo-site neutral-signal"**
  - **NEW neutral-signal convention** (ChronoFrame 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: HoshinoSuzumi sole-dev + MIT + Discord + Product-Hunt + HelloGitHub + dual-branch + bilingual. **174th tool — sole-dev-photographer-portfolio sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + dual-branch + releases + Discord + featured. **180th tool in transparent-maintenance family** 🎯 **180-TOOL TRANSPARENT-MAINTENANCE MILESTONE at ChronoFrame**.
- **PHOTO-GALLERY-CATEGORY:**
  - **ChronoFrame** — smooth-UX; map-EXIF; display-focused
  - **Pigallery2** — lightweight; directory-based
  - **Damselfly** — management-focused (b127)
  - **Immich** — full-featured; mobile-first
  - **Photoview** — simple; map-features
- **ALTERNATIVES WORTH KNOWING:**
  - **Pigallery2** — if you want directory-based + simple
  - **Photoview** — if you want similar + mature
  - **Choose ChronoFrame if:** you want smooth UX + map-explore + portfolio display.
- **PROJECT HEALTH**: active + Product-Hunt-launched + bilingual + dual-branch + live-demo. Strong.

## Links

- Repo: <https://github.com/HoshinoSuzumi/chronoframe>
- Live demo: <https://lens.bh8.ga>
- Pigallery2 (alt): <https://github.com/bpatrik/pigallery2>
- Photoview (alt): <https://github.com/photoview/photoview>
