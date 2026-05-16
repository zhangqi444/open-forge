---
name: Zipline
description: "Next-generation ShareX/file upload server. Self-hosted image + file host with folders, tags, URL shortening, embeds, OAuth2, 2FA, passkeys, quotas, custom themes. TypeScript/Next.js. License: MIT (verify). Active; Discord."
---

# Zipline

Zipline is **"your own Imgur + url.me + file.io — self-hosted"** — a full-featured file-upload server designed as a ShareX endpoint + standalone web UI. Upload any file (images, videos, PDFs, arbitrary binaries), get a short URL back, embed with rich previews on Discord/Twitter/Facebook, organize with folders + tags, shorten URLs, receive Discord/HTTP webhooks, protect uploads with passwords or quotas. TypeScript / Next.js. Modern + polished.

Built + maintained by **diced** + community. License: MIT (verify `LICENSE` per prior precedent MediaManager 97). Active + Discord + polished documentation at zipline.diced.sh.

Use cases: (a) **personal image host** — replace Imgur for screenshots + memes (b) **ShareX endpoint** — Windows ShareX uploader points at your Zipline (iOS Shortcuts / Flameshot Linux equivalents) (c) **Discord rich-embed media** — drop file in Discord → pretty preview (d) **team file share** with users + invites + quotas (e) **URL shortening** — dual-purpose tool (Slash 97 precedent) (f) **PWA upload from mobile** (g) **2FA + Passkey + OAuth authentication** — enterprise-friendly auth (h) **custom themes** — match your brand (i) **invite-only community file host** — private file sharing.

Features (from upstream README):

- **Upload any file**
- **Folders + Tags**
- **URL shortening**
- **Rich embeds** (OpenGraph + oEmbed + Discord-pretty)
- **Discord + HTTP webhooks**
- **OAuth2 / 2FA / Passkeys** — modern auth
- **Password protection on uploads**
- **Image compression**
- **Video thumbnails**
- **REST API**
- **PWA**
- **Partial uploads** (resumable)
- **Invites** + **quotas**
- **Custom themes**

- Upstream repo: <https://github.com/diced/zipline>
- Docs: <https://zipline.diced.sh>
- Docker getting-started: <https://zipline.diced.sh/docs/get-started/docker>
- Discord: <https://discord.gg/EAhCRfGxCF>
- Docker Hub: <https://hub.docker.com/r/diced/zipline>
- ShareX (Windows tool): <https://getsharex.com>

## Architecture in one minute

- **Next.js** / TypeScript backend + frontend
- **PostgreSQL** — DB
- **Resource**: moderate — 300-600MB RAM; disk for uploads (UNBOUNDED)
- **Port 3000** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker compose** | **Upstream-provided; Zipline + Postgres**                       | **Primary**                                                                        |
| Bare-metal         | Node.js + Postgres                                                        | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `up.example.com` (short)                                    | URL          | TLS MANDATORY                                                                                    |
| DB                   | PostgreSQL                                                  | DB           | Zipline's only supported DB                                                                                    |
| `CORE_SECRET`        | JWT signing                                                                                    | **CRITICAL** | **IMMUTABLE**                                                                                    |
| Upload dir           | `./uploads/`                                                                                 | Storage      | GROWS UNBOUNDED                                                                                    |
| Max file size / quota per user | Enforce limits                                                                                       | Config       | Prevent abuse                                                                                                            |
| OAuth providers      | (optional) GitHub / Google / etc.                                                                                                            | SSO          | For enterprise/family                                                                                                                            |

## Install via Docker (upstream-recommended)

```yaml
services:
  zipline:
    image: ghcr.io/diced/zipline:v4.6.0    # **pin version**
    restart: unless-stopped
    environment:
      - CORE_RETURN_HTTPS=true
      - CORE_HOST=0.0.0.0
      - CORE_PORT=3000
      - CORE_SECRET=${CORE_SECRET}         # openssl rand -hex 32
      - CORE_DATABASE_URL=postgres://postgres:${DB_PASSWORD}@postgres:5432/postgres
    ports: ["3000:3000"]
    volumes:
      - ./zipline-uploads:/zipline/uploads
      - ./zipline-public:/zipline/public
    depends_on: [postgres]

  postgres:
    image: postgres:17
    environment:
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    volumes:
      - ./zipline-db:/var/lib/postgresql/data
```

## First boot

1. Start → browse `http://host:3000`
2. Register admin
3. Generate ShareX config (inside Zipline → generate `.sxcu` file)
4. Install ShareX on Windows / upload tools on macOS+Linux
5. Import `.sxcu` → upload test file → verify URL returned + file accessible
6. Configure OAuth / 2FA
7. Set per-user quotas
8. Put behind TLS reverse proxy
9. Plan for disk-growth + backups

## Data & config layout

- `uploads/` — all uploaded files (UNBOUNDED)
- `public/` — branding + custom themes
- Postgres — user accounts, upload metadata, shorteners
- `.env` / compose environment — CORE_SECRET + DB

## Backup

```sh
docker compose exec postgres pg_dump -U postgres > zipline-$(date +%F).sql
sudo tar czf zipline-uploads-$(date +%F).tgz zipline-uploads/     # ONLY IF NEEDED
```

## Upgrade

1. Releases: <https://github.com/diced/zipline/releases>. Active + semver.
2. Docker: pull + migrate.
3. v3 → v4 was a major upgrade with schema changes; read release notes for breaking changes + migration path.
4. Back up DB BEFORE major upgrades.

## Gotchas

