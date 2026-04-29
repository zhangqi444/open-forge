---
name: Flarum
description: Lightweight, modern discussion forum software. PHP/Laravel-ish + Mithril.js frontend. Successor to phpBB/esoTalk, designed for fast, distraction-free community forums. MIT.
---

# Flarum

Flarum is a PHP forum platform — think phpBB or Discourse, but explicitly designed around simplicity and extensibility. Fast SPA UI, rich text composer, tags/categories via extensions, social login, likes, subscriptions, email notifications. Runs on modest hardware.

- Upstream repo: <https://github.com/flarum/flarum> (skeleton app) + <https://github.com/flarum/core> (actual code)
- Install docs: <https://docs.flarum.org/install>
- Forum docs: <https://docs.flarum.org/>
- Community: <https://discuss.flarum.org/>

**Upstream ships no Docker image.** The recommended install is via Composer on a LAMP/LEMP stack; for Docker, the de-facto community image is `mondedie/flarum` (multi-platform, tracks upstream stable releases).

## Compatible install methods

| Infra     | Runtime                              | Notes                                                                  |
| --------- | ------------------------------------ | ---------------------------------------------------------------------- |
| Single VM | Docker (`mondedie/flarum`) + MariaDB | **Easiest self-host.** Multi-arch image, 1k+ stars                     |
| Single VM | Composer + nginx/Apache + PHP-FPM + MariaDB | Upstream-documented, production-proven                          |
| Shared hosting | Flarum ZIP upload + MySQL        | Works on most cPanel hosts with PHP 8.1+                                |
| Kubernetes | Community images + MySQL operator   | Community Helm chart at <https://artifacthub.io/packages/search?ts_query_web=flarum> |

## Inputs to collect

| Input                    | Example                          | Phase     | Notes                                                         |
| ------------------------ | -------------------------------- | --------- | ------------------------------------------------------------- |
| `FORUM_URL`              | `https://forum.example.com`      | Runtime   | **Required.** Must match external URL exactly                  |
| MariaDB/MySQL creds      | strong password                  | DB        | MariaDB 10.5+ recommended; MySQL 8.0+ also works                |
| `FLARUM_ADMIN_USER` + `FLARUM_ADMIN_PASS` + `FLARUM_ADMIN_MAIL` | admin/8+chars/email | Bootstrap | Required **only on first install**; remove env after     |
| `FLARUM_TITLE`           | `My Community`                   | Runtime   | Display title                                                 |
| SMTP                     | any provider                     | Runtime   | For email notifications, password reset                        |
| Reverse proxy            | Caddy/Traefik/nginx              | TLS       | **Required.** Image exposes HTTP on `:8888` inside container  |
| PHP extensions           | optional                         | Runtime   | Additional PHP extensions via `PHP_EXTENSIONS` env             |
| GitHub token (optional)  | for private extensions           | Runtime   | `GITHUB_TOKEN_AUTH` for composer private repos                 |

## Install via Docker Compose (`mondedie/flarum`)

From <https://github.com/mondediefr/docker-flarum>:

```yaml
services:
  flarum:
    image: mondedie/flarum:stable
    container_name: flarum
    env_file: flarum.env
    volumes:
      - ./assets:/flarum/app/public/assets
      - ./extensions:/flarum/app/extensions
      - ./storage/logs:/flarum/app/storage/logs
      - ./nginx:/etc/nginx/flarum
    ports:
      - "8080:8888"         # behind a reverse proxy — expose externally on :443
    depends_on:
      - mariadb

  mariadb:
    image: mariadb:10.11
    container_name: mariadb
    environment:
      - MYSQL_ROOT_PASSWORD=REPLACE_ME
      - MYSQL_DATABASE=flarum
      - MYSQL_USER=flarum
      - MYSQL_PASSWORD=REPLACE_WITH_STRONG_PASSWORD
    volumes:
      - ./db:/var/lib/mysql
```

`flarum.env`:

```env
DEBUG=false
FORUM_URL=https://forum.example.com

# DB (must match MariaDB service creds)
DB_HOST=mariadb
DB_USER=flarum
DB_NAME=flarum
DB_PASS=REPLACE_WITH_STRONG_PASSWORD
DB_PORT=3306
#DB_PREF=            # Optional table prefix

# First-install admin (remove after initial install)
FLARUM_ADMIN_USER=admin
FLARUM_ADMIN_PASS=REPLACE_WITH_8PLUS_CHARS
FLARUM_ADMIN_MAIL=admin@example.com
FLARUM_TITLE=My Community

# Tuning
UPLOAD_MAX_SIZE=50M
PHP_MEMORY_LIMIT=128M
OPCACHE_MEMORY_LIMIT=128

# Optional: add PHP extensions (e.g. imagick, redis)
#PHP_EXTENSIONS=imagick redis
```

Bring up DB first, wait for it, then Flarum:

```sh
docker compose up -d mariadb
sleep 10
docker compose up -d flarum
```

After first successful boot, **remove the `FLARUM_ADMIN_*` env vars** — they're only needed during install. Re-setting a password requires `bin/flarum reset-password` inside the container.

## Install via Composer (upstream-documented)

<https://docs.flarum.org/install#installing-flarum>:

