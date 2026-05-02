# Flox

**What it is:** A self-hosted movie, series, and anime watch list built on Laravel and Vue.js. Uses The Movie Database (TMDb) API for metadata, posters, and discovery. Features a simple 3-point rating system (good/medium/bad), episode tracking, calendar view, watchlist, ActivityPub federation, and optional Plex sync. Lightweight and focused — no media server, just a list.

**Official URL:** https://github.com/Simounet/flox
**Docs:** https://simounet.github.io/flox/
**Demo:** https://flox-demo.pyxl.dev (login: `demo` / `demo`)
**License:** MIT
**Stack:** Laravel (PHP 8.4+) + Vue.js + MariaDB/MySQL

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | PHP 8.4+ + MariaDB | Standard Laravel deployment |
| Docker | Docker Compose | Community images available; check docs |

> **Note:** No official Docker image maintained in this repo — check the docs at https://simounet.github.io/flox/ for current Docker options.

---

## Inputs to Collect

### Pre-deployment
- TMDb API key — free at https://www.themoviedb.org/faq/api
- Database credentials — MariaDB or MySQL
- `APP_URL` — public URL of your Flox instance
- `CLIENT_URI` — path prefix for the frontend (e.g. `/` if root, `/flox/public` if subfolder)

---

## Software-Layer Concerns

**Manual installation:**
```bash
git clone https://github.com/Simounet/flox
cd flox/backend
composer install --no-dev -o --prefer-dist
php artisan flox:init    # prompts for DB credentials
# Add your TMDb API key to backend/.env
php artisan flox:db      # runs migrations; prompts for admin credentials
```

**File permissions** — give recursive write access to:
- `backend/storage/`
- `public/assets/`
- `public/exports/`

**`backend/.env` key settings:**
```dotenv
APP_URL=https://flox.example.com
CLIENT_URI=/                        # or /subfolder/flox/public
TMDB_API_KEY=your_tmdb_key
FEDERATION_ENABLED=true             # set false to disable ActivityPub
```

**ActivityPub federation:** When enabled, reviews are delivered to followers on compatible platforms. Disable with `FEDERATION_ENABLED=false` for private/solo use.

**Plex sync:** Configure via UI settings — syncs watched movies, shows, and episodes from Plex to Flox.

**Web server:** Point document root to `public/`. Apache `.htaccess` included; for Nginx use `try_files $uri $uri/ /index.php`.

**Cron (daily metadata updates):**
```bash
* * * * * php /path/to/flox/backend/artisan schedule:run >> /dev/null 2>&1
```
Daily lists (Popular, Upcoming, Current) are updated via the scheduler.

**Upgrade procedure:**
```bash
git pull
cd backend
composer install --no-dev -o --prefer-dist
php artisan migrate
```

---

## Gotchas

- **TMDb API key required** — free account; without it, no metadata, posters, or search results
- **MariaDB/MySQL only** — known issues with PostgreSQL; not officially supported
- **PHP 8.4+ required** — check your server's PHP version before deploying
- **`CLIENT_URI` must match your web server config** — mismatch causes 404s on the Vue.js frontend; set both `APP_URL` and `CLIENT_URI` correctly
- **Not a media server** — Flox only tracks what you've watched/want to watch; it doesn't serve or download media

---

## Links
- GitHub: https://github.com/Simounet/flox
- Docs: https://simounet.github.io/flox/
- Demo: https://flox-demo.pyxl.dev
- TMDb API: https://www.themoviedb.org/faq/api
