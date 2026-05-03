---
name: ownCloud
description: "File sync, share, and collaboration — the project that spawned Nextcloud. ownCloud Core (PHP) + Desktop/Mobile sync clients. Apps for calendar, contacts, mail, office. 200M+ users worldwide. AGPL-3.0. **Note:** successor 'ownCloud Infinite Scale (oCIS)' is a Go-based rewrite; consider it for new deployments."
---

# ownCloud

ownCloud is the OG open-source **file sync, share, and collaboration platform** — "your own Dropbox + Google Drive on your server." Store files, sync across devices, share with others via link/email, collaborate through apps (calendar, contacts, mail, news, office integration). It's been around since 2010 and has 200+ million users worldwide.

**🧭 Important context — two products under one brand:**

1. **ownCloud Core ("ownCloud Server 10.x")** — the classic PHP app in `github.com/owncloud/core`. This is what most of the internet means by "ownCloud." Still maintained (bug fixes + security), but **feature development has largely shifted** to...
2. **ownCloud Infinite Scale (oCIS)** — a ground-up **Go-based rewrite** (`github.com/owncloud/ocis`). Modern architecture (microservices, MinIO for blob storage, S3 semantics). **Recommended for new deployments** if you're picking ownCloud's ecosystem.

And then there's the elephant in the room: **Nextcloud** (`github.com/nextcloud/server`) is the 2016 ownCloud fork by most of the original team. For most people asking "should I pick ownCloud or Nextcloud today?" → Nextcloud has more community + plugin momentum, while ownCloud-the-company now focuses on oCIS + enterprise customers.

This recipe covers **ownCloud Core 10.x** (the PHP classic). For oCIS, see a dedicated recipe.

Core features:

- **File sync** — desktop (Win/Mac/Linux) + mobile (iOS/Android) clients
- **File share** — via link (password/expiry), with internal users, with federated ownCloud/Nextcloud instances
- **Calendar + Contacts (apps)** — CalDAV/CardDAV
- **Mail (app)** — IMAP webmail
- **Office** — via OnlyOffice / Collabora integration apps
- **Encryption** — server-side + client-side options
- **LDAP + SAML + OIDC** for enterprise auth
- **External storage** — mount S3, FTP, SMB, etc. as folders
- **Versioning + trash bin**
- **Activity + audit logs**
- **App store** — dozens of apps
- **REST + WebDAV API**

- ownCloud Core (10.x): <https://github.com/owncloud/core>
- ownCloud Infinite Scale (oCIS): <https://github.com/owncloud/ocis>
- Website: <https://owncloud.com>
- Docs: <https://doc.owncloud.com/server/latest/>
- App store: <https://marketplace.owncloud.com/>

## Architecture in one minute (ownCloud Core 10.x)

- **PHP 7.4 / 8.0** (check current compat; 10.x is winding down PHP version support)
- **MySQL 8 / MariaDB 10.6+ / Postgres 12+ / SQLite** (SQLite dev only)
- **Redis** — recommended for locking + cache
- **APCu** for local cache
- **Cron** — for background jobs (cleanups, versioning, external storage scans)
- **Web server**: Apache/Nginx + PHP-FPM
- **Composer v2 required** for building from source (dev); released packages include vendor/

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                          |
| ----------- | ---------------------------------------------------- | -------------------------------------------------------------- |
| Single VM   | Native LAMP/LEMP                                       | **Primary supported path**                                         |
| Single VM   | Official Docker image (`owncloud/server`)                  | Available; check current maintenance state                             |
| Appliance   | Univention Corporate Server                                    | Enterprise option                                                           |
| Managed     | ownCloud.online / partners                                        | Commercial SaaS                                                                  |
| Kubernetes  | Helm charts (for oCIS more than Core)                              | oCIS is K8s-native; Core isn't as clean                                             |

## Inputs to collect

| Input          | Example                      | Phase     | Notes                                                            |
| -------------- | ---------------------------- | --------- | ---------------------------------------------------------------- |
| Domain         | `cloud.example.com`            | URL       | `trusted_domains` in config                                         |
| DB             | MySQL / MariaDB / Postgres     | DB        | MariaDB 10.6+ common                                                         |
| Admin user     | set via install wizard            | Bootstrap | Strong password                                                                     |
| Data dir       | `/var/www/owncloud/data`             | Storage   | **Place outside webroot** for security                                                       |
| Cron           | Every 15 min (`systemd timer` or crontab) | Schedule  | `php occ system:cron`                                                                             |
| Redis          | localhost / shared                        | Perf      | Highly recommended                                                                                       |
| TLS            | Let's Encrypt                             | Security  | Mandatory for clients                                                                                           |
| SMTP           | host + port + creds                        | Email     | Invites, notifications, password reset                                                                                |

## Install (native LEMP, summary)

