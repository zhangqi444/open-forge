---
name: phpMyAdmin
description: "Classic web-based administration UI for MySQL and MariaDB. Browse + edit tables, run queries, import/export SQL, manage users, replication, events. PHP + MySQL/MariaDB. The DBA's Swiss Army knife for MySQL since 1998. GPL-2.0."
---

# phpMyAdmin

phpMyAdmin is **the** classic web UI for MySQL / MariaDB administration — around since 1998, bundled with cPanel/WHM/XAMPP/MAMP for decades, and still the default "I need to poke at a MySQL database via a browser" tool. Browse tables, edit rows inline, run ad-hoc SQL, import/export dumps, manage users + grants, track replication, handle events/triggers/routines, edit relations visually.

Who it's for:

- **Devs** — quick DB inspection + schema edits during development
- **DBAs** — user management, replication status, slow-query review
- **Small-to-medium apps** — DB admin GUI without installing a heavyweight desktop tool
- **Shared hosting** — often preinstalled

Features:

- **Browse + edit** — inline row editing, table filters, foreign-key navigation
- **Query** — syntax-highlighted SQL editor, bookmark queries, explain plans
- **Import / Export** — SQL, CSV, XML, LaTeX, YAML, PDF, many more
- **User management** — create users, edit grants, per-host privileges
- **Replication** — view master/slave status
- **Events / Triggers / Routines** — manage server-side programming
- **Designer** — visual relation editor (foreign keys as arrows)
- **Console** — popup SQL console on any page
- **Track** — watch a DB for schema changes (basic audit)
- **2FA** — TOTP / WebAuthn for admin login
- **Themes** — light/dark/custom

- Upstream repo: <https://github.com/phpmyadmin/phpmyadmin>
- Website: <https://www.phpmyadmin.net/>
- Docs: <https://docs.phpmyadmin.net/>
- Docker Hub: <https://hub.docker.com/_/phpmyadmin>

## Architecture in one minute

- **PHP 7.2.5+** (check current release requirement)
- **No dedicated storage** — reads/writes the MySQL you connect it to
- **Optional config storage DB** — phpMyAdmin's "pmadb" stores bookmarks, history, designer relations, tracking (requires a dedicated schema it creates)
- **Web server** — Apache or Nginx with PHP-FPM
- **Sessions** — default file-based or Redis/Memcached
- **Stateless-ish** — easy to scale horizontally behind LB

## Compatible install methods

| Infra        | Runtime                                          | Notes                                                             |
| ------------ | ------------------------------------------------ | ----------------------------------------------------------------- |
| Single VM    | **Docker (`phpmyadmin` official image)**            | **Simplest**                                                           |
| Single VM    | Native LAMP/LEMP                                       | Drop in, configure `config.inc.php`                                      |
| Shared host  | cPanel / Plesk preinstalled                                | Often already there                                                               |
| Kubernetes   | Deployment + Service behind ingress                             | Stateless; easy                                                                           |
| Behind DB    | Same host as MySQL                                                   | Most common homelab pattern                                                                     |

## Inputs to collect

| Input             | Example                       | Phase     | Notes                                                            |
| ----------------- | ----------------------------- | --------- | ---------------------------------------------------------------- |
| Domain            | `dbadmin.example.com`            | URL       | Reverse proxy with TLS; VPN-gate strongly recommended                |
| MySQL host        | `mysql.example.com:3306`           | DB        | Or `127.0.0.1` same host                                                    |
| MySQL user        | DB admin user (per-DB or `root`)       | Auth      | **Do NOT use root on a public-reachable instance**                                    |
| blowfish_secret   | 32+ random chars                              | Crypto    | Required for cookie auth; don't rotate                                                        |
| pmadb (opt)       | dedicated MySQL schema                                | Storage   | Unlocks bookmarks, designer, tracking; phpMyAdmin creates tables                                     |
| Auth type         | `cookie` (default) / `http` / `config` / `signon`     | Auth      | Cookie = normal login; `config` = hardcoded user (avoid)                                                     |
| HTTPS             | Let's Encrypt                                                   | Security  | **Mandatory** — you're sending DB credentials                                                                              |

