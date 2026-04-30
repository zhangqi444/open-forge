---
name: Pixelfed
description: "Federated photo-sharing platform on the Fediverse — Instagram-like UI, ActivityPub protocol. Follow accounts on Mastodon/Pixelfed/other ActivityPub servers. PHP (Laravel) + Postgres + Redis + Horizon queue. AGPL-3.0."
---

# Pixelfed

Pixelfed is **federated photo sharing** — think "open-source, ActivityPub-federated Instagram." Post photos, add captions + tags + alt text, follow other accounts across the Fediverse (including Mastodon), see a chronological timeline (no algorithm, no ads). Millions of users across the federated network.

Features:

- **Photo posting** — single + carousel, with filters (Instagram-like)
- **Stories** — ephemeral posts (24h)
- **Collections** — organize posts into albums
- **Circles** — share with limited groups
- **Direct messages** — private chats
- **ActivityPub federation** — interop with Mastodon, Pleroma, Misskey, Friendica, other Pixelfed instances
- **Timeline** — home (follows) + local (instance) + global (fediverse)
- **Discover** — find posts by hashtag / trending
- **Hashtags** — searchable
- **Alt text + content warnings** (accessibility-first)
- **Chronological only** — no recommendation algorithm
- **EXIF stripping** — GPS + device data removed on upload (configurable)
- **Media proxy** — cache remote media locally for privacy
- **Third-party mobile apps** — Pixeldroid (Android), many for iOS
- **Admin dashboard** — moderation, reports, federation blocks
- **Autospam tools** — rate limiting, captcha, email domain blocks

- Upstream repo: <https://github.com/pixelfed/pixelfed>
- Website: <https://pixelfed.org>
- Docs: <https://docs.pixelfed.org>
- Fediverse stats: <https://fedidb.org/software/pixelfed>
- Discord: <https://discord.gg/msXs3MumsK>
- Mastodon (project): <https://mastodon.social/@pixelfed>

## Architecture in one minute

- **PHP 8.1+** (Laravel framework)
- **DB**: Postgres (recommended) or MySQL/MariaDB
- **Redis**: cache, sessions, rate limiting, **Laravel Horizon queue** (mandatory for federation)
- **Queue workers**: process federation deliveries, media, notifications — **must be running**
- **Scheduler**: cron (every minute) runs Laravel scheduler
- **Storage**: local filesystem or **S3-compatible** (S3/MinIO/Wasabi/Backblaze/etc.) for media
- **Image processing**: ImageMagick / FFmpeg (for videos)
- **Nginx + PHP-FPM** recommended

## Compatible install methods

