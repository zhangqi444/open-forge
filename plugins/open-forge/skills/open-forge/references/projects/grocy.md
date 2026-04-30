---
name: Grocy
description: "ERP for your household — batteries-included grocery + chore management. Stock tracking, shopping lists, meal planning, recipe cost, barcode scanning, chores with due dates, batteries list, equipment, tasks. PHP + SQLite. Runs on a Pi. MIT."
---

# Grocy

Grocy is genuinely what it calls itself: "**ERP for your household**." It tracks every jar of peanut butter, every roll of toilet paper, every AA battery, every chore, every home-maintenance task, and every recipe — with expiry dates, reorder thresholds, consumption rates, and meal plans tied to stock levels.

It's not for everyone (it's a lot of data entry), but for people who want to stop running out of coffee, track what's in the freezer, plan meals with accurate "do I have the ingredients" checks, and know when to change the smoke alarm batteries — Grocy is unmatched.

Core features:

- **Stock tracking** — every product with quantity, location, expiry date, price, barcode
- **Shopping list** — auto-generated from reorder thresholds
- **Meal planning** — calendar of meals → generates shopping list
- **Recipes** — with ingredient lists, cost per serving, nutrition
- **Chores** — recurring tasks with assignees, schedules, due dates
- **Tasks** — one-off household to-dos
- **Batteries** — tracks battery life/charge cycles by device
- **Equipment** — appliances, tools, manuals, warranty docs
- **Userfields + userentities** — extend with your own data model
- **Multiple locations** — "pantry", "freezer 1", "garage", "toolshed"
- **Barcode scanning** — via Grocy's **Barcode Buddy** and the Android/iOS apps
- **Multi-user** with quantity unit conversions
- **REST API** — full CRUD
- **Bulk import** from CSV
- **Notifications** — Apprise integration (Telegram, email, Discord, etc.)
- **OpenFoodFacts integration** — scan barcode → auto-fill product

- Upstream repo: <https://github.com/grocy/grocy>
- Website: <https://grocy.info>
- Demo: <https://demo.grocy.info>
- Docker Hub (LSIO): <https://hub.docker.com/r/linuxserver/grocy>
- Barcode Buddy: <https://github.com/Forceu/barcodebuddy>
- Android app: <https://github.com/patzly/grocy-android> (community)
- iOS app: "Grocy mobile" (community)

## Architecture in one minute

- **PHP 7.4+ / 8.x** (Slim framework)
- **SQLite** — the one and only DB (no MySQL/Postgres)
- **No Node, no Redis, no queue** — self-contained
- **REST API** + embedded web UI (Bootstrap + Vanilla JS)
- **File upload** — local disk
- Tiny footprint — runs on a Pi Zero

## Compatible install methods

| Infra       | Runtime                                          | Notes                                                            |
| ----------- | ------------------------------------------------ | ---------------------------------------------------------------- |
| Single VM   | **LinuxServer.io Docker** (`linuxserver/grocy`)     | **Most common**                                                     |
| Raspberry Pi | arm64 / armhf images                                | **Popular Pi project**                                                   |
| NAS         | Synology / QNAP Docker                                   | Trivial                                                                      |
| Native      | Apache/Nginx + PHP-FPM                                   | Standard LAMP deploy                                                              |
| Shared host | cPanel PHP hosting                                         | Tiny footprint; works                                                                 |
| Kubernetes  | Minimal Deployment + PVC                                      | Stateless container, SQLite file on PVC                                                    |

## Inputs to collect

| Input         | Example                     | Phase     | Notes                                                           |
| ------------- | --------------------------- | --------- | --------------------------------------------------------------- |
| Port          | `80` or `9283` (LSIO default) | Network   | Behind reverse proxy with TLS optional                              |
| Data dir      | `/config`                      | Storage   | SQLite DB + uploaded files (photos, receipts, manuals)                       |
| Admin user    | default `admin` / `admin`        | Bootstrap | **CHANGE ON FIRST LOGIN**                                                    |
| PUID/PGID     | `1000` / `1000`                   | Perms     | LSIO convention                                                                      |
| Timezone      | `America/Los_Angeles`               | Locale    | Affects expiry dates                                                                       |
| Barcode mode (opt) | Barcode Buddy companion service | Hardware | For USB-barcode-scanner workflow                                                             |

## Install via Docker (LinuxServer.io)

```sh
docker run -d --name grocy \
  --restart unless-stopped \
  -p 9283:80 \
  -v /opt/grocy/config:/config \
  -e PUID=1000 -e PGID=1000 -e TZ=America/Los_Angeles \
  lscr.io/linuxserver/grocy:4.x   # pin; check Docker Hub
```

Browse `http://<host>:9283` → log in with default **`admin` / `admin`** and **change password immediately**.

## Install via Docker Compose

```yaml
services:
  grocy:
    image: lscr.io/linuxserver/grocy:4.x
    container_name: grocy
    restart: unless-stopped
    ports:
      - "9283:80"
    environment:
      PUID: 1000
      PGID: 1000
      TZ: America/Los_Angeles
    volumes:
      - ./config:/config

  # Optional: Barcode Buddy companion — scan barcodes via USB scanner, auto-log to Grocy
  barcodebuddy:
    image: f0rc3/barcodebuddy-docker:latest
    container_name: barcodebuddy
    restart: unless-stopped
    ports:
      - "8100:80"
    environment:
      BBUDDY_GROCY_API_URL: http://grocy:80/api/
      BBUDDY_GROCY_API_KEY: <api-key-from-grocy-user-profile>
    volumes:
      - ./barcodebuddy:/config
```

## First boot

