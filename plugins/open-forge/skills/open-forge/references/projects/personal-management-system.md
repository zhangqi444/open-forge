---
name: Personal Management System (PMS)
description: "Self-hosted 'personal CMS/CRM' — single place for todos, notes, contacts, passwords, schedules, travel plans, payments, files, photos, videos. Solo-dev hobby project; ‘no support guaranteed'. Symfony backend + separate frontend. MIT-licensed. Intended for private home-network use."
---

# Personal Management System (PMS)

Volmarg's Personal Management System is **"a personal CMS / CRM for your own life"** — one self-hosted web app where todos, notes, contacts, passwords, achievements, schedules, pending issues, travel plans, payments, shopping lists, work-hours, files, images, and videos all live. The author's stated goal: **"have an application running on a Raspberry Pi 24/7 plugged into my home network, without access to internet"**. This is a solo-dev + self-use project that was open-sourced, not a product trying to attract enterprise customers.

Built + maintained by **Volmarg** (solo). **MIT-licensed**. Split-repo design: this is the **backend** (<https://github.com/Volmarg/personal-management-system>); frontend is <https://github.com/Volmarg/personal-management-system-front>. Documentation + demo: <https://volmarg.github.io>. Upstream is **extremely candid**: *"I cannot guarantee support. I've got a job, personal things etc, I'm just sharing my code/my application as MIT."*

Use cases: (a) **digital-minimalist** who wants ONE tool instead of Notion + Google Keep + LastPass + Todoist + TripIt + Mint (b) **home-network-only private cloud** on a Pi (c) **code-comfortable user** willing to hack on Symfony extensions for new modules (d) **NOT** for: multi-user teams, enterprise, or anyone needing vendor-support.

Modules (from README, paraphrased):

- **🎯 Todo/Goals** — tasks + payment-collection goals
- **📖 Notes** — categorized scratch notes
- **📞 Contacts** — address book + backup
- **🔑 Passwords** — encrypted in DB with copy button
- **🏆 Achievements** — personal wins log
- **📅 Schedules** — recurring reminders (oil changes, bills, visits)
- **🔁 Issues** — ongoing/pending cases with subrecord contacts
- **🌴 Travels** — places to visit with Google Map + images
- **💸 Payments** — spending tracker, owed-money, bills
- **🛒 Shopping** — wishlist
- **💻 Job** — afterhours + holidays tracker
- **📷 Images** — masonry galleries
- **📁 Files** — DataTable browser
- **🎬 Video** — personal video store
- **📑 Reports** — read-only data reports

- Upstream backend: <https://github.com/Volmarg/personal-management-system>
- Upstream frontend: <https://github.com/Volmarg/personal-management-system-front>
- Docs: <https://volmarg.github.io>
- Getting-started / install: <https://volmarg.github.io/docs/getting-started/installation.html>
- Demo: <http://personal-management-system.pl/> (admin@admin.admin / admin)
- Tech stack: <https://volmarg.github.io/docs/technical/tech-stack.html>

## Architecture in one minute

- **PHP Symfony** backend
- **Separate React (or similar) frontend** — deploy both
- **MySQL / MariaDB** — relational DB
- **File storage** — local filesystem
- **Resource**: modest — Pi-friendly by design
- **Single-user** — no multi-tenant; one admin = the whole system

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | Upstream + community Docker images (check current)              | **Typical path**                                                                   |
| Bare-metal         | PHP 8 + Symfony + MySQL + nginx                                           | Upstream documents this                                                                    |
| Raspberry Pi       | Pi-friendly by design                                                                 | Author runs it on his own Pi                                                                           |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain / LAN address | `pms.home.lan`                                              | URL          | **LAN-only** recommended by author's stated use-case                                                                        |
| MySQL creds          | DB + user                                                   | DB           | Symfony conventions                                                                                        |
| `APP_SECRET`         | long random                                                                          | Secret       | Symfony; **immutable** class                                                                                                      |
| Backend + frontend   | Deploy BOTH repos                                                                                       | Setup        | This is split-repo; missing one = broken system                                                                                                      |
| Password-module encryption key                                | Encrypts password-module data in DB                                                                                                          | Secret       | **Crown-jewel** — protects stored passwords                                                                                                                       |

## Install

Follow upstream documentation at <https://volmarg.github.io/docs/getting-started/installation.html>.

**High-level**:
1. Clone BACKEND repo (`Volmarg/personal-management-system`)
2. Clone FRONTEND repo (`Volmarg/personal-management-system-front`)
3. MySQL DB + Symfony `.env` config
4. `composer install` + migrations
5. Frontend build → serve via nginx
6. First login (demo creds `admin@admin.admin` / `admin` — **CHANGE IMMEDIATELY**)

## First boot

1. Change default admin password **FIRST**
2. Configure the password-module encryption key (before storing any passwords!)
3. Import contacts / existing data if any
4. Explore modules; disable ones you won't use
5. Back up DB
6. Put behind reverse proxy with TLS if reachable beyond `localhost`
7. **Preferred: LAN-only**. Don't expose to public internet given solo-dev + "no support guaranteed" posture.

## Data & config layout

- **MySQL** — all module data (todos, notes, contacts, passwords, etc.)
- **Filesystem** — uploaded images, videos, files
- **Password module** — DB-encrypted at rest (if encryption key configured)

## Backup

```sh
# DB
mysqldump -u pms -p pms > pms-$(date +%F).sql
# Uploaded files
sudo tar czf pms-files-$(date +%F).tgz /path/to/pms/uploads
# Config + .env (includes encryption keys)
sudo cp .env .env-$(date +%F).backup
```

**Do NOT lose the password-module encryption key** — without it, stored passwords are unrecoverable.

## Upgrade

1. Releases: <https://github.com/Volmarg/personal-management-system/releases>. Slow / hobby-pace.
2. `git pull` + `composer install` + migrations.
3. **Back up DB + `.env` FIRST.**
4. Hobby project = read release notes carefully.

## Gotchas

- **"No support guaranteed"** — upstream is completely honest about this. Volmarg is a working dev using his own tool; MIT-release is a gift, not a service. Same **transparent-status family** as Wakapi / xyOps / Dim / pad-ws (batches 81-85). **Fifth tool in the honest-maintenance-mode family.** You get what you get.
- **Solo-dev + personal-project = bus-factor-1.** Volmarg could stop pushing commits tomorrow with zero warning. Plan accordingly:
  - **Keep backups external** (not just on the PMS host)
  - **Export data periodically** to formats you can import elsewhere (CSV for contacts, plain text for notes)
  - **Consider alternatives** for critical data classes (e.g., store passwords in a REAL password manager like Vaultwarden, not in PMS's Passwords module)
- **Passwords module vs actual password managers**: this module exists for convenience; it's **NOT** a designed-for-security password vault like **Vaultwarden / Bitwarden / KeePassXC**. Differences:
  - PMS passwords-module = DB-encrypted, Symfony-stored, solo-dev code
  - Vaultwarden = audited-protocol-compatible, E2E-encrypted, clients on every platform, battle-tested
  - **For actual password security: use Vaultwarden.** Use PMS passwords module only for "website-I-visit-once-a-year" tier secrets.
- **Default demo credentials (`admin@admin.admin` / `admin`)** — these are PUBLIC. Scanners know them. **Change immediately on first boot.** Same class as Black Candy (batch 83) default-admin-PUBLIC pattern.
- **LAN-only deployment matches upstream intent.** The author explicitly designed for "without access to internet" use. Exposing PMS to public internet = misusing the tool + amplifying solo-dev bus-factor risk. Threat model assumes trusted LAN.
- **Single-user, full-admin**: there's one user = you. No RBAC, no multi-tenant, no guest mode. Fine for intended use-case.
- **Split-repo architecture** — backend + frontend are separate repos. You MUST clone + deploy both. Common stumble for new users: deploying only the backend + confused why the UI doesn't work.
- **Scope-overlap with best-of-breed tools**: PMS tries to be "one tool for everything", which means:
  - **Todos** — worse than Vikunja / Todoist
  - **Notes** — worse than Obsidian / Joplin / Standard Notes
  - **Passwords** — worse than Vaultwarden / Bitwarden
  - **Contacts** — worse than Radicale + CardDAV
  - **Travel** — worse than TripIt / dedicated apps
  - **Photos** — worse than Immich / PhotoPrism
  - **Files** — worse than Nextcloud / Seafile
  - **Payments** — worse than Actual Budget / ezBookkeeping
  - The VALUE is **one install + one backup + one UI**, not feature-depth per module. Same **integrated-vs-best-of-breed** tradeoff framing as xyOps (84). Know what you're buying.
- **Symfony framework maintenance** — upstream PHP + Symfony version drift matters. Volmarg targets PHP 8.x + a specific Symfony version. Upgrading dependencies independently may break.
- **Encryption key for passwords module is CROWN-JEWEL.** Losing it = decades of stored passwords are garbage. **Back up separately** from DB backups. **Immutability-of-secrets family — 9th tool** (after Black Candy, Lychee, Forgejo, Fider, FreeScout, Nexterm, Wakapi, Statamic, Vikunja).
- **Project health**: solo-dev + personal use + hobby pace + MIT + long-running. Not abandoned; not accelerating. Perfect fit for a small audience; wrong fit for production/team/business. **Use at your own risk, with honest expectations.**
- **Alternatives worth knowing:**
  - **Nextcloud** — the OSS heavyweight personal-cloud; battle-tested
  - **Obsidian** (commercial) + **Joplin** / **Standard Notes** (OSS) — notes-first
  - **Vaultwarden** — proper password manager
  - **Radicale + DAVx⁵** — CalDAV/CardDAV minimalist
  - **Immich / PhotoPrism** — photos
  - **Actual Budget** / **ezBookkeeping** — money
  - **Vikunja** — todos
  - **HedgeDoc / Wiki.js** — notes + wiki
  - **Choose PMS if:** you want ONE hobby tool + accept the bus-factor + align with its LAN-only + solo-use intent.
  - **Choose Nextcloud + best-of-breed apps if:** you want production-grade personal cloud with depth per category.

## Links

- Backend repo: <https://github.com/Volmarg/personal-management-system>
- Frontend repo: <https://github.com/Volmarg/personal-management-system-front>
- Docs: <https://volmarg.github.io>
- Installation: <https://volmarg.github.io/docs/getting-started/installation.html>
- Demo: <http://personal-management-system.pl/>
- Tech stack: <https://volmarg.github.io/docs/technical/tech-stack.html>
- Vaultwarden (strong password-manager alt): <https://github.com/dani-garcia/vaultwarden>
- Nextcloud (integrated personal cloud alt): <https://nextcloud.com>
- Joplin (notes alt): <https://joplinapp.org>
- Obsidian (notes alt, commercial): <https://obsidian.md>
- Immich (photos alt): <https://immich.app>
- Actual Budget (finance alt): <https://actualbudget.org>
