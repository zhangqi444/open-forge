---
name: WordPress
description: Classic self-hosted CMS and blogging platform. PHP + MySQL/MariaDB. Millions of themes and plugins, mature ecosystem.
---

# WordPress

WordPress is the reference PHP-based content management system. The official Docker image is maintained by the Docker Library team and is the canonical self-host path — the `WordPress/WordPress` GitHub repo is an SVN mirror, not a Docker source.

- Official image repo (Docker Library): <https://github.com/docker-library/wordpress>
- Image docs: <https://hub.docker.com/_/wordpress>
- WordPress source (SVN mirror): <https://github.com/WordPress/WordPress>
- Upstream project: <https://wordpress.org/>

## Compatible install methods

| Infra           | Runtime                          | Notes                                                               |
| --------------- | -------------------------------- | ------------------------------------------------------------------- |
| Single VM       | Docker + Compose                 | Recommended; Docker Library publishes a reference compose           |
| Single VM       | Bitnami WordPress image          | Alternative, more opinionated (non-root, different paths)            |
| Kubernetes      | Bitnami Helm chart, official     | Well-supported; not upstream-Docker-library                          |
| Managed LAMP    | cPanel / Plesk / bare LAMP       | Well-documented; Docker isn't required                               |
| Multisite       | Any of the above + config        | Set `WP_ALLOW_MULTISITE` via `WORDPRESS_CONFIG_EXTRA`                |

## Image variants

From <https://hub.docker.com/_/wordpress>:

- `wordpress:<version>` / `wordpress:<version>-apache` — Apache + mod_php (default, easiest)
- `wordpress:<version>-fpm` — PHP-FPM; pair with nginx
- `wordpress:<version>-fpm-alpine` — slim FPM variant
- `wordpress:cli` — Alpine-based WP-CLI (does not run WordPress itself)

Always **pin a major-minor** (e.g. `wordpress:6.9-apache`) instead of floating `latest` in production.

## Inputs to collect

| Input                     | Example                          | Phase     | Notes                                                         |
| ------------------------- | -------------------------------- | --------- | ------------------------------------------------------------- |
| `WORDPRESS_DB_HOST`       | `db`                             | Runtime   | Compose service name or external MySQL/MariaDB hostname        |
| `WORDPRESS_DB_USER`       | `wpuser`                         | Runtime   | Must already exist in DB or be created by the DB container     |
| `WORDPRESS_DB_PASSWORD`   | strong random                    | Runtime   | Supports `_FILE` secret variant                                |
| `WORDPRESS_DB_NAME`       | `wordpress`                      | Runtime   | **DB must already exist** — image does not create it           |
| `WORDPRESS_TABLE_PREFIX`  | `wp_`                            | Runtime   | Multi-site on same DB needs unique prefixes                    |
| Auth salts (8 values)     | random 64-byte strings           | Runtime   | `WORDPRESS_AUTH_KEY`, …, `WORDPRESS_NONCE_SALT`. Auto-generated per container unless any DB env var is set; pin them for stable sessions. |
| MySQL/MariaDB creds       | matching `MYSQL_*` vars          | Data      | Keep in lockstep with `WORDPRESS_DB_*`                         |
| Reverse proxy TLS         | Caddy/nginx/Traefik              | Network   | Set `X-Forwarded-Proto` upstream — image respects it           |

## Install via Docker Compose

Upstream's reference compose (from <https://github.com/docker-library/docs/blob/master/wordpress/compose.yaml>):

```yaml
services:
  wordpress:
    image: wordpress:6.9-apache      # pin — don't use :latest
    restart: always
    ports:
      - 8080:80
    environment:
      WORDPRESS_DB_HOST: db
      WORDPRESS_DB_USER: wpuser
      WORDPRESS_DB_PASSWORD: __change_me__
      WORDPRESS_DB_NAME: wordpress
    volumes:
      - wordpress:/var/www/html

  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wpuser
      MYSQL_PASSWORD: __change_me__
      MYSQL_RANDOM_ROOT_PASSWORD: '1'
    volumes:
      - db:/var/lib/mysql

volumes:
  wordpress:
  db:
```

Then:

```sh
docker compose up -d
# Wait for "/usr/local/bin/apache2-foreground" in logs
# Browse http://<host>:8080 → run the famous 5-minute installer
```

### Behind a reverse proxy

