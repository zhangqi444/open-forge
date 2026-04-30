---
name: Readarr
description: "⚠️ RETIRED (upstream-announced). Book + audiobook collection manager for Usenet/BitTorrent users. Servarr family *arr tool. Retired due to unusable metadata + no maintainer. Community mirror rreading-glasses exists but unsupported. GPL-3.0. Seek alternatives: Calibre-Web, LazyLibrarian, AudioBookShelf."
---

# Readarr

> ## ⚠️ PROJECT RETIRED
> 
> **Readarr was officially retired by the Servarr team.** The upstream README's opening banner announces the retirement due to:
> - **Metadata source became unusable**
> - **No maintainer time to fix or rebuild**
> - **Community Open Library migration stalled**
> 
> **Consequence**: the project is in maintenance-only status; future-dev very unlikely.
> 
> **Quote from the README:**
> > "Without anyone to take over Readarr development, we expect it to wither away, so we still encourage you to seek alternatives to Readarr."
> 
> **Status of this recipe:** we catalog it for **historical + migration-advisory purposes**, not as a recommended-install. If you already have Readarr running, this recipe helps you understand its position + plan migration.

Readarr is **"the *arr for ebooks + audiobooks"** — part of the Servarr family (Sonarr TV, Radarr movies, Lidarr music, Readarr books, Prowlarr indexer-aggregator). It monitors RSS + indexers for new books by your favorite authors, grabs them via Usenet or BitTorrent, sorts + renames them, integrates with Calibre Content Server + download clients. Beta-forever; never reached 1.0; now officially retired.

Built + maintained by **the Servarr Team** (same group behind Sonarr/Radarr/Lidarr/Prowlarr) until retirement. **License: GPL-3.0**. Funded historically via Open Collective (backers + sponsors). Discord community large.

Historical use cases: (a) **ebook library auto-curation** — track author releases (b) **audiobook automation** for Plex/Jellyfin audiobook shelves (c) **DRM-free book hoarding** — paired with Calibre for format conversion (d) **integration with Sonarr/Radarr/Lidarr** stack — unified media automation.

Features (historical):

- **Author + book tracking** — monitor RSS feeds
- **Usenet + BitTorrent** integration — SAB, NZBGet, qBittorrent, Deluge, rTorrent, Transmission, uTorrent
- **Calibre Content Server integration** — add to library + format conversion
- **Quality profiles** — "prefer AZW3 over PDF"
- **Automatic failed-download handling**
- **Manual search** — pick specific release
- **RSS monitoring**
- **Multi-instance** — one for ebooks + one for audiobooks
- **REST API** for Bazarr / Overseerr / tautulli / etc.

- Upstream repo: <https://github.com/Readarr/Readarr>
- Retirement notice: <https://github.com/Readarr/Readarr/blob/develop/README.md> (top banner)
- Servarr wiki: <https://wiki.servarr.com/readarr>
- Discord: <https://readarr.com/discord>
- API docs: <https://readarr.com/docs/api/>
- rreading-glasses community metadata mirror: <https://github.com/blampe/rreading-glasses>
- Open Collective: <https://opencollective.com/Readarr>
- Docker Hub (hotio): <https://hub.docker.com/r/hotio/readarr>
- Docker Hub (LinuxServer): <https://hub.docker.com/r/linuxserver/readarr>

## Architecture in one minute

