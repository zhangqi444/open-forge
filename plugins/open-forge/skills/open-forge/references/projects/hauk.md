---
name: Hauk
description: "Self-hosted real-time location sharing service. PHP + Memcached/Redis + Android app. bilde2910/Hauk. Share your location via a temporary link, live GPS tracking, F-Droid + Play Store companion app. GPL-3.0."
---

# Hauk

**Self-hosted real-time location sharing.** Start a session from the Android companion app, share a link — watchers follow your live GPS position on a map until the session expires. No third-party location services. Companion app on F-Droid and Google Play.

Built + maintained by **Marius Lindvall (bilde2910)**. GPL-3.0.

- Upstream repo: <https://github.com/bilde2910/Hauk>
- Docker Hub: `bilde2910/hauk`
- Android app (F-Droid): <https://f-droid.org/packages/info.varden.hauk>
- Docs/FAQ: <https://github.com/bilde2910/Hauk/wiki/FAQ>

## Architecture in one minute

- **PHP** backend (with `memcached`/`memcache` or `redis` extension)
- **Memcached** (default) or **Redis** — in-memory store for live session data; Docker image bundles Memcached
- Port **80** internal; strongly recommended to use HTTPS via reverse proxy (location data is sensitive)
- Config: single `config.php` file mounted at `/etc/hauk/config.php`
- Android companion app sends GPS; browser receives live map view
- Resource: **very low** — PHP + lightweight in-memory cache

## Compatible install methods

| Infra | Runtime | Notes |
|-------|---------|-------|
| **Docker** | `bilde2910/hauk` (Memcached bundled) | **Simplest** — single container |
| Docker | `bilde2910/hauk` + external Redis | For shared Redis setups |
| VPS / bare | PHP + web server + Memcached/Redis | Manual install via `install.sh` |

## Install via Docker Compose

```yaml
services:
  hauk:
    image: bilde2910/hauk
    container_name: hauk
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./config/hauk:/etc/hauk
```

**Config setup:**

```bash
mkdir -p ./config/hauk
curl -o ./config/hauk/config.php \
  https://raw.githubusercontent.com/bilde2910/Hauk/master/backend-php/include/config-sample.php
# Edit config.php — at minimum set a secure password_hash
```

Generate a bcrypt password hash:
```bash
htpasswd -nBC 10 "" | tail -c +2
```

```bash
docker compose up -d
```

## Key config.php settings

| Setting | Default | Notes |
|---------|---------|-------|
| `storage_backend` | `MEMCACHED` | `MEMCACHED` or `REDIS` |
| `memcached_host` | `localhost` | Docker image includes Memcached internally |
| `memcached_port` | `11211` | |
| `redis_host` | `localhost` | If using external Redis |
| `redis_use_auth` | `false` | Set `true` + `redis_auth` if Redis has a password |
| `auth_method` | `PASSWORD` | `PASSWORD`, `HTPASSWD`, or `LDAP` |
| `password_hash` | (empty — insecure) | **Must be changed.** Generate with `htpasswd -nBC 10 ""` |
| `default_expire` | — | Default session expiry in seconds |
| `max_expire` | — | Maximum session expiry the app can request |
| `leaflet_tile_url` | — | Custom map tile server URL |

## Gotchas

- **Use HTTPS.** Location data in transit is sensitive. Always front with a TLS-terminating reverse proxy; never expose port 80 directly.
- **Default password is empty.** The sample config ships with a hash for an empty password — change `password_hash` before going live.
- **Memcached is bundled in the Docker image.** Leave `memcached_host` as `localhost` when using the official Docker image.
- **Location data is ephemeral.** Sessions expire automatically — there is no persistent location history.
- **Android app required for sharing.** The server provides the map viewer; the companion Android app handles GPS posting. No iOS app.
- **Multiple users.** Use `HTPASSWD` or `LDAP` auth for per-user credentials; `PASSWORD` is a single shared secret.

## Backup

No persistent data — Hauk stores only active sessions in memory. Back up `config.php`:

```sh
cp ./config/hauk/config.php ./config/hauk/config.php.bak
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Location-sharing-family comparison

- **Hauk** — PHP/Memcached, temporary share links, Android app; GPL-3.0
- **OwnTracks** — MQTT/HTTP, continuous tracking, iOS + Android; EPL-2.0
- **Traccar** — Java, GPS fleet tracking, many device protocols; Apache-2.0
- **ulogger** — PHP/MySQL, continuous GPS logging, web UI; GPL-3.0

**Choose Hauk if:** you want quick temporary real-time location sharing — "here's where I am right now" — via a simple link, without persistent tracking.

## Links

- Repo: <https://github.com/bilde2910/Hauk>
- FAQ: <https://github.com/bilde2910/Hauk/wiki/FAQ>
- Sample config: <https://github.com/bilde2910/Hauk/blob/master/backend-php/include/config-sample.php>
- F-Droid: <https://f-droid.org/packages/info.varden.hauk>
