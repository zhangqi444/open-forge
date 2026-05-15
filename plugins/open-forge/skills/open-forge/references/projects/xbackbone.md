---
name: XBackBone
description: "Self-hosted lightweight file manager and ShareX backend. Docker or PHP. PHP + SQLite/MySQL. sergix44/XBackBone. ShareX config generator, multi-storage backends (S3/GCS/Azure/FTP), multi-user, LDAP auth, code highlighting, web player. AGPL."
---

# XBackBone

**Lightweight self-hosted file manager and ShareX backend.** Upload files (images, GIFs, videos, code, documents) via ShareX, curl, or the web UI — get direct shareable links with rich previews (syntax highlighting, video/audio player, PDF viewer, image display). Multi-user with roles and disk quotas. Multiple storage backends: local, AWS S3, Google Cloud, Azure Blob, Dropbox, FTP. LDAP auth.

Built + maintained by **SergiX44 (Sergio Brighenti)**. AGPL-3.0 license.

- Upstream repo: <https://github.com/sergix44/XBackBone>
- Docs: <https://sergix44.github.io/XBackBone/>
- Discord: <https://discord.gg/ksPfXFbhDF>
- Docker Hub: `ghcr.io/sergix44/xbackbone`

## Architecture in one minute

- **PHP 7.3+** backend (Slim framework)
- **SQLite** (default, zero-config) or **MySQL/MariaDB**
- Storage backends: Local, S3, Google Cloud, Azure Blob, Dropbox, FTP(s)
- Port: configured web server (Apache or nginx)
- Docker: `ghcr.io/sergix44/xbackbone`
- Resource: **very low** — PHP + SQLite; near-zero overhead

## Compatible install methods

| Infra        | Runtime                          | Notes                                           |
| ------------ | -------------------------------- | ----------------------------------------------- |
| **Docker**   | `ghcr.io/sergix44/xbackbone`     | **Easiest** — GHCR                              |
| **PHP web**  | Apache/nginx + PHP 7.3+          | Download release zip → web install wizard       |

## Install via Docker

```yaml
services:
  xbackbone:
    image: ghcr.io/sergix44/xbackbone:3.8.1
    container_name: xbackbone
    ports:
      - "80:80"
    volumes:
      - ./storage:/app/storage
      - ./database:/app/resources/database
      - ./logs:/app/logs
    restart: unless-stopped
```

Visit `http://localhost` → web installer wizard.

## Install via PHP (manual)

1. Download latest release ZIP from GitHub releases.
2. Extract to web server document root.
3. Navigate to `http://example.com/xbackbone` → redirects to install page.
4. Complete the install wizard (sets base URL, DB type, admin credentials).
5. (Or manual): copy `config.example.php` → `config.php`, edit, then `php bin/migrate --install`.
6. Default login after manual install: **`admin` / `admin`** — **change immediately**.

## First boot

1. Deploy + run install wizard (Docker auto-runs on first visit).
2. Log in as admin.
3. **Change admin password immediately.**
4. Settings → Users → create additional users with roles/quotas as needed.
5. Settings → ShareX config → download the generated ShareX SXCU file for your instance.
6. Import the SXCU into ShareX → screenshots and recordings upload automatically.
7. Configure storage backend (default: local; optionally S3/GCS/Azure/Dropbox).
8. Put behind TLS.

## Features overview

| Feature | Details |
|---------|---------|
| ShareX backend | Full ShareX upload support; config generator (SXCU); all upload types |
| Web upload | Drag-and-drop upload in the browser |
| File previews | Images, GIF, video player, audio player, PDF viewer, code syntax highlighting |
| Direct links | Discord, Telegram, Facebook OG embeds work out of the box |
| URL shortener | Shorten URLs via ShareX or API |
| Multi-user | User management with roles; disk quota per user |
| Public/private | Per-upload visibility control |
| Tags | Automatic + custom upload tagging |
| Search | Full-text search across uploads |
| Storage backends | Local, S3, GCS, Azure Blob, Dropbox, FTP(s) |
| LDAP auth | Active Directory / OpenLDAP integration |
| Themes | Bootswatch themes (Bootstrap 5) |
| Updates | In-app update system (no CLI needed) |
| Logging | Access and error logging |
| Linux uploader | Custom script generator for \*NIX CLI uploading |
| Telegram sharing | Share uploads directly to Telegram |