```sh
# 1. Prereqs on the host: PHP 8.1+, Composer, MySQL/MariaDB, web server
composer create-project flarum/flarum /var/www/forum
cd /var/www/forum
# 2. Configure web server (nginx/Apache) — doc examples at:
#    https://docs.flarum.org/config
# 3. Browse the forum URL; the installer wizard walks you through DB + admin setup
```

Ownership matters: `chown -R www-data:www-data /var/www/forum && chmod -R 755 /var/www/forum` (with appropriate user).

## Data & config layout (Docker path)

- `./assets/` — uploaded avatars + forum assets (critical)
- `./extensions/` — installed Flarum extensions (composer-installed)
- `./storage/logs/` — Flarum + nginx logs
- `./nginx/` — custom nginx vhost config (optional)
- MariaDB volume — all forum content (posts, users, tags, settings)
- `./assets/.env` / `config.php` (generated inside container) — DB creds, site URL

## Extension management

From inside the container:

```sh
# List installed
docker exec flarum extension list

# Install an extension (searches packagist/flarum)
docker exec flarum extension require fof/upload

# Remove
docker exec flarum extension remove fof/upload
```

`mondedie/flarum` persists extensions under `/flarum/app/extensions` which is volume-mounted, so they survive container recreation.

## Backup

```sh
# Database (everything else is rebuildable)
docker compose exec -T mariadb mysqldump -u root -p"$ROOT_PWD" flarum | gzip > flarum-db-$(date +%F).sql.gz

# Uploaded assets
tar czf flarum-assets-$(date +%F).tgz ./assets ./extensions
```

## Upgrade

1. Flarum releases: <https://github.com/flarum/core/releases>.
2. `mondedie/flarum:stable` follows latest Flarum stable; `:<version>` tags pin to specific major/minor.
3. `docker compose pull && docker compose up -d` — container entrypoint runs migrations on startup.
4. Read Flarum's upgrade guide for any breaking extension-API changes between majors (e.g. 1.x → 2.x required extension updates): <https://docs.flarum.org/update>.
5. After upgrade, check each installed extension on <https://flarum.org/extensions> to confirm compatibility with the new core version.

## Gotchas

- **The `flarum/flarum` repo is a skeleton, not the app.** Actual code is in `flarum/core` + several dozen official extensions. Most installation errors are in extensions, not core.
- **Upstream ships no Docker image.** The mondedie and crazymax community images are the de-facto path. Upstream doesn't publish images because Flarum's "philosophy" is composer + PHP — Docker is considered user territory.
- **Flarum 2.x is a major rewrite** (branch `2.x` is the new default). Extensions from 1.x may not work. Check extension compatibility before upgrading.
- **`FLARUM_ADMIN_*` envs run the install wizard on every container start until data exists.** Once installed, Flarum detects an existing DB and skips — but leaving these env vars set is a credentials leak. Remove them after first-boot.
- **Flarum requires a reverse proxy for HTTPS.** The mondedie image has nginx inside serving HTTP only. Terminate TLS at Caddy/Traefik/nginx-proxy upstream.
- **`FORUM_URL` must match exactly** (scheme + host, no trailing slash). Wrong value = broken CSRF, broken asset URLs.
- **UID/GID are `991:991` by default.** Mismatch with host file ownership causes "permission denied" on `./assets/` writes. Set `UID`/`GID` env to match host user.
- **Extension installations require outbound internet access.** Container calls packagist + GitHub. Firewalled deploys need a private Composer mirror.
- **Default upload limit is 50 MB.** Nginx also has its own client-max-body-size — the upstream reverse proxy usually needs matching config.
- **Debug mode leaks stack traces.** `DEBUG=true` is useful during install troubleshooting but **must be off in production** — attackers can read DB credentials from error pages.
- **Backup before updating extensions**: the Flarum extension ecosystem is mostly one-developer-per-extension. Extension updates occasionally break migrations in ways that require DB rollback.
- **Email notifications need `queue` + `cron` configured** (inside the container, already handled by `mondedie/flarum`'s init). Bare-metal installs require setting up a systemd timer for `php flarum queue:work` and `php flarum schedule:run`.
- **Tags are an extension** (`flarum/tags`), not built-in. Install it first if you want structured categorization.
- **`flarum/extension-manager`** (official) adds a web UI for extension management. Alternative to `extension require` CLI.
- **Search uses MySQL LIKE by default** — slow on large forums. Install a Meilisearch/Elasticsearch-backed extension for better perf at scale.
- **Community extensions vary in quality.** FriendsOfFlarum (FoF) is the biggest high-quality ecosystem.

## Links

- Main repo: <https://github.com/flarum/flarum>
- Core: <https://github.com/flarum/core>
- Install docs: <https://docs.flarum.org/install>
- Update guide: <https://docs.flarum.org/update>
- Extensions marketplace: <https://flarum.org/extensions>
- FriendsOfFlarum: <https://github.com/FriendsOfFlarum>
- Community forum: <https://discuss.flarum.org/>
- Docker image (mondedie): <https://github.com/mondediefr/docker-flarum>
- Docker image (crazymax): <https://github.com/crazy-max/docker-flarum>
- Discord: <https://flarum.org/discord/>
