---
name: Cypht
description: "Lightweight, open-source, multi-account webmail + news reader. PHP. Docker. cypht-org/cypht. IMAP + JMAP + EWS + RSS/Atom. Combined views, module-based architecture, no database required (optional)."
---

# Cypht

**Lightweight, module-based, multi-account webmail and news reader.** Combines all your email accounts (IMAP/SMTP, JMAP, EWS/Exchange) and RSS/Atom feeds into a single unified interface. Think "news reader, but for email." Does not replace your existing mail servers — it's a unified client that proxies them. Entirely built from plugins ("module sets"). No database required by default (flat-file session); SQLite/MySQL/Postgres optional.

Built + maintained by **Jason Munro** and the Cypht community.

- Upstream repo: <https://github.com/cypht-org/cypht>
- Website + docs: <https://cypht.org>
- Install guide: <https://cypht.org/install>
- Modules: <https://cypht.org/modules>
- Features: <https://cypht.org/features>
- Docker Hub: <https://hub.docker.com/r/cypht/cypht>
- Gitter community: <https://gitter.im/cypht-org/community>

## Architecture in one minute

- **PHP** (7.2+; 8.x supported) application
- **No database required** by default — PHP sessions + flat-file config
- Optional: SQLite / MySQL / PostgreSQL for user data persistence + multi-user
- Port: standard HTTP (80 inside Docker; map to your choice)
- Module-based: every feature (IMAP, JMAP, EWS, 2FA, PGP, GitHub, LDAP, NNTP, Mailchimp...) is an optional module
- Resource: **low** — PHP-FPM, no heavy backend

## Compatible install methods

| Infra         | Runtime                  | Notes                                                                    |
| ------------- | ------------------------ | ------------------------------------------------------------------------ |
| **Docker**    | `cypht/cypht`            | **Easiest** — Docker Hub                                                 |
| **PHP webserver** | bare PHP            | Apache or nginx + PHP-FPM; see cypht.org/install                        |
| **Composer**  | `jason-munro/cypht`      | For PHP developers embedding Cypht                                       |

## Inputs to collect

| Input                        | Example                          | Phase    | Notes                                                                                  |
| ---------------------------- | -------------------------------- | -------- | -------------------------------------------------------------------------------------- |
| Domain                       | `mail.example.com`               | URL      | Reverse proxy + TLS                                                                    |
| Config dir                   | `./cypht-config`                 | Storage  | Mount as `/var/lib/hm3/` (or as configured in `hm3.rc`)                               |
| IMAP/SMTP servers            | `imap.example.com:993`           | Config   | Added per-user in the web UI; no server-side pre-config required                      |
| DB (optional)                | SQLite or MySQL/PG creds         | Storage  | Required only for multi-user + persistent user data; default = flat-file sessions     |
| Admin password               | strong password                  | Auth     | Set in `hm3.rc` config file (`admin_users` or session auth)                           |

## Install via Docker

```bash
docker run -d \
  --name cypht \
  -p 8025:80 \
  -v ./cypht-config:/var/lib/hm3 \
  --restart unless-stopped \
  cypht/cypht:latest
```

Visit `http://<host>:8025`.

## Install via Docker Compose

```yaml
services:
  cypht:
    image: cypht/cypht:latest
    container_name: cypht
    ports:
      - "8025:80"
    volumes:
      - ./cypht-config:/var/lib/hm3
    restart: unless-stopped
```

For multi-user with database persistence, add MySQL/SQLite and configure `hm3.rc` accordingly. See full install guide: <https://cypht.org/install>

## Configuration (`hm3.rc`)

Cypht is configured via `hm3.rc` (INI-format). Key settings:

```ini
[user_settings]
user_settings_dir   = /var/lib/hm3/users/
user_settings_type  = file   # or sqlite, mysql, pgsql

[session_settings]
session_type        = PHP    # or DB

[allowed_output_pages]
; ... 

[modules]
enabled_modules     = imap,smtp,feeds,2fa,pgp,accounts,...
```

Full config reference: <https://cypht.org/install> (Config File section).

