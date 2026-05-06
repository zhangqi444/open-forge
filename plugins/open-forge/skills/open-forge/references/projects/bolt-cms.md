---
name: bolt-cms
description: Bolt CMS recipe for open-forge. Simple, fast, open source PHP CMS built on Symfony with YAML configuration, REST/GraphQL API out of the box, multilingual support, and Composer-based extensibility. Source: https://github.com/bolt/core
---

# Bolt CMS

Simple and flexible open source CMS built on PHP, Symfony, Doctrine, Twig, and API-Platform. Supports both traditional CMS and headless/decoupled deployments. Fully multilingual (editor UI in 15 languages), configured via YAML for content types. Ships with REST and GraphQL APIs out of the box. Extensible via Composer ecosystem. Upstream: https://github.com/bolt/core. Docs: https://docs.boltcms.io/.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Composer | Linux / macOS / Windows | Recommended. Creates a full project scaffold. |
| Docker | Linux / macOS | Community Docker images available; official image via project scaffold. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Database type?" | SQLite (default, zero config), MySQL/MariaDB, or PostgreSQL |
| install | "Database credentials?" | If not SQLite: host, port, user, password, db name |
| install | "Site domain / URL?" | e.g. https://example.com |
| install | "Admin username + password?" | Created via `bolt:add-user --admin` command |

## Software-layer concerns

### Install via Composer

  composer create-project bolt/project mysite
  cd mysite

### Configure database in .env

  # SQLite (default — zero setup)
  DATABASE_URL=sqlite:///%kernel.project_dir%/var/data/bolt.sqlite

  # MySQL / MariaDB
  DATABASE_URL=mysql://user:"password"@127.0.0.1:3306/boltdb?serverVersion=8.0

  # PostgreSQL
  DATABASE_URL=postgresql://user:"password"@127.0.0.1:5432/boltdb?serverVersion=14&charset=utf8

### Initialize database and admin user

  bin/console doctrine:database:create
  bin/console doctrine:schema:create
  bin/console bolt:add-user --admin
  # Follow prompts to set username, email, password

  # Optionally load dummy content for testing:
  bin/console doctrine:fixtures:load --no-interaction

  # Copy themes to web-accessible folder:
  composer run post-create-project-cmd

  # Verify installation:
  bin/console bolt:info

### Run dev server

  # Using Symfony CLI (install from https://symfony.com/download):
  symfony server:start

  # Or PHP built-in:
  php -S localhost:8000 -t public/

### Key paths

  config/contenttypes.yaml   # Define content types (pages, posts, etc.)
  config/menu.yaml           # Navigation menus
  config/routing.yaml        # URL routing overrides
  public/                    # Web root
  var/data/bolt.sqlite       # SQLite database (if used)
  var/cache/                 # Cache — clear on deploy

### Production deployment (Apache/Nginx)

  # Web root must point to: /path/to/project/public/
  # PHP 8.1+ required

  # Nginx example:
  root /var/www/mysite/public;
  try_files $uri /index.php$is_args$args;

  # Set permissions:
  chown -R www-data:www-data var/ public/files/ public/thumbs/
  chmod -R 755 var/ public/files/

  # Production env:
  APP_ENV=prod
  APP_DEBUG=0

  # Clear cache for production:
  APP_ENV=prod bin/console cache:clear

## Upgrade procedure

  composer update bolt/core
  bin/console doctrine:schema:update --force
  APP_ENV=prod bin/console cache:clear

## Gotchas

- **Web root is `public/`**: point your web server at the `public/` subdirectory, not the project root. Exposing the project root is a security risk.
- **SQLite limitations**: SQLite works well for small sites; for multiple concurrent users or heavy write loads, migrate to MySQL/PostgreSQL.
- **Content types in YAML**: all content structures (fields, taxonomies, relationships) are defined in `config/contenttypes.yaml`. Add/change content types there, then clear cache.
- **API enabled by default**: REST and GraphQL APIs are enabled at `/api/`. Restrict access if not needed: set `bolt.api_enabled: false` in `config/bolt.yaml`.
- **File uploads**: uploaded media stored in `public/files/`. Ensure this directory is writable by the web server user and excluded from version control.
- **Project maintained**: primary maintainer Bob den Otter passed away in early 2024; new maintainers continue development as of 2024.

## References

- Upstream GitHub: https://github.com/bolt/core
- Project skeleton: https://github.com/bolt/project
- Documentation: https://docs.boltcms.io/
- Setup guide: https://github.com/bolt/core/blob/main/SETUP.md
