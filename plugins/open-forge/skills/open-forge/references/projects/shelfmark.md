---
name: Shelfmark
description: "Self-hosted book + audiobook search + request tool. Aggregates web/torrent/usenet/IRC sources + metadata providers (Hardcover, Open Library, Google Books). Pairs with Calibre-Web/Audiobookshelf. Multi-user + OIDC. License: check repo. Active; rising."
---

# Shelfmark

Shelfmark is **"Overseerr / Jellyseerr / Ombi — but for books and audiobooks"** — a self-hosted web interface that searches and requests books and audiobooks across multiple configured sources. You bring your sources (web indexers, torrent indexers, usenet indexers, IRC), metadata providers (Hardcover, Open Library, Google Books), and download clients; Shelfmark gives you ONE UI to search and request. Multi-user + request-approval workflow + automatic imports to Calibre-Web + Audiobookshelf + Grimmory. Fills the gap left by Readarr's retirement (batch 93).

Built + maintained by **calibrain** (GitHub org/author). License: check repo. Active; Docker deployment; documentation in README; still rising-star phase.

Use cases: (a) **replace Readarr** which was officially retired 2024 (batch 93 precedent) (b) **book + audiobook unified search** — no more searching 3 indexers separately (c) **family book server** — household members can request books; admin approves + imports (d) **Calibre-Web + Audiobookshelf power-user** — automates the "find → download → import" chain (e) **audiobook community** — direct audiobook-source integration (rare + valuable) (f) **multi-source resilience** — one source down? try the next (g) **privacy-respecting book discovery** — no Goodreads / Amazon tracking.

Features (from upstream README):

- **One-stop interface** — clean modern UI
- **Multiple sources** — web, torrent, usenet, IRC
- **Audiobook-native** search + download
- **Metadata providers** — Hardcover, Open Library, Google Books
- **Multi-user + requests** with approval workflow
- **Authentication** — built-in login, OIDC SSO, proxy auth, Calibre-Web-DB integration
- **Real-time download queue** with progress
- **Proxy + DNS configuration**
- **Cloudflare-protected-source handling**
- **Import integrations**: Calibre, Calibre-Web, Calibre-Web-Automated, Grimmory, Audiobookshelf

- Upstream repo: <https://github.com/calibrain/shelfmark>
- Quick start: <https://github.com/calibrain/shelfmark>
- Docker compose: <https://raw.githubusercontent.com/calibrain/shelfmark/main/compose/docker-compose.yml>

## Architecture in one minute

- **Node.js / Typescript** backend + frontend (typical shape for this class)
- **SQLite or Postgres** — DB
- **Resource**: moderate — 300-500MB RAM
- **Port 8084** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-provided `compose/docker-compose.yml`**              | **Primary**                                                                        |
| Bare-metal         | Node.js                                                                  | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `books.example.com`                                         | URL          | TLS recommended                                                                                    |
| Source credentials   | Torrent/usenet/IRC indexers + API keys                      | **CRITICAL** | **Typical *arr-family stack setup**                                                                                    |
| Metadata provider API keys | Hardcover / Google Books / Open Library tokens       | Auth         | Most have free tiers                                                                                    |
| Download client URL + key | qBittorrent / SABnzbd / NZBGet / etc.                                                                                | Integration  | For actual download                                                                                    |
| Calibre-Web or Audiobookshelf URL + key | For auto-import                                                                                                            | Integration  | Optional                                                                                                            |
| OIDC config          | (optional) SSO                                                                                                                                  | SSO          | Family/team SSO                                                                                                                                            |

## Install via Docker

```sh
curl -O https://raw.githubusercontent.com/calibrain/shelfmark/main/compose/docker-compose.yml
docker compose up -d
# Browse http://localhost:8084
```

## First boot

1. Start → browse `:8084`
2. Register admin
3. Configure metadata providers (Open Library is free)
4. Add indexer sources (torrent, usenet, IRC)
5. Add download client (qBittorrent, SABnzbd)
6. Configure import target (Calibre-Web, Audiobookshelf)
7. Search + request a book; verify end-to-end workflow
8. Configure OIDC if multi-user
9. Put behind TLS reverse proxy
10. Back up config + DB

## Data & config layout

- `/config/` — config + DB + artwork cache
- `/books/` — downloaded books (target for import)
- Client-path bind-mounts — match your download-client paths exactly (critical for auto-import)

## Backup

```sh
sudo tar czf shelfmark-$(date +%F).tgz shelfmark-config/
```

## Upgrade

1. Releases: <https://github.com/calibrain/shelfmark/releases>. Rising-star; active.
2. Docker: pull + restart.
3. Pre-1.0 likely — read release notes + back up.

## Gotchas

- **FILLS THE READARR-RETIREMENT GAP** (batch 93 precedent): Readarr was officially retired as RETIRED-BUT-CATALOGED (1st tool in that status class, batch 93). Shelfmark is a direct successor for the book-discovery-and-request workflow. **Recipe convention: note "fills-gap-from-retired-tool" relationship** — Shelfmark ← Readarr. Applicable whenever a new tool fills a retired/abandoned tool's niche.
- **NETWORK-SERVICE-LEGAL-RISK = *ARR-PIRACY-TOOLING SUB-FAMILY**: Shelfmark's torrent/usenet/IRC source integration puts it firmly in the *arr-piracy-tooling sub-family (same as Readarr 93, MediaManager 97 by inheritance). **24th tool in network-service-legal-risk family.** Similar legal exposure patterns:
  - Sources often index copyrighted content
  - DMCA notices to your IP / hosting provider
  - Private-tracker credentials = commitment to tracker rules
  - **Personal-use-only deployment**; don't offer publicly.