## Install via Docker (with external MySQL)

```sh
docker run -d --name phpmyadmin \
  --restart unless-stopped \
  -e PMA_HOST=mysql.example.com \
  -e PMA_PORT=3306 \
  -e PMA_ABSOLUTE_URI=https://dbadmin.example.com/ \
  -e UPLOAD_LIMIT=300M \
  -p 8080:80 \
  phpmyadmin:5.2   # pin a specific version
```

For multi-DB-host picker: `-e PMA_HOSTS=db1,db2,db3` instead of `PMA_HOST`.

## Install via Docker Compose (alongside MySQL)

```yaml
services:
  mysql:
    image: mysql:8.4
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: <strong>
      MYSQL_DATABASE: appdb
      MYSQL_USER: app
      MYSQL_PASSWORD: <strong>
    volumes:
      - mysql-data:/var/lib/mysql

  phpmyadmin:
    image: phpmyadmin:5.2                       # pin specific version
    restart: unless-stopped
    depends_on: [mysql]
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      PMA_ABSOLUTE_URI: https://dbadmin.example.com/
      UPLOAD_LIMIT: 300M
    ports:
      - "8080:80"

volumes:
  mysql-data:
```

## Install natively

```sh
cd /var/www
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.tar.gz
tar xzf phpMyAdmin-5.2.1-all-languages.tar.gz
mv phpMyAdmin-5.2.1-all-languages pma
cd pma
cp config.sample.inc.php config.inc.php
# Edit config.inc.php:
#   $cfg['blowfish_secret'] = '32+-char-random';
#   $cfg['Servers'][$i]['host'] = '127.0.0.1';
#   $cfg['Servers'][$i]['auth_type'] = 'cookie';
# Point nginx/apache docroot at /var/www/pma
```

## phpMyAdmin config storage (pmadb)

For bookmarks, query history, designer saved layouts, column comments, relations, tracking, use dedicated schema:

```sql
CREATE USER 'pma'@'localhost' IDENTIFIED BY '<strong>';
CREATE DATABASE phpmyadmin;
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost';
SOURCE /path/to/phpmyadmin/sql/create_tables.sql;
```

Then in `config.inc.php`:

```php
$cfg['Servers'][$i]['controluser'] = 'pma';
$cfg['Servers'][$i]['controlpass'] = '<strong>';
$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';
$cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmark';
// (more table mappings per upstream docs)
```

## First boot

1. Browse `https://dbadmin.example.com/`
2. Log in with a MySQL user
3. Left pane → databases → click a DB → Browse / Structure / SQL
4. User accounts → create dedicated app users + grants
5. Import → drop a `.sql` file (respecting UPLOAD_LIMIT)
6. Export → pick a DB → choose format → download

## Data & config layout

- `config.inc.php` — server connections, features, auth
- phpmyadmin config storage (`pmadb`) — bookmarks, designer state, column comments, tracking
- Session files (`/tmp/sess_*` or Redis) — logged-in user tokens
- phpMyAdmin itself stores **nothing important outside config**

## Backup

Back up **the MySQL databases** (phpMyAdmin manages them, not its own data):

```sh
mysqldump -u root -p --all-databases | gzip > mysql-$(date +%F).sql.gz
cp config.inc.php pma-config-$(date +%F).bak
```

## Upgrade

1. Releases: <https://github.com/phpmyadmin/phpmyadmin/releases>. Active LTS-style cycle.
2. Docker: bump tag, pull, up -d.
3. Native: download new tarball → replace files, keep `config.inc.php`.
4. pmadb tables may need migration via `sql/upgrade.sql` for major versions.
5. Read `ChangeLog` for breaking PHP version / auth changes.

## Gotchas

