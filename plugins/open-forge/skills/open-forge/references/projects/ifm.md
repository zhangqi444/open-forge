---
name: ifm
description: IFM (Improved File Manager) recipe for open-forge. Single PHP file web-based file manager. Create, edit, copy, move, upload, download, extract archives, change permissions, image preview. Optional LDAP/password auth. Source: https://github.com/misterunknown/ifm
---

# IFM — Improved File Manager

Single PHP file web-based file manager. Everything in one `index.php` — no install, no database, no dependencies to manage. Features: create/edit/delete/copy/move/download/upload files and directories, upload via URL or drag-and-drop, extract archives (tar, tgz, tar.bz2, zip), change permissions, image preview, optional authentication (plain or LDAP). MIT licensed.

Upstream: <https://github.com/misterunknown/ifm> | Demo: <https://ifmdemo.gitea.de/>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker (official image) | Recommended — Apache + PHP, Alpine-based |
| Any PHP server | Drop single PHP file | Place `index.php` in web root — zero install |
| Linux | Apache/Nginx + PHP 7+ | Manual install |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Data directory to expose | The directory IFM will manage (mounted at `/var/www` in Docker) |
| config | Port | Default: 8080 → 80 |
| config (optional) | UID/GID | Run as specific user (default: www-data, uid/gid 33) |
| config (optional) | Authentication | Disabled by default; enable with `IFM_AUTH=1` |
| config (optional) | Auth credentials | `IFM_AUTH_SOURCE=inline;user:bcrypt-hash` |

## Software-layer concerns

### Architecture

- Single PHP file (`index.php`) — entire app in one file; no framework, no composer, no npm
- PHP 7.0+ required
- Required PHP extensions: bz2, curl, fileinfo, json, mbstring, openssl, phar, posix, zip, zlib
- Optional: ldap extension (for LDAP auth)

### Editions

| Edition | Description |
|---|---|
| Standard (`ifm.php`) | Bundles all JS/CSS dependencies inline |
| CDN (`ifm-cdn.php`) | Loads Bootstrap/jQuery from CDN (smaller file, needs internet) |
| Minified (`*.min.php`) | Gzip-compressed — not recommended unless file size is critical |

### Docker config (env vars)

| Var | Description | Default |
|---|---|---|
| IFM_DOCKER_UID | UID to run as | 33 (www-data) |
| IFM_DOCKER_GID | GID to run as | 33 (www-data) |
| IFM_AUTH | Enable authentication (1=yes) | 0 |
| IFM_AUTH_SOURCE | Auth backend: `inline;user:bcrypt` or `ldap;...` | (none) |
| IFM_ROOT_DIR | Root directory for file manager | /var/www |

Full list of config env vars: https://github.com/misterunknown/ifm/wiki/Configuration

## Install — Docker (recommended)

```bash
# Basic (no auth, exposes /path/to/data)
docker run --rm -d --name ifm \
  -p 8080:80 \
  -v /path/to/data:/var/www \
  ghcr.io/misterunknown/ifm:stable

# With specific UID/GID (match your data dir owner)
docker run --rm -d --name ifm \
  -p 8080:80 \
  -v /path/to/data:/var/www \
  -e IFM_DOCKER_UID=1000 \
  -e IFM_DOCKER_GID=1000 \
  ghcr.io/misterunknown/ifm:stable

# With inline auth (replace hash with bcrypt of your password)
docker run --rm -d --name ifm \
  -p 8080:80 \
  -v /path/to/data:/var/www \
  -e IFM_AUTH=1 \
  -e 'IFM_AUTH_SOURCE=inline;admin:$2y$05$...' \
  ghcr.io/misterunknown/ifm:stable
```

Generate a bcrypt password hash:
```bash
# Using PHP
php -r "echo password_hash('yourpassword', PASSWORD_BCRYPT);"
# Using htpasswd
htpasswd -bnBC 10 "" yourpassword | tr -d ':\n'
```

## Install — Single file (no Docker)

```bash
# Download latest release
curl -LO https://github.com/misterunknown/ifm/releases/latest/download/ifm.php

# Place in your web root (Apache/Nginx must serve PHP)
sudo cp ifm.php /var/www/html/files/index.php

# Access at https://yourserver/files/
```

## Build from source

```bash
git clone https://github.com/misterunknown/ifm.git
cd ifm
make   # builds ifm.php, ifm-cdn.php, and minified variants
```

## Upgrade procedure

Docker:
```bash
docker pull ghcr.io/misterunknown/ifm:stable
docker rm -f ifm
# Re-run docker run command
```

Single file: download new `ifm.php` and replace the old one.

## Gotchas

- No authentication by default — IFM exposes full filesystem access to the mounted directory without auth. Always enable `IFM_AUTH=1` or protect with a reverse proxy (basic auth / IP restriction) before exposing to any network.
- UID/GID mismatch: if the container runs as www-data (uid 33) but your data dir is owned by another user, file operations will fail with permission errors. Set `IFM_DOCKER_UID`/`IFM_DOCKER_GID` to match your data directory owner.
- `root_dir` is locked to `/var/www` by default — IFM cannot navigate above this directory. To expose a different path, mount it at `/var/www` or configure `IFM_ROOT_DIR`.
- The `--rm` flag in the docker run examples removes the container on stop — omit it or use `-d --restart unless-stopped` for persistent deployment.
- Minified versions (`*.min.php`) are gzip-compressed PHP files — most web servers won't execute them directly without special config; use the standard edition instead.

## Links

- Source: https://github.com/misterunknown/ifm
- Configuration wiki: https://github.com/misterunknown/ifm/wiki/Configuration
- Demo: https://ifmdemo.gitea.de/
- Releases: https://github.com/misterunknown/ifm/releases/latest
