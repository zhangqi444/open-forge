# MantisBT

MantisBT (Mantis Bug Tracker) is a web-based bug and issue tracking system. It is widely used for software development projects and supports MySQL, PostgreSQL, and other databases.

**Website:** https://www.mantisbt.org/
**Source:** https://github.com/mantisbt/mantisbt
**License:** GPL-2.0
**Stars:** ~1,762

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | PHP + MySQL/MariaDB + Apache/nginx | Classic LAMP |
| Any Linux/VPS | Docker (community image) | No official image |
| Any Linux/VPS | PHP + PostgreSQL | Supported |

---

## Inputs to Collect

### Phase 1 — Planning
- Database backend: MySQL 5.5.35+ / MariaDB or PostgreSQL 9.2+
- Web server: Apache or nginx
- PHP version: 8.1+
- Admin email address
- Site base URL

### Phase 2 — Deployment
- `DB_HOST`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`
- `MANTIS_ADMIN_EMAIL`
- Web root path (e.g. `/var/www/html/mantisbt`)

---

## Software-Layer Concerns

### Docker Compose (Community Image)
No official Docker image exists; the community image `vimagick/mantisbt` is commonly used:

```yaml
services:
  db:
    image: mariadb:10.11
    environment:
      MYSQL_ROOT_PASSWORD: rootpass
      MYSQL_DATABASE: bugtracker
      MYSQL_USER: mantis
      MYSQL_PASSWORD: mantispass
    volumes:
      - mantis_db:/var/lib/mysql

  mantisbt:
    image: vimagick/mantisbt:latest
    ports:
      - "8080:80"
    environment:
      - MANTIS_DB_HOST=db
      - MANTIS_DB_NAME=bugtracker
      - MANTIS_DB_USERNAME=mantis
      - MANTIS_DB_PASSWORD=mantispass
    depends_on:
      - db
    volumes:
      - mantis_uploads:/var/www/html/mantisbt/uploads

volumes:
  mantis_db:
  mantis_uploads:
```

### Manual Installation
```bash
# Extract tarball to web root
tar -xzf mantisbt-*.tar.gz -C /var/www/html/
mv /var/www/html/mantisbt-* /var/www/html/mantisbt

# Set permissions
chown -R www-data:www-data /var/www/html/mantisbt
chmod -R 755 /var/www/html/mantisbt

# Run web installer
# Navigate to https://example.com/mantisbt/admin/install.php
```

### Post-Installation Security (CRITICAL)
```bash
# Remove admin directory after installation — this is required!
rm -rf /var/www/html/mantisbt/admin/
```

### Config File
Primary config: `config/config_inc.php`
```php
<?php
$g_hostname               = 'localhost';
$g_db_type                = 'mysqli';
$g_database_name          = 'bugtracker';
$g_db_username            = 'mantis';
$g_db_password            = 'mantispass';
$g_default_timezone       = 'UTC';
$g_webmaster_email        = 'admin@example.com';
$g_from_email             = 'noreply@example.com';
$g_return_path_email      = 'admin@example.com';
```

### Data Volumes
| Path | What's stored |
|------|--------------|
| `uploads/` | Attached files |
| MySQL/MariaDB data dir | All issue data |

---

## Upgrade Procedure

```bash
# Backup database first!
mysqldump bugtracker > mantisbt_backup.sql

# Extract new version to a clean directory
tar -xzf mantisbt-new.tar.gz

# Copy config from old installation
cp /old/mantisbt/config/config_inc.php /new/mantisbt/config/

# Copy custom files if any (custom_strings_inc.php, etc.)

# Swap web root (or update symlink)

# Run database upgrade
# Navigate to https://example.com/mantisbt/admin/install.php

# Remove admin/ directory again!
rm -rf /var/www/html/mantisbt/admin/
```

---

## Gotchas

- **Delete admin/ directory**: After every install or upgrade, the `admin/` directory must be removed. It exposes sensitive operations if left accessible.
- **No official Docker image**: Use community images or a standard PHP Docker image with manual setup.
- **Email configuration**: MantisBT sends lots of notifications; configure SMTP properly in `config_inc.php` with `$g_smtp_host`, `$g_smtp_port`, etc.
- **File permissions**: The `uploads/` directory must be writable by the web server user.
- **PHP extensions required**: `mysqli` or `pgsql`, `mbstring`, `gd`, `fileinfo`, `curl`, `xml`.
- **Custom fields and workflows**: Extensive customization available but requires PHP config file edits.

---

## Links
- Docs / Admin Guide: https://www.mantisbt.org/docs/
- Requirements: https://www.mantisbt.org/requirements.php
- GitHub Releases: https://github.com/mantisbt/mantisbt/releases
- Demo: https://www.mantisbt.org/bugs/my_view_page.php
