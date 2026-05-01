---
name: TYPO3
description: "Enterprise open-source PHP content management framework. Docker or DDEV/Composer. PHP/MySQL. TYPO3/typo3. Highly extensible, multi-site, multi-language, 60,000+ extensions, TypoScript, GDPR-compliant. GPL."
---

# TYPO3

**Enterprise open-source PHP content management framework.** One of the most mature CMSes in the world — used by governments, universities, and enterprises for complex, multi-site, multi-language websites. Highly extensible via 60,000+ extensions; TypoScript configuration language; backend/frontend separation; strong GDPR compliance tools. Not a blog platform — TYPO3 is a full framework for building complex web applications.

Built + maintained by **TYPO3 Core Development Team** and community. GPL v2+ license.

- Upstream repo: <https://github.com/TYPO3/typo3>
- Website: <https://typo3.org>
- Docs: <https://docs.typo3.org>
- Extension Registry: <https://extensions.typo3.org>
- Install guide: <https://docs.typo3.org/installation>
- Docker Hub: <https://hub.docker.com/r/typo3/cms-base-image>

## Architecture in one minute

- **PHP 8.2+** backend (Symfony components under the hood)
- **MySQL 8+ / PostgreSQL 12+ / SQLite** database
- **Apache or nginx** web server with rewrite rules
- Standard PHP + web server + DB stack — no exotic runtime dependencies
- Backend (admin interface) + Frontend (site rendering) are cleanly separated
- Extensible via TYPO3 Extension API + Extbase MVC framework
- Resource: **medium** — PHP + DB; scales with caching (Redis/Memcached)

## Compatible install methods

| Infra         | Runtime                      | Notes                                                               |
| ------------- | ---------------------------- | ------------------------------------------------------------------- |
| **DDEV**      | DDEV local dev environment   | **Recommended for dev** — `ddev config --project-type=typo3 && ddev start` |
| **Composer**  | `composer create-project typo3/cms-base-distribution` | Standard install; requires PHP + web server |
| **Docker**    | `typo3/cms-base-image`       | Base Docker image; community compose examples available             |
| **Hosting**   | Shared PHP hosting (cPanel)  | Many European hosts support TYPO3 natively                          |

## System requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| PHP | 8.2 | 8.3 |
| MySQL | 8.0 | 8.0+ |
| PostgreSQL | 12 | 15+ |
| Web server | Apache 2.4 / nginx | nginx |
| Memory | 256 MB PHP | 512+ MB |

Full requirements: <https://docs.typo3.org/system-requirements>

## Install via Composer (recommended production method)

```bash
# Install TYPO3 v13 (latest LTS)
composer create-project typo3/cms-base-distribution my-typo3 ^13

cd my-typo3

# Create initial admin user
./vendor/bin/typo3 setup

# Start built-in PHP server (dev only)
php -S localhost:8080 -t public
```

Then configure your web server to point document root to `public/`.

## Install via DDEV (local dev)

```bash
mkdir my-typo3 && cd my-typo3
ddev config --project-type=typo3 --php-version=8.3
ddev start
ddev composer create typo3/cms-base-distribution
ddev typo3 setup
ddev launch
```

Full DDEV guide: <https://docs.typo3.org/installation>

## First boot

1. Run `composer create-project` or DDEV setup.
2. Configure database connection (set `TYPO3_DB_*` env vars or fill in the Install Tool wizard).
3. Run `./vendor/bin/typo3 setup` — creates admin user + initializes DB.
4. Access backend at `https://your-site.com/typo3/`.
5. Install a site package or distribution to bootstrap a complete site.
6. Configure pages, templates, and content in the backend.
7. Install extensions via Extension Manager or Composer.

## TYPO3 backend access

Backend URL: `http://your-site/typo3/`

Key backend modules:

