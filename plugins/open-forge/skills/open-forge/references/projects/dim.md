---
name: Dim
description: "Self-hosted media manager — organize + stream movies + TV via browser with hardware-accelerated transcoding. Rust backend + React UI. Smaller, faster, simpler than Plex/Jellyfin. AGPL-3.0. Development slower as of 2024-2025 — check status."
---

# Dim

Dim is **"a small, fast, Rust-based Plex/Jellyfin alternative"** — a self-hosted media manager + streaming server that organizes your movie/TV library, beautifies with poster art, and plays in a browser with **hardware-accelerated transcoding** (libva-based). The selling points: **tiny footprint, speedy startup, modern Rust stack**, minimal config.

Built + maintained by **Dusk Labs** (small team). **AGPL-3.0**. **Status note**: development pace has slowed visibly as of 2024-2025 (issue activity, release cadence). Not necessarily abandoned — check `github.com/Dusk-Labs/dim` pulse before building critical infrastructure on it. Still functional and in community use.

Use cases: (a) **lightweight Plex alternative** without the account/sign-in bloat (b) **homelab media server** on a Pi or N100 mini-PC (c) **developer playground** for Rust + video-streaming learning (d) **single-user / small-family** media library.

Features:

- **Movies + TV shows** — organized + poster art
- **Browser-based web player**
- **Hardware-accelerated transcoding** (libva: Intel QuickSync, AMD VCE)
- **Metadata fetching** (TMDb)
- **Minimal dependencies** (Rust binary + small UI)
- **SQLite** backend — no separate DB to run
- **Docker** multiarch images
- **Chromecast / browser-native casting** (check current version)

- Upstream repo: <https://github.com/Dusk-Labs/dim>
- Discord: <https://discord.gg/gBPyQ7NVah>
- GHCR images: `ghcr.io/dusk-labs/dim:dev` (dev) + `ghcr.io/dusk-labs/dim:master` (multiarch)
- Docker compose template: <https://github.com/Dusk-Labs/dim/blob/master/docker-compose-template.yml>

## Architecture in one minute

- **Rust** binary (ffmpeg + ffprobe bundled or symlinked)
- **React** web UI
- **SQLite** — embedded DB
- **libva** for hardware transcoding (Intel iGPU / AMD)
- **Resource**: small — 200-500MB RAM baseline; transcoding adds CPU/GPU load
- **Port 8000** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`ghcr.io/dusk-labs/dim:master`** (multiarch)                 | **Upstream-primary**                                                               |
| Bare-metal         | Download binary from GitHub releases + run                                | Has runtime deps (libva, libharfbuzz, libfontconfig, libfribidi, libtheora, libvorbis)     |
| From source        | Rust nightly + yarn + ffmpeg                                                        | For developers                                                                                         |
| Raspberry Pi       | arm64 docker image                                                                              | Works; transcoding CPU-only on Pi (no GPU acceleration)                                                                                                  |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `dim.example.com`                                               | URL          | TLS via reverse proxy                                                                                    |
| Media mount          | `/media:ro`                                                             | Storage      | Read-only mount of library                                                                                    |
| Config path          | `~/.config/dim`                                                                    | Storage      | Persistent (scan metadata + DB)                                                                                           |
| `/dev/dri/renderD128`| GPU device                                                                                       | Hardware     | For hardware transcoding                                                                                                              |
| TMDb API key (opt)   | For metadata                                                                                                     | Config       | Check current version — may be bundled                                                                                                                |

## Install via Docker

```sh
docker run -d \
  -p 8000:8000/tcp \
  -v $HOME/.config/dim:/opt/dim/config \
  -v /media:/media:ro \
  --device=/dev/dri/renderD128 \
  ghcr.io/dusk-labs/dim:master        # pin a specific tag in prod
```

Or Docker Compose per upstream `docker-compose-template.yml`.

## First boot

1. Deploy
2. Browse `http://host:8000`
3. Add your first library (path = `/media` mount)
4. Wait for scan + metadata fetching
5. Browse + play content
6. Put behind TLS reverse proxy
7. Back up config directory (contains SQLite DB)

## Data & config layout

- `~/.config/dim/` — SQLite DB + scan metadata + config
- Media library (read-only mount) — untouched
- Logs to stdout

## Backup

```sh
sudo tar czf dim-config-$(date +%F).tgz ~/.config/dim/
```

## Upgrade

