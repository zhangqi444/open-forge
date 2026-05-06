---
name: htmly
description: HTMLy recipe for open-forge. Databaseless flat-file PHP blogging platform and CMS. Fast, simple install with no database required — content stored as plain files. Source: https://github.com/danpros/htmly
---

# HTMLy

Open-source databaseless PHP blogging platform and CMS. Uses a flat-file approach (no database required) — content is stored as plain text files. Features fast content discovery by date, category, tag, and author, with a web installer, theme support, and backup. Upstream: https://github.com/danpros/htmly. Docs: https://docs.htmly.com.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Web installer (source zip) | PHP 7.2+ on Apache/nginx | Standard. Upload zip, run install.php in browser. |
| Online installer | PHP 7.2+ on Apache/nginx | Downloads HTMLy automatically; just upload one PHP file. |
| Manual (config only) | PHP 7.2+ | Rename config.ini.example, delete install.php — no wizard needed. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Site URL?" | e.g. https://blog.example.com — set as site.url in config.ini |
| setup | "Admin username/email/password?" | Created during web installer |
| setup | "Site title and description?" | Set in installer or config.ini |
| theme | "Theme preference?" | Browse themes at htmly.com/theme |

## Software-layer concerns

### Requirements

  PHP 7.2+
  PHP extensions: mbstring, xml, intl, gd, zip

  # Debian/Ubuntu:
  apt-get install php php-mbstring php-xml php-intl php-gd php-zip

### Web installer install

  # 1. Download latest release zip from GitHub:
  #    https://github.com/danpros/htmly/releases/latest

  # 2. Upload and extract to web server document root or subdirectory
  #    e.g. /var/www/html/blog/

  # 3. Visit the installer URL:
  #    Root install:   https://example.com/install.php
  #    Subdirectory:   https://example.com/blog/install.php

  # 4. Follow the installer steps
  # 5. Delete install.php after setup (installer tries to self-delete)

### Online installer (minimal upload)

  # 1. Download only online-installer.php from latest release
  # 2. Upload to your web server
  # 3. Visit: https://example.com/online-installer.php
  # 4. The installer downloads HTMLy automatically

### Manual config (no installer)

  cp config/config.ini.example config/config.ini
  # Edit config.ini: set site.url, site.title, site.description
  rm install.php

### Key config options (config/config.ini)

  site.url = "https://blog.example.com"
  site.title = "My Blog"
  site.description = "A blog about things"
  theme = "htmly"          # theme folder name under themes/
  posts.perpage = 10

### Directory structure

  content/       - posts, pages, user content (plain text/markdown files)
  cache/         - must be writable by web server (chmod 755)
  config/        - config.ini and users
  themes/        - installed themes
  system/        - HTMLy core (do not modify)

### Apache .htaccess (required for pretty URLs)

HTMLy includes a .htaccess for Apache with mod_rewrite. Ensure:
  AllowOverride All   # in your Apache VirtualHost <Directory>

For nginx, equivalent rewrite rules are available in the docs.

### Admin panel access

  https://your-site.com/login

## Upgrade procedure

1. Back up content/ and config/ directories
2. Download new release zip
3. Extract over existing installation (content/ and config/ are preserved if not overwritten)
4. If upgrading from an older version, check the changelog for any migration steps
5. Clear the cache/ directory

## Gotchas

- **cache/ and content/ must be writable**: chmod 755 (or 775 for group) by the web server user.
- **Delete install.php**: leave it accessible and anyone can reinstall and wipe your config. Delete it immediately after setup.
- **site.url is critical**: must match the actual URL. Wrong value breaks all links and the admin login.
- **No database migrations**: flat-file means upgrades rarely break data, but clear cache/ after every upgrade.
- **mod_rewrite required on Apache**: without it, all URLs except the homepage return 404.
- **Markdown for posts**: content files use markdown. The file path and naming convention determines post URL structure — see docs.
- **Backup = zip content/ + config/**: no database dump needed, but don't forget these two directories.

## References

- Upstream GitHub: https://github.com/danpros/htmly
- Documentation: https://docs.htmly.com
- Themes: https://www.htmly.com/theme/
- Demo: http://demo.htmly.com/
