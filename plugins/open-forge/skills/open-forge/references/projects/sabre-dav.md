---
name: sabre/dav
description: "Most popular WebDAV framework for PHP — create WebDAV, CalDAV, CardDAV servers. Powers Baikal, Nextcloud, ownCloud, many more. sabre-io/dav. sabre.io docs. Decade-plus lineage."
---

# sabre/dav

sabre/dav is **"THE WebDAV framework for PHP — upstream of Baikal, Nextcloud CalDAV/CardDAV"** — the most popular WebDAV framework for PHP. Used to build WebDAV, CalDAV, and CardDAV servers. **Not a server itself** — a library/framework. Powers Baikal (via sabre-io) and Nextcloud/ownCloud's CalDAV/CardDAV. Long branch-maintenance discipline (PHP version matrix explicit).

Built + maintained by **sabre-io** org. PHP 7.4+ / 8.0+ on master. Long version-support matrix (unmaintained branches clearly marked).

Use cases: (a) **build your own CalDAV/CardDAV server** (b) **embed WebDAV in existing PHP app** (c) **dependency for Baikal/Nextcloud** (d) **understand CalDAV protocol via reference impl** (e) **migrate legacy WebDAV to modern PHP** (f) **PHP WebDAV library for plugins** (g) **corporate directory CardDAV serving** (h) **calendar sync infrastructure**.

Features (per README):

- **WebDAV + CalDAV + CardDAV** server framework
- **PHP 7.4+ / 8.0+** (master)
- **Versioned branches** with clear maintenance status
- **Most popular PHP WebDAV framework**

- Upstream repo: <https://github.com/sabre-io/dav>
- Website: <https://sabre.io>
- Install docs: <https://sabre.io/dav/install/>

## Architecture in one minute

- **PHP library/framework** — not a standalone service
- Integrate into your own PHP server
- **Resource**: depends on app
- **Port**: HTTP (per your PHP front-end)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Composer**       | `composer require sabre/dav`                                                                                           | **Primary**                                                                                   |
| **Via Baikal**     | Baikal includes sabre/dav                                                                                              | Alt (most common way to "use" it)                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| PHP                  | 7.4+ / 8.0+                                                 | Runtime      | Branch-dependent                                                                                    |
| Composer             | Package manager                                             | Runtime      |                                                                                    |
| Backend              | SQLite/MySQL/Postgres/File                                  | DB           |                                                                                    |
| Auth                 | Basic/Digest/PDO                                            | Auth         |                                                                                    |

## Install

Per sabre.io/dav/install. Integrate via Composer into your PHP app:
```sh
composer require sabre/dav
```
Then configure server.php with a backend (SQL, File) + auth + principals + calendar/address-book entry points.

Or use **Baikal** (pre-built sabre-io distribution with admin UI).

## First boot

1. Compose-require sabre/dav
2. Write `server.php` entry point
3. Configure backend (DB or File)
4. Configure auth
5. Mount calendar/address-book endpoints
6. Test with CalDAV/CardDAV client (Thunderbird, iOS, Android)
7. Put behind TLS + auth

## Data & config layout

- Per your integration — DB tables for principals, events, address-book entries

## Backup

Per your integration — DB dump + config file.

## Upgrade

1. Branch-choice matters — master is PHP 7.4+
2. `composer update sabre/dav`
3. Review CHANGELOG for breaking changes

## Gotchas

- **198th HUB-OF-CREDENTIALS Tier 2 — DAV-FRAMEWORK-FOUNDATION**:
  - Holds: depends entirely on your integration — likely CalDAV/CardDAV user data + auth
  - **This is a library, not a service** — sensitivity depends on the integrating app
  - **198th tool in hub-of-credentials family — Tier 2**
- **LIBRARY-NOT-SERVICE**:
  - Recipe scope is different — no docker-compose here
  - **Recipe convention: "library-framework-not-standalone-service neutral-signal"**
  - **NEW neutral-signal convention** (sabre/dav 1st formally)
  - **Library-not-standalone-service: 1 tool** 🎯 **NEW FAMILY** (sabre/dav — unusual entry-type in this catalog of services)
- **UPSTREAM-OF-MANY-APPS**:
  - Baikal, Nextcloud, ownCloud, many more depend on sabre/dav
  - Supply-chain gravity = very high
  - **Recipe convention: "upstream-dependency-of-many-popular-apps positive-signal"**
  - **NEW positive-signal convention** (sabre/dav 1st formally)
- **EXPLICIT-BRANCH-MAINTENANCE-MATRIX**:
  - Clear table of maintained vs unmaintained versions
  - **Recipe convention: "explicit-maintenance-status-matrix-per-branch positive-signal"**
  - **NEW positive-signal convention** (sabre/dav 1st formally; responsible discipline)
- **DECADE-PLUS-OSS**:
  - sabre/dav is very old (pre-2010)
  - **Decade-plus-OSS: 17 tools** 🎯 **17-MILESTONE** (+sabre/dav)
- **TWO-DECADE-PLUS-OSS**:
  - sabre.io approaching or past 15-20 years
  - **Two-decade-plus-OSS: 2 tools** (Review Board+sabre/dav) 🎯 **2-MILESTONE**
- **DAV-PROTOCOL-COMPLIANCE**:
  - Standard-protocol implementation
  - **Recipe convention: "standard-protocol-broad-client-ecosystem"** reinforces Wolf, Maloja, Movim
- **COMPOSER-PHP-PACKAGE-MANAGEMENT**:
  - **Composer-PHP-distribution: 1 tool** 🎯 **NEW FAMILY** (sabre/dav — distinct from npm/PyPI/gem)
- **INSTITUTIONAL-STEWARDSHIP**: sabre-io org + 15+ years + explicit-maintenance-matrix + upstream-of-ecosystem + docs-site + active. **184th tool — protocol-framework-foundation sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + explicit-version-matrix + docs + CI. **190th tool in transparent-maintenance family** 🎯 **190-TOOL TRANSPARENT-MAINTENANCE MILESTONE at sabre/dav**.
- **DAV-FRAMEWORK-CATEGORY:**
  - **sabre/dav** — PHP; dominant
  - **python-caldav / caldav.js** — client libraries (different role)
  - **DAViCal** — PHP; older; standalone server
  - **Baikal** — uses sabre/dav; pre-built
- **ALTERNATIVES WORTH KNOWING:**
  - **Baikal** — if you just want a server
  - **Radicale** — if you want Python + self-contained
  - **Choose sabre/dav if:** you're building your own PHP DAV server/plugin.
- **PROJECT HEALTH**: 15+ years active + ecosystem-gravity + version-matrix. Exceptional.

## Links

- Repo: <https://github.com/sabre-io/dav>
- Website: <https://sabre.io>
- Baikal (pre-built): <https://github.com/sabre-io/Baikal>
- Radicale (alt): <https://github.com/Kozea/Radicale>
