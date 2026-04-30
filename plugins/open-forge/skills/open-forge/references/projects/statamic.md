---
name: Statamic
description: "Flat-first, Laravel + Git powered CMS — Markdown/YAML content on disk + Antlers/Blade templating + Control Panel. Fieldsets, Collections, Taxonomies, Globals. MIT (core) + Statamic Pro (commercial). Installs as Composer package into existing Laravel app."
---

# Statamic

Statamic is **"a CMS that's just flat files, a Laravel app, and Git"** — content is **Markdown + YAML files on disk** (not a database table), meaning **your entire site is version-controlled** by default. Use it to build marketing sites, portfolios, docs, blogs, e-commerce, company sites — anything where content + design + code evolve together.

Built by **Wilderborn / Jason Varga / Jack McDade** — the commercial Statamic Corp. The core is **MIT-licensed** (free); **Statamic Pro** is a commercial license unlocking Forms, Users, Assets beyond basics, advanced features — essentially: **commercially sustainable open-source CMS with a Pro tier**.

Features (combined MIT core + Pro):

- **Flat-first content** — Markdown + YAML → Git-native workflow
- **Laravel-native** — build with full Laravel framework
- **Control Panel** — modern admin UI for non-technical authors
- **Antlers** — Statamic's templating language (plus Blade support)
- **Collections + Entries** — flexible content types
- **Taxonomies** — tags/categories with first-class support
- **Globals** — shared values (site title, social links)
- **Fieldtypes** — 40+ built-in (Bard rich-text, Replicator, Assets, ...)
- **Assets** — image+file management; Glide-powered transformations
- **Multi-site** — multiple domains from one installation
- **Localization** — multi-language
- **Users + Roles + Permissions** (Pro)
- **Forms** (Pro for advanced)
- **Static caching** — optional; cached HTML for speed
- **Git integration** — commit on publish
- **Addons ecosystem** on <https://statamic.com/marketplace>

- Upstream repo (this package): <https://github.com/statamic/cms>
- Application repo (use this to start projects): <https://github.com/statamic/statamic>
- Docs: <https://statamic.dev>
- Homepage + commercial: <https://statamic.com>
- Discord: <https://statamic.com/discord>
- Pricing (Pro license): <https://statamic.com/pricing>
- Marketplace: <https://statamic.com/marketplace>
- Contribution guide: <https://github.com/statamic/cms/blob/master/CONTRIBUTING.md>

## Architecture in one minute

- **Laravel 10/11** under the hood
- **PHP 8.1+** required
- **Content**: `content/collections/*/*.md` YAML-front-matter Markdown files
- **No database required** by default (flat files for content). OPTIONAL DB for users/forms/auth
- **Composer** installed: `composer require statamic/cms`
- **CLI scaffold**: `statamic new site` (via installable CLI)
- **Resource**: small — typical Laravel app footprint; can run on shared hosting

## Compatible install methods

| Infra                   | Runtime                                                         | Notes                                                                          |
| ----------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / VPS         | **PHP 8.1+ + web server (nginx/Apache)**                            | **Upstream-recommended**                                                           |
| Managed PHP hosting     | Forge / Ploi / RunCloud / Cleavr / Vapor                                    | Laravel-specialist PaaS; very common                                                       |
| Docker                  | **Laravel Sail (dev)** or custom Dockerfile                                            | No official production image                                                                               |
| Kubernetes              | Standard PHP-FPM + nginx                                                                          | Works; stateful file storage needs PV if running multi-pod                                                                 |
| Shared hosting          | Any PHP 8.1+ host with Composer                                                                              | Works — flat-first = no DB req                                                                                             |
| Static export           | **Static site generation** — Statamic can publish to static HTML                                                | For max perf + zero server                                                                                                                  |
| SSG pattern via Vapor   | Laravel Vapor (AWS Lambda)                                                                                             | Possible; complex                                                                                                                          |

## Inputs to collect

