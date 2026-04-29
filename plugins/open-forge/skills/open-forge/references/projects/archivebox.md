---
name: archivebox-project
description: ArchiveBox recipe for open-forge. MIT-licensed self-hosted web archiving tool — give it URLs (bookmarks, browser history, RSS feeds, domains), it produces a browsable local archive with: original HTML, rendered PDF + screenshot + full-page DOM via headless Chromium, YouTube-DL media, WARC for replay, plaintext + ARTICLE content, favicons, metadata. Written in Python/Django. Built-in Sonic full-text search (in same container since recent versions). Orchestrator runs scheduled crawls. Covers the official docker-compose.yml w/ env var reference (ALLOWED_HOSTS, PUBLIC_INDEX, SEARCH_BACKEND_ENGINE=sonic, CSRF_TRUSTED_ORIGINS, ADMIN_USERNAME/PASSWORD), the `init --install` workflow, noVNC for watching the browser scrape, and the optional Pi-hole/WireGuard/ChangeDetection/PYWB overlays.
---

# ArchiveBox

MIT-licensed self-hosted web archiving tool. Upstream: <https://github.com/ArchiveBox/ArchiveBox>. Docs: <https://docs.archivebox.io>. Website: <https://archivebox.io>. Wiki: <https://github.com/ArchiveBox/ArchiveBox/wiki>.

Give it URLs — bookmarks, browser history, RSS feeds, Pocket exports, entire domains — and ArchiveBox produces a browsable, searchable, permanent local copy. Outputs per snapshot:

- **Original HTML** (`index.html`)
- **Rendered PDF** (headless Chromium)
- **Full-page screenshot** (headless Chromium)
- **Full DOM + assets** (headless Chromium — CSS, JS, images, fonts)
- **WARC** (Web ARChive format — replayable via pywb / Wayback)
- **Media via yt-dlp** (YouTube + 1000+ sites)
- **Plaintext extract + readable ARTICLE** (via Readability)
- **Favicons, metadata, git repos (if a GitHub URL)**
- **Title, timestamp, original URL — all queryable**

Designed for personal/institutional archiving of your own bookmarks, research, RSS, etc. Not a general-purpose scraper (respects robots.txt by default).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/ArchiveBox/ArchiveBox/wiki/Docker#docker-compose> | ✅ Recommended | Most deployments. |
| Docker run | <https://github.com/ArchiveBox/ArchiveBox/wiki/Docker> | ✅ | Single-container. |
| `pip install archivebox` + CLI | <https://docs.archivebox.io/en/latest/Install.html> | ✅ | Bare-metal Python users. |
| `apt` / Homebrew / pkg | <https://github.com/ArchiveBox/ArchiveBox/wiki/Install> | ✅ (various) | Platform-native. |
| NixOS module | community | ⚠️ | NixOS users. |

Image: `archivebox/archivebox:latest` (Docker Hub). For production pin a specific version.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | `AskUserQuestion`: `docker-compose` / `docker-run` / `pip` | Drives section. |
| ports | "HTTP port?" | Default `8000` | Internal; map/proxy as needed. |
| storage | "Data dir?" | Default `./data` | Bind-mount from host. Grows indefinitely — plan for big disk. |
| hostname | "Public hostname(s)?" | e.g. `archive.example.com` (space-separated) | Becomes `ALLOWED_HOSTS`. MUST be set for non-localhost access. |
| hostname | "CSRF trusted origins?" | e.g. `https://archive.example.com` | `CSRF_TRUSTED_ORIGINS` — required for admin login over HTTPS. |
| admin | "Create admin user?" | `AskUserQuestion`: `via-env (ADMIN_USERNAME/PASSWORD on first run)` / `manually-via-cli` | Both work; env is easier. |
| privacy | "Public access mode?" | `AskUserQuestion`: `private-snapshots-list` / `public-snapshots-list` / `public-add-view-too` | Sets `PUBLIC_INDEX`, `PUBLIC_SNAPSHOTS`, `PUBLIC_ADD_VIEW`. |
| search | "Full-text search?" | `AskUserQuestion`: `sonic-builtin (recommended)` / `none` / `ripgrep` | `SEARCH_BACKEND_ENGINE=sonic` uses the in-container Sonic. |
| secrets | "Sonic password?" | Random string | `SEARCH_BACKEND_PASSWORD`. |
| permissions | "Host UID/GID if permission issues?" | Default container UID 911 | Set `PUID` / `PGID` if your host user is different. |
| tls | "Reverse proxy?" | `AskUserQuestion`: `caddy` / `traefik` / `nginx-builtin-example` / `none` | ArchiveBox speaks HTTP; needs external TLS for non-localhost. |

