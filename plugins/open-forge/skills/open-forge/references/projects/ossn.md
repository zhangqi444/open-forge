# OSSN (Open Source Social Network)

OSSN is a PHP-based social networking platform that lets you build a self-hosted social networking site with Facebook-like features: profiles, friends, messaging, newsfeed, groups, photos, albums, blogs, notifications, and live chat. Supports multiple languages and has a component/plugin ecosystem.

**Website:** https://www.opensource-socialnetwork.org/
**Source:** https://github.com/opensource-socialnetwork/opensource-socialnetwork
**License:** CAL-1.0 (Cryptographic Autonomy License)
**Stars:** ~1,206

> ⚠️ **CAL-1.0 License**: The Cryptographic Autonomy License imposes strong user data portability requirements. Review the license terms before commercial or community use. It is OSI-approved but has unusual obligations around user key management and data portability.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu 18.04–24.04 | PPA package install | Official/easiest |
| Any Linux | PHP 8.x + MySQL/MariaDB + Apache | Manual LAMP |
| Any Linux | Docker | Official Docker repo available |
| Any | Web installer from zip | Traditional PHP deployment |

---

## Inputs to Collect

### Phase 1 — Planning
- PHP 8.x + MySQL 5.7+ / MariaDB
- Site URL (used in config — cannot easily be changed later)
- Admin username, email, password
- Database name, user, password
- SMTP/email settings for notifications

### Phase 2 — Deployment
- `DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
- Site base URL
- Web root path (must be writable by web server)

---

## Software-Layer Concerns

### Method 1: Ubuntu PPA (Easiest)
```bash
sudo add-apt-repository ppa:arsalanshah/opensource-socialnetwork
sudo apt-get update
sudo apt-get install opensource-socialnetwork
```
Installs Apache, PHP, MySQL and configures everything automatically. Access at `http://localhost/` after install.

### Method 2: Docker
```bash
# Official Docker repository
git clone https://github.com/opensource-socialnetwork/docker
cd docker
docker compose up -d
# Access at http://localhost:8080
```

### Method 3: Manual Web Installer
```bash
# Download from https://www.opensource-socialnetwork.org/download
unzip ossn-*.zip -d /var/www/html/ossn/

# Set directory permissions
chgrp www-data /var/www/html/ossn/
chmod g+w /var/www/html/ossn/
chmod -R g+w /var/www/html/ossn/

# Run web installer
# Browse to https://yourdomain.com/ossn/installation/
```

### Apache Virtual Host Config
```apache
<VirtualHost *:80>
    ServerName social.example.com
    DocumentRoot /var/www/html/ossn

    <Directory /var/www/html/ossn>
        AllowOverride All
        Require all granted
    </Directory>

    # Required: enable mod_rewrite
    # sudo a2enmod rewrite
</VirtualHost>
```

### nginx Config
```nginx
server {
    listen 80;
    server_name social.example.com;
    root /var/www/html/ossn;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.2-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

### Key Directories
| Path | Purpose |
|------|---------|
| `ossn_data/` | User uploads, avatars, photos |
| `components/` | Installed plugins/components |
| `themes/` | Installed themes |

### Components (Plugins)
Download from community: https://www.opensource-socialnetwork.org/community/groups/view/components
Install via Admin Panel → Components → Install Component.

---

## Upgrade Procedure

```bash
# See official upgrade guide:
# https://www.opensource-socialnetwork.org/wiki/view/708/how-to-upgrade-ossn

# General steps:
# 1. Backup database and files
mysqldump ossn_db > ossn_backup.sql
tar -czf ossn_files_backup.tar.gz /var/www/html/ossn/

# 2. Download new version
wget https://www.opensource-socialnetwork.org/download -O ossn_new.zip
unzip ossn_new.zip

# 3. Overwrite files (preserve ossn_data/ and configuration)
rsync -av --exclude='ossn_data/' --exclude='components/' \
  ossn_new/. /var/www/html/ossn/

# 4. Run upgrade script if prompted by web UI
```

---

## Gotchas

- **CAL-1.0 license**: The Cryptographic Autonomy License is unusual — it requires that users can export and control their own data/keys. Read carefully before building a commercial product on it.
- **Site URL is set at install time**: OSSN bakes the site URL into the database. Moving to a different domain requires database updates.
- **Directory must be web-server writable**: Unlike some CMSes, OSSN requires the entire install directory to be writable by the web server, not just specific subdirs.
- **mod_rewrite required**: Apache must have `mod_rewrite` enabled (`a2enmod rewrite`) and `.htaccess` files must be allowed (`AllowOverride All`).
- **Email configuration needed**: Registration confirmations and notifications require working SMTP. Configure in Admin Panel → Email Settings.
- **Component quality varies**: Community components vary in quality and PHP 8.x compatibility. Test before deploying to production.
- **Performance at scale**: OSSN is a PHP app without aggressive caching; for large communities, configure PHP-FPM with OPcache and use a MySQL/MariaDB with query caching.

---

## Links
- Installation Guide: https://www.opensource-socialnetwork.org/wiki/view/706/how-to-install-open-source-social-network
- Upgrade Guide: https://www.opensource-socialnetwork.org/wiki/view/708/how-to-upgrade-ossn
- Docker: https://github.com/opensource-socialnetwork/docker
- Components: https://www.opensource-socialnetwork.org/community/groups/view/components
- Demo: http://demo.opensource-socialnetwork.org/
- Download: https://www.opensource-socialnetwork.org/download