1. Log in with `admin` / `admin` → **change password**
2. Settings (top right) → profile → configure timezone, language, date format
3. Settings → Manage Master Data:
   - Locations: "pantry", "freezer", "fridge", "garage"
   - Quantity units: "piece", "gram", "ml" (seed set exists; customize)
   - Products: add your first product manually or via barcode scan
4. Start scanning groceries when you shop → stock builds up
5. Set min-stock amounts → shopping list populates automatically
6. Add recipes → meal plan → weekly shopping auto-generated

## Data & config layout

Inside `/config` (LSIO):

- `data/grocy.db` — **the SQLite DB — everything lives here**
- `data/storage/` — uploaded files (product photos, equipment manuals, receipts)
- `data/plugins/` — userscripts/plugins
- `data/config.php` — runtime config overrides
- `www/data/` — legacy paths (depends on version)
- `php/php.ini` — PHP settings

## Backup

```sh
# The DB is CRITICAL — one file
cp /opt/grocy/config/data/grocy.db /backups/grocy-$(date +%F).db

# Storage (photos, manuals) — optional but nice
tar czf grocy-storage-$(date +%F).tgz /opt/grocy/config/data/storage
```

## Upgrade

1. Releases: <https://github.com/grocy/grocy/releases>. Active.
2. Docker: `docker compose pull && docker compose up -d`. Migrations run on startup.
3. **Always back up `grocy.db` first** — DB migrations occasionally need tweaks if upgrading across multiple major versions.
4. Native: download latest release zip; preserve `data/` and `config.php`; overwrite rest; browse `/` to run migration.

## Gotchas

- **Default creds `admin` / `admin`** — CHANGE ON FIRST LOGIN. If exposed publicly before change, assume compromise.
- **It's a lot of data entry** — Grocy rewards people who're willing to scan every purchase. If you hate data entry, Grocy will feel like a second job. Consider whether you'll actually maintain it before committing.
- **Barcode scanning is the killer feature for adoption** — getting a USB barcode scanner (~$30) or using Barcode Buddy with a phone as scanner dramatically changes the UX. Without it, Grocy is tedious.
- **OpenFoodFacts integration** — great for first-scan autofill, but coverage is spotty for non-European products. Prepare to enter non-matching items manually the first time.
- **Mobile apps are community-maintained** — "Grocy Android" (patzly) and iOS "Grocy mobile" are not from upstream. They've been reliable but aren't guaranteed to track the latest API changes immediately.
- **Quantity unit conversions** are powerful but confusing at first — 1 kg of flour → 1 kg flour in pantry, but recipe needs 500g, which is "0.5 of pantry flour." Set up QU conversions carefully per product.
- **Multi-user + shared household** — multiple accounts share the same DB (it's a household-level tool, not a multi-tenant platform). Per-user permissions are coarse.
- **Recipes with price tracking** — cost-per-serving is only accurate if you update purchase prices consistently.
- **Batteries / Equipment features** are genuinely unique among household-management tools. Pairs nicely with home-assistant notifications when you tie charge cycles / warranty expiries to HA.
- **Chores feature overlaps with task tools** (Todoist, TickTick, home assistant) — decide whether you want chores in Grocy vs elsewhere. Doing both = duplicate maintenance.
- **Notifications** via Apprise — configure under Settings → Apprise. Useful for "stock low: coffee" or "chore due: change smoke alarm batteries."
- **Backup discipline** — SQLite is one file. If lost, you lose everything. Set up automated daily backups + offsite.
- **Multi-household / multi-user separation** — not designed for it. Each install = one household.
- **Shopping list apps** — Grocy's built-in list is fine; if you want Bring!/Google Keep sync, you'll need an external bridge (community scripts exist).
- **Recipe import** — no one-click URL-to-recipe import (unlike Mealie/Tandoor). You manually enter. Mealie paired with Grocy is a common combo (Mealie for recipe discovery + Grocy for stock).
- **PWA installable** on phones — decent mobile UX for quick stock decrements while cooking.
- **Active development** — 1-2 major releases/year + patches; stable and well-maintained.
- **No cloud sync** — self-hosted only (which is the point).
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **Mealie** — recipe-focused; meal planning; not full household ERP (separate recipe)
  - **Tandoor Recipes** — recipes + meal plan + shopping list; no stock/chores (separate recipe)
  - **KitchenOwl** — meal-planning-focused; lighter than Grocy
  - **Home Assistant** — has integrations that sync Grocy state with HA for automation
  - **Our Groceries / Bring! / AnyList** — SaaS shopping list apps
  - **Pantry Check / Fridgely / MyFridgeFood** — commercial apps
  - **Choose Grocy if:** you want a **whole-household ERP** — stock + recipes + chores + equipment + batteries — and are willing to do the data entry.
  - **Choose Mealie/Tandoor if:** you only care about recipes + meal planning.
  - **Choose Bring! if:** you just want a shared shopping list.

## Links

- Repo: <https://github.com/grocy/grocy>
- Website: <https://grocy.info>
- Demo: <https://demo.grocy.info>
- Documentation: <https://grocy.info/docs>
- Discourse: <https://forums.grocy.info>
- Discord: <https://discord.gg/RjYCv7Z>
- Docker Hub (LSIO): <https://hub.docker.com/r/linuxserver/grocy>
- Barcode Buddy: <https://github.com/Forceu/barcodebuddy>
- Android (community): <https://github.com/patzly/grocy-android>
- F-Droid: <https://f-droid.org/packages/xyz.zedler.patrick.grocy>
- Releases: <https://github.com/grocy/grocy/releases>
- Changelog: <https://github.com/grocy/grocy/blob/master/changelog/60_UNRELEASED_xxxx-xx-xx.md>
- Apprise docs (for notifications): <https://github.com/caronc/apprise>
