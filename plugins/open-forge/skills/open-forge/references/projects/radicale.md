---
name: Radicale
description: "Small but powerful CalDAV (calendars, todos) + CardDAV (contacts) server — Python, file-system storage, works out-of-the-box, many clients supported. Minimal dependencies. GPLv3."
---

# Radicale

Radicale is **"the small, sharp CalDAV/CardDAV server that just works"** — a lightweight Python implementation of the standards that Apple/Nextcloud/Google calendar/contact clients speak. If you want to sync calendars + contacts between devices WITHOUT Google/Apple/Microsoft servers, Radicale is the most common minimalist answer in the self-host world.

Built by **Kozea** + contributors; **GPLv3**; runs as a simple Python process (uwsgi/gunicorn in production); **stores everything on the file system** in a plain directory structure, making backup trivial.

Features:

- **CalDAV** — events, todos, journals
- **CardDAV** — contacts (business cards / vcards)
- **HTTP** browsing
- **Authentication** (optional; multiple backends — htpasswd / LDAP / Remote user via forward-auth)
- **TLS** native OR via reverse proxy
- **Works with many clients** — Thunderbird, Apple Calendar/Contacts, iOS/macOS native, DAVx⁵ (Android), Evolution, Outlook (via plugins), Nextcloud tasks, Tasks.org, …
- **File-system storage** — one file per calendar item; one directory per collection. Plain vCard / iCalendar files.
- **Plugin-extensible** (auth, storage, rights, web interfaces)
- **Minimal dependencies** — pure Python
- **Works out-of-the-box** — "sensible defaults" design

- Upstream repo: <https://github.com/Kozea/Radicale>
- Homepage: <https://radicale.org>
- Master documentation: <https://radicale.org/master.html>
- Wiki: <https://github.com/Kozea/Radicale/wiki>
- Issues: <https://github.com/Kozea/Radicale/issues>
- Discussions: <https://github.com/Kozea/Radicale/discussions>
- Reporting Issues guide: <https://github.com/Kozea/Radicale/wiki/01-‐-Reporting-Issues>
- Python package: `pip install radicale`
- Docker (community): <https://hub.docker.com/r/tomsquest/docker-radicale/>

## Architecture in one minute

- **Python 3** — server + CLI
- **File system storage** — `~/.var/lib/radicale/collections/<user>/<collection>/<item>.ics`
- **HTTP server** built-in OR WSGI via uwsgi/gunicorn behind nginx
- **Auth backends**: `htpasswd`, `http_x_remote_user` (forward-auth), `ldap`, `none`
- **Resource**: tiny — 30-80 MB RAM per worker; scales per-user count
- **No DB** — backup = copy the directory

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM          | **`pip install radicale`** + systemd unit                          | **Upstream-primary**                                                               |
| Docker             | **Community `tomsquest/docker-radicale`** (well-maintained)                | Popular                                                                                    |
| Raspberry Pi       | Same as above — lightweight                                                           | Great home use                                                                                         |
| Shared hosting     | If Python + WSGI allowed                                                                           | Works                                                                                                  |
| Kubernetes         | Simple Python deploy + PV                                                                                    | Works                                                                                                  |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `dav.example.com`                                                  | URL          | TLS via reverse proxy STRONGLY recommended                                       |
| Storage dir          | `/var/lib/radicale/collections/`                                      | Storage      | Plain FS — back this up                                                                          |
| Auth backend         | `htpasswd` (simple) / LDAP / forward-auth                                          | Auth         | Default config has NO auth — MUST configure                                                                   |
| htpasswd file        | generated via `htpasswd -B -c /etc/radicale/users alice`                      | Auth         | bcrypt recommended                                                                                                 |
| TLS                  | Let's Encrypt via reverse proxy                                                                        | TLS          | Clients often reject self-signed                                                                                                    |

## Install via Docker

Using the well-maintained community image:
```yaml
services:
  radicale:
    image: tomsquest/docker-radicale:3.7.3.0          # pin version in prod
    container_name: radicale
    init: true
    read_only: true
    security_opt: [no-new-privileges:true]
    cap_drop: [ALL]
    cap_add: [CHOWN, SETUID, SETGID, KILL]
    deploy:
      resources:
        limits:
          memory: 256M
          pids: 50
    healthcheck:
      test: curl -f http://127.0.0.1:5232 || exit 1
    restart: unless-stopped
    volumes:
      - ./data:/data
      - ./config:/config:ro
    ports:
      - "5232:5232"
```

### Via pip (systemd)

```sh
pip install radicale passlib bcrypt
htpasswd -B -c /etc/radicale/users alice
# Edit /etc/radicale/config — set auth to htpasswd, point to users file, set storage path
# Systemd unit runs: python3 -m radicale --config /etc/radicale/config
```

## First boot

1. Generate htpasswd user: `htpasswd -B -c users alice`
2. Start Radicale
3. Browse `http://<host>:5232/` → login → "create collection" → name + type (addressbook / calendar)
4. Get collection URL (typically `http://<host>:5232/alice/cal1/`)
5. Add to client:
   - Apple Calendar: System Settings → Internet Accounts → Other → Add CalDAV → URL + user + pass
   - Thunderbird: new calendar → Network → CalDAV → URL
   - DAVx⁵ (Android): add account → URL + user/pass
6. Test bi-directional sync (add event on phone, see it on desktop)
7. Put behind TLS reverse proxy BEFORE using passwords over the internet
8. Enable forward-auth (Authelia/Authentik) if you want stronger authentication

## Data & config layout

