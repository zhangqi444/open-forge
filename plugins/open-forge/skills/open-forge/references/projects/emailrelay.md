---
name: emailrelay
description: EmailRelay recipe for open-forge. Lightweight SMTP store-and-forward server with POP3 access. Policy-free design — uses external scripts for filtering, routing, and delivery. GPL-3.0, C++. Source: https://sourceforge.net/p/emailrelay/code/HEAD/tree/
---

# EmailRelay (E-MailRelay)

A lightweight, policy-free SMTP store-and-forward mail server with POP3 access to spooled messages. Designed to sit between email clients and an upstream SMTP relay. Non-blocking I/O (like nginx/Squid) — excellent scalability with minimal resource use. External scripts handle address validation, spam filtering, local delivery, and message processing. Runs on Linux and Windows. GPL-3.0, written in C++. Website: <https://emailrelay.sourceforge.net/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | Native binary (package or source) | Single process, minimal deps |
| Windows | Native exe | Runs as Windows service |
| Raspberry Pi / ARM | Build from source | Low resource footprint — good for embedded use |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Upstream smarthost?" | host:port | The relay server EmailRelay forwards to (e.g. your ISP's SMTP, SendGrid, etc.) |
| "Listen port?" | Number | Default 25 (or 587 for submission) |
| "TLS?" | Yes / No | TLS to/from upstream and/or clients |
| "POP3 access to spool?" | Yes / No | Allows mail clients to retrieve spooled messages |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Spam filter script?" | Script path | Optional — emailrelay calls script on receipt |
| "Delivery script?" | Script path | Optional — for local mailbox delivery |
| "Authentication?" | PLAIN / LOGIN / CRAM-MD5 | For client submission auth |

## Software-Layer Concerns

- **Policy-free design**: EmailRelay intentionally has no built-in spam filtering, bounce handling, or local delivery logic — these are delegated to external scripts you provide.
- **Store-and-forward**: Mail is spooled to disk (`--spool-dir`) first, then forwarded on schedule or demand. Two modes: `--as-server` (daemon) and `--as-client` (flush queue).
- **Spool directory**: Stores `.content` (message body) and `.envelope` (headers/metadata) files per message. Easy to inspect/manage.
- **External scripts**: `--filter` (per-message processing), `--client-filter` (outgoing filter), `--address-verifier` (RCPT validation). Scripts are called with the envelope file path as argument.
- **POP3 server**: Optional built-in POP3 server allows mail clients to retrieve spooled inbound messages.
- **Single binary**: One executable, minimal library dependencies, easy to deploy anywhere.
- **Config file**: `/etc/emailrelay.conf` on Unix — command-line options and file options are equivalent.

## Deployment

### Install from package (Debian/Ubuntu)

```bash
# Check SourceForge for latest release or build from source
# https://sourceforge.net/projects/emailrelay/files/

# Or build from source:
apt install libssl-dev libpam0g-dev
wget https://sourceforge.net/projects/emailrelay/files/emailrelay/emailrelay-2.6.1.tar.gz
tar xzf emailrelay-2.6.1.tar.gz && cd emailrelay-2.6.1
./configure && make && sudo make install
```

### Run as store-and-forward relay

```bash
# Start as daemon (store incoming mail, relay to smarthost)
emailrelay --as-server \
  --forward-to mail.isp.example.com:587 \
  --spool-dir /var/spool/emailrelay \
  --log --log-file /var/log/emailrelay.log \
  --port 25 \
  --tls-config=tlsv1.2 \
  --daemon

# Flush queue (deliver spooled mail to smarthost)
emailrelay --as-client mail.isp.example.com:587 \
  --spool-dir /var/spool/emailrelay
```

### Config file (`/etc/emailrelay.conf`)

```
as-server
forward-to mail.smarthost.example.com:587
spool-dir /var/spool/emailrelay
port 25
log
log-file /var/log/emailrelay.log
tls-config tlsv1.2
daemon
pid-file /run/emailrelay.pid
```

### systemd service

```ini
[Unit]
Description=EmailRelay SMTP server
After=network.target

[Service]
ExecStart=/usr/local/sbin/emailrelay --config /etc/emailrelay.conf
Restart=on-failure
User=emailrelay

[Install]
WantedBy=multi-user.target
```

### SpamAssassin filter script example

```bash
#!/bin/bash
# /etc/emailrelay/spam-filter.sh — called with envelope path as $1
spamassassin < "$1.content" > /tmp/sa-out.txt 2>/dev/null
if grep -q "^X-Spam-Status: Yes" /tmp/sa-out.txt; then
  exit 1  # reject
fi
exit 0  # accept
```

## Upgrade Procedure

1. Download new release from SourceForge.
2. Stop service, replace binary, restart.
3. Spool directory and config persist across upgrades.

## Gotchas

- **Policy-free means scripting required**: If you want spam filtering or local delivery, you must write the filter scripts. EmailRelay won't do this for you.
- **Not a full MTA**: EmailRelay doesn't do MX lookups, bounce handling, or local mailbox management by default — it's a relay/forwarder.
- **Port 25**: ISPs and VPS providers often block outbound port 25 — use port 587 to smarthost.
- **Spool inspection**: Each message = two files in `--spool-dir`: `.envelope` (metadata) and `.content` (body). Deleting both removes the message.
- **Script exit codes**: Filter scripts signal accept (0), reject (1), or requeue (2) via exit code.

## Links

- Website: https://emailrelay.sourceforge.net/
- User Guide: https://emailrelay.sourceforge.net/userguide.html
- SourceForge downloads: https://sourceforge.net/projects/emailrelay/files/
- Reference manual: https://emailrelay.sourceforge.net/reference.html
