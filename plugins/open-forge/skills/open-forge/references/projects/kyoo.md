---
name: Kyoo
description: "Portable self-hosted media server (movies/series/anime). Jellyfin/Plex alternative. Dynamic transcoding, intro/credit detection, OIDC, Helm chart. zoriya sole. React-Native frontend. Discord + Swagger API."
---

# Kyoo

Kyoo is **"Jellyfin / Plex — but 'no manual metadata' + dynamic transcoding + anime-name-parsing-works + OIDC-by-default"** — a self-hosted media server. Movies + Series + Anime. Aims at **low-maintenance**: no required folder-structure, no manual metadata edits. Media not scanned correctly (even weird names) = **bug** (not user-error). No plugin system — features built-in. Frontend: React-Native (shared code → web + mobile clients).

Built + maintained by **zoriya** (sole; recent v5 rewrite). License: check LICENSE. Active; Discord; Swagger API docs; official Helm chart; hardware transcoding supported.

Use cases: (a) **Jellyfin-alternative** — simpler metadata (b) **anime library** — parser handles weird fansub names (c) **Plex-replacement for OSS-first users** (d) **home-media-server for non-tech family** — less-maintenance (e) **Kubernetes-native media** — Helm chart available (f) **OIDC-integrated household** — Google/Authelia SSO (g) **intro-skip automation** — fingerprinting (h) **hardware-transcoding** — NVIDIA/Intel GPU.

Features (per README):

- **Dynamic transcoding** (seek instantly; auto-quality)
- **Video preview thumbnails** on scrub
- **Intro/credit detection** (audio fingerprinting OR chapter-title matching)
- **Enhanced subtitle support** (PGS/VODSUB + SSA/ASS; embedded fonts)
- **Anime name parsing** (weird fansub names)
- **Helm chart** (Kubernetes)
- **OIDC** (Google, Discord, Authelia, etc.)
- **Swagger API docs**
- ~Watch-list sync (SIMKL)~ (soon in v5)
- ~Download/offline~ (soon)

- Upstream repo: <https://github.com/zoriya/Kyoo>
- Install guide: <https://github.com/zoriya/Kyoo/blob/master/INSTALLING.md>
- API docs: <https://kyoo.zoriya.dev/swagger>
- Discord: <https://discord.gg/E6Apw3aFaA>

## Architecture in one minute

- **Multiple services** (transcoder + API + scanner + frontend)
- **Frontend**: React-Native + Expo (web + mobile shared)
- **PostgreSQL** DB
- **Port**: web UI + API
- **Resource**: moderate-high — 500MB-1GB+ RAM; GPU optional for HW transcoding

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream**                                                    | **Primary**                                                                        |
| **Kubernetes**     | **Official Helm chart**                                                                                                | Cloud-native                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `kyoo.example.com`                                          | URL          | TLS                                                                                    |
| Media dir            | `/media/library` (movies + TV mounted)                      | Storage      | Read-only preferred                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| OIDC provider        | Google / Authelia / Discord                                 | Auth         | Built-in support                                                                                    |
| GPU (optional)       | NVIDIA / Intel                                              | Transcode    | Hardware-accelerated                                                                                    |
| Transcoder cache     | Temp transcode output                                       | Storage      | SSD preferred                                                                                    |

## Install via Docker

Follow: <https://github.com/zoriya/Kyoo/blob/master/INSTALLING.md>

## First boot

1. Mount media library (READ-ONLY)
2. Configure OIDC (recommended; avoid local-auth-only)
3. Start stack → browse web UI
4. Let scanner index library
5. Verify anime-parsing works on your collection
6. Test transcoding on low-end device
7. Enable HW-transcoding if GPU available
8. Put behind TLS reverse proxy
9. Back up DB + config

## Data & config layout

- Media library — READ-ONLY mount
- PostgreSQL — metadata, users, watch-history
- Transcoder cache — SSD; regenerable

## Backup

```sh
docker compose exec db pg_dump -U kyoo kyoo > kyoo-$(date +%F).sql
sudo tar czf kyoo-config-$(date +%F).tgz config/
```

## Upgrade

1. Releases: <https://github.com/zoriya/Kyoo/releases>. Active; v5 recent rewrite.
2. Read release notes — v5 migration was significant
3. Some features (SIMKL sync, offline) paused in v5, coming back
4. **Recipe convention: "major-version-rewrite-feature-regression callout"** — rare but real

