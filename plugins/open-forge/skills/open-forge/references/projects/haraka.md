---
name: haraka
description: Haraka recipe for open-forge. Fast, scalable Node.js SMTP server with plugin architecture. Works as an MTA/MSA or filtering proxy in front of another mail store. Covers npm install and service configuration. Upstream: https://github.com/haraka/Haraka
---

# Haraka

Highly scalable Node.js SMTP server with a modular plugin architecture. Designed to handle thousands of concurrent SMTP connections and deliver thousands of messages per second. Used as a filtering MTA, outbound relay, or Mail Submission Agent (MSA).

5,565 stars · MIT

Upstream: https://github.com/haraka/Haraka
Website: https://haraka.github.io/
Docs: https://haraka.github.io/core/ReadMe

**Important scope note**: Haraka is an **SMTP server only** — it makes no attempt to be a mail store or IMAP server. It is typically used **alongside** a mail store like Dovecot/Postfix/Exchange, either as a filtering layer or outbound relay.

## What it is

Haraka is an SMTP platform for:

- **Filtering MTA** — Receives inbound SMTP, runs spam/virus checks via plugins, then forwards to a local mail store
- **Outbound relay** — Sends email to the internet with DKIM signing, rate limiting, and queue management
- **MSA** — Mail Submission Agent on port 587 with authentication
- **Plugin framework** — Write custom filtering logic in JavaScript/Node.js

### Key plugins

| Plugin | Purpose |
|---|---|
| `spamassassin` | SpamAssassin integration |
| `dkim_sign` | DKIM signing of outbound mail |
| `auth/flat_file` | User authentication (MSA mode) |
| `rcpt_to.routes` | Route delivery to different backends by recipient |
| `smtp_forward` | Forward accepted mail to another SMTP server |
| `karma` | Connection/transaction reputation scoring |
| `dns_list` | DNS blocklist checks |
| `helo.checks` | Validate HELO/EHLO hostname |

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| npm global install (recommended) | https://github.com/haraka/Haraka#installing-haraka | Standard — requires Node.js |
| Docker | Community images available | Containerized |

## Requirements

- Node.js 18+ (LTS recommended)
- npm
- Root or sufficient privileges to bind to port 25

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| domain | "Domain(s) to accept mail for?" | All |
| mode | "Filtering MTA (receive + forward), outbound relay, or MSA (port 587)?" | All |
| forward_host | "Forward accepted mail to which SMTP host:port?" | Filtering MTA mode |

## Install

### 1. Install Node.js

    # Using NodeSource (Debian/Ubuntu)
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs

    node --version  # should be 18+

### 2. Install Haraka globally

    npm install -g Haraka

    # Verify
    haraka --version

### 3. Create a Haraka instance directory

    haraka -i /etc/haraka

This creates `/etc/haraka/` with:

    /etc/haraka/
    ├── config/
    │   ├── host_list         # domains to accept mail for
    │   ├── plugins           # list of active plugins
    │   ├── smtp.ini          # listening ports/addresses
    │   └── smtp_forward.ini  # forwarding destination
    └── plugins/              # custom plugins

### 4. Configure domains (host_list)

    echo "example.org" >> /etc/haraka/config/host_list
    echo "other.org" >> /etc/haraka/config/host_list

### 5. Configure plugins

Edit `/etc/haraka/config/plugins` — one plugin per line:

    # Basic filtering MTA setup
    dns_list
    helo.checks
    mail_from.is_resolvable
    rcpt_to.in_host_list
    spamassassin
    smtp_forward

    # For outbound MSA (add auth, remove inbound-only plugins):
    # auth/flat_file
    # dkim_sign
    # queue/smtp_forward

### 6. Configure forwarding

If using `smtp_forward` plugin, edit `/etc/haraka/config/smtp_forward.ini`:

    [main]
    host=127.0.0.1
    port=2525

This forwards accepted mail to your local Postfix/Dovecot on port 2525.

### 7. Configure SMTP listener

Edit `/etc/haraka/config/smtp.ini`:

    [main]
    listen=0.0.0.0:25

    # For MSA mode (also listen on 587):
    # listen=0.0.0.0:25,0.0.0.0:587

### 8. Start Haraka

    # Foreground (for testing)
    haraka -c /etc/haraka

    # Background (production)
    haraka -c /etc/haraka &

### 9. systemd service

    cat > /etc/systemd/system/haraka.service << 'SVCEOF'
    [Unit]
    Description=Haraka SMTP Server
    After=network.target

    [Service]
    Type=simple
    ExecStart=/usr/bin/haraka -c /etc/haraka
    Restart=on-failure
    RestartSec=5
    # Haraka needs to bind port 25 — run as root or use authbind/setcap
    User=root

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable --now haraka

## DKIM signing (outbound)

Generate a DKIM key pair:

    openssl genrsa -out /etc/haraka/config/dkim/example.org/private 2048
    openssl rsa -in /etc/haraka/config/dkim/example.org/private -pubout \
      -out /etc/haraka/config/dkim/example.org/public

Add `dkim_sign` to plugins. Add to DNS:

    selector._domainkey.example.org  TXT  "v=DKIM1; k=rsa; p=<base64-public-key>"

## Upgrade

    npm install -g Haraka
    systemctl restart haraka

## Gotchas

- **Not a mail store** — Haraka does not deliver to local mailboxes or serve IMAP. It must forward to a mail store (Postfix+Dovecot, Exchange, Mailcow). This is by design.
- **Runs as root by default** — Binding port 25 requires root. For a non-root setup, use `authbind` or `setcap cap_net_bind_service+ep` on the Node binary.
- **Plugin order matters** — Plugins in `config/plugins` run in listed order. Put rejection/blocklist plugins early; expensive checks (SpamAssassin) later.
- **Node.js version** — Haraka requires Node.js 18+. Check `node --version` before installing. The system Node.js from `apt` on older Debian/Ubuntu may be too old.
- **smtp_forward vs queue** — `smtp_forward` is a delivery plugin; it forwards the message to another server. `queue/smtp_forward` is similar but uses the outbound queue for reliability. Use the queued version for production.
- **Logging** — Haraka logs to stdout by default. Use systemd journald or redirect to a file for persistent logs.

## Links

- GitHub: https://github.com/haraka/Haraka
- Website: https://haraka.github.io/
- Docs: https://haraka.github.io/core/ReadMe
- Plugin list: https://haraka.github.io/plugins/
- Configuration reference: https://haraka.github.io/core/Config
