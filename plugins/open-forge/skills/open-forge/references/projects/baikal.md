---
name: Baikal
description: "CalDAV + CardDAV server built on SabreDAV. PHP. Minimal, mature, focused. Works with Thunderbird/DAVx5/iOS/macOS/Evolution/Gnome. GPL-2.0. Built by Jérôme Schneider + fruux; now community-maintained via sabre-io. The stable answer to \"self-host calendar + contacts\"."
---

# Baikal

Baikal is **"the minimal, boring, mature CalDAV + CardDAV server"** — a self-hosted calendar + contacts server built on top of the **SabreDAV library** (the widely-used PHP CalDAV/CardDAV implementation that also powers Nextcloud's calendar). Runs on PHP + SQLite or MySQL. Designed to JUST work: install, point your Thunderbird / iOS / Android / Evolution / DAVx5 / Apple Calendar / macOS Contacts at it, and you're done. No social features, no chat, no cloud — just calendar + contacts.

Built by **Jérôme Schneider** (Net Gusto) + **fruux GmbH**; now developed by community volunteers under **sabre-io** org. **License: GPL-2.0**. Mature (15+ year project); actively maintained as of recent releases; minimalist philosophy unchanged.

Use cases: (a) **escape Google Calendar / iCloud / Microsoft Exchange** for personal calendar/contacts (b) **self-hosted family calendar** — shared between household members (c) **privacy-focused professional calendar** — no cloud provider reads your schedule (d) **calendar backend for other tools** — some other tools use CalDAV; Baikal is the backend they need (e) **DAVx5 (Android) users** often pair with Baikal for a clean self-host (f) **Thunderbird + Baikal** = classic desktop email/calendar/contacts self-host trio (g) **Raspberry Pi home server** sweet spot — Baikal is light enough for Pi Zero.

Features (from upstream README + sabre.io docs):

- **CalDAV** server (calendar sync protocol)
- **CardDAV** server (contact sync protocol)
- **WebDAV** base
- **Multi-user** with permissions
- **iCal feed** for public sharing
- **Subscription support** (read-only shared calendars)
- **Minimal web UI** for user/calendar/addressbook admin
- **MySQL + SQLite** backends
- **PHP 7.4+** / **PHP 8**

- Upstream repo: <https://github.com/sabre-io/Baikal>
- Homepage / docs: <https://sabre.io/baikal/>
- Install: <https://sabre.io/baikal/install/>
- Upgrade: <https://sabre.io/baikal/upgrade/>
- SabreDAV library: <https://sabre.io>
- German community guide: <https://github.com/JsBergbau/BaikalAnleitung>
- French community guide: <https://github.com/criticalsool/Baikal-Guide-FR>

## Architecture in one minute

- **PHP 7.4+/8** (web app)
- **SQLite** or **MySQL/MariaDB** — DB
- **Resource**: tiny — 50-150MB RAM; runs fine on Pi Zero
- **Port 80/443** behind any PHP webserver (Apache, nginx+php-fpm, Caddy+php-fpm)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Tarball + PHP** | **Download release tarball + extract into webroot**             | **Upstream-primary**                                                               |
| **Docker (community)** | `ckulka/baikal` or `stieglitz/baikal` — popular community      | **Not upstream-official but widely used**                                                                                   |
| Bare-metal PHP     | Copy tarball + configure Apache/nginx+php-fpm                                                 | DIY                                                                                               |
| Managed fruux      | Original authors' commercial service (adjacent, not Baikal-hosted)                                                                                    | Commercial alt                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `dav.example.com`                                           | URL          | TLS MANDATORY (CalDAV passwords are plaintext over HTTPS)                                                                                    |
| DB                   | SQLite or MySQL                                             | DB           | SQLite fine for <100 users                                                                                    |
| Admin password       | First-boot setup wizard                                                                           | Bootstrap    | Strong                                                                                    |
| `/var/www/baikal/Specific` | Config dir (gets created)                                                                                | Config       | DB + user settings stored here                                                                                    |
| PHP + Apache/nginx   | Standard LAMP/LEMP stack                                                                                  | Webserver    | Standard PHP deployment                                                                                                            |

## Install via Docker (community image)

```yaml
services:
  baikal:
    image: ckulka/baikal:0.11.1-nginx    # **pin specific version**; note: community image
    container_name: baikal
    restart: unless-stopped
    ports: ["8081:80"]
    volumes:
      - ./baikal-config:/var/www/baikal/config
      - ./baikal-data:/var/www/baikal/Specific
```

For upstream-official setup: download release tarball from <https://github.com/sabre-io/Baikal/releases>, extract into webroot, configure Apache/nginx, browse to `install/` for setup wizard.

## First boot

1. Browse `/install/` → run setup wizard
2. Choose DB (SQLite easiest)
3. Set admin password
4. Create first user in admin UI
5. Create a calendar + addressbook for that user
6. CalDAV/CardDAV URL for clients: `https://dav.example.com/dav.php/principals/<username>/`
7. Configure Thunderbird / DAVx5 / iOS:
   - **Thunderbird**: Calendar → New Calendar → On the Network → CalDAV
   - **iOS**: Settings → Accounts → Add Account → Other → Add CalDAV account
   - **DAVx5 (Android)**: add CalDAV + CardDAV credentials
8. Put behind TLS reverse proxy — MANDATORY
9. Back up DB + `Specific/` directory

## Data & config layout

- `Specific/` — database + per-user DAV data (SQLite files, etc.)
- `config/` — config.yaml-style files (baikal.yaml + system.yaml)
- Behind webroot — secure against direct access to `Specific/`

## Backup

```sh
# Ideally stop briefly for consistency
sudo tar czf baikal-$(date +%F).tgz baikal-config/ baikal-data/
# MySQL: mysqldump
```

## Upgrade

1. Releases: <https://github.com/sabre-io/Baikal/releases>. Moderate cadence; semver.
2. **Read upgrade instructions carefully** at <https://sabre.io/baikal/upgrade/> — Baikal upgrade has specific steps for DB migrations
3. Tarball: replace files (keep Specific/ + config/); upgrade wizard may run on first access
4. Docker community: pull + restart
5. Back up BEFORE major upgrades

## Gotchas

- **CALDAV / CARDDAV ARE TEXTUAL PROTOCOLS WITH CLIENT-SPECIFIC QUIRKS**:
  - **iOS quirks**: iOS sometimes expects very specific path patterns; test with a real iPhone before rolling out
  - **Android DAVx5 quirks**: works well; most widely-used Android CalDAV client
  - **Thunderbird quirks**: Lightning + TbSync + CalDAV/CardDAV add-ons have historical interop issues
  - **Apple Calendar / Contacts on macOS**: generally works; watch for push notifications
  - **Exchange clients** expecting Exchange ActiveSync: will NOT work (different protocol); need z-push if you want EAS compatibility
- **TLS IS NON-NEGOTIABLE**: CalDAV/CardDAV clients authenticate with passwords sent in HTTP headers. Without TLS, passwords are plaintext. Never expose Baikal without HTTPS. Use Let's Encrypt via reverse proxy.
- **HUB-OF-CREDENTIALS TIER 2 with PERSONAL-DATA-DENSITY**:
  - All users' calendar events (with private events, medical appointments, gym visits, meetings)
  - All users' contact data (phone, email, addresses, birthdays, notes)
  - Passwords + auth tokens
  - **54th tool in hub-of-credentials family — Tier 2** with **PII-density warning** (calendar + contacts combined reveal full social graph + schedule)
- **CALENDAR + CONTACTS = LIFELOG-ADJACENT**: Baikal's dataset overlaps with Ryot's LIFELOG sub-family (batch 95). Not quite LIFELOG-level (no fitness/reading), but significant. Treat with respect: encrypted backups, limited access, audit logs.
- **MULTI-USER PERMISSIONS**: Baikal's calendar sharing is CalDAV-native; shared calendars appear in clients' calendar lists. Family sharing works naturally. **DV-threat-model applies** (SparkyFitness 94, Ryot 95, KitchenOwl 96) — shared household calendar can reveal sensitive info; ensure access-removal flow works.
- **PHP STACK CONSIDERATIONS**: PHP is mature, widely-understood, but requires keeping PHP + Apache/nginx + dependencies up-to-date for security. Use a minor-version-lock (PHP 8.x) + keep the distro package stream fresh.
- **BACKUP FREQUENCY MATTERS**: calendar + contacts change daily; backup daily. Losing a week of data = real pain (missed appointments, lost contacts).
- **SHARED-CALENDAR FEATURE works but has quirks**: read-write sharing works on most clients; some older clients are read-only even on writable shares. Test per client.
- **PHP SESSION + CSRF** security: Baikal is stateful PHP with standard session handling. Keep PHP security headers configured at reverse proxy level.
- **SOLE-MAINTAINER → COMMUNITY-VOLUNTEER-RUN**: original authors (Jérôme Schneider + fruux) no longer actively developing; community volunteers (sabre-io org) maintain. **30th tool in institutional-stewardship — "community-steward-of-legacy-tool" sub-tier** (4th tool in this sub-tier, joining ddclient 93 + others). Slow cadence but stable + functional.
- **TRANSPARENT-MAINTENANCE**: GPL-2 + 15-year history + semver + community-steward + CI badge + Weblate-translations (via tr.opengist.io — actually opengist's, not Baikal's) + docs. **36th tool in transparent-maintenance family.**
- **GPL-2.0** — copyleft; modifications must share code if distributed. Fine for self-host.
- **SABRE-IO LIBRARY ECOSYSTEM = UNDERLYING VALUE**: Baikal is a thin web wrapper over SabreDAV. SabreDAV is ALSO used by Nextcloud's calendar/contacts apps. Knowing SabreDAV runs both tools = same core-code reliability.
- **INTEGRATION WITH NEXTCLOUD**: if running Nextcloud, use Nextcloud's calendar/contacts (same SabreDAV under the hood). Baikal is for "don't want Nextcloud; just calendar/contacts".
- **FOCUS-IS-FEATURE narrative**: Baikal does CalDAV/CardDAV well, nothing else. In a homelab ecosystem of over-featured tools, this narrow-focus is a virtue. **Recipe convention: "focus-is-feature" framing** — narrow-scope tools that do one thing excellently.
- **ICAL SUBSCRIPTIONS = PUBLIC-SHARE-FOR-SOME-USES**: Baikal supports iCal feeds (public URL → anyone with URL can subscribe). Useful for "team schedule", "public events", etc. Don't enable for private calendars.
- **ALTERNATIVES WORTH KNOWING:**
  - **Radicale** — Python; minimalist; very-easy-setup; good for small-scale
  - **DAVical** — PHP; older; more-enterprise-y
  - **SOGo** — Groupware: CalDAV + CardDAV + webmail + more; heavier
  - **Nextcloud Calendar + Contacts** — if you want the full cloud suite + SabreDAV under the hood
  - **CalendarServer (Darwin CalendarServer)** — Apple's reference; Python; complex
  - **Kolab** — enterprise groupware
  - **Google Calendar / iCloud / Exchange** — commercial SaaS alternatives
  - **Choose Baikal if:** you want PHP + minimal + stable + focused on calendar/contacts only.
  - **Choose Radicale if:** you want Python + even-more-minimal + pure-standards-focus.
  - **Choose Nextcloud if:** you want calendar + contacts + files + chat + etc. in one.
  - **Choose SOGo if:** you want a groupware suite (webmail + etc.).
- **PROJECT HEALTH**: community-steward phase; stable; slow-cadence. Low-excitement + high-reliability tool. Exactly what you want for calendar/contacts.

## Links

- Repo: <https://github.com/sabre-io/Baikal>
- Homepage: <https://sabre.io/baikal/>
- Install: <https://sabre.io/baikal/install/>
- Upgrade: <https://sabre.io/baikal/upgrade/>
- SabreDAV: <https://sabre.io>
- fruux (original co-authors): <https://fruux.com>
- DAVx5 (Android CalDAV/CardDAV client): <https://www.davx5.com>
- Thunderbird: <https://www.thunderbird.net>
- Radicale (alt): <https://radicale.org>
- SOGo (alt groupware): <https://sogo.nu>
- Nextcloud Calendar (alt): <https://apps.nextcloud.com/apps/calendar>
