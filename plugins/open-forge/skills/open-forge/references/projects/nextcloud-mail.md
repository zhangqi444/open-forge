---
name: Nextcloud Mail
description: "Email client app for Nextcloud. Nextcloud app (PHP/Vue). nextcloud/mail. Install from Nextcloud app store — no standalone Docker image. Connects IMAP accounts, unified inbox, S/MIME encryption, AI thread summaries, Contacts/Calendar integration. AGPL-3.0."
---

# Nextcloud Mail

**IMAP email client integrated into Nextcloud.** Access multiple email accounts from your Nextcloud instance. Unified inbox across accounts, S/MIME encryption support, thread grouping, AI-powered priority inbox and thread summaries (via Nextcloud AI backend). Deep integration with Nextcloud Contacts and Calendar.

Built + maintained by **Nextcloud GmbH and contributors**. AGPL-3.0 license.

- Upstream repo: <https://github.com/nextcloud/mail>
- Nextcloud App Store: <https://apps.nextcloud.com/apps/mail>
- Admin docs: <https://docs.nextcloud.com/server/stable/admin_manual/groupware/mail.html>

> **Installation note:** Nextcloud Mail is a **Nextcloud app** — not a standalone Docker container. It requires a running Nextcloud instance and is installed via the Nextcloud app store. There is no standalone `docker-compose.yml` for Mail alone.

## Prerequisites

- A running Nextcloud instance
- At least one IMAP/SMTP email account to connect
- Nextcloud 25+ (check the app store for current compatibility)

## Install

### Option 1: Nextcloud web UI (easiest)

1. Log in as Nextcloud admin.
2. Go to **Apps** → search for "Mail".
3. Click **Install** → wait for installation.
4. Open Mail from the top navigation.
5. Click **+ Add account** → enter your IMAP/SMTP credentials.

### Option 2: occ command

```bash
docker compose exec nextcloud php occ app:install mail
docker compose exec nextcloud php occ app:enable mail
```

### Option 3: Manual

```bash
curl -L https://github.com/nextcloud-releases/mail/releases/latest/download/mail.tar.gz | \
  tar xz -C /var/www/nextcloud/apps/
# Enable in admin panel
```

## Account setup

Nextcloud Mail connects to external IMAP servers — it is an **email client**, not an email server.

To add an account after installation:
1. **Mail → Settings → + Add account**
2. Enter email address, IMAP server/port/TLS, SMTP server/port/TLS, credentials
3. Mail auto-discovers settings for common providers (Gmail, Outlook, Fastmail, etc.)

## Features overview

| Feature | Details |
|---------|---------|
| Multiple accounts | Connect any number of IMAP accounts |
| Unified inbox | One view across all accounts |
| Thread view | Messages grouped by conversation thread |
| Mailbox management | Create, rename, delete, and organize mailboxes (IMAP folders) |
| S/MIME | Send and receive S/MIME-signed and encrypted emails |
| Mailvelope support | PGP via Mailvelope browser extension |
| AI priority inbox | Rank important messages first (Nextcloud AI backend) |
| AI thread summaries | Summarize long email threads (Nextcloud AI backend, opt-in) |
| Contacts integration | Auto-complete from Nextcloud Contacts; show contact details |
| Calendar integration | Event invitations appear as calendar events |
| Files integration | Attach Nextcloud files directly to emails |
| Tasks integration | Create tasks from emails |
| Message search | Search across all messages |
| HTML + plain text | Compose in rich HTML or plain text |
| Attachments | Download/preview attachments via Nextcloud Files |
| Alias support | Send from aliases configured on your mail server |

## AI features (optional)

Nextcloud Mail includes AI features powered by the Nextcloud text processing backend:

| Feature | Description | Ethical AI Rating |
|---------|-------------|-------------------|
| Priority Inbox | Locally trained model on your own data | 🟢 Green |
| Thread Summaries | Depends on configured AI backend | 🟢–🔴 varies |

AI features require configuring a text processing app in Nextcloud admin (Nextcloud Assistant + a backend like llm2 or an external API).

## Gotchas

- **This is an email client, not a server.** Nextcloud Mail connects to existing IMAP/SMTP servers. It doesn't replace your mail server. You still need a mail provider (Gmail, Fastmail, self-hosted Stalwart/Dovecot, etc.).
- **Requires Nextcloud.** Not a standalone app. Need a full Nextcloud installation.
- **S/MIME requires certificates.** To use S/MIME, you need a valid S/MIME certificate issued by a CA. Self-signed certificates work for signing but not for trusted encryption with external recipients.
- **AI features need a backend.** Priority Inbox and thread summaries require a Nextcloud AI/text-processing backend to be configured separately (e.g. Nextcloud Assistant + local LLM or OpenAI API).
- **IMAP sync performance.** With many messages across many accounts, initial sync can be slow. Subsequent syncs are incremental and fast.
- **Background job for sync.** Like all Nextcloud background tasks, mail sync runs on the cron schedule. Configure system cron (not AJAX) for reliable background sync.

## Upgrade

```bash
# Via Nextcloud admin panel: Apps → Updates → Mail
# or:
docker compose exec nextcloud php occ app:update mail
```

## Project health

Active Nextcloud GmbH + community development, AI features, S/MIME, Contacts/Calendar integration. AGPL-3.0.

## Email-client-family comparison

- **Nextcloud Mail** — Nextcloud app, IMAP client, S/MIME, AI features, Contacts/Calendar integration, AGPL-3.0
- **Roundcube** — PHP, standalone IMAP webmail; no Nextcloud integration; widely deployed
- **Rainloop/Snappymail** — PHP, standalone IMAP webmail; lightweight; no AI features
- **Horde Webmail** — PHP, standalone; powers Nextcloud Mail internally (Horde libraries)
- **Stalwart Mail** — Rust, full email **server** (IMAP+SMTP+JMAP); not a client

**Choose Nextcloud Mail if:** you already run Nextcloud and want an integrated email client with Contacts/Calendar/Files integration, S/MIME, and optional AI features — within your Nextcloud ecosystem.

## Links

- Repo: <https://github.com/nextcloud/mail>
- App Store: <https://apps.nextcloud.com/apps/mail>
- Admin docs: <https://docs.nextcloud.com/server/stable/admin_manual/groupware/mail.html>
