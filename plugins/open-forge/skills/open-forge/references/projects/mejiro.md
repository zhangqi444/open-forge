# Mejiro (Pellicola)

**Instant PHP photo gallery** — no-install photo publishing. Drop photos in a directory and Pellicola generates a responsive gallery with EXIF data, pagination, search, geotagged map display, RSS feed, and optional download links. GDPR-compliant (no external dependencies, no tracking).

> The ASD entry uses the name "Mejiro" but the actual project is called **Pellicola**.

**Source:** https://github.com/dmpop/pellicola  
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | PHP + web server (Apache/lighttpd/nginx) | No install step — clone and serve |
| Any | Docker + Caddy (auto-HTTPS) | docker-compose.yml included for HTTPS deployments |

---

## System Requirements

- PHP 7+
- PHP extensions: `GD`, `EXIF`
- Web server (Apache, lighttpd, or nginx)
- Git (optional, for cloning)

---

## Inputs to Collect

### Config (`config.php`)
| Setting | Description | Default |
|---------|-------------|---------|
| `base_url` | Public URL of the gallery | `http://127.0.0.1` |
| `photos_dir` | Directory containing photos | `photos/` |
| `photos_per_page` | Pagination size | `20` |
| `DOWNLOAD_PASSWORD` | Hashed password for downloads (optional) | `secret` (hashed) |
| `SHOW_MAP` | Show OpenStreetMap for geotagged photos | `false` |
| `allow_downloads` | Allow visitors to download originals | `false` |

---

## Software-layer Concerns

### Quick install (Debian/Ubuntu/Raspberry Pi)
```bash
curl -sSL https://raw.githubusercontent.com/dmpop/pellicola/main/install.sh | sudo bash
```

### Manual install
```bash
# Clone into web server docroot
git clone https://github.com/dmpop/pellicola.git /var/www/pellicola
# Or download ZIP and extract
# Make writable
sudo chown www-data -R /var/www/pellicola
# Edit config
nano /var/www/pellicola/config.php
# Add photos
cp *.jpg /var/www/pellicola/photos/
```

### Docker (auto-HTTPS with Caddy)
1. Edit `Caddyfile`: replace `<email address>` and `<domain name>`
2. Run:
   ```bash
   docker compose up -d
   ```

### Docker (HTTP, manual)
```bash
docker build -t pellicola .
docker run -d --rm -p 80:8000 --name=pellicola \
  -v /path/to/photos:/usr/src/pellicola/photos:rw pellicola
```

### Album structure
```
photos/                   ← root gallery (all .jpg/.jpeg/.JPG/.JPEG)
photos/album-name/        ← subdirectory = separate album
```

### Photo descriptions
- Create `photo-name.txt` alongside the image
- Multi-language: `de-photo-name.txt`, `ja-photo-name.txt`, etc.
- HTML markup supported in `.txt` files

### Password hashing (for download protection)
```bash
php -r 'echo password_hash("your-password", PASSWORD_DEFAULT);'
```
Paste the output into `config.php` as `$DOWNLOAD_PASSWORD`.

### Features
- Responsive gallery, mobile-friendly
- EXIF data display (aperture, focal length, shutter speed, ISO)
- Geotagged photo map (OpenStreetMap) when `$SHOW_MAP = true`
- Pagination (configurable photos per page)
- Basic filename/description search
- RSS feed (auto-generated)
- Multiple albums (subdirectories)
- RAW file download links (place `.raw` file alongside JPEG)
- Camera/stats page
- Random photo feature (useful for browser new-tab backgrounds)
- No external JS/CSS dependencies — fully self-contained

---

## Upgrade Procedure

```bash
git pull
# Or re-run the install script
```
Config and `photos/` directory are not overwritten.

---

## Gotchas

- **Supported formats: `.jpg`, `.jpeg`, `.JPG`, `.JPEG` only.** Other formats are ignored.
- **`config.php` `base_url` must be set correctly** — used to build RSS feed URLs and map links.
- **Write permissions required** on the `pellicola/` directory for the web server user (`www-data`).
- **Default download password is `secret`** — change it before going public by hashing a new password with the PHP command above.
- **No user accounts or auth** built-in. Password protection applies only to the download feature. Use a reverse proxy with auth for full access control.

---

## References

- Upstream README: https://github.com/dmpop/pellicola#readme
