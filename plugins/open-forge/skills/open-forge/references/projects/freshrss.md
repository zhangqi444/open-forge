---
name: FreshRSS
description: Lightweight self-hosted RSS/Atom aggregator. Multi-user with anonymous reading mode, WebSub push, XPath web scraping, OPML, API for mobile clients (Fever / Google Reader / Nextcloud News compatible), extensions. Runs on a Raspberry Pi. AGPL-3.0.
---

# FreshRSS

FreshRSS is the lightweight, sensible-default RSS aggregator: PHP + Apache, one container, tiny resource footprint, works on a Pi with 150 feeds + 22k articles. Feature-rich enough for power users (custom tags, queries saved as virtual feeds, XPath scraping for feed-less sites, WebSub push for real-time) but simple enough to "install and forget".

- Upstream repo: <https://github.com/FreshRSS/FreshRSS>
- Website: <https://freshrss.org>
- Docs: <https://freshrss.github.io/FreshRSS/>
- Docker docs: <https://github.com/FreshRSS/FreshRSS/blob/edge/Docker/README.md>
- Installation docs: <https://freshrss.github.io/FreshRSS/en/admins/03_Installation.html>

## Compatible install methods

| Infra        | Runtime                                               | Notes                                                                    |
| ------------ | ----------------------------------------------------- | ------------------------------------------------------------------------ |
| Single VM    | Docker (`freshrss/freshrss` or `ghcr.io/freshrss/freshrss`) | **Recommended.** Multi-arch: amd64, arm64, armv7                          |
| Raspberry Pi | Docker (armv7/arm64)                                  | Works on Pi 1 with 512 MB RAM                                             |
| Single VM    | Apache / nginx / lighttpd + PHP 8.1+                  | Classic PHP install — `git clone` into web root                          |
| YunoHost     | Package                                               | One-click                                                                 |
| Cloudron / PikaPods / Elestio / Hostinger | Managed one-click                        | SaaS with Docker under the hood                                          |
| Kubernetes   | Community manifests                                   | Stateless PHP + external DB (SQLite PVC or Postgres)                     |

## Inputs to collect

| Input                 | Example                                        | Phase     | Notes                                                                    |
| --------------------- | ---------------------------------------------- | --------- | ------------------------------------------------------------------------ |
| Public URL            | `https://rss.example.com`                      | Runtime   | Only the `/p/` path is exposed to the web; `/data/` must NOT be public  |
| DB backend            | SQLite (default) / PostgreSQL 10+ / MySQL 8 / MariaDB 10.6+ | DB | SQLite is perfect for single-user; Postgres for 2+ users + performance |
| Admin credentials     | created via wizard or `cli/do-install.php`     | Bootstrap | First user becomes the admin                                             |
| `TZ`                  | `Europe/Paris`                                 | Runtime   | Affects feed timestamps shown in UI                                      |
| `CRON_MIN`            | `3,33`                                         | Runtime   | Built-in cron to poll feeds — without it, feeds never refresh            |
| `TRUSTED_PROXY`       | `172.16.0.0/12 192.168.0.0/16`                 | Security  | For use behind reverse proxy; rejects spoofed `X-Forwarded-For` otherwise |
| Data volume           | `/var/www/FreshRSS/data`                       | Data      | DB + users + cache + logs + config                                       |
| Extensions volume     | `/var/www/FreshRSS/extensions`                 | Data      | Third-party extensions (optional)                                        |

## Install via Docker Compose (upstream default)

From <https://github.com/FreshRSS/FreshRSS/blob/edge/Docker/freshrss/docker-compose.yml>:

