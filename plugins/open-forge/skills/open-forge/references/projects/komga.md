---
name: Komga
description: "Self-hosted comics, manga, magazines, and ebooks server. Reads CBR/CBZ/PDF/EPUB; OPDS feeds for ebook readers; modern web reader with webtoon mode; Kavita-like library management. Kotlin/Spring + Vue.js. MIT."
---

# Komga

Komga is **a self-hosted comics / manga / magazines / ebooks server** — point it at folders of comic-book archives (CBR/CBZ) or PDFs/EPUBs, it indexes them, serves them via a beautiful web reader and OPDS feeds, and syncs reading progress.

Ideal for: **comic book & manga collectors**. Also handles magazines + PDFs + EPUBs competently.

Features:

- **Libraries + Series + Books hierarchy** — folder structure preserved
- **Formats**: CBR, CBZ, CB7, CBT, EPUB, PDF, MOBI (limited)
- **Web reader** — click/tap navigation, keyboard shortcuts, fit-to-width/height, double-page spread
- **Webtoon mode** — scrolling vertical reader for Korean webtoons / vertical manga
- **OPDS 1.2 + 2.0 feeds** — plug into ebook readers (Chunky, Panels, KyBook, Moon+ Reader, etc.)
- **Kavita-style reading lists + collections**
- **Metadata**: ComicInfo.xml inside archives, EPUB metadata
- **Metadata providers** — ComicVine, AniList, MangaUpdates via plugins/scripts
- **Multi-user** with per-library permissions
- **Read progress sync** across devices
- **Age ratings** + content filters per user
- **Thumbnail generation**
- **Duplicate detection**
- **REST API** + API tokens
- **Import from Plex / Kavita / etc.** via metadata
- **Tachiyomi extension** — read Komga library in the Android Tachiyomi app
- **Kindlebridge support** — send to Kindle

- Upstream repo: <https://github.com/gotson/komga>
- Website: <https://komga.org>
- Docs: <https://komga.org/docs/introduction>
- Demo: (no public; try locally)
- Docker Hub: <https://hub.docker.com/r/gotson/komga>

## Architecture in one minute

- **Kotlin / Spring Boot** backend
- **Vue.js** frontend
- **SQLite** (default) — fine for millions of pages
- **JVM** — ~500 MB RAM typical; bursts during scans
- **File-tree scanner** watches libraries for changes

## Compatible install methods

| Infra              | Runtime                                                          | Notes                                                                          |
| ------------------ | ---------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker (`gotson/komga`)**                                          | **Upstream-recommended**                                                           |
| Single VM          | Native JAR + Java 17+                                                       | Cross-platform                                                                               |
| Synology / QNAP    | Docker via Container Manager                                                            | Common NAS deployment                                                                                   |
| Raspberry Pi       | arm64 Docker (Pi 4+ recommended for JVM)                                                           | Works; Pi 3 marginal                                                                                               |
| Kubernetes         | Community Helm                                                                                            | Works                                                                                                                            |
| Managed            | — (no SaaS)                                                                                                                 |                                                                                                                                               |

## Inputs to collect

| Input              | Example                                | Phase       | Notes                                                                       |
| ------------------ | -------------------------------------- | ----------- | --------------------------------------------------------------------------- |
| Library dir        | `/data/comics`, `/data/manga`                  | Storage     | Mount read or read-write                                                                  |
| Komga data dir     | `/config`                                            | State       | SQLite + thumbnails + user data                                                                         |
| Port               | `25600`                                                    | Network     | Default                                                                                                       |
| Admin user         | first user on bootstrap via env                                       | Bootstrap   | Or set `KOMGA_ADMINEMAIL` / password env                                                                                 |
| OPDS               | included                                                                       | Feature     | Enabled by default                                                                                                                      |
| Reverse proxy      | Caddy / Traefik / nginx                                                                | TLS         | Recommended                                                                                                                                              |

## Install via Docker

```yaml
services:
  komga:
    image: gotson/komga:1.20                          # pin
    container_name: komga
    restart: unless-stopped
    ports:
      - "25600:25600"
    environment:
      TZ: America/Los_Angeles
    volumes:
      - ./config:/config
      - /data/comics:/data/comics                       # your library (read-only for safety)
      - /data/manga:/data/manga
    user: "1000:1000"
```

Browse `http://<host>:25600/`.

## First boot

1. First-visit wizard → create admin email + password
2. **Administration → Libraries → Add** → give it a name + path (inside-container path, e.g., `/data/comics`)
3. Komga scans → builds thumbnails → series/books appear
4. Configure periodic rescan (or use inotify — on by default)
5. Create additional users → assign library access
6. Add OPDS to your e-reader (URL: `http://<host>:25600/opds/v1.2/catalog`)
7. Install **Tachiyomi** on Android → add Komga extension → enter URL + creds → read manga on-the-go

