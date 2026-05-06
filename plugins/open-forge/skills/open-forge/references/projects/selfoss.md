---
name: selfoss
description: selfoss recipe for open-forge. Covers PHP web server install (the only upstream-documented method). selfoss is a multipurpose RSS reader and feed aggregation web app written in PHP — runs on any PHP-capable web server.
---

# selfoss

Multipurpose RSS reader and feed aggregation web application. Lets you follow updates from websites, social networks, and other platforms in a single place. Written in PHP, runs on virtually any web host. Upstream: <https://github.com/fossar/selfoss>. Website: <https://selfoss.aditu.de>.

**License:** GPL-3.0 · **Language:** PHP · **Default port:** 80/443 (via web server) · **Stars:** ~2,500

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| PHP on nginx | <https://selfoss.aditu.de> | ✅ (implied — PHP app) | Recommended; nginx + PHP-FPM on any Linux server. |
| PHP on Apache | <https://selfoss.aditu.de> | ✅ (implied — ships .htaccess) | Apache + mod_php or PHP-FPM; .htaccess files required. |
| Community Docker image | <https://hub.docker.com/r/hardware/selfoss> | Community-maintained | For Docker environments — not in upstream install docs. |
| Shared hosting | <https://github.com/fossar/selfoss/releases> | ✅ | Upload the release zip to any PHP-capable shared host via FTP/SFTP. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Which web server — nginx or Apache?" | AskUserQuestion | Determines server config section. |
| domain | "What domain will selfoss be served on?" | Free-text | All methods. |
| database | "Which database — SQLite (default, zero config) or MySQL/PostgreSQL?" | AskUserQuestion | Determines config.ini database section. |
| database_creds | "Database host, name, user, and password?" | Free-text (sensitive) | MySQL/PostgreSQL only. |
| php | "PHP version available? (7.4+ required, 8.x recommended)" | Free-text | All methods — verify before install. |
| cron | "How should feed updates be triggered — cron job or systemd timer?" | AskUserQuestion: cron / systemd | Required for automatic feed updates. |

## Install

Reference: <https://github.com/fossar/selfoss#installation>

### 1. Download and extract

```bash
# Download the latest stable release from:
# https://github.com/fossar/selfoss/releases
wget https://github.com/fossar/selfoss/releases/latest/download/selfoss.zip
unzip selfoss.zip -d /var/www/selfoss
cd /var/www/selfoss
```

### 2. Set directory permissions

```bash
chown -R www-data:www-data /var/www/selfoss
chmod -R 755 /var/www/selfoss

# These directories must be writable by the web server:
chmod -R 775 data/cache data/favicons data/logs data/thumbnails data/sqlite
```

### 3. Configure selfoss

```bash
cp config-example.ini config.ini
nano config.ini
```

Minimal `config.ini` for SQLite (default):

```ini
; selfoss configuration
; No database config needed for SQLite (default)

; Optional: set a salt for password hashing
salt=change_this_to_a_random_string

; Optional: default items per page
items=50
```

For MySQL/PostgreSQL:

```ini
db_type=mysql
db_host=localhost
db_database=selfoss
db_username=selfossuser
db_password=yourpassword
db_port=3306
```

### 4. Configure nginx

```nginx
server {
    listen 443 ssl;
    server_name rss.example.com;

    root /var/www/selfoss;
    index index.php;

    # Block access to data directory
    location ^~ /data {
        deny all;
    }

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
    }
}
```

### 5. Set up feed updates (cron)

```bash
# Edit root or www-data crontab:
crontab -u www-data -e

# Add line to update feeds every 5 minutes:
*/5 * * * * curl -s "https://rss.example.com/update"

# Or run the CLI updater directly:
*/5 * * * * php /var/www/selfoss/cliupdate.php
```

Or with a systemd timer (see upstream docs for unit file template).

### 6. Set a login password (optional)

selfoss supports optional password protection. Add to `config.ini`:

```ini
username=admin
password=<bcrypt hash — generate via selfoss web UI or CLI>
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| PHP version | Requires PHP 7.4+; PHP 8.x recommended. Extensions: pdo, pdo_sqlite (or pdo_mysql/pdo_pgsql), curl, json, xml, mbstring. |
| Database | Default: SQLite at data/sqlite/selfoss.db (zero config). MySQL/PostgreSQL for multi-user or higher-load setups. |
| config.ini | Must not be deleted on upgrade. Contains all runtime configuration. |
| data/ directory | Persists cache, favicons, thumbnails, SQLite DB. Never delete on upgrade. Back up before updating. |
| .htaccess | Required for Apache; uploaded alongside app files. Handles URL rewriting. |
| Feed update cron | Without a cron job or systemd timer, feeds will not update automatically. |
| Auth | Optional HTTP auth via config.ini username/password. No multi-user support — single admin account. |
| Plugins/spouts | selfoss supports custom spouts (feed sources) placed in spouts/ directory. |

## Upgrade procedure

Reference: <https://github.com/fossar/selfoss#update>

```bash
# 1. Backup
cp -r /var/www/selfoss/data ~/selfoss-data-backup-$(date +%Y%m%d)
# Also backup your database if using MySQL/PostgreSQL

# 2. Download new release
wget https://github.com/fossar/selfoss/releases/latest/download/selfoss.zip
unzip selfoss.zip -d /tmp/selfoss-new

# 3. Delete old files EXCEPT data/ and config.ini
find /var/www/selfoss -mindepth 1 -not -path '*/data/*' -not -name 'config.ini' -delete

# 4. Copy new files (excluding data/)
rsync -a --exclude='data/' /tmp/selfoss-new/ /var/www/selfoss/

# 5. Re-check permissions
chown -R www-data:www-data /var/www/selfoss
chmod -R 775 /var/www/selfoss/data

# 6. Read NEWS.md for breaking changes
cat /var/www/selfoss/NEWS.md | head -50

# 7. Database migration happens automatically on first page load
# Clear browser cache after upgrade
```

## Gotchas

- **Do NOT delete data/:** The data/ directory contains your SQLite database, cached favicons, and thumbnails. Deleting it means losing all feed subscriptions and read state.
- **config.ini not included in release:** The zip does not ship a live `config.ini`. Copy `config-example.ini` → `config.ini` and edit. On upgrade, your existing `config.ini` must be preserved.
- **Apache .htaccess:** When using Apache, upload the invisible `.htaccess` files from the release. Without them, URL rewriting breaks and selfoss returns 404s.
- **No Docker image upstream:** selfoss does not publish an official Docker image. Community images (e.g. `hardware/selfoss`) exist but may lag behind releases.
- **Feed updates require external trigger:** selfoss has no internal scheduler — you must set up a cron job or systemd timer to call the update URL or `cliupdate.php`. Without it, feeds never refresh.
- **Single-user:** selfoss has no multi-user support. One `username`/`password` in config.ini, or no auth for personal/VPN-only use.
- **Browser cache after upgrade:** Clear browser cache after major upgrades — JS/CSS assets may be cached from the old version.

## Upstream links

- GitHub: <https://github.com/fossar/selfoss>
- Website: <https://selfoss.aditu.de>
- Releases: <https://github.com/fossar/selfoss/releases>
- Forum: <https://forum.selfoss.aditu.de/>