```sh
# Prereqs: PHP 7.4/8.0 with extensions (ctype curl dom gd iconv intl json libxml mbstring posix simplexml xml xmlreader xmlwriter zip)
# Plus APCu, Redis, PHP-FPM, MariaDB, nginx, certbot

cd /var/www
wget https://download.owncloud.com/server/stable/owncloud-complete-YYYYMMDD.tar.bz2
tar -xjf owncloud-complete-YYYYMMDD.tar.bz2
chown -R www-data:www-data owncloud
# Nginx server block: see https://doc.owncloud.com/server/latest/admin_manual/installation/nginx.html
# Browse https://cloud.example.com → install wizard:
#   - admin user/password
#   - data directory (outside webroot!)
#   - DB type + creds

# Post-install:
cd owncloud
sudo -u www-data php occ maintenance:install --database mysql --database-name owncloud --database-user owncloud --database-pass <strong> --admin-user admin --admin-pass <strong> --data-dir /srv/owncloud-data

# Enable Redis in config/config.php; restart PHP-FPM
# Cron: sudo -u www-data php /var/www/owncloud/occ system:cron
```

## Install via Docker (compose, Core 10.x)

```yaml
services:
  owncloud:
    image: owncloud/server:10.16.1           # pin; check Docker Hub / owncloud site
    container_name: owncloud
    restart: unless-stopped
    depends_on: [mariadb, redis]
    ports:
      - "8080:8080"
    environment:
      OWNCLOUD_DOMAIN: cloud.example.com
      OWNCLOUD_TRUSTED_DOMAINS: cloud.example.com
      OWNCLOUD_DB_TYPE: mysql
      OWNCLOUD_DB_NAME: owncloud
      OWNCLOUD_DB_USERNAME: owncloud
      OWNCLOUD_DB_PASSWORD: <strong>
      OWNCLOUD_DB_HOST: mariadb
      OWNCLOUD_ADMIN_USERNAME: admin
      OWNCLOUD_ADMIN_PASSWORD: <strong>
      OWNCLOUD_REDIS_ENABLED: "true"
      OWNCLOUD_REDIS_HOST: redis
      HTTP_PORT: "8080"
    volumes:
      - ./files:/mnt/data

  mariadb:
    image: mariadb:10.11
    command: --max-allowed-packet=128M --innodb-log-file-size=64M
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: <strong-root>
      MYSQL_USER: owncloud
      MYSQL_PASSWORD: <strong>
      MYSQL_DATABASE: owncloud
    volumes:
      - ./mariadb:/var/lib/mysql

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: ["--databases", "1"]
    volumes:
      - ./redis:/data
```

## First boot

1. Log in as admin
2. Settings → General → enable/disable apps (Calendar, Contacts, Mail, ...)
3. Settings → Security → enable brute-force throttling, enforce TLS, strong password policy
4. Install sync clients on each device; connect to `https://cloud.example.com`
5. Configure LDAP/SAML/OIDC if enterprise auth required
6. Set cron method to systemd timer or crontab (NOT "AJAX" — unreliable)

## Data & config layout

Inside the install dir (`/var/www/owncloud/`):

- `config/config.php` — main config
- `apps/` — first-party apps
- `apps-external/` — apps installed from marketplace
- `data/` — file storage + user DBs (user metadata) — **consider moving to `/srv/owncloud-data` outside webroot**
- `core/` — framework
- `lib/` — libs

## Backup

```sh
# DB (CRITICAL — all metadata, shares, users)
mysqldump -uowncloud -p --single-transaction owncloud | gzip > oc-db-$(date +%F).sql.gz

# Data dir (all user files; can be HUGE)
rsync -aAXv /srv/owncloud-data/ /backups/oc-files-$(date +%F)/

# Config
cp config/config.php oc-config-$(date +%F).bak
```

## Upgrade

