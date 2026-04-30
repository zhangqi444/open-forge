---
name: Roundcube Webmail
description: "Classic browser-based IMAP webmail client — address book, folder management, drag-and-drop, PGP, calendar (via plugin). PHP-based, skin + plugin architecture. Ubiquitous on cPanel/Plesk hosts. GPL-3.0 (with plugin/skin exceptions)."
---

# Roundcube Webmail

Roundcube is **the classic browser-based IMAP webmail client** — you point it at your IMAP/SMTP servers and get a three-pane (folder / message-list / message) webmail UX with drag-and-drop, address book, folder management, search, threaded conversations, spell-check, and a mature plugin ecosystem. If you've ever logged into webmail via cPanel, Plesk, or a shared-host control panel, you've seen Roundcube.

Pair it with **Mailu / Mailcow / iRedMail / Dovecot+Postfix** as the backend; Roundcube handles the UI. Many mail stacks bundle Roundcube; you can also run it standalone against any IMAP server.

Features:

- **IMAP + SMTP + Sieve** — read, send, filter
- **Folders** — full folder management (create, rename, subscribe, move)
- **Threading** — conversation view
- **Drag-and-drop** — messages + folders + attachments
- **Search** — subject, body, headers (server-side IMAP SEARCH)
- **Address book** — local + CardDAV + LDAP
- **MIME attachments** — inline images, previews, downloads
- **Compose** — HTML + plain-text, drafts, signatures, attachment remembering
- **Identities** — multi-identity per account (From addresses)
- **Encryption** — **Enigma** plugin (PGP/MIME), **S/MIME** plugin
- **Managesieve** — server-side mail filters (requires Dovecot sieve)
- **Spam** — mark junk; integrates with SpamAssassin/Rspamd via IMAP flags
- **Themes** — Elastic (default, responsive), Larry (classic), plus third-party
- **Plugins** — 100+: calendar, tasks, contextmenu, newmail_notifier, markasjunk2, archive, attachment_reminder, vacation, etc.
- **i18n** — 80+ language packs
- **Mobile** — Elastic skin is mobile-responsive

- Upstream repo: <https://github.com/roundcube/roundcubemail>
- Website: <https://roundcube.net>
- Docs: <https://roundcube.net/support>
- Docker image (official): <https://hub.docker.com/r/roundcube/roundcubemail>
- Plugins: <https://plugins.roundcube.net>
- Skins: <https://plugins.roundcube.net> (filter: skin)

## Architecture in one minute

- **PHP 7.3+** (check current for version floor)
- **DB**: MySQL / MariaDB / Postgres / SQLite (SQLite fine for solo)
- **IMAP server**: Dovecot / Cyrus / Courier / any RFC-compliant IMAP
- **SMTP server**: Postfix / Exim / SES / Mailgun / any SMTP endpoint
- **Optional**: Managesieve server (usually Dovecot) for server-side filters
- **Web server**: Apache / Nginx + PHP-FPM
- **Stateless-ish**: mail lives on IMAP server; Roundcube stores preferences, address book, drafts cache in its DB

## Compatible install methods

| Infra         | Runtime                                                  | Notes                                                                                   |
| ------------- | -------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| Single VM     | **Docker (`roundcube/roundcubemail`)**                       | **Easy**                                                                                       |
| Single VM     | Native LAMP/LEMP + Roundcube tarball                                  | Classic — drop into webroot                                                                          |
| Shared host   | cPanel/Plesk bundled install                                                   | Ubiquitous                                                                                          |
| Inside a mail stack | Mailu / Mailcow / iRedMail bundle Roundcube                                             | One less container to worry about                                                                           |
| Kubernetes    | Community manifests                                                                         | Works                                                                                                                 |
| Raspberry Pi  | Native or Docker                                                                                  | Fine for family mail                                                                                                           |

## Inputs to collect

| Input         | Example                     | Phase     | Notes                                                            |
| ------------- | --------------------------- | --------- | ---------------------------------------------------------------- |
| Domain        | `webmail.example.com`          | URL       | Reverse proxy with TLS                                               |
| IMAP server   | `mail.example.com:993 (TLS)`         | Network   | Must be reachable from Roundcube server                                       |
| SMTP server   | `mail.example.com:587 (STARTTLS)`          | Network   | For sending                                                                             |
| DB            | MySQL / Postgres / SQLite creds                  | DB        | For preferences, address book, sessions, drafts                                                            |
| DES key       | random 24 chars                                         | Crypto    | `des_key` in `config.inc.php` — encrypts session data                                                                |
| Default host  | `ssl://mail.example.com:993`                                        | Config    | `default_host` — which IMAP to log into                                                                                     |
| SMTP settings | `smtp_server`, `smtp_port`, `smtp_user`, `smtp_pass`                         | Config    | `%u` / `%p` = auth-as-user                                                                                                              |

