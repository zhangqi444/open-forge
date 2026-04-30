---
name: Polaris
description: "Self-hosted music streaming server. Rust. Designed for 100,000+ songs. Multi-format (flac/mp3/mp4/mpc/ogg/opus/ape/wav/aiff). Waveform viz; multi-value metadata. agersant sole. MIT. No premium tier."
---

# Polaris

Polaris is **"Navidrome / Airsonic — but Rust + performance-first + 100,000+-songs + no-premium-version"** — a self-hosted music streaming server. Goals: **exceptional performance + large-collection support (100k+ songs) + easy install/deploy/maintain + beautiful UI**. Multi-format: flac/mp3/mp4/mpc/ogg/opus/ape/wav/aiff. Browse by album/artist/genre OR as file-tree. **Song audio-waveform visualization**. Multi-value metadata fields. Powerful per-field search. Plain-text config (also editable in UI). Multi-user with per-user playlists.

Built + maintained by **agersant (sole maintainer)**. License: **MIT**. Active; Codecov; Windows/Linux/BSD/Docker; demo at demo.polaris.stream.

Use cases: (a) **self-host your music library** — escape streaming services (b) **large FLAC library** — lossless archives + streaming (c) **audiophile-grade music serving** — format variety (d) **100k+-song library** — scales to large collections (e) **family music-server** — multi-user with playlists (f) **BSD deployment** — cross-platform including BSD (g) **offline-first-ownership** — your music on your hardware (h) **waveform-browsing** — unusual UX feature.

Features (per README):

- **Windows + Linux + BSD + Docker**
- **Multi-format**: flac/mp3/mp4/mpc/ogg/opus/ape/wav/aiff
- **Dark/light modes + customizable palette**
- **Browse by album/artist/genre** OR **file-tree**
- **Audio-waveform visualization**
- **Multi-value metadata** (multiple artists per song)
- **Per-field search**
- **Plain-text config** + UI-editable
- **Multi-user + per-user playlists**
- **Mobile playback**
- **No premium tier** (explicit commitment)
- **Rust** implementation

- Upstream repo: <https://github.com/agersant/polaris>
- Demo: <https://demo.polaris.stream> (demo_user/demo_password)

## Architecture in one minute

- **Rust** backend
- **SQLite** DB (metadata index)
- **Your filesystem** = music library
- **Resource**: low — Rust-efficient; scales to large libraries
- **Port 5050** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream image**                                              | **Primary**                                                                        |
| **Windows**        | **Native installer**                                            | Desktop                                                                                   |
| **Linux**          | **Binary / package**                                            | Native                                                                                   |
| **BSD**            | **Rust build**                                                  | Rare-supported                                                                                   |
| Source             | `cargo build`                                                                            | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `music.example.com`                                         | URL          | TLS                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Music library path   | `/music`                                                    | Storage      | **Typically read-only mount** (positive-signal)                                                                                    |
| Index path           | SQLite location                                             | Storage      |                                                                                    |
| Users                | Family members                                              | Multi-user   |                                                                                    |

## Install via Docker

```yaml
services:
  polaris:
    image: agersant/polaris:latest        # **pin version**
    volumes:
      - /path/to/music:/music:ro        # read-only
      - polaris-data:/data
    ports: ["5050:5050"]
    restart: unless-stopped

volumes:
  polaris-data: {}
```

## First boot

1. Start → browse `:5050`
2. Add library mount → scan
3. Create admin + users
4. Configure clients (web, iOS, Android — via OSS 3rd-party apps)
5. Put behind TLS reverse proxy
6. Back up config + index (music-library itself is separately managed)

## Data & config layout

- `/music/` — read-only mount of your music files
- `/data/` — SQLite index + config

## Backup

```sh
sudo tar czf polaris-data-$(date +%F).tgz polaris-data/
# Music library = back up separately (it's your actual collection)
```

## Upgrade

1. Releases: <https://github.com/agersant/polaris/releases>. Active.
2. Docker pull + restart
3. Index may need re-scan on major versions

