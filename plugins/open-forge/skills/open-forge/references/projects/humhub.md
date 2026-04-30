---
name: HumHub
description: "Modular open-source social network / intranet / knowledge base. Users, Spaces (groups), Content (posts, wiki, files, calendar, tasks, polls), 80+ modules (LDAP, OnlyOffice, JWT SSO, Gallery, Mail). PHP + MySQL. Used by 4500+ organizations. AGPL-3.0 (plus commercial EE)."
---

# HumHub

HumHub is **a modular open-source social networking / intranet platform** — think "Facebook for your company/school/organization" combined with wiki + file sharing + events + tasks. Used by 4500+ organizations worldwide; 30+ translations; responsive web + mobile apps.

Four-pillar architecture:

1. **Users** — profiles with cover photos, bios, custom fields; follow each other
2. **Spaces** — groups for projects/departments/events with fine-grained permissions
3. **Content** — posts, wiki pages, photos, files, calendar events, tasks, polls, etc.
4. **Modules** — ~80 modules extend functionality (LDAP, OnlyOffice, SSO, Gallery, Wiki, Mail DMs, News, Calendar…)

Use cases:

- **Corporate intranet** — announcements, teams, docs
- **School / university internal network** — classes, groups, resources
- **NGO / association community**
- **Customer community portal**
- **Family / club private social network**

Features:

- Feed / microblogging per-user and per-space
- Wiki module (versioned pages)
- Calendar (incl. CalDAV export)
- Tasks (project mgmt lite)
- Files (with folders, versioning)
- Gallery (photos/videos)
- Polls
- Direct messages (Mail module)
- Notifications (in-app + email)
- Mentions, tags, comments, likes, bookmarks
- Search (across content types)
- Mobile apps (iOS + Android)
- REST API (via RESTful API module)
- SSO (LDAP, SAML via Enterprise, JWT via module, OAuth2 via module)
- Theming (light/dark, custom themes)

- Upstream repo: <https://github.com/humhub/humhub>
- Website / Demo: <https://www.humhub.org>
- Docs: <https://docs.humhub.org>
- Community forum: <https://community.humhub.com>
- Marketplace (modules + themes): <https://marketplace.humhub.com>
- Enterprise: <https://www.humhub.com/licences>

## Architecture in one minute

- **PHP 8.0+** / Yii 2 framework
- **DB**: MySQL 5.7+ / MariaDB 10.3+ (Postgres unsupported)
- **Web server**: Apache / Nginx + PHP-FPM
- **File storage**: local filesystem (`uploads/`) — large over time
- **Search**: MySQL fulltext by default; optional Zend Lucene / ElasticSearch via module
- **Cron job**: **mandatory** — runs scheduled tasks (notifications, cleanup, email digests) every minute
- **Queue**: Sync by default (inline); for scale use DB-queue or Redis via module/config

## Compatible install methods

| Infra         | Runtime                                          | Notes                                                              |
| ------------- | ------------------------------------------------ | ------------------------------------------------------------------ |
| Single VM     | **Docker Compose** (community + `mariushoch/humhub`)   | Common                                                                |
| Single VM     | Native LAMP/LEMP + HumHub tarball                         | Classic PHP deploy                                                         |
| YunoHost      | Community package                                                 | One-click                                                                          |
| Kubernetes    | Community manifests                                                     | Possible                                                                                |
| Managed       | **HumHub Cloud** (`humhub.com`) commercial hosting                              | Upstream company's SaaS                                                                         |
| Raspberry Pi  | arm64 Docker or native                                                              | Fine for small community                                                                                  |

## Inputs to collect

