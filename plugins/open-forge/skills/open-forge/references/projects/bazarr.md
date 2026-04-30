---
name: Bazarr
description: "Companion to Sonarr + Radarr that automatically downloads + manages subtitles. Per-series + per-movie language preferences, 50+ subtitle providers (Addic7ed, OpenSubtitles, Podnapisi, Whisper-ASR, etc.), auto-upgrade when better subs found. Python. GPL-3.0."
---

# Bazarr

Bazarr is **"the subtitles member of the arr-stack"** — a companion to **Sonarr** (TV) + **Radarr** (movies) that handles what they don't: finding, downloading, and managing subtitles for your media library. You define per-show + per-movie language preferences ("always English + French + SDH"), Bazarr watches Sonarr/Radarr for new content, queries 50+ subtitle providers, downloads the best match, and keeps checking for upgrades.

Built + maintained by **morpheus65535** + community contributors (Bazarr org). **GPL-3.0**. Long-running; widely-deployed. **LinuxServer.io + hotio Docker images** are the common deploy paths; their UI is **"inspired by Sonarr"** for familiarity.

Use cases: (a) **non-English media consumption** (b) **accessibility** — SDH / hard-of-hearing subtitles (c) **foreign-film households** — always-bilingual subtitles (d) **arr-stack completion** — Sonarr + Radarr cover video; Bazarr covers subtitles (e) **AI-transcription via Whisper** — generate subs where none exist online.

Features:

- **Supports Sonarr + Radarr** (integrates via their APIs, watches for new content)
- **184+ subtitles languages** (per-content config)
- **50+ subtitle providers**: Addic7ed, OpenSubtitles.com + .org, Podnapisi, Subscene (legacy), GreekSubs, LegendasDivx, Yavka, Wizdom, YIFY, TVSubtitles, Subf2m, Embedded-Subtitles (internal), **Whisper ASR** (via `ahmetoner/whisper-asr-webservice`), many more
- **Manual search** — override auto-downloads
- **Auto-upgrade subtitles** when better version becomes available
- **Forced / foreign subtitles** support where providers offer
- **Library scan** — pick up existing internal + external subs
- **Delete-subs from disk** through UI
- **Plex / Emby / Jellyfin** post-process hooks
- **Web UI** (Sonarr-style)

- Upstream repo: <https://github.com/morpheus65535/bazarr>
- Wiki: <https://wiki.bazarr.media>
- Releases: <https://github.com/morpheus65535/bazarr/releases>
- LinuxServer image: <https://docs.linuxserver.io/images/docker-bazarr/>
- hotio image: <https://hub.docker.com/r/hotio/bazarr>
- Discord: <https://discord.gg/MH2e2eb>
- Feature votes: <http://features.bazarr.media>
- Whisper ASR companion: <https://github.com/ahmetoner/whisper-asr-webservice>

## Architecture in one minute

- **Python** backend + single-page web UI
- **SQLite** DB
- **Resource**: modest — 200-400MB RAM typical
- **Port 6767** default
- **LS.io conventions** (PUID/PGID/s6-overlay) in the common deploy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`lscr.io/linuxserver/bazarr`** (LSIO) or `hotio/bazarr`       | **Primary**; LSIO-ecosystem trust                                                   |
| Bare-metal         | Python + pip + git clone                                                  | Windows / Linux / macOS / Pi                                                               |
| unRAID / Synology  | Well-documented community templates                                                           | Native                                                                                                  |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `bazarr.example.com`                                        | URL          | TLS via reverse proxy                                                                                    |
| Sonarr + Radarr URLs + API keys                             | `http://sonarr:8989` + token                                | Integration  | Bazarr reads their library + follows their releases                                                                                    |
| Media mount          | Matches what Sonarr/Radarr see                                          | Storage      | Bazarr writes sidecar subtitle files (`.srt`) next to videos                                                                                    |
| Subtitle provider accounts                                    | OpenSubtitles.com (free tier); others as needed                                                                  | Config       | Most providers require account; some are API-keyed                                                                                                              |
| Languages + profiles | Per-show / per-movie preferred language profiles                                                                                    | Config       | The key setup — tune to your household                                                                                                                  |
| Path mappings        | If Bazarr's mount path differs from Sonarr's                                                                                                    | Config       | Common source of "can't find media" errors                                                                                                                              |

## Install via Docker Compose (LinuxServer.io)

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest          # **pin version** in prod
    container_name: bazarr
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Etc/UTC
    volumes:
      - ./bazarr-config:/config
      - /mnt/media:/media                             # match Sonarr/Radarr
    ports: ["6767:6767"]
    restart: unless-stopped
```

Per LS.io docs; full details at <https://wiki.bazarr.media>.

## First boot

1. Browse `http://host:6767` → complete setup wizard
2. Connect Sonarr → paste API key; test
3. Connect Radarr → same
4. Settings → Languages → create language profiles (e.g., "English + Spanish + SDH")
5. Assign profiles to series / movies (Mass Edit tools help)
6. Settings → Providers → enable OpenSubtitles.com + others; paste credentials
7. (opt) Deploy Whisper-ASR companion for AI-transcription fallback
8. Watch first subtitles roll in
9. Put behind TLS reverse proxy + basic auth if internet-exposed
10. Back up `/config`

