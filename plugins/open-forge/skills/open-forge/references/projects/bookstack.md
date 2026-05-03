---
name: BookStack
description: Self-hosted wiki / documentation platform organized as books → chapters → pages. Laravel + MySQL/MariaDB. Designed for readable, opinionated team docs.
---

# BookStack

BookStack is a PHP/Laravel app for storing internal documentation in a book-like hierarchy (shelves → books → chapters → pages). Rich WYSIWYG + markdown editors, diagrams.net + Drawio integration, comments, search, multi-factor auth, LDAP/SAML/OIDC SSO. MIT-licensed.

- Upstream repo: <https://codeberg.org/bookstack/bookstack> (**primary — GitHub is archived mirror**)
- Install docs: <https://www.bookstackapp.com/docs/admin/installation/>
- Official project does NOT publish a Docker image or compose file directly — the community-standard image is **`lscr.io/linuxserver/bookstack`** (LinuxServer.io). BookStack documentation also recommends this image.

## Compatible install methods

| Infra              | Runtime                                | Notes                                                                |
| ------------------ | -------------------------------------- | -------------------------------------------------------------------- |
| Single VM          | Docker + Compose (linuxserver image)   | **Recommended self-host path.**                                       |
| Single VM          | Ubuntu install script                  | Upstream ships `installation-ubuntu-22.04.sh` — Apache+PHP+MySQL     |
| Bare metal         | Manual Laravel install                 | Works on any LAMP stack; docs walk through nginx + php-fpm           |
| Kubernetes         | Community Helm charts                  | No upstream chart                                                    |

## Inputs to collect

| Input               | Example                                | Phase     | Notes                                                              |
| ------------------- | -------------------------------------- | --------- | ------------------------------------------------------------------ |
| `APP_URL`           | `https://wiki.example.com`             | Runtime   | **Full origin including scheme.** Must match external URL exactly  |
| `APP_KEY`           | `base64:<32 random bytes>`             | Runtime   | Laravel app key; permanent                                         |
| DB host/name/user/pass | `db:3306 / bookstack / bookstack / <pw>` | Runtime | Matches MariaDB service's env                                       |
| `PUID` / `PGID`     | `1000` / `1000`                        | Runtime   | Match host owner of `/config` bind mount                            |
| `TZ`                | `America/Denver`                       | Runtime   | Affects log timestamps + recurring tasks                            |
| SMTP config         | any provider                           | Runtime   | Needed for invites, password reset; edit via `.env`                 |

## Install via Docker Compose (linuxserver image + MariaDB)

Adapted from <https://github.com/linuxserver/docker-bookstack#docker-compose-recommended>:

```yaml
services:
  bookstack:
    image: lscr.io/linuxserver/bookstack:26.03.4   # pin; track releases at the link below
    container_name: bookstack
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - APP_URL=https://wiki.example.com
      - APP_KEY=base64:REPLACE_ME_32_BYTES
      - DB_HOST=db
      - DB_PORT=3306
      - DB_USERNAME=bookstack
      - DB_PASSWORD=STRONG_DB_PASSWORD
      - DB_DATABASE=bookstack
      - QUEUE_CONNECTION=database   # optional but recommended for background tasks
    volumes:
      - ./bookstack/config:/config
    ports:
      - 6875:80
    restart: unless-stopped
    depends_on:
      - db

  db:
    image: lscr.io/linuxserver/mariadb:11.4
    container_name: bookstack-db
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
      - MYSQL_ROOT_PASSWORD=ROOT_PASSWORD_CHANGE_ME
      - MYSQL_DATABASE=bookstack
      - MYSQL_USER=bookstack
      - MYSQL_PASSWORD=STRONG_DB_PASSWORD
    volumes:
      - ./bookstack/db:/config
    restart: unless-stopped
```

Steps:

1. `APP_KEY`: `echo -n 'base64:'; openssl rand -base64 32` (or run `docker compose run --rm bookstack php /app/www/artisan key:generate --show` inside a running container to let Laravel generate it, then paste into env).
2. `docker compose up -d`.
3. Browse `http://<host>:6875` (or proxy `APP_URL` → `bookstack:80`). Default login is `admin@admin.com` / `password` — **log in and change both immediately.**

### Image tags

`lscr.io/linuxserver/bookstack` — tag list at <https://github.com/linuxserver/docker-bookstack/pkgs/container/bookstack>. BookStack version numbers look like `25.02.4`. The linuxserver image tag roughly tracks upstream.

## Data & config layout

- `/config/` on host → mounts BookStack's `.env` plus uploads: `/config/www/uploads/`, `/config/www/storage/`, etc.
- `/config/www/.env` — Laravel config. For email, LDAP, SAML, OIDC — edit this file; env-var passthrough from the container is supported for the common DB + URL vars only.
- `/config/keys/` — the linuxserver image persists APP_KEY and certs here
- MariaDB `/config/` on host → `/var/lib/mysql` plus `my.cnf` overrides

## Backup

```sh
# Full config + uploads
docker run --rm -v "$PWD/bookstack/config":/src -v "$PWD":/backup alpine \
  tar czf /backup/bookstack-config-$(date +%F).tgz -C /src .

# Database
docker compose exec -T db mariadb-dump -u bookstack -p"$DB_PASSWORD" bookstack | gzip > bookstack-db-$(date +%F).sql.gz
```

Keep `APP_KEY` in your secret store — needed to decrypt tokens and session data on restore.

## Upgrade

1. Read release notes: <https://codeberg.org/bookstack/bookstack/releases> — watch for breaking Laravel migrations.
2. Bump the `lscr.io/linuxserver/bookstack` tag.
3. `docker compose pull && docker compose up -d`.
4. The entrypoint runs `php artisan migrate` on boot. Back up before major jumps (e.g. v24 → v25).

## Gotchas

- **`APP_URL` must match external URL exactly** (scheme + host + no trailing slash). Wrong value = login redirects break, asset URLs malformed, logout loops.
- **Default admin credentials are public.** Change them immediately after first boot — automated scanners know `admin@admin.com / password`.
- **Uploads can grow large.** Attachments + images live under `/config/www/uploads/` — plan disk + backups accordingly.
- **SSO / LDAP requires editing `.env`**, not environment variables. The linuxserver image only passes a subset of envs through; for everything else edit `/config/www/.env` and restart the container.
- **Reverse proxy: preserve `X-Forwarded-Proto`.** Without it Laravel generates `http://` URLs even behind HTTPS, breaking assets and cookies.
- **MariaDB 11.x recommended** (MySQL 8 also works). MariaDB 10.5 and below are unsupported in recent BookStack versions.
- **No upstream Docker image.** Community-maintained linuxserver image is the de facto standard; if it stops being maintained, upstream's install guide (Ubuntu script) is the fallback.
- **Email is off by default.** Self-service password reset and invites silently fail until SMTP is configured in `.env`.
- **Codeberg is the primary git host** (full migration completed 2026-04). GitHub is now an archived mirror. Issues and PRs happen on Codeberg (<https://codeberg.org/bookstack/bookstack>).
- **`QUEUE_CONNECTION=database`** is recommended — without it, long tasks (PDF exports, large imports) run synchronously and time out.
- **APP_KEY rotation invalidates all sessions and encrypted fields.** Generate once, store forever.

## Links

- Docs: <https://www.bookstackapp.com/docs>
- Install guide (all methods): <https://www.bookstackapp.com/docs/admin/installation/>
- Docker README (linuxserver): <https://github.com/linuxserver/docker-bookstack>
- Upstream `.env.example`: <https://codeberg.org/bookstack/bookstack/raw/branch/development/.env.example.complete>
- Releases: <https://codeberg.org/bookstack/bookstack/releases>
- GitHub mirror (archived): <https://github.com/BookStackApp/BookStack>
- Community discussions: <https://community.bookstackapp.com/>
