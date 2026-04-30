---
name: Dispatcharr
description: "Open-source IPTV stream + EPG + VOD management. Consolidates multiple IPTV sources, HDHomeRun emulation for Plex/Emby/Jellyfin live TV, M3U/Xtream/XMLTV output, FFmpeg transcoding. \"The *arr family's IPTV cousin.\" AGPL-3.0. Active."
---

# Dispatcharr

Dispatcharr is **"the *arr family's IPTV cousin"** — an open-source IPTV stream + EPG + VOD management platform. Consolidate multiple IPTV provider feeds into one interface; manage thousands of channels; match EPG data; emulate HDHomeRun tuners so Plex/Jellyfin/Emby discover your streams as live TV sources; transcode streams with FFmpeg; run everything through a VPN container; expose as M3U/Xtream-Codes API/HDHomeRun to clients; monitor + fail over in real-time.

Created by **OkinawaBoss** + contributions from **dekzter, SergeantPanda, Bucatini** + community. **License: AGPL-3.0**. Active; Discord support; docs at dispatcharr.github.io.

Use cases: (a) **consolidate multiple IPTV subscriptions** behind one interface (b) **Plex/Emby/Jellyfin live-TV** via HDHomeRun emulation (virtual tuners) (c) **centralize VPN-routed streams** — all IPTV through Gluetun or similar, clients never see the VPN (d) **transcoding** — normalize codecs + audio + bitrates for low-bandwidth clients (e) **multi-user access control** — household or small-group stream sharing with permissions (f) **real-time monitoring** of stream health + bandwidth + failover (g) **plugin system** for custom workflows (h) **EPG generation** — create custom TV guides + XMLTV export.

Features (from upstream README):

- **Stream proxy + relay** with real-time client management
- **M3U + Xtream Codes** import + filter + organize
- **EPG matching + generation** — auto-match or custom
- **VOD library** with IMDB/TMDB metadata
- **Multi-format output**: M3U, XMLTV EPG, Xtream Codes API, HDHomeRun
- **Real-time monitoring** — connections, bandwidth, failover
- **Stream profiles** — tailored config per client/bandwidth
- **FFmpeg + VLC + Streamlink** backends for transcoding
- **Multi-user + access control** — granular perms + network restrictions
- **Plugin system**
- **Self-hosted, no third-party dependencies**

- Upstream repo: <https://github.com/Dispatcharr/Dispatcharr>
- Docs: <https://dispatcharr.github.io/Dispatcharr-Docs/>
- Discord: <https://discord.gg/Sp45V5BcxU>
- Docker Hub: `ghcr.io/dispatcharr/dispatcharr`

## Architecture in one minute

- **Python/Django** backend + React frontend (typical *arr-clone pattern)
- **PostgreSQL** — DB
- **Redis** — cache/queue
- **FFmpeg / VLC / Streamlink** — transcoding backends (must be available)
- **Resource**: moderate-heavy — CPU heavy if transcoding; 500MB-2GB RAM; 1 core per concurrent transcode
- **Ports**: web UI (typically 9191 or 8080), stream ports

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Primary; per docs**                                          | **Often with Gluetun VPN sidecar**                                                 |
| Unraid             | Community templates                                                       | Common homelab                                                                                   |
| Bare-metal Python  | Django app                                                                                   | DIY                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| IPTV provider creds  | M3U URL(s) + Xtream Codes accounts                          | **CRITICAL** | **These are your subscription credentials**                                                                                    |
| EPG sources          | URLs to XMLTV guides or Xtream EPG                          | Config       | Many free + commercial sources                                                                                    |
| Plex/Jellyfin/Emby   | URL + token for HDHomeRun discovery                                                                           | Integration  | For live-TV tuner integration                                                                                    |
| VPN config (optional) | Gluetun or similar                                                                                              | Network      | All streams route through VPN                                                                                                            |
| Admin creds          | First-boot setup                                                                                                        | Bootstrap    | Strong password                                                                                                                            |
| `SECRET_KEY`         | Django signing                                                                                                                       | **CRITICAL** | **IMMUTABLE**                                                                                                                                            |