## Gotchas

- **116th HUB-OF-CREDENTIALS TIER 2 — MEDIA-LIBRARY-META**:
  - Watch-history + OIDC-trust + metadata-DB + user-preferences
  - **116th tool in hub-of-credentials family — Tier 2**
- **NO-PLUGIN-SYSTEM AS DESIGN CHOICE**:
  - Unlike Jellyfin/Plex (heavy plugin-ecosystem)
  - Trade-off: less extensibility, less attack-surface
  - **Recipe convention: "no-plugin-system-as-security-design-choice positive-signal"**
  - **NEW positive-signal convention** (Kyoo 1st formally)
- **READ-ONLY-LIBRARY-MOUNT-DISCIPLINE**:
  - Media library should be mounted :ro
  - **Read-only-library-mount-discipline: 2 tools** (Polaris+Kyoo) 🎯 **2-TOOL MILESTONE**
- **ANIME-NAME-PARSING-DECLARED-A-BUG**:
  - "Media not being scanned correctly ... is considered a bug"
  - Unusually assertive UX commitment
  - **Recipe convention: "declared-quality-commitment positive-signal"** (rare)
  - **NEW positive-signal convention** (Kyoo 1st formally)
- **v5 REWRITE — FEATURES PAUSED**:
  - Watch-list sync, offline-download paused during v5 rewrite
  - Transparent about what's missing
  - **Recipe convention: "feature-regression-transparency-during-rewrite positive-signal"**
  - **NEW positive-signal convention** (Kyoo 1st formally)
- **OIDC-BUILT-IN (not-plugin)**:
  - Built-in, not plugin
  - Aligned with no-plugin design
  - **Recipe convention: "OIDC-built-in positive-signal"** — reinforces (Defguard 108 etc.)
- **HARDWARE-TRANSCODING-OPTIONAL**:
  - GPU detection — NVIDIA/Intel
  - **Hardware-dependent-tool (optional): 4 tools** (CheckCle+Scriberr+...+Kyoo) 🎯
- **HELM-CHART OFFICIAL**:
  - Kubernetes-first support
  - **Recipe convention: "official-Helm-chart positive-signal"** — reinforces
- **APPLE-PLATFORM-DECLINED**:
  - Honest: "Apple support not planned due to dev-fee"
  - **Recipe convention: "honest-platform-declined-with-reason positive-signal"**
  - **NEW positive-signal convention** (Kyoo 1st formally)
- **REACT-NATIVE-+-EXPO SHARED-CODE**:
  - Web + mobile from one codebase
  - **Recipe convention: "shared-codebase-web-plus-mobile positive-signal"**
- **SWAGGER-API-DOCUMENTATION**:
  - API-discoverability
  - **Recipe convention: "Swagger-API-docs positive-signal"**
  - **NEW positive-signal convention** (Kyoo 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: zoriya sole + Discord + Helm-chart + v5-rewrite-transparent + React-Native-expo. **102nd tool — sole-maintainer-with-rewrite-transparency sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + Discord + Swagger + Helm + install-docs + rewrite-transparency + releases. **110th tool 🎯 110-TOOL MILESTONE in transparent-maintenance family**.
- **MEDIA-SERVER-CATEGORY:**
  - **Kyoo** — OSS; low-maintenance; anime-friendly; OIDC-built-in
  - **Jellyfin** — OSS; mature; plugin-heavy
  - **Plex** — commercial; mature; most-polished client-apps
  - **Emby** — commercial; hybrid
  - **Streama / Kodi + add-ons** — others
- **ALTERNATIVES WORTH KNOWING:**
  - **Jellyfin** — if you want mature + plugins + best client-app-support
  - **Plex** — if you want polished UX
  - **Emby** — if you want hybrid
  - **Choose Kyoo if:** you want low-maintenance + anime-first + OIDC-native + K8s-ready.
- **PROJECT HEALTH**: active + v5-rewrite-recent + Discord + Helm + Swagger. Strong.

## Links

- Repo: <https://github.com/zoriya/Kyoo>
- Install: <https://github.com/zoriya/Kyoo/blob/master/INSTALLING.md>
- API: <https://kyoo.zoriya.dev/swagger>
- Jellyfin (alt): <https://jellyfin.org>
