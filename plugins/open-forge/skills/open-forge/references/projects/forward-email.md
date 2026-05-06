---
name: forward-email
description: Forward Email recipe for open-forge. Privacy-focused open-source email service — full email hosting with SMTP, IMAP, CalDAV/CardDAV, encrypted mailboxes, catch-all aliases, and API. Source: https://github.com/forwardemail/forwardemail.net
---

# Forward Email

Privacy-focused, 100% open-source email service. Provides email forwarding, full mailbox hosting (SMTP/IMAP), encrypted SQLite mailboxes per alias, catch-all addresses, CalDAV/CardDAV, webhooks, and a REST API. Positioned as an all-in-one alternative to Gmail + Mailchimp + Sendgrid. Upstream: https://github.com/forwardemail/forwardemail.net. Docs: https://forwardemail.net/en/faq.

Note: The hosted service at forwardemail.net is free for basic use. Self-hosting is supported but is a complex, ops-heavy deployment designed for bare metal servers. Most users should use the hosted service unless they have strong data-sovereignty requirements.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Hosted service (forwardemail.net) | Any | Recommended for most users. Free tier available. |
| Self-hosted (bare metal) | Linux (Ubuntu) | Complex. Requires a dedicated server with reverse DNS, multiple open ports, Ansible. |
| Self-hosted (Docker) | Docker | Not the primary supported path; bare metal Ansible is upstream's method. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Domain name(s)?" | Primary domain for email hosting; DNS records required |
| setup | "Server IP (with rDNS)?" | Reverse DNS (PTR record) must point to the server hostname for mail delivery |
| setup | "Admin email?" | Superadmin account for the web interface |
| storage | "SQLite storage path?" | Encrypted per-alias mailboxes; needs fast local disk |
| tls | "TLS certificates?" | Let's Encrypt provisioned automatically if DNS is configured |

## Software-layer concerns

### Architecture overview

Forward Email is a Node.js monorepo running multiple services:
  - MX server (inbound email, port 25)
  - SMTP server (outbound relay, ports 465/587)
  - IMAP server (mailbox access, port 993)
  - Web/API server (HTTPS, port 443)
  - SQLite per-alias encrypted mailboxes (Bree background jobs)

### DNS prerequisites (before setup)

  # Required DNS records for your domain:
  MX     @ 10 mx1.forwardemail.net   (or your server hostname)
  A      @ <server-IP>
  PTR    <server-IP> → <server-hostname>   (set at hosting provider)
  SPF    TXT  "v=spf1 a mx ~all"
  DKIM   TXT  <generated-during-setup>
  DMARC  TXT  "v=DMARC1; p=quarantine"

### Self-hosted setup (summary)

  # Clone the repo
  git clone https://github.com/forwardemail/forwardemail.net
  cd forwardemail.net

  # Install Node.js 18.20.4 (exact version required)
  # Install system dependencies (see Ubuntu section in README):
  sudo apt-get install build-essential python3 libssl-dev ...

  # Copy and configure environment file
  cp .env.defaults .env
  # Edit .env: set domain, SMTP credentials, Redis URL, SQLite paths, etc.

  # Install dependencies
  npm install

  # For production, use the Ansible playbooks in the infra/ directory
  # See: https://github.com/forwardemail/forwardemail.net#server-infrastructure

### Key environment variables (from .env)

  NODE_ENV=production
  DOMAIN=forwardemail.example.com
  WEB_HOST=mail.example.com
  SMTP_HOST=smtp.example.com
  IMAP_HOST=imap.example.com
  # Database (SQLite for mailboxes, Redis for queue/cache)
  SQLITE_STORAGE_PATH=/mnt/storage/sqlite
  REDIS_URL=redis://localhost:6379
  # TLS
  LETSENCRYPT_DOMAIN=example.com

## Upgrade procedure

  git pull
  npm install
  # Restart all services (PM2 / systemd)
  pm2 restart all

## Gotchas

- **Bare metal strongly recommended**: email delivery requires stable IPs, working rDNS, and low latency. VPS/cloud works but shared IPs often have poor reputation. Upstream recommends dedicated servers.
- **Port 25 must be open**: many cloud providers block port 25 (inbound SMTP). Check with your provider before attempting self-hosting.
- **Reverse DNS (PTR) is critical**: without matching PTR record, outbound mail will be rejected by major providers (Gmail, Outlook).
- **Complex dependency stack**: Node.js 18 exact version, Redis, SQLite, system packages. Not a trivial setup.
- **License is BUSL-1.1**: the Business Source License restricts commercial use/competition with the hosted service. Self-hosting for personal/organizational use is permitted.
- **Encrypted mailboxes**: each alias has a passphrase-encrypted SQLite DB. Lost passphrase = lost mailbox. Back up both the SQLite files AND the passphrases.
- **Spam/blocklist risk**: new mail servers almost always start on blocklists. Plan for a warm-up period and register with major postmaster portals.

## References

- Upstream GitHub: https://github.com/forwardemail/forwardemail.net
- FAQ / docs: https://forwardemail.net/en/faq
- Self-hosted guide: https://forwardemail.net/en/blog/docs/best-email-service
- Hosted service: https://forwardemail.net
