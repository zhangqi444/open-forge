---
name: jirafeau
description: Jirafeau recipe for open-forge. One-click file sharing — select file, upload, get a link. PHP, no database required. Source: https://gitlab.com/jirafeau/Jirafeau
---

# Jirafeau

A KISS (Keep It Simple, Stupid) one-click file sharing web app. Select a file, upload it, share a link. Optional password protection, expiry, self-destruct on first download, and data encryption. PHP only — no database required. AGPL-3.0 licensed. Upstream: <https://gitlab.com/jirafeau/Jirafeau>. Demo: <https://jirafeau.net/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux VPS | Docker Compose | Official image from GitLab Container Registry |
| Any Linux VPS | PHP + Apache/NGINX | Classic LAMP/LEMP stack; no database needed |
| Shared hosting | PHP | Works on basic PHP hosting if file permissions allow |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain for Jirafeau?" | FQDN | e.g. share.example.com |
| "Max upload file size (MB)?" | Number | Controlled by PHP post_max_size for native; config for Docker |
| "Require password to upload?" | Yes / No | Optional; restricts who can upload |
| "Default link expiry?" | none / day / week / month / year | Default is none (no expiry) |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Admin password?" | String (sensitive) | For the /admin.php interface; auto-generated if using Docker |
| "Enable data encryption at rest?" | Yes / No | Encrypts stored files; slightly slower |
| "Storage path for uploaded files?" | Directory path | Must persist; default inside app dir |

## Software-Layer Concerns

- **No database**: Files stored as flat files in the configured data directory. Keep this directory on a persistent volume.
- **File deduplication**: Jirafeau stores duplicate files only once but generates separate download links per upload.
- **Admin interface**: Available at /admin.php — lists all files, allows deletion, shows storage usage.
- **Expiry cleanup**: A CLI script (`lib/expire.php`) must be run via cron to delete expired files: `php /path/to/jirafeau/lib/expire.php`
- **Config file**: `lib/config.local.php` overrides defaults from `lib/config.original.php`. Created by the install wizard or manually.
- **PHP requirements**: PHP >= 7.4. No database, no mail server required.
- **Encryption**: Optional AES encryption of stored files — key derived from a server-side secret. Encrypted files are not readable without the server.

## Deployment

### Docker Compose

```yaml
services:
  jirafeau:
    image: registry.gitlab.com/jirafeau/jirafeau:latest
    ports:
      - "8080:80"
    volumes:
      - jirafeau_data:/www/data
    environment:
      ADMIN_PASSWORD: "your-admin-password"  # or leave blank for auto-generated
      # STYLE: default
      # MAX_FILE_SIZE: 0  # 0 = unlimited
    restart: unless-stopped

volumes:
  jirafeau_data:
```

Check container logs for auto-generated admin password if not set: `docker compose logs jirafeau`

Then access admin at http://<host>:8080/admin.php

### Native PHP (Apache)

```bash
git clone https://gitlab.com/jirafeau/Jirafeau.git /var/www/jirafeau
chown -R www-data:www-data /var/www/jirafeau
# Visit https://your-domain/jirafeau/ — install wizard runs automatically
```

Configure Apache vhost or NGINX server block pointing to /var/www/jirafeau.

### Cron for expiry cleanup

```bash
# Add to www-data crontab or /etc/cron.daily
php /var/www/jirafeau/lib/expire.php
```

## Upgrade Procedure

1. Docker: `docker compose pull && docker compose up -d` — data volume persists.
2. Native: `git pull` in the app directory (or replace with new release archive). Config in `lib/config.local.php` is not overwritten by git pull.
3. Always backup the data directory before upgrading.

## Gotchas

- **Large file uploads**: PHP's `upload_max_filesize` and `post_max_size` limits apply for native installs — adjust in php.ini. The HTML5 chunked upload bypasses post_max_size for the file itself but not the whole request.
- **No user accounts**: Jirafeau has no user management — it's upload-by-link, optionally with a single upload password.
- **Flat file storage**: Very large numbers of files can slow down the admin interface and cleanup script. Fine for typical use.
- **Fork of archived upstream**: This GitLab repo is a continuation fork of the original mojo42/Jirafeau (now archived). Verify the active fork at https://gitlab.com/jirafeau/Jirafeau before deploying.
- **Encrypted files not portable**: Files encrypted with Jirafeau's server-side key cannot be decrypted without that same key — include it in your backup strategy.

## Links

- Source: https://gitlab.com/jirafeau/Jirafeau
- Demo: https://jirafeau.net/
- Docker image: registry.gitlab.com/jirafeau/jirafeau:latest
- Docker docs: https://gitlab.com/jirafeau/Jirafeau/-/blob/master/docker/README.md
- Config reference: https://gitlab.com/jirafeau/Jirafeau/-/blob/master/lib/config.original.php
