---
name: Shaarli
description: "Personal, minimalist, super-fast, database-free bookmarking service — PHP single-user link-shelf. Original Shaarli inspired many bookmark-sharing tools; still actively maintained. Self-hosted personal link-archive + RSS feed + public sharing. PHP. Zlib/Libpng license (custom FOSS)."
---

# Shaarli

Shaarli is **"your personal, minimalist, super-fast bookmarking service — no database required"** — a single-user PHP application you install on shared hosting or a tiny VPS, hit `/` to log in, and start shelving links. Each link gets a title, description, tags, permanent URL, and an optional public view. Use it as a **personal read-it-later** + **public link-shelf + micro-blog**. The original **"you have a server? you have a Shaarli."** minimalist bookmarking project. Tons of descendants + forks inspired by it (LinkAce, Shiori, Linkding, etc.), but the original is still maintained + fast + compact.

Built + maintained by **Shaarli org** (community; forked from sebsauvage's original in 2015 and maintained by the community since). **License: custom FOSS** (Zlib/Libpng-style — GitHub API returns `NOASSERTION`; see `COPYING` in repo; free software with attribution). **Single-user by design.** Data stored in **flat files** — no MySQL / Postgres / SQLite required; portable backup = copy a directory.

Use cases: (a) **replace Pocket / Pinboard / Instapaper / del.icio.us legacy** — self-hosted (b) **public link-shelf / linkblog** — share your reading with the world via RSS + permalink URLs (c) **personal archive** of read-articles + reference-links (d) **minimalist homelab bookmark** tool on smallest Pi (e) **RSS feed publisher** — your Shaarli IS a feed source others can subscribe to.

Features:

- **Single-user** — one admin account
- **Flat-file storage** — PHP serialized files; no DB
- **Tags + search + full-text**
- **Public / private per-link**
- **RSS/Atom feed** of your public links
- **"Daily" view** — your own daily digest
- **Bookmarklet** — one-click bookmark from any browser
- **API** — add/edit/query programmatically
- **Themes + plugins** — actively maintained ecosystem
- **Markdown support** for descriptions
- **ReadYourself plugin** / Wallabag integration
- **Export / import** — Netscape bookmark format (interop with every other bookmark tool)
- **LDAP auth** (via plugin / reverse-proxy)
- **Mobile-friendly UI**

- Upstream repo: <https://github.com/shaarli/Shaarli>
- Docs: <https://shaarli.readthedocs.io>
- Docker (GHCR): <https://github.com/shaarli/Shaarli/pkgs/container/shaarli>
- Docker Hub: <https://hub.docker.com/r/shaarli/shaarli>
- Demo: <https://demo.shaarli.org> (`demo` / `demo`)
- Gitter chat: <https://gitter.im/shaarli/Shaarli>
- Ecosystem / plugins: <https://github.com/shaarli>
- Awesome-Shaarli-style-tools: <https://links.kevinmarks.com/> (examples)

## Architecture in one minute

- **PHP 7.4+ / 8.x** — web application
- **Flat-file storage** — no DB
- **Single-user** — one admin
- **Resource**: tiny — works on shared hosting, Raspberry Pi Zero, any PHP host
- **Port 80/443** via Apache / nginx-fpm / Caddy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`ghcr.io/shaarli/shaarli`** (multi-arch)                      | **Simplest modern path**                                                           |
| Apache / nginx + PHP-FPM | Tarball release → unpack → web server → done                      | Classic LAMP                                                                               |
| Shared hosting     | Upload files; Shaarli supports shared-hosting deploys                                   | Historical strength                                                                        |
| Raspberry Pi       | Fine — PHP8 + nginx                                                                 | Tiny resource footprint                                                                                    |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `links.example.com`                                         | URL          | TLS required for non-local use                                                                                    |
| Admin user + password | At first-login setup                                                   | Bootstrap    | **Strong password mandatory**                                                                                    |
| Timezone             | e.g., `Europe/Berlin`                                                                  | Config       | For "Daily" view + timestamps                                                                                                              |
| Data dir             | `/var/www/shaarli/data` (or Docker volume)                                                                                     | Storage      | Flat files — back this up                                                                                                                      |
| Reverse proxy headers                       | `X-Forwarded-For` / `X-Forwarded-Proto`                                                                                                                         | Network      | Set correctly if behind proxy                                                                                                                                          |

## Install via Docker

```sh
docker run -d --name shaarli \
  -p 8000:80 \
  -v shaarli-data:/var/www/shaarli/data \
  ghcr.io/shaarli/shaarli:latest   # **pin version** in prod
```

Or via docker-compose:

```yaml
services:
  shaarli:
    image: ghcr.io/shaarli/shaarli:latest    # pin
    restart: unless-stopped
    volumes:
      - ./shaarli-data:/var/www/shaarli/data
    ports: ["8000:80"]
```

Per <https://shaarli.readthedocs.io>.

## First boot

1. Browse `http://host:8000` → installer wizard
2. Set admin username + password
3. Set timezone + page title + default-privacy (public/private)
4. Install bookmarklet: drag to browser bookmarks bar
5. Test: add first link via bookmarklet
6. Subscribe to your own RSS feed → verify
7. Put behind TLS reverse proxy
8. Back up `/var/www/shaarli/data` (or mounted volume)

## Data & config layout

- `data/config.json.php` — admin creds + config
- `data/datastore.php` — your links (flat-file; **THE critical file**)
- `data/` — plugins, themes, cache
- **No DB** — `data/` directory IS your database

## Backup

```sh
docker compose stop shaarli
sudo tar czf shaarli-data-$(date +%F).tgz shaarli-data/
docker compose start shaarli
```

Portability = trivial. Copy `data/` anywhere; restore anywhere.

## Upgrade

1. Releases: <https://github.com/shaarli/Shaarli/releases>. Slow but steady cadence.
2. Docker: `docker pull + up -d`.
3. Auto-migration on boot (schema changes in `datastore.php` format).
4. Back up `data/` BEFORE upgrading — just in case.

## Gotchas

- **Flat-file storage = simplicity benefit + scale limit.** Fast for hundreds-to-thousands of links. At **10,000+ links** + full-text search, response times degrade (PHP reads the whole datastore into memory). Not a wiki-scale tool.
- **Single-user enforced** — no teams, no shared accounts. By design. If you want multi-user bookmark sharing → **Linkding / Wallabag / LinkAce / Shiori** (separate tools).
- **Admin password stored HASHED** in `config.json.php` — treat as secret but modern hashing makes offline-brute-force hard. Still: **change-on-first-boot** and don't share the data dir publicly.
- **Public links are REALLY PUBLIC** — indexed by search engines unless you add `robots.txt` / meta noindex. If you post private reading lists publicly by accident, assume it's crawled.
- **Historical license note**: **custom Zlib/Libpng-style license** (GitHub API returns `NOASSERTION`). Actual license text in `COPYING` file — compatible with Free-Software commercial use. **Same "review LICENSE" discipline as Chartbrew (batch 86).** Confirm your use-case against the actual license text.
- **PHP version drift**: Shaarli targets PHP 7.4+ but modern best practice is PHP 8.x. Old shared-hosting providers running PHP 5.6 won't work.
- **Sessions + reverse-proxy**: if behind reverse proxy with path-prefix (`example.com/shaarli/`), ensure `X-Forwarded-*` headers are set or configure the `ROOT_URL` correctly.
- **Bookmarklet quirks across browsers** — mostly works; some browsers (Safari iOS) make bookmarklets harder to install. Each browser has its own method.
- **Plugin security** — Shaarli has a plugin system that executes PHP inside your server. **Only install plugins from the official repo + trusted sources.** Same class as WordPress plugin discipline — a malicious plugin = full server compromise.
- **Migrating FROM Shaarli**: Netscape bookmark export is universal → portable to every other bookmark tool. Good lock-in-free design.
- **Migrating TO Shaarli**: import Netscape bookmarks from Pocket/Pinboard/browser → works.
- **No per-link encryption / privacy is binary** (public/private flag). If you need granular sharing (e.g., "share this with team X but not team Y"), Shaarli isn't your tool.
- **API for integrations** is nice — automated link-archival from RSS readers, pipe bookmarks from IFTTT, etc.
- **Project health**: community-maintained (post-2015 fork from original sebsauvage version); active commits; Gitter community; long-running; no immediate bus-factor concerns given low-code-complexity + broad ecosystem of Shaarli-inspired tools.
- **Cultural context**: Shaarli is part of the **French FOSS / sebsauvage-adjacent ecosystem** — PrivateBin, Lufi, FramaForms etc. If you like that ethos (minimalist, privacy-focused, PHP-based self-host), Shaarli fits.
- **Alternatives worth knowing:**
  - **Linkding** — modern Django single-user+multi-user link manager; tag-rich UI
  - **LinkAce** — PHP multi-user bookmark manager; more features
  - **Wallabag** — read-it-later with full-article archival (pocket-style)
  - **Shiori** — Go-based bookmark manager; simpler self-host
  - **Pinboard** (commercial, paid SaaS) — del.icio.us-style
  - **Hoarder / Karakeep** — AI-tagging bookmark tool
  - **Raindrop.io** — SaaS bookmarks
  - **Browser sync (Firefox / Chrome)** — commodity option
  - **Choose Shaarli if:** you want minimal + single-user + flat-file + RSS + long-history + tiny-footprint.
  - **Choose Linkding if:** you want modern UI + optional multi-user + still minimalist.
  - **Choose Wallabag if:** you want full-article-archival, not just URLs.

## Links

- Repo: <https://github.com/shaarli/Shaarli>
- Docs: <https://shaarli.readthedocs.io>
- Docker image (GHCR): <https://github.com/shaarli/Shaarli/pkgs/container/shaarli>
- Demo: <https://demo.shaarli.org>
- Gitter: <https://gitter.im/shaarli/Shaarli>
- Releases: <https://github.com/shaarli/Shaarli/releases>
- Linkding (alt): <https://github.com/sissbruecker/linkding>
- LinkAce (alt): <https://www.linkace.org>
- Wallabag (alt, read-it-later): <https://wallabag.org>
- Shiori (alt, Go): <https://github.com/go-shiori/shiori>
- Hoarder / Karakeep (alt, AI tagging): <https://github.com/hoarder-app/hoarder>
- Raindrop.io (commercial SaaS alt): <https://raindrop.io>
