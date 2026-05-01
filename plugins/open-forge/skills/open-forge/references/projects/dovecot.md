---
name: Dovecot
description: "Self-hosted IMAP and POP3 mail server. Linux packages or Docker. C. dovecot/core. High-performance email storage and retrieval, mbox/Maildir/dbox, Sieve filtering, full-text search, authentication backends, LMTP/SMTP relay."
---

# Dovecot

**High-performance open-source IMAP and POP3 server.** The most widely deployed IMAP server in the world — used by ISPs and organizations to serve millions of mailboxes. Handles email storage and retrieval (IMAP/POP3); typically used alongside an SMTP server (Postfix, Exim, Sendmail) to build a complete mail stack. Supports Maildir, mbox, and dbox storage formats; Sieve email filtering; full-text search; multiple authentication backends.

Built + maintained by **Dovecot Oy** and open-source community. MIT/LGPL license (core); commercial Pro version available.

- Upstream repo: <https://github.com/dovecot/core>
- Website + docs: <https://doc.dovecot.org>
- Docker Hub: <https://hub.docker.com/r/dovecot/dovecot>
- Community: <https://dovecot.org/mailing-lists>

## Architecture in one minute

- **C** daemon — IMAP (port 143/993) + POP3 (port 110/995) server
- Processes: `master` (supervisor), `imap`, `pop3`, `lmtp`, `auth`, `indexer`, etc.
- Storage backends: **Maildir** (standard, recommended), **mbox** (legacy), **dbox** (Dovecot-native), **obox** (S3/object storage, Pro)
- Authentication: PAM, passwd, LDAP, SQL, OAuth2, passdb/userdb
- **LMTP**: accept inbound mail from an SMTP server (Postfix → Dovecot via LMTP)
- **Sieve**: server-side email filtering (sort, forward, vacation, etc.)
- **Full-text search**: Xapian/Solr/Squat plugins
- Docker image: `dovecot/dovecot` (multi-arch; amd64/arm64/armv7)
- Resource: **low-medium** — C daemon; scales to millions of users

## Compatible install methods

| Infra             | Runtime                  | Notes                                                             |
| ----------------- | ------------------------ | ----------------------------------------------------------------- |
| **Packages**      | APT/YUM + official repo  | **Most common** — Dovecot project maintains own APT/YUM repos     |
| **Docker**        | `dovecot/dovecot`        | Official Docker Hub; multi-arch                                   |
| **Source**        | `./configure && make`    | From GitHub; see INSTALL.md                                       |

## Inputs to collect

| Input                       | Example                          | Phase    | Notes                                                             |
| --------------------------- | -------------------------------- | -------- | ----------------------------------------------------------------- |
| Mail storage path           | `/var/mail/vhosts`               | Storage  | Where Maildir/mbox folders are stored                             |
| Authentication backend      | PAM / SQL / LDAP / passwd        | Auth     | How users authenticate                                            |
| SSL certificate             | Let's Encrypt or custom          | TLS      | Required for IMAPS/POP3S                                          |
| SMTP server integration     | Postfix → Dovecot LMTP           | Mail     | Postfix delivers to Dovecot via LMTP socket                       |
| Sieve (optional)            | ManageSieve port 4190            | Filter   | For server-side email rules                                       |

## Install via packages (Ubuntu/Debian)

```bash
# Official Dovecot APT repo (for latest stable)
wget https://repo.dovecot.org/DOVECOT-REPO-GPG -O /etc/apt/trusted.gpg.d/dovecot.gpg
# Add APT sources (see https://doc.dovecot.org/installation/packages/)
apt-get install dovecot-core dovecot-imapd dovecot-pop3d
# For LMTP:
apt-get install dovecot-lmtpd
# For Sieve:
apt-get install dovecot-sieve dovecot-managesieved
```

## Install via Docker

```bash
docker pull dovecot/dovecot:latest
docker run -d \
  --name dovecot \
  -p 143:143 -p 993:993 -p 110:110 -p 995:995 \
  -v ./dovecot-config:/etc/dovecot \
  -v ./mail:/var/mail \
  dovecot/dovecot:latest
```

Full Docker guide: <https://doc.dovecot.org/installation/docker/>

## Core configuration files

| File | Purpose |
|------|---------|
| `/etc/dovecot/dovecot.conf` | Main config (includes `conf.d/`) |
| `/etc/dovecot/conf.d/10-auth.conf` | Authentication settings |
| `/etc/dovecot/conf.d/10-mail.conf` | Mail location (Maildir/mbox/dbox) |
| `/etc/dovecot/conf.d/10-ssl.conf` | TLS/SSL settings |
| `/etc/dovecot/conf.d/20-imap.conf` | IMAP-specific settings |
| `/etc/dovecot/conf.d/90-sieve.conf` | Sieve filter settings |

