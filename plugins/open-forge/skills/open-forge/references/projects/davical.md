# DAViCal

> Self-hosted CalDAV and CardDAV server — share calendars and contacts between devices and users. Supports CalDAV, CardDAV, WebDAV, and delegation (read/write sharing between users). Long-established PHP + PostgreSQL stack; Debian packages available.

**Official URL:** https://www.davical.org  
**Wiki:** https://wiki.davical.org  
**Source:** https://gitlab.com/davical-project/davical

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Debian/Ubuntu VPS | Debian package + Apache | Primary supported path; `apt install davical` |
| Any Linux VPS/VM | PHP + Apache/Nginx + PostgreSQL | Manual install |
| Any Linux VPS/VM | Docker | Community Docker images; not official |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `DOMAIN` | Public domain for CalDAV/CardDAV endpoint | `cal.example.com` |
| `POSTGRES_PASSWORD` | PostgreSQL password for DAViCal database user | strong password |
| `ADMIN_PASSWORD` | Initial DAViCal admin password | strong password |
| `ADMIN_EMAIL` | Admin account email | `admin@example.com` |

---

## Software-Layer Concerns

### Debian/Ubuntu Installation (Recommended)
```bash
# Install DAViCal and dependencies
sudo apt install davical

# Install and configure PostgreSQL
sudo apt install postgresql
sudo -u postgres createuser davical_dba --no-superuser --no-createdb --no-createrole
sudo -u postgres createuser davical_app --no-superuser --no-createdb --no-createrole
sudo -u postgres createdb davical --owner davical_dba
sudo -u postgres psql davical < /usr/share/davical/dba/davical.sql

# Configure Apache virtual host
# See https://wiki.davical.org/w/Installation for the full vhost config
```

### Apache Virtual Host
DAViCal uses URL rewriting to expose CalDAV/CardDAV at clean paths. The package ships example Apache config at `/usr/share/doc/davical/examples/`.

### Config File
Main config: `/etc/davical/<hostname>-conf.php`

```php
<?php
$c->pg_connect[] = 'dbname=davical port=5432 user=davical_app password=yourpassword host=localhost';
$c->admin_email = 'admin@example.com';
$c->system_name = 'My Calendar Server';
```

### Calendar Client Config
Point clients at:
- CalDAV principal: `https://cal.example.com/principals/USERNAME/`
- CalDAV collection: `https://cal.example.com/caldav.php/USERNAME/CALNAME/`
- CardDAV: `https://cal.example.com/carddav.php/principals/USERNAME/`

### Ports
- Standard HTTP/HTTPS via Apache/Nginx — port `80`/`443`

### Delegation
DAViCal supports sharing calendars between users with configurable read/read-write permissions via the admin web UI.

---

## Upgrade Procedure

1. `sudo apt update && sudo apt upgrade davical`
2. The package manager handles database schema upgrades automatically
3. Check the wiki changelog for manual steps required on major version bumps

---

## Gotchas

- **PostgreSQL only** — DAViCal does not support MySQL/MariaDB or SQLite
- **Apache recommended** — Nginx requires manual URL rewrite configuration; Apache is much easier with the provided example vhost
- **Community support model** — as of 2014, DAViCal relies on community contributors; the project is maintained but not commercially backed; response times on issues vary
- **PHP required** — needs PHP with the PostgreSQL extension (`php-pgsql`) installed
- **iOS/macOS auto-discovery** — for `.well-known/caldav` and `.well-known/carddav` auto-discovery to work, configure redirects in your web server config
- **HTTPS strongly recommended** — CalDAV sends credentials; always run behind TLS in production

---

## Links
- Website: https://www.davical.org
- Installation guide: https://www.davical.org/installation.php
- Wiki: https://wiki.davical.org
- GitLab: https://gitlab.com/davical-project/davical
