---
name: tiny-file-manager
description: Tiny File Manager recipe for open-forge. Lightweight single-PHP-file web-based file manager. Self-hosted via PHP server or Docker. Source: https://github.com/prasathmani/tinyfilemanager. Wiki: https://github.com/prasathmani/tinyfilemanager/wiki.
---

# Tiny File Manager

Minimalist, single-file PHP web-based file manager. Drop one PHP file into any web-accessible directory to get file upload/download/edit/compress/extract, a built-in code editor (Cloud9 IDE), multi-language support, and user-level access control. Upstream: <https://github.com/prasathmani/tinyfilemanager>. Wiki / docs: <https://github.com/prasathmani/tinyfilemanager/wiki>.

> **Security caution (upstream):** Do not leave this exposed on public-facing servers indefinitely. Change default credentials immediately. Consider IP-restricting access. Remove or disable when not in active use.

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| VPS / bare metal | PHP 7.2+ with Apache/NGINX | Drop tinyfilemanager.php into webroot; zero dependencies |
| VPS / bare metal | Docker Compose | Official Docker image: tinyfilemanager/tinyfilemanager |
| Shared hosting | PHP CGI | Single file; works on any PHP host |
| Local dev | php -S localhost:8080 tinyfilemanager.php | Built-in PHP server; no webserver needed |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Docker or bare PHP?" | Drives setup steps |
| credentials | "Admin username and password?" | Default admin/admin@123 — must change before use |
| credentials | "Read-only user username and password?" | Default user/12345 — change or disable |
| paths | "Which directory should be the root for the file manager?" | Maps to $root_path in config or Docker volume |
| auth | "Restrict to specific IP(s)?" | Optional; set $ip_whitelist in config |

## Software-layer concerns

- Config: edit variables at top of tinyfilemanager.php, or use a separate config.php file placed in the same directory
- Passwords: hashed with password_hash(); generate new hashes at https://tinyfilemanager.github.io/docs/pwd.html
- Default credentials (MUST CHANGE): admin/admin@123, user/12345
- Auth: set $use_auth = true (default); set to false to disable login (dangerous on any network)
- Ports: PHP built-in server uses any port you specify; Docker default 8080->80
- User root dirs: each user can be confined to a subdirectory via $auth_users config

### Docker Compose

```yaml
services:
  tinyfilemanager:
    image: tinyfilemanager/tinyfilemanager:latest
    container_name: tinyfilemanager
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./data:/var/www/html/data
      - ./config.php:/var/www/html/config.php
    environment:
      TZ: UTC
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost/"]
      interval: 30s
      timeout: 10s
      retries: 3
```

Mount config.php for custom settings (credentials, paths, etc.). If no config.php, defaults apply (insecure credentials).

### Bare PHP (no Docker)

```bash
# Download single file
curl -O https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
# Optionally add config.php alongside it
# Serve
php -S 0.0.0.0:8080 tinyfilemanager.php
```

Or drop tinyfilemanager.php into your Apache/NGINX webroot and open in browser.

### Minimal config.php (change passwords)

```php
<?php
$use_auth = true;
$auth_users = [
    'admin' => password_hash('MY_SECURE_ADMIN_PASS', PASSWORD_DEFAULT),
    'user'  => password_hash('MY_SECURE_USER_PASS', PASSWORD_DEFAULT),
];
$root_path = '/var/www/html/data';
$root_url  = '';
```

## Upgrade procedure

1. Download new tinyfilemanager.php: curl -O https://raw.githubusercontent.com/prasathmani/tinyfilemanager/master/tinyfilemanager.php
2. Replace old file; your config.php is separate and unaffected
3. Docker: docker compose pull && docker compose up -d

## Gotchas

- **Default credentials are published**: admin/admin@123 is in the README. Anyone who finds your URL can log in. Change them before exposing to any network.
- **Single PHP file**: No database, no install — but also no audit log, no 2FA, and limited access control. Not suited for sensitive production file management.
- **PHP version**: Requires PHP 5.5+ (PHP 8+ recommended). Fileinfo, iconv, zip, tar, and mbstring extensions strongly recommended for full functionality.
- **config.php placement**: Must be in the same directory as tinyfilemanager.php; it is auto-included if present.
- **HTTPS**: Always serve over HTTPS; credentials are sent as POST data. Use NGINX/Caddy in front for TLS.
- **Cloud9 IDE**: The built-in editor is capable of editing files directly on the server. Restrict user access to prevent accidental edits to server config files.
- **Offline mode**: For air-gapped deployments, use the offline branch which bundles all CDN assets locally.

## Links

- Upstream repo: https://github.com/prasathmani/tinyfilemanager
- Wiki / full docs: https://github.com/prasathmani/tinyfilemanager/wiki
- Docker Hub: https://hub.docker.com/r/tinyfilemanager/tinyfilemanager
- Docker deploy guide: https://github.com/prasathmani/tinyfilemanager/wiki/Deploy-by-Docker
- Password hash generator: https://tinyfilemanager.github.io/docs/pwd.html
- Releases: https://github.com/prasathmani/tinyfilemanager/releases