| Input              | Example                            | Phase     | Notes                                                              |
| ------------------ | ---------------------------------- | --------- | ------------------------------------------------------------------ |
| Domain             | `intranet.example.org`                | URL       | Set in `config/dynamic.php`                                              |
| DB                 | MySQL/MariaDB creds                       | DB        | Only MySQL-family supported                                                     |
| Admin              | created via installer wizard                   | Bootstrap | Change default                                                                           |
| SMTP               | host/port/user/pass                                  | Email     | For user invites + notifications                                                                      |
| Upload path        | `uploads/` (writable by web server)                       | Storage   | Persistent volume                                                                                             |
| Open registration  | config flag                                                      | Policy    | Disable for private intranets                                                                                         |
| Modules            | Select from marketplace                                                 | Config    | Install via UI after first boot                                                                                                  |
| Cron               | `* * * * *` runs cron.php                                                        | Ops       | **MANDATORY**                                                                                                                            |

## Install via Docker

```yaml
services:
  humhub:
    image: mariushoch/humhub:1.x                 # community image, pin major
    container_name: humhub
    restart: unless-stopped
    depends_on: [db]
    environment:
      HUMHUB_DB_HOST: db
      HUMHUB_DB_USER: humhub
      HUMHUB_DB_PASSWORD: <strong>
      HUMHUB_DB_NAME: humhub
      HUMHUB_AUTO_INSTALL: "1"
      HUMHUB_ADMIN_EMAIL: admin@example.org
      HUMHUB_ADMIN_PASSWORD: <strong>
      HUMHUB_ADMIN_USERNAME: admin
      HUMHUB_SITE_NAME: "Acme Intranet"
      HUMHUB_BASE_URL: https://intranet.example.org
    volumes:
      - humhub-uploads:/var/www/localhost/htdocs/uploads
      - humhub-modules:/var/www/localhost/htdocs/protected/modules
      - humhub-config:/var/www/localhost/htdocs/protected/config
    ports:
      - "8080:80"

  db:
    image: mariadb:11
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: <strong>
      MARIADB_DATABASE: humhub
      MARIADB_USER: humhub
      MARIADB_PASSWORD: <strong>
    volumes:
      - humhub-db:/var/lib/mysql

volumes:
  humhub-uploads:
  humhub-modules:
  humhub-config:
  humhub-db:
```

Front with Caddy/Traefik for TLS.

## Cron (MANDATORY)

```cron
* * * * * www-data cd /var/www/humhub && php yii cron/run >/dev/null 2>&1
* * * * * www-data cd /var/www/humhub && php yii queue/run >/dev/null 2>&1
```

Without cron: notifications don't send, summary emails don't fire, search indexes stall.

## Install (native tarball)

```sh
wget https://download.humhub.com/downloads/install/humhub-1.x.zip
unzip humhub-1.x.zip -d /var/www/humhub
chown -R www-data:www-data /var/www/humhub
# Configure Apache/Nginx pointing at /var/www/humhub
# Browse site → installer wizard → fills protected/config/dynamic.php
# After install: delete / protect the installer directory per docs
```

## First boot

1. Browse site → installer wizard: name, DB, admin, base URL
2. Admin dashboard → Settings → configure SMTP
3. Settings → Appearance → set theme + logo
4. Settings → Users → registration mode (open / invite only / closed)
5. Marketplace → install needed modules (Calendar, Wiki, Files, OnlyOffice, LDAP, etc.)
6. Create first Space (e.g., "General") + add members
7. Test posting + commenting + a notification cycle

## Data & config layout

- `protected/config/dynamic.php` — generated config (DB, base URL)
- `protected/config/common.php` — optional custom overrides
- `uploads/` — user-uploaded files + profile pics (grows over time; can be GBs)
- DB — all content + users + memberships
- `protected/modules/` — installed marketplace modules

## Backup

```sh
# DB
docker exec humhub-db mysqldump -u root -p humhub | gzip > humhub-$(date +%F).sql.gz
# Uploads
tar czf humhub-uploads-$(date +%F).tgz uploads/
# Config
cp protected/config/dynamic.php humhub-config-$(date +%F).bak
```

Critical: uploads volume. Users' profile pictures + posted photos + attached files all live there.

## Upgrade

