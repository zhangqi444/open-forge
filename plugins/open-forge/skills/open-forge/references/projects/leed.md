# Leed

**What it is:** A free and minimal self-hosted RSS/Atom feed aggregator (the name is a contraction of "Light Feed"). Runs on your own server, fetches feeds via cron, and presents them in a clean reader interface. Supports OPML import/export for migrating from other RSS readers. Multilingual (French, English, Spanish). Plugin system via Leed-market.

**Official URL:** https://github.com/LeedRSS/Leed
**License:** AGPL-3.0
**Stack:** PHP 7.2+ + MySQL + Apache; no official Docker image

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Apache + PHP + MySQL | Traditional LAMP stack |
| Shared hosting | Apache + PHP + MySQL | Works on standard shared hosting with cron access |

> **Note:** No official Docker image. Designed for classic LAMP hosting.

---

## Inputs to Collect

### Pre-deployment
- MySQL database credentials — host, database, user, password
- Web server document root — where to place the Leed files
- Cron access — required to automatically fetch/update feeds

---

## Software-Layer Concerns

**Installation:**
1. Download the latest release from https://github.com/LeedRSS/Leed/releases/latest
2. Upload/extract to your web server directory
3. Set permissions: `chmod 775` on the folder and contents (or `0755` on OVH/some shared hosts)
4. Visit `http://your.domain/leed/install.php` in a browser and follow the wizard
5. **Delete `install.php`** after installation completes (security)

**Feed sync via cron** — choose one method:

Option 1 (local/direct — produces formatted console output):
```bash
# crontab -e
0 * * * * cd /path/to/leed && php action.php >> logs/cron.log 2>&1
```

Option 2 (remote via wget — can be triggered externally):
```bash
0 * * * * wget --no-check-certificate --quiet --output-document /dev/null \
  "http://127.0.0.1/leed/action.php?action=synchronize&code=YOUR_SYNC_CODE"
```
The sync code is set during installation and visible in the Leed admin panel.

**OPML import/export:** Available in the admin interface for migrating feeds to/from other readers.

**Plugins:** Install via the [Leed-market](https://github.com/Leed-market) repository — browse approved plugins and copy to the `plugins/` directory.

**Upgrade procedure:**
1. Back up your database
2. Download the new release and overwrite existing files
3. Visit the admin panel — Leed will run any needed DB migrations

---

## Gotchas

- **Apache recommended** — README notes it has not been tested on nginx; may require additional configuration for nginx rewrite rules
- **Cron is required** — without cron, feeds only update when you manually trigger synchronization from the admin panel
- **Delete `install.php`** — leaving it accessible post-install is a security risk
- **Single-user by default** — Leed is designed primarily as a personal RSS reader; multi-user support is limited

---

## Links
- GitHub: https://github.com/LeedRSS/Leed
- Plugins (Leed-market): https://github.com/Leed-market
- Releases: https://github.com/LeedRSS/Leed/releases/latest
