---
name: b1gmail
description: b1gMail recipe for open-forge. Complete PHP-based webmail and email solution with user management, POP3 catchall, and optional Postfix integration. GPL-2.0. Source: https://codeberg.org/b1gMail/b1gMail
---

# b1gMail

A complete webmail solution that runs on a standard PHP/MariaDB stack. Features multi-domain support, webmail interface, spam filtering hooks, POP3 catchall mailboxes, and optional integration with Postfix or b1gMailServer for full MTA functionality. GPL-2.0 licensed. Source: <https://codeberg.org/b1gMail/b1gMail>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Apache2 + PHP 7.2–8.x + MariaDB | Primary supported stack |
| Any Linux | NGINX + PHP-FPM + MariaDB | Works with PHP-FPM |
| Docker | docker-dev template (dev only) | Upstream docker-dev is for development, not production |
| Windows | WAMP / WSL | Upstream supports; WSL recommended |

> **MySQL 8.0+ is not supported** — use MariaDB. See upstream README for details.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. mail.example.com |
| "Admin email?" | Email | Initial admin account |
| "MariaDB host?" | Host | Default localhost |
| "MariaDB database name?" | String | e.g. b1gmail |
| "MariaDB user?" | String | Dedicated DB user |
| "MariaDB password?" | Secret | Strong password |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "PHP version?" | 7.2–8.x | PHP 7.2 minimum; PHP 8.1+ recommended |
| "TLS?" | Yes / No | Handled by Apache/NGINX |
| "Use Postfix integration?" | Yes / No | Optional MTA pairing |

## Software-Layer Concerns

- **MySQL 8 unsupported**: Use MariaDB (10.x recommended). MySQL 8 has incompatibilities.
- **PHP version**: PHP 7.2 minimum. PHP 8.0+ supported. PHP 8.2+ — check upstream for compatibility status.
- **Config files**: `src/serverlib/config.inc.php` (copy from `config.default.inc.php`) and `src/serverlib/version.inc.php` (copy from `version.default.inc.php`).
- **Setup lock file**: Delete `src/setup/lock` before running web installer; remove `src/setup/` directory after installation.
- **SIGNKEY**: `B1GMAIL_SIGNKEY` must be set in `config.inc.php` — generated during initial setup. Back this up.
- **Database migrations**: After pulling updates, run `tools/db_sync.php` or use ACP → Tools → Optimize → Check structure to apply schema changes.
- **Postfix integration**: Optional; requires Postfix transport configuration pointing to b1gMailServer.
- **File permissions**: Web server user must have write access to `src/temp/` and `src/data/`.

## Deployment

### 1. Database setup

```bash
mysql -u root -p
CREATE DATABASE b1gmail CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'b1gmail'@'localhost' IDENTIFIED BY 'strongpassword';
GRANT ALL PRIVILEGES ON b1gmail.* TO 'b1gmail'@'localhost';
FLUSH PRIVILEGES;
```

### 2. Download and configure

```bash
# Clone the repository (or download release tarball from Codeberg)
git clone https://codeberg.org/b1gMail/b1gMail.git /var/www/b1gmail
cd /var/www/b1gmail/src/serverlib

# Copy default config files
cp config.default.inc.php config.inc.php
cp version.default.inc.php version.inc.php

# Remove setup lock to allow web installer
rm /var/www/b1gmail/src/setup/lock

# Set permissions
chown -R www-data:www-data /var/www/b1gmail/src/
chmod -R 755 /var/www/b1gmail/src/
chmod -R 775 /var/www/b1gmail/src/temp /var/www/b1gmail/src/data
```

### 3. Web server (Apache2 example)

```apache
<VirtualHost *:80>
    ServerName mail.example.com
    DocumentRoot /var/www/b1gmail/src
    <Directory /var/www/b1gmail/src>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

```bash
a2enmod rewrite
systemctl reload apache2
```

### 4. Web installer

Open `http://mail.example.com/` in a browser and follow the setup wizard:
- Enter MariaDB credentials
- Set admin username and password
- Complete domain configuration

### 5. Post-install cleanup

```bash
# Remove setup directory for security
rm -rf /var/www/b1gmail/src/setup/
```

## Upgrade Procedure

1. Back up database: `mysqldump b1gmail > b1gmail-backup.sql`
2. Back up `src/serverlib/config.inc.php` (contains SIGNKEY)
3. `git pull` (or extract new release)
4. Restore `config.inc.php`
5. Run schema sync: visit ACP → Tools → Optimize → Check structure, or run `php tools/db_sync.php`
6. Test login

## Gotchas

- **MySQL 8 incompatible**: Use MariaDB — MySQL 8 has authentication and syntax changes that break b1gMail.
- **Remove setup/ after install**: Leaving the setup directory accessible is a security risk.
- **SIGNKEY backup**: If `config.inc.php` is lost and regenerated with a different SIGNKEY, all existing sessions and encrypted data become inaccessible.
- **Postfix integration is optional**: b1gMail can work purely as webmail with POP3 catchall; Postfix MTA integration is a separate advanced configuration.
- **docker-dev is dev-only**: The upstream docker template (`docker-dev/`) is intended for development. Build a proper production Docker image or use native PHP hosting.
- **PHP 8.2+ warnings**: Check Codeberg issues for any PHP 8.2 deprecation notices if upgrading PHP.

## Links

- Source: https://codeberg.org/b1gMail/b1gMail
- Website: https://www.b1gmail.eu
- b1gMailServer (optional MTA addon): https://www.b1gmail.eu/en/start/addon-b1gmailserver/
