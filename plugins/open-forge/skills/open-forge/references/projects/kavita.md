---
name: Kavita
description: Fast, feature-rich, cross-platform reading server for manga, webtoons, comics (CBR/CBZ/ZIP/RAR/7z), and books (EPUB/PDF). Responsive web readers, OIDC login, role-based access, smart filters, reading lists, scrobbling. Optional paid "Kavita+" tier for external metadata. GPL-3.0.
---

# Kavita

Kavita is a self-hosted reading server built for digital library owners. It indexes your existing folders of manga, webtoons, comics, and e-books, and serves them via a sleek web reader that works on phones, tablets, and desktops. Think of it as Plex for books.

Core strengths:

- **Format breadth** — CBR, CBZ, ZIP, RAR (legacy + RAR5), 7zip, raw image folders, EPUB, PDF
- **Purpose-built web readers** — continuous-scroll webtoon mode, virtual-page EPUB reader, PDF reader with per-device progress
- **Rich metadata** — scan from files, edit in UI, smart filters + saved searches
- **Reading lists** — including CBL (Comic Book List) import
- **Role-based access** — age restrictions, per-user library scoping, OIDC login
- **Collections + "Want to Read"** — curated groupings
- **EPUB annotations/highlights** — syncs across devices
- **Multi-language UI** — translated on Weblate
- **Themes** — community theme repo

**Kavita+ (paid)** is a subscription service from the lead maintainer (majora2007) that adds external metadata fetching (Anilist/MAL scrobbling + rich metadata). The core server is free/GPL; Kavita+ is an external paid add-on.

- Upstream repo: <https://github.com/Kareadita/Kavita>
- Website: <https://www.kavitareader.com>
- Wiki/docs: <https://wiki.kavitareader.com>
- Demo: <https://demo.kavitareader.com> (user `demouser` / password `Demouser64`)
- Docker image: <https://hub.docker.com/r/jvmilazz0/kavita>

## Architecture in one minute

- **ASP.NET Core 8** backend + Angular frontend, shipped as a single process
- **SQLite** metadata DB (Kavita does NOT support Postgres — SQLite only)
- **Port 5000** by default
- Library scan is file-based: watch folder OR manual/scheduled scan
- Thumbnails/covers cached on disk; large libraries have non-trivial cache sizes
- Active development; **explicitly pre-1.0** — upstream warns data loss is possible, keep backups

## Compatible install methods

| Infra      | Runtime                                            | Notes                                                    |
| ---------- | -------------------------------------------------- | -------------------------------------------------------- |
| Single VM  | Docker / Compose (`jvmilazz0/kavita`)                | **Most common**                                            |
| Single VM  | Native .NET binary (Linux, macOS, Windows)           | From GitHub releases                                        |
| Kubernetes | Community Helm charts OR raw manifests                | Stateless except data volume                                  |
| NAS        | Synology / QNAP / Unraid community templates           | Popular for library stashes                                    |
| Managed    | PikaPods (20% revenue to upstream)                     | <https://www.pikapods.com/pods?run=kavita>                       |

## Inputs to collect

| Input              | Example                            | Phase      | Notes                                                              |
| ------------------ | ---------------------------------- | ---------- | ------------------------------------------------------------------ |
| Manga/comics library path | `/mnt/comics`                | Storage    | Read-only mount OK for the library; config dir is writable             |
| Config path              | `/opt/kavita/config`                | Storage    | SQLite DB, covers, logs, bookmarks                                        |
| Port                     | `5000`                              | Network    | UI + API                                                                  |
| Admin account            | created via first-run wizard        | Bootstrap  | First user = admin. Race risk if exposed to internet during setup.         |
| OIDC (optional)          | issuer + client + secret            | Auth       | v0.8+ — Keycloak / Authentik / etc.                                         |
| Reverse proxy            | `X-Forwarded-*` headers              | Network    | For TLS — Kavita is plain HTTP internally                                      |
| `TZ`                     | `America/New_York`                   | Scheduling | Scans + scheduled tasks use this                                              |

## Install via Docker Compose

```yaml
services:
  kavita:
    image: jvmilazz0/kavita:0.8.x    # pin specific tag; check Docker Hub
    container_name: kavita
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      TZ: America/New_York
    volumes:
      - ./config:/kavita/config
      # Mount library paths — as many as you like, read-only recommended
      - /mnt/manga:/manga:ro
      - /mnt/comics:/comics:ro
      - /mnt/books:/books:ro
```

First run → browse `http://<host>:5000` → wizard prompts to create admin account. **Do this immediately** to avoid first-user-is-admin race if exposed to the internet.

## Library layout recommendations

Kavita auto-detects series from folder names. Recommended structure:

```
/manga
├── Berserk
│   ├── Berserk Vol 01.cbz
│   ├── Berserk Vol 02.cbz
├── One Piece
│   ├── One Piece Vol 001.cbz
│   ...
/comics
├── Batman
│   ├── Batman (2016)
│   │   ├── Batman 001 (2016).cbz
```

Within the Kavita UI:

- Libraries → **Add library** → type (Manga / Comic / Book / Raw Images / LightNovel) → pick folders
- Metadata is derived from file/folder names; you can fine-tune via ComicInfo.xml (embedded in CBZ) or EPUB metadata.

