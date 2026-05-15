---
name: SnappyMail
description: "Simple, modern, lightweight & fast web-based email client. PHP. Docker. the-djmaze/snappymail. AGPL fork of RainLoop. No database required."
---

# SnappyMail

**Simple, modern, lightweight & fast web-based email client.** A heavily upgraded and secured fork of RainLoop Webmail Community edition. No database required — config stored in flat files. PHP 7.4+. Privacy-friendly (no Gravatar, Google, Facebook, Twitter, DropBox analytics). Dark mode. AGPL 3.0.

Built + maintained by **the-djmaze**. Replaces RainLoop (which is unmaintained).

- Upstream repo: <https://github.com/the-djmaze/snappymail>
- Website + docs: <https://snappymail.eu>
- Docker Hub: <https://hub.docker.com/r/djmaze/snappymail>
- Wiki (install instructions): <https://github.com/the-djmaze/snappymail/wiki/Installation-instructions>

## Architecture in one minute

- **PHP** app (7.4+ required; 8.x recommended)
- **No database** — flat-file config + per-user data in a `data/` dir
- Port **8888** (Docker default) — serves web UI
- IMAP + SMTP connections are made from the PHP server outbound (server-side proxy mode, not client-direct)
- Resource: **low** — PHP-FPM, flat files
- Multi-arch Docker images: `linux/amd64`, `linux/arm64`, `linux/arm/v7`

## Compatible install methods

| Infra         | Runtime                         | Notes                                                                                  |
| ------------- | ------------------------------- | -------------------------------------------------------------------------------------- |
| **Docker**    | `djmaze/snappymail`             | **Recommended** — Docker Hub + GHCR                                                    |
| **PHP webserver** | Manual / shared hosting     | Unzip release tarball into webroot; see wiki                                           |

## Inputs to collect

| Input                        | Example                          | Phase    | Notes                                                                                            |
| ---------------------------- | -------------------------------- | -------- | ------------------------------------------------------------------------------------------------ |
| Domain                       | `mail.example.com`               | URL      | Reverse proxy + TLS                                                                              |
| IMAP/SMTP server(s)          | `imap.gmail.com`, `smtp.gmail.com` | Config | Configured per-domain in admin panel or pre-configured via config file                          |
| Admin password               | strong password                  | Auth     | Set via `?admin` URL path or env var on first run                                                |
| Data dir                     | `./snappymail-data`              | Storage  | Flat-file user data + config; mount as volume                                                    |

## Install via Docker

```yaml
services:
  snappymail:
    image: djmaze/snappymail:v2.38.2
    container_name: snappymail
    ports:
      - "8888:8888"
    volumes:
      - ./snappymail-data:/var/lib/snappymail
    restart: unless-stopped
```

```sh
docker compose up -d
```

Visit `http://<host>:8888`.

## First boot

1. Deploy container.
2. Visit `http://<host>:8888/?admin` to access the admin panel.
3. Set the admin password (prompted on first visit).
4. Configure **mail domains** (IMAP/SMTP servers, ports, SSL/TLS settings) in admin → Domains.
5. Configure **plugins** (ChangePassword, PGP, 2FA, etc.) in admin → Plugins.
6. Log in with an email account on the main interface.
7. Put behind TLS (required for secure mail handling in production).
8. Back up `./snappymail-data/`.

## Data & config layout

- `/var/lib/snappymail/` — all data:
  - `_data_/_default_/configs/` — global config + domain configs
  - `_data_/_default_/logs/` — access + error logs
  - `_data_/_default_/storage/` — per-user data (identities, signatures, settings)
  - `_data_/_default_/plugins/` — installed plugins

## Backup

```sh
docker compose stop snappymail
sudo tar czf snappymail-$(date +%F).tgz snappymail-data/
docker compose start snappymail
```

Contents: email account credentials (stored as config), user settings, signatures. No email bodies — those stay on the IMAP server. Still sensitive (IMAP passwords).

## Upgrade

1. Releases: <https://github.com/the-djmaze/snappymail/releases>
2. `docker compose pull && docker compose up -d`
3. Visit `/?admin` after upgrade — upgrade script runs automatically on first request if needed.

## Gotchas

- **No database by design.** Config is flat-file. Simplifies install but means no search index, no mail stored server-side beyond session cache. SnappyMail is a proxy/client — all email lives on your IMAP server.
- **Admin panel is at `/?admin`** — not a separate port or path like `/admin`. Protect this URL (IP restrict in nginx/Caddy, or use the `SNAPPYMAIL_ADMIN_PASSWORD` env to pre-set it). Leaving it open on a public instance is a security issue.
- **Server-side IMAP proxy.** SnappyMail connects to IMAP/SMTP _from the server_, not directly from the user's browser. This means: (a) the server needs outbound IMAP/SMTP access, (b) the server needs to trust the IMAP server's TLS cert, (c) IMAP credentials are stored (encrypted) in the data dir.
- **PHP 7.4+ required; PHP 8.x preferred.** The project explicitly dropped backward compat with PHP 5/7.3 and older. Docker image bundles the right PHP; bare-metal installs must verify.
- **Fail2ban support.** Auth failures are written to syslog. Upstream provides Fail2ban instructions in the wiki — essential for any public-facing instance.
- **AGPL 3.0.** Serving a modified SnappyMail over a network requires publishing the modified source.
- **Plugin system.** Many features (ChangePassword, PGP, 2FA, additional IMAP providers) are shipped as plugins — enable them in admin → Plugins. Vanilla install is intentionally minimal.
- **RainLoop migration.** SnappyMail is a drop-in upgrade from RainLoop — copy your RainLoop data dir over; most settings transfer. RainLoop is effectively unmaintained; migration is the right call.
- **Privacy-first.** No Gravatar lookups, no Google/Facebook/Twitter/DropBox integrations, no X-Mailer headers. Ideal for privacy-conscious personal/small-org mail deployments.

## Project health

Active development, Docker CI (GitHub Actions), multi-arch images, plugin ecosystem, Fail2ban support, AGPL. Maintained by the-djmaze.

## Webmail-family comparison

- **SnappyMail** — PHP, no-DB, lightweight, fast, privacy-first; RainLoop fork
- **Roundcube** — PHP, MySQL/PG, mature, rich plugin ecosystem, more complex
- **Rainloop** — abandoned predecessor of SnappyMail
- **Sogo** — CalDAV + CardDAV + webmail, enterprise-focused, heavy
- **Horde** — old-school enterprise groupware
- **Bichon** — archive-only (no sending/reading live mail)

**Choose SnappyMail if:** you want a fast, no-DB PHP webmail client that's easy to deploy and respects user privacy.

## Links

- Repo: <https://github.com/the-djmaze/snappymail>
- Wiki: <https://github.com/the-djmaze/snappymail/wiki/Installation-instructions>
- Docker Hub: <https://hub.docker.com/r/djmaze/snappymail>
- Roundcube (alt): <https://roundcube.net>
