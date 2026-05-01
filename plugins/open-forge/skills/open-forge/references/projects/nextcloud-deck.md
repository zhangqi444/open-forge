---
name: Nextcloud Deck
description: "Kanban board app for Nextcloud. PHP. nextcloud/deck. Cards, labels, attachments, markdown, Circles integration, activity stream, mobile apps (Android/iOS), Trello import."
---

# Nextcloud Deck

**Kanban-style organization tool for Nextcloud.** Personal task management and team project organization integrated directly into your Nextcloud instance. Add tasks to cards, write notes in markdown, assign labels, share boards with your team, attach files, discuss with comments, and track changes in an activity stream.

Developed and maintained by **Nextcloud GmbH and contributors**. AGPL-3.0.

- Upstream repo: <https://github.com/nextcloud/deck>
- App store: <https://apps.nextcloud.com/apps/deck>
- Android app (F-Droid / Play): <https://github.com/stefan-niedermann/nextcloud-deck>
- iOS app: <https://github.com/holger-dev/nextdeck>
- Docs: <https://deck.readthedocs.io>

## Architecture in one minute

- **Nextcloud app** (PHP) — installs into an existing Nextcloud instance
- **Not a standalone app** — requires Nextcloud server
- No separate Docker container; ships as a `.tar.gz` app bundle installed via Nextcloud admin
- Data stored in your Nextcloud database (MySQL/PostgreSQL/SQLite)
- Resource: adds load to existing Nextcloud; not trivial for large boards (see performance note)

## Prerequisites

- A running **Nextcloud** instance (any modern supported version)
- Admin access to the Nextcloud instance (to install apps)

## Install

**Option 1: Nextcloud App Store (recommended)**

1. Log in to Nextcloud as admin.
2. Go to Apps → Search "Deck" → Install.
3. Done — Deck appears in the Nextcloud top menu.

**Option 2: Manual install**

```bash
# In your Nextcloud apps directory
cd /var/www/html/apps   # or your apps-extra dir
curl -LO https://github.com/nextcloud-releases/deck/releases/latest/download/deck.tar.gz
tar xzf deck.tar.gz
# Enable in Nextcloud admin → Apps
```

## First use

1. Open Nextcloud → click the Deck icon (top nav).
2. Create a **Board** (e.g. "Work Projects", "Household Tasks").
3. Add **Stacks** (columns) — typically "To Do", "In Progress", "Done".
4. Add **Cards** to stacks — each card = a task.
5. Click a card to add: description (markdown), due date, labels, attachments, comments, assigned users.
6. Share the board with teammates/Circles groups.
7. Watch changes in the Activity stream.

## Features

| Feature | Details |
|---------|---------|
| Boards | Create multiple kanban boards per user/team |
| Stacks | Columns within a board (configurable) |
| Cards | Tasks with title, description (markdown), due date |
| Labels | Color-coded tags; filter cards by label |
| Assignees | Assign cards to Nextcloud users |
| Attachments | Attach Nextcloud files; embed in markdown |
| Comments | Discuss cards with team; supports @mentions |
| Activity stream | Full audit trail of all changes |
| Board sharing | Share with individual users or Circles groups |
| Mobile apps | Android (F-Droid/Play) + iOS (App Store) |
| Trello import | Migrate from Trello via `trello-to-deck` |
| Mail-to-Deck | Create cards via email with `mail2deck` |
| Chrome extension | Create cards from browser tab with `A-deck` |
| QOwnNotes | Link cards to markdown notes |

## 3rd-party integrations

- [trello-to-deck](https://github.com/maxammann/trello-to-deck) — Migrate from Trello
- [mail2deck](https://github.com/newroco/mail2deck) — Create cards via email
- [A-deck](https://github.com/leoossa/A-deck) — Chrome extension: create card from current tab
- [QOwnNotes](https://github.com/pbek/QOwnNotes) — Note-to-card linking

## Backup

Deck data is in your Nextcloud database — it's backed up as part of your normal Nextcloud backup:

```sh
# Include in your Nextcloud backup routine:
mysqldump -u nextcloud -p nextcloud > nextcloud-$(date +%F).sql
# Deck's attachment files are in Nextcloud's data directory
```

## Upgrade

Deck is upgraded via the Nextcloud updater:
1. Nextcloud admin → Apps → Deck → Update (if available).
2. Or: `sudo -u www-data php /var/www/html/occ app:update deck`

## Gotchas

- **Requires an existing Nextcloud instance.** Deck is not standalone — if you don't run Nextcloud, use a different Kanban tool (Planka, Vikunja, etc.).
- **Performance limitations with large boards.** Upstream explicitly notes: Deck is not ready for intensive usage. A user with 13 boards × 100 cards × 5 attachments each = 6,500 DB queries per page load. Works fine for normal personal/small-team use; will struggle at scale.
- **Database choice matters.** SQLite is supported but not recommended for multi-user or large-board Nextcloud. MySQL/PostgreSQL + proper indexes are essential if you have many boards.
- **Circles app for team sharing.** "Circles" is a separate Nextcloud app; install it to share boards with groups (not just individual users).
- **Mobile apps are from separate maintainers.** The Android app (stefan-niedermann/nextcloud-deck) and iOS app (holger-dev/nextdeck) are community-maintained, not by the core Deck team. Check their repos for compatibility with your Nextcloud + Deck version.
- **Activity feed can grow large.** Every card move, edit, comment generates an activity entry. Nextcloud's background job prunes old activities — ensure your background jobs (cron) are running.
- **AGPL-3.0.** Deck's source must remain open if you modify and serve it over a network.
- **Deck API.** There's a REST API for Deck — useful for integrations and automation. See `deck.readthedocs.io`.

## Project health

Active development, Nextcloud App Store, CI, Android + iOS mobile apps, AGPL, multiple integrations. Maintained by Nextcloud GmbH + community. High usage across Nextcloud installations.

## Kanban-within-Nextcloud vs standalone comparison

- **Nextcloud Deck** — integrated into Nextcloud; no extra infra; limited scale
- **Planka** — Node.js + Postgres, standalone Kanban, Trello-like; no Nextcloud dependency
- **Vikunja** — Go, task management + Kanban, CalDAV/CalDAV; standalone
- **Wekan** — Meteor, MongoDB, open-source Trello clone; standalone
- **Trello** — SaaS; the commercial reference

**Choose Nextcloud Deck if:** you already run Nextcloud and want integrated Kanban without running another service.

## Links

- Repo: <https://github.com/nextcloud/deck>
- App Store: <https://apps.nextcloud.com/apps/deck>
- Docs: <https://deck.readthedocs.io>
- Android app: <https://github.com/stefan-niedermann/nextcloud-deck>
- iOS app: <https://github.com/holger-dev/nextdeck>
- Planka (standalone alt): <https://planka.app>