| Module | Purpose |
|--------|---------|
| Web → Page | Edit page tree and content elements |
| Web → List | Direct database/record view |
| File → Filelist | Media and file management |
| Admin Tools → Install | System maintenance and config |
| Extension Manager | Install/uninstall extensions |
| Template | TypoScript template editor |
| Scheduler | Background task scheduler |

## Key concepts

| Concept | Description |
|---------|-------------|
| **TypoScript** | TYPO3's proprietary configuration language for rendering control |
| **Page tree** | Hierarchical page structure; every URL is a page record |
| **Content elements** | Reusable content blocks on pages (text, images, plugins, etc.) |
| **Extensions** | Plugins that extend TYPO3 — install via Composer or Extension Manager |
| **Fluid templates** | HTML + Fluid templating engine for frontend rendering |
| **Extbase** | MVC framework for building extensions |
| **Site configuration** | YAML config defining domains, languages, routes |
| **Scheduler** | Background task runner for periodic tasks |

## Gotchas

- **TYPO3 is a framework, not a blog CMS.** If you just want to publish a blog or simple site, WordPress or TYPO3 is probably overkill. TYPO3 excels at complex, multi-site, multi-language enterprise sites with strict access controls and custom content models.
- **TypoScript learning curve.** TypoScript is TYPO3's proprietary configuration language for rendering. It's powerful but has a steep learning curve. Modern TYPO3 (v12/v13) increasingly replaces TypoScript with YAML site config and Fluid templates — but you'll still encounter TypoScript everywhere.
- **Always use Composer for extensions.** Don't use the Extension Manager's built-in download for production — use `composer require vendor/extension`. This ensures proper version management and lock files.
- **LTS vs non-LTS.** TYPO3 has a clear release cycle — pick an LTS version for production (v12 LTS or v13 LTS). LTS versions receive security updates for 5 years.
- **PHP-FPM + nginx is the standard production setup.** The PHP built-in server is dev-only. Configure nginx with TYPO3's recommended rewrite rules.
- **Caching.** TYPO3 has a multi-level caching system. For production, configure a cache backend (Redis or Memcached) for significant performance improvements. Default is file-based caching.
- **Install Tool = sensitive.** The TYPO3 Install Tool (admin panel for sys-level config, DB updates, etc.) should be password-protected in production. It's at `/typo3/install.php`.
- **Upgrade path.** TYPO3 major upgrades (v11→v12→v13) are well-documented but require migration of deprecated APIs and extension compatibility checks. TYPO3 maintains a strict deprecation policy and migration scripts.

## Backup

```sh
# DB dump
mysqldump typo3 > typo3-$(date +%F).sql
# Files
tar czf typo3-files-$(date +%F).tgz public/fileadmin/ public/typo3conf/
```

## Project health

25+ year active PHP development, LTS release cycle (5 years), 60,000+ extensions, enterprise adoption, comprehensive docs. Active TYPO3 Association + Oy. GPL v2+.

## CMS-family comparison

- **TYPO3** — PHP, enterprise, multi-site/multi-language, TypoScript, 60k+ extensions, steep learning curve, GPL
- **WordPress** — PHP, simplest setup, largest plugin ecosystem; less suited for enterprise multi-site
- **Drupal** — PHP, enterprise, structured content; different philosophy; better US market presence
- **NEOS CMS** — PHP, modern content editing (inline), smaller community; shares TYPO3 Flow foundation
- **Craft CMS** — PHP, elegant developer experience; commercial licensing

**Choose TYPO3 if:** you're building a complex, multi-site, multi-language enterprise website and need fine-grained content control, strong access permissions, and a 25-year track record in European enterprise/government/university deployments.

## Links

- Repo: <https://github.com/TYPO3/typo3>
- Docs: <https://docs.typo3.org>
- Install guide: <https://docs.typo3.org/installation>
- Extensions: <https://extensions.typo3.org>
- Docker: <https://hub.docker.com/r/typo3/cms-base-image>
- get.typo3.org: <https://get.typo3.org>
