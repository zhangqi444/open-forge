# WikiDocs

**Databaseless markdown flat-file wiki engine**
Official site: https://www.wikidocs.app

WikiDocs is a simple wiki built on plain markdown files — no database required. Supports WYSIWYG editing, KaTeX math, image uploads, page revisions, namespaces, sitemap generation, public/private browsing, and syntax highlighting. Runs via PHP + Apache in Docker.

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Docker host | docker-compose | Single container, no external dependencies |
| Any Docker host | docker run | Quick single-command start |
| VPS / bare metal | PHP 7.0+ + Apache/Nginx | Manual install; Apache mod_rewrite required |

## Inputs to Collect

### Phase: Pre-deployment
- `PUID` — user ID for file ownership (default: `1000`)
- `PGID` — group ID for file ownership (default: `1000`)
- Data directory path to bind-mount at `/datasets`

## Software-Layer Concerns

**Docker image:** `zavy86/wikidocs`

**Data volume:** `/datasets` — contains all wiki pages, config, attachments, and uploads; **back this up**

**Port:** `80` inside container; map to any host port

**First-run setup:**
- Visit `http://your-host/setup.php` to auto-generate `datasets/config.inc.php` and `.htaccess`
- Or manually copy `config.sample.inc.php` to `datasets/config.inc.php` and configure

**Authentication:** Set via config — wiki supports both public (read-only) and private (code-protected) access. Default auth code is set in config file.

**Apache requirement:** For bare-metal installs, `mod_rewrite` must be enabled; the Docker image handles this automatically.

## Upgrade Procedure

1. Pull latest image: `docker-compose pull`
2. Recreate: `docker-compose up -d`
3. All wiki content in `/datasets` persists across upgrades
4. Check release notes for config format changes before major version upgrades

## Gotchas

- **Run setup.php first** — on a fresh install, visiting any page before setup will fail; go to `/setup.php` first
- **PUID/PGID must match host bind-mount owner** — if files in `./datasets` are owned by root but container runs as UID 1000, uploads will fail
- **Flat-file means no search index** — full-text search is limited compared to database-backed wikis
- **Apache-only in Docker** — the official image uses Apache; Nginx users should use bare-metal install with appropriate rewrite rules
- **No built-in user management** — access control is based on a single authentication code, not per-user accounts

## References
- Upstream README: https://github.com/Zavy86/wikidocs/blob/HEAD/README.md
- Docker Hub: https://hub.docker.com/r/zavy86/wikidocs
- Demo: http://demo.wikidocs.app (auth code: `demo`)
