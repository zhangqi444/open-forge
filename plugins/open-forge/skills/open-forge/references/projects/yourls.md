---
name: YOURLS
description: "Your Own URL Shortener" — mature PHP-based private/public link shortener. Admin UI, custom keywords, click tracking, geo stats, plugins (social APIs, anti-spam, auth), full REST API, bookmarklet. PHP + MySQL/MariaDB. MIT.
---

# YOURLS

YOURLS (Your Own URL Shortener) is one of the oldest + most battle-tested self-hosted link shorteners (first release 2009). Written in PHP, backed by MySQL/MariaDB, works on any shared-hosting setup that runs WordPress (literally — same LAMP stack).

- **Public or private** — bitly-style public OR gated to authenticated users
- **Custom keywords** — pick your own `/catchy-name` short code
- **Click statistics** — daily/weekly/monthly, geo (country-level), referrer, user agent
- **Plugins** — extensive API; 100+ community plugins (Cloudflare Turnstile CAPTCHA, 2FA, Social auto-post, QR codes, custom themes)
- **REST API** — programmatic shortening from scripts + apps
- **Bookmarklet** — shorten the current tab URL in one click
- **WordPress/Drupal integration** — via plugins

- Upstream repo: <https://github.com/YOURLS/YOURLS>
- Website: <https://yourls.org>
- Docs: <https://docs.yourls.org>
- Plugin directory: <https://github.com/YOURLS/awesome-yourls>
- Blog: <https://blog.yourls.org>

## Architecture in one minute

- **PHP web app** (Composer-managed) served by Apache / nginx / Caddy + PHP-FPM
- **MySQL / MariaDB** — stores URLs, clicks, options, plugin data
- **Plugins** drop into `user/plugins/` as folders; enabled via admin UI
- No queue, no worker — everything happens in-request

## Compatible install methods

| Infra         | Runtime                                                | Notes                                                                     |
| ------------- | ------------------------------------------------------ | ------------------------------------------------------------------------- |
| Single VM     | Docker (`yourls:apache` official image)                | **Recommended**                                                            |
| Shared hosting | cPanel upload + MySQL via Softaculous                 | Works — YOURLS predates Docker                                             |
| Single VM     | LAMP stack (Apache + PHP 7.4+/8+ + MariaDB)            | Classic install                                                            |
| Kubernetes    | Community charts                                        | Not upstream-maintained                                                    |

## Inputs to collect

| Input                      | Example                          | Phase     | Notes                                                      |
| -------------------------- | -------------------------------- | --------- | ---------------------------------------------------------- |
| Public URL                 | `https://yr.example.com`         | DNS       | Short domain → shorter links                                |
| `YOURLS_SITE`              | same as public URL               | Runtime   | Permanent — baked into generated short URLs                 |
| `YOURLS_DB_*`              | user/pw/host/name                 | DB        | `YOURLS_DB_USER`/`PASS`/`HOST`/`NAME`                        |
| `YOURLS_USER` + `_PASS`    | admin-user + admin-pw             | Bootstrap | Admin login for UI                                          |
| `YOURLS_PRIVATE`           | `true`                            | Auth      | `true` = login required (recommended)                       |
| `YOURLS_COOKIEKEY`         | 128+ chars random                 | Security  | Generate at <https://yourls.org/cookie>                     |
| Timezone                   | `UTC`                             | Runtime   | Click-stats timestamps                                     |

## Install via Docker Compose

Using the official `yourls` Docker Hub image:

```yaml
services:
  yourls:
    image: yourls:1.10.3-apache    # pin to specific version
    container_name: yourls
    restart: unless-stopped
    depends_on:
      - db
    ports:
      - "8080:80"
    environment:
      YOURLS_SITE: https://yr.example.com
      YOURLS_USER: admin
      YOURLS_PASS: <strong>
      YOURLS_DB_HOST: db
      YOURLS_DB_USER: yourls
      YOURLS_DB_PASS: <strong>
      YOURLS_DB_NAME: yourls
      YOURLS_PRIVATE: "true"
      YOURLS_COOKIEKEY: <paste from https://yourls.org/cookie>
      # Optional tuning:
      # YOURLS_HOURS_OFFSET: "0"
      # YOURLS_LANG: "en_US"
    volumes:
      - yourls-plugins:/var/www/html/user/plugins

  db:
    image: mariadb:10.11
    container_name: yourls-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: <strong>
      MYSQL_DATABASE: yourls
      MYSQL_USER: yourls
      MYSQL_PASSWORD: <strong>
    volumes:
      - yourls-db:/var/lib/mysql

volumes:
  yourls-db:
  yourls-plugins:
```

Official image: <https://hub.docker.com/_/yourls>.

## First boot

1. Browse `https://yr.example.com/admin/install.php` → click **Install YOURLS**
2. Log in with `YOURLS_USER` + `YOURLS_PASS` → `https://yr.example.com/admin/`
3. Shorten your first URL
4. Grab your API signature token from **Tools** → use it for programmatic shortening

## REST API

Signature-token-based API:

```sh
curl "https://yr.example.com/yourls-api.php" \
  -d "signature=<sig>" \
  -d "action=shorturl" \
  -d "url=https://long-url.example.com/path" \
  -d "keyword=custom" \
  -d "title=My Link" \
  -d "format=json"
```

Returns `{"status":"success","shorturl":"https://yr.example.com/custom", ...}`.

## Plugins

Drop plugin directories into `user/plugins/<plugin-name>/` (bind-mount in Docker setup). Enable via admin UI → **Manage Plugins**.

Popular:

- **Allow Hyphens in Short URLs** — permit dashes
- **Cloudflare Turnstile** — bot protection on shorten form
- **Fresh Meat** — admin dashboard widget
- **QR Code** — auto-generate QR per short URL
- **Social Auto Poster** — tweet your short links
- **Anti-spam filters** — blocklist domains

Full list: <https://github.com/YOURLS/awesome-yourls>.

## Data & config layout

- `/var/www/html/user/config.php` — generated from env vars; auth + DB + site URL
- `/var/www/html/user/plugins/` — installed plugins (persist)
- `/var/www/html/user/pages/` — custom static pages
- **MySQL/MariaDB** — all URL + click + option data; `yourls_url` + `yourls_log` + `yourls_options` tables

## Backup

```sh
# MySQL dump
docker compose exec -T db mysqldump -uroot -p"<root-pw>" yourls | gzip > yourls-db-$(date +%F).sql.gz

# Plugins
docker run --rm -v yourls-plugins:/src -v "$PWD":/backup alpine tar czf /backup/yourls-plugins-$(date +%F).tgz -C /src .
```

Losing the DB = all your short URLs + stats gone. Existing printed/shared short links become dead.

## Upgrade

1. Releases: <https://github.com/YOURLS/YOURLS/releases>. Infrequent but steady.
2. Bump image tag → `docker compose pull && docker compose up -d`. DB schema migrations run automatically (via `admin/upgrade.php` → first admin visit).
3. **Back up DB first.** Major version jumps (1.7 → 1.8 → 1.9 → 1.10) have schema changes.
4. Plugins may lag; check compatibility before upgrading if you rely on specific plugins.

## Gotchas

- **`YOURLS_SITE` is permanent.** Short URLs are `<YOURLS_SITE>/<keyword>`; changing the domain means ALL your printed links break. Pick a domain + stick with it forever.
- **Use a short domain.** The whole point is to shorten — `yr.example.com` or `ex.am` beats `analytics.my-company.example.com`. Register something short upfront.
- **`YOURLS_PRIVATE=true` is recommended.** Without it, your instance is a **public link shortener** — spammers will find it and abuse your domain reputation (blocklist hits on Google Safe Browsing, SpamHaus, etc.).
- **Cookie key must be 128+ chars random.** Use <https://yourls.org/cookie> to generate.
- **Cloudflare Turnstile plugin recommended** for any public-facing install.
- **Spam is the #1 threat.** Even with `YOURLS_PRIVATE`, leaked API signatures = mass spam URLs created under your domain → domain blacklisting. Rotate signatures periodically.
- **URL validation is lenient by default.** Install a blocklist plugin for known-bad domains.
- **Click stats are basic.** Country + referrer + UA, but no advanced dashboards. For heavy analytics, layer on Matomo/Plausible on the redirect target itself.
- **Custom keywords should avoid profanity/ambiguity** (auto-generated random strings avoid this).
- **PHP version**: needs 7.4+ or 8.0+. Check compose image tag's bundled PHP.
- **Apache vs nginx**: official image is Apache. For nginx + PHP-FPM, build your own image or use a community fork.
- **Shared hosting installs** are viable (it's designed for it) but you give up isolation.
- **REST API response format**: XML, JSON, or Simple (text). Default XML — pass `format=json` explicitly.
- **Regex-based URL rewriting** for custom short domain TLDs — tricky, documented but rare.
- **Unicode / IDN short codes** — disabled by default; enable in plugin if you need `xn--` domains.
- **MIT license** — no source-sharing obligation, fork freely.
- **Alternatives worth knowing:**
  - **Shlink** — modern PHP, REST+GraphQL API, multi-domain, QR codes built-in (stronger for API-driven use)
  - **Kutt.it** — Node.js, simpler, optional custom domains
  - **Dub** — commercial-leaning OSS (Next.js + Postgres + Redis), link analytics first-class (separate recipe notes Dub has marked itself not-for-production)
  - **Polr** — PHP, minimal
  - **commafeed** — unrelated (RSS)
  - **bitly / rebrandly** — commercial SaaS

## Links

- Repo: <https://github.com/YOURLS/YOURLS>
- Website: <https://yourls.org>
- Docs: <https://docs.yourls.org>
- Cookie key generator: <https://yourls.org/cookie>
- Awesome YOURLS (plugins + tools): <https://github.com/YOURLS/awesome-yourls>
- Blog: <https://blog.yourls.org>
- Community discussions: <https://github.com/YOURLS/YOURLS/discussions>
- Releases: <https://github.com/YOURLS/YOURLS/releases>
- Docker Hub (official): <https://hub.docker.com/_/yourls>
- API docs: <https://docs.yourls.org/development/api.html>
