# FlatPress

**Lightweight flat-file blogging engine** — no database required. Content stored as files. Easy to install (download, unzip, upload), customizable with themes and plugins.

**Official site:** https://flatpress.org  
**Source:** https://github.com/flatpressblog/flatpress  
**Wiki / docs:** https://wiki.flatpress.org  
**License:** GPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | PHP + web server (Apache/Nginx/LiteSpeed) | No database needed |
| Shared hosting | PHP | Primary deployment target |
| VPS / Docker | PHP-FPM + nginx | Works well in a PHP container |

---

## Requirements

- PHP (any recent version; FlatPress is lightweight and broadly compatible)
- Web server with write access to FlatPress directory
- No database

---

## Inputs to Collect

### Provision phase
| Input | Description | Default |
|-------|-------------|---------|
| `DOCUMENT_ROOT` | Web root directory for FlatPress | `/var/www/flatpress` |
| `BASE_URL` | Public URL of the blog | — |

### Setup phase (web installer)
| Input | Description |
|-------|-------------|
| Admin username | Blog administrator login |
| Admin password | Blog administrator password |
| Blog title | Displayed site name |
| Timezone | Blog timezone |

---

## Software-layer Concerns

### Installation
```bash
# Download latest release from https://flatpress.org/download
unzip flatpress-*.zip -d /var/www/flatpress
chown -R www-data:www-data /var/www/flatpress
# Browse to http://your-domain/ and run the web installer
```

### Docker (PHP-FPM + nginx)
FlatPress has no official Docker image. Use a generic PHP image:
```yaml
services:
  app:
    image: php:8.3-apache
    volumes:
      - ./flatpress:/var/www/html
    ports:
      - '80:80'
```
Mount a downloaded FlatPress archive into the container's web root.

### Config paths
| Path | Purpose |
|------|---------|
| `fp-data/` | All user data: posts, comments, attachments |
| `fp-plugins/` | Plugin files |
| `fp-themes/` | Theme files |
| `fp-content/config/` | Site configuration |

Back up the entire `fp-data/` directory to preserve all content.

### URL rewriting
FlatPress uses `.htaccess` for clean URLs on Apache. For nginx, configure:
```nginx
location / {
    try_files $uri $uri/ /index.php?$args;
}
```

---

## Upgrade Procedure

1. Download the new release
2. Back up `fp-data/` and `fp-content/config/`
3. Extract the new release, overwriting all files **except** `fp-data/`
4. Visit the admin panel — FlatPress will apply any needed config migrations automatically

---

## Gotchas

- **No database** — all content is file-based. Backup is as simple as copying `fp-data/`.
- **Write permissions required.** The web server user must be able to write to `fp-data/`. If you see 500 errors after install, check permissions (`chmod -R 755 fp-data/`).
- **Plugins and themes** installed separately from https://wiki.flatpress.org.
- **Comment spam** — built-in spam protection; consider enabling CAPTCHA plugin for public blogs.
- **Multi-user** is limited; FlatPress is designed primarily for single-author blogs.

---

## References

- Upstream README: https://github.com/flatpressblog/flatpress#readme
- Installation wiki: https://wiki.flatpress.org/doc:install
- Plugin directory: https://wiki.flatpress.org/doc:plugins
