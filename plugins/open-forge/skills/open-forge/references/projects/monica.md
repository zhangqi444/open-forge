---
name: Monica (Personal CRM)
description: Open-source personal relationship manager — remember details about friends & family, schedule reminders, log interactions. PHP/Laravel + MariaDB/MySQL.
---

# Monica

Monica is a Laravel 10 app for tracking people in your personal life: contacts, relationships, events, gifts, tasks, reminders. Two official images exist: the `apache` image (all-in-one) and the `fpm` image (PHP-FPM behind your own nginx/apache). The apache flavor is recommended for most self-hosters.

- Upstream app repo: <https://github.com/monicahq/monica>
- **Docker image repo:** <https://github.com/monicahq/docker>
- Image: `monica` on Docker Hub (<https://hub.docker.com/_/monica>) — official library image
- Docs: <https://www.monicahq.com/docs>

## Compatible install methods

| Infra                | Runtime                   | Notes                                                                                |
| -------------------- | ------------------------- | ------------------------------------------------------------------------------------ |
| Single VM            | Docker + Compose (apache) | Recommended — the `monica` official image + MariaDB                                  |
| Single VM            | Docker + Compose (fpm)    | Use when you already run nginx as a front-door                                       |
| Kubernetes           | Helm chart (community)    | `cowboysysop/charts` maintains one; not upstream                                     |
| Bare metal           | Manual Laravel install    | Supported — Apache/PHP 8.2 + Composer; see docs                                      |

## Inputs to collect

| Input          | Example                                                  | Phase     | Notes                                                          |
| -------------- | -------------------------------------------------------- | --------- | -------------------------------------------------------------- |
| `APP_KEY`      | `base64:<32 random bytes>`                               | Runtime   | **Required.** `echo -n 'base64:'; openssl rand -base64 32`     |
| `APP_URL`      | `https://monica.example.com`                             | Runtime   | Full origin; required for mail links and asset URLs            |
| DB credentials | `DB_USERNAME`, `DB_PASSWORD`                             | Runtime   | Must match MariaDB container's `MYSQL_USER` / `MYSQL_PASSWORD` |
| SMTP config    | `MAIL_MAILER=smtp`, `MAIL_HOST`, `MAIL_PORT`, user, pass | Runtime   | Required for reminders, invites, password reset                |
| UID/GID (fpm)  | `1000:1000`                                              | Runtime   | Match host owner of `storage/` mount                           |

## Install via Docker Compose (apache variant, recommended)

Upstream's canonical apache example (from <https://github.com/monicahq/docker#apache-version>):

```yaml
services:
  app:
    image: monica:4.1.2    # pin to a real release; avoid :latest in production
    depends_on:
      - db
    ports:
      - 8080:80
    environment:
      - APP_KEY=base64:REPLACE_ME_32_BYTES
      - APP_URL=https://monica.example.com
      - DB_HOST=db
      - DB_USERNAME=usermonica
      - DB_PASSWORD=secret_change_me
      # Mail (required for anything user-facing):
      - MAIL_MAILER=smtp
      - MAIL_HOST=smtp.example.com
      - MAIL_PORT=587
      - MAIL_USERNAME=noreply@example.com
      - MAIL_PASSWORD=__smtp_password__
      - MAIL_ENCRYPTION=tls
      - MAIL_FROM_ADDRESS=noreply@example.com
    volumes:
      - data:/var/www/html/storage
    restart: always

  db:
    image: mariadb:11
    environment:
      - MYSQL_RANDOM_ROOT_PASSWORD=true
      - MYSQL_DATABASE=monica
      - MYSQL_USER=usermonica
      - MYSQL_PASSWORD=secret_change_me
    volumes:
      - mysql:/var/lib/mysql
    restart: always

volumes:
  data:
    name: monica_data
  mysql:
    name: monica_mysql
```

Steps:

1. Generate `APP_KEY`: `echo -n 'base64:'; openssl rand -base64 32`
2. Pick a strong MariaDB password and set it in **both** places (matching `DB_PASSWORD` and `MYSQL_PASSWORD`).
3. `docker compose up -d`
4. **Run once after first boot:**

   ```sh
   docker compose exec app php artisan setup:production
   ```

   This caches config/routes and optimizes the app for production. Re-run on every upgrade.

5. Browse `http://<host>:8080` and create the first account.

### FPM variant notes

If you already run nginx, use `monica:<ver>-fpm` instead, mount `/var/www/html/storage` (shared volume) and `/var/www/html/public` (read-only) into an nginx container, proxy `.php` requests to `app:9000`. Upstream nginx example: <https://github.com/monicahq/docker/tree/main/.examples/nginx-proxy>.

## Data & config layout

- `/var/www/html/storage/` — uploads, logs, session cache, key files. **This is your data** — back it up.
- `/var/lib/mysql/` — MariaDB data dir; back up with `mysqldump` or volume snapshot.
- Configuration is env-var driven; no file to manage inside the container.

## Backup

```sh
# App storage
docker run --rm -v monica_data:/data -v "$PWD":/backup alpine \
  tar czf /backup/monica-data-$(date +%F).tgz -C /data .

# Database
docker compose exec db mariadb-dump -u usermonica -p monica | gzip > monica-db-$(date +%F).sql.gz
```

Persist `APP_KEY` alongside your backups — **without it, encrypted fields in the DB cannot be decrypted.**

## Upgrade

1. Check <https://github.com/monicahq/monica/releases> for breaking changes (especially major versions).
2. Bump the image tag in compose; `docker compose pull`.
3. `docker compose up -d` — the entrypoint runs `php artisan migrate` automatically.
4. `docker compose exec app php artisan setup:production` to re-cache.
5. On major upgrades, back up DB + storage first.

## Gotchas

- **`APP_KEY` is irreplaceable.** Treat it like a database encryption key. Losing it orphans encrypted fields.
- **DB_PASSWORD must match** MYSQL_PASSWORD exactly, and both must be set before the mariadb volume is first initialized. Changing MYSQL_PASSWORD after init has no effect — you must edit the existing user or recreate the volume.
- **`setup:production` is not optional** — without it Laravel is in dev mode and performance is noticeably worse.
- **MariaDB 11 → 12 requires explicit upgrade.** Don't silently bump the `mariadb` tag across majors; run `mariadb-upgrade` per upstream MariaDB docs.
- **SMTP required for real use.** First-user registration and admin creation work without mail, but password reset, reminders, and invitations do not.
- **Public S3/compatible storage** needs `FILESYSTEM_DISK=s3` + `AWS_*` env vars; by default uploads go to the local `storage/` volume.
- **Queues are optional** but recommended for heavy reminder loads — add `queue` + `cron` services mirroring the swarm example at <https://github.com/monicahq/docker/blob/main/docker-compose.yml>.
- **Version-4 series is current.** Earlier v2/v3 images on Docker Hub are unmaintained; do not start a new install there.
- **Don't expose port 3306.** The MariaDB service should stay on the compose-internal network.

## Links

- App repo: <https://github.com/monicahq/monica>
- Docker repo: <https://github.com/monicahq/docker>
- Docker Hub: <https://hub.docker.com/_/monica>
- Env var reference: <https://github.com/monicahq/monica/blob/main/.env.example>
- Docs: <https://www.monicahq.com/docs>
- Releases: <https://github.com/monicahq/monica/releases>
