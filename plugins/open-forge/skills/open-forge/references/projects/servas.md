---
name: servas
description: Servas recipe for open-forge. Covers Docker Compose (SQLite, recommended) and MariaDB variants. Servas is a self-hosted bookmark management tool with tags, nested groups, smart groups, multi-user support, 2FA, and browser extensions for Firefox and Chrome.
---

# Servas

Self-hosted bookmark management tool built on Laravel, Inertia.js, Svelte, and Tailwind CSS. Organizes bookmarks with tags, groups (nested), and smart groups (tag-based auto-grouping). Supports multiple users with 2FA, import/export (JSON and HTML), dark/light theme, and browser extensions for Firefox and Chrome. Upstream: <https://github.com/beromir/Servas>. Docker Hub: <https://hub.docker.com/r/beromir/servas>.

**License:** GPL-3.0 · **Language:** PHP (Laravel) + Node.js (Svelte/Inertia) · **Default port:** 8080 · **Stars:** ~800

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose — SQLite | <https://github.com/beromir/Servas#docker> | ✅ | **Recommended.** Simplest setup — no separate database container needed. |
| Docker Compose — MariaDB | <https://github.com/beromir/Servas/tree/main/docker/mariadb-example> | ✅ | Higher concurrency or existing MariaDB/MySQL infrastructure. |
| Manual (PHP/Node.js) | <https://github.com/beromir/Servas#manual> | ✅ | Development or bare-metal without Docker. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Database: SQLite (simpler) or MariaDB/MySQL (existing DB infra)?" | AskUserQuestion | Determines compose variant. |
| domain | "What URL will Servas be served at?" | Free-text | All methods. |
| port | "Host port to expose Servas on? (default: 8080)" | Free-text | Docker methods. |
| db_password | "MariaDB password? (only needed for MariaDB variant)" | Free-text (sensitive) | MariaDB variant only. |
| registration | "Allow public self-registration? (SERVAS_ENABLE_REGISTRATION)" | AskUserQuestion: Yes / No | All methods — set false after creating accounts. |

## Install — Docker Compose (SQLite, recommended)

Reference: <https://github.com/beromir/Servas/blob/main/docker/compose.prod.yaml>

```bash
mkdir servas && cd servas

# Download compose and env files
curl -O https://raw.githubusercontent.com/beromir/Servas/main/docker/compose.prod.yaml
mv compose.prod.yaml docker-compose.yml
curl -O https://raw.githubusercontent.com/beromir/Servas/main/docker/.env.prod.example
mv .env.prod.example .env
```

Edit `.env`:

```bash
APP_NAME=Servas
APP_ENV=production
APP_KEY=                              # generated in step below
APP_DEBUG=false
APP_URL=https://bookmarks.example.com

SERVAS_ENABLE_REGISTRATION=true       # set false after account creation
SERVAS_SHOW_APP_VERSION=true

DB_CONNECTION=sqlite
DB_DATABASE=/app/database/sqlite/database.sqlite
DB_FOREIGN_KEYS=true
```

Start containers:

```bash
docker compose -f docker-compose.yml up -d

# Generate application key (required before first use)
docker exec -it servas php artisan key:generate --force

# Restart to apply the key
docker compose restart
```

Open `http://<host>:8080/register` to create your account. After account creation, set `SERVAS_ENABLE_REGISTRATION=false` in `.env` and restart.

### docker-compose.yml (SQLite)

```yaml
services:
  servas:
    image: beromir/servas
    container_name: servas
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./.env:/app/.env
      - servas-db-sqlite:/app/database/sqlite

volumes:
  servas-db-sqlite:
```

## Install — Docker Compose (MariaDB)

Reference: <https://github.com/beromir/Servas/tree/main/docker/mariadb-example>

```bash
# Fetch MariaDB example files
curl -O https://raw.githubusercontent.com/beromir/Servas/main/docker/mariadb-example/compose.prod.yaml
mv compose.prod.yaml docker-compose.yml
curl -O https://raw.githubusercontent.com/beromir/Servas/main/docker/mariadb-example/.env.prod.example
mv .env.prod.example .env
```

Key `.env` differences for MariaDB variant:

```bash
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=servas
DB_USERNAME=servas
DB_PASSWORD=strongpassword
```

Follow the same `key:generate` and registration steps as the SQLite variant.

## Install — Manual (PHP + Node.js)

Requirements: PHP 8.4, Composer, Node.js, npm, Git, MariaDB/MySQL or SQLite.

```bash
git clone https://github.com/beromir/Servas.git
cd Servas

composer install --optimize-autoloader --no-dev
npm install
npm run build

cp .env.example .env
# Edit .env: APP_URL, DB_*, etc.

php artisan migrate
php artisan key:generate

# Serve with nginx/Apache + PHP-FPM pointing to public/ as document root
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| APP_KEY | Must be generated after deploy (`php artisan key:generate`). Never regenerate on an existing install — invalidates all sessions and encrypted data. |
| APP_URL | Must match the actual URL exactly (including scheme). Wrong value breaks asset loading and redirects. |
| SERVAS_ENABLE_REGISTRATION | Default `true`. Set to `false` after creating accounts to prevent unauthorized signups. |
| Volumes (SQLite) | SQLite database lives in a named Docker volume `servas-db-sqlite`. Back up the volume or the file at `/app/database/sqlite/database.sqlite`. |
| PHP version | PHP 8.4 required (as per upstream README as of v1.1.x). Composer and npm required for manual install. |
| Browser extensions | Firefox: <https://addons.mozilla.org/en-US/firefox/addon/servas/> · Chrome: Chrome Web Store. Configure extension with your instance URL + credentials. |
| 2FA | Enabled per-user in Settings. Uses TOTP (compatible with any authenticator app). |
| Import/Export | Settings → Export/Import. Supports JSON and Netscape HTML bookmark format. |

## Upgrade procedure

```bash
cd servas
docker compose pull
docker compose up -d
```

After upgrade:

```bash
# Run any pending database migrations
docker exec -it servas php artisan migrate --force
```

Back up the SQLite volume before upgrading:

```bash
docker run --rm -v servas_servas-db-sqlite:/data -v $(pwd):/backup alpine \
  tar czf /backup/servas-sqlite-$(date +%Y%m%d).tar.gz -C /data .
```

## Gotchas

- **Generate APP_KEY before first use:** Without `php artisan key:generate`, the app will throw encryption errors. Run it once right after starting the container, then restart.
- **Disable registration after setup:** `SERVAS_ENABLE_REGISTRATION=true` is the default. Anyone who can reach your instance can register. Set it to `false` once your accounts exist.
- **SQLite volume backup:** The SQLite database is in a Docker named volume. Use `docker exec` or `docker cp` to extract it for backups — it's a single file at `/app/database/sqlite/database.sqlite`.
- **PHP 8.4 for manual install:** The upstream README specifies PHP 8.4 for manual installs (Docker image bundles the correct version).
- **nginx document root is `public/`:** For manual installs behind nginx, point the root to the `public/` subdirectory, not the project root.

## Upstream links

- GitHub: <https://github.com/beromir/Servas>
- Docker Hub: <https://hub.docker.com/r/beromir/servas>
- Firefox extension: <https://addons.mozilla.org/en-US/firefox/addon/servas/>
- Releases: <https://github.com/beromir/Servas/releases>
