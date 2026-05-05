---
name: concrete-5-cms
description: Concrete CMS recipe for open-forge. Open-source PHP CMS with inline page editing, marketplace add-ons, and Express Objects for custom data. Formerly concrete5. Upstream: https://github.com/concretecms/concretecms
---

# Concrete CMS

Open-source content management system with inline page editing — click any element on the page to edit it directly in the browser. Includes a marketplace for themes and add-ons, Express Objects for custom data types, multilingual support, and a built-in workflow engine. Formerly known as concrete5 (rebranded 2021). Upstream: <https://github.com/concretecms/concretecms> — MIT.

PHP + MySQL/MariaDB/PostgreSQL.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Composer (recommended) | <https://documentation.concretecms.org/developers/installation> | Yes | Clean install on any PHP host. |
| Release ZIP | <https://www.concretecms.com/download> | Yes | Shared hosting or servers without Composer. |
| Docker Compose | Community | Community | Containerised dev/production. No official first-party image. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| db | Database name, user, password | Free-text / sensitive | All |
| db | Database host (default: localhost) | Free-text | All |
| db | Database type (MySQL/MariaDB or PostgreSQL) | Choice | All |
| admin | Admin username, password, email | Free-text / sensitive | First-run installer |
| site | Site name | Free-text | First-run installer |
| domain | Public hostname | Free-text | All |

## Composer install (recommended)

Requirements: PHP 8.1+, Composer, MySQL 8+ / MariaDB 10.4+ / PostgreSQL 11+, Apache or Nginx.

```bash
composer create-project -n concrete5/concrete5 my-site
cd my-site
# Set web server document root to /path/to/my-site
# Visit http://<host>/ to run the web installer
```

Required PHP extensions: pdo_mysql (or pdo_pgsql), gd, xml, json, mbstring, curl, zip, fileinfo.

Apache: enable mod_rewrite and set AllowOverride All. Concrete CMS ships a .htaccess that handles URL rewriting.

Nginx:
```nginx
location / {
    try_files $uri $uri/ /index.php$is_args$args;
}
location ~ \.php$ {
    fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

## Docker Compose (community)

```yaml
version: "3.8"

services:
  concretecms-db:
    image: mysql:8
    container_name: concretecms-db
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: REPLACE_ROOT_PASSWORD
      MYSQL_DATABASE: concretecms
      MYSQL_USER: concretecms
      MYSQL_PASSWORD: REPLACE_DB_PASSWORD
    volumes:
      - concretecms_db:/var/lib/mysql

  concretecms:
    image: concrete5/concrete5:latest
    container_name: concretecms
    restart: unless-stopped
    depends_on:
      - concretecms-db
    ports:
      - "8080:80"
    environment:
      DB_SERVER: concretecms-db
      DB_DATABASE: concretecms
      DB_USERNAME: concretecms
      DB_PASSWORD: REPLACE_DB_PASSWORD
    volumes:
      - concretecms_files:/var/www/html/application/files
      - concretecms_packages:/var/www/html/packages

volumes:
  concretecms_db:
  concretecms_files:
  concretecms_packages:
```

Note: the community Docker image (concrete5/concrete5) is not maintained by the Concrete CMS core team.

## Key directories

| Path | Purpose |
|---|---|
| application/files/ | User uploads — must be writable and persisted in Docker |
| application/config/ | Generated config (database.php, app.php) |
| application/cache/ | Page and block cache — must be writable |
| packages/ | Installed marketplace add-ons and themes |
| concrete/ | Core CMS code — do not edit; overwritten on upgrade |

## Key features

- **Inline editing:** Click any block on the page to edit content without leaving the front end
- **Express Objects:** Define custom data types via GUI (like custom post types), no coding required
- **Marketplace:** Themes and add-ons at https://marketplace.concretecms.com
- **Multilingual:** Built-in i18n with locale-specific content trees
- **Workflow:** Approval workflows before page publishing
- **File Manager:** Integrated media library with tagging and image editing
- **Blocks:** Text, image, gallery, form, calendar, search — drag-and-drop onto any page

## Upgrade procedure

Via Dashboard: Dashboard > System & Settings > Update Concrete CMS > click "Update to X.Y.Z"

Via CLI:
```bash
composer update concrete5/concrete5
php concrete/bin/concrete5 c5:update
```

Always back up the database and application/files/ before upgrading.

## Gotchas

- **Never edit /concrete/ directly.** It is the core and is overwritten on every upgrade. Put customisations in /application/ or a package.
- **application/files/ must be persisted in Docker.** All uploads live here. Losing this volume loses all media.
- **.htaccess required for Apache.** Without mod_rewrite and AllowOverride All, pretty URLs break.
- **Cache can mask changes.** After editing templates, clear via Dashboard > System > Clear Cache or php concrete/bin/concrete5 c5:cache:clear.
- **Concrete CMS 9.x is current.** Versions 8.x and 5.7.x are legacy branches.

## Upstream docs

- GitHub: https://github.com/concretecms/concretecms
- Documentation: https://documentation.concretecms.org
- Marketplace: https://marketplace.concretecms.com
- Community forums: https://forums.concretecms.org
- Docker Hub: https://hub.docker.com/r/concrete5/concrete5
