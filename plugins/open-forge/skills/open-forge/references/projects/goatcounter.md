---
name: GoatCounter
description: "Privacy-friendly web analytics — lightweight (~3.5KB tracker), no cookies, no GDPR notice needed, JS-free pixel option, logfile import. Free hosted service + self-hostable single-binary Go app. SQLite or Postgres. EUPL-1.2."
---

# GoatCounter

GoatCounter is **a privacy-first, lightweight web analytics platform** — created by **Martin Tournoij (arp242)**. Designed as an antidote to Google Analytics's privacy invasion + Matomo's configuration complexity. Tracks essential metrics (visits, unique-ish visitors, browsers, countries, referrers) without cookies, fingerprinting, or third-party sharing — **no GDPR cookie banner required**.

Runs as a **single statically-compiled Go binary**. SQLite by default (zero-dep); Postgres for larger deployments. Tracker adds **~3.5 KB** to your site. Free hosted at <https://www.goatcounter.com> for non-commercial use; self-host without restrictions.

Features:

- **Privacy-aware** — no unique user tracking, non-identifiable hashed session IDs (rotate daily)
- **No cookies** — no GDPR banner needed (in most jurisdictions)
- **Multiple data-ingestion paths**:
  1. JavaScript tracker — most common
  2. **No-JS image pixel** — for strict CSP or JS-blocked users
  3. HTTP/REST API — backend middleware integration
  4. **Logfile import** — parse nginx/Apache/Caddy/CloudFront access logs
- **Lightweight UI** — fast + accessibility-first (screen-reader friendly)
- **Key metrics** — pageviews, unique-ish visits, referrers, campaigns, browsers, OS, screen size, country, language
- **Goals / events / campaigns**
- **Export** — full data export; your data is yours
- **Multiple sites** — one instance, many tracked sites
- **Email reports**
- **Embeddable** stats — public dashboards possible

- Upstream repo: <https://github.com/arp242/goatcounter>
- Website: <https://www.goatcounter.com>
- Docs: <https://www.goatcounter.com/help>
- Demo: <https://stats.arp242.net>
- Author: <https://www.arp242.net>
- Sponsor: <https://www.goatcounter.com/contribute>

## Architecture in one minute

- **Single Go binary** (`goatcounter`); embeds the web UI + API
- **SQLite** (default, zero-setup) or **PostgreSQL** (for larger)
- **No dependencies** beyond DB
- **Resource**: extremely light — <100 MB RAM for typical sites; handles millions of pageviews/month on modest hardware
- **Static binary** means deployment = copy + run

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Download binary from releases + systemd unit**                   | **Upstream-recommended — ~5 min setup**                                                       |
| Single VM          | **Docker (community image)**                                               | Works                                                                                          |
| Raspberry Pi       | ARM binaries available — ideal Pi use case                                         | Very low resource                                                                                         |
| Kubernetes         | Community manifests — but it's so simple K8s is overkill                                                     |                                                                                                                        |
| Managed            | **goatcounter.com** (free for non-commercial, paid for commercial)                                                    | **Use this if non-commercial — skip self-hosting**                                                                                                                     |

## Inputs to collect

| Input              | Example                             | Phase       | Notes                                                                 |
| ------------------ | ----------------------------------- | ----------- | --------------------------------------------------------------------- |
| Domain             | `stats.example.com`                    | URL         | TLS reverse proxy                                                              |
| DB                 | SQLite (default) / Postgres                 | DB          | SQLite fine up to modest scale                                                                |
| Admin account      | first site on `create` command                     | Bootstrap   | Strong password                                                                                  |
| Tracker domain     | `https://stats.example.com/count`                                 | Setup       | Script src                                                                                                     |
| SMTP (opt)         | for email reports + password resets                                              | Email       | Optional                                                                                                                 |

## Install via binary (Linux)

```sh
# Download latest release
wget https://github.com/arp242/goatcounter/releases/download/v2.5.0/goatcounter-v2.5.0-linux-amd64.gz
gunzip goatcounter-v2.5.0-linux-amd64.gz
sudo mv goatcounter-v2.5.0-linux-amd64 /usr/local/bin/goatcounter
sudo chmod +x /usr/local/bin/goatcounter

# Create user + data dir
sudo useradd -r -s /bin/false goatcounter
sudo mkdir -p /var/lib/goatcounter
sudo chown goatcounter: /var/lib/goatcounter

# DB init (SQLite)
sudo -u goatcounter goatcounter db create -createdb=goatcounter.sqlite3

# Create first site + admin
sudo -u goatcounter goatcounter db create site \
  -vhost=stats.example.com -user.email=you@example.com -user.password=CHANGE_ME

# Run (behind reverse proxy)
sudo -u goatcounter goatcounter serve -listen=127.0.0.1:8080 -tls=proxy
```

Systemd unit: upstream provides an example. Put Caddy/Nginx in front for TLS.

## Install via Docker (community)

```yaml
services:
  goatcounter:
    image: baldurmen/goatcounter:latest                # community image; pin in prod
    restart: unless-stopped
    volumes:
      - ./data:/data
    environment:
      GOATCOUNTER_DOMAIN: stats.example.com
    ports:
      - "8080:8080"
```

## First boot