## Install (Docker)

```yaml
services:
  roundcube:
    image: roundcube/roundcubemail:1.6.x-apache   # pin minor + variant
    restart: unless-stopped
    depends_on: [db]
    environment:
      ROUNDCUBEMAIL_DB_TYPE: pgsql
      ROUNDCUBEMAIL_DB_HOST: db
      ROUNDCUBEMAIL_DB_USER: roundcube
      ROUNDCUBEMAIL_DB_PASSWORD: <strong>
      ROUNDCUBEMAIL_DB_NAME: roundcube
      ROUNDCUBEMAIL_DEFAULT_HOST: ssl://mail.example.com
      ROUNDCUBEMAIL_DEFAULT_PORT: "993"
      ROUNDCUBEMAIL_SMTP_SERVER: tls://mail.example.com
      ROUNDCUBEMAIL_SMTP_PORT: "587"
      ROUNDCUBEMAIL_PLUGINS: archive,zipdownload,managesieve,enigma
      ROUNDCUBEMAIL_SKIN: elastic
      ROUNDCUBEMAIL_DES_KEY: <24-random-chars>
    volumes:
      - ./rc-config:/var/roundcube/config
      - ./rc-db-sqlite:/var/roundcube/db         # only if sqlite
    ports:
      - "8080:80"

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: roundcube
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: roundcube
    volumes:
      - rc-db:/var/lib/postgresql/data

volumes:
  rc-db:
```

Front with Caddy/Traefik/Nginx for TLS.

## Install (native, Debian/Ubuntu)

```sh
sudo apt install roundcube roundcube-plugins roundcube-plugins-extra
# Or: download tarball from roundcube.net, extract to /var/www/roundcube,
# then /var/www/roundcube/installer/ for the web installer (DELETE after).
```

Or tarball:
```sh
cd /var/www
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.x/roundcubemail-1.6.x-complete.tar.gz
tar xzf roundcubemail-1.6.x-complete.tar.gz
mv roundcubemail-1.6.x roundcube
chown -R www-data:www-data roundcube/temp roundcube/logs
# Browse /installer → fill details → generates config
# DELETE or BLOCK /installer after setup
```

## First boot

1. Browse `https://webmail.example.com/installer` (first run) → enter DB + IMAP + SMTP settings → wizard writes `config/config.inc.php`
2. **IMPORTANT**: delete / protect `installer/`:
   ```sh
   rm -rf /var/www/roundcube/installer/
   ```
3. Browse `https://webmail.example.com/` → log in as an existing IMAP user (e.g., `alice@example.com`)
4. Settings → Preferences → set timezone, date format, composing defaults, signature
5. Address book → add contacts or enable CardDAV
6. Filters (if Managesieve enabled) → create a spam-folder rule

## Data & config layout

