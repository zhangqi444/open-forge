---
name: Stalwart Mail Server
description: "All-in-one open-source mail and collaboration server — SMTP, IMAP4, JMAP, POP3, CalDAV, CardDAV, WebDAV with built-in spam filtering, DKIM/DMARC/SPF, and a web admin UI. Rust. AGPL-3.0."
---

# Stalwart Mail Server

Stalwart is a modern, all-in-one open-source mail and collaboration server written in Rust. It handles the full email stack (SMTP, IMAP4, JMAP, POP3) plus collaboration protocols (CalDAV, CardDAV, WebDAV) in a single binary with a web admin interface, built-in spam filtering, and comprehensive email authentication (DKIM, DMARC, SPF, ARC, DANE, MTA-STS).

Maintained by Stalwart Labs. Fast-moving project; v0.x series with production deployments. An Enterprise edition adds advanced features (ISO 27001 certification, commercial license, professional support).

Use cases: (a) self-hosted email server for individuals, families, or organizations (b) replacing hosted Gmail/Outlook/FastMail (c) privacy-first email with full data ownership (d) developer-friendly email infrastructure with JMAP support (e) all-in-one groupware with calendar and contacts.

Features:

- **Complete email protocols** — SMTP, IMAP4rev2, IMAP4rev1, JMAP, POP3, ManageSieve
- **Collaboration** — CalDAV + CardDAV (calendar, contacts), WebDAV (file storage), JMAP for Calendars/Contacts
- **Email authentication** — DKIM (with auto key rotation), DMARC, SPF, ARC; DANE, MTA-STS, TLS reporting
- **Spam/phishing filter** — built-in comprehensive filter rules; Sieve scripting support
- **Web admin UI** — browser-based management; no CLI required for day-to-day ops
- **TLS** — automatic ACME/Let's Encrypt certificate management
- **Storage backends** — local filesystem, S3-compatible, PostgreSQL, MySQL, SQLite, Redis
- **Directory integration** — LDAP, SQL directories for user management
- **Rate limiting & quotas** — per-user mailbox quotas, connection/message rate limits
- **Milter integration** — connect external mail filters (SpamAssassin, ClamAV, rspamd)
- **Single binary** — all protocols in one process; simple deployment

- Upstream repo: https://github.com/stalwartlabs/stalwart
- Homepage: https://stalw.art/
- Docs: https://stalw.art/docs/install/get-started
- Discord: https://discord.com/servers/stalwart-923615863037390889

## Architecture

- **Single Rust binary** — all protocols handled in-process; minimal dependencies
- **Storage** — configurable: RocksDB (default, embedded), PostgreSQL, MySQL, SQLite for message store; S3 for blob storage
- **TLS** — built-in ACME; or bring your own certificates
- **No external dependencies** — does not require Redis, Elasticsearch, or separate MTA
- **Ports**:
  - `25` — SMTP (inbound)
  - `465` — SMTPS (submission with SSL)
  - `587` — Submission (STARTTLS)
  - `143` — IMAP
  - `993` — IMAPS
  - `4190` — ManageSieve
  - `8080` — HTTP admin + JMAP + WebDAV/CalDAV/CardDAV

## Compatible install methods

| Infra       | Runtime               | Notes                                                        |
|-------------|-----------------------|--------------------------------------------------------------|
| Linux VPS   | Binary (recommended)  | Download release binary; run as systemd service              |
| Docker      | `stalwartlabs/stalwart` | Official image; quick start                                |
| Docker Compose | with optional reverse proxy | For TLS termination and port management              |
| Kubernetes  | Helm chart (community) | Check docs for k8s deployment                               |

## Inputs to collect

| Input          | Example                    | Phase    | Notes                                                      |
|----------------|----------------------------|----------|------------------------------------------------------------|
| Domain         | `mail.example.com`         | DNS      | MX record + A record required                              |
| Hostname       | `mail.example.com`         | Config   | Server hostname for SMTP HELO/EHLO                         |
| Admin password | strong password            | Install  | Set on first-run setup wizard                              |
| TLS cert       | ACME / Let's Encrypt       | TLS      | Stalwart handles ACME automatically                        |
| Storage path   | `/opt/stalwart/`           | Config   | Where to store messages and config                         |