**ComicInfo.xml** is the single best investment for a good-looking library — tools like [Comictagger](https://github.com/comictagger/comictagger) batch-embed it.

## OIDC login (v0.8+)

Kavita 0.8.0 introduced OIDC. Config in **Server Settings → OIDC**:

- Issuer URL: `https://auth.example.com`
- Client ID / Secret
- Redirect URI: `https://kavita.example.com/api/oauth2/callback`
- Auto-create users on first login: checkbox
- Assign roles via claim: optional

Works with Authelia, Authentik, Keycloak, Zitadel, Logto.

## Data & config layout

Inside `/kavita/config`:

- `kavita.db` — SQLite DB (users, metadata, reading progress, libraries)
- `covers/` — cover thumbnails (can be several GB for large libraries)
- `bookmarks/` — per-user bookmarks
- `logs/` — rolling logs
- `temp/` — scan work area
- `themes/` — custom themes
- `files/` — cached EPUB decompressions

**Library folders** (the actual comics/books) are mounted separately and are typically mounted read-only.

## Backup

```sh
# Config (includes DB) — this is what you REALLY need
docker run --rm -v "$(pwd)/config:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/kavita-config-$(date +%F).tgz -C /src .

# Or just the DB
cp ./config/kavita.db ./kavita-db-$(date +%F).db
```

**Library files** (your comics/books) — back up separately from Kavita (normal file-level backup).

## Upgrade

1. Releases: <https://github.com/Kareadita/Kavita/releases>. **Active** (frequent patches).
2. **Pre-1.0** — upstream explicitly warns data schema changes can require manual migration; always back up `kavita.db` before upgrading.
3. `docker compose pull` → `docker compose up -d`. Migrations run on startup.
4. `nightly` and `stable` tags exist — use `stable` (or pinned version) for production; `nightly` = daily builds, may break.

## Gotchas

- **Kavita is explicitly pre-1.0** — upstream quote: "You may lose data and have to restart." Take the backup warning seriously.
- **SQLite only** — no Postgres/MySQL backend. SQLite handles libraries of hundreds of thousands of files, but schedule scans wisely (see below).
- **Library scans can be slow** on big libraries (>50k files) — first scan can take hours on NAS. Use scheduled full-scans + file-system-watcher for real-time additions.
- **RAM usage during scans** can spike — plan for 1-2 GB during heavy metadata extraction (EPUB parsing especially).
- **First-user-is-admin race** — if you expose Kavita to the internet before creating the admin, someone else can. Always set up before adding DNS/reverse proxy.
- **Default port 5000 collides with macOS AirPlay** — if running locally on Mac, change the host port.
- **Kavita+ is a commercial add-on** — free core server does NOT get: external metadata scraping (Anilist/MAL/MU/CV), scrobbling, rating+review sync, chapter auto-match. Those require Kavita+ ($3-4/month; 50% off first month with `FIRSTTIME` promo). If you contribute via OpenCollective, ask majora2007 for a provisioned license.
- **OIDC was 0.8+** — earlier versions had local auth only.
- **RAR5 support** is via a native library; some RAR files fail to extract — convert problematic CBRs to CBZ (`7z a` or [kcc](https://github.com/ciromattia/kcc)).
- **PDF reading** is supported but less polished than EPUB/CBZ — consider converting PDFs to CBZ if they're actually comics (many tools do this).
- **Thumbnails can fill disk** — 100k-series library = several GB of covers. Plan `/kavita/config` partition accordingly.
- **Age restriction** + **library scoping** are powerful — let kids log in with accounts restricted to kid libraries + max age rating.
- **Reverse proxy** — Kavita runs HTTP only. Always TLS-terminate in nginx/Caddy/Traefik. Watch `X-Forwarded-*` headers (Kavita honors them when `TrustedReverseProxies` is set in `appsettings.json`).
- **Webtoon continuous mode** is the killer reader feature — auto-scroll between chapters without leaving the reader.
- **KOReader sync** is supported — set KOReader's sync server to your Kavita instance; read your library on e-readers.
- **Tachiyomi / Mihon / Suwayomi** — popular mobile manga readers — can connect to Kavita via the [Tachiyomi-Extensions](https://github.com/Kareadita/Tachiyomi-Extensions) Kavita source.
- **Open Audible Book Store (OPDS)** endpoint exists — `https://kavita.example.com/api/opds/<API_KEY>` — use with any OPDS-compatible reader (Moon+, KOReader, etc.).
- **GPL-3.0 license** — core server; Kavita+ is a hosted service on top.
- **Alternatives worth knowing:**
  - **Komga** — very similar Kotlin/Spring project; mature; PostgreSQL support; Apache 2.0 (separate recipe)
  - **Ubooquity** — older Java reader; less active
  - **Calibre-Web / Calibre-Web-Automated** — E-book focused (EPUB/MOBI/PDF); weaker for manga/comics
  - **Stump** — newer Rust project; fast; still maturing
  - **COPS** — PHP OPDS server for Calibre libraries
  - **Audiobookshelf** — audiobooks + ebooks hybrid
  - **Choose Kavita if:** you want the most polished reader UX for manga/webtoons + comics; are OK with SQLite; want OIDC.
  - **Choose Komga if:** you want Postgres; prefer more conservative/mature codebase; value more granular series-book-issue model.

## Links

- Repo: <https://github.com/Kareadita/Kavita>
- Website: <https://www.kavitareader.com>
- Wiki: <https://wiki.kavitareader.com>
- Install docs: <https://wiki.kavitareader.com/guides/installation>
- Themes repo: <https://github.com/Kareadita/Themes>
- Kavita+ info: <https://wiki.kavitareader.com/kavita+>
- Docker Hub: <https://hub.docker.com/r/jvmilazz0/kavita>
- Releases: <https://github.com/Kareadita/Kavita/releases>
- Demo: <https://demo.kavitareader.com>
- Discord: <https://discord.gg/eczRp9eeem>
- Tachiyomi/Mihon extensions: <https://github.com/Kareadita/Tachiyomi-Extensions>
- OpenCollective: <https://opencollective.com/kavita>
- Translations (Weblate): <https://hosted.weblate.org/engage/kavita/>
