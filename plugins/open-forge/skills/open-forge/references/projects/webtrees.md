# webtrees

**Web's leading self-hosted online collaborative genealogy application — works with standard GEDCOM files, full editing and privacy controls, multi-user collaboration, and media support.**
Official site: https://webtrees.net
GitHub: https://github.com/fisharebest/webtrees

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | PHP + web server | Apache or NGINX with PHP; MySQL recommended |
| Any Linux | Docker | Community Docker images available |

---

## Inputs to Collect

### Required
- Web server — Apache or NGINX with URL rewriting enabled
- PHP 7.1–7.4 (webtrees 2.x); PHP 5.3–7.0 for webtrees 1.7
- Database — MySQL recommended; PostgreSQL, SQL Server, SQLite supported
- Database credentials — host, name, user, password

### Optional
- GEDCOM file — import existing family tree data
- Media files — photos, documents linked to individuals

---

## Software-Layer Concerns

### Installation (standard)
1. Download the latest release ZIP from https://github.com/fisharebest/webtrees/releases/latest
2. Unzip and upload to a web-accessible directory
3. Visit the URL in a browser — setup wizard starts automatically
4. Create your first family tree; import GEDCOM if available

### System requirements
- ~100 MB disk for application; additional for media/GEDCOM files
- PHP with adequate memory and execution time for your tree size
- MySQL strongly recommended for correct locale-aware name sorting

### Database table prefix
webtrees uses a configurable table prefix, allowing multiple instances in the same database.

### "Pretty URLs"
Requires URL rewriting configured on the web server (mod_rewrite for Apache, try_files for NGINX).

---

## Upgrade Procedure

**Automatic (recommended):**
Admin login → notification of new version → automatic upgrade option

**Manual:**
1. Backup the database and files
2. Create `data/offline.txt` to show maintenance page during upload
3. Download latest ZIP, overwrite files
4. Delete `data/offline.txt`
5. Run database migrations if prompted

---

## Gotchas

- MySQL/MariaDB is strongly preferred — other databases may not sort names correctly per locale
- PHP execution time and memory limits may need tuning for large trees
- Automatic upgrade is available from the admin panel — manual upgrade only needed if auto fails
- webtrees 1.7 is the last version supporting PHP < 7.1

---

## References
- Official site & demo: https://webtrees.net
- Forum / support: https://www.webtrees.net/index.php/forum
- GitHub: https://github.com/fisharebest/webtrees#readme