1. Browse `https://stats.example.com/` → log in as created admin
2. `Settings → Sites → New site` if multi-site
3. Grab the JS snippet from `Settings → Site code`
4. Paste in your site's `<head>`:
   ```html
   <script data-goatcounter="https://stats.example.com/count"
           async src="//gc.zgo.at/count.js"></script>
   ```
5. Visit your site → refresh GoatCounter dashboard → metrics appear
6. (Optional) configure email reports, goals, campaigns
7. (Optional) import historical nginx logs: `goatcounter import -site=1 nginx-access.log`

## Data & config layout

- `/var/lib/goatcounter/goatcounter.sqlite3` — all data (SQLite)
- Or Postgres via `-db` flag
- Binary config via CLI flags + optional config file

## Backup

```sh
# SQLite
sudo sqlite3 /var/lib/goatcounter/goatcounter.sqlite3 ".backup '/backup/goatcounter-$(date +%F).sqlite3'"

# Postgres
pg_dump -U goatcounter goatcounter | gzip > goatcounter-$(date +%F).sql.gz
```

## Upgrade

1. Releases: <https://github.com/arp242/goatcounter/releases>. Solid pace.
2. **Back up DB.**
3. Binary: download new version, replace, restart service. Migrations auto on start.
4. Read release notes — major versions may require `goatcounter migrate` command.

## Gotchas

- **"Unique visitors" is approximate** — GoatCounter uses a non-identifiable hash of (IP + User-Agent + salt-rotated-daily). Not a true UV count; intentional design. Good enough for traffic trends; not for precise UV reporting.
- **No GDPR cookie banner** — because no cookies are set. But verify your local jurisdiction — in some regions even server-side IP logging requires disclosure. Read GoatCounter's GDPR page: <https://www.goatcounter.com/gdpr>.
- **Non-commercial hosted service is free**; commercial use needs a paid plan on goatcounter.com. Self-hosting has no such restriction — full EUPL-1.2 FOSS.
- **Use hosted for small/personal sites**: like weblate hosted, this is the "don't self-host unless you need to" case. Self-host if you want full data ownership, very high traffic, or commercial avoidance.
- **JS-blocked visitors**: use the pixel-based tracker (`<img>` tag) OR logfile import for complete coverage.
- **Logfile import is powerful**: retroactively import months of nginx logs → full historical stats. Great for migrating from GA/Matomo.
- **Retention**: GoatCounter stores events indefinitely by default. Configure retention in site settings if privacy policy / storage demands.
- **CSP**: if your site uses strict CSP, allow `stats.example.com` in `script-src` + `connect-src` (or use pixel tracker which needs `img-src`).
- **Bot filtering**: GoatCounter filters common bots by user-agent. Can customize.
- **Multiple sites**: one GoatCounter instance handles many domains — useful for agencies / personal portfolio of sites.
- **SQLite at scale**: handles millions of events well. At ~10M+ events/day, switch to Postgres.
- **Email reports**: configure SMTP for daily/weekly summaries.
- **API**: allows event ingestion from backend (bypass client tracker). Useful for server-rendered apps, mobile apps, webhooks.
- **"GoatCounter Cloud" is arp242's operation** — single-dev project + hosted service. Monitor project health (it's healthy as of now).
- **Migration from other tools**: GoatCounter has no direct GA/Matomo importer; historical data usually stays in old tool + fresh start in GC (logfile import covers "what happened in the last N days" gap).
- **Accessibility**: UI is deliberately keyboard + screen-reader friendly — rare in analytics space.
- **License**: **EUPL-1.2** (European Union Public License v1.2 — copyleft, GPL-compatible).
- **Author**: Martin Tournoij (arp242); responsive but single-maintainer — plan accordingly for production.
- **Alternatives worth knowing:**
  - **Plausible** — similar privacy-first philosophy; Elixir; active development; commercial-friendly
  - **Umami** — Node.js; MySQL/Postgres; modern UI; no-cookie
  - **Matomo** — heavyweight; full-featured; PHP; competes directly with GA
  - **Fathom** — commercial privacy-first (also self-hostable)
  - **Shynet** — Django, privacy-first
  - **Pirsch** — Go, privacy-first, commercial SaaS
  - **Countly** (batch 68) — product analytics; different scope
  - **PostHog** — product analytics + feature flags; heavier
  - **Simple Analytics** — commercial SaaS
  - **Choose GoatCounter if:** you want tiny, privacy-first, EUPL-licensed, SQLite-single-binary simplicity.
  - **Choose Plausible if:** you want a polished UI + active team + self-host + commercial-friendly.
  - **Choose Umami if:** you want modern JS-based stack.
  - **Choose Matomo if:** you want GA-feature-parity and don't mind PHP.

## Links

- Repo: <https://github.com/arp242/goatcounter>
- Website: <https://www.goatcounter.com>
- Help / docs: <https://www.goatcounter.com/help>
- GDPR page: <https://www.goatcounter.com/gdpr>
- Demo: <https://stats.arp242.net>
- Releases: <https://github.com/arp242/goatcounter/releases>
- Sponsor: <https://www.goatcounter.com/contribute>
- Plausible (alt): <https://plausible.io>
- Umami (alt): <https://umami.is>
- Matomo (alt): <https://matomo.org>
- Fathom (alt): <https://usefathom.com>
