---
name: rukovoditel-project
description: Rukovoditel recipe for open-forge. Configurable open-source web application designer for business and project management. PHP + MySQL, manual LAMP install. Based on upstream site at https://www.rukovoditel.net.
---

# Rukovoditel

Configurable open-source web application designer for business process management, project tracking, CRM, and custom workflow automation. PHP-based, MySQL/MariaDB backend. GPL-2.0. Upstream: https://www.rukovoditel.net. Current version: 3.7.1.

Rukovoditel is highly customisable: users define their own entities, fields, relationships, and workflows through the admin interface — no coding required. Useful for teams that need a tailored internal tool without a developer.

## Compatible install methods

| Method | When to use |
|---|---|
| Manual LAMP/LEMP | Standard; download zip and configure |
| Docker Compose (community) | Containerised; no official image |

## Inputs to collect

| Phase | Prompt | Format | Notes |
|---|---|---|---|
| database | "MySQL host / user / password / database name?" | Four values | Used in install wizard |
| config | "Admin email?" | email | Set during web install wizard |
| config | "Admin password?" | Free-text (sensitive) | Set during web install wizard |
| network | "Domain or IP for install?" | URL | Base URL for the application |
| smtp | "SMTP config for email notifications?" | host, port, user, pass | Optional; configured post-install in Settings |

## Software-layer concerns

| Concern | Detail |
|---|---|
| Language | PHP >= 8.0.2 |
| Database | MySQL 5.7+ or MariaDB 10.x |
| Web server | Apache (mod_rewrite required) or nginx |
| Config file | includes/config.php — written by install wizard |
| Writable dirs | attachments/, temp/ — must be writable by web server |
| Install wizard | Located at /install/ — delete or restrict after install |
| Upgrade path | Download new zip, overwrite files, run upgrade wizard |

## Install: Manual LAMP

Source: https://www.rukovoditel.net/download.php

### 1. Download

Download the latest release from https://www.rukovoditel.net/download.php (current: v3.7.1).

```bash
cd /var/www/html
wget https://www.rukovoditel.net/downloads/rukovoditel_3.7.1.zip
unzip rukovoditel_3.7.1.zip
mv rukovoditel_3.7.1 rukovoditel
```

### 2. Set permissions

```bash
chown -R www-data:www-data /var/www/html/rukovoditel
chmod -R 755 /var/www/html/rukovoditel
chmod -R 777 /var/www/html/rukovoditel/attachments
chmod -R 777 /var/www/html/rukovoditel/temp
```

### 3. Create MySQL database

```sql
CREATE DATABASE rukovoditel CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'rukovoditel'@'localhost' IDENTIFIED BY 'changeme';
GRANT ALL PRIVILEGES ON rukovoditel.* TO 'rukovoditel'@'localhost';
FLUSH PRIVILEGES;
```

### 4. Configure Apache

Enable mod_rewrite:
```bash
sudo a2enmod rewrite
```

Virtual host (Apache):
```apache
<VirtualHost *:80>
    ServerName rukovoditel.example.com
    DocumentRoot /var/www/html/rukovoditel
    <Directory /var/www/html/rukovoditel>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
```

### 5. Run install wizard

Visit http://yourserver/rukovoditel/install/ and complete the wizard:
- Database host, name, user, password
- Admin email and password

After install, delete or restrict the install/ directory:
```bash
rm -rf /var/www/html/rukovoditel/install
```

## Install: Docker Compose (community)

No official Docker image. Example with custom build:

```yaml
services:
  rukovoditel:
    image: php:8.2-apache
    container_name: rukovoditel
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./rukovoditel:/var/www/html
      - rukovoditel-attachments:/var/www/html/attachments
    depends_on:
      - db

  db:
    image: mysql:8.0
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: rukovoditel
      MYSQL_USER: rukovoditel
      MYSQL_PASSWORD: changeme
      MYSQL_ROOT_PASSWORD: rootpassword
    volumes:
      - mysql-data:/var/lib/mysql

volumes:
  rukovoditel-attachments:
  mysql-data:
```

Pre-copy extracted Rukovoditel files into ./rukovoditel/ before starting. Enable mod_rewrite via a custom Dockerfile or entrypoint.

## Upgrade procedure

Source: https://www.rukovoditel.net/download.php (installation instruction link)

1. Back up the database: `mysqldump -u rukovoditel -p rukovoditel > backup_$(date +%Y%m%d).sql`
2. Back up the attachments/ directory
3. Download the new release zip from https://www.rukovoditel.net/download.php
4. Extract and overwrite all files EXCEPT attachments/ and includes/config.php
5. Visit http://yourserver/rukovoditel/install/ — the wizard will detect an existing install and run the upgrade
6. Delete the install/ directory after upgrading

## Gotchas

- mod_rewrite required: Apache's mod_rewrite must be enabled and .htaccess allowed (AllowOverride All). Without it, URLs and routing break.
- Delete install/ after setup: Leaving the install/ directory accessible is a security risk — anyone could re-run the wizard.
- attachments/ must be writable: File uploads silently fail if the attachments/ directory is not writable by the web server process.
- No official Docker image: Run via standard LAMP stack or build a custom Docker image from php:8.x-apache.
- Admin-level customisation: Rukovoditel's power is in defining custom entities and fields through the UI admin panel. Plan the data model before deploying.

## Links

- Official site: https://www.rukovoditel.net
- Download: https://www.rukovoditel.net/download.php
- Demo: https://demo.rukovoditel.net (check site for current demo credentials)