| Input                | Example                                                    | Phase        | Notes                                                                        |
| -------------------- | ---------------------------------------------------------- | ------------ | ---------------------------------------------------------------------------- |
| Domain               | `example.com`                                                  | URL          | TLS via web server                                                                   |
| PHP                  | 8.1 minimum; 8.3+ recommended                                        | Runtime      | Plus extensions: OpenSSL, PDO, Mbstring, Tokenizer, XML, Ctype, JSON, BCMath, Fileinfo                       |
| Composer             | 2.x                                                                    | Dependency   | PHP dep-manager                                                                                       |
| Storage              | Content = Git; Assets (uploads) = disk or S3                                     | Storage      | Plan for user-uploaded assets                                                                                              |
| Statamic Pro license | optional; ~$275/site or subscription                                                 | License      | Required for advanced features (Users roles, Forms Pro, etc.)                                                                              |
| Git remote           | GitHub / GitLab / ...                                                             | Workflow     | Content-as-code; deploy via git-pull or CI                                                                                                                |
| SMTP                 | transactional email                                                                         | Email        | For Forms (Pro)                                                                                                                                  |

## Install

Start from the application scaffold (recommended):

```sh
# Via Statamic CLI (recommended):
composer global require statamic/cli
statamic new my-site
cd my-site
php artisan serve
# admin at /cp — prompt creates first admin
```

Or into an existing Laravel app:
```sh
composer require statamic/cms
php please install
```

## First boot

1. Create first admin user (`php please make:user`) — **strong password + 2FA** if Pro
2. Configure site(s) in `config/statamic/sites.php` (multi-site if needed)
3. Build your first Collection: `php please make:collection pages`
4. Define Blueprint (fields) for Collection in Control Panel
5. Create entries in CP → preview via Antlers/Blade templates
6. Git-commit content
7. For production: set `APP_ENV=production`, `APP_DEBUG=false`, `APP_KEY` generated
8. Configure caching: static-cache for max perf; Stache for content-indexing
9. Deploy: push to Git → deploy via Forge/Ploi/CI
10. Configure backups: files + (if using DB for users/forms) DB

## Data & config layout

- `content/collections/` — content entries (.md with YAML front-matter)
- `content/taxonomies/` — tags/categories
- `content/globals/` — shared values
- `content/trees/` — navigation structures
- `resources/blueprints/` — field definitions
- `resources/fieldsets/` — reusable field groups
- `resources/views/` — Antlers/Blade templates
- `public/assets/` or S3 — user uploads
- `users/` — user YAML (flat files) by default; optional DB driver
- `.env` — secrets (APP_KEY, DB, mail, etc.) — **never commit**
- Git-tracked: everything above EXCEPT `.env`, `storage/`, `vendor/`, `public/assets/`

## Backup

Most content is in Git — that's half the backup. Still:
```sh
# Back up storage/ (cache, logs, user uploads if local-disk) + .env + DB if applicable
sudo tar czf statamic-$(date +%F).tgz .env storage/ public/assets/
# If using DB for users/forms:
mysqldump -u user -p statamic > statamic-db-$(date +%F).sql
```

Assets on S3 don't need tarring (S3 lifecycle/versioning).

## Upgrade

1. Releases: <https://github.com/statamic/cms/releases>. Very active cadence.
2. Composer: `composer update statamic/cms` → `php please statamic:install`
3. **Read upgrade guide** — Statamic has documented v4→v5 style migration steps.
4. **Back up `.env`, `content/`, `users/` first.**
5. Laravel version alignment: Statamic requires specific Laravel major; bumping = coordinated.

## Gotchas

