---
name: Nextcloud News
description: "RSS/Atom feed aggregator app for Nextcloud. Nextcloud app (PHP). nextcloud/news. Install from Nextcloud app store — no standalone Docker image. Multi-folder feed management, unread tracking, API for mobile apps (Nextcloud News Android, Vienna RSS, etc.), AGPL-3.0."
---

# Nextcloud News

**RSS/Atom feed aggregator for Nextcloud.** Read all your RSS and Atom feeds in one place inside your Nextcloud instance. Organize feeds in folders, mark items read/unread, star articles. RESTful API for third-party clients (Nextcloud News Android app, Vienna RSS, Reeder, etc.).

Built + maintained by **Nextcloud community**. AGPL-3.0 license.

- Upstream repo: <https://github.com/nextcloud/news>
- Nextcloud App Store: <https://apps.nextcloud.com/apps/news>
- Docs: <https://nextcloud.github.io/news/>

> **Installation note:** Nextcloud News is a **Nextcloud app** — not a standalone Docker container. It requires a running Nextcloud instance and is installed via the Nextcloud app store or manually. There is no `docker-compose.yml` for News alone.

## Prerequisites

- A running Nextcloud instance (self-hosted via Docker or otherwise)
- Nextcloud 25+ (check the app store page for current compatibility)
- PHP (already part of Nextcloud)

## Install

### Option 1: Nextcloud web UI (easiest)

1. Log in as Nextcloud admin.
2. Go to **Apps** → search for "News".
3. Click **Install** → wait for installation.
4. Open News from the top navigation bar.

### Option 2: App store download + manual install

```bash
# Inside your Nextcloud apps directory
curl -L https://github.com/nextcloud-releases/news/releases/latest/download/news.tar.gz | \
  tar xz -C /var/www/nextcloud/apps/
# Then enable in Nextcloud admin panel: Apps → News → Enable
```

### Option 3: occ command

```bash
docker compose exec nextcloud php occ app:install news
docker compose exec nextcloud php occ app:enable news
```

## Configuration

Configure the background job (feed fetching) in Nextcloud admin → Basic settings → Background jobs. Recommended: **cron** via system crontab:

```cron
*/15 * * * * www-data php /var/www/nextcloud/cron.php
```

Or use the Nextcloud Docker image's built-in cron sidecar container. News fetches feeds on cron runs — longer intervals mean slower updates.

## Features overview

| Feature | Details |
|---------|---------|
| RSS/Atom feeds | Subscribe to any RSS 2.0 or Atom 1.0 feed |
| Folder organization | Group feeds into named folders |
| Unread tracking | Mark items read, unread; track reading progress |
| Starred items | Star articles to save for later |
| Search | Search across feed items |
| OPML import/export | Import/export your feed list (OPML format) |
| Mobile app API | RESTful API used by Android/iOS clients |
| Shared feeds | Share feed subscriptions with other Nextcloud users |
| Theme integration | Inherits Nextcloud dark/light theme |

## Mobile and desktop clients

Nextcloud News has a RESTful API compatible with several third-party readers:

| Client | Platform |
|--------|---------|
| Nextcloud News (official) | Android |
| Vienna RSS | macOS |
| Reeder | iOS/macOS |
| ReadKit | macOS/iOS |
| Fiery Feeds | iOS |
| Various community clients | Linux, Windows |

## Gotchas

- **Requires Nextcloud.** This is not a standalone app. You need a full Nextcloud installation. If you just want an RSS reader without Nextcloud, use FreshRSS, Miniflux, or Tiny Tiny RSS instead.
- **Background job must be configured.** Feeds won't update automatically without a working Nextcloud cron job. The default "AJAX" background job is unreliable — use system cron or the Nextcloud cron sidecar container.
- **Parallel feed fetch limit.** By default, Nextcloud News fetches feeds sequentially during cron runs. For many feeds, increase parallelism in the News admin settings.
- **No built-in full-text fetch.** News shows the content provided by the feed. For feeds that only publish summaries, full article text must be fetched by a proxy/plugin if desired.

## Upgrade

Upgrade via Nextcloud admin panel (Apps → Updates) or:
```bash
docker compose exec nextcloud php occ app:update news
```

## Project health

Active Nextcloud community development, REST API for clients, AGPL-3.0.

## RSS-reader-family comparison

- **Nextcloud News** — Nextcloud app, no standalone install, REST API for clients, AGPL-3.0
- **FreshRSS** — PHP, standalone, multi-user, Fever/Google Reader API, AGPL-3.0
- **Miniflux** — Go, standalone, minimal, fast, PostgreSQL, AGPL-3.0
- **Tiny Tiny RSS** — PHP, standalone, feature-rich, complex; standalone
- **Yarr** — Go, single binary, SQLite; simple, personal use

**Choose Nextcloud News if:** you already run Nextcloud and want an RSS reader integrated into your Nextcloud ecosystem with mobile app API support.

## Links

- Repo: <https://github.com/nextcloud/news>
- Nextcloud App Store: <https://apps.nextcloud.com/apps/news>
- Docs: <https://nextcloud.github.io/news/>