- `config/config.inc.php` — primary config (DB, IMAP, SMTP, plugins, skins)
- `config/defaults.inc.php` — upstream defaults (don't edit; copy lines to `config.inc.php`)
- DB — users (prefs), address book contacts, saved searches, managesieve cache
- `logs/` — PHP errors, IMAP session logs (rotate!)
- `temp/` — temp files (attachments being uploaded, MIME assembly)

## Backup

```sh
# DB
docker exec rc-db pg_dump -U roundcube roundcube | gzip > rc-db-$(date +%F).sql.gz
# Config
cp config/config.inc.php rc-config-$(date +%F).bak
# Mail itself is on your IMAP server — separate backup
```

Mail data lives on the IMAP server, not in Roundcube. Roundcube backup = just prefs + address book. Losing it = users re-configure; no mail lost.

## Upgrade

1. Releases: <https://github.com/roundcube/roundcubemail/releases>. Active; 1.6 is current series.
2. **Back up config + DB.**
3. Docker: bump tag.
4. Native: replace codebase; run `bin/installto.sh /var/www/roundcube` from the new extracted tarball.
5. DB schema migrations run automatically.
6. Remove `installer/` after.
7. Plugins sometimes lag — check plugin compat before bumping Roundcube major.

## Gotchas

- **Delete / protect `installer/` after install.** Anyone hitting `/installer` can potentially reset config. Same gotcha as Dolibarr / MediaWiki / most PHP apps.
- **des_key** — must be stable; changing invalidates all active sessions. Back it up.
- **Logs in `logs/` can grow** — Roundcube writes per-session IMAP protocol traces at debug level. Keep log level at ERROR in prod; rotate.
- **`temp/` fill-up** — partial uploads; rotate via cron.
- **Password plugin** for users to change their IMAP password from webmail — requires a driver for your mail backend (Dovecot, LDAP, SQL). Configure carefully.
- **HTML email + remote images** — by default, Roundcube blocks remote images until user clicks "Always show images for this sender." Security feature against tracking pixels.
- **Plugin overload** — every plugin is extra surface area. Enable only what users need; prune aggressively.
- **Skin `Elastic` is responsive** (mobile-friendly); `Larry` is classic 3-pane; `Classic` is retro. Most deployments: Elastic.
- **Session storage**: default is DB; for multi-server, use Redis or memcached.
- **Managesieve** (server-side filter editor) requires Dovecot with managesieve plugin listening on :4190; enable `managesieve` plugin in Roundcube config.
- **Enigma** (PGP) — stores keys in Roundcube's DB or on disk; usable but not as integrated as Mailvelope browser extension. For serious PGP users, Thunderbird or Mailvelope is often better.
- **S/MIME plugin** — certs required.
- **Calendar/Tasks** — require RCMCarddav + Kolab-style backends or third-party plugins; Roundcube doesn't ship with a calendar out of the box (Kolab fork does).
- **Multi-server**: stateless-ish; share DB + config across PHP nodes; sticky sessions optional.
- **Roundcube Next** (2014-2016 revamp attempt) was shelved; current 1.x line is the active product. Roundcube development is **slow-and-steady**, not flashy.
- **Security**: subscribe to the Roundcube security announcement list — CVEs land occasionally.
- **Branding**: you can rebrand via skins + logo replacement; commercial deployments often do.
- **ActiveSync / CalDAV/CardDAV** — not native; add separately (z-push, SOGo integration, etc.).
- **IMAP performance**: Roundcube relies on server-side IMAP features. Dovecot with FTS (full-text search) + metadata indexing is much snappier than stock IMAP.
- **License**: GPL-3.0 **with explicit exceptions for plugins + skins** — those can be non-GPL. Nice for commercial plugin authors.
- **Alternatives worth knowing:**
  - **SnappyMail** — modern fork of the defunct **RainLoop**; more modern UX, single-file PHP, lighter; included in Mailu as webmail option
  - **RainLoop** — original; abandoned; SnappyMail is its successor
  - **SOGo** — groupware (webmail + calendar + contacts + ActiveSync) — heavier
  - **Rainloop / afterlogic AfterMail / SquirrelMail / Horde IMP** — older/niche webmails
  - **Thunderbird** (desktop IMAP client) or **K-9/FairEmail** (Android)
  - **Apple Mail / Outlook** — native clients
  - **Modern webmails**: **Mailcow uses SOGo + Roundcube**; **Mailu uses Roundcube + SnappyMail** choice
  - **Tutanota / ProtonMail webmail** — encrypted but paired with their own backend
  - **Choose Roundcube if:** proven, plugin-rich, standard webmail UI over your own IMAP.
  - **Choose SnappyMail if:** you want a lighter, more modern-looking webmail in one PHP file.
  - **Choose SOGo if:** you need webmail + calendar + contacts + ActiveSync integrated.

## Links

- Repo: <https://github.com/roundcube/roundcubemail>
- Website: <https://roundcube.net>
- Docs / support: <https://roundcube.net/support>
- Download: <https://roundcube.net/download>
- Docker Hub: <https://hub.docker.com/r/roundcube/roundcubemail>
- Docker image README: <https://github.com/roundcube/roundcubemail-docker>
- Releases: <https://github.com/roundcube/roundcubemail/releases>
- Plugins directory: <https://plugins.roundcube.net>
- Wiki: <https://github.com/roundcube/roundcubemail/wiki>
- License + exceptions: <https://roundcube.net/license>
- SnappyMail alternative: <https://snappymail.eu>
- SOGo alternative: <https://www.sogo.nu>
