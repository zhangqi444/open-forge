---
name: HomeBox
description: "Self-hosted home inventory + organization system — track your stuff, locations, categories, tags, warranties, receipts, photos, maintenance. Single Go binary + embedded Web UI + SQLite. Tiny (<50 MB RAM). AGPL-3.0."
---

# HomeBox

HomeBox is **a home inventory management system** — cataloging the stuff you own: electronics, tools, kitchen appliances, hobby gear, kids' toys, seasonal stuff in the attic. Every item gets a location (house → garage → shelf 3), category, tags, photos, receipts, warranty info, purchase date/price, notes. Search across everything. Perfect for: insurance claims (you know what you had), finding "where did I put X," warranty tracking, decluttering.

**Fork note**: HomeBox was originally developed at `hay-kot/homebox` (project by the Mealie author). **`hay-kot/homebox` has been archived/paused; `sysadminsmedia/homebox` is the active community fork** and is considered the canonical successor.

Design principles (upstream):

- **Simple but expandable** — no complicated setup
- **Blazingly fast** — Go; idle RAM <50 MB
- **Portable** — SQLite + embedded UI; rsync the data directory and you're moved

Features:

- **Rich organization** — items, locations (nested), categories, tags
- **Custom fields** per item
- **Powerful search** — full-text across all items
- **Image upload** — multiple photos per item
- **Document + warranty tracking** — attach PDFs, receipts
- **Purchase tracking** — price, date, vendor
- **Maintenance** — schedule + log repairs, cleaning, service
- **QR codes** — print labels; scan to view item
- **Import** — CSV + JSON
- **Multi-user** with group-level sharing
- **Responsive UI** — desktop / tablet / phone
- **REST API**

- Upstream repo (active): <https://github.com/sysadminsmedia/homebox>
- Original repo (archived): <https://github.com/hay-kot/homebox>
- Docs: <https://homebox.software/en/>
- Quick start: <https://homebox.software/en/quick-start/>
- Demo: <https://demo.homebox.software>
- Nightly demo: <https://nightly.homebox.software>
- Discord: <https://discord.gg/aY4DCkpNA9>

## Architecture in one minute

- **Single Go binary** with embedded Web UI (Vue/Nuxt compiled in)
- **SQLite** DB (or Postgres for multi-writer)
- **Local filesystem** for uploaded images + docs
- **Very low resource** — <50 MB RAM idle
- **Single Docker container** is the deployment unit

## Compatible install methods

| Infra              | Runtime                                                         | Notes                                                                          |
| ------------------ | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **Docker (`ghcr.io/sysadminsmedia/homebox`)**                       | **Upstream-recommended**                                                           |
| Single VM          | Native Go binary                                                             | From releases                                                                                  |
| Raspberry Pi       | arm64 Docker — tiny footprint                                                             | Ideal Pi use case                                                                                          |
| Synology / QNAP    | Docker                                                                                      | Common NAS deployment                                                                                                   |
| Kubernetes         | Community manifests                                                                                        | Simple: Deployment + PVC                                                                                                               |
| Managed            | **PikaPods** (commercial managed) — <https://www.pikapods.com/pods?run=homebox>                                        | Paid hosted                                                                                                                                         |

## Inputs to collect

| Input              | Example                               | Phase     | Notes                                                                     |
| ------------------ | ------------------------------------- | --------- | ------------------------------------------------------------------------- |
| Domain             | `inventory.example.com`                   | URL       | Behind reverse proxy                                                              |
| Port               | `7745`                                      | Network   | Default                                                                              |
| Data dir           | `/data`                                          | Storage   | SQLite + uploaded images/docs                                                                 |
| Admin user         | created on first registration                           | Bootstrap | **Lock registration after creating admin** (env var)                                                           |
| DB                 | SQLite (default) / Postgres                                  | DB        | SQLite fine for most                                                                                   |

## Install via Docker

```yaml
services:
  homebox:
    image: ghcr.io/sysadminsmedia/homebox:latest     # pin in prod
    container_name: homebox
    restart: unless-stopped
    ports:
      - "7745:7745"
    environment:
      HBOX_LOG_LEVEL: info
      HBOX_LOG_FORMAT: text
      HBOX_WEB_MAX_UPLOAD_SIZE: "10"                  # MB
      HBOX_OPTIONS_ALLOW_REGISTRATION: "true"          # set false after creating admin!
    volumes:
      - ./data:/data
```