Minimal `10-mail.conf` for Maildir:
```
mail_location = maildir:~/Maildir
```

## Typical full mail stack

```
Internet → Postfix (SMTP, port 25/587/465) → Dovecot (LMTP) → Maildir storage
User mail client ← Dovecot (IMAP/POP3, port 143/993/110/995)
```

Postfix `main.cf` for LMTP delivery to Dovecot:
```
mailbox_transport = lmtp:unix:private/dovecot-lmtp
```

## Authentication backends

| Backend | Config | Notes |
|---------|--------|-------|
| `passwd` + `shadow` | System users | Simple; users = system accounts |
| `SQL` (MySQL/PostgreSQL) | `passdb { driver = sql }` | Virtual users; recommended for multi-domain |
| `LDAP` | `passdb { driver = ldap }` | Active Directory / OpenLDAP |
| `OAuth2` | `passdb { driver = oauth2 }` | For SSO environments |
| `PAM` | `passdb { driver = pam }` | Linux PAM modules |

## Gotchas

- **Dovecot is IMAP/POP3 only.** Dovecot receives and stores mail — it does NOT send mail. You need an SMTP server (Postfix is the standard pairing). Postfix handles SMTP; Dovecot handles IMAP/POP3 and receives from Postfix via LMTP.
- **Maildir vs mbox.** **Use Maildir** for new installations — each email is a separate file; reliable with NFS; concurrent access safe. `mbox` is a single file per folder; corruption-prone with concurrent access; only for legacy compatibility.
- **LMTP socket vs TCP.** Postfix can deliver to Dovecot via a Unix socket (`lmtp:unix:private/dovecot-lmtp`) — faster and no network exposure — or via TCP (`lmtp:127.0.0.1:24`). Socket delivery is preferred on the same host.
- **Virtual users vs system users.** For multi-domain mail servers, use SQL-based virtual users (not system accounts). System user auth is fine for a single-domain home server. Virtual users don't create Linux accounts.
- **TLS is mandatory.** Don't run IMAP or POP3 without TLS in production. Use IMAPS (993) or IMAP+STARTTLS (143). Obtain certs from Let's Encrypt (certbot) and configure in `10-ssl.conf`.
- **Full-text search index.** Without FTS, Dovecot falls back to sequential scan for IMAP SEARCH. For large mailboxes, enable the Xapian FTS plugin (`apt install dovecot-fts-xapian`).
- **Sieve for filtering.** Sieve is the standard server-side filtering language. Dovecot implements it via the Pigeonhole project. Enables vacation replies, sorting to folders, forwarding — all without client-side rules.
- **doveadm tool.** `doveadm` is Dovecot's admin CLI — check mailboxes, force index rebuilds, kick users, migrate mail, run Sieve scripts. Essential for operations.
- **Dovecot Pro.** The commercial version adds object storage (S3/Azure), high-availability clustering, and enterprise support. The community edition covers all personal and small business use cases.

## Useful commands

```bash
# Check Dovecot config
doveconf -n

# Test authentication
doveadm auth test user@example.com

# Force re-index a mailbox
doveadm index -u user@example.com INBOX

# List user's mailboxes
doveadm mailbox list -u user@example.com

# Reload config
doveadm reload
```

## Project health

20+ year C codebase, very active development, official APT/YUM repos, Docker Hub (multi-arch), extensive docs, ISP-scale production use worldwide. Maintained by Dovecot Oy. MIT/LGPL community edition.

## Mail-server-family context

Dovecot is the IMAP/POP3 component of a mail stack:

| Role | Software |
|------|---------|
| SMTP (receive + relay) | Postfix (most common), Exim, Sendmail |
| IMAP/POP3 (storage + retrieval) | **Dovecot** |
| Spam filtering | SpamAssassin, Rspamd |
| Webmail | Roundcube, Rainloop, Snappymail |
| All-in-one stacks | Mailcow, Mailu, iRedMail (all use Dovecot internally) |

**If you want a complete self-hosted email server with a web UI and easy setup:** use [Mailcow](https://mailcow.email) or [Mailu](https://mailu.io) — both use Dovecot as the IMAP server internally but wrap it in a Docker Compose stack with Postfix, Rspamd, SOGo/Rainloop, and a management UI.

**Use Dovecot directly if:** you need fine-grained control over a mail server, are building a custom stack, or already have an SMTP server and need IMAP.

## Links

- Repo: <https://github.com/dovecot/core>
- Docs: <https://doc.dovecot.org>
- Docker Hub: <https://hub.docker.com/r/dovecot/dovecot>
- APT/YUM repos: <https://doc.dovecot.org/installation/packages/>
- Mailing list: <https://dovecot.org/mailing-lists>