- **PUBLIC-SIGNUP + FILE-HOST = PHISHING / MALWARE / CSAM RISK**:
  - **Biggest operational concern for file-hosts**: abusers upload malware, phishing pages (HTML), CSAM, copyrighted content
  - Your domain = the URL abusers share → your domain gets blocklisted by Gmail + Safe-Browsing (Slash 97 precedent)
  - **Hosting provider's ToS violation** → server cancelled
  - **LEGAL EXPOSURE**: **CSAM hosting = criminal regardless of your intent**; immediate FBI / NCMEC involvement if discovered
  - **22nd tool in network-service-legal-risk family** — **NEW: "public-file-upload-host-illegal-content-conduit sub-family" — 12th sub-family** joining Slash's URL-shortener-phishing-vector (Slash 97). Distinct: file-host hosts actual content; URL-shortener hosts redirects. Both face similar reputation + legal risks but different technical attack surface.
  - **Mitigation for file-hosts**:
    - **DEFAULT TO INVITE-ONLY** — Zipline supports invites; use them
    - Disable public signup
    - **Scan uploads with ClamAV / VirusTotal integration** (add; don't expect built-in)
    - **Limit file types** (no .html, .js, .exe unless justified)
    - **Rate-limit uploads per IP**
    - **Monitor disk usage + abuse reports**
    - **Abuse contact** on domain + prompt response
    - **Integrate with PhotoDNA / abuse APIs for content scanning** (advanced)
- **RECIPE CONVENTION: "public-file-host-operator-responsibility" callout** for file-host tools (Zipline, Chevereto, Lychee, Shlink-with-uploads, etc.): operators must implement anti-abuse from day one or face blocklisting + legal exposure.
- **HUB-OF-CREDENTIALS TIER 2**:
  - Users + their uploads (potentially private / sensitive photos/files)
  - API tokens (ShareX auth)
  - OAuth credentials
  - 2FA secrets
  - Passkeys
  - Invite codes
  - Discord/HTTP webhook URLs
  - **47th tool in hub-of-credentials family — Tier 2.**
- **`CORE_SECRET` IMMUTABILITY**: **35th tool in immutability-of-secrets family.**
- **DISK GROWTH UNBOUNDED**: set per-user quotas + retention policies. Monitor disk free space. Orphaned-file cleanup if Zipline doesn't garbage-collect deleted users' uploads (verify).
- **SCREENSHOT TOOLS + ZIPLINE INTEGRATION** worth recipe-noting:
  - **Windows**: ShareX (canonical)
  - **macOS**: ShareX-macOS-equivalents, built-in screenshot → Shortcuts + HTTP
  - **Linux**: Flameshot + custom script; GNOME screenshot + scripts
  - **iOS**: Shortcuts app → HTTP upload to Zipline
  - **Android**: HTTPShortcuts app or similar
- **DISCORD RICH EMBEDS = REASON-FOR-BEING for many Zipline users**: Zipline's OpenGraph/oEmbed metadata makes Discord previews pretty. Content-Type + oEmbed tuning matter for correct previews.
- **OAUTH2 + PASSKEY + 2FA = ENTERPRISE-READY AUTH**: rare in self-hosted image-hosts. Positive differentiator.
- **TRANSPARENT-MAINTENANCE**: active + docs + Discord + Docker Hub metrics + semver + release notes. **39th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: diced + community. **32nd tool in institutional-stewardship — sole-maintainer-with-community.** **19th tool in sole-maintainer-with-community class.**
- **LICENSE CHECK NEEDED**: README doesn't explicitly state license (MediaManager 97 precedent). Verify LICENSE file before commercial use.
- **REGIONAL CONTENT LAWS** (Germany NetzDG, EU DSA): if Zipline instance serves public uploads + you're in EU, DSA compliance may apply depending on size + hosting model. Get legal counsel for public commercial instances.
- **VIDEO-THUMBNAIL GENERATION = FFMPEG**: Zipline uses ffmpeg-kit or similar for video thumbnails. ffmpeg-shell-exec-gateway family concern applies LIGHTLY — if arbitrary video input → malformed video could trigger ffmpeg bugs. Keep ffmpeg updated.
- **PARTIAL UPLOADS (RESUMABLE)** = nice feature for large files + unreliable networks. Reinforces Zipline's production-readiness.
- **ALTERNATIVES WORTH KNOWING:**
  - **Chevereto** — PHP image-host; more-photography-focused; freemium
  - **Lychee** — PHP photo-gallery; photography-first
  - **Pictshare** — PHP; simpler
  - **Shlink** (batch-future; related to Slash 97 URL-shortener)
  - **Imagor / Thumbor** — image-transformation (different niche)
  - **Minio + custom frontend** — self-host S3 with DIY UI
  - **Imgur / Catbox / file.io** — commercial SaaS
  - **ShareX upload endpoints you can DIY** (custom server)
  - **Chibisafe** — another modern self-host image-host
  - **Choose Zipline if:** you want MODERN stack + Next.js + polished auth + ShareX integration + rich-embeds.
  - **Choose Chevereto if:** you want PHP + photography-focus.
  - **Choose Lychee if:** you want photo-gallery-first.
  - **Choose Chibisafe if:** you want alternative-modern-option.
- **PROJECT HEALTH**: active + polished + documented + Discord + semver. Strong for a maintainer-driven image-host.

## Links

- Repo: <https://github.com/diced/zipline>
- Docs: <https://zipline.diced.sh>
- Docker getting started: <https://zipline.diced.sh/docs/get-started/docker>
- Docker Hub: <https://hub.docker.com/r/diced/zipline>
- Discord: <https://discord.gg/EAhCRfGxCF>
- ShareX: <https://getsharex.com>
- Chevereto (alt): <https://chevereto.com>
- Lychee (alt): <https://lycheeorg.github.io>
- Chibisafe (alt): <https://chibisafe.app>
- Flameshot (Linux screenshot): <https://flameshot.org>
