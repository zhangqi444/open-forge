---
name: Tracearr
description: "Real-time monitoring + analytics for Plex, Jellyfin, and Emby. Multi-server dashboard. Session tracking with geolocation. Anti-account-sharing. Crowdin-localized. connorgallopo/Tracearr. docs.tracearr.com. Discord + Ko-Fi."
---

# Tracearr

Tracearr is **"Tautulli + multi-backend + anti-account-sharing"** — a monitoring + analytics platform for **Plex, Jellyfin, AND Emby** in one dashboard. Real-time session tracking, playback analytics, bandwidth + codec + resolution stats, IP-geolocation (with ASN + continent + postal), spot-account-sharing detection.

Built + maintained by **connorgallopo**. CI + nightly builds. Crowdin-localized. Discord. Ko-Fi funded. docs.tracearr.com. ghcr.io container.

Use cases: (a) **unified dashboard** for Plex+Jellyfin+Emby (b) **session monitoring** w/ geolocation (c) **anti-account-sharing detection** (d) **bandwidth + transcode tracking** (e) **library analytics** (growth, storage, codec) (f) **who-watched-what-when-where audit** (g) **Tautulli upgrade / multi-backend** (h) **media-server homelab observability**.

Features (per README):

- **Multi-server dashboard** (Plex + Jellyfin + Emby)
- **Session tracking** w/ geolocation (ASN + continent + postal)
- **Stream analytics** (transcode/direct, bandwidth, codec, resolution)
- **Library analytics** (item counts, storage, growth)
- **Nightly CI** builds
- **Crowdin-localized**
- **Docker (ghcr.io)**

- Upstream repo: <https://github.com/connorgallopo/Tracearr>
- Docs: <https://docs.tracearr.com>
- Discord: <https://discord.gg/a7n3sFd2Yw>
- Ko-Fi: <https://ko-fi.com/E1E21QRI1L>

## Architecture in one minute

- Next.js monorepo (apps/web)
- SQLite or PostgreSQL
- Poll Plex/Jellyfin/Emby APIs
- **Resource**: low-moderate
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker (ghcr.io)** | Upstream                                                                                                             | **Primary**                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `tracearr.example.com`                                      | URL          | TLS                                                                                    |
| Plex token           | From Plex                                                   | Secret       | **Full API access**                                                                                    |
| Jellyfin token       | Admin API key                                               | Secret       | **Full API access**                                                                                    |
| Emby API key         | Admin API key                                               | Secret       | **Full API access**                                                                                    |
| GeoIP DB             | MaxMind or ipinfo                                           | Data         |                                                                                    |

## Install via Docker

See docs.tracearr.com. Typical:
```yaml
services:
  tracearr:
    image: ghcr.io/connorgallopo/tracearr:latest        # **pin**
    ports: ["3000:3000"]
    volumes:
      - ./tracearr-data:/data
    environment:
      - DATABASE_URL=...
    restart: unless-stopped
```

## First boot

1. Start
2. Create admin
3. Add Plex / Jellyfin / Emby server(s) + tokens
4. Verify session polling
5. Upload GeoIP DB (optional)
6. Review analytics dashboards
7. Set up anti-sharing rules
8. Put behind TLS
9. Back up DB

## Data & config layout

- `/data/` — DB + session history + geolocation

## Backup

```sh
sudo tar czf tracearr-$(date +%F).tgz tracearr-data/
# Contains: media-server admin-tokens — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/connorgallopo/Tracearr/releases>
2. Docker pull + restart
3. DB migrations auto

## Gotchas

- **182nd HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — MULTI-MEDIA-SERVER-ADMIN-TOKENS**:
  - Holds: **Plex + Jellyfin + Emby admin tokens** (all THREE!), session history, viewer IP + geolocation
  - Multi-backend = triple-blast-radius
  - Extends **media-stack-credential-aggregator**
  - **182nd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - Matures sub-cat: **"media-stack-credential-aggregator": 5 tools** 🎯 **5-TOOL MILESTONE**
  - **CROWN-JEWEL Tier 1: 63 tools / 56 sub-categories** (sub-cat matured, not new)
- **TAUTULLI-ALTERNATIVE-MULTI-BACKEND**:
  - Tautulli is Plex-only; Tracearr handles all 3
  - **Recipe convention: "single-backend-vs-multi-backend-tradeoff"**
  - **NEW recipe convention** (Tracearr 1st formally)
- **IP-GEOLOCATION-PII**:
  - Viewer IP + geo = PII
  - **Recipe convention: "viewer-IP-geolocation-PII-retention-discipline callout"**
  - **NEW recipe convention** (Tracearr 1st formally; reinforces Reitti)
- **ANTI-ACCOUNT-SHARING-DETECTION**:
  - Feature designed to flag sharing patterns
  - Compare-IP-pattern = human-tracking
  - **Recipe convention: "anti-account-sharing-detection-human-tracking-ethics callout"**
  - **NEW recipe convention** (Tracearr 1st formally)
- **PLEX-TOKEN-FULL-POWER**:
  - Plex token = account-god-mode (can manage servers, users, libraries)
  - **Recipe convention: "Plex-token-full-account-scope-discipline"** reinforces earlier precedents
- **NIGHTLY-CI-QUALITY-OPS**:
  - **Nightly-CI-quality-ops: 3 tools** (Jellystat+Podsync+Tracearr) 🎯 **3-TOOL MILESTONE**
- **CROWDIN-LOCALIZED**:
  - **Community-translation-infrastructure: 4 tools** (+Tracearr) 🎯 **4-TOOL MILESTONE**
- **KO-FI-FUNDING**:
  - **Ko-Fi-funding: 4 tools** (+Tracearr) 🎯 **4-TOOL MILESTONE**
- **GHCR-PRIMARY-REGISTRY**:
  - ghcr.io is primary
  - **Recipe convention: "GHCR-primary-registry positive-signal"**
  - **NEW positive-signal convention** (Tracearr 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: connorgallopo sole-dev + Crowdin + CI + nightly + docs + Discord + Ko-Fi + GHCR. **168th tool — multi-channel-sole-dev-analytics-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + nightly + docs + Crowdin + Discord + releases. **174th tool in transparent-maintenance family.**
- **MEDIA-MONITOR-CATEGORY:**
  - **Tracearr** — multi-backend (Plex+Jellyfin+Emby); modern; geolocation
  - **Tautulli** — Plex-only; dominant; mature
  - **Jellystat** — Jellyfin-only (b119)
  - **Maintainerr** — Plex/Jellyfin/Emby rules-engine (destructive b123)
- **ALTERNATIVES WORTH KNOWING:**
  - **Tautulli** — if Plex-only + mature
  - **Jellystat** — if Jellyfin-only + focused
  - **Choose Tracearr if:** you want all-3-backends + anti-sharing + modern UX.
- **PROJECT HEALTH**: active + docs + Discord + Ko-Fi + CI + nightly + Crowdin. Strong.

## Links

- Repo: <https://github.com/connorgallopo/Tracearr>
- Docs: <https://docs.tracearr.com>
- Tautulli (alt): <https://github.com/Tautulli/Tautulli>
- Jellystat (alt): <https://github.com/CyferShepard/Jellystat>
