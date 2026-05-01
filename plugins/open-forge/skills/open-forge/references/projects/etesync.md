---
name: EteSync / Etebase
description: "Etebase (EteSync 2.0) server — end-to-end-encrypted syncing for contacts, calendars, tasks, and notes. Client-side crypto. Python/Django. etesync/server. etebase.com. IRC + Matrix."
---

# EteSync / Etebase

Etebase (EteSync 2.0) is **"CalDAV/CardDAV but end-to-end encrypted, at the protocol layer"** — a server for **E2E-encrypted syncing** of contacts, calendars, tasks, and notes. Server sees only ciphertext; keys stay with clients. Python/Django.

Built + maintained by **etesync** org. Python 3.7+. IRC + Matrix community. Django-based — editable settings. Etebase SDK for clients (EteSync apps on iOS/Android/desktop). ClientConnections to CalDAV/CardDAV bridge.

Use cases: (a) **E2E-encrypted contacts + calendar sync** (b) **privacy-first alternative to iCloud/Google Sync** (c) **secure family/team contact sharing** (d) **E2E notes sync** (e) **zero-knowledge-architecture PIM sync** (f) **self-hosted alternative to EteSync.com SaaS** (g) **CalDAV/CardDAV bridge for encrypted data** (h) **tamper-evident personal data vault**.

Features (per README):

- **Etebase / EteSync 2.0** server
- **E2E encryption** — server holds ciphertext only
- **Contacts + calendars + tasks + notes**
- **Python 3.7+**
- **Django** settings editable
- **Client SDK** (Etebase libraries)
- **Bridge to CalDAV/CardDAV**
- **Multi-community** (IRC + Matrix)

- Upstream repo: <https://github.com/etesync/server>
- Website: <https://www.etebase.com>
- Community chat: <https://www.etebase.com/community-chat/>

## Architecture in one minute

- **Python 3.7+ / Django**
- SQLite default (Postgres supported)
- **Server-side**: only sees ciphertext
- **Client-side**: all crypto
- **Resource**: low
- **Port**: HTTP (put behind TLS)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Native Python**  | virtualenv + pip                                                                                                       | **Primary**                                                                                   |
| **Docker**         | Community images                                                                                                       | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `etesync.example.com`                                       | URL          | **TLS MANDATORY**                                                                                    |
| Python 3.7+          | System                                                      | Runtime      |                                                                                    |
| Django config        | `etebase_server/settings.py`                                | Config       | Secret key, DB, allowed hosts                                                                                    |
| Client apps          | Per-device                                                  | Clients      | Etebase apps for iOS/Android/desktop                                                                                    |

## Install

Per README:
```sh
git clone https://github.com/etesync/server.git etebase
cd etebase
virtualenv -p python3 .venv
source .venv/bin/activate
pip install -r requirements.txt
# Edit etebase_server/settings.py
./manage.py migrate
./manage.py runserver  # or gunicorn / uwsgi
```

## First boot

1. Clone + set up virtualenv
2. Edit Django settings (SECRET_KEY, ALLOWED_HOSTS, DB)
3. Run migrations
4. Front with gunicorn/uwsgi + nginx + TLS
5. Create Django superuser
6. Install Etebase client on iOS/Android/desktop
7. **Register account via client** (generates crypto keys)
8. Sync contacts/calendar/tasks/notes
9. **Back up encryption-keys client-side** (lost key = lost data — E2E feature)
10. Back up server-side data (ciphertext-only)

## Data & config layout

- Django DB — users + encrypted blobs (ciphertext)
- `/settings.py` — SECRET_KEY, DB config

## Backup

```sh
# Server-side backup = ciphertext only (safe)
# Client-side keys = the actual trust root
# Users responsible for their own key backup
```

## Upgrade

1. Releases: <https://github.com/etesync/server/releases>
2. Update source + requirements + migrations
3. Watch for crypto-protocol changes

## Gotchas