## Install — Docker Compose

Canonical flow per upstream (<https://github.com/ArchiveBox/ArchiveBox/wiki/Docker#docker-compose>):

```bash
mkdir -p ~/archivebox/data && cd ~/archivebox
curl -fsSL 'https://docker-compose.archivebox.io' > docker-compose.yml

# Initialize the data dir + install headless Chromium + yt-dlp + dependencies
docker compose run archivebox init --install

# Add some URLs
docker compose run archivebox add --depth=1 'https://news.ycombinator.com'

# Or import from a bookmark file
docker compose run -T archivebox add < bookmarks.txt

# Start the web UI
docker compose up -d

# Open http://archivebox.localhost:8000/
```

Minimal compose (from upstream `docker-compose.yml`):

```yaml
services:
  archivebox:
    image: archivebox/archivebox:latest         # pin in prod
    ports:
      - 8000:8000
    volumes:
      - ./data:/data
    environment:
      - ADMIN_USERNAME=admin                     # creates admin on first run
      - ADMIN_PASSWORD=<random>                  # CHANGE THIS
      - LISTEN_HOST=archive.example.com:8000
      - ALLOWED_HOSTS=*                          # set to your hostnames
      - CSRF_TRUSTED_ORIGINS=https://archive.example.com  # MUST match admin UI URL
      - PUBLIC_INDEX=True
      - PUBLIC_SNAPSHOTS=True
      - PUBLIC_ADD_VIEW=False
      - SEARCH_BACKEND_ENGINE=sonic
      - SEARCH_BACKEND_PASSWORD=<random>
      # - PUID=911
      # - PGID=911
    restart: unless-stopped
```

## Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `ADMIN_USERNAME` | — | Creates admin on first run |
| `ADMIN_PASSWORD` | — | Admin password (first run only) |
| `ALLOWED_HOSTS` | `*` | Django allowed hosts — set to your public hostnames |
| `CSRF_TRUSTED_ORIGINS` | — | MUST match admin URL for login to work over HTTPS |
| `LISTEN_HOST` | `:8000` | Listen address |
| `PUBLIC_INDEX` | `True` | Anonymous can see snapshot list |
| `PUBLIC_SNAPSHOTS` | `True` | Anonymous can view snapshot content |
| `PUBLIC_ADD_VIEW` | `False` | Anonymous can submit URLs |
| `SEARCH_BACKEND_ENGINE` | `ripgrep` | `sonic` / `ripgrep` / `''` (disabled) |
| `SEARCH_BACKEND_PASSWORD` | — | Sonic auth (required if sonic) |
| `TIMEOUT` | `60` | Per-URL archive timeout (seconds) |
| `CHECK_SSL_VALIDITY` | `True` | Set `False` to archive URLs with bad certs |
| `USER_AGENT` | — | Custom UA (avoid bot blocks) |
| `PUID` / `PGID` | `911` | Host UID/GID match for bind-mount permissions |

Full reference: <https://github.com/ArchiveBox/ArchiveBox/wiki/Configuration>.

## First archiving session

After `docker compose up -d`:

1. Open <http://archivebox.localhost:8000/> → log in as `admin` / your password.
2. **Add** page → paste URLs, one per line. Choose extractors (HTML/PDF/screenshot/DOM/media/WARC).
3. Click Archive → watch the progress in the UI.
4. Once done, click a snapshot → browse the archived version, download artifacts, read plaintext.

Archive a whole RSS feed periodically:

```bash
docker compose run archivebox schedule \
  --add --every=day --depth=1 \
  'https://example.com/feed.xml'
```

The orchestrator (running inside the main container since recent versions) picks up scheduled jobs automatically. Used to be a separate scheduler sidecar — no longer needed.

## Optional addons (from upstream compose)

### noVNC — watch the archiving browser in real time

Useful for setting up a Chromium profile with logins (so ArchiveBox can archive authenticated pages).

```yaml
novnc:
  image: theasp/novnc:latest
  environment:
    - DISPLAY_WIDTH=1920
    - DISPLAY_HEIGHT=1080
  ports:
    - 127.0.0.1:8080:8080         # localhost-only; no auth!
```

Open <http://127.0.0.1:8080/vnc.html>.

### Pi-hole — block ads/trackers during archiving

Saves disk space by not downloading ads. See upstream compose — uncomment the `pihole` service + `dns` network.

### WireGuard — route archiving through VPN

To avoid IP blocks. `network_mode: 'service:archivebox'` shares the network namespace.

### ChangeDetection.io — watch for changes + archive

Pairs nicely — ChangeDetection monitors, calls ArchiveBox webhook to archive on change.

### PYWB — replay WARC archives

`webrecorder/pywb` — browse WARCs in a Wayback-like UI. Auto-imports ArchiveBox WARCs.

## Data layout

```
./data/
├── ArchiveBox.conf          # main config (can override env vars)
├── index.sqlite3            # Django DB — snapshots, users, tags
├── archive/
│   └── 1234567890.123/      # one folder per snapshot, timestamped
│       ├── index.html       # original HTML
│       ├── output.pdf       # Chromium-rendered PDF
│       ├── screenshot.png   # Chromium full-page screenshot
│       ├── output.html      # fully-rendered DOM
│       ├── warc/            # WARC replayable archive
│       ├── media/           # yt-dlp output
│       ├── favicon.ico
│       ├── title.txt
│       └── index.json       # machine-readable snapshot metadata
├── personas/
│   └── Default/chrome_profile/   # Chromium profile (cookies, logins)
├── logs/
├── sonic/                   # Sonic full-text search index
└── sources/                 # imported bookmark files
```

**Backup priority:**

1. **`./data/index.sqlite3`** — snapshot metadata. Without it, archive folders are orphaned.
2. **`./data/archive/`** — the actual content. Can get huge (GB per hundred snapshots).
3. **`./data/sonic/`** — search index. Rebuildable via `archivebox update --index-only`.
4. **`./data/ArchiveBox.conf`** — config.

Use `docker compose run archivebox manage dumpdata` for a portable JSON export.

## Upgrade procedure

```bash
docker compose pull
docker compose run archivebox init --install     # re-runs migrations + updates extractors
docker compose up -d
docker compose logs -f archivebox
```

Always run `init --install` after a pull — it migrates the DB and updates headless-Chromium/yt-dlp versions.

Release notes: <https://github.com/ArchiveBox/ArchiveBox/releases>.

## Gotchas

- **`ALLOWED_HOSTS=*`** in the default compose is Django's "allow all" — unsafe for production. Set to your actual hostnames: `ALLOWED_HOSTS=archive.example.com,archive.internal`.
- **`CSRF_TRUSTED_ORIGINS` is mandatory for HTTPS admin login.** Without it, you get CSRF errors logging in. Must include the full scheme: `https://archive.example.com` (NOT just the hostname).
- **First-run `init --install` downloads ~1 GB of extractors** (Chromium, yt-dlp binary, Node deps). Takes a few minutes. Re-runs are fast.
- **Archive directory grows indefinitely.** A single snapshot can be 10-100 MB (screenshot + PDF + WARC + media). 10K snapshots = 100-1000 GB. Plan disk accordingly.
- **yt-dlp media archives are the biggest disk hogs.** Disable via `SAVE_MEDIA=False` if you don't need it.
- **Permission issues on bind-mounts** are common. Set `PUID` / `PGID` to match your host user's UID/GID, or `chown -R 911:911 ./data` after first init.
- **`docker compose run archivebox ...` creates a new container each time** — noisy in `docker ps -a`. Prune periodically: `docker container prune`.
- **Admin UI login requires a user.** If you don't set `ADMIN_USERNAME/PASSWORD` env vars, create via:
  ```bash
  docker compose run archivebox manage createsuperuser
  ```
- **Scheduler runs inside the main container** now (not a separate service). Don't add a sidecar scheduler from old docs.
- **Sonic full-text search** — if stopped/crashed, reindex with `docker compose run archivebox update --index-only`.
- **`PUBLIC_INDEX=True + PUBLIC_SNAPSHOTS=True` exposes your archive to anyone** who knows the URL. Default for convenience; flip to `False` for private.
- **`PUBLIC_ADD_VIEW=True` lets anyone submit URLs** to be archived — fine for a personal bookmark dropbox; spam risk if exposed wide.
- **Chromium user profile** lives in `./data/personas/Default/chrome_profile/`. Log into sites there (via noVNC) to archive authenticated content.
- **Chromium needs ~1 GB RAM to render pages.** On a 2-GB VPS, OOM kills are possible under heavy archiving. Tune via Chromium flags or limit concurrency.
- **`TIMEOUT=60`** is often too short for complex pages. Bump to `120` or `300` if you see timeouts in logs.
- **WARC files are big** (~1-5 MB per page). Great for Wayback-style replay (pywb); bad for disk if you archive thousands of pages. Disable via `SAVE_WARC=False`.
- **Import sources** live in `./data/sources/` — drop bookmark.html / Pocket CSV / RSS OPML files there, re-run `add`.
- **`robots.txt` is respected** by default. Sites that block archivers (e.g. many news sites) won't archive fully. Override: `CHECK_SSL_VALIDITY=False` + custom `USER_AGENT` + `--overwrite` flag.
- **Can't archive sites behind paywalls/login** unless you pre-log-in via the Chromium profile (noVNC).
- **Django admin is at `/admin/`** — useful for bulk edits, tag management.
- **REST API** exists (Django REST Framework). Good for scripting bulk adds from scripts.
- **Upgrading major versions** (v0.7 → v0.8) requires reading release notes; some migrations are non-trivial. Back up `index.sqlite3` first.
- **Docker image is ~3 GB.** Not lightweight — bundles Chromium, Node, Python, many tools.

## Links

- Upstream repo: <https://github.com/ArchiveBox/ArchiveBox>
- Docs: <https://docs.archivebox.io>
- Wiki (lots of depth): <https://github.com/ArchiveBox/ArchiveBox/wiki>
- Docker wiki: <https://github.com/ArchiveBox/ArchiveBox/wiki/Docker>
- Configuration reference: <https://github.com/ArchiveBox/ArchiveBox/wiki/Configuration>
- Install options: <https://github.com/ArchiveBox/ArchiveBox/wiki/Install>
- Scheduled archiving: <https://github.com/ArchiveBox/ArchiveBox/wiki/Scheduled-Archiving>
- Chromium setup (auth profiles): <https://github.com/ArchiveBox/ArchiveBox/wiki/Chromium-Install>
- Storage setup (S3/B2/GDrive/etc.): <https://github.com/ArchiveBox/ArchiveBox/wiki/Setting-Up-Storage>
- Search backend setup: <https://github.com/ArchiveBox/ArchiveBox/wiki/Setting-up-Search>
- Demo: <https://demo.archivebox.io>
- Releases: <https://github.com/ArchiveBox/ArchiveBox/releases>
- Docker Hub: <https://hub.docker.com/r/archivebox/archivebox>
- Community forum: <https://zulip.archivebox.io>