| Infra        | Runtime                                                  | Notes                                                                 |
| ------------ | -------------------------------------------------------- | --------------------------------------------------------------------- |
| Single VM    | **Native PHP-FPM + Nginx + Postgres + Redis + Horizon**      | **Upstream-documented path**                                                  |
| Docker       | Community Docker Compose stacks (several maintained)                     | Common; pick an active one                                                             |
| YunoHost     | Official package                                                                  | One-click for YunoHost users                                                                    |
| Kubernetes   | Community manifests                                                                   | Possible                                                                                               |
| Managed      | Community instances (<https://pixelfed.org/join>)                                           | Free to join — no self-host needed                                                                             |

## Inputs to collect

| Input              | Example                             | Phase     | Notes                                                                 |
| ------------------ | ----------------------------------- | --------- | --------------------------------------------------------------------- |
| Domain             | `pixelfed.example.com`                 | URL/DNS   | **PERMANENT** — federation identity; changing = breaks all remote follows    |
| DB                 | Postgres creds                              | DB        | Postgres preferred                                                                   |
| Redis              | host + port                                       | Cache     | Shared with queue                                                                                  |
| Storage driver     | local / s3                                              | Storage   | S3 recommended for scale                                                                                      |
| Admin user         | created via `php artisan user:create`                         | Bootstrap | Multi-admin possible                                                                                                    |
| SMTP               | host/port/user/pass                                             | Email     | For registration + password resets                                                                                                          |
| Open registration  | `OPEN_REGISTRATION=true/false`                                           | Config    | True for public instance; false for solo/small                                                                                                              |
| Registration mode  | normal / email-whitelist / invite-only                                               | Config    | Control spam                                                                                                                                              |
| Media size limits  | `MAX_PHOTO_SIZE` (KB), `MAX_ALBUM_LENGTH`                                                 | Config    | Balance against storage cost                                                                                                                                              |
| Federation         | `ACTIVITY_PUB=true`                                                                             | Config    | Enables inbound/outbound federation                                                                                                                                                      |
| Horizon workers    | systemd service running Laravel Horizon                                                                  | Ops       | **MANDATORY**                                                                                                                                                                   |

## Install (native, recommended path)

Follow <https://docs.pixelfed.org/running-pixelfed/installation.html> — summary:

```sh
# Install PHP 8.1+, Nginx, Postgres, Redis, FFmpeg, ImageMagick
git clone -b dev https://github.com/pixelfed/pixelfed.git
cd pixelfed
composer install --no-dev
cp .env.example .env
# Edit .env: APP_URL, DB_*, REDIS_*, MAIL_*, filesystem driver, ActivityPub
php artisan key:generate
php artisan storage:link
php artisan migrate --force
php artisan import:cities       # optional (geocoding)
php artisan horizon:install
php artisan passport:install
# Create admin
php artisan user:create
php artisan instance:actor
# Nginx config, systemd services for horizon + scheduler cron
```

### Systemd for Horizon (mandatory)

```ini
# /etc/systemd/system/pixelfed-horizon.service
[Unit]
Description=Pixelfed Horizon Queue
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/pixelfed
ExecStart=/usr/bin/php artisan horizon
Restart=always

[Install]
WantedBy=multi-user.target
```

### Cron scheduler

```cron
* * * * * www-data cd /var/www/pixelfed && php artisan schedule:run >> /dev/null 2>&1
```

## Install via Docker (community stacks)

Several community-maintained Docker Compose repos exist; pick one actively maintained. Typical stack: `pixelfed-app` + `pixelfed-worker` (horizon) + `pixelfed-scheduler` + `pixelfed-db` (postgres) + `pixelfed-redis`. Refer to <https://docs.pixelfed.org/running-pixelfed/docker.html>.

## First boot

1. Browse `https://pixelfed.example.com/` → sign up (or log in as created admin)
2. Settings → profile: avatar, bio, privacy
3. Upload first photo — verify it displays
4. Follow someone on another Pixelfed instance (type `@user@otherinstance.com` in search) → verify follow works (= federation works)
5. Check Admin dashboard (`/i/admin`) — statistics, queue, reports
6. Ensure Horizon dashboard (`/horizon`) shows jobs processing (admin-only)

## Data & config layout

- `.env` — config (APP_KEY, DB, Redis, SMTP, instance actor keys)
- `storage/app/public/` — user-uploaded media (if local driver); symlinked to `public/storage/`
- S3 bucket — user media (if S3 driver)
- DB — all posts, users, follows, federation queue state, etc.
- Redis — cache + queue state

## Backup

```sh
# DB
pg_dump -U pixelfed pixelfed | gzip > pixelfed-db-$(date +%F).sql.gz
# Storage (if local)
tar czf pixelfed-storage-$(date +%F).tgz storage/app/public/
# .env (contains APP_KEY + instance actor private key)
cp .env pixelfed-env-$(date +%F).bak
```

**Critical**: the `APP_KEY` + instance actor private key in `.env` are your instance's federation identity. **Lose them and federation breaks permanently** (remote servers can't verify your signatures). Back up `.env` separately + securely.

## Upgrade

1. Releases: <https://github.com/pixelfed/pixelfed/releases>. Active.
2. **Back up DB + storage + .env.**
3. Put in maintenance: `php artisan down`.
4. `git pull` (or new image), `composer install --no-dev`, `php artisan migrate --force`, `php artisan horizon:terminate` (restarts workers with new code), `php artisan up`.
5. Clear caches: `php artisan config:cache && php artisan route:cache`.
6. Read release notes — breaking `.env` variable changes happen.