## Data & config layout

- `/config/database.sqlite` — SQLite (libraries + series + books + users + progress)
- `/config/thumbnails/` — cached thumbnails
- `/data/...` — source files (not touched by Komga)

## Backup

```sh
docker compose stop komga           # for consistent SQLite
tar czf komga-$(date +%F).tgz config/
docker compose start komga
```

Source library files back up independently.

## Upgrade

1. Releases: <https://github.com/gotson/komga/releases>. Active; weekly-ish.
2. Back up `config/` before major (1.x → 2.x) jumps.
3. Docker: bump tag; migrations auto.
4. Read release notes for breaking changes in metadata model.

## Gotchas

- **Mount your library read-only** when possible — Komga doesn't need write access (with one exception: if you use thumbnail side-files, but prefer to store in `/config/`).
- **File organization matters**: `Library/Series Name/Series Name - c001.cbz` or `Library/Series Name/Volume 01.cbz` — keeping a consistent scheme lets Komga group into series + volumes cleanly.
- **ComicInfo.xml** embedded in CBR/CBZ archives is the metadata standard — Komga reads it. Use **ComicTagger** / **Mylar3** to batch-write metadata.
- **EPUB metadata**: Komga reads EPUB `content.opf`; ensure clean metadata for good library organization.
- **Tachiyomi users**: the Komga extension is first-class. Set up once; phone/tablet access to your entire library.
- **Thumbnail generation**: first scan of a large library is CPU-heavy (JVM + image manipulation). Let it finish; ~1-3 seconds per book.
- **RAM**: JVM defaults are reasonable but can balloon during large scans. Set `JAVA_TOOL_OPTIONS=-Xmx2G` if you see OOM.
- **Database size**: SQLite scales to tens of millions of pages. If you have >100k books, watch `database.sqlite` size + backup frequency.
- **OPDS authentication**: basic auth over OPDS; use app-specific passwords if Komga adds them (check current release).
- **Age ratings**: set per-book or per-series + per-user max — enforces kid-safe libraries.
- **Reading progress sync** requires users to log in across devices; anonymous reading doesn't track.
- **Webtoon mode**: long vertical scroll — toggle per book if Komga guesses wrong.
- **Import reading progress from Kavita / Plex / Calibre**: check upstream migration scripts; some community tools exist.
- **Duplicate detection**: helps clean up multi-source libraries.
- **Filename parsing**: Komga uses heuristics; for unusual patterns (`.5` specials, `Vol 1 Part 2`), manually set series/volume.
- **Reverse proxy WebSocket**: Komga uses WS for live updates; ensure proxy supports it.
- **Mobile browser**: responsive UI works; PWA install for fullscreen.
- **Comparison to Kavita**: Kavita is ASP.NET-based; richer social/review features; Komga is Java-based; more OPDS-focused + simpler.
- **Comparison to Calibre Web**: Calibre is ebook-first; Komga is comic-first; both handle both but with different biases.
- **Comparison to Ubooquity**: older Java comic server; Komga has largely replaced it.
- **License**: **MIT**.
- **Alternatives worth knowing:**
  - **Kavita** — modern .NET comic/ebook server; richer features (separate recipe likely)
  - **Calibre Web** — ebook-first; great for EPUBs; PDF/CBZ less polished (separate recipe likely)
  - **Ubooquity** — older Java; largely superseded
  - **Calibre** (desktop) — library manager, great for organizing; no multi-user web UI
  - **Lazy Librarian** — book-downloader adjacent
  - **Komga + Mylar3** — pair for auto-downloading comics to your Komga library
  - **Komga + Kapowarr** — similar auto-downloader
  - **Plex + comics plugin** — works but Komga + Tachiyomi is better UX
  - **Choose Komga if:** you want a polished comic/manga server with great OPDS + Tachiyomi integration.
  - **Choose Kavita if:** you want more ebook-focused features + social/reviews.
  - **Choose Calibre Web if:** primarily EPUB.

## Links

- Repo: <https://github.com/gotson/komga>
- Website: <https://komga.org>
- Docs: <https://komga.org/docs/introduction>
- Installation: <https://komga.org/docs/installation/docker>
- Releases: <https://github.com/gotson/komga/releases>
- Docker Hub: <https://hub.docker.com/r/gotson/komga>
- Discord: <https://discord.gg/TdRpkDu>
- Reddit: <https://www.reddit.com/r/Komga>
- Tachiyomi extension: <https://komga.org/docs/guides/tachiyomi>
- ComicTagger (metadata tool): <https://github.com/comictagger/comictagger>
- Mylar3 (comic downloader): <https://github.com/mylar3/mylar3>
- Kavita (alt): <https://www.kavitareader.com>
- Calibre Web (alt): <https://github.com/janeczku/calibre-web>
- Ubooquity (alt): <https://vaemendis.net/ubooquity/>