## ShareX configuration

1. Log in → Settings → My Account → ShareX config.
2. Download the `.sxcu` file.
3. In ShareX: drag the `.sxcu` onto the window, or: Destinations → Custom Image Uploader → import.
4. Set as active uploader.
5. Done — screenshots, screen recordings, and file captures auto-upload to XBackBone.

## Storage backends

| Backend | Config key | Notes |
|---------|-----------|-------|
| Local | `local` | Default; files in `storage/` dir |
| AWS S3 | `s3` | S3 key, secret, bucket, region |
| Google Cloud | `gcs` | Service account JSON + bucket |
| Azure Blob | `azure` | Connection string + container |
| Dropbox | `dropbox` | OAuth token |
| FTP(s) | `ftp` | Host, user, password, TLS option |

Configure in `config.php` or via the web installer.

## Gotchas

- **Default credentials are `admin`/`admin`.** The manual install leaves these as defaults. The web installer lets you set them. Change immediately either way.
- **Delete `/install` after setup.** Same rule as other PHP apps — the install directory is a security risk if left accessible. Delete `install/` after the wizard completes.
- **AGPL license.** If you serve XBackBone publicly and modify it, you must publish your modifications. The footer attribution must be kept (AGPL "copyright notice").
- **SQLite for personal use; MySQL for multi-user.** SQLite handles hundreds of files with no issues. For teams with many concurrent uploads, switch to MySQL for better concurrency.
- **In-app update.** XBackBone has a built-in update mechanism — admin panel → check for updates → apply. No CLI needed. Works well for simple installs; for Docker, pull the new image instead.
- **Storage backend migration.** Switching storage backends after deployment is a manual process (you need to move files). Choose your backend before starting if possible.
- **Bootswatch themes.** XBackBone uses Bootstrap with Bootswatch themes. Change the active theme in Settings. The dark theme is Darkly; other options include Flatly, Cosmo, etc.
- **`php-ftp` extension for FTP backend.** Required only if using the FTP storage driver. Not installed by default in all PHP setups.

## Backup

```sh
docker compose stop xbackbone
sudo tar czf xbackbone-$(date +%F).tgz storage/ database/ logs/
docker compose start xbackbone
```

## Upgrade

Docker:
```sh
docker compose pull && docker compose up -d
```

Web (in-app): Admin panel → Check for updates → Apply.

## Project health

Active PHP development, GHCR, Discord, multi-storage backends, LDAP, Bootswatch themes, in-app updates. Solo-maintained by SergiX44. AGPL-3.0.

## File-hosting-family comparison

- **XBackBone** — PHP+SQLite, ShareX backend, multi-storage (S3/GCS/Azure/Dropbox/FTP), LDAP, in-app updates, AGPL
- **Zipline** — Node.js, ShareX backend, active development; similar scope; MIT
- **Picsur** — NestJS, image-focused; ⚠️ unmaintained
- **Chibisafe** — Node.js, modern image/file host; ShareX support
- **Lychee** — PHP, photo album management; no ShareX focus

**Choose XBackBone if:** you want a mature, battle-tested ShareX backend with multi-storage (including S3/Azure/GCS), LDAP auth, rich file previews, and multi-user management.

## Links

- Repo: <https://github.com/sergix44/XBackBone>
- Docs: <https://sergix44.github.io/XBackBone/>
- Discord: <https://discord.gg/ksPfXFbhDF>
- GHCR: `ghcr.io/sergix44/xbackbone`