- **Flat-first = Git-native + 1 site.** Strength: content review = PR review. Weakness: scaling to many authors editing simultaneously = merge-conflict risk. For high-volume multi-author sites, consider DB-backed CMSes (Drupal, WordPress) instead.
- **`.env` file lives in production** — APP_KEY, DB creds, mail passwords. Lock down perms (`chmod 600`) + exclude from backups you share.
- **APP_KEY rotation breaks encrypted values**: Laravel uses APP_KEY for encrypted cookie/session data. Rotating APP_KEY mid-production = all existing sessions invalid + encrypted DB columns unreadable. Set once + back up — same immutability pattern as Rallly `SECRET_KEY` (batch 75).
- **Statamic Pro licensing**: one-time-ish purchase per site. License revocation on non-payment WILL disable Pro features in production. Budget as permanent line item.
- **Free vs Pro feature line**: Free includes most content workflows. Pro adds Users/Roles (multi-author), Forms management, Revisions, Multi-site beyond 1, Impersonation. Evaluate needs honestly.
- **Authors need Git training** or stay entirely in the CP. "Content editor accidentally force-pushes" is a real failure mode. Consider workflow: editors use CP → auto-commit → admin reviews.
- **Static caching = massive perf, but**: cache invalidation is the classic hard problem. Full-static requires diligent cache-busting on entry updates. Start with Stache (content-indexed), upgrade to static-cache when traffic warrants.
- **Antlers vs Blade**: Antlers is Statamic-native + templating language; Blade is Laravel. Both supported. For Statamic-only devs → Antlers simpler. For Laravel-experienced → Blade saves context-switching.
- **Assets + cloud storage**: default is local disk. For multi-server / autoscaling → S3/Spaces/R2 via Laravel Filesystems. Glide transformations work with cloud disks.
- **Mobile app for CP**: no official. CP is responsive-web-capable.
- **Comparison to WordPress**: WP = database, PHP, massive ecosystem, plugin security nightmares. Statamic = flat files, Laravel, smaller ecosystem, more developer-centric. For developer-built marketing sites → Statamic. For non-tech-founder-launching-blog → WP still reigns.
- **Comparison to Ghost**: Ghost = Node, membership-focused, simpler scope. Statamic = PHP, more flexible, CMS-general.
- **Comparison to headless CMSes** (Strapi, Directus): Statamic is MORE integrated (templating + content together). Headless is decoupled. Different architectures.
- **License**: **MIT** (core) + **Pro commercial**. Source is open. Pro features gated by license key.
- **Project health**: Statamic Corp commercially supports the project. Funding via Pro + services = sustainable. Long runway, no bus-factor risk.
- **Ethical purchase**: buying Statamic Pro directly funds the open-source core. Pattern matches Write.as / Rallly managed-tier (batch 74-75) — commercial tier sustains the OSS.
- **Alternatives worth knowing:**
  - **WordPress** — database, biggest ecosystem, largest attack surface
  - **Ghost** — Node, membership-first, blog-focused
  - **Kirby** — PHP, flat-file, commercial (not OSS)
  - **Grav** — PHP, flat-file, MIT
  - **Craft CMS** — PHP, database, commercial
  - **Directus / Strapi** — headless CMS
  - **Eleventy / Hugo / Astro** — static site generators (no CMS UI)
  - **Decap CMS / Tina CMS** — Git-based CMS UI over static site
  - **Choose Statamic if:** Laravel shop + marketing/content site + Git-native workflow + some budget for Pro.
  - **Choose WordPress if:** non-technical authors + maximum plugin ecosystem.
  - **Choose Ghost if:** newsletter/membership primary use-case.
  - **Choose Hugo/Eleventy if:** developer-only + no CMS UI needed.

## Links

- Repo (core package): <https://github.com/statamic/cms>
- Application repo (start here): <https://github.com/statamic/statamic>
- Docs: <https://statamic.dev>
- Homepage: <https://statamic.com>
- Pricing: <https://statamic.com/pricing>
- Marketplace: <https://statamic.com/marketplace>
- Discord: <https://statamic.com/discord>
- Discussions: <https://github.com/statamic/cms/discussions>
- Code of Conduct: <https://github.com/statamic/cms/wiki/Code-of-Conduct>
- Releases: <https://github.com/statamic/cms/releases>
- Migrator (from v2/v3): <https://github.com/statamic/migrator>
- Ghost (alt): <https://ghost.org>
- Kirby (alt): <https://getkirby.com>
- Grav (alt): <https://getgrav.org>
