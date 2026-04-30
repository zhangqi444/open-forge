---
name: Pinry
description: "Self-hosted tiling image/video/webpage board — Pinterest-alike for hoarding visual references. Python/Django + Vue.js. Multi-user, public+private boards, tags, full API, CLI. BSD-2-Clause. Multi-arch Docker; 10+ year project; active."
---

# Pinry

Pinry is **"Pinterest, self-hosted + open-source + yours"** — a tiling image/video/webpage pinboard for saving, tagging, and sharing visual content in a masonry-grid skimmable format. Save links from any site (via browser extension or CLI), organize into boards (public or private), tag + search, share with friends. Like Pinterest but without the ads, the engagement-optimization, and the data harvesting. Multi-user supported; full REST API.

Built + maintained by **Pinry core team** (pinry org; @winkidney + contributors). **License: BSD-2-Clause**. Active (10+ years old); multi-arch Docker; i18n with EN/简体中文/French; CLI tool (`pinry-cli-py`) + browser extensions.

Use cases: (a) **personal visual scrapbook** — design references, mood boards, recipe photos (b) **designer/artist inspiration library** — tag-searchable visual refs (c) **travel planning** — save hotel/restaurant photos by destination (d) **engineering team reference board** — UI patterns, architecture diagrams, chart styles (e) **replacement for Pinterest** — escape commercial platform lock-in (f) **team knowledge curation** — visual wiki-like reference.

Features (from upstream README):

- **Image fetch + online preview** — paste URL, auto-fetch thumbnail + metadata
- **Tagging** system
- **Browser extensions** for one-click pinning
- **Multi-user**
- **Public + private boards**
- **Search by tag / board name**
- **Full REST API** via Django REST Framework
- **CLI support** — `pinry-cli-py` for command-line adds
- **i18n** — English, Simplified Chinese, French
- **Multi-arch Docker** — ARMv7 / ARMv8 / AMD64
- **Works well with Docker**

- Upstream repo: <https://github.com/pinry/pinry>
- Homepage / screenshots / docs: <https://pinry.github.io/pinry/>
- Install docs: <https://pinry.github.io/pinry/install-with-docker/>
- Development docs: <https://pinry.github.io/pinry/development/>
- Docker Hub: <https://hub.docker.com/r/getpinry/pinry>
- CLI tool: <https://github.com/pinry/pinry-cli-py>

## Architecture in one minute

- **Python / Django** backend
- **Vue.js** frontend
- **SQLite** (single-user default) or **MySQL/Postgres**
- **Redis** for caching (optional)
- **Resource**: moderate — 300-500MB RAM + storage scales with pin count + image sizes
- **Port**: 80/443 via webserver (+ Django port if direct)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`getpinry/pinry:latest`** (multi-arch)                        | **Upstream-primary**                                                               |
| Docker compose     | For separate DB + media volumes                                           | Production pattern                                                                                   |
| Bare-metal         | Python + Django + build Vue frontend                                                       | Development path                                                                                               |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `pins.example.com`                                          | URL          | TLS recommended                                                                                    |
| Secret key           | Django SECRET_KEY                                           | **CRITICAL** | **IMMUTABLE** — Django-standard                                                                                    |
| Admin creds          | `python manage.py createsuperuser`                          | Bootstrap    | Strong password                                                                                    |
| DB                   | SQLite / MySQL / Postgres                                                               | DB           | Multi-user → prefer Postgres                                                                                    |
| Media storage        | Persistent volume for pinned images                                                                                    | Storage      | **GROWS LARGE** — plan disk                                                                                                            |
| SMTP                 | For user password-reset / invites                                                                                                           | Email        | Useful for multi-user instance                                                                                                                            |

## Install via Docker (simple single-container)

```yaml
services:
  pinry:
    image: getpinry/pinry:4.x                # **pin to specific version**
    restart: unless-stopped
    environment:
      - PINRY_SECRET_KEY=${PINRY_SECRET_KEY}
      - PINRY_ALLOW_REGISTRATION=False       # lock down public registration
    volumes:
      - ./pinry-data:/data
    ports: ["8000:80"]
```

## First boot

1. Browse URL → click register (or admin-create-user path)
2. Create admin user via `docker exec -it pinry python manage.py createsuperuser`
3. Install browser extension → link to your instance
4. Start pinning
5. Organize into boards (public/private)
6. Put behind TLS reverse proxy
7. Back up DB + media

## Data & config layout

- DB — users, pins metadata, boards, tags
- `/data/images/` — stored pinned images (thumbnails + originals)
- `/data/static/` — static assets
- `.env` — SECRET_KEY + DB creds

## Backup

```sh
# SQLite:
sudo cp pinry-data/db.sqlite3 pinry-$(date +%F).db
# Postgres:
docker compose exec db pg_dump -U pinry pinry > pinry-$(date +%F).sql
sudo tar czf pinry-media-$(date +%F).tgz pinry-data/images/
```

## Upgrade

1. Releases: <https://github.com/pinry/pinry/releases>. Active.
2. Docker: pull + restart; Django migrations auto-run.
3. Back up BEFORE major upgrades.
4. Read release notes for breaking changes.

## Gotchas

