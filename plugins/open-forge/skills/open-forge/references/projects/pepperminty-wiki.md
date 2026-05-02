# Pepperminty Wiki

**What it is:** A complete wiki engine contained in a single PHP file. Drop it on any PHP-enabled web server and you have a fully-functional wiki with file uploads, page revision history, tags, full-text search, and more — no database required.

**Official URL:** https://github.com/sbrl/Pepperminty-Wiki
**Website:** https://peppermint.mooncarrot.space/
**Docs:** https://starbeamrainbowlabs.com/labs/peppermint/__nightdocs/01-Welcome.html
**Docker Hub:** `sqlatenwiki/peppermintywiki`
**License:** MPL-2.0
**Stack:** PHP (single file) + flat-file storage

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | PHP + web server (Apache/Nginx) | Recommended; single file drop-in |
| Any Linux VPS / bare metal | Docker | Official image available |
| Homelab (Pi, NAS) | PHP + web server | Lightweight, works on low-spec hardware |
| Shared hosting | PHP | Works anywhere PHP is available |

---

## Inputs to Collect

### Pre-deployment
- Web server root / virtual host document root
- Admin username and password (set in `peppermint.php` config section or via first-run setup)
- Storage directory path (default: same directory as the PHP file)

### Runtime
- Wiki name and site title
- Allowed file upload types and max upload size
- Module selection (modules are built into the single file; choose at download time via the configurator)

---

## Software-Layer Concerns

**Installation:** Download the single `index.php` file (or build a custom version at the online configurator) and place it in your web root. Point your web server at it.

**No database:** All data is stored in flat files in the same directory. Back up the whole folder.

**Config:** Stored at the top of `index.php` — edit the `$settings` array directly, or use the admin panel after first login.

**Default port:** Whatever your web server uses (80/443).

**File structure:**
```
/wiki/
  index.php        ← the entire wiki engine
  data/            ← pages and uploads stored here (auto-created)
  .htaccess        ← optional, for pretty URLs with Apache
```

**Docker quick start:**
```bash
docker run -d \
  -p 8080:80 \
  -v ./wiki-data:/var/www/html/data \
  sqlatenwiki/peppermintywiki
```

See the [Getting Started / Docker](https://starbeamrainbowlabs.com/labs/peppermint/__nightdocs/04-Getting-Started.html#Docker) docs for the full Docker setup.

**Upgrade procedure:**
1. Download the new `index.php`
2. Replace the old file (data directory is untouched)
3. Check the [Changelog](https://github.com/sbrl/Pepperminty-Wiki/blob/master/Changelog.md) for config key changes

---

## Gotchas

- **Single file = single point of configuration** — all settings are in the PHP file itself; keep a backup before upgrading
- **Flat-file storage** — no concurrent write protection; avoid heavy simultaneous edits
- **Module selection happens at download time** — use the online configurator to pick modules; you can't add modules after download without rebuilding
- **No built-in HTTPS** — put behind a reverse proxy (Caddy/Nginx) for TLS
- **CardDav/CalDAV sync not included** — pure wiki only
- Android app exists in beta: https://play.google.com/apps/testing/com.sbrl.peppermint

---

## Links
- GitHub: https://github.com/sbrl/Pepperminty-Wiki
- Docs: https://starbeamrainbowlabs.com/labs/peppermint/__nightdocs/01-Welcome.html
- Online configurator: https://peppermint.mooncarrot.space/
- Changelog: https://github.com/sbrl/Pepperminty-Wiki/blob/master/Changelog.md