1. Releases: <https://github.com/humhub/humhub/releases>. Active.
2. **Back up DB + uploads + config.**
3. Docker: bump tag; migrations run automatically on container start.
4. Native: extract new tarball over old (preserving `uploads/`, `config/`, `modules/`), run:
   ```sh
   php yii migrate --migrationPath=@humhub/migrations --interactive=0
   php yii migrate/up --migrationPath=@humhub/modules/*/migrations --interactive=0
   ```
5. Read release notes for breaking module changes; some marketplace modules lag.

## Gotchas

- **Cron is mandatory.** Set it on day one; otherwise notifications silently fail.
- **MySQL only** — no Postgres. Don't pick HumHub if your org mandates Postgres.
- **Module marketplace quality varies** — core modules (Wiki, Calendar, Tasks, Gallery) are well-maintained. Third-party modules may lag behind major HumHub upgrades.
- **Enterprise Edition** — commercial feature add-ons (Advanced User Management, SAML SSO Pro, Audit Log, etc.). Community Edition is fully functional for most; don't expect SAML out of the box without EE or community module.
- **File uploads** — default limits in `php.ini`, Nginx, HumHub config all need to agree; otherwise upload silently fails. Raise in all three.
- **Email deliverability** — sends notifications aggressively; use a good SMTP relay (Mailgun/SES/etc.) + SPF/DKIM.
- **Private file downloads** — HumHub serves attachments through PHP with access checks; don't put `uploads/` in webroot directly.
- **GDPR** — has data-subject-access + anonymization tools; review for your jurisdiction.
- **Profile-field customization** is deep — admins can add arbitrary custom fields + mandatory.
- **Spaces are the core** — don't flood with hundreds of spaces; start small; use categories.
- **Notifications** can overwhelm — per-user preferences available; include digest option.
- **Scale**: 1k-10k users fine on modest hardware; beyond that consider Redis caching + search module + tuned MySQL.
- **Search**: default MySQL fulltext isn't great; install Zend Lucene or ElasticSearch module for real search.
- **Mobile apps** (iOS + Android) — official; require your HumHub URL + account.
- **RESTful API module** — paid (EE) for some endpoints; check module license.
- **Translations** — Crowdin-powered; 30+ languages; volunteer-driven quality varies.
- **Theme customization** — theming via LESS + custom modules; deep but learning curve.
- **License: AGPL-3.0** for CE. Modifying HumHub and hosting as a service to others triggers source-disclosure.
- **Enterprise: separate commercial license** for EE modules.
- **Deprecated `installer/` protection** — as with other PHP apps, block access after install (docs detail).
- **Don't forget to disable open registration** on private intranets.
- **Alternatives worth knowing:**
  - **Mastodon / Misskey / Pleroma** — ActivityPub; more microblogging-focused (separate recipes)
  - **Discourse** — forum-centric, different UX (separate recipe)
  - **BuddyBoss / BuddyPress** — WordPress-plugin-based social networking
  - **Mattermost / Rocket.Chat / Zulip** — team chat (different paradigm — chat not feed)
  - **Mastodon + Lemmy + Matrix** — federated alternatives
  - **Yammer / Microsoft Viva / Workplace by Meta (shutting down)** — commercial intranet social
  - **Slab / Notion / Outline / Confluence** — wiki-first
  - **Choose HumHub if:** you want Facebook-style intranet social feed + spaces + modular extensions.
  - **Choose Discourse if:** discussion + forums is the primary workflow.
  - **Choose Mastodon if:** you want federated vs closed organizational.
  - **Choose Outline/Slab if:** docs + knowledge base is primary, social feed is secondary.

## Links

- Repo: <https://github.com/humhub/humhub>
- Website: <https://www.humhub.org>
- Docs: <https://docs.humhub.org>
- Community: <https://community.humhub.com>
- Marketplace: <https://marketplace.humhub.com>
- Releases: <https://github.com/humhub/humhub/releases>
- Licences: <https://www.humhub.com/licences>
- Enterprise (hosted): <https://www.humhub.com>
- Install docs: <https://docs.humhub.org/docs/admin/installation>
- Cron docs: <https://docs.humhub.org/docs/admin/installation#cron-job>
- Mobile apps: <https://www.humhub.com/en/app>