## Data & config layout

- `/config/` — SQLite DB, settings, logs, cache
- Subtitles written next to videos (sidecar `.srt` files) in `/media`
- Provider credentials in DB — **treat as secrets**

## Backup

```sh
docker compose stop bazarr
sudo tar czf bazarr-config-$(date +%F).tgz bazarr-config/
docker compose start bazarr
```

Subtitles themselves live with the media; back up your media as usual.

## Upgrade

1. Releases: <https://github.com/morpheus65535/bazarr/releases>. Active cadence.
2. LSIO Docker: bump tag; migrations auto.
3. Back up config FIRST.
4. Major versions: read release notes — provider changes happen.

## Gotchas

- **Path-mapping issues** are the #1 new-user stumble. If Sonarr sees `/tv/The Office/Season 01/pilot.mkv` and Bazarr sees `/media/tv/The Office/Season 01/pilot.mkv`, Bazarr can't find the file. **Fix via either**:
  - Mount the media path identically in both containers (preferred)
  - Use Bazarr Settings → Sonarr → Path Mappings to translate
- **Subtitle providers go down + change APIs frequently.** Subscene closed (legacy support in Bazarr). OpenSubtitles.org shifted to .com with a REST API. Addic7ed has aggressive rate-limits. Bazarr release notes often say "provider X fixed / provider Y removed" — follow updates.
- **OpenSubtitles.com free-tier rate-limits** — anonymous/free downloads are limited per day. Paid VIP account = higher limits. If you have a large library + demanding langs, budget for VIP.
- **Whisper-ASR companion** is POWERFUL but resource-heavy — GPU-accelerated transcription of untranscribed audio. Deploy `ahmetoner/whisper-asr-webservice` alongside Bazarr; point Bazarr at its endpoint. Quality varies by language + accent + audio quality. Great fallback for obscure content; not a replacement for native-speaker subs.
- **Subtitle quality is highly variable.** Two subs for the same movie may differ wildly in timing + translation accuracy. Bazarr's score system picks the "best" (hash-match + user-rating), but "best" on OpenSubtitles ≠ "good" in absolute terms. Enabling auto-upgrade helps.
- **Forced subs + SDH** — some providers mix these up. Review your language profile ordering.
- **Internal embedded subtitles** — Bazarr can detect embedded subs inside .mkv files (saves re-downloading). Enable "Use Embedded Subtitles" in settings.
- **Pirated-media legal context** — same arr-stack framing as Ombi (batch 85) / Bitmagnet (85) / Tdarr (84). Bazarr doesn't download media; it downloads subtitles. Subtitles themselves are typically user-created + free; downloading them is generally legal even where piracy is grey. But Bazarr only matters if you have the media — which might be legal or not depending on source.
- **Provider credential storage** — stored in DB. If Bazarr is compromised, provider accounts leak. Keep Bazarr on trusted network.
- **LinuxServer.io image conventions** (PUID/PGID/s6-overlay/`/config`) — same family as Webtop (83), Ombi (85), Sonarr/Radarr/Lidarr. Trusted packaging ecosystem signal.
- **Hashed cookies for some providers** (AvistaZ, Ktuvit): some providers require getting session cookies manually. Documented in readme + wiki. One-time setup pain.
- **No multi-user** — Bazarr is admin-level. Not intended for multi-tenant.
- **Web UI auth is basic** — enable it. Internet-exposed Bazarr is hub-of-credentials (provider accounts). Same class as Ombi + Sonarr + Radarr. **Keep behind VPN or SSO reverse proxy.**
- **Project health**: active + long-running + large community + well-supported. morpheus65535 + contributors + Discord. No bus-factor concerns.
- **Alternatives worth knowing:**
  - **subliminal** — CLI subtitle downloader (Bazarr uses it internally as a library)
  - **Subsync** — subtitle timing sync tool (complementary, not replacement)
  - **Periphery** — similar-scope older tool; less active
  - **Manual download from OpenSubtitles** + **Plex / Jellyfin built-in search** — what Bazarr automates
  - **Choose Bazarr if:** you run Sonarr/Radarr + want subtitles automated + multi-language.
  - **Choose subliminal CLI if:** you want scripting + no web UI.

## Links

- Repo: <https://github.com/morpheus65535/bazarr>
- Wiki: <https://wiki.bazarr.media>
- Releases: <https://github.com/morpheus65535/bazarr/releases>
- LinuxServer image: <https://docs.linuxserver.io/images/docker-bazarr/>
- hotio image: <https://hotio.dev/containers/bazarr/>
- Discord: <https://discord.gg/MH2e2eb>
- Features (upvote): <http://features.bazarr.media>
- Whisper ASR companion: <https://github.com/ahmetoner/whisper-asr-webservice>
- Subliminal (library): <https://github.com/Diaoul/subliminal>
- OpenSubtitles.com: <https://www.opensubtitles.com>