## First boot

1. Deploy container.
2. Create/edit `hm3.rc` in the config volume.
3. Visit the web UI → log in (default admin or create user per install guide).
4. Add IMAP accounts (Settings → Add Email Account).
5. Add RSS/Atom feeds (Settings → Add Feed).
6. Enable modules you need (admin panel → Modules or via `hm3.rc`).
7. Configure SMTP for sending.
8. Put behind TLS.

## Available modules (highlights)

| Module       | Adds |
|-------------|------|
| `imap`       | IMAP account support |
| `smtp`       | SMTP sending |
| `feeds`      | RSS/Atom news reader |
| `2fa`        | TOTP two-factor authentication |
| `pgp`        | PGP message encryption/decryption |
| `github`     | GitHub notifications feed |
| `ldap`       | LDAP address book |
| `nntp`       | NNTP newsgroups |
| `themes`     | Visual theme switching |
| `contacts`   | CardDAV contacts |
| `calendar`   | CalDAV calendar |

Full module list: <https://cypht.org/modules>

## Backup

```sh
docker compose stop cypht
sudo tar czf cypht-$(date +%F).tgz cypht-config/
docker compose start cypht
```

Contents: IMAP credentials + user settings. Sensitive — IMAP passwords stored here. Keep encrypted.

## Upgrade

1. `docker pull cypht/cypht:latest && docker compose up -d`
2. Review changelog at <https://github.com/cypht-org/cypht/releases>

## Gotchas

- **No database by default = no persistence across sessions on multi-user setups.** Flat-file sessions work for single-user personal installs. For a shared instance where multiple users keep accounts between visits, configure SQLite or MySQL/PostgreSQL in `hm3.rc`.
- **IMAP server-side proxy model.** Cypht connects to IMAP from the server, not the browser. Outbound IMAP access must be allowed from the host. IMAP credentials are stored server-side — treat the config volume as sensitive.
- **Module configuration in `hm3.rc`.** Enabling/disabling features requires editing the INI file and restarting. The web admin panel provides some control but not all modules are toggle-able live.
- **Combined view is the killer feature.** The "Everything" inbox combines all accounts + feeds into a unified timeline — great for inbox-zero workflows across many accounts. This is the core differentiator vs. clients that show accounts in silos.
- **JMAP support.** JMAP is the modern successor to IMAP (RFC 8620). Fastmail uses JMAP; Cypht is one of few open-source clients with JMAP support.
- **EWS (Exchange Web Services).** For corporate Exchange / Microsoft 365 accounts that don't allow IMAP access. Requires the `ews` module.
- **2FA is TOTP (app-based).** Requires the `2fa` module. No SMS fallback.
- **Monthly community meetings** — see the GitHub wiki. Active community stewardship.
- **Security page.** Cypht has a dedicated security section: <https://cypht.org/security>. The project has undergone audits — good sign for a credential-handling app.

## Project health

CII Best Practices badge, monthly community meetings, Docker Hub, Composer package, active GitHub. Maintained by Jason Munro + community. Long-running project (originally "hm3").

## Webmail-family comparison

- **Cypht** — PHP, no-DB default, module-based, combined multi-account view, RSS+email hybrid, JMAP/EWS
- **SnappyMail** — PHP, no-DB, fast, clean UI, RainLoop fork, IMAP-only
- **Roundcube** — PHP, MySQL/PG, mature, rich plugins, standard IMAP webmail
- **Sogo** — CalDAV + CardDAV + webmail groupware; heavy
- **Bichon** — archive-only (no live reading or sending)

**Choose Cypht if:** you want a unified inbox across many email accounts + RSS feeds with module-based extensibility, JMAP/EWS support, and minimal server requirements.

## Links

- Repo: <https://github.com/cypht-org/cypht>
- Website: <https://cypht.org>
- Install: <https://cypht.org/install>
- Modules: <https://cypht.org/modules>
- Docker Hub: <https://hub.docker.com/r/cypht/cypht>
- SnappyMail (simpler webmail alt): <https://snappymail.eu>
