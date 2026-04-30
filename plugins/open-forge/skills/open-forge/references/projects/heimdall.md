---
name: Heimdall
description: Elegant application dashboard for organizing your self-hosted web apps + bookmarks. "Enhanced apps" fetch live stats (queue size, download speed) from known apps' APIs. Good browser start-page option with built-in search bar. Laravel + SQLite. MIT.
---

# Heimdall

Heimdall is a sleek "application dashboard" — a single web page that lists all your self-hosted apps as beautiful tiles. Instead of 20 browser bookmarks to `192.168.1.50:8080/sonarr`, `:8081/radarr`, `:8989/tautulli`, etc., you get a single `start.example.com` page with nicely-colored icons per app.

The **Enhanced Apps** feature is the killer trick: for dozens of popular apps (Sonarr, Radarr, Plex, Nextcloud, NZBGet, Sabnzbd, Tautulli, Portainer, pfSense, Home Assistant, etc.), Heimdall can query their APIs and show live stats on the tile — download speeds, queue counts, CPU usage. Turns a bookmark page into a mini-dashboard.

Also works as a browser start page with optional search bar (Google, Bing, DuckDuckGo).

Features:

- **Beautiful tiles** — colored by app; auto-pulled icons for 400+ "Foundation Apps"
- **Enhanced Apps** — live stats for 100+ popular self-hosted services
- **Search bar** — multi-provider; keyboard-first
- **Custom background** images
- **Tags** to group apps
- **Item ordering + pinning**
- **Multi-user** (admin/guest)
- **Dark mode**
- **8+ UI languages**

- Upstream repo: <https://github.com/linuxserver/Heimdall>
- Website: <https://heimdall.site>
- Apps directory: <https://apps.heimdall.site>
- Docker Hub (LSIO): <https://hub.docker.com/r/linuxserver/heimdall>
- Discord: <https://discord.gg/CCjHKn4>

## Architecture in one minute

- **Laravel** (PHP 7.2.5+ / 8.x) + Blade templates
- **SQLite** (default) — small + light; MySQL not needed
- **PHP extensions**: BCMath, Ctype, Fileinfo, JSON, Mbstring, OpenSSL, PDO, Tokenizer, XML, sqlite, zip
- Standard LAMP deploy OR LinuxServer.io Docker image
- Small footprint — runs happily on 256 MB RAM

## Compatible install methods

| Infra       | Runtime                                           | Notes                                                           |
| ----------- | ------------------------------------------------- | --------------------------------------------------------------- |
| Single VM   | **LinuxServer.io Docker** (`linuxserver/heimdall`)  | **Most common** — multi-arch                                      |
| Single VM   | Native LAMP (Apache + PHP)                            | Works; Apache `.htaccess` needs `AllowOverride`                     |
| Single VM   | Native LEMP (nginx + PHP-FPM)                          | Works; translate `.htaccess` to nginx rewrites                          |
| Shared host | cPanel / shared PHP — just upload                      | Very small footprint                                                      |
| Raspberry Pi | LSIO image supports armhf + arm64                        | Runs well on any Pi                                                          |

## Inputs to collect

| Input         | Example                      | Phase     | Notes                                                            |
| ------------- | ---------------------------- | --------- | ---------------------------------------------------------------- |
| Port          | `80`, `443`                   | Network   | Bind container ports; exposed via reverse proxy                       |
| Config dir    | `/config`                      | Storage   | Persistence: SQLite DB + uploaded backgrounds + search providers YAML    |
| PUID / PGID   | `1000` / `1000`                 | Perms     | LSIO convention                                                              |
| Admin user    | created via first UI run         | Bootstrap | Race-safe — first visit prompts for admin                                        |
| TLS (opt)     | Let's Encrypt via reverse proxy   | Security  | Mostly a private-use tool; TLS is nice-to-have if internet-exposed                 |

## Install via Docker (LinuxServer.io)

```sh
docker run -d --name heimdall \
  --restart unless-stopped \
  -p 8080:80 \
  -p 8443:443 \
  -v /opt/heimdall/config:/config \
  -e PUID=1000 -e PGID=1000 -e TZ=UTC \
  lscr.io/linuxserver/heimdall:2.x   # pin; check Docker Hub
```

Browse `http://<host>:8080` → first-run wizard creates admin account.

## Install via Docker Compose

```yaml
services:
  heimdall:
    image: lscr.io/linuxserver/heimdall:2.x
    container_name: heimdall
    restart: unless-stopped
    ports:
      - "8080:80"
      - "8443:443"
    environment:
      PUID: 1000
      PGID: 1000
      TZ: UTC
    volumes:
      - ./config:/config
```

Front with Caddy for TLS:

```
start.example.com {
    reverse_proxy 127.0.0.1:8080
}
```

## Install natively (LAMP quick)

```sh
# Prereqs: PHP 7.2.5+ with extensions (bcmath, ctype, fileinfo, json, mbstring, openssl, pdo-sqlite, tokenizer, xml, zip)
cd /var/www
wget https://github.com/linuxserver/Heimdall/archive/refs/tags/vX.Y.Z.tar.gz
tar -xzf vX.Y.Z.tar.gz
mv Heimdall-X.Y.Z heimdall
cd heimdall
cp .env.example .env
php artisan key:generate
chown -R www-data:www-data storage bootstrap/cache database/app.sqlite

# Apache docroot → /var/www/heimdall/public
# .htaccess is provided; ensure AllowOverride All in Apache config
# nginx: translate .htaccess to rewrite rules (see Laravel docs)

# Quick-and-dirty (dev only):
php artisan serve --host=0.0.0.0 --port=8080
```

## First boot