- **IRC SOURCES = OBSCURE CHANNEL**: Shelfmark's IRC-indexer integration is unusual + useful for certain book communities (e.g., ebook.in channels). Operationally: bot-like presence on IRC + channel moderators may ban.
- **CLOUDFLARE HANDLING = SCRAPER-ANTI-BOT WORKAROUND**: Shelfmark's "Cloudflare handling" feature helps access Cloudflare-protected sources. **Anti-bot-bypass functionality** — legal gray area + CloudFlare may actively evolve anti-bypass. Recipe convention: note "anti-bot-bypass-fragile" status.
- **HUB-OF-CREDENTIALS TIER 2**:
  - Indexer API keys (multiple)
  - Download client API keys
  - Metadata provider API keys
  - Calibre-Web / Audiobookshelf integration keys
  - OIDC tokens
  - Multi-user accounts
  - **52nd tool in hub-of-credentials family — Tier 2.**
- **VPN-SIDECAR PATTERN** (Dispatcharr 96, slskd 98 precedents) **applies to Shelfmark** — running behind Gluetun protects home IP from DMCA + hides activity from ISP. Torrent + usenet users commonly use this.
- **AUDIOBOOK PROVIDERS = NARROW NICHE**: audiobook indexers are fewer + more-insular than general-book indexers. Communities (e.g., MyAnonamouse, AudioBookBay) have strict ratio/invite rules. Respect community norms.
- **TRANSPARENT-MAINTENANCE**: active + Docker + compose file published + multiple integration options + documentation. **44th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: calibrain org + community. **37th tool in institutional-stewardship.**
- **LICENSE CHECK**: verify LICENSE file (prior conventions precedent).
- **METADATA PROVIDERS**:
  - **Hardcover** — modern + API-friendly (compared to Goodreads)
  - **Open Library** — free + open-knowledge
  - **Google Books** — commercial but widely available
  - **Goodreads** (not listed) — Amazon-controlled + deprecated API
  - Shelfmark choosing Hardcover + Open Library over Goodreads = signal of privacy-awareness
- **INTEGRATION ECOSYSTEM = ASSET-OF-RECIPE**: Shelfmark pairs with:
  - **Calibre-Web** — browser-accessible Calibre library
  - **Calibre-Web-Automated (CWA)** — CWA is a fork of Calibre-Web with automation
  - **Audiobookshelf** — self-hosted audiobook server (Plex-like)
  - **Grimmory** — book-management alternative
  - Ecosystem-familiarity (running one of above) = prerequisite for Shelfmark user
- **POST-READARR-ECOSYSTEM CATEGORY** emerging (book-management-and-discovery tools):
  - **Shelfmark** — discovery + request
  - **Calibre-Web / CWA** — library management + reading
  - **Audiobookshelf** — audiobook server
  - **Komga / Kavita** — comic/manga library
  - **LazyLibrarian** — alternative *arr-style book automation
  - **Readarr (retired)** — RETIRED-BUT-CATALOGED reference
  - **Recipe convention: "post-Readarr book-ecosystem" note** for recipes in this space.
- **REQUEST-APPROVAL WORKFLOW = SOCIAL-MEDIATION**: multi-user → requests → admin approves. This workflow is socially meaningful (family requests, friend requests). Similar in shape to Overseerr/Jellyseerr for media.
- **ALTERNATIVES WORTH KNOWING:**
  - **Readarr** (RETIRED-BUT-CATALOGED — batch 93)
  - **LazyLibrarian** — older *arr-style
  - **Calibre-Web + manual search** — DIY
  - **Overseerr / Jellyseerr** — media-request cousins (movies + TV)
  - **Choose Shelfmark if:** you want MODERN + book+audiobook + actively-developed + gap-filler.
  - **Choose LazyLibrarian if:** you want proven + older + stable.
- **PROJECT HEALTH**: active + filling-real-gap (Readarr-retired) + modern-stack + multiple-integrations. Strong rising-star signals.

## Links

- Repo: <https://github.com/calibrain/shelfmark>
- Compose: <https://github.com/calibrain/shelfmark/blob/main/compose/docker-compose.yml>
- Calibre: <https://calibre-ebook.com>
- Calibre-Web: <https://github.com/janeczku/calibre-web>
- Calibre-Web-Automated: <https://github.com/crocodilestick/Calibre-Web-Automated>
- Audiobookshelf: <https://www.audiobookshelf.org>
- Grimmory: <https://github.com/grimmory-tools/grimmory>
- Hardcover (metadata): <https://hardcover.app>
- Open Library (metadata): <https://openlibrary.org>
- Readarr (retired, batch 93): <https://github.com/Readarr/Readarr>
- Overseerr (media-request cousin): <https://overseerr.dev>
