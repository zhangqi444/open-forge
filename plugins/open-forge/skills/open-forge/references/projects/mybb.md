# MyBB

MyBB is a free, extensible forum software built in PHP with MySQL. It features a classic bulletin board interface, plugin/theme system, moderation tools, multi-language support, and a large community ecosystem of plugins and themes.

**Website:** https://mybb.com/
**Source:** https://github.com/mybb/mybb
**License:** LGPL-3.0
**Stars:** ~1,215

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux/VPS | PHP 8.0+ + MySQL/MariaDB + Apache/nginx | Classic LAMP/LEMP |
| Shared hosting | PHP + MySQL | Traditional deployment |
| Docker | Community images | No official Docker image |

---

## Inputs to Collect

### Phase 1 — Planning
- PHP 8.0+ with extensions: `gd`, `mbstring`, `curl`, `xml`, `zip`, `pdo_mysql`
- MySQL 5.5+ / MariaDB 10.0+
- Database name, user, password
- Forum URL (used in config)
- Admin email and password

### Phase 2 — Deployment
- `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- `DB_TABLE_PREFIX` (default: `mybb_`)
- Forum site URL
- Web root path

---

## Software-Layer Concerns

### Download and Install
```bash
# Download from https://mybb.com/download/
wget https://resources.mybb.com/downloads/mybb_latest.zip
unzip mybb_latest.zip -d mybb_extract/

# Copy Upload/ directory contents to web root
cp -r mybb_extract/Upload/. /var/www/html/forum/

# Set permissions
chmod 777 /var/www/html/forum/cache/
chmod 777 /var/www/html/forum/uploads/
chmod 777 /var/www/html/forum/admin/backups/
# (reduce to 755 after installation)
```

### Web Installer
1. Browse to `https://yourdomain.com/forum/install/`
2. Follow setup wizard:
   - Verify requirements
   - License agreement
   - Database configuration (host, name, user, pass, prefix)
   - Table creation
   - Populate initial data
   - Set admin account (username, password, email)
   - Configure board settings (name, URL, etc.)
3. Installation complete

```bash
# REQUIRED: Remove install directory after setup
rm -rf /var/www/html/forum/install/
```

### nginx Configuration
```nginx
server {
    listen 80;
    server_name forum.example.com;
    root /var/www/html/forum;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Deny access to sensitive files
    location ~* /inc/config\.php { deny all; }
    location ~* /\.ht { deny all; }
}
```

### Config File
Main config: `inc/config.php` (created by installer)
```php
<?php
$config['database']['type'] = 'mysqli';
$config['database']['database'] = 'mybb_forum';
$config['database']['table_prefix'] = 'mybb_';
$config['database']['hostname'] = 'localhost';
$config['database']['username'] = 'mybbuser';
$config['database']['password'] = 'dbpassword';
$config['database']['port'] = '3306';
```

### Directory Permissions (Post-Install)
```bash
# Tighten permissions after install
chmod 644 inc/config.php
chmod 755 cache/
chmod 755 uploads/
chmod 755 admin/backups/
# Remove world-write on install dir (already deleted above)
```

### Plugins and Themes
- Install plugins: Admin CP → Configuration → Plugins → Upload Plugin
- Install themes: Admin CP → Templates & Style → Themes → Import a Theme
- Plugin repository: https://community.mybb.com/mods.php

---

## Upgrade Procedure

```bash
# Download new version
wget https://resources.mybb.com/downloads/mybb_latest.zip
unzip mybb_latest.zip -d mybb_new/

# Put forum in maintenance mode
# Admin CP → Configuration → Board Settings → Enable maintenance mode

# Back up database
mysqldump mybb_forum > mybb_backup.sql

# Overwrite files (preserves inc/config.php and uploads/)
rsync -av --exclude='inc/config.php' --exclude='uploads/' \
  mybb_new/Upload/. /var/www/html/forum/

# Re-set directory permissions
chmod 777 cache/ uploads/ admin/backups/

# Run database upgrade
# Browse to https://yourdomain.com/forum/install/upgrade.php

# Remove install/ again after upgrade
rm -rf /var/www/html/forum/install/

# Disable maintenance mode
```

---

## Gotchas

- **Delete `install/` after every install/upgrade**: Leaving it accessible is a critical security hole.
- **No official Docker image**: Community Docker images exist but are unsupported. Traditional LAMP deployment is the standard.
- **PHP 8.x compatibility**: Verify plugin and theme compatibility with PHP 8 before upgrading. Some older plugins may have issues.
- **`inc/config.php` security**: This file contains DB credentials and must not be world-readable. Set to `644` with the web server user as owner.
- **Uploads directory**: User-uploaded files go in `uploads/`; back this up separately along with the database.
- **Caching**: MyBB uses filesystem caching in `cache/`; this directory must be writable. Consider Redis/Memcached for high-traffic forums.
- **Email configuration**: Configure SMTP in Admin CP → Configuration → Mail Settings for reliable email delivery (registration, notifications).

---

## Links
- Docs: https://docs.mybb.com/
- Installation Guide: https://docs.mybb.com/1.8/install/
- Upgrade Guide: https://docs.mybb.com/1.8/install/upgrade/
- Download: https://mybb.com/download/
- Plugin/Theme Repository: https://community.mybb.com/mods.php
- Community Forum: https://community.mybb.com/