```yaml
volumes:
  data:
  extensions:

services:
  freshrss:
    image: freshrss/freshrss:latest    # or pin to 1.x / specific version
    container_name: freshrss
    hostname: freshrss
    restart: unless-stopped
    ports:
      - 8080:80
    logging:
      options:
        max-size: 10m
    volumes:
      - data:/var/www/FreshRSS/data
      - extensions:/var/www/FreshRSS/extensions
    environment:
      TZ: Europe/Paris
      CRON_MIN: '3,33'                              # poll at 3 + 33 past each hour
      TRUSTED_PROXY: 172.16.0.0/12 192.168.0.0/16   # only if behind reverse proxy
```

### Quick `docker run`

```sh
docker run -d --restart unless-stopped --log-opt max-size=10m \
  -p 8080:80 \
  -e TZ=Europe/Paris \
  -e 'CRON_MIN=1,31' \
  -v freshrss_data:/var/www/FreshRSS/data \
  -v freshrss_extensions:/var/www/FreshRSS/extensions \
  --name freshrss \
  freshrss/freshrss
```

### First-run install

Two options:

**Web wizard (GUI):**

1. Browse `http://<host>:8080`.
2. Language → Checks (all green) → DB config → Admin account → Done.

**CLI (automation-friendly):**

```sh
docker exec --user www-data freshrss cli/do-install.php \
  --default-user myadmin
docker exec --user www-data freshrss cli/create-user.php \
  --user myadmin --password 'strong-password-here'
```

(For Alpine-based images, use `--user apache` instead of `--user www-data`.)

## Image variants

From <https://github.com/FreshRSS/FreshRSS/blob/edge/Docker/README.md>:

- `:latest` — latest stable release (recommended for prod)
- `:edge` — rolling release, matches `edge` branch (unstable but current)
- `:1.X.Y` — specific version pin
- `:1` — latest within major 1.x
- `*-alpine` — smaller (Alpine), slightly slower in benchmarks
- Default (non-Alpine) is Debian-based

Example production pinning:

```yaml
image: freshrss/freshrss:1.27.1-alpine
```

## External database

Edit `data/config.php` (after first install) OR pre-configure via env before first boot:

For **PostgreSQL** (recommended multi-user):

```yaml
environment:
  FRESHRSS_DB_TYPE: pgsql
  FRESHRSS_DB_HOST: postgres
  FRESHRSS_DB_USER: freshrss
  FRESHRSS_DB_PASSWORD: REPLACE_ME
  FRESHRSS_DB_NAME: freshrss
```

(Plus a `postgres:17` service in the same compose.)

## Data & config layout

Inside `/var/www/FreshRSS/data`:

- `config.php` — global server config (base URL, DB, default language, auth type)
- `users/<user>/config.php` — per-user preferences
- `users/<user>/feeds.db` — per-user SQLite feed store (if SQLite)
- `users/<user>/log.txt` — per-user logs (polling errors, etc.)
- `users/_/` — shared/global logs
- `cache/` — feed body cache, article summaries
- `tokens/` — API tokens, session tokens

`extensions/` is a separate volume for third-party extensions.

**Critical path security:** `data/` contains **all personal data, including API tokens**. Never expose `/data/` to the web — reverse-proxy `/` → `/p/` only (the `Dockerfile` already sets DocumentRoot to `/p/`, but manual installs must do this).

## Backup

```sh
# Stop briefly for consistency (SQLite), then tar:
docker compose stop freshrss
docker run --rm -v freshrss_data:/src -v "$PWD":/backup alpine \
  tar czf /backup/freshrss-data-$(date +%F).tgz -C /src .
docker compose start freshrss

# Or, OPML export per user (feed list only, no read state):
docker exec --user www-data freshrss cli/export-opml-for-user.php \
  --user myadmin > myadmin-feeds-$(date +%F).opml
```

## Upgrade

1. Releases: <https://github.com/FreshRSS/FreshRSS/releases> (every 2–3 months).
2. Docker: `docker compose pull && docker compose up -d`. Migrations run on startup.
3. Bare-metal: `cli/update.php` OR git-pull + re-run install from web UI.
4. **Extensions may not be compatible with new majors** — check per-extension before upgrading.
5. Migration docs: <https://freshrss.github.io/FreshRSS/en/admins/04_Update.html>.

