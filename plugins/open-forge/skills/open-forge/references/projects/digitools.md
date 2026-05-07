---
name: digitools
description: Digitools recipe for open-forge. A set of simple PHP-based classroom tools (timers, randomisers, story generator with ARASAAC pictograms). PHP + SQLite only — no Node.js build step. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digitools
---

# Digitools

A set of simple tools to accompany in-person or remote course facilitation — includes timers, randomisers, a story generator with ARASAAC pictograms, and other classroom utilities. Part of the Ladigitale educational suite. Pure PHP with SQLite — uniquely, **no Node.js build step** required. Just deploy the PHP files. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digitools>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8+ + SQLite + NGINX/Apache2 | Production — no build step needed |
| Docker | PHP-FPM + NGINX | Serve PHP files directly |
| Shared hosting | PHP 8+ + SQLite | Works on most shared hosts |

> **No Node.js or build step required** — this is the simplest digi* app to deploy. Just clone and serve.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digitools.example.com |
| "PHP version?" | 8.x | PHP 8.0+ required |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Web server?" | NGINX / Apache2 | Serves PHP files directly |
| "TLS?" | Yes / No | Handled by web server |

## Software-Layer Concerns

- **PHP + SQLite only**: No npm, no Composer, no Redis — just PHP with the SQLite extension.
- **SQLite extension required**: `php8.x-sqlite3` — data stored in SQLite.
- **No build step**: Deploy the cloned source directly (or a release tarball) — no `npm run build`.
- **ARASAAC pictograms**: Included story generator symbols are CC BY-NC-SA from the Government of Aragon — not for commercial use.
- **Write permissions**: PHP process needs write access to the SQLite database file directory.

## Deployment

### 1. Install dependencies

```bash
apt install php8.1 php8.1-fpm php8.1-sqlite3
```

### 2. Clone and deploy

```bash
git clone https://codeberg.org/ladigitale/digitools.git /var/www/digitools
chown -R www-data:www-data /var/www/digitools/
```

### 3. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digitools.example.com;

    root /var/www/digitools;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

```bash
nginx -t && systemctl reload nginx
```

## Upgrade Procedure

```bash
cd /var/www/digitools && git pull
# No build step needed — changes are live immediately
```

## Gotchas

- **No build step**: Unlike most digi* apps, there is no npm/Vite build — deploy source directly.
- **SQLite write permissions**: Ensure the web server user (`www-data`) can write to the directory containing the SQLite database file.
- **ARASAAC license restriction**: Pictogram symbols are CC BY-NC-SA — not suitable for commercial deployments.
- **Simplest digi* app**: If you're evaluating the suite, start here — zero build tooling required.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digitools
- Website: https://ladigitale.dev/digitools
- Demo: https://ladigitale.dev/digitools/
- ARASAAC: https://arasaac.org
- Ladigitale suite: https://ladigitale.dev/
