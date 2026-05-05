# Drupal

Open-source content management platform powering millions of websites — from personal blogs to enterprise portals, e-commerce sites, and government platforms. Drupal provides a flexible content model, a powerful module ecosystem (50,000+ contrib modules), multilingual support, and a robust REST/JSON:API.

**Official site:** https://www.drupal.org/

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Official `drupal` image on Docker Hub |
| Any Linux host | LAMP/LEMP stack | PHP 8.2+, Apache or Nginx, MySQL/PostgreSQL |
| Kubernetes | Helm (community) | Community Helm charts available |
| Shared / managed hosting | PHP hosting | Widely supported on cPanel/Plesk hosts |

---

## Inputs to Collect

### Phase 1 — Planning
- Database: MySQL/MariaDB (most common) or PostgreSQL
- PHP version: 8.2+ (Drupal 10/11)
- File storage for media uploads: local or cloud (S3 via contrib module)
- Domain name and TLS config

### Phase 2 — Deployment
- Database host, name, user, password
- Admin account credentials (set during install wizard)
- `settings.php` — auto-generated during install; store outside web root

---

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  drupal:
    image: drupal:latest
    restart: always
    ports:
      - "8080:80"
    volumes:
      - drupal-modules:/var/www/html/modules
      - drupal-profiles:/var/www/html/profiles
      - drupal-themes:/var/www/html/themes
      - drupal-sites:/var/www/html/sites
    depends_on:
      - db

  db:
    image: mysql:8.0
    restart: always
    environment:
      MYSQL_DATABASE: drupal
      MYSQL_USER: drupal
      MYSQL_PASSWORD: secret
      MYSQL_ROOT_PASSWORD: rootsecret
    volumes:
      - db-data:/var/lib/mysql

volumes:
  drupal-modules:
  drupal-profiles:
  drupal-themes:
  drupal-sites:
  db-data:
```

After starting, visit `http://localhost:8080/core/install.php` to complete the web-based install wizard.

### Composer-based Install (Recommended for Production)

```bash
# Install Drupal project template
composer create-project drupal/recommended-project my-drupal-site
cd my-drupal-site

# Set up web server to point to web/ directory
# Complete install at http://your-domain/install.php

# Install contrib modules via Composer
composer require drupal/admin_toolbar drupal/token

# Enable modules via Drush
./vendor/bin/drush en admin_toolbar token -y
```

### Key File Paths
- `web/sites/default/settings.php` — database and site config (auto-generated)
- `web/sites/default/files/` — public file uploads (must be writable)
- `private/` — private file storage (keep outside web root)

### Database Config in `settings.php`
```php
$databases['default']['default'] = [
  'driver' => 'mysql',
  'database' => 'drupal',
  'username' => 'drupal',
  'password' => 'secret',
  'host' => 'localhost',
  'port' => '3306',
  'prefix' => '',
];
```

---

## Upgrade Procedure

```bash
# Composer-managed projects
composer update drupal/core-recommended --with-all-dependencies

# Run database updates
./vendor/bin/drush updatedb -y
./vendor/bin/drush cache-rebuild

# Docker: pull new image and re-run install (if using official image)
docker compose pull && docker compose up -d
```

Always read the [release notes](https://www.drupal.org/project/drupal/releases) before upgrading major versions.

---

## Gotchas

- **`sites/default/files/` must be writable** by the web server user — `chmod 755` and `chown www-data` this directory.
- **`settings.php` must NOT be world-writable** after install — Drupal's security check will warn if it is.
- **Composer is required** for modern Drupal — don't unzip tarballs manually; use `composer create-project` for proper dependency management.
- **Drush** is the essential CLI tool for Drupal — install via `composer require drush/drush`.
- **Trusted host patterns** must be set in `settings.php` for production to prevent HTTP Host header attacks.
- **Major version upgrades** (e.g. 10 → 11) require the Upgrade Status module and careful dependency review.

---

## References
- GitHub: https://github.com/drupal/drupal
- Official site: https://www.drupal.org/
- Docker Hub: https://hub.docker.com/_/drupal
- Documentation: https://www.drupal.org/documentation
- Drush: https://www.drush.org/
- Module ecosystem: https://www.drupal.org/project/project_module