## Install via Docker compose (typical + Gluetun VPN sidecar)

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:v3
    cap_add: [NET_ADMIN]
    environment:
      - VPN_SERVICE_PROVIDER=...  # your VPN
      - VPN_TYPE=wireguard
      - WIREGUARD_PRIVATE_KEY=...
    ports:
      - "9191:9191"   # Dispatcharr web UI proxied through VPN sidecar

  dispatcharr:
    image: ghcr.io/dispatcharr/dispatcharr:latest   # **pin version**
    network_mode: "service:gluetun"     # all egress via VPN
    environment:
      - SECRET_KEY=${SECRET_KEY}
      - DATABASE_URL=postgres://...
    volumes:
      - ./dispatcharr-data:/data
    depends_on: [db, redis, gluetun]

  db:
    image: postgres:16
    volumes: [./dispatcharr-db:/var/lib/postgresql/data]
    environment:
      POSTGRES_DB: dispatcharr
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_USER: dispatcharr

  redis:
    image: redis:7-alpine
```

## First boot

1. Start → browse `http://host:9191` → create admin
2. Add IPTV provider (M3U URL or Xtream creds)
3. Scan channels; filter/categorize
4. Add EPG source; match channels
5. Configure output (M3U/Xtream/HDHomeRun virtual device)
6. Point Plex/Emby/Jellyfin at HDHomeRun device URL
7. Test live TV + DVR from media server
8. Configure transcoding profiles if needed
9. Put admin UI behind TLS + auth (not just VPN)
10. Back up DB + config

## Data & config layout

- Postgres — channels, EPG, users, streams, sessions
- `/data/` — logs, custom scripts, plugin data, recordings (if DVR)
- `.env` — SECRET_KEY + IPTV + EPG credentials

## Backup

```sh
docker compose exec db pg_dump -U dispatcharr dispatcharr > dispatcharr-$(date +%F).sql
sudo tar czf dispatcharr-data-$(date +%F).tgz dispatcharr-data/
```

## Upgrade

1. Releases: <https://github.com/Dispatcharr/Dispatcharr/releases>. Active.
2. Docker: pull + restart.
3. Back up BEFORE major upgrades; plugin compat may break.

## Gotchas

- **IPTV LEGAL AMBIGUITY = NON-TRIVIAL**: Dispatcharr is neutral — it manages streams from providers you subscribe to. However:
  - Many "IPTV providers" resell copyrighted content without rights (pirate IPTV) — using those = criminal / civil liability
  - Legitimate IPTV exists (Pluto TV, IPTV-free-legal, cable-provider-streamed feeds, subscription OTT via official channels)
  - **Dispatcharr doesn't pirate; users' choice of provider determines legality**
  - **15th tool in network-service-legal-risk family** joining *arr-piracy-tooling sub-family (Readarr 93) — **NEW: "IPTV-piracy-conduit-risk" sub-family** distinct from *arr (which seeks torrents) — Dispatcharr consumes subscription IPTV feeds. Distinct operational + legal profile. Adds 7th sub-family to network-service-legal-risk.
- **HDHOMERUN EMULATION = LEGAL PRECEDENT**: HDHomeRun is Silicon Dust's hardware tuner; emulating its API is generally legal (interoperability precedent). Dispatcharr implements HDHomeRun protocol so Plex/Emby/Jellyfin treat Dispatcharr as a real HDHomeRun device → virtual tuners.
- **VPN-SIDECAR PATTERN = RECIPE-WORTHY**: running Dispatcharr behind Gluetun (or similar VPN container) is common because:
  - Some IPTV providers geo-restrict
  - VPN hides your home IP from providers
  - Centralized VPN for household streams
  - **`network_mode: "service:vpn"` pattern** applies broadly (also for Sonarr/Radarr/Readarr/Bazarr). **Recipe convention: "VPN-sidecar pattern"** for tools needing outbound-VPN. Shoutrrr recipient / documentation worthy.
- **TRANSCODING IS EXPENSIVE**:
  - CPU transcoding = slow + hot (1 core per stream)
  - GPU transcoding (NVENC / QSV / VAAPI) = much faster
  - Hardware-accelerate where possible
  - **"Intel iGPU with QSV" is the sweet spot** for homelabs (low power + effective)
- **FFMPEG SHELL-EXEC GATEWAY RISK**: Dispatcharr invokes FFmpeg for transcoding. Stream profiles configure FFmpeg args. If a user can craft arbitrary FFmpeg args via the UI → shell-command-injection-adjacent risk. **3rd tool in web-exposed-shell-exec-gateway adjacent-category** (OliveTin 91, Dagu 94, **Dispatcharr 96 — weaker variant because FFmpeg args not full-shell**). Treat carefully:
  - Restrict admin access to FFmpeg profile editors
  - Don't expose Dispatcharr to untrusted users
