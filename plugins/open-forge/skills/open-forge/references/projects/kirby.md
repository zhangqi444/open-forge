---
name: kirby
description: Kirby recipe for open-forge. Flexible file-based PHP CMS with no database required. Easy setup, powerful panel editor, and developer-friendly templating with Twig-like syntax. Commercial license required for production use. Source: https://github.com/getkirby/kirby
---

# Kirby

Flexible, file-based PHP CMS with no database required — content is stored in plain text files and folders. Ships with a powerful browser-based Panel editor, customizable content blueprints, and a clean PHP templating system. Loved by developers for its flexibility: build anything from personal blogs to agency sites and headless APIs. **Not free software** — a license is required for production use (free trial available). Upstream: https://github.com/getkirby/kirby. Docs: https://getkirby.com/docs.

> ⚠️ **License**: Kirby requires a paid license per site for production use. Free for local/test environments. See https://getkirby.com/buy.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Starterkit (Composer) | Linux / macOS / Windows | Recommended. Full example site with content. |
| Plainkit (Composer) | Linux / macOS / Windows | Minimal scaffold, blank slate. |
| Manual ZIP download | Linux / macOS / Windows | No Composer required. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "PHP version?" | PHP 8.1+ required; 8.2+ recommended |
| install | "Web server type?" | Apache (built-in support), Nginx, or Caddy |
| auth | "Panel admin username + email + password?" | Created via Kirby Panel first-run setup |
| license | "Kirby license key?" | Required before going live on production |

## Software-layer concerns

### Install via Composer (Starterkit — recommended)

  composer create-project getkirby/starterkit mysite
  cd mysite

  # Or the minimal Plainkit:
  composer create-project getkirby/plainkit mysite

### Install via ZIP (no Composer)

  # Download Starterkit from: https://github.com/getkirby/starterkit/releases/latest
  # Unzip and upload to your server.

### Directory structure

  content/          # All content (plain text files + folders — this IS the database)
  kirby/            # Kirby core (do not edit)
  media/            # Auto-generated thumbnails and file cache (writable)
  site/             # Your site customizations
  site/blueprints/  # Content structure definitions
  site/controllers/ # Page controllers
  site/snippets/    # Reusable template partials
  site/templates/   # Page templates
  index.php         # Entry point
  .htaccess         # Apache rewrite rules (included)

### Apache configuration

  # Web root: project root (not a subdirectory)
  # The included .htaccess handles URL routing.
  # Ensure mod_rewrite is enabled:
  a2enmod rewrite
  # AllowOverride All must be set for the vhost directory.

### Nginx configuration

  # Web root: project root
  server {
      root /var/www/mysite;
      index index.php;

      location / {
          try_files $uri $uri/ /index.php$is_args$args;
      }

      location ~ \.php$ {
          fastcgi_pass unix:/run/php/php8.2-fpm.sock;
          fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
          include fastcgi_params;
      }

      # Protect sensitive directories:
      location ~ ^/(kirby|site/config) {
          deny all;
      }
  }

### First-time Panel setup

  # Navigate to: https://yoursite.com/panel
  # Kirby will prompt you to create an admin account on first visit.
  # No database or CLI setup required.

### Configuration (site/config/config.php)

  <?php
  return [
      'debug' => false,                      // set true in dev only
      'panel' => ['install' => false],       // set true on first install if needed
      'url' => 'https://yoursite.com',       // canonical URL
  ];

### Key PHP extensions required

  # gd or imagick (for image resizing)
  # mbstring, curl, json, zip

### File permissions

  chown -R www-data:www-data content/ media/ site/
  chmod -R 755 content/ media/

### Environment-specific config

  # Kirby supports per-environment configs:
  site/config/config.localhost.php    # dev overrides
  site/config/config.example.com.php # production overrides

## Upgrade procedure

  # Via Composer:
  composer update getkirby/cms

  # Or download new Kirby ZIP and replace the kirby/ folder.
  # Never overwrite: content/, site/, index.php, .htaccess

## Gotchas

- **Not free for production**: Kirby requires a license ($109 per site, one-time) before going live. Develop/test locally for free.
- **content/ is the database**: all content lives in flat files under `content/`. Back this directory up. It's easy to version-control with git.
- **media/ is cache**: the `media/` directory contains auto-generated thumbnails. It's safe to delete (will be regenerated). Do not commit it to git.
- **Panel not required**: Kirby can be used as a headless CMS. The Panel is optional — disable it entirely if not needed by setting `'panel' => false` in config.
- **No database migrations**: content changes are file edits. Changing field names in blueprints requires manually renaming content file fields.
- **PHP sessions**: Kirby uses PHP sessions for Panel auth. Ensure session.save_path is writable on the server.
- **Kirby 4 vs 3**: Kirby 4 (current) requires PHP 8.1+. Kirby 3 requires PHP 7.4+. They are not drop-in compatible; check migration guides if upgrading.

## References

- Upstream GitHub: https://github.com/getkirby/kirby
- Starterkit: https://github.com/getkirby/starterkit
- Plainkit: https://github.com/getkirby/plainkit
- Documentation: https://getkirby.com/docs/guide
- Quickstart: https://getkirby.com/docs/guide/quickstart
- Nginx setup: https://getkirby.com/docs/cookbook/setup/nginx
- License + pricing: https://getkirby.com/buy
