---
name: digiscreen
description: Digiscreen recipe for open-forge. Interactive classroom whiteboard/wallpaper for in-person or remote teaching. PHP 8.4+ + Composer. Optional Google/Pixabay API keys. From Ladigitale (documentation in French). AGPL-3.0. Source: https://codeberg.org/ladigitale/digiscreen
---

# Digiscreen

An interactive whiteboard/wallpaper application designed for classroom use, usable both in-person and remotely. Features timers, polls, media display, pictograms (ARASAAC), emoji reactions (OpenMoji), and sound effects. Part of the Ladigitale educational suite. PHP 8.4+ API; optional Digidrive integration uses S3/Composer. Documentation in French. AGPL-3.0 licensed. Source: <https://codeberg.org/ladigitale/digiscreen>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | PHP 8.4+ + NGINX/Apache2 | Production (standard) |
| Any Linux + Digidrive | PHP 8.4+ + Composer + S3 | Only if using Digidrive file integration |
| Docker | Custom | No official Docker image |

> Node.js is a **build-time** dependency only. Composer is only needed for Digidrive integration.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain?" | FQDN | e.g. digiscreen.example.com |
| "Authorized domains?" | Comma-separated or `*` | AUTHORIZED_DOMAINS |
| "Google YouTube API key?" | String or blank | VITE_GOOGLE_API_KEY — enables YouTube embeds |
| "Pixabay API key?" | String or blank | VITE_PIXABAY_API_KEY — enables image search |
| "Use Digidrive integration?" | Yes / No | If yes, S3 + Composer required |

### Phase 2 — Deploy (Digidrive / S3 only)

| Prompt | Format | Notes |
|---|---|---|
| "S3 endpoint?" | URL | S3_ENDPOINT |
| "S3 access key?" | String | S3_ACCESS_KEY |
| "S3 secret key?" | Secret | S3_SECRET_KEY |
| "S3 region?" | String | S3_REGION |
| "S3 bucket?" | String | S3_BUCKET |

## Software-Layer Concerns

- **PHP 8.4+ required**: Even without Digidrive, PHP 8.4 is the minimum.
- **Composer optional**: Only needed for Digidrive integration — `composer install` only if using S3/Digidrive.
- **Google YouTube API key**: Optional — enables embedding YouTube videos in classroom display.
- **Pixabay API key**: Optional — enables image search.
- **S3/Digidrive**: Optional integration for storing classroom media in S3-compatible storage.
- **ARASAAC pictograms**: Included symbols are licensed CC BY-NC-SA 4.0 from the Government of Aragon.
- **VITE_`-prefixed vars are build-time**: Embedded in JS bundle.

## Deployment

### 1. Install dependencies

```bash
apt install php8.4 php8.4-fpm nodejs npm
# Only if using Digidrive:
# curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
```

### 2. Clone, configure, and build

```bash
git clone https://codeberg.org/ladigitale/digiscreen.git /opt/digiscreen
cd /opt/digiscreen

# Only if using Digidrive:
# composer install --no-dev

cat > .env.production << 'EOF'
AUTHORIZED_DOMAINS=digiscreen.example.com
VITE_GOOGLE_API_KEY=
VITE_PIXABAY_API_KEY=
EOF

npm install
npm run build
```

### 3. Deploy

```bash
cp -r dist/ /var/www/digiscreen/
chown -R www-data:www-data /var/www/digiscreen/
```

### 4. NGINX configuration

```nginx
server {
    listen 443 ssl;
    server_name digiscreen.example.com;

    root /var/www/digiscreen;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

## Upgrade Procedure

1. `cd /opt/digiscreen && git pull`
2. `npm install && npm run build`
3. `cp -r dist/ /var/www/digiscreen/`

## Gotchas

- **ARASAAC pictograms license**: The included pictogram symbols are CC BY-NC-SA 4.0 — not for commercial use.
- **YouTube requires Google API key**: Without `VITE_GOOGLE_API_KEY`, YouTube embedding is disabled.
- **Composer only for Digidrive**: Don't run `composer install` if you're not using Digidrive — it's unnecessary.
- **Build-time vars**: VITE_GOOGLE_API_KEY, VITE_PIXABAY_API_KEY, AUTHORIZED_DOMAINS are baked in at build.
- **S3 credentials runtime**: S3_* vars are PHP runtime only.
- **French-language project**: UI and docs are in French.

## Links

- Source: https://codeberg.org/ladigitale/digiscreen
- Website: https://ladigitale.dev/digiscreen/
- Demo: https://ladigitale.dev/digiscreen/
- ARASAAC: https://arasaac.org
- Ladigitale suite: https://ladigitale.dev/