Browse `http://<host>:7745/`.

## First boot

1. Browse → Register (first user creates a group + becomes admin)
2. **After registering**: set `HBOX_OPTIONS_ALLOW_REGISTRATION=false` + restart, so strangers can't sign up
3. Create Locations: "House" → "Garage" → "Shelf 3" → etc.
4. Create Categories: Electronics, Tools, Books, etc.
5. Add items → photos → warranty doc → purchase price
6. (Optional) Print QR code labels for boxes — scan to list contents
7. Invite family (same group) so everyone sees shared household items

## Data & config layout

- `/data/homebox.db` — SQLite
- `/data/documents/` — uploaded files
- Env vars control all config

## Backup

```sh
docker compose stop homebox             # consistent SQLite snapshot (seconds)
sudo tar czf homebox-$(date +%F).tgz data/
docker compose start homebox
```

Losing the DB = losing your entire inventory. Back up — weekly minimum; monthly snapshot to cold storage.

## Upgrade

1. Releases: <https://github.com/sysadminsmedia/homebox/releases>. Active.
2. Back up `data/` before major jumps.
3. Docker: bump tag; migrations auto.

## Gotchas

- **Archived original vs active fork**: if you find `hay-kot/homebox`, note it's archived. `sysadminsmedia/homebox` is maintained. Docker image paths differ.
- **Migration from `hay-kot` to `sysadminsmedia`**: DB is compatible; swap Docker image; works. Verify on a copy first.
- **Registration default**: `HBOX_OPTIONS_ALLOW_REGISTRATION=true` by default. **Disable** after creating your admin user — otherwise anyone reaching your UI can sign up.
- **Not a POS system**: HomeBox is for personal inventory, not for a shop. For retail / warehouse, use something like Part-DB / Snipe-IT / InvenTree.
- **Not for high-value tracking** with chain-of-custody needs. Use for home stuff.
- **Upload size default** is modest — set `HBOX_WEB_MAX_UPLOAD_SIZE` for bigger receipts/PDFs.
- **QR codes**: print from UI on label sheets; physical labels dramatically improve "where did I put the drill?" UX.
- **Custom fields**: use per-item for things like serial numbers, MACs, model numbers. Critical for electronics inventory.
- **Sharing**: multi-user within a "group"; shared view. No granular per-item permissions — all group members see all items.
- **Backups for insurance**: keep an offsite copy — if fire/theft, your HomeBox DB is the list insurance wants.
- **Import**: CSV + JSON importer handles bulk adds. Export to JSON for portability.
- **License**: **AGPL-3.0**.
- **Alternatives worth knowing:**
  - **Snipe-IT** — IT asset management; more enterprise; PHP/Laravel (separate recipe likely)
  - **InvenTree** — inventory management; engineering/maker focus (batch 61 recipe)
  - **Part-DB** — electronic components inventory
  - **Grocy** — household management (batch 59 recipe); different scope (groceries + chores; limited item inventory)
  - **Spreadsheet / Notion / AppSheet** — DIY
  - **StuffKeeper** — similar concept
  - **Choose HomeBox if:** home-user inventory; simple + blazing fast + SQLite portability.
  - **Choose Snipe-IT if:** IT/office asset tracking with check-in/check-out.
  - **Choose InvenTree if:** engineering/maker parts inventory + BOM.
  - **Choose Grocy if:** household management beyond just inventory.

## Links

- Active repo: <https://github.com/sysadminsmedia/homebox>
- Original (archived): <https://github.com/hay-kot/homebox>
- Docs: <https://homebox.software/en/>
- Quick start: <https://homebox.software/en/quick-start/>
- Demo: <https://demo.homebox.software>
- Releases: <https://github.com/sysadminsmedia/homebox/releases>
- Docker (GHCR): <https://github.com/sysadminsmedia/homebox/pkgs/container/homebox>
- Discord: <https://discord.gg/aY4DCkpNA9>
- Reddit: <https://reddit.com/r/homebox>
- Translations (Weblate): <https://translate.sysadminsmedia.com>
- Managed option (PikaPods): <https://www.pikapods.com/pods?run=homebox>
- Snipe-IT (alt): <https://snipeitapp.com>
- InvenTree (alt, engineering): see batch 61 recipe
- Part-DB (alt, electronics): <https://github.com/Part-DB/Part-DB-server>
