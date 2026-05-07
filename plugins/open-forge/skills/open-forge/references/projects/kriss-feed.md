---
name: kriss-feed
description: Kriss Feed recipe for open-forge. Simple self-hosted RSS/Atom feed reader. Single PHP file, no database. Add feeds, browse in list/expanded/reader view, OPML import/export. Source: https://github.com/tontof/kriss_feed
---

# Kriss Feed

Simple and minimal self-hosted RSS/Atom feed reader. Single PHP file — no database, no installation wizard. Drop it on any PHP-capable web server and you're done. Features include add/remove feeds, list/expanded/reader view, mark as read, OPML import/export, auto-update, lazy loading on scroll, and optional Shaarli integration. CC0-1.0 licensed (public domain).

Upstream: <https://github.com/tontof/kriss_feed>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | PHP 5.4+ (any web server) | Single file — drop in any PHP directory |
| Any | Docker (any PHP image) | Mount as web root |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Password | Set during first visit or in index.php (see gotchas) |
| config (optional) | Shaarli URL | For sharing links via Shaarli |

## Software-layer concerns

### Architecture

- Single `index.php` file — contains entire application
- No database — data stored in flat files in the same directory (gitignored `data/` folder)
- PHP cURL or allow_url_fopen required for fetching feeds

### Data files

Kriss Feed stores its data in flat files next to `index.php` (in a `data/` directory it creates):
- Feed list and metadata
- Cached articles (last 10 per feed)

## Install

```bash
# Download single file
wget https://raw.githubusercontent.com/tontof/kriss_feed/master/index.php -O index.php

# Place in any PHP-served directory
# e.g. /var/www/html/feed/index.php

# Set write permissions for data directory
chmod 755 /var/www/html/feed/
```

Access at http://yourserver/feed/ — set your password on first visit.

## Install — Docker

```bash
mkdir kriss-feed && cd kriss-feed
wget https://raw.githubusercontent.com/tontof/kriss_feed/master/index.php

docker run -d \
  --name kriss-feed \
  --restart unless-stopped \
  -p 8080:80 \
  -v $(pwd):/var/www/html \
  php:8-apache
```

## Upgrade procedure

```bash
# Just overwrite index.php with the latest version
# Data files are preserved (they're in data/ subdirectory)
wget https://raw.githubusercontent.com/tontof/kriss_feed/master/index.php -O index.php
```

## Gotchas

- Single file with no separate config — password and settings are stored inside the flat data files created on first use. The first visit sets the admin password.
- No authentication by default until you set a password on first visit — set the password immediately after placing the file on the server.
- Data directory must be writable by the web server — if the web server user can't write to the directory containing `index.php`, feed fetching and caching will fail silently.
- The project uses CC0 (public domain) — feel free to modify or redistribute without restrictions.
- PHP cURL or `allow_url_fopen` must be enabled — required to fetch RSS/Atom feeds from external URLs.
- Last major version (v8) — project is maintained as stable but not actively developed.

## Links

- Source: https://github.com/tontof/kriss_feed
- Demo: http://tontof.net/feed