1. Browse Heimdall
2. First visit → wizard prompts for admin account
3. **Add your first app**: click "+" → type app name (e.g., "Sonarr") → matched "Foundation App" auto-fills icon + color
4. For **Enhanced Apps**: select Sonarr, fill in URL + API key; Heimdall starts pulling live stats
5. Upload a background image (Settings → Background)
6. (Optional) Set this as your browser home page

## Add Enhanced App example (Sonarr)

1. Click "+" → type "Sonarr" → select
2. Tile settings: URL `http://sonarr:8989`, API Key from Sonarr's Settings → General
3. "Override settings in config" → set URL Visible to clients if different from server
4. Save → tile now shows queue count + download speed

For Docker-to-Docker stats, use Docker network names (e.g., `http://sonarr:8989`) in the "config" URL and your public URL (`https://sonarr.example.com`) as the "click-to-open" URL.

## Data & config layout

Inside `/config` (LSIO Docker) or `database/` + `storage/` + `.env` (native):

- `database/app.sqlite` — SQLite DB (users + app list + settings)
- `storage/app/public/` — uploaded background images + icons
- `storage/app/searchproviders.yaml` — search providers
- `.env` — app config

LSIO image helpfully places uploads under `/config/www/backgrounds/` and search providers at `/config/www/searchproviders.yaml`.

## Backup

```sh
# Full config volume
docker run --rm -v "$(pwd)/config:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/heimdall-$(date +%F).tgz -C /src .

# Or just the DB
cp config/www/database.sqlite heimdall-db-$(date +%F).sqlite
```

## Upgrade

1. Releases: <https://github.com/linuxserver/Heimdall/releases>. Moderate cadence.
2. Docker: `docker compose pull && docker compose up -d`. Laravel migrations run on startup.
3. Native: download new release tarball; preserve `.env` + `database/app.sqlite` + `storage/app/`; run `php artisan migrate --force` + `php artisan cache:clear`.
4. Upgrade frequency is low — Heimdall is a mature dashboard; not many new features.

## Gotchas

- **Not actively changing direction** — Heimdall is a mature project; development cadence is modest. It does one thing (application dashboard) well and isn't chasing a flashy modern rewrite. Similar competitors (Homepage, Homer, Dashy) are more actively iterating.
- **Custom backgrounds not saving** — if an uploaded image doesn't appear, check PHP `upload_max_filesize` + `post_max_size`. LSIO Docker: edit `/config/php/php-local.ini` and add `upload_max_filesize = 30M`.
- **Docker networking for Enhanced Apps**: if Heimdall and target apps are both in Docker, use internal Docker service names (`http://sonarr:8989`) for the Enhanced App config. The "click-to-open" URL can still be your public URL. Otherwise Heimdall can't reach the API.
- **API keys stored in SQLite** in the config volume. Not encrypted. Protect the volume.
- **Search providers** are a YAML file — edit `searchproviders.yaml` to add/remove/reorder. Pull requests at <https://github.com/linuxserver/Heimdall/discussions/categories/search-providers> to contribute community entries.
- **Multi-user** (admin + guest) is limited — mostly admin-only. For "each family member has their own dashboard," consider Homepage or Dashy.
- **No built-in SSO** — use reverse proxy auth (Authelia, Authentik, oauth2-proxy) if you want SSO.
- **Tile icons**: the Foundation Apps catalog has 400+ known apps. If an icon is missing, upload your own.
- **Enhanced Apps accuracy**: live stats are polled from target app APIs — polling frequency matters (Heimdall's default is reasonable but adjustable). Heavy polling = load on your apps.
- **Languages**: 8 shipped (English, German, Finnish, French, Swedish, Spanish, Turkish, Russian). More via contributions.
- **LinuxServer.io image** adds their PUID/PGID wrapper + Docker mods system. Works well but if you prefer bare Laravel, build from source.
- **Laravel 8+ compatibility** — Heimdall has been Laravel 5/6/7 historically. Recent versions use current Laravel LTS; keep PHP 8.x available.
- **Security**: Heimdall is typically LAN-only. If exposed to the internet, use reverse proxy with auth + fail2ban.
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **Homepage (`gethomepage.dev`)** — actively developed; YAML-driven; huge integration list; Docker-native; modern UX (separate recipe)
  - **Homer** — static YAML-config dashboard; lightweight; no backend (separate recipe)
  - **Dashy** — Vue.js; feature-rich; YAML config; dark/light themes
  - **Organizr** — PHP; Unraid-popular; tab-based UI
  - **Flame** — simple dashboard; less active
  - **Dashmachine** — simpler alternative
  - **SUI** — minimal
  - **Starbase 80** — newer, lightweight
  - **Choose Heimdall if:** you want live stats per-app (Enhanced Apps) + a polished colorful dashboard with database-backed config (no YAML editing).
  - **Choose Homepage if:** you want the most actively-developed option with deep integrations + YAML-as-code.
  - **Choose Homer if:** you want a minimal no-backend YAML-configured dashboard.

## Links

- Repo: <https://github.com/linuxserver/Heimdall>
- Website: <https://heimdall.site>
- Apps catalog: <https://apps.heimdall.site>
- Foundation apps list: <https://apps.heimdall.site/applications/foundation>
- Enhanced apps list: <https://apps.heimdall.site/applications/enhanced>
- Docker Hub (LSIO): <https://hub.docker.com/r/linuxserver/heimdall>
- Search provider contributions: <https://github.com/linuxserver/Heimdall/discussions/categories/search-providers>
- Releases: <https://github.com/linuxserver/Heimdall/releases>
- Overview video: <https://youtu.be/GXnnMAxPzMc>
- Discord: <https://discord.gg/CCjHKn4>