- `/data/collections/<user>/<uuid>/` — per-collection dir
- Each event / contact = individual `.ics` or `.vcf` file (standard formats — can open in text editor)
- `/data/collections/<user>/<uuid>/.Radicale.props` — collection metadata
- `/config` — `radicale.conf` (server config)
- No DB; no caching layer; no indexes — everything is files

## Backup

```sh
sudo tar czf radicale-$(date +%F).tgz /var/lib/radicale/collections/
# Or git-version it:
cd /var/lib/radicale/collections && git add -A && git commit -m "snapshot $(date)"
```

Calendar + contacts data = sensitive. Encrypt backups.

## Upgrade

1. Releases: <https://github.com/Kozea/Radicale/releases>. Sustained but not frequent — mature stable software.
2. `pip install --upgrade radicale` OR `docker pull` + restart.
3. File format backward-compatible (vCard/iCal standards) — low upgrade risk.

## Gotchas

- **Default config has NO authentication.** On first run, Radicale accepts anyone. MUST configure auth (`htpasswd` minimum) BEFORE exposing to any network. Don't just run and hope.
- **TLS mandatory for real use.** Basic-auth credentials + calendar/contact data over cleartext HTTP = trivially snoopable. Put Radicale behind nginx/Caddy/Traefik with Let's Encrypt.
- **Clients can be picky about paths**: Apple Calendar, Thunderbird, DAVx⁵ all have slightly different URL conventions. Upstream docs + DAVx⁵ docs cover them. If client says "can't connect," walk through the URL structure carefully.
- **Apple CalDAV client** sometimes refuses self-signed certs entirely — use Let's Encrypt from day one, not self-signed.
- **Collection discovery**: some clients auto-discover via `.well-known/caldav` and `.well-known/carddav` — set up the redirect in your reverse proxy:
  ```
  location /.well-known/caldav { return 301 https://$host/radicale/; }
  location /.well-known/carddav { return 301 https://$host/radicale/; }
  ```
- **Rights model**: Radicale's `rights` config controls who can access whose collections. Default = per-user own collections only. Group/shared collections need explicit configuration.
- **No web UI beyond trivial** — create/delete collections is supported; rich calendar viewing = use a client. DON'T treat the Radicale web UI as an end-user product.
- **Push notifications (CalDAV-sync-intensive on iOS)** — Radicale is POLL-based. Clients poll periodically. No push notifications for new events (not an iCloud replacement). For heavy mobile use, poll interval tradeoff = battery vs freshness.
- **Scales to ~10s of users, 1000s of events per user** comfortably on modest hardware. Beyond that (enterprise-scale), look at EGroupware/Nextcloud for DB-backed + performance.
- **Git-versioning `collections/` dir** = free version history for calendars + contacts. Recover "I deleted an event three weeks ago" scenario with `git log`. Recommended pattern.
- **Sharing calendars across users** works via ACL/rights config but is non-trivial. Read upstream docs. For family-shared calendar: create a shared collection + give each user read-write rights.
- **iOS limitations**: iOS built-in CalDAV/CardDAV is functional but can be finicky. DAVx⁵ on Android is SIGNIFICANTLY more capable + user-friendly. Android users: install DAVx⁵.
- **Comparison to Nextcloud**: Nextcloud has CalDAV/CardDAV built-in BUT it's a much heavier app (DB + PHP + many features). If all you want is calendar/contacts sync, Radicale is 1/100 the complexity.
- **Comparison to Baikal**: similar scope (PHP-based CalDAV/CardDAV). If you prefer PHP stack, Baikal. If Python, Radicale.
- **Comparison to EGroupware / SOGo**: enterprise groupware with CalDAV/CardDAV built-in + webmail + more. Heavier.
- **Two-factor auth / WebAuthn**: Radicale doesn't natively support. Put behind forward-auth (Authelia, Authentik, Pocket ID batch earlier) for MFA.
- **License**: **GPLv3**.
- **Project health**: Kozea + community; mature; sustained. Not bus-factor-1.
- **Alternatives worth knowing:**
  - **Baikal** — PHP; similar scope
  - **Nextcloud** (Calendar + Contacts apps) — full groupware
  - **SOGo** — full groupware (GPL)
  - **EGroupware** — full groupware (GPL)
  - **Davis** — PHP-based Baikal-alt
  - **Apple iCloud / Google / Microsoft 365** — commercial SaaS; your calendar data lives there
  - **Choose Radicale if:** minimalist + Python + file-based + lightweight + CalDAV/CardDAV only.
  - **Choose Baikal if:** PHP stack preferred.
  - **Choose Nextcloud if:** want whole groupware, not just calendar.
  - **Choose DAVx⁵ + Radicale for Android** — best combo for Android sync.

## Links

- Repo: <https://github.com/Kozea/Radicale>
- Homepage: <https://radicale.org>
- Master docs: <https://radicale.org/master.html>
- Wiki: <https://github.com/Kozea/Radicale/wiki>
- Docker image (community): <https://github.com/tomsquest/docker-radicale>
- Docker Hub: <https://hub.docker.com/r/tomsquest/docker-radicale/>
- Discussions: <https://github.com/Kozea/Radicale/discussions>
- PyPI: <https://pypi.org/project/Radicale/>
- DAVx⁵ (Android client): <https://www.davx5.com>
- Baikal (alt): <https://sabre.io/baikal/>
- Nextcloud (alt): <https://nextcloud.com>
- iCalendar RFC: <https://tools.ietf.org/html/rfc5545>
- vCard RFC: <https://tools.ietf.org/html/rfc6350>
- CalDAV RFC: <https://tools.ietf.org/html/rfc4791>
- CardDAV RFC: <https://tools.ietf.org/html/rfc6352>