## Install (Linux binary)

```sh
# Download and run the install script
curl -fsSL https://github.com/stalwartlabs/stalwart/releases/latest/download/install.sh | bash

# Or download the binary directly
# https://github.com/stalwartlabs/stalwart/releases

# First run: setup wizard
stalwart-mail --init /opt/stalwart
```

The setup wizard configures your domain, TLS, and admin credentials interactively.

See https://stalw.art/docs/install/get-started for complete installation steps.

## Docker quick start

```sh
docker run -d \
  -p 25:25 -p 465:465 -p 587:587 \
  -p 143:143 -p 993:993 \
  -p 4190:4190 -p 8080:8080 \
  -v stalwart-data:/opt/stalwart-mail \
  --name stalwart \
  stalwartlabs/stalwart:latest
```

Then visit `http://localhost:8080/` to complete setup via the web wizard.

## Required DNS records

```
# MX record
example.com.   IN  MX  10  mail.example.com.

# A record
mail.example.com.  IN  A  <your-server-ip>

# SPF
example.com.   IN  TXT  "v=spf1 mx ~all"

# DKIM (key generated by Stalwart; copy from admin UI)
selector._domainkey.example.com.  IN  TXT  "v=DKIM1; k=rsa; p=<key>"

# DMARC
_dmarc.example.com.  IN  TXT  "v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"

# MTA-STS
_mta-sts.example.com.  IN  TXT  "v=STSv1; id=<timestamp>"
```

## Data & config layout

- **`/opt/stalwart/`** — default data directory
  - `config.toml` — main configuration
  - `data/` — message store (RocksDB by default)
  - `blobs/` — email attachments and large content
  - `certs/` — TLS certificates (ACME-managed)

## Upgrade

```sh
# Stop service
systemctl stop stalwart-mail

# Download new binary
# Replace binary at /usr/local/bin/stalwart-mail

# Start service (runs DB migrations automatically)
systemctl start stalwart-mail
```

## Gotchas

- **Port 25 often blocked by cloud providers** — AWS, GCP, Azure, DigitalOcean, Hetzner, and others block port 25 on new VPS instances to prevent spam. You need to request unblocking or use a transactional email relay for outbound delivery. Check your provider's policy before choosing a VPS for email hosting.
- **IP reputation matters enormously** — new IP addresses have no sending reputation. Fresh VPS IPs are often pre-listed on spam blacklists. Use MXToolbox to check your IP's reputation, and consider a "warmup" period of gradual volume increase.
- **DKIM + SPF + DMARC are non-optional** — modern email providers (Gmail, Outlook) reject or junk mail missing proper authentication. Stalwart generates DKIM keys automatically; copy the TXT record to your DNS.
- **Reverse DNS (PTR) record required** — your VPS IP must have a PTR record matching your mail hostname. Set this in your VPS provider's control panel (not your domain registrar).
- **AGPL-3.0 license** — if you modify Stalwart and offer it as a service, you must release modifications under AGPL-3.0. The Enterprise edition provides a commercial license.
- **v0.x = active development** — Stalwart moves fast; backup before upgrades, and review the changelog for breaking changes.
- **Email self-hosting is hard in general** — deliverability, spam management, and keeping up with changing standards (BIMI, TLS reporting, etc.) require ongoing attention. Stalwart handles much of this automatically, but plan for ongoing maintenance.
- **Alternatives:** Maddy (Go, similar single-binary approach), Mailcow (Docker-based, full groupware stack), Mail-in-a-Box (Ubuntu-based turnkey), iRedMail (traditional Postfix/Dovecot stack), Migadu (managed, affordable).

## Links

- Repo: https://github.com/stalwartlabs/stalwart
- Homepage: https://stalw.art/
- Documentation: https://stalw.art/docs/install/get-started
- Docker Hub: https://hub.docker.com/r/stalwartlabs/stalwart
- Releases: https://github.com/stalwartlabs/stalwart/releases
- Discord: https://discord.com/servers/stalwart-923615863037390889
- Blog: https://stalw.art/blog/