1. Releases: <https://github.com/Dusk-Labs/dim/releases>. Slowing cadence — check project pulse.
2. Docker: `docker pull + docker compose up -d`.
3. Back up config first.
4. If project becomes unmaintained, Jellyfin migration = scan your library fresh in Jellyfin (no direct import).

## Gotchas

- **Development pace has slowed as of 2024-2025.** Check `github.com/Dusk-Labs/dim` — issue activity, release cadence, commit frequency — BEFORE building your media stack around Dim. Not dead; not sprinting. Risk profile: higher than Jellyfin (Linux Foundation-style community) or Plex (commercial). Comparable status to **Wakapi batch 81 ("PRs currently closed") maintenance-mode signal**. Transparent upstream communication is a positive signal; absence of it = investigate before committing.
- **Media-server fundamentals still apply:**
  - **Legal content only.** Streaming pirated media even privately = copyright liability. Your own rips + purchases = fine. Same framing as Black Candy (batch 83) + Tdarr (84) + library-arr-stack context.
  - **Single-user vs multi-user**: check current auth model. Dim's multi-user story is less polished than Jellyfin's.
  - **Mobile apps / cast targets**: Plex + Jellyfin have extensive client ecosystems; Dim does not. Use browser on each device.
- **Hardware transcoding**:
  - **Intel QuickSync** (iGPU) works via libva — lowest power, great quality-per-watt. Mount `/dev/dri/renderD128`.
  - **AMD VCE** works via libva — older drivers can be rough.
  - **Nvidia NVENC** — check current Dim support; historically less covered.
  - **Raspberry Pi** has no usable GPU transcode path in most cases; CPU-only.
- **Codec support** depends on bundled FFmpeg version. Audio: AAC + AC3 ubiquitous. Video: H.264/HEVC broadly. AV1 / VVC = bleeding edge + client-browser-compat issue.
- **HDR tone mapping** — if your file is HDR and your browser doesn't support HDR display, you need tone mapping during transcode. Expensive. Test on your content.
- **Subtitles**: SRT is straightforward; PGS/VOBSUB = bitmap subs require OCR or burn-in during transcode. Check current Dim subtitle handling.
- **Library organization** follows standard movie + TV conventions:
  - `Movies/Inception (2010)/Inception (2010).mkv`
  - `TV/The Office/Season 01/The Office - S01E01 - Pilot.mkv`
  - Wrong naming = bad metadata match. Use a renamer tool (Sonarr / FileBot / tinyMediaManager) BEFORE pointing Dim at your library.
- **TMDb API key**: metadata comes from The Movie Database. Get a free API key from TMDb; may be bundled in Dim. If TMDb changes policy, Dim's metadata source needs to adapt.
- **AGPL-3.0 license** — standard network-service copyleft. Self-host privately = fine. Commercial SaaS offering Dim = disclose modifications. Nth AGPL tool in recipe family.
- **Bus-factor**: small team + slowing pace + AGPL. If development stalls, fork possible but Rust + video-streaming expertise is rare combination. Jellyfin is the natural fallback for OSS continuity.
- **Project health**: moderate + concerning trajectory. Not yet "dead" but not sprinting. Monitor status before depending.
- **Alternatives worth knowing:**
  - **Jellyfin** — the FOSS incumbent; mature; large client ecosystem; .NET-based; HEAVIER but battle-tested. **Strong default for new deployments.**
  - **Plex** — commercial; polished; requires Plex account signup (some privacy-wary folks dislike this)
  - **Emby** — commercial middle-ground; Jellyfin's predecessor in lineage
  - **Kodi** — local media player; can stream but not primarily a server
  - **Streama** — Node.js; small
  - **Ampache** — more music-focused; PHP
  - **Olive** — new; emerging
  - **Choose Dim if:** want minimal footprint + Rust appreciation + single-user + homelab exploration.
  - **Choose Jellyfin if:** want the FOSS production-grade option with client ecosystem.
  - **Choose Plex if:** want polish + don't mind the account.

## Links

- Repo: <https://github.com/Dusk-Labs/dim>
- Releases: <https://github.com/Dusk-Labs/dim/releases>
- Docker Compose template: <https://github.com/Dusk-Labs/dim/blob/master/docker-compose-template.yml>
- Discord: <https://discord.gg/gBPyQ7NVah>
- Jellyfin (strong alt): <https://jellyfin.org>
- Plex (commercial alt): <https://www.plex.tv>
- Emby (alt): <https://emby.media>
- TMDb: <https://www.themoviedb.org>
- tinyMediaManager (library organizer): <https://www.tinymediamanager.org>