## Gotchas

- **Don't expose `/data/` to the web.** The Docker image handles this automatically (DocumentRoot = `/p/`). Manual Apache/nginx installs MUST block `/data` at the web-server level or your API tokens and user DBs are fetchable by URL.
- **`CRON_MIN` empty = no feed polling.** If you don't set it (or unset it), FreshRSS never auto-fetches feeds. Either set `CRON_MIN`, or run `cli/actualize_script.php` from an external cron.
- **`TRUSTED_PROXY` matters behind Caddy/Traefik/nginx.** Without it, FreshRSS may reject login attempts (thinking they come from the proxy IP, not the user) or log the wrong client IP.
- **SQLite is single-writer.** Multi-user setups with frequent polling can see DB-lock errors. Switch to PostgreSQL at the first sign of lock warnings in logs.
- **XPath scraping is brittle.** Sites redesign → your custom scraper breaks → silent feed-stops. Check the Errors log in admin regularly.
- **WebSub (push) requires public HTTPS.** Your FreshRSS must be reachable at a public URL over HTTPS for publishers to deliver pushes; without it, WebSub falls back to polling.
- **API endpoints for mobile clients:** Fever API (legacy), Google Reader API (standard), Nextcloud News API (for Nextcloud News apps). Enable per-user under Profile → Authentication. Many Android/iOS RSS apps use one of these.
- **AllowEncodedSlashes.** For Apache-based installs, enable `AllowEncodedSlashes` in vhost config for better compatibility with mobile clients. Docker image has this enabled; manual installs may not.
- **Extensions ecosystem is community-run.** <https://github.com/FreshRSS/Extensions>. Quality varies; stick to extensions with recent commits.
- **Anonymous reading mode** lets you expose a public "feed wall" — useful for shared team reading, but make sure you haven't accidentally marked private feeds as "Show in anonymous view".
- **Multi-user = multi-admin.** By default, any new user is a regular user; admins are promoted via the admin panel. Forgot your admin password? Only via `cli/update-user.php`.
- **Time zones matter for feed parsing.** Set `TZ` to match your server/users — otherwise "new articles" calculation uses UTC and feels off by your local offset.
- **Slim image variants exist** but are rarely worth it — the full image is already small (<200 MB).
- **AGPL-3.0, not GPL.** If you run a modified FreshRSS as a SaaS, you must make your modifications available to users.
- **Low resource usage is real.** Upstream benchmark: 150 feeds + 22k articles, sub-second response time on Pi 1. Modern hardware runs 1000+ feeds effortlessly.
- **SSL at the container?** FreshRSS doesn't terminate TLS — reverse proxy it.
- **Alternatives worth knowing:**
  - **Miniflux** — Go-based, ultra-minimalist, single binary
  - **Tiny Tiny RSS** — older PHP alternative, more features but stagnant
  - **Commafeed** — Java, feature-rich
  - **Stringer** — Ruby, minimal

## Links

- Repo: <https://github.com/FreshRSS/FreshRSS>
- Website: <https://freshrss.org>
- Demo: <https://demo.freshrss.org>
- Docs: <https://freshrss.github.io/FreshRSS/>
- Installation: <https://freshrss.github.io/FreshRSS/en/admins/03_Installation.html>
- Docker docs: <https://github.com/FreshRSS/FreshRSS/blob/edge/Docker/README.md>
- Configuration: <https://freshrss.github.io/FreshRSS/en/admins/05_Configuration.html>
- Update: <https://freshrss.github.io/FreshRSS/en/admins/04_Update.html>
- Extensions: <https://github.com/FreshRSS/Extensions>
- CLI: <https://github.com/FreshRSS/FreshRSS/blob/edge/cli/README.md>
- Releases: <https://github.com/FreshRSS/FreshRSS/releases>
- Docker Hub: <https://hub.docker.com/r/freshrss/freshrss>