- **.NET (C#)** backend — shared codebase with Sonarr/Radarr/Lidarr
- **React** frontend
- **SQLite** DB
- **Calibre Content Server** (optional external dependency)
- **Download clients** (external)
- **Indexers** — Prowlarr-managed, or direct configuration
- **Resource**: moderate — 200-500MB RAM depending on library size
- **Port**: 8787

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker (LSIO)      | `linuxserver/readarr`                                           | LinuxServer community-maintained                                                                                   |
| Docker (hotio)     | `hotio/readarr`                                                           | hotio-maintained alt image                                                                                   |
| Bare-metal Windows / Linux / macOS / Pi | Binary releases                                                        | Historical install path                                                                                               |
| Servarr-script installers | Community-maintained installers                                                                                 | Linux distros                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Media library path   | `/books`                                                    | Storage      | Where Readarr files books                                                                                    |
| Downloads path       | `/downloads`                                                | Storage      | Shared with torrent/usenet client                                                                                    |
| Indexer(s)           | Via Prowlarr or direct                                      | Sources      | Usenet + torrent indexers                                                                                    |
| Download client creds | SAB/NZBGet/qBittorrent API keys                                                                    | Auth         | Standard *arr pattern                                                                                    |
| Calibre creds        | Content Server URL + user/pass                                                                                  | Optional     | For library integration                                                                                                            |
| API key              | Auto-generated                                                                                                           | Auth         | For Overseerr / etc. integration                                                                                                                            |
| Metadata source      | **Broken upstream; consider community mirror rreading-glasses**                                                                                                                               | **CRITICAL** | **Core reason for retirement**                                                                                                                                                         |

## Install via Docker (LSIO — historical path)

```yaml
services:
  readarr:
    image: lscr.io/linuxserver/readarr:develop
    container_name: readarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - ./readarr-config:/config
      - /media/books:/books
      - /downloads:/downloads
    ports: ["8787:8787"]
    restart: unless-stopped
```

## Gotchas

- **⚠️ OFFICIALLY RETIRED — THIS IS THE HEADLINE**: upstream explicitly + publicly announced retirement. **Do not build new automation on Readarr.** If you have existing Readarr:
  - Plan migration over next 6-12 months
  - Accept that bugs won't be fixed upstream
  - Metadata lookups may fail; community mirror `rreading-glasses` is unsupported third-party
- **NEW PATTERN: "RETIRED-BUT-CATALOGED"** status. Recipe convention: when a project is officially retired but still has user-base migration-advisory, we keep the recipe WITH banner and framing that highlights RETIRED status + migration paths. Different from "skipped" (which is for recipes we choose not to write) + different from "deprecated-but-functional". **1st tool in RETIRED-BUT-CATALOGED status.**
- **METADATA IS THE CRITICAL DEPENDENCY**: unlike Sonarr (TVDB + TMDB) or Radarr (TMDB) which have stable metadata providers, books/audiobooks lack a well-maintained open metadata provider. Options:
  - **Open Library** (Internet Archive project) — community tried to migrate Readarr; stalled
  - **rreading-glasses mirror** — community third-party; unsupported by anyone official
  - **Google Books API** — commercial + rate-limited
  - **Goodreads** — Amazon-owned; API deprecated
  - **No clean answer.** This is WHY Readarr died.
- **COMMUNITY FORKS**: since Readarr is GPL-3.0, anyone can fork + maintain. Watch for forks; contribute or support if one emerges.
- **HISTORICAL HUB-OF-CREDENTIALS Tier 2**: Readarr historically stored download-client API keys + indexer API keys + Calibre creds. **34th tool in hub-of-credentials family — Tier 2.** (Historical — still relevant for users with running instances.)
- **MULTIPLE INSTANCES for BOOK vs AUDIOBOOK**: Readarr's design assumes one instance per format class (ebook, audiobook). Doubles the infra cost + maintenance burden vs unified solutions.
- **PIRACY LEGAL RISK**: Readarr's primary use case is automated Usenet/BitTorrent downloads. **Regional legality varies** — some jurisdictions tolerate personal-use private torrenting; others don't. **11th tool in network-service-legal-risk family** (joining Bitmagnet, PlexTraktSync, pyLoad, TVHeadend batch 93, etc.). This risk applies to ALL Servarr *arr tools.
- **ALTERNATIVES — MIGRATION PATHS:**
  - **For ebook library management (no automation)**:
    - **Calibre** — the OG ebook manager; standalone desktop + content server
    - **Calibre-Web** — self-hosted web UI for Calibre library; Python/Flask; GPL-3
    - **Kavita** — modern self-hosted e-book/comic/manga reader + manager; GPL-3
    - **Komga** — comic/manga-focused; also handles ebooks; MIT
  - **For audiobook library management**:
    - **AudioBookShelf** — self-hosted audiobook + podcast server; ISC; excellent
    - **Booksonic** — Airsonic fork for audiobooks (less active)
  - **For automation (Readarr's core feature)**:
    - **LazyLibrarian** — Python-based *arr-like for books; still somewhat active
    - **Sonarr-forks that handle ebooks** — none robust
    - **Custom scripts** against Prowlarr / search APIs
  - **For audiobook automation**:
    - **AudioBookShelf + manual seeding** — most users end up here
- **RECOMMENDATION FOR NEW DEPLOYMENTS (2026)**:
  - **Ebooks**: Calibre-Web (management) + Kavita (reader) — no automation, but stable
  - **Audiobooks**: AudioBookShelf — excellent reader + light management
  - **Automation**: LazyLibrarian (moderate) or manual workflow (most reliable)
- **INSTITUTIONAL-STEWARDSHIP with honest-retirement**: the Servarr team's transparent + humane retirement announcement is exemplary. **Sets precedent for OSS project end-of-life communication** — acknowledge the failure mode + recommend alternatives + keep the lights dim but on for transition. **15th tool in transparent-maintenance family** (the RETIREMENT is the transparent maintenance — **rare + admirable honest-retirement signal**).
- **"RETIREMENT" as MAINTENANCE POSTURE**: distinct from "abandoned" (silent death) + "deprecated" (still-maintained but encouraged-to-migrate). Retirement = actively-saying-we're-stopping + recommending-alternatives + potentially-keeping-archive. **1st tool in "honest-retirement" sub-class of transparent-maintenance.**
- **OPEN COLLECTIVE FUNDING**: historical backers/sponsors visible on collective. Demonstrates financial sustainability wasn't the killer — lack-of-maintainer-time + metadata-infrastructure were.
- **GPL-3.0**: forkable; any sufficiently-motivated team can revive. Readarr won't come back from the original team.

## Links

- Repo: <https://github.com/Readarr/Readarr>
- Retirement notice: at the top of the upstream README
- Servarr wiki: <https://wiki.servarr.com/readarr>
- rreading-glasses (community metadata mirror): <https://github.com/blampe/rreading-glasses>
- Calibre (ebook manager): <https://calibre-ebook.com>
- Calibre-Web (web UI for Calibre): <https://github.com/janeczku/calibre-web>
- Kavita (reader alt): <https://www.kavitareader.com>
- Komga (comic/manga alt): <https://komga.org>
- AudioBookShelf (audiobook alt): <https://www.audiobookshelf.org>
- LazyLibrarian (automation alt): <https://gitlab.com/LazyLibrarian/LazyLibrarian>
- Open Library: <https://openlibrary.org>