## Gotchas

- **Horizon queue workers are mandatory for federation.** If Horizon stops, posts don't federate out, incoming activities queue up but don't process, and your instance appears "dead" to the fediverse. Monitor Horizon dashboard + set systemd auto-restart.
- **Domain is permanent.** ActivityPub identity = domain. Rehoming = all remote follows break; all remote mentions of you become orphans. Choose domain carefully.
- **`.env` secrets** — `APP_KEY` encrypts DB data; instance actor private key signs federation messages. **Lose these = lost instance identity.** Back up + restore together.
- **Federation is a target for abuse.** Other instances send spam, CSAM, harassment. Budget for moderation time; use instance-level blocks; consider moderation tools. Have a clear Terms of Service + privacy policy.
- **Legal obligations** vary by jurisdiction — hosting a federated social network makes you a publisher. CSAM laws apply everywhere. **Enable media hash scanning** if handling public uploads; consider a trust-and-safety partner or clear incident response plan.
- **EXIF stripping** — on by default; verify settings. GPS coords in photos leak locations.
- **Scale**: Pixelfed on a 2 GB / 1 vCPU VPS is fine for solo or <50 users. For public registration, budget more (8+ GB RAM, multi-core, fast disk, S3 for media).
- **Storage growth** — photos + videos + remote media cache. 1 TB+ is realistic for public instances. S3 + lifecycle policies.
- **Media proxy** fetches remote media for display; fills disk unless capped. Tune `MEDIA_CACHE` env vars.
- **ImageMagick + ghostscript CVEs** — keep distro packages updated.
- **Mobile apps**: PixelDroid (Android, F-Droid), various community iOS apps. Mastodon apps with Pixelfed backend support growing.
- **Stories feature** — ephemeral, 24h; inspired by Instagram; some instances disable.
- **Autospam tools** — email domain blocklists, captcha on signup, rate limits. Public instances need these.
- **Character set** — Postgres with UTF8; Pixelfed posts support emoji + RTL scripts.
- **Federation tuning**: outbound delivery retries for dead remote servers can clog queue. Configure retry limits + DLQ.
- **AGPL-3.0** — modifying + running as a public service triggers source disclosure. Keep a link to your modified source prominent.
- **Commercial/private**: no formal Pixelfed Cloud; community hosts exist (see pixelfed.org/join).
- **Pixelfed 2.0 (major version)** — check current state; some features (groups, longer videos) may be gated by version.
- **Alternatives worth knowing:**
  - **Mastodon** — fediverse microblog; text-first but supports photos (separate recipe)
  - **Misskey / Sharkey** — feature-rich fediverse; more JS/art community
  - **Friendica** — federated social network
  - **WriteFreely** — long-form ActivityPub blogging
  - **Own Instagram replacement**: no perfect 1:1 OSS mapping; Pixelfed is closest
  - **Choose Pixelfed if:** photo-first federated sharing.
  - **Choose Mastodon if:** text + photos + longer reach in current fediverse.
  - **Choose a managed instance** (pixelfed.org/join) if self-host ops are too much.

## Links

- Repo: <https://github.com/pixelfed/pixelfed>
- Website: <https://pixelfed.org>
- Docs: <https://docs.pixelfed.org>
- Install docs: <https://docs.pixelfed.org/running-pixelfed/installation.html>
- Docker docs: <https://docs.pixelfed.org/running-pixelfed/docker.html>
- Instances list: <https://pixelfed.org/join>
- Releases: <https://github.com/pixelfed/pixelfed/releases>
- FediDB stats: <https://fedidb.org/software/pixelfed>
- Discord: <https://discord.gg/msXs3MumsK>
- Crowdin translations: <https://crowdin.com/project/pixelfed>
- ActivityPub spec: <https://www.w3.org/TR/activitypub/>
- Laravel Horizon docs: <https://laravel.com/docs/horizon>
- PixelDroid (Android app): <https://pixeldroid.org>
