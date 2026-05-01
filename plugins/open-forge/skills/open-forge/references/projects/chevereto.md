---
name: Chevereto
description: "Self-hosted image and video sharing platform. PHP + MariaDB. chevereto/chevereto. Image/video uploads, user profiles, albums, categories, EXIF, ShareX support, 2FA, REST API. Free edition AGPL-3.0 (personal use); Pro/Lite commercial editions with additional features. Since 2007."
---

# Chevereto

**Self-hosted image and video sharing platform — the OG self-hosted media sharing software since 2007.** Create your own media sharing website with user profiles, albums, categories, direct links, EXIF data, ShareX support, 2FA, and a full REST API. Available as a free personal-use edition (AGPL-3.0) and commercial Pro/Lite editions with advanced features.

Built + maintained by **Rodolfo Berríos Arce**. Free edition: AGPL-3.0. Pro/Lite: commercial.

- Upstream repo: <https://github.com/chevereto/chevereto>
- Docker Hub: `chevereto/chevereto`
- Docs: <https://v4-docs.chevereto.com>
- Live demo: <https://demo.chevereto.com>

## Architecture in one minute

- **PHP** web application (requires PHP 8+)
- **MariaDB** (or MySQL) — external database required
- **Docker** image bundles PHP + web server; MariaDB runs as a separate service
- Port **80** internal; needs a reverse proxy for HTTPS
- Volumes: `/var/www/html/images/` (user-uploaded media) + `/_assets/` (application assets)
- Resource: **medium** — PHP + MariaDB; storage depends heavily on uploaded media volume

## Compatible install methods

