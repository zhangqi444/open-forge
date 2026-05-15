---
name: seafile-ce
description: Recipe for Seafile Community Edition — open-source file sync and sharing server with client-side encryption, desktop sync, and collaboration features.
---

# Seafile Community Edition

Open-source cloud storage and file sync server. Features: selective folder sync, delta transfers, client-side library encryption, version history, file sharing (links with password protection), built-in collaborative docs (SeaDoc), wiki, OnlyOffice/Collabora integration, and extensible file metadata. Uses its own sync protocol (not WebDAV-only). Upstream: <https://github.com/haiwen/seafile>. Server: <https://github.com/haiwen/seafile-server>. Docs: <https://manual.seafile.com>. License: AGPLv3 (CE). ~12K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://manual.seafile.com/deploy_docker/ce_docker/> | Yes | Recommended; official multi-container stack |
| Linux native install | <https://manual.seafile.com/deploy/using_mysql/> | Yes | Bare-metal on Ubuntu/Debian with MySQL/MariaDB |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | Public URL for Seafile? | HTTP(S) URL with port or domain (e.g. https://seafile.example.com) | Required — used in config and file links |
| software | Admin email? | Email address | First-run setup |
| software | Admin password? | Sensitive string | First-run setup |
| software | MySQL/MariaDB root password? | Sensitive string | Docker Compose |
| software | MySQL Seafile DB password? | Sensitive string | Docker Compose |
| software | Time zone? | TZ string | Optional |

## Software-layer concerns

### Docker Compose

```yaml
services:
  db:
    image: mariadb:10.11
    container_name: seafile-mysql
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: db_dev   # change this
      MYSQL_LOG_CONSOLE: "true"
      MARIADB_AUTO_UPGRADE: "1"
    volumes:
      - seafile-mysql:/var/lib/mysql

  memcached:
    image: memcached:1.6.29
    container_name: seafile-memcached
    restart: unless-stopped
    entrypoint: memcached -m 256

  seafile:
    image: seafileltd/seafile-mc:13.0-latest
    container_name: seafile
    restart: unless-stopped
    ports:
      - "80:80"
      # - "443:443"   # uncomment for HTTPS
    volumes:
      - seafile-data:/shared
    environment:
      DB_HOST: db
      DB_ROOT_PASSWD: db_dev          # must match above
      TIME_ZONE: Etc/UTC
      SEAFILE_ADMIN_EMAIL: admin@example.com
      SEAFILE_ADMIN_PASSWORD: asecret   # change this
      SEAFILE_SERVER_LETSENCRYPT: "false"
      SEAFILE_SERVER_HOSTNAME: seafile.example.com
    depends_on:
      - db
      - memcached

volumes:
  seafile-mysql:
  seafile-data:
```

Docs: <https://manual.seafile.com/deploy_docker/ce_docker/>

### Key environment variables

| Variable | Description |
|---|---|
| DB_HOST | MariaDB/MySQL container hostname |
| DB_ROOT_PASSWD | MySQL root password (must match db service) |
| SEAFILE_SERVER_HOSTNAME | Public hostname (without protocol) |
| SEAFILE_ADMIN_EMAIL | Initial admin email |
| SEAFILE_ADMIN_PASSWORD | Initial admin password |
| SEAFILE_SERVER_LETSENCRYPT | Auto-issue Let's Encrypt cert (true/false) |
| TIME_ZONE | TZ identifier |

### Data volume layout (/shared)

| Path | Purpose |
|---|---|
| /shared/seafile/conf/ | Configuration files (seahub_settings.py, seafile.conf, ccnet.conf) |
| /shared/seafile/seafile-data/ | Repository object storage |
| /shared/seafile/logs/ | Application logs |
| /shared/seahub-data/ | User avatars, thumbnail cache |

### Reverse proxy (Nginx) for HTTPS

See the official Nginx config template at <https://manual.seafile.com/deploy/https_with_nginx/>. Key headers:

```nginx
location / {
    proxy_pass http://127.0.0.1:8000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Host $server_name;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 1200s;
    client_max_body_size 0;
    access_log /var/log/nginx/seahub.access.log;
    error_log /var/log/nginx/seahub.error.log;
}
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the migration notes for each version at <https://manual.seafile.com/upgrade/> — some upgrades require running migration scripts.

## Gotchas

- `SERVICE_URL` and `FILE_SERVER_ROOT`: must be set correctly in seahub_settings.py or via environment, otherwise file downloads and upload links break.
- `client_max_body_size 0`: required in Nginx to allow large file uploads.
- Pro vs CE: only CE is open-source (AGPL). Pro edition adds Office Web App integration, S3/Ceph backends, audit logs, and more — requires a license.
- Encryption: library encryption is client-side (keys never leave the client). Server admin cannot read encrypted libraries.
- Desktop clients: available for Windows, macOS, Linux at <https://www.seafile.com/en/download/>.
- Seahub (web UI) + Seafile server (daemon) are separate components — both run inside the official Docker image.

## Links

- GitHub (server): <https://github.com/haiwen/seafile-server>
- GitHub (sync client daemon): <https://github.com/haiwen/seafile>
- Docker install docs: <https://manual.seafile.com/deploy_docker/ce_docker/>
- Manual: <https://manual.seafile.com>
- Docker Hub: <https://hub.docker.com/r/seafileltd/seafile-mc>
- Downloads (desktop/mobile clients): <https://www.seafile.com/en/download/>
