---
name: Calibre-Web Automated (CWA)
description: "'All-in-one' self-hosted digital library — Calibre-Web modern UI + Calibre's powerful backend features + automations (auto-ingest, format conversion, metadata fixes, KOSync, OAuth/OIDC). Enhanced fork of Calibre-Web. Docker-first. GPL-3.0."
---

# Calibre-Web Automated (CWA)

Calibre-Web Automated is **Calibre-Web on steroids** — formerly "Calibre-Web Automator", now CWA. It combines **the lightweight modern Calibre-Web web UI** with **Calibre's powerful CLI backend features** and adds a slew of automations on top: **auto-ingest from a watch folder**, **format conversion**, **metadata enforcement**, **cover fixes**, **KOReader (KOSync) progress sync**, and **OAuth 2.0 / OIDC** authentication — features the stock Calibre-Web lacks or requires awkward workarounds for.

Created + maintained by **crocodilestick**. Actively developed; strong ebook/homelab community. Clean fork/enhancement of Calibre-Web (not competing with it — positioned as "Calibre-Web + Calibre's features + automations").

**Why it exists** (paraphrasing upstream): Calibre itself is fantastic but containerizes awkwardly (KasmVNC dependency, resource-heavy, terrible on mobile). Calibre-Web is lightweight + modern but misses some Calibre features. CWA stitches the gap with automation so you stop running two services in parallel.

Features:

- **Calibre-Web UI** — modern, responsive, mobile-friendly
- **Auto-ingest** — drop books into a folder, CWA imports + tags + converts
- **Metadata fixing** — enforce your preferred format/tags/language
- **Format conversion** — EPUB ↔ Kindle (MOBI/AZW3/KFX) ↔ PDF ↔ etc. (uses Calibre's CLI tools)
- **Automatic cover generation + fixing**
- **OPDS feeds** — for e-readers that support it (KOReader, Moon+ Reader, etc.)
- **KOReader sync (KOSync)** — progress + bookmarks sync
- **Send-to-Kindle / Kobo** via email
- **Enhanced OAuth 2.0 / OIDC** — SSO with Authelia/Authentik/Keycloak/etc.
- **Multi-user** with per-user shelves + reading progress
- **Full-text search** (via optional indexer)
- **Usenet / torrent-ready** (pairs with Readarr)
- **Docker-first** — official image includes Calibre's CLI toolchain

- Upstream repo: <https://github.com/crocodilestick/Calibre-Web-Automated>
- Docker Hub: <https://hub.docker.com/r/crocodilestick/calibre-web-automated>
- Releases: <https://github.com/crocodilestick/Calibre-Web-Automated/releases>
- Community: see repo; Discord linked in README
- Ko-fi: <https://ko-fi.com/crocodilestick>

**Affiliated projects:**
- **Shelfmark** (book-downloader front-end) — <https://github.com/calibrain/shelfmark>
- **Calibre Web Companion** (Flutter mobile app) — <https://github.com/doen1el/calibre-web-companion>

## Architecture in one minute

- **Python / Flask** app (Calibre-Web base) + **Calibre CLI binaries** (`ebook-convert`, `calibredb`, etc.) bundled
- **SQLite** (`metadata.db`) — Calibre library metadata
- **Filesystem** for book files
- **Watch folder** monitored for new files → auto-import → conversion → filed into library
- **Runs best as Docker** — image handles Calibre CLI complexity
- **Resource**: 300-500 MB RAM idle; spikes during conversion

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                          |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker Compose (`crocodilestick/calibre-web-automated`)**         | **Upstream-recommended** — only supported path                                     |
| Synology / QNAP / Unraid | Docker package                                                            | Very popular                                                                              |
| Raspberry Pi       | arm64 supported — works; conversions slow on Pi                                              | Fine for small libraries                                                                                  |
| Kubernetes         | Community manifests                                                                           | Works                                                                                                                |
| Bare metal / native | Not supported — CWA is Docker-only by design                                                                                  |                                                                                                                                           |

## Inputs to collect

| Input                    | Example                                   | Phase        | Notes                                                                     |
| ------------------------ | ----------------------------------------- | ------------ | ------------------------------------------------------------------------- |
| Domain                   | `books.home.lan`                              | URL          | Reverse proxy + TLS                                                               |
| Calibre library path     | `/calibre-library`                                    | Storage      | Where books live (bind-mount)                                                                 |
| Ingest folder            | `/cwa-book-ingest`                                                | Storage      | CWA watches this for new files                                                                                     |
| Admin                    | **default `admin` / `admin123`** — CHANGE                    | Bootstrap    | Default credential noise same as batches 68-71                                                                                        |
| OAuth provider           | Authelia / Authentik / Keycloak / Google / Microsoft / GitHub     | Auth         | Configure after install                                                                                                                      |
| Migration from stock CW  | Copy existing `app.db` + library                                                    | Migration    | Documented path                                                                                                                                                  |

## Install via Docker Compose

```yaml
services:
  calibre-web-automated:
    image: crocodilestick/calibre-web-automated:latest    # pin in prod
    container_name: calibre-web-automated
    restart: unless-stopped
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Los_Angeles
    volumes:
      - ./config:/config
      - ./ingest:/cwa-book-ingest
      - ./library:/calibre-library
    ports:
      - "8083:8083"
```

Browse `http://<host>:8083/` → log in `admin` / `admin123` → **change password IMMEDIATELY**.

## First boot

1. Log in → **change admin password** (default `admin` / `admin123` — do NOT leave)
2. `Admin → Configuration → Calibre Library Path` → set to `/calibre-library`
3. Create initial Calibre library if fresh (CWA docs explain) or point at existing `metadata.db`
4. Drop a test EPUB into `./ingest/` → CWA auto-imports → appears in library
5. Configure auto-conversion preferences (Admin → CWA settings)
6. Configure KOSync endpoint: `http://<host>:8083/kosync/` on KOReader
7. Set up OAuth/OIDC for SSO (Admin → OAuth)
8. Add users; configure per-user shelves
9. (Optional) integrate Readarr / Shelfmark for automatic downloads

## Data & config layout

- `/config/` — `app.db` (CWA users + settings) + logs + config
- `/calibre-library/` — `metadata.db` (Calibre's library catalog) + book files organized by `Author/Title/`
- `/cwa-book-ingest/` — drop zone (processed files are moved/consumed)
- Keep all three volumes backed up

## Backup

```sh
# Everything
sudo tar czf cwa-$(date +%F).tgz config/ library/
# Ingest folder is ephemeral; skip
```

**Library is the big one** — can be 10s-100s GB of books. Plan storage + backup accordingly.

## Upgrade

1. Releases: <https://github.com/crocodilestick/Calibre-Web-Automated/releases>. Active.
2. Docker: bump tag → restart → migrations auto.
3. **Back up `config/` + `library/` first.**
4. Read release notes — occasionally schema changes require careful migration.

## Gotchas

- **Default creds `admin` / `admin123`** — change on first login, always. (Same as Zabbix, GLPI, Speedtest Tracker.)
- **Docker-only by design**: CWA bundles Calibre CLI + Kindle/Kobo conversion tools (including occasionally-proprietary components via Docker). Not a "run it native" tool.
- **Library on HDD vs SSD**: metadata scans + format conversions benefit from SSD. Pure storage on HDD is fine, but ingest/conversion throughput is better on SSD.
- **Ingest folder permissions**: PUID/PGID must match folder owner or drops silently fail. Check logs.
- **Calibre library = specific directory structure** (managed by Calibre / `calibredb`). Don't manually rearrange files — `metadata.db` will drift. Use CWA's UI or `calibredb` CLI.
- **Migration from stock Calibre-Web**: documented — copy `app.db` + library path. Test on a copy before switching production.
- **Piracy disclaimer**: upstream explicitly states CWA doesn't approve of or support piracy. Self-host responsibly. Shelfmark (affiliated) is a search/download front-end; how users source content is their responsibility.
- **Format conversion costs CPU**: large libraries being bulk-re-converted can saturate a Pi for hours. Schedule off-hours.
- **KFX (Amazon proprietary format)**: requires Calibre's KFX plugin; bundled in CWA image but Amazon can change KFX format without notice → conversions break until updated. Stay current.
- **Send-to-Kindle**: via email requires configured SMTP + Amazon's "approved senders" list updated on Amazon account. Amazon occasionally changes email rules.
- **KOSync endpoint**: some KOReader versions have quirky auth handshakes — check CWA's docs for current endpoint URL format.
- **OAuth/OIDC with Authelia/Authentik**: well-tested; follow docs for redirect URI + group mapping.
- **Upstream bandwidth for downloads**: don't expose public without authentication + rate limit. Ebook libraries can get DMCA-noticed if publicly exposed with copyrighted content.
- **Shelfmark** integration is optional but popular — pairs for one-click "search + download to ingest" flow.
- **Legal status of auto-downloading**: varies by jurisdiction + content; always user's responsibility.
- **Resource scale**: 1000 books = fine; 100,000 books = plan DB indexing + SSD + RAM (full-text search index adds memory).
- **License**: **GPL-3.0** (inherited + compatible with Calibre-Web base).
- **Relationship to Calibre-Web**: CWA is a friendly fork/superset. Upstream Calibre-Web continues separately; CWA pulls in upstream fixes + adds its own.
- **Relationship to Calibre**: CWA is independent; doesn't run Calibre's GUI (that's the whole point of Calibre-Web). Uses Calibre's CLI tools only.
- **Alternatives worth knowing:**
  - **Calibre-Web** (stock) — simpler; fewer features; still actively maintained (upstream)
  - **Calibre** (native) — full Calibre desktop; KasmVNC in Docker for UI
  - **Komga** (batch 66) — comics/manga focused; not for ebooks primarily
  - **Kavita** — comics + ebooks; modern UI; competitor
  - **Audiobookshelf** — audiobooks + podcasts (separate focus)
  - **Readarr** — *arr for ebooks; pairs with CWA
  - **LazyLibrarian** — similar to Readarr; older
  - **Choose CWA if:** you want Calibre-Web's UI + Calibre's backend + auto-ingest + ebook automations.
  - **Choose Kavita if:** you read comics + ebooks + want modern UI.
  - **Choose Komga if:** manga/comics priority.
  - **Choose Calibre-Web (stock) if:** simpler + no automation needs.

## Links

- Repo: <https://github.com/crocodilestick/Calibre-Web-Automated>
- Docker Hub: <https://hub.docker.com/r/crocodilestick/calibre-web-automated>
- Releases: <https://github.com/crocodilestick/Calibre-Web-Automated/releases>
- Ko-fi: <https://ko-fi.com/crocodilestick>
- Shelfmark (affiliated downloader): <https://github.com/calibrain/shelfmark>
- Calibre Web Companion (mobile): <https://github.com/doen1el/calibre-web-companion>
- Calibre-Web (upstream base): <https://github.com/janeczku/calibre-web>
- Calibre: <https://calibre-ebook.com>
- KOReader: <https://koreader.rocks>
- Readarr: <https://github.com/Readarr/Readarr>
- Kavita (alt): <https://www.kavitareader.com>
- Komga (batch 66, alt comics): <https://komga.org>