| Infra      | Runtime                                  | Notes                                                 |
| ---------- | ---------------------------------------- | ----------------------------------------------------- |
| **Docker** | `chevereto/chevereto` + MariaDB          | **Primary** — two-container stack                     |
| VPS        | PHP + web server + MariaDB               | Manual install via script                             |
| cPanel     | PHP app + MySQL                          | Via [cPanel guide](https://v4-docs.chevereto.com/guides/cpanel/) |
| Plesk      | PHP app + MySQL                          | Via [Plesk guide](https://v4-docs.chevereto.com/guides/plesk/) |

## Install via Docker Compose (free edition)

```yaml
services:
  database:
    image: mariadb:10.11
    restart: always
    volumes:
      - database:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: change_this_root_password
      MYSQL_DATABASE: chevereto
      MYSQL_USER: chevereto
      MYSQL_PASSWORD: change_this_user_password
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-u", "root", "-p$${MYSQL_ROOT_PASSWORD}"]
      interval: 15s
      timeout: 30s
      retries: 5
      start_period: 15s

  chevereto:
    image: chevereto/chevereto:latest
    restart: always
    depends_on:
      database:
        condition: service_healthy
    volumes:
      - storage:/var/www/html/images/
      - assets:/var/www/html/_assets/
    ports:
      - "80:80"
    environment:
      CHEVERETO_DB_HOST: database
      CHEVERETO_DB_USER: chevereto
      CHEVERETO_DB_PASS: change_this_user_password
      CHEVERETO_DB_PORT: 3306
      CHEVERETO_DB_NAME: chevereto
      CHEVERETO_HOSTNAME: localhost         # Set to your domain
      CHEVERETO_HOSTNAME_PATH: /
      CHEVERETO_HTTPS: 0                    # Set to 1 behind HTTPS reverse proxy
      CHEVERETO_MAX_POST_SIZE: 2G
      CHEVERETO_UPLOAD_MAX_FILESIZE: 2G
      CHEVERETO_ASSET_STORAGE_TYPE: local
      CHEVERETO_ASSET_STORAGE_URL: http://localhost/_assets/
      CHEVERETO_ASSET_STORAGE_BUCKET: /var/www/html/_assets/

volumes:
  database:
  storage:
  assets:
```

```bash
docker compose up -d
```

Visit `http://your-server/` and complete the installer.

## Key environment variables

| Variable | Notes |
|----------|-------|
| `CHEVERETO_DB_HOST` | MariaDB/MySQL hostname |
| `CHEVERETO_DB_USER` | Database username |
| `CHEVERETO_DB_PASS` | Database password |
| `CHEVERETO_DB_PORT` | Database port (default: 3306) |
| `CHEVERETO_DB_NAME` | Database name |
| `CHEVERETO_HOSTNAME` | Your domain name (without protocol) |
| `CHEVERETO_HOSTNAME_PATH` | Path prefix (use `/` for root) |
| `CHEVERETO_HTTPS` | `1` when behind HTTPS reverse proxy |
| `CHEVERETO_MAX_POST_SIZE` | Maximum upload size (e.g. `2G`) |
| `CHEVERETO_UPLOAD_MAX_FILESIZE` | PHP upload file size limit (match `MAX_POST_SIZE`) |
| `CHEVERETO_ASSET_STORAGE_TYPE` | `local` or cloud storage (`s3`, `azure`, etc.) — Pro feature |

## Edition comparison

| Feature | Free | Lite | Pro |
|---------|------|------|-----|
| Image & video uploads | ✅ | ✅ | ✅ |
| ShareX support | ✅ | ✅ | ✅ |
| 360° images | ✅ | ✅ | ✅ |
| User profiles + albums | ✅ | ✅ | ✅ |
| Categories, labels | ✅ | ✅ | ✅ |
| EXIF data | ✅ | ✅ | ✅ |
| REST API | ✅ | ✅ | ✅ |
| 2FA | ✅ | ✅ | ✅ |
| Docker support | ✅ | ✅ | ✅ |
| Watermarks | ❌ | — | ✅ |
| Multi-language | ❌ | — | ✅ |
| Social network features | ❌ | — | ✅ |
| S3/cloud storage | ❌ | — | ✅ |
| License | AGPL-3.0 | Commercial | Commercial |

## Gotchas

- **Free edition = personal use only.** The free edition is AGPL-3.0 and explicitly intended for personal usage; it lacks many features found in commercial editions. For commercial use, purchase Pro or Lite.
- **AGPL-3.0.** If you deploy modified Chevereto free edition as a network service, you must publish your modifications under AGPL-3.0.
- **Reverse proxy for HTTPS.** The Docker image serves HTTP on port 80. Always put a TLS-terminating reverse proxy (Nginx, Caddy, Traefik) in front, and set `CHEVERETO_HTTPS=1`.
- **`CHEVERETO_HOSTNAME` must match.** Set this to your actual domain. Incorrect values break URL generation, image links, and API responses.
- **Upload limits must match.** `CHEVERETO_MAX_POST_SIZE` and `CHEVERETO_UPLOAD_MAX_FILESIZE` must be equal or uploads will be silently limited.
- **Pro Docker image.** The Pro edition Docker image requires building from the `chevereto/docker` repo (requires license key) — it is **not** available as a pre-built public image.
- **Storage volumes.** The `images/` volume stores all uploaded media. Keep it backed up and sized for your upload volume.

## Backup

```sh
# Back up MariaDB
docker exec $(docker compose ps -q database) mysqldump -u root -pchange_this_root_password chevereto > chevereto-db-$(date +%F).sql

# Back up media and assets
tar czf chevereto-storage-$(date +%F).tar.gz \
  $(docker volume inspect <project>_storage --format '{{ .Mountpoint }}') \
  $(docker volume inspect <project>_assets --format '{{ .Mountpoint }}')
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

In-app upgrades also available via `/dashboard`.

## Project health

Long-running project (since 2007), active development, AGPL-3.0 free edition + commercial Pro.

## Image-hosting-family comparison

- **Chevereto** — PHP/MariaDB, full media sharing platform, user accounts, API; AGPL-3.0 (free) / commercial
- **Lychee** — PHP/MariaDB, photo management gallery, albums; MIT
- **Piwigo** — PHP/MySQL, photo gallery, albums, plugins; GPL-2.0
- **Immich** — Node/ML, photo/video backup (Google Photos-like), AI search; AGPL-3.0
- **Photoprism** — Go, AI-powered photo management; AGPL-3.0

**Choose Chevereto if:** you want to host an image/video sharing *platform* (multiple users, public profiles, albums, direct links, API) — like running your own Imgur.

## Links

- Repo: <https://github.com/chevereto/chevereto>
- Docs: <https://v4-docs.chevereto.com>
- Docker guide: <https://v4-docs.chevereto.com/guides/docker/>
- Pure Docker guide: <https://v4-docs.chevereto.com/guides/docker/pure-docker>
- Demo: <https://demo.chevereto.com>
