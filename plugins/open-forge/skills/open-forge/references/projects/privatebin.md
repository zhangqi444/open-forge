---
name: PrivateBin
description: "Minimalist, open-source, encrypted online pastebin. Zero-knowledge: server never sees cleartext. Text + attachment support, password protection, burn-after-reading, expiry, discussion, QR code. PHP; filesystem or SQL backend. Zlib/libpng license."
---

# PrivateBin

PrivateBin is a minimalist, **zero-knowledge** online pastebin. You paste text (or an attachment), the browser encrypts it with AES-256 **before** sending, and the server stores only ciphertext. The decryption key lives in the URL fragment (`#abc123...`), which **never leaves the browser** (URL fragments aren't sent in HTTP requests). The server literally cannot read your data.

Think GitHub Gist / Pastebin.com without the trust assumption. Great for sharing secrets, logs, configs, debug info, or anything you'd rather not leave plaintext on a third-party service.

Features:

- **End-to-end encrypted** — server sees only ciphertext
- **Burn after reading** — paste deletes itself after first view
- **Expiry** — 5 min, 1 hour, 1 day, 1 week, 1 month, 1 year, forever (configurable)
- **Password protection** — additional passphrase beyond the URL key
- **Attachments** — base64-encoded blobs (same E2E encryption)
- **Discussion** — threaded comments, also encrypted
- **QR code** — share paste URL
- **Syntax highlighting** + markdown rendering
- **Zero JavaScript beyond the browser's** — the server is pure PHP + static assets
- **Multiple storage backends**: filesystem, MySQL, Postgres, SQLite, Google Cloud, S3
- **i18n** — 30+ languages
- **Tor hidden service** — popular for anonymity

- Upstream repo: <https://github.com/PrivateBin/PrivateBin>
- Website: <https://privatebin.info>
- Docs: <https://github.com/PrivateBin/PrivateBin/wiki>
- Demo / public instances: <https://privatebin.info/directory/>
- Docker Hub: <https://hub.docker.com/r/privatebin/nginx-fpm-alpine>

## Architecture in one minute

- **PHP 7.3+** (modern PHP recommended)
- **Client-side**: vanilla JavaScript + WebCrypto (for AES-GCM encryption)
- **Server**: receives only ciphertext + metadata (expiry, burn flag)
- **Storage**: choose one of filesystem / SQLite / MySQL / Postgres / S3 / Google Cloud Storage
- **No DB required** for filesystem mode — the simplest deployment
- **Tiny footprint** — suitable for Pi Zero or cheap VPS

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                         |
| ----------- | ---------------------------------------------------- | ------------------------------------------------------------- |
| Single VM   | **Docker (`privatebin/nginx-fpm-alpine`)**               | **Simplest**                                                      |
| Single VM   | Native LAMP/LEMP                                          | Drop `.zip` into docroot; configure `cfg/conf.php`                |
| Shared host | cPanel PHP hosting                                          | Works in ~2 min                                                          |
| Raspberry Pi | Any arch Docker                                              | Tiny footprint                                                                |
| Tor hidden  | Behind Tor proxy                                                 | Popular for maximum anonymity                                                     |
| Kubernetes  | Minimal Deployment + PVC                                             | Stateless PHP container + PV for filesystem storage                                     |

## Inputs to collect

| Input            | Example                      | Phase     | Notes                                                            |
| ---------------- | ---------------------------- | --------- | ---------------------------------------------------------------- |
| Domain           | `paste.example.com`            | URL       | Reverse proxy with TLS                                              |
| Port             | `80` or `443`                   | Network   | Behind reverse proxy                                                        |
| Storage backend  | filesystem (default)             | Storage   | Simplest; scale to SQL only if volume is large                                  |
| Data dir         | `/srv/data`                        | Storage   | Writable by PHP-FPM user; outside webroot                                             |
| `cfg/conf.php`   | from `conf.sample.php`              | Config    | Copy + edit: expiry options, file size limits, storage backend                               |
| TLS              | Let's Encrypt                         | Security  | Mandatory — you don't want MITM tampering with the JS                                         |
| CAPTCHA (opt)    | hCaptcha / reCAPTCHA                     | Abuse     | For public instances                                                                              |

## Install via Docker

```sh
docker run -d --name privatebin \
  --restart unless-stopped \
  -p 8080:8080 \
  -v /opt/privatebin/data:/srv/data \
  -v /opt/privatebin/conf.php:/srv/cfg/conf.php:ro \
  privatebin/nginx-fpm-alpine:2.0.4    # pin; check Docker Hub
```

## Install via Docker Compose

```yaml
services:
  privatebin:
    image: privatebin/nginx-fpm-alpine:2.0.4    # pin specific version
    container_name: privatebin
    restart: unless-stopped
    read_only: true
    tmpfs:
      - /var/run
      - /tmp
    volumes:
      - ./data:/srv/data
      - ./conf.php:/srv/cfg/conf.php:ro
    ports:
      - "8080:8080"
```

Get a starter `conf.php` from <https://github.com/PrivateBin/PrivateBin/blob/master/cfg/conf.sample.php>, edit settings (expiry options, allowed formatters, sizelimit), mount read-only.

## Install natively

```sh
# Prereqs: PHP 7.3+ with GD extension (for QR) and session handling
cd /var/www
wget https://github.com/PrivateBin/PrivateBin/archive/refs/tags/vX.Y.Z.tar.gz
tar -xzf vX.Y.Z.tar.gz
mv PrivateBin-X.Y.Z paste
cd paste
cp cfg/conf.sample.php cfg/conf.php
# Edit cfg/conf.php
# Point Nginx/Apache docroot → /var/www/paste
chown -R www-data:www-data data/    # if using filesystem backend
```

## Config highlights (`cfg/conf.php`)

```php
[main]
name = "MyPrivateBin"
basepath = "https://paste.example.com/"
opendiscussion = false               # allow comments by default?
discussion = true                     # allow comments at all
burnafterreadingselected = false      # default radio button?
password = true                        # allow password-protection?
fileupload = true                      # allow attachment uploads?
sizelimit = 10485760                   # 10 MB per paste
template = "bootstrap"                 # bootstrap, bootstrap-dark, page, ...
languageselection = true                # show language dropdown?

[expire]
default = "1week"

[expire_options]
5min = 300
10min = 600
1hour = 3600
1day = 86400
1week = 604800
1month = 2592000
1year = 31536000
never = 0

[formatter_options]
plaintext = "Plain Text"
syntaxhighlighting = "Source Code"
markdown = "Markdown"

[model]
class = Filesystem                     # or MySQL, Postgres, etc.

[model_options]
dir = "/srv/data"
```

## Tor hidden service

```
# /etc/tor/torrc
HiddenServiceDir /var/lib/tor/privatebin/
HiddenServicePort 80 127.0.0.1:8080
```

Restart Tor → `/var/lib/tor/privatebin/hostname` contains your `.onion` address.

## First boot

Browse → paste text → choose expiry → click "Send" → URL with `#key` fragment copied. Share that URL.

No account creation, no setup wizard. That's the design.

## Data & config layout

- `/srv/data/` (Docker) or `data/` (native) — encrypted pastes
- `cfg/conf.php` — server config

## Backup

Almost stateless. Back up:

```sh
tar czf privatebin-data-$(date +%F).tgz /srv/data/
cp /etc/privatebin/conf.php privatebin-conf-$(date +%F).bak
```

For `never`-expiring pastes, data grows unbounded. Rotate.

## Upgrade

1. Releases: <https://github.com/PrivateBin/PrivateBin/releases>. Active.
2. Docker: pin, `docker compose pull && docker compose up -d`.
3. Native: download new release; preserve `cfg/conf.php` + `data/`; overwrite rest.
4. Read CHANGELOG for storage backend changes (rare).

## Gotchas

- **Zero-knowledge means "lost URL = lost paste"** — if you lose the URL (specifically the `#key` fragment), the paste cannot be recovered. Not by the server, not by a time machine. This is by design.
- **URL fragment matters** — `#key` is the decryption key. Users who pasted the URL without the fragment (e.g., from a truncated UI) can't decrypt. Always share the full URL.
- **Burn-after-reading + crawlers**: if a URL-scanning bot visits the URL before the human (Slack/Discord/email preview scrapers), the burn fires on the bot's visit. PrivateBin does have some mitigation (requires JS execution + explicit click) but expect this gotcha with automated previewers.
- **Password is IN ADDITION TO** the URL key, not a replacement. Even with password, you still need the URL key in the fragment.
- **Public instances attract abuse** — spam, illegal content, phishing payloads. Running a public PrivateBin = moderation burden (takedowns, abuse reports, potential legal exposure). Consider keeping yours private (auth on reverse proxy, or IP-restrict).
- **Spam on public instances**: consider enabling `markdown = false` and setting `fileupload = false` to reduce appeal for phishers.
- **Tor hidden service** is a popular deployment; the design aligns perfectly.
- **Storage backend choice**: filesystem is fine for <100k pastes. For very high volume, use Postgres/MySQL/S3. S3 backend is great for serverless deployments.
- **File uploads** are expensive — base64 expansion + DB storage. Enforce `sizelimit`. Consider disabling uploads if your use case is text-only.
- **Expiry cleanup** — on filesystem backend, expired pastes are deleted lazily on access. For cleanup, run `bin/cleanup.php` via cron. DB backends have their own TTL handling.
- **Rate limiting** — `[main] trafficlimit` + `trafficlimitheader` help but are IP-based. Reverse-proxy with fail2ban is stronger.
- **HTTPS everywhere** — the client-side JS does the crypto. If someone MITMs the JS download, they can exfiltrate plaintext. TLS is load-bearing.
- **Subresource Integrity** — PrivateBin ships with SRI hashes; don't modify JS files after install without updating SRI.
- **Browser crypto support** — PrivateBin requires WebCrypto (AES-GCM). Very old browsers (IE11) don't work; modern browsers all do.
- **Mobile**: works fine; responsive; no native app.
- **Discussion feature**: comments are also E2E-encrypted but discoverable by paste viewers. Useful for collaborative debugging; disable if you don't want it.
- **Directory of public instances**: <https://privatebin.info/directory/> — if you don't want to run your own, use a trusted instance.
- **License**: Zlib/libpng license (permissive, non-viral). Unusual choice; permits any use including commercial.
- **Alternatives worth knowing:**
  - **snibox** — multi-language snippet manager; not E2E encrypted
  - **Hastebin** — minimal pastebin; not E2E
  - **OpenPaste** — another pastebin
  - **onetimesecret** — focused on "one-time" secret sharing; simpler (separate recipe)
  - **PasswordPusher** — one-time-reveal passwords; simpler + focused (separate recipe)
  - **cryptgeon** — modern alternative with similar E2E approach
  - **Choose PrivateBin if:** you want a mature E2E-encrypted pastebin with discussion + attachments + multiple storage backends.
  - **Choose onetimesecret if:** you just want "share this secret once and have it disappear."
  - **Choose cryptgeon if:** you want a more modern UX + similar guarantees.

## Links

- Repo: <https://github.com/PrivateBin/PrivateBin>
- Website: <https://privatebin.info>
- Wiki / docs: <https://github.com/PrivateBin/PrivateBin/wiki>
- Install guide: <https://github.com/PrivateBin/PrivateBin/wiki/Installation>
- Config reference: <https://github.com/PrivateBin/PrivateBin/wiki/Configuration>
- Public instance directory: <https://privatebin.info/directory/>
- Docker Hub: <https://hub.docker.com/r/privatebin/nginx-fpm-alpine>
- Releases: <https://github.com/PrivateBin/PrivateBin/releases>
- Security audit history: <https://privatebin.info/security.html>
- Tor support: <https://github.com/PrivateBin/PrivateBin/wiki/Tor-support>
- FAQ: <https://github.com/PrivateBin/PrivateBin/wiki/FAQ>