- **SECURITY: do not expose phpMyAdmin on the public internet.** It's been a #1 automated-scanner target for 20 years. Constant brute-force + zero-day risk. Defense-in-depth:
  1. Put it on a VPN / Tailscale / SSH tunnel
  2. OR reverse-proxy with basic auth + strong TLS + fail2ban + IP allowlist
  3. Enable 2FA (TOTP or WebAuthn) for all users
  4. Never use `root`@`%` — dedicated user per DB, limited host
  5. Use a **non-obvious path** (not `/phpmyadmin/`) — security through obscurity doesn't work alone but reduces noise
- **`$cfg['blowfish_secret']`** — required for cookie auth; set 32+ random chars; **don't rotate** after deployment (invalidates existing cookies).
- **auth_type=`config`** stores MySQL creds in `config.inc.php` plaintext — only use for loopback/localhost admin consoles.
- **Session storage**: default file-based sessions work but behind load-balancers use Redis/Memcached for shared sessions.
- **Upload limits** — both `UPLOAD_LIMIT` (phpMyAdmin env or php.ini) AND MySQL `max_allowed_packet` AND nginx `client_max_body_size` must all be raised for big imports.
- **Large DB exports**: phpMyAdmin exports via PHP → memory limits kill >1 GB exports. Use `mysqldump` CLI instead.
- **Running queries** — long-running queries can hit PHP `max_execution_time`. For maintenance, use CLI, not phpMyAdmin.
- **CSRF protection** is enabled since 4.x; older embedded/extension panels that POST directly don't work.
- **2FA setup** — Admin → Settings → Two-factor authentication. TOTP via app; WebAuthn via passkey. Enable for every user with schema-modifying rights.
- **Multiple DB servers** — one phpMyAdmin can connect to many via `PMA_HOSTS` (comma-separated). Login picker appears on landing page.
- **MariaDB** — fully supported; phpMyAdmin auto-detects + uses MariaDB-specific features where applicable.
- **MySQL 8 `caching_sha2_password`** — default since 8.0; phpMyAdmin supports but some old LAMP stacks pair with `mysql_native_password`. If login fails mysteriously, check auth plugin.
- **Designer view** saves to pmadb; without pmadb configured, designer is read-only.
- **Does NOT manage**: Postgres (use pgAdmin), SQL Server (use Azure Data Studio / SSMS), SQLite (use Adminer or DB Browser for SQLite), MongoDB (use Mongo Express / Compass).
- **"Adminer" is a simpler single-file alternative** — if phpMyAdmin feels heavy, Adminer is ~500 KB of PHP and covers many DBs.
- **License**: GPL-2.0 (classic permissive-ish copyleft).
- **Alternatives worth knowing:**
  - **Adminer** — single-file PHP; MySQL/Postgres/SQLite/MSSQL/Oracle/SQLite; lighter
  - **DBeaver Community** (desktop) — cross-DB; rich IDE
  - **DataGrip** (JetBrains) — commercial DB IDE
  - **MySQL Workbench** — MySQL official; desktop
  - **HeidiSQL** — Windows DB GUI
  - **pgAdmin** — for Postgres
  - **CloudBeaver** — web-based DBeaver; multi-DB (separate recipe)
  - **Choose phpMyAdmin if:** you want the ubiquitous, feature-complete MySQL/MariaDB web UI.
  - **Choose Adminer if:** you want a single-file lightweight multi-DB tool.
  - **Choose CloudBeaver if:** you need one web UI for MySQL + Postgres + others.

## Links

- Repo: <https://github.com/phpmyadmin/phpmyadmin>
- Website: <https://www.phpmyadmin.net/>
- Docs: <https://docs.phpmyadmin.net/>
- Setup guide: <https://docs.phpmyadmin.net/en/latest/setup.html>
- Docker Hub: <https://hub.docker.com/_/phpmyadmin>
- Releases: <https://github.com/phpmyadmin/phpmyadmin/releases>
- Security advisories: <https://www.phpmyadmin.net/security/>
- Translations (Weblate): <https://hosted.weblate.org/projects/phpmyadmin/>
- Config reference: <https://docs.phpmyadmin.net/en/latest/config.html>
- 2FA docs: <https://docs.phpmyadmin.net/en/latest/two_factor.html>
- Adminer alternative: <https://www.adminer.org>
