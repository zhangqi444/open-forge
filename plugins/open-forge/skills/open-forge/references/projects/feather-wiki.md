---
name: feather-wiki
description: Feather Wiki recipe for open-forge. 58KB self-contained single-HTML-file wiki — runs entirely in the browser, saves to WebDAV server or locally. No server runtime needed. AGPL-3.0, JavaScript. Source: https://codeberg.org/Alamantus/FeatherWiki
---

# Feather Wiki

A 58-kilobyte self-contained wiki that runs entirely in your browser. The entire app — UI, logic, and data — lives in a single HTML file. Like TiddlyWiki but smaller. No server runtime required; can be served from any static file host or WebDAV server with save-back support. Extensible via community extensions. AGPL-3.0, JavaScript. Source: <https://codeberg.org/Alamantus/FeatherWiki>. Website: <https://feather.wiki>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any static file host | Browser-only | Serve the HTML file — no server-side processing |
| Any WebDAV server | Browser + WebDAV | Server must return `dav` header on OPTIONS — enables "Save to Server" button |
| Any NGINX/Apache | Browser + WebDAV module | Enable WebDAV (`dav_methods PUT`) for server-save support |
| Tiddlyhost (hosted) | Hosted service | Hosted option at tiddlyhost.com — not self-hosted |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Serve from static host or WebDAV?" | Static / WebDAV | WebDAV enables automatic server-save; static = manual download-to-save |
| "Domain?" | FQDN | e.g. wiki.example.com |
| "Password protection needed?" | Yes / No | Must be implemented at the web server level (basic auth or cookie-based) |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "WebDAV path?" | URL path | e.g. `/wiki/` — where the HTML file lives |

## Software-Layer Concerns

- **Single HTML file = entire app**: The wiki data is embedded inside the HTML file itself. Saving overwrites the file with updated content (PUT request to WebDAV, or download locally).
- **WebDAV detection**: Feather Wiki sends `OPTIONS` to the server. If the response includes a `dav` header, it shows "Save to Server" button. Without it, only "Save Locally" (download) is available.
- **No database**: All wiki pages, settings, and attachments are encoded inside the HTML file. Easy to version-control, email, or copy.
- **Password protection**: Feather Wiki has no built-in auth — use HTTP basic auth at the web server layer if the wiki contains private data.
- **Extensions**: Community extensions add features (syntax highlighting, graph views, etc.) — loaded by pasting JS into wiki settings. See https://feather.wiki/?page=gallery#extensions.
- **Size limit**: The HTML file grows as you add content. Very large wikis (hundreds of pages) may become slow to save.
- **Codeberg-hosted source**: Not on GitHub — at codeberg.org/Alamantus/FeatherWiki.

## Deployment

### Static NGINX (local-save only)

```bash
# Download the latest Feather Wiki HTML
wget https://feather.wiki/builds/FeatherWiki.html -O /var/www/wiki/index.html

# NGINX — serve as static file
```

```nginx
server {
    listen 443 ssl;
    server_name wiki.example.com;
    root /var/www/wiki;

    # Optional: basic auth for private wiki
    auth_basic "Private Wiki";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

Users save locally (download updated HTML) and re-upload manually.

### NGINX with WebDAV (server-save enabled)

```nginx
server {
    listen 443 ssl;
    server_name wiki.example.com;
    root /var/www/wiki;

    # Required for WebDAV detection
    dav_methods PUT DELETE MKCOL COPY MOVE;
    dav_ext_methods OPTIONS PROPFIND;
    dav_access user:rw group:rw all:r;
    create_full_put_path on;

    # Auth required before writing
    auth_basic "Wiki";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

```bash
# Install nginx-extras (includes WebDAV module)
apt install nginx-extras libnginx-mod-http-dav-ext

# Set permissions
chown -R www-data:www-data /var/www/wiki/
```

### Using a "Nest" (self-hosted save server)

Feather Wiki provides "nests" — minimal server scripts for save-back support. See https://codeberg.org/Alamantus/FeatherWiki/src/branch/main/nests for PHP, Node, and Python nest implementations.

## Upgrade Procedure

1. Download new Feather Wiki HTML from https://feather.wiki.
2. Your wiki data is in the _existing_ HTML file — copy your data into the new version using the Import function in Settings, or use the migration tool if provided.
3. There is no server-side component to upgrade.

## Gotchas

- **Data is in the HTML file**: If you delete the HTML file, you lose your wiki. Back up regularly — `cp index.html index.html.bak`.
- **WebDAV requires the `dav` header on OPTIONS**: Standard NGINX doesn't include this without `nginx-extras` + WebDAV module. Without it, only "Save Locally" works.
- **Auth must be server-side**: No built-in user accounts — protect private wikis with HTTP basic auth or a reverse proxy with auth middleware.
- **Large wikis get slow**: Everything is in one file — thousands of pages + attachments will make the HTML file large and browser operations slower.
- **Not a multi-user wiki**: Designed for personal use. Concurrent edits from multiple users will cause save conflicts.

## Links

- Source: https://codeberg.org/Alamantus/FeatherWiki
- Website / documentation: https://feather.wiki
- Extensions gallery: https://feather.wiki/?page=gallery#extensions
- Nests (save servers): https://codeberg.org/Alamantus/FeatherWiki/src/branch/main/nests
- Releases: https://codeberg.org/Alamantus/FeatherWiki/releases