Terminate TLS at Caddy/nginx/Traefik. Ensure the proxy sets `X-Forwarded-Proto: https`; the image's bundled `wp-config-docker.php` will honor it and emit `https://` URLs. If you see mixed-content warnings, confirm the proxy header is present.

### Pinned salts

By default the image generates random salts per container start — a container rebuild logs everyone out. For stable sessions, generate once and set all 8 env vars:

```sh
curl -s https://api.wordpress.org/secret-key/1.1/salt/
# Copy each value into WORDPRESS_AUTH_KEY, WORDPRESS_SECURE_AUTH_KEY,
# WORDPRESS_LOGGED_IN_KEY, WORDPRESS_NONCE_KEY, and their *_SALT twins.
```

## Data & config layout

- Volume `wordpress` → `/var/www/html` — full WordPress tree: core files, `wp-content/` (uploads, themes, plugins), generated `wp-config.php`
- Volume `db` → `/var/lib/mysql` — MySQL data dir
- `wp-config.php` is generated on first boot from env vars via `wp-config-docker.php`. Edit env (or use `WORDPRESS_CONFIG_EXTRA=...`) rather than the file directly.

Back up both volumes; losing `wp-content/uploads` loses your media library.

## Backup

```sh
# DB
docker compose exec -T db mysqldump -uwpuser -p"$WORDPRESS_DB_PASSWORD" wordpress | gzip > wp-db-$(date +%F).sql.gz

# Files
docker run --rm -v compose_wordpress:/data -v "$PWD":/backup alpine \
  tar czf /backup/wp-html-$(date +%F).tgz -C /data .
```

Store salts alongside backups — without them logins fail to verify after restore to a fresh container.

## Upgrade

WordPress auto-updates minor core versions from inside the app by default. For major jumps or Docker-native upgrade:

1. Back up DB + `/var/www/html` volume.
2. Bump the image tag in compose (check <https://hub.docker.com/_/wordpress/tags>).
3. `docker compose pull && docker compose up -d`.
4. On first request, WordPress auto-runs DB schema migrations.

**Watch for:** plugin/theme incompatibilities on major bumps. Stage upgrades in a clone of the site first (`wp-cli db export` + `wp search-replace` from the `wordpress:cli` image).

## Gotchas

- **`WORDPRESS_DB_NAME` must exist before the container starts.** If using an external DB (not the bundled `db:` service), create the database and grant privileges first.
- **Auto-generated salts change on every container rebuild** unless pinned — sessions invalidate and in rare cases can break 2FA plugins.
- **File permissions.** The image runs as `www-data` (UID 33 in Debian-based images, 82 in Alpine WP-CLI). When mounting host dirs, `chown -R 33:33 wp-content` or use an `init` container.
- **Uploads default to a 2 MB limit.** Override with a `custom.ini` in `$PHP_INI_DIR/conf.d/` via a derived image (see the Docker Hub docs' PHP directives section).
- **`latest` tag floats across major versions.** Always pin; a silent major bump can break plugins.
- **Reverse-proxy HTTPS setup requires `X-Forwarded-Proto`.** Without it the UI emits plain `http://` asset URLs and browsers block mixed content.
- **Multisite requires `WP_ALLOW_MULTISITE=1`** — set via `WORDPRESS_CONFIG_EXTRA=define('WP_ALLOW_MULTISITE', true);`, not a dedicated env var.
- **Plugins that write inside `/var/www/html`** (updates, backups, caching) only persist if the volume is mounted. A `tmpfs` or read-only root breaks them — use the "static image" pattern from the Docker Hub docs if you want read-only deploys.
- **MySQL 8 default auth plugin** is `caching_sha2_password`; WordPress handles it fine, but some older plugins bundle their own DB client that doesn't. If you hit auth errors, the image docs suggest MySQL 8 with `default-authentication-plugin=mysql_native_password` as a workaround.
- **Don't run WP-CLI (UID 82) against a Debian-container volume (UID 33)** without `--user 33:33`; otherwise you get permission errors or wrong file ownership.

## Links

- Docker Hub: <https://hub.docker.com/_/wordpress>
- Image source: <https://github.com/docker-library/wordpress>
- Image docs: <https://github.com/docker-library/docs/tree/master/wordpress>
- Reference compose: <https://github.com/docker-library/docs/blob/master/wordpress/compose.yaml>
- Upstream WordPress docs: <https://wordpress.org/documentation/>
- WP-CLI: <https://hub.docker.com/_/wordpress/tags?name=cli>
- Secret key generator: <https://api.wordpress.org/secret-key/1.1/salt/>
