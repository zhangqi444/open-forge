---
name: iredmail
description: iRedMail recipe for open-forge. Full-featured mail server solution — Postfix + Dovecot + SpamAssassin + ClamAV + SOGo/Roundcube. Shell-script installer on Linux/BSD. Upstream: https://github.com/iredmail/iRedMail
---

# iRedMail

Full-featured, open-source mail server solution. Installs and configures Postfix (SMTP), Dovecot (IMAP/POP3), SpamAssassin, ClamAV antivirus, Amavis, optional webmail (Roundcube or SOGo), and an admin panel — all in one shell script on a clean Linux/BSD server.

1,792 stars · GPL-3.0

Upstream: https://github.com/iredmail/iRedMail
Website: https://www.iredmail.org/
Docs: https://docs.iredmail.org/
Docker edition: https://github.com/iredmail/dockerized

## What it is

iRedMail installs a complete mail server stack in minutes:

- **Postfix** — SMTP server (send/receive email)
- **Dovecot** — IMAP and POP3 server (access mailboxes)
- **SpamAssassin + Amavis** — Spam filtering
- **ClamAV** — Antivirus scanning
- **Roundcube** — Webmail client (optional)
- **SOGo** — Groupware webmail with CalDAV/CardDAV (optional)
- **iRedAdmin** — Web admin panel (open-source or paid Pro)
- **Fail2ban** — Brute force protection
- **DKIM signing** — DomainKeys Identified Mail for deliverability
- **TLS/SSL** — Encrypted SMTP and IMAP
- **Virtual domains** — Multiple email domains from one server
- **OpenLDAP or MySQL/PostgreSQL** — User/domain storage backend
- **Quota management** — Per-user mailbox size limits

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Bare metal / VPS | Ubuntu 22.04/24.04 | Recommended; full-featured |
| Bare metal / VPS | Debian 12/13 | Supported |
| Bare metal / VPS | Rocky Linux 9/10, AlmaLinux 9/10 | Supported |
| Bare metal / VPS | FreeBSD 14.x | Supported |
| Docker | iredmail/dockerized | All-in-one Docker edition |

Note: iRedMail must be installed on a **fresh, clean OS** with no existing mail server software. Do not run on a shared server.

## Inputs to collect

### Phase 1 — Pre-install
- Dedicated server/VPS with at least 2GB RAM (4GB+ recommended)
- Clean OS install (Ubuntu 24.04 recommended)
- Fully qualified domain name (FQDN) set as hostname: e.g. mail.example.com
- Static public IP address
- Port 25 open (many cloud providers block port 25 by default — check before starting)
- DNS records to prepare:
  - A record: mail.example.com → <your-ip>
  - MX record: example.com → mail.example.com
  - PTR (reverse DNS): <your-ip> → mail.example.com
  - SPF TXT record: v=spf1 mx ~all
  - DKIM and DMARC (generated/configured by iRedMail)

### Phase 2 — Installer prompts
- Mail domain name (e.g. example.com)
- Admin password for postmaster@example.com
- Storage backend: OpenLDAP, MySQL, or PostgreSQL
- Optional components: Roundcube, SOGo, iRedAdmin
- Mailbox storage path

## Software-layer concerns

### Installation
  # Download from https://www.iredmail.org/download.html
  tar xjf iRedMail-x.y.z.tar.bz2
  cd iRedMail-x.y.z/
  bash iRedMail.sh

Interactive installer walks through all options. Takes 10-30 minutes.

### Config paths (after install)
- /etc/postfix/ — Postfix SMTP configuration
- /etc/dovecot/ — Dovecot IMAP/POP3 configuration
- /etc/amavis/ — Amavis/SpamAssassin
- /etc/clamav/ — ClamAV antivirus
- /opt/iredapd/ — iRedAPD policy server
- Mailboxes: /var/vmail/ (default)

### Ports
- TCP 25 — SMTP (inbound and relay)
- TCP 587 — SMTP Submission (authenticated outbound)
- TCP 465 — SMTP over TLS (legacy)
- TCP 993 — IMAPS (TLS)
- TCP 995 — POP3S (TLS)
- TCP 80/443 — Webmail and admin panel

### Docker edition
  git clone https://github.com/iredmail/dockerized
  cd dockerized
  # Edit docker-compose.yml: set hostname, domain, passwords
  docker compose up -d

## Upgrade procedure

1. Backup: follow https://docs.iredmail.org/backup.restore.html
   - mysql: mysqldump or pg_dump
   - /var/vmail/ (mailboxes)
   - Config directories
2. Check upgrade guide for your version at: https://docs.iredmail.org/#upgrade
3. Follow the version-specific upgrade instructions (manual steps + SQL changes)
4. iRedMail does NOT have an automatic upgrade tool for major versions; each upgrade is documented step-by-step

## Gotchas

- Port 25 may be blocked — cloud providers (AWS, GCP, Azure, Hetzner, DigitalOcean) block port 25 by default; you must request it to be unblocked, or use a mail relay service
- PTR record is essential — major providers (Gmail, Outlook) reject mail from IPs without matching reverse DNS; set PTR at your hosting provider
- Fresh OS only — do not install on a server that already has a web server, database, or other mail software; conflicts are guaranteed
- Deliverability takes time — new IP addresses have no reputation; expect some mail going to spam initially; use a mail warm-up strategy
- iRedMail Easy — commercial platform at https://www.iredmail.org/easy.html offers easier deployment and one-click upgrades; the shell-script installer is more hands-on
- Manual upgrades — major version upgrades require following documented step-by-step procedures; there's no automated upgrade path
- iRedAdmin Pro — the free iRedAdmin has limited features; Pro version adds per-domain management, statistics, and a nicer UI
- Spam filtering tuning — SpamAssassin needs tuning for your traffic patterns; defaults are a starting point

## Links

- Upstream README: https://github.com/iredmail/iRedMail/blob/master/README.md
- Installation guide: https://docs.iredmail.org/#install
- Upgrade guides: https://docs.iredmail.org/#upgrade
- Docker edition: https://github.com/iredmail/dockerized
- iRedMail Easy (commercial): https://www.iredmail.org/easy.html
