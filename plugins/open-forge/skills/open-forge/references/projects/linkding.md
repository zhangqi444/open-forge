---
name: linkding
description: Minimal, fast, self-hosted bookmark manager. Tags, bulk edit, Markdown notes, read-later, auto-archive (local HTML or Wayback Machine), SSO via OIDC or auth proxy, browser extensions for Firefox/Chrome. Django + SQLite. MIT.
---

# linkding

linkding (from the German *"Link-Ding"* = "link-thing") is a deliberately-simple, fast, self-hosted bookmark manager. Less feature-bloated than Wallabag, more functional than Shiori, and maintained with the explicit goal of "small, focused, easy to host."

Core features:

- **Clean UI** optimized for readability
- **Tags** (no folders — flat, searchable)
- **Bulk editing** + Markdown notes on each bookmark
- **Read-later** workflow (mark as unread → inbox)
- **Share** bookmarks with other users OR guest users (public shares)
- **Auto-fetch** title, description, favicon when you save a URL
- **Auto-archive** — either local HTML snapshot OR submit to Internet Archive (Wayback Machine)
- **Import/export** — Netscape HTML (Pocket, Firefox, Chrome bookmark exports all work)
- **PWA** — install on phone home screen
- **Browser extensions** — Firefox + Chrome + bookmarklet
- **SSO** — OIDC OR generic auth-proxy header-trust mode (Authelia, Authentik)
- **REST API** — for 3rd-party apps (many mobile clients)
- **Admin panel** (Django admin) — user self-service + raw data

- Upstream repo: <https://github.com/sissbruecker/linkding>
- Docs: <https://linkding.link>
- Installation: <https://linkding.link/installation>
- Demo: <https://demo.linkding.link>
- Docker Hub: <https://hub.docker.com/r/sissbruecker/linkding>

## Architecture in one minute