1. Releases: <https://github.com/owncloud/core/releases> (Core) / <https://owncloud.com/server-release-channels/> (stable channel)
2. **Back up DB + data + config first.**
3. Put into maintenance mode: `sudo -u www-data php occ maintenance:mode --on`
4. Extract new release over existing install (preserve `data/`, `config/config.php`, `apps-external/`)
5. Run: `sudo -u www-data php occ upgrade`
6. Exit maintenance mode: `sudo -u www-data php occ maintenance:mode --off`
7. **Skipping major versions is NOT supported** — upgrade one major at a time.
8. Post-2022: consider migrating to oCIS (Infinite Scale) for a modern re-architecture. ownCloud offers a [migration path from Core 10.x to oCIS](https://doc.owncloud.com/ocis/latest/migration/).

## Gotchas

- **The big strategic question**: if you're starting fresh in 2025+, pick between:
  - **Nextcloud** — more community, bigger app ecosystem, active development on the PHP stack
  - **ownCloud Infinite Scale (oCIS)** — Go-native, S3-first, modern architecture, driven by ownCloud GmbH
  - **ownCloud Core 10.x** — maintenance-mode-ish; OK for existing installs; not recommended for new deployments unless you have a specific reason
- **PHP version treadmill** — Core 10.x support for PHP 7.4/8.0 winds down; PHP 8.3+ compat is oCIS territory.
- **Data directory outside webroot** — MUST. If you install to `/var/www/owncloud`, put data in `/srv/owncloud-data`, not `/var/www/owncloud/data`. Misconfiguration = file leakage via direct URL access.
- **File locking**: enable Redis file locking in `config.php` (`filelocking.enabled = true` + Redis memcache) — without it, concurrent uploads from sync clients can corrupt.
- **HTTPS strict-transport-security + perfect-forward-secrecy** — sync clients expect strong TLS. Use `Security → TLS` section of docs for best-practice nginx config.
- **Cron choice matters**: "Ajax" cron runs on page views = unreliable for idle instances. Use "Webcron" (URL ping from external) OR (best) a real cron / systemd timer running `occ system:cron` every 15 min.
- **Big files**: tune `upload_max_filesize` + `post_max_size` in PHP + `client_max_body_size` in nginx. Default 2 MB trips users.
- **S3 backend** (primary storage on S3) — supported in Core 10.x; mature in oCIS; config is involved. Objectstorage for end-user scale.
- **Sharing links + expiry** — good defaults; enforce password on links in Security settings for public sharing.
- **External storage apps** (SMB, SFTP, WebDAV, S3 bucket) — can mount other backends as user folders. Useful for migrating off legacy NAS.
- **Encryption (server-side)** — slows performance + complicates backups. Enable only if you trust the design; "client-side encryption" apps (e.g., Cryptomator via WebDAV) are often a better pattern.
- **Federated sharing** — Core supports federation with other ownCloud + Nextcloud instances. Good for inter-org sharing.
- **2FA** — enforce via apps. App store has TOTP, U2F, WebAuthn.
- **Activity + audit logs** — enable audit app for compliance. Logs go to `owncloud.log` + audit-specific location.
- **occ CLI** is the admin's friend: `php occ` shows 100+ subcommands (users, groups, apps, encryption, files:scan, upgrade, etc.). Use instead of UI for bulk operations.
- **Files:scan** — when files are added out-of-band to data dir, run `occ files:scan --all` so ownCloud indexes them.
- **Desktop clients** — mature, multi-platform. iOS/Android apps also solid.
- **App quality**: marketplace has good apps (Calendar, Contacts, OnlyOffice, Collabora, Tasks), but some 3rd-party apps are abandoned. Check last-updated dates.
- **ownCloud Enterprise Edition** adds features (workflow, antivirus hooks, compliance) via commercial license.
- **AGPL-3.0** — strong copyleft; deploying a modified version = you must publish source to users.
- **Alternatives worth knowing:**
  - **Nextcloud** — the community fork with bigger ecosystem + more active development; API-compatible-ish with ownCloud for some things (separate recipe)
  - **ownCloud Infinite Scale (oCIS)** — ownCloud's modern Go rewrite (separate recipe)
  - **Seafile** — different architecture; library-based; fast sync; C/Python (separate recipe)
  - **Pydio** — PHP; modern UX
  - **Syncthing** — peer-to-peer sync; no central server; different paradigm
  - **Resilio Sync** / **NextCloud + File sync** — combinations
  - **Google Drive / Dropbox / OneDrive / iCloud Drive** — SaaS
  - **Choose Nextcloud if:** you want the most active community + biggest app ecosystem on the PHP sync/share stack.
  - **Choose oCIS if:** you want a modern Go-native rearchitecture + S3-first storage.
  - **Choose ownCloud Core 10.x if:** you already run it (migration isn't free); for new deploys, pick one of the above.
  - **Choose Seafile if:** you prioritize sync speed + don't need an app ecosystem.

## Links

- ownCloud Core repo: <https://github.com/owncloud/core>
- ownCloud Infinite Scale repo: <https://github.com/owncloud/ocis>
- Website: <https://owncloud.com>
- Documentation (Core 10.x): <https://doc.owncloud.com/server/latest/>
- Install docs: <https://doc.owncloud.com/server/latest/admin_manual/installation/>
- Docker docs: <https://doc.owncloud.com/server/latest/admin_manual/installation/docker/>
- App marketplace: <https://marketplace.owncloud.com/>
- Releases: <https://github.com/owncloud/core/releases>
- Enterprise: <https://owncloud.com/enterprise/>
- Infinite Scale migration: <https://doc.owncloud.com/ocis/latest/migration/>
- Desktop clients: <https://owncloud.com/desktop-app/>
- Mobile apps: <https://owncloud.com/mobile-apps/>
- Community forum: <https://central.owncloud.org>