- **PUBLIC REGISTRATION = ABUSE VECTOR IF EXPOSED**: `PINRY_ALLOW_REGISTRATION=False` by default (or set it). A public Pinry allowing signup → spammers pin affiliate links / NSFW / malware URLs → moderation nightmare + potential legal exposure. **Keep registration invite-only for multi-user deployments.**
- **IMAGE FETCH = SSRF RISK**: users paste URLs; Pinry fetches them server-side. Classic **SSRF vulnerability surface** — malicious user pastes `http://internal-service:8080/admin` → Pinry fetches internal endpoint → leaks response in pin preview. Mitigations:
  - **Network-level egress firewall** — block RFC1918 + localhost from Pinry's outbound
  - **URL validation** in Pinry upstream (verify presence)
  - **Same risk class as CommaFeed (batch 92) feed-subscription SSRF**
  - **2nd tool in SSRF-via-user-URL family** (after CommaFeed).
- **LEGAL: IMAGE COPYRIGHT**: Pinning an image fetches + stores a copy. Fair use / copyright varies by jurisdiction:
  - **US fair use**: personal reference use often OK; commercial / republication not
  - **EU**: more restrictive; InfoSoc Directive + copyright directives
  - **Content of pins** may include third-party copyrighted material → if publicly-exposed Pinry instance redistributes these, liability possible
  - **DMCA / EU-equivalent takedown compliance** — if running a public instance, have a takedown procedure + abuse contact
- **PUBLIC + PRIVATE BOARDS = ACCESS-CONTROL TESTING**: privacy-boundary bugs are common in content-pinning apps. Test:
  - Private board URL accessibility for non-owner → should 404/403
  - API endpoints for private-board pin retrieval → should check auth
  - Share-link features → scope expectations
  - **Treat as moderate-sensitivity** — private boards may contain personal content (boudoir, medical, financial).
- **HUB-OF-CREDENTIALS LIGHT**: stores user accounts + pin metadata. Not extreme but:
  - Users may pin URLs containing tokens (analytics, tracking, embedded secrets in URLs)
  - Browser extension may capture page content at pin-time
  - **37th tool in hub-of-credentials family — LIGHT tier.**
- **`SECRET_KEY` IMMUTABILITY** (Django-standard): **27th tool in immutability-of-secrets family.** Rotating invalidates sessions + some password-reset tokens.
- **MEDIA STORAGE GROWS UNBOUNDED**: each pin = image(s) stored. Implement:
  - Storage quotas per user
  - Image-size-cap on fetch (e.g., reject >10MB originals)
  - Periodic orphan-cleanup (pins deleted but images not)
  - Plan disk; S3-backend via Django storages for scale
- **BROWSER EXTENSION PERMISSIONS**: the Pinry browser extension reads current page URL + may capture page-preview. Relatively light permissions; verify the specific extension's manifest before installing. Compromised extensions = browser-level attack.
- **PYTHON/DJANGO SECURITY HYGIENE**: Django is very mature but runs in your infra → keep Django up to date (SECURITY patches), monitor CVEs, run `pip audit`, use Django's CSRF/CSP middleware.
- **10+ YEAR AGE**: long-lived project + positive signal. Community contributors + multi-arch + i18n suggest sustained stewardship. Similar "age-as-maturity" framing as ddclient (batch 93) + TVHeadend (batch 94).
- **BSD-2-CLAUSE LICENSE**: minimal copyleft obligations; very permissive; commercial-reuse-friendly.
- **MULTI-LANGUAGE / i18n**: English + Simplified Chinese + French is small but real. Lower than LimeSurvey/Moodle 50+-language ecosystems but sign of international care.
- **CLI TOOL = AUTOMATION FRIENDLY**: pinry-cli-py enables scripting (bulk-import from existing Pinterest export, cron jobs, integrations). Nice developer-friendly signal.
- **TRANSPARENT-MAINTENANCE**: BSD + active + Docker multi-arch + CI badges + i18n + CLI. **19th tool in transparent-maintenance family.**
- **COMMERCIAL-TIER**: no paid services; BSD + community. **11th tool in pure-community category.**
- **ALTERNATIVES WORTH KNOWING:**
  - **Hoarder / Karakeep** — modern self-hosted bookmark + content saver; active
  - **Linkwarden** — bookmark + link archive; Next.js; active (batch 94+ pending)
  - **Shiori** — self-hosted bookmark; Go; minimal
  - **Wallabag** — read-it-later + bookmarks; PHP; mature
  - **LinkAce** — bookmark manager (batch 94 pending)
  - **Are.na** — commercial SaaS; beautiful reference-library UX
  - **Pinterest** — commercial SaaS; content-quality + network-effects; ad-heavy
  - **Raindrop.io** — commercial SaaS freemium bookmarks
  - **Choose Pinry if:** you want image-focused + tiling-grid + multi-user + BSD + 10+years-mature.
  - **Choose Hoarder/Karakeep or Linkwarden if:** modern + bookmarks + broader-content-type (not image-focused).
  - **Choose Are.na if:** you accept commercial + want polished reference-library UX.

## Links

- Repo: <https://github.com/pinry/pinry>
- Homepage + screenshots: <https://pinry.github.io/pinry/>
- Docker: <https://hub.docker.com/r/getpinry/pinry>
- CLI: <https://github.com/pinry/pinry-cli-py>
- Hoarder/Karakeep (alt): <https://github.com/karakeep-app/karakeep>
- Linkwarden (alt): <https://linkwarden.app>
- Shiori (alt): <https://github.com/go-shiori/shiori>
- Wallabag (alt): <https://wallabag.org>
- Are.na (commercial alt): <https://www.are.na>