- **Django** (Python) app
- **SQLite** (default) OR **Postgres**
- **Port 9090** (internal default)
- **Archive feature** — on-demand triggers a `single-file-cli` invocation to snapshot pages locally
- Single container; no Redis or Celery needed (uses Django's lightweight background tasks)

## Compatible install methods

| Infra       | Runtime                                            | Notes                                                                |
| ----------- | -------------------------------------------------- | -------------------------------------------------------------------- |
| Single VM   | Docker (`sissbruecker/linkding`)                    | **Most common**                                                        |
| Single VM   | Docker Compose (+ Postgres optional)                  | For teams                                                               |
| Kubernetes  | Community Helm charts                                  | Stateless app + volume                                                   |
| Native      | Python venv + Django runserver / Gunicorn              | Development / bare-metal                                                   |
| Managed     | PikaPods, YunoHost, community-hosted                    | See <https://linkding.link/managed-hosting>                                    |

## Inputs to collect

| Input             | Example                                  | Phase     | Notes                                                            |
| ----------------- | ---------------------------------------- | --------- | ---------------------------------------------------------------- |
| `LD_SUPERUSER_NAME` + `LD_SUPERUSER_PASSWORD` | `admin` + strong          | Bootstrap | Creates first admin on first boot                                    |
| Port              | `9090`                                   | Network   | Internal container port                                              |
| Data volume       | `/etc/linkding/data`                      | Filesystem | SQLite + archive HTMLs                                                 |
| OIDC (optional)   | issuer + client + secret                   | Auth      | Env vars prefixed `LD_OIDC_*`                                           |
| Auth proxy (opt.) | `LD_ENABLE_AUTH_PROXY=True`                | Auth      | Trust headers from Authelia / Authentik / oauth2-proxy                  |
| Postgres (opt.)   | `LD_DB_*` env vars                          | DB        | SQLite default is fine for most                                            |
| CSRF trusted      | `LD_CSRF_TRUSTED_ORIGINS`                   | Reverse proxy | Must include your public URL                                                |

## Install via Docker (simplest)

```sh
docker run -d --name linkding \
  --restart unless-stopped \
  -p 9090:9090 \
  -v /opt/linkding/data:/etc/linkding/data \
  -e LD_SUPERUSER_NAME=admin \
  -e LD_SUPERUSER_PASSWORD=<strong> \
  sissbruecker/linkding:1.x.x    # pin; check Docker Hub
```

Browse `http://<host>:9090`. Log in with `admin` / `<strong>`.

## Install via Docker Compose

```yaml
services:
  linkding:
    image: sissbruecker/linkding:1.x.x
    container_name: linkding
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./data:/etc/linkding/data
    environment:
      LD_SUPERUSER_NAME: admin
      LD_SUPERUSER_PASSWORD: <strong>
      LD_CSRF_TRUSTED_ORIGINS: https://bookmarks.example.com
      # OIDC (optional)
      # LD_ENABLE_OIDC: "True"
      # OIDC_RP_SIGN_ALGO: RS256
      # OIDC_OP_ISSUER_ID: https://auth.example.com
      # OIDC_OP_AUTHORIZATION_ENDPOINT: https://auth.example.com/oauth/authorize
      # OIDC_OP_TOKEN_ENDPOINT: https://auth.example.com/oauth/token
      # OIDC_OP_USER_ENDPOINT: https://auth.example.com/oauth/userinfo
      # OIDC_OP_JWKS_ENDPOINT: https://auth.example.com/oauth/jwks
      # OIDC_RP_CLIENT_ID: linkding
      # OIDC_RP_CLIENT_SECRET: <secret>
      # Auth proxy mode (alternative to OIDC):
      # LD_ENABLE_AUTH_PROXY: "True"
      # LD_AUTH_PROXY_USERNAME_HEADER: HTTP_REMOTE_USER
      # LD_AUTH_PROXY_LOGOUT_URL: https://auth.example.com/logout
```

## First boot

1. Browse `https://bookmarks.example.com`
2. Log in with `LD_SUPERUSER_NAME` / `LD_SUPERUSER_PASSWORD`
3. Top-right → **Settings → Users** — invite others (admin can create)
4. Install browser extension:
   - Firefox: <https://addons.mozilla.org/firefox/addon/linkding-extension/>
   - Chrome: <https://chrome.google.com/webstore/detail/linkding-extension/beakmhbijpdhipnjhnclmhgjlddhidpe>
5. Configure extension → URL = your install, username/password or API token

## Archive options

In Settings → Options:

- **Enable snapshots** — saves HTML+resources to local disk (uses `single-file-cli` under the hood)
- **Enable Internet Archive** — submits URL to Wayback Machine on save

Snapshots live on disk at `/etc/linkding/data/assets/`. They consume space — a few hundred MB per 1000 archives.

## Data & config layout

Inside `/etc/linkding/data/`:

- `db.sqlite3` — DB (if not using Postgres)
- `assets/` — archived HTML snapshots + favicon cache
- `favicons/` — site favicons
- `backups/` — (if you enable auto-backup)

## Backup

```sh
# Full volume
docker run --rm -v "$(pwd)/data:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/linkding-$(date +%F).tgz -C /src .

# Or export bookmarks as Netscape HTML from the UI
# (Settings → General → Export bookmarks)
```

Export HTML is future-proof (importable into any browser or bookmark manager).

## Upgrade

1. Releases: <https://github.com/sissbruecker/linkding/releases>. Active.
2. `docker compose pull && docker compose up -d`.
3. Django migrations run automatically; back up `db.sqlite3` first.
4. 1.x → 2.x jumps have historically been smooth; read release notes for any env var renames.

## Gotchas

- **SQLite scales to tens of thousands of bookmarks** comfortably. >100k bookmarks or heavy archive use → consider Postgres.
- **`LD_CSRF_TRUSTED_ORIGINS`** MUST be set correctly when behind a reverse proxy — else Django rejects POST requests as CSRF.
- **`LD_SUPERUSER_PASSWORD` is used on every startup** — if the superuser already exists, it updates the password to match. So don't leave it in env if you've changed the password via UI, or it'll revert.
- **Archive feature uses `single-file-cli`** bundled in the image — it runs a headless Chromium to snapshot pages. Memory-hungry (~500 MB per snapshot at peak). Tune `LD_CSRF_TRUSTED_ORIGINS` + resource limits.
- **Per-user personal bookmarks + shared bookmarks** — linkding distinguishes "shared" (visible to other users or via public share link) vs "personal" (only you). Guest users (share-link-only viewers) are supported.
- **Admin panel at `/admin`** is Django's admin — raw DB access for superusers. Powerful + dangerous; normal users don't see it.
- **REST API** — generate an API token in Settings; use with browser extension, mobile apps, or custom scripts.
- **Community mobile apps** — search <https://linkding.link/community> for iOS/Android clients.
- **Tag naming**: tags can contain spaces but many users prefer hyphens for URL-friendliness. The search syntax uses `#tagname`.
- **Search**: full-text over title, description, notes, URL. Use `!inbox` for unread, `!unread`, `!untagged`, `!shared` as built-in filters.
- **Wayback Machine submission** is free but hit-rate-limited — don't submit thousands at once.
- **Backup ≠ export**: export HTML is bookmark data only (not notes, not archive snapshots). Full backup = volume tarball.
- **MIT license** — permissive.
- **linkding has one maintainer** (`sissbruecker`) who's deliberate about scope — PRs for big features often get politely declined to keep the project minimal. Feature velocity is moderate + focused.
- **Alternatives worth knowing:**
  - **Shiori** — Go, also minimal; very similar philosophy (separate recipe)
  - **Hoarder / Karakeep** — newer, Next.js, AI tagging, polished UX
  - **LinkWarden** — collections-first, modern, pretty
  - **Wallabag** — "read-later" focused, EPUB export, mobile apps (separate recipe)
  - **Readeck** — reader-first bookmark tool, Go
  - **Pinboard** — $11/year commercial SaaS
  - **Pocket** — discontinued 2024/2025
  - **Omnivore / Raindrop.io / Memos** — varying philosophies
  - **Choose linkding if:** you want minimal, fast, easy-to-host, with read-later + archive + SSO; you don't need AI features; you want a tool that won't bloat.

## Links

- Repo: <https://github.com/sissbruecker/linkding>
- Docs: <https://linkding.link>
- Installation: <https://linkding.link/installation>
- Managed hosting: <https://linkding.link/managed-hosting>
- Browser extension (Firefox): <https://addons.mozilla.org/firefox/addon/linkding-extension/>
- Browser extension (Chrome): <https://chrome.google.com/webstore/detail/linkding-extension/beakmhbijpdhipnjhnclmhgjlddhidpe>
- Community apps: <https://linkding.link/community>
- Demo: <https://demo.linkding.link>
- Docker Hub: <https://hub.docker.com/r/sissbruecker/linkding>
- Releases: <https://github.com/sissbruecker/linkding/releases>
- Configuration reference: <https://linkding.link/options>
- REST API: <https://linkding.link/api>
- Discussions: <https://github.com/sissbruecker/linkding/discussions>