## Gotchas

- **103rd HUB-OF-CREDENTIALS TIER 3**:
  - Music library metadata + play-history + user accounts
  - Lower-sensitivity than many tools (what you listen to is generally less-personal than reading/health)
  - **103rd tool in hub-of-credentials family — Tier 3**
- **READ-ONLY MUSIC MOUNT = POSITIVE-SIGNAL**:
  - Polaris doesn't modify library
  - **Recipe convention: "read-only-library-mount-discipline positive-signal"** — safer than tools that write
  - **NEW positive-signal convention** (Polaris 1st formally — many music-server tools allow this but Polaris treats as best-practice)
- **NO PREMIUM TIER = EXPLICIT COMMITMENT**:
  - README explicitly states: "without any kind of premium version"
  - Rejects open-core business model
  - **Recipe convention: "explicit-no-premium-commitment positive-signal"**
  - **NEW positive-signal convention** (Polaris 1st formally)
  - Contrast with open-core tools (Dittofeed 106, KrakenD 109, ...)
- **RUST IMPLEMENTATION**:
  - Memory-safe, fast
  - **Recipe convention: "Rust-for-performance positive-signal"** — reinforces prior Rust tools
- **LARGE-COLLECTION FIRST-CLASS**:
  - 100k+ songs is explicit design goal
  - Many tools fall over at scale
  - **Recipe convention: "scalability-as-explicit-design-goal positive-signal"**
  - **NEW positive-signal convention** (Polaris 1st formally)
- **BSD SUPPORT**:
  - Unusual — most OSS tools are Linux+macOS only
  - **Recipe convention: "BSD-support positive-signal"** — uncommon
  - **NEW positive-signal convention** (Polaris 1st formally)
- **WAVEFORM VISUALIZATION**:
  - Unusual UX feature
  - **Recipe convention: "audio-waveform-visualization rare-UX-feature"**
- **MULTI-VALUE METADATA**:
  - Correct handling of "featuring" artists etc.
  - Respects music metadata reality (collaborations)
  - **Recipe convention: "multi-value-metadata-support positive-signal"**
- **PLAIN-TEXT CONFIG + UI-EDITABLE**:
  - Config-as-code friendly
  - Also operator-friendly via UI
  - **Recipe convention: "dual-mode-config positive-signal"**
  - **NEW positive-signal convention** (Polaris 1st formally)
- **MUSIC-STREAMING-CATEGORY:**
  - **Polaris** — Rust; performance-first
  - **Navidrome** — Go; Subsonic API; mature
  - **Airsonic** (advanced) — Java; legacy
  - **Jellyfin** — full media (TV/movies/music) — general-purpose
  - **Funkwhale** — federated; Python/Django
  - **Ampache** — PHP; mature
  - **Mopidy** — MPD frontend; Python
  - **Gonic** — Go; Subsonic API
  - **Supersonic / Sonixd** (client apps)
- **INSTITUTIONAL-STEWARDSHIP**: agersant sole-maintainer + community. **89th tool — sole-maintainer-with-community sub-tier (36th).**
- **TRANSPARENT-MAINTENANCE**: active + Rust + Codecov + cross-platform + demo + MIT + no-premium-commitment. **97th tool in transparent-maintenance family.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Navidrome** — if you want Subsonic-API ecosystem + Go + mature
  - **Jellyfin** — if you want full-media (not music-only)
  - **Funkwhale** — if you want federated music
  - **Choose Polaris if:** you want Rust + 100k+ songs + performance + no-premium + audio-waveform.
- **PROJECT HEALTH**: active + sole-maintainer + MIT + cross-platform + Rust. Strong.

## Links

- Repo: <https://github.com/agersant/polaris>
- Demo: <https://demo.polaris.stream>
- Navidrome (alt): <https://github.com/navidrome/navidrome>
- Funkwhale (alt): <https://dev.funkwhale.audio/funkwhale/funkwhale>
- Gonic (alt): <https://github.com/sentriz/gonic>