- **190th HUB-OF-CREDENTIALS Tier 2 — CIPHERTEXT-PIM-SYNC** (tier downgraded because E2E means server holds ciphertext only):
  - Holds: E2E-encrypted contacts + calendars + tasks + notes (server can't read), account metadata, SECRET_KEY
  - **190-TOOL HUB-OF-CREDENTIALS MILESTONE at Etebase**
  - **CROWN-JEWEL Tier 1 sub-cat previously existed** — "E2E-encrypted-PIM sync" could be considered for MATURATION if another qualifies
- **TRUE-E2E-ENCRYPTION-SERVER-CIPHERTEXT-ONLY**:
  - Server CANNOT read user data
  - **Recipe convention: "true-E2E-server-cannot-read-user-data highest-positive-signal"**
  - **NEW positive-signal convention** (Etebase 1st formally as dedicated-E2E-PIM-server)
  - **True-E2E-encryption-at-rest: 4 tools** (Chitchatter+Enclosed+PsiTransfer+Etebase) 🎯 **4-TOOL MILESTONE**
- **LOST-KEY-LOST-DATA**:
  - E2E feature: no password recovery
  - **Recipe convention: "E2E-key-loss-no-recovery-by-design-discipline callout"**
  - **NEW recipe convention** (Etebase 1st formally; HIGHEST-severity — emphasize client-side key backup)
- **IRC-PLUS-MATRIX-COMMUNITY**:
  - Both IRC and Matrix (bridged)
  - **Multi-community-channel-presence: 6 tools** 🎯 **6-TOOL MILESTONE** (+Etebase)
  - **Matrix-chat-community: 4 tools** (+Etebase) 🎯 **4-TOOL MILESTONE**
  - **IRC-community-channel: 1 tool** 🎯 **NEW FAMILY** (Etebase — distinct from Slack/Discord/Matrix)
- **DJANGO-SETTINGS-PY-EDITABLE**:
  - Classic Django config pattern
  - **Recipe convention: "Django-settings-py-direct-edit-pattern neutral-signal"**
  - **NEW neutral-signal convention** (Etebase 1st formally)
- **SECRET-KEY-REQUIRED**:
  - Django SECRET_KEY must be rotated from default
  - **Recipe convention: "Django-SECRET_KEY-production-rotation-mandatory callout"**
  - **NEW recipe convention** (Etebase 1st formally)
- **DECADE-PLUS-OSS**:
  - EteSync has long lineage
  - **Decade-plus-OSS: 15 tools** (+Etebase) 🎯 **15-TOOL MILESTONE**
- **ZERO-KNOWLEDGE-ARCHITECTURE**:
  - **Recipe convention: "zero-knowledge-architecture-server positive-signal"**
  - **NEW positive-signal convention** (Etebase 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: etesync org + website + community-chat + client SDKs + Django + active + decade-plus + E2E-architecture. **176th tool — cryptography-PIM-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + releases + docs + multi-community + website + client-ecosystem. **182nd tool in transparent-maintenance family.**
- **E2E-PIM-SYNC-CATEGORY:**
  - **Etebase** — E2E-encrypted; all 4 types (contacts/cal/tasks/notes)
  - **Baikal / Radicale** — CalDAV/CardDAV (no E2E)
  - **Nextcloud** — CalDAV/CardDAV + app ecosystem (no native E2E for PIM)
  - **Proton Mail/Calendar** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Baikal/Radicale** — if you want simple CalDAV (no E2E)
  - **Nextcloud** — if you want everything + app store
  - **Choose Etebase if:** you want true-E2E + zero-knowledge + all-PIM-types.
- **PROJECT HEALTH**: mature + active + client SDKs + multi-community + decade-plus. Strong.

## Links

- Repo: <https://github.com/etesync/server>
- Website: <https://www.etebase.com>
- Baikal (alt): <https://github.com/sabre-io/Baikal>
- Radicale (alt): <https://github.com/Kozea/Radicale>