- **HUB-OF-CREDENTIALS TIER 2**: Dispatcharr stores:
  - IPTV provider credentials (M3U URLs + Xtream creds)
  - EPG source credentials
  - Plex/Emby/Jellyfin tokens (for HDHomeRun discovery)
  - Admin + user accounts
  - VPN creds if integrated
  - **47th tool in hub-of-credentials family — Tier 2.**
- **`SECRET_KEY` IMMUTABILITY** (Django): **32nd tool in immutability-of-secrets family.**
- **PLUGIN SYSTEM = EXTENSION RISK**: plugins can run arbitrary code inside Dispatcharr. Only install trusted plugins. Review before installing. Common pattern; Dispatcharr joins tools with plugin-based-extension-risk (OliveTin, Homarr, etc.).
- **HIGH-BANDWIDTH INTERNAL**: Dispatcharr proxies streams → high internal network usage. 100Mbps+ for multiple HD streams. Ensure adequate bandwidth on Docker network; consider host-networking if performance-critical.
- **CONCURRENT STREAM LIMITS**: IPTV providers often limit concurrent connections per account. Dispatcharr + multiple clients = you'll hit the provider limit easily. Configure provider's max-connections carefully.
- **DMCA EXPOSURE IF PUBLIC**: if Dispatcharr is exposed to the internet for remote access, you're a distribution endpoint. DMCA takedowns + provider ToS + hosting-provider enforcement actions. **Run private-access only.** Tailscale / VPN only.
- **INSTITUTIONAL-STEWARDSHIP**: OkinawaBoss founder + several major contributors + Discord. **24th tool in institutional-stewardship — transitional-from-sole-maintainer-to-team** (reinforces Kometa 95 pattern).
- **TRANSPARENT-MAINTENANCE**: AGPL + Discord + docs site + active + acknowledges contributors. **29th tool in transparent-maintenance family.**
- **AGPL-3.0**: source disclosure for modifications + network-service distribution. Fine for self-host; be aware if offering as SaaS.
- **PRONUNCIATION**: "dispatcher" per README — preempting-common-misunderstanding pattern (similar to Kometa's PMM rebrand 95).
- **THIS IS THE *ARR FAMILY COUSIN** — mental model: like Sonarr (TV) + Radarr (movies) + Readarr (books, now RETIRED per batch 93) + Lidarr (music) + Bazarr (subtitles) + Prowlarr (indexers) + Jackett (indexer proxy), Dispatcharr handles IPTV. Users of the *arr ecosystem will be familiar with the pattern: indexer-driven workflow + container-first + API-driven + community.
- **ALTERNATIVES WORTH KNOWING:**
  - **xTeVe** — predecessor / similar IPTV proxy for Plex; older; less actively developed
  - **Threadfin** — fork-continuation of xTeVe with active development (healthy-fork-after-abandonment pattern reinforces Redlib 95)
  - **TVHeadend** (batch 94) — full-feature TV backend including DVR; more complex setup; GPL-3
  - **ErsatzTV** — virtual TV channel creator (different niche; curates existing library into channels)
  - **Channels DVR** — commercial DVR with IPTV support
  - **Plex DVR** — built-in Plex; requires real HDHomeRun or similar
  - **Choose Dispatcharr if:** you want *arr-family UX + modern stack + HDHomeRun emulation + plugins + active.
  - **Choose Threadfin if:** you want xTeVe-lineage proven-codebase.
  - **Choose TVHeadend if:** you want mature + GPL-3 + full DVR + MythTV-lineage.
  - **Choose ErsatzTV if:** you want curated virtual channels from your library (different use case).
- **PROJECT HEALTH**: active + AGPL + Discord + multiple contributors + docs site. Rising star in IPTV self-host space.

## Links

- Repo: <https://github.com/Dispatcharr/Dispatcharr>
- Docs: <https://dispatcharr.github.io/Dispatcharr-Docs/>
- Discord: <https://discord.gg/Sp45V5BcxU>
- Docker: `ghcr.io/dispatcharr/dispatcharr`
- Threadfin (alt): <https://github.com/Threadfin/Threadfin>
- xTeVe (ancestor): <https://github.com/xteve-project/xTeVe>
- TVHeadend (alt): <https://tvheadend.org>
- ErsatzTV (adjacent): <https://ersatztv.org>
- Gluetun (VPN): <https://github.com/qdm12/gluetun>
- Plex: <https://plex.tv>
- Jellyfin: <https://jellyfin.org>
