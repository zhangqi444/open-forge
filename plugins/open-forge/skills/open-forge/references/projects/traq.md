# Traq

**Project management and issue tracking system** written in PHP. Tracks issues for multiple projects with multiple milestones. Alpha-stage development as of latest release.

**Official site:** https://traq.io  
**Source:** https://github.com/nirix/traq  
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | PHP 8.3+ + MariaDB/MySQL + web server | Native install; no official Docker image |
| VPS / server | Apache with mod_rewrite | Primary documented setup |
| VPS / server | nginx | Configure `try_files` for clean URLs |

---

## Requirements

- PHP 8.3+
- MariaDB (or MySQL)
- Apache with `mod_rewrite` (or nginx configured as 404 fallback to `index.php`)
- Composer (PHP dependency manager)
- pnpm (Node.js package manager, for frontend build)
- Node.js

---

## Inputs to Collect

### Provision phase
| Input | Description |
|-------|-------------|
| `DB_HOST` | MariaDB/MySQL hostname |
| `DB_NAME` | Database name |
| `DB_USER` | Database username |
| `DB_PASS` | Database password |
| `APP_URL` | Public URL of the Traq instance |

---

## Software-layer Concerns

### Installation
```bash
git clone https://github.com/nirix/traq
cd traq

# Install PHP dependencies
composer install

# Install Node dependencies and build frontend
pnpm install
pnpm run build

# Configure web server to serve from project root
# For Apache: rename htaccess.txt → .htaccess
mv htaccess.txt .htaccess

# Browse to your domain and follow the web installer
```

### nginx clean URL config
```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
# Or configure index.php as the 404 handler as noted in docs
```

### Apache `.htaccess`
Rename the provided `htaccess.txt` to `.htaccess` in the project root. Requires `mod_rewrite` enabled.

### Persistent data
Traq stores all data in MariaDB/MySQL. Back up the database regularly:
```bash
mysqldump -u traq_user -p traq_db > backup-$(date +%F).sql
```

---

## Upgrade Procedure

1. Pull latest code:
   ```bash
   git pull origin main
   ```
2. Update dependencies:
   ```bash
   composer install
   pnpm install
   pnpm run build
   ```
3. Run any database migrations (check release notes for migration steps)
4. Clear any application cache if applicable

---

## Gotchas

- **Alpha software.** As of v3.9.0-alpha.1, Traq is under active development and may have breaking changes between releases. Not recommended for production without testing.
- **No Docker image.** There is no official Docker image; you'll need to containerize manually or run natively.
- **`.htaccess` rename required for Apache.** The repo ships `htaccess.txt` — it must be renamed to `.htaccess` before Apache clean URLs will work.
- **pnpm required** (not npm or yarn) for the Node.js frontend build step.
- **PHP 8.3+ required.** Older PHP versions are not supported.

---

## References

- Upstream README: https://github.com/nirix/traq#readme
- Official site: https://traq.io
