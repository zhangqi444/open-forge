---
name: Matomo
description: Privacy-first web analytics platform — open-source alternative to Google Analytics. 100% data ownership; PHP/MySQL stack.
---

# Matomo

Matomo (formerly Piwik) is a full-featured web analytics platform: page views, goals, funnels, e-commerce, heatmaps (via premium plugin), GDPR-compliant tracking. It's a PHP web app backed by MySQL/MariaDB. The official Docker image (`matomo`, on the Docker Hub library) ships Apache + PHP-FPM variants.

- Main repo: <https://github.com/matomo-org/matomo>
- **Docker repo:** <https://github.com/matomo-org/docker>
- Image: `matomo` (official library image on Docker Hub)
- Docs: <https://matomo.org/docs/>

## Compatible install methods

| Infra              | Runtime                      | Notes                                                             |
| ------------------ | ---------------------------- | ----------------------------------------------------------------- |
| Single VM          | Docker + Compose (apache)    | Recommended — upstream ships `.examples/apache/compose.yml`       |
| Single VM          | Docker + Compose (nginx/fpm) | `.examples/nginx/compose.yml` for nginx front-door                |
| Kubernetes         | Community Helm chart         | `bitnami/matomo` — not upstream-maintained                        |
| Bare metal         | PHP 8.2+ + Apache/nginx + MariaDB | Fully supported; see docs                                     |
| Managed hosting    | Any PHP host with MySQL       | Works on shared hosting; see the standard installer                |

## Inputs to collect

| Input                 | Example                           | Phase     | Notes                                                       |
| --------------------- | --------------------------------- | --------- | ----------------------------------------------------------- |
| `MARIADB_ROOT_PASSWORD` | strong random                   | Data      | Required; one-time init                                      |
| `MARIADB_PASSWORD`    | strong random                      | Data      | Matomo's DB user password                                    |
| Matomo admin user     | set via installer UI on first boot | Runtime  | No env vars for this; the browser installer prompts         |
| Site URL              | `https://stats.example.com`        | Runtime  | Set `trusted_hosts` to match (General Settings → Trusted Hosts) |
| Geolocation DB        | MaxMind GeoLite2 / DB-IP          | Optional  | Drop into `misc/` for country/city accuracy                 |
| SMTP                  | any                                | Runtime   | For password reset, scheduled reports                       |

## Install via Docker Compose

Upstream's `.examples/apache/compose.yml` (at <https://github.com/matomo-org/docker/blob/master/.examples/apache/compose.yml>), verbatim:

```yaml
services:
  db:
    image: mariadb:lts
    command: --max-allowed-packet=64MB
    restart: always
    volumes:
      - db:/var/lib/mysql:Z
    environment:
      - MARIADB_AUTO_UPGRADE=1
      - MARIADB_DATABASE=matomo
      - MARIADB_DISABLE_UPGRADE_BACKUP=1
      - MARIADB_INITDB_SKIP_TZINFO=1
      - MARIADB_PASSWORD=${MARIADB_PASSWORD}
      - MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD}
      - MARIADB_USER=matomo

  app:
    image: matomo:5.3.2-apache     # pin; see https://hub.docker.com/_/matomo/tags
    restart: always
    volumes:
      - matomo:/var/www/html:z
    depends_on:
      - db
    environment:
      - MATOMO_DATABASE_ADAPTER=mysql
      - MATOMO_DATABASE_DBNAME=matomo
      - MATOMO_DATABASE_HOST=db
      - MATOMO_DATABASE_PASSWORD=${MARIADB_PASSWORD}
      - MATOMO_DATABASE_TABLES_PREFIX=matomo_
      - MATOMO_DATABASE_USERNAME=matomo
    ports:
      - 8080:80

volumes:
  db:
  matomo:
```

Steps:

```sh
cat > .env <<EOF
MARIADB_ROOT_PASSWORD=$(openssl rand -hex 16)
MARIADB_PASSWORD=$(openssl rand -hex 16)
EOF

docker compose up -d
```

Browse `http://<host>:8080` → the Matomo web installer walks through:

1. System check
2. Database credentials (pre-filled from env vars)
3. Super user (admin) account
4. First website to track
5. JS tag / image tracker to embed in your site

After install, add your reverse-proxy domain to **Administration → System → General Settings → Trusted Hosts**, or Matomo will refuse traffic from it.

### Scheduled archiving (important)

For sites with more than a few thousand hits/day, turn off "browser-triggered archiving" and run the archive task on a cron:

```sh
# Host cron — runs Matomo's archive CLI every hour
0 * * * * docker compose -f /srv/matomo/compose.yml exec -T app \
  /usr/local/bin/php /var/www/html/console core:archive --url=https://stats.example.com
```

Reference: <https://matomo.org/docs/setup-auto-archiving/>.

## Data & config layout

- Volume `matomo` → `/var/www/html` — includes `config/config.ini.php`, uploaded plugins, `misc/` (GeoIP DBs). This is your app state outside the database.
- Volume `db` → `/var/lib/mysql` — MariaDB data dir.
- Config file: `/var/www/html/config/config.ini.php` inside the `app` container (the installer writes it).
- Environment variables with `_FILE` suffix read secrets from files — useful for Docker secrets.

## Backup

```sh
# DB dump
docker compose exec -T db mariadb-dump -u matomo -p"$MARIADB_PASSWORD" matomo | gzip > matomo-db-$(date +%F).sql.gz

# App state volume
docker run --rm -v matomo:/data -v "$PWD":/backup alpine tar czf /backup/matomo-app-$(date +%F).tgz -C /data .
```

## Upgrade

1. Check release notes: <https://matomo.org/changelog/>.
2. Bump the `matomo` image tag in compose.
3. `docker compose pull && docker compose up -d` — the entrypoint runs DB migrations automatically via `core:update` on start.
4. Browse to `/` once; if a schema update is waiting, Matomo will show a "Database upgrade required" screen and run it when you click through (or run `docker compose exec app php console core:update --yes`).
5. Plugin updates happen via **Administration → Marketplace → Updates**; they live in the `matomo` volume and survive image updates.

## Gotchas

- **Trusted Hosts is a footgun.** If your reverse-proxy domain isn't in the trusted-hosts list, every request 403s. Add it via UI, or manually via `config.ini.php` under `[General] trusted_hosts[]`.
- **Browser-triggered archiving doesn't scale.** Any site over ~10k hits/day needs the CLI cron (above) — otherwise reports get slow or stale.
- **MariaDB `lts` tag floats.** Pin (e.g. `mariadb:11.4`) if you want deterministic upgrades.
- **`MARIADB_AUTO_UPGRADE=1`** handles minor MariaDB bumps automatically but doesn't skip majors.
- **`:Z` / `:z` SELinux labels** in the compose example are for RHEL/Fedora hosts; harmless elsewhere. Remove them on Synology / weird storage backends that don't support them.
- **Geolocation requires a separate DB.** Matomo's UI can auto-download MaxMind GeoLite2, but MaxMind now requires a free license key (<https://www.maxmind.com/en/geolite2/signup>). DB-IP is a license-free alternative.
- **Plugins installed from Marketplace need write access to the `matomo` volume.** The image runs as `www-data` (uid 33); if you bind-mount from host, align permissions or plugin install fails silently.
- **IP anonymization is OFF by default.** For EU/GDPR compliance, enable it under **Privacy → Anonymize data**; also consider disabling browser fingerprint + cookie-less tracking mode.
- **`matomo.js` / `matomo.php` are the tracker endpoints.** If you rename them to bypass ad-blockers (a common tactic), remember to update your tracking snippet on every site.
- **`matomo:fpm` image needs an nginx/apache front** — see `.examples/nginx/compose.yml` upstream.

## Links

- Main repo: <https://github.com/matomo-org/matomo>
- Docker repo + examples: <https://github.com/matomo-org/docker>
- Docs home: <https://matomo.org/docs/>
- Installation guide: <https://matomo.org/docs/installation/>
- Auto-archiving: <https://matomo.org/docs/setup-auto-archiving/>
- Releases / changelog: <https://matomo.org/changelog/>
- Docker Hub tags: <https://hub.docker.com/_/matomo/tags>
