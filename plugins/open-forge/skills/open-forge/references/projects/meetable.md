# Meetable

> Minimal events aggregator website — list upcoming and past events, publish iCal feeds, accept RSVPs, and collect photos/notes via webmentions. Built with Laravel/PHP. Live at events.indieweb.org.

**Official URL:** https://github.com/aaronpk/Meetable

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS/VM | PHP 8.2+ + Nginx/Apache + MySQL | Primary documented method |
| Any Linux VPS/VM | Docker (community) | No official image; wrap in php-fpm container |
| Heroku | Heroku (deploy button) | One-click deploy with ClearDB + CloudCube |

---

## Inputs to Collect

### Phase: Pre-Deploy
| Input | Description | Example |
|-------|-------------|---------|
| `APP_URL` | Public URL of your site | `https://events.example.org` |
| `APP_KEY` | Laravel app key (generated) | `base64:...` (run `php artisan key:generate`) |
| `DB_HOST` | MySQL/MariaDB host | `127.0.0.1` |
| `DB_DATABASE` | Database name | `meetable` |
| `DB_USERNAME` | DB user | `meetable` |
| `DB_PASSWORD` | DB password | strong password |
| `AUTH_METHOD` | Auth backend | `session` / `github` / `oidc` / `vouch` / `heroku` |

### Phase: Auth (choose one)
| Input | Description | When needed |
|-------|-------------|-------------|
| `GITHUB_CLIENT_ID` | GitHub OAuth app client ID | `AUTH_METHOD=github` |
| `GITHUB_CLIENT_SECRET` | GitHub OAuth app secret | `AUTH_METHOD=github` |
| `OIDC_AUTHORIZATION_ENDPOINT` | OIDC authorize URL | `AUTH_METHOD=oidc` |
| `OIDC_TOKEN_ENDPOINT` | OIDC token URL | `AUTH_METHOD=oidc` |
| `OIDC_CLIENT_ID` | OIDC client ID | `AUTH_METHOD=oidc` |
| `OIDC_CLIENT_SECRET` | OIDC client secret | `AUTH_METHOD=oidc` |
| `VOUCH_HOSTNAME` | Vouch proxy hostname | `AUTH_METHOD=vouch` |

### Phase: Storage (optional)
| Input | Description | Default |
|-------|-------------|---------|
| `FILESYSTEM_DRIVER` | Storage backend | `local` |
| `AWS_ACCESS_KEY_ID` | S3 key (for cloud storage) | — |
| `AWS_SECRET_ACCESS_KEY` | S3 secret | — |
| `AWS_DEFAULT_REGION` | S3 region | — |
| `AWS_BUCKET` | S3 bucket | — |

---

## Software-Layer Concerns

### Config & Environment
- Copy `.env.example` to `.env`; fill in DB credentials and `APP_URL` before running migrations
- Generate the app key: `php artisan key:generate`
- Run migrations: `php artisan migrate`
- Queue worker needed for background jobs: `php artisan queue:listen` (or cron with `queue:work --stop-when-empty`)

### Data Directories
| Path | Purpose |
|------|---------|
| `storage/` | Uploaded images, cache, logs — must be writable by web server (`chown -R www-data: storage`) |
| `public/storage` | Symlinked from `storage/app/public` via `php artisan storage:link` |

### Key Environment Variables
```
APP_URL=https://events.example.org
APP_KEY=                           # php artisan key:generate
DB_HOST=127.0.0.1
DB_DATABASE=meetable
DB_USERNAME=meetable
DB_PASSWORD=secret
AUTH_METHOD=session                # or github, oidc, vouch, heroku
ALLOW_MANAGE_EVENTS=admins         # or 'users' for open submissions
ALLOW_MANAGE_SITE=admins
```

### Nginx Config
```nginx
server {
  listen 443 ssl http2;
  server_name events.example.org;
  root /path/to/meetable/public;
  index index.php;
  try_files $uri /index.php?$args;
  location ~* \.php$ {
    fastcgi_pass php-pool;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
  }
}
```

### Ports
- No built-in port; served by Nginx/Apache on 80/443

---

## Upgrade Procedure

1. `git pull`
2. `composer install --no-dev`
3. `php artisan migrate`
4. `php artisan config:cache && php artisan route:cache`
5. Restart queue worker: `php artisan queue:restart`

---

## Gotchas

- **`storage/` writable** — if Nginx/PHP-FPM can't write here, the app silently fails on uploads and caching
- **`php artisan storage:link`** — required when using local file storage; must be re-run after deploys that replace the `public/` directory
- **Passkey (session) auth** — first login creates the admin account; there's no web UI to add more users afterward — must do it at DB level
- **Queue worker** — without a running `queue:listen` or cron, background jobs (webmention processing, notifications) don't run
- **Redis optional but recommended** — default queue uses the database driver which is slower under load; set `QUEUE_CONNECTION=redis` and `CACHE_DRIVER=redis` for production
- **iCal feeds** — home page, tag pages, and individual event pages all expose iCal URLs; no extra config required

---

## Links
- GitHub: https://github.com/aaronpk/Meetable
- README / setup docs: https://github.com/aaronpk/Meetable#readme
- Live example: https://events.indieweb.org
