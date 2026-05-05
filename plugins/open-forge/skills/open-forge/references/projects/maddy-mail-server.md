---
name: maddy-mail-server
description: Maddy Mail Server recipe for open-forge. All-in-one mail server in Go — replaces Postfix+Dovecot+OpenDKIM+OpenSPF+OpenDMARC with a single daemon. Binary tarball + systemd install. Upstream: https://github.com/foxcpp/maddy
---

# Maddy Mail Server

All-in-one composable mail server written in Go. Implements SMTP (MTA + MX) and IMAP in a single daemon with a unified configuration file. Replaces the traditional Postfix + Dovecot + OpenDKIM + OpenSPF + OpenDMARC stack.

5,953 stars · GPL-3.0

Upstream: https://github.com/foxcpp/maddy
Website: https://maddy.email/
Setup tutorial: https://maddy.email/tutorials/setting-up/
Documentation: https://maddy.email/

**IMAP storage note**: Maddy's IMAP storage is described as "beta." For a production mail server requiring stable, feature-complete IMAP, the upstream docs suggest considering Dovecot for storage. Maddy's SMTP/MTA side is stable.

## What it is

Maddy handles the full email server stack:

- **MX (inbound SMTP)** — Receives email for your domain from the internet
- **MTA (outbound SMTP)** — Sends email from your users to the internet
- **IMAP server** — Users access their mailboxes via any IMAP client
- **DKIM** — Signs outgoing messages with your domain key
- **SPF** — Validates SPF records on inbound mail
- **DMARC** — Enforces DMARC policy
- **DANE / MTA-STS** — TLS verification for inbound/outbound SMTP
- **Authentication** — Local user accounts with password management

Single binary, single config file — no separate daemons for each protocol.

## Prerequisites (critical)

Running a mail server requires DNS and network prerequisites:

1. **A VPS with port 25 unblocked** — Many VPS/cloud providers block port 25. Confirm with your provider before attempting. (Google Cloud, Oracle Cloud block it; Hetzner, Vultr, DigitalOcean typically allow it.)
2. **A domain you control** — With ability to set MX, A, TXT (DKIM/SPF/DMARC) records
3. **Reverse DNS (PTR) record** — Your VPS IP must have a PTR record pointing to your mail hostname (e.g., `mx1.example.org`). Set via your VPS provider's control panel.
4. **Dedicated server/VPS** — Do not share with other mail servers.

## Required DNS records

| Record | Type | Value |
|---|---|---|
| `example.org` | MX | `10 mx1.example.org.` |
| `mx1.example.org` | A | `<YOUR_SERVER_IP>` |
| `mx1.example.org` | AAAA | `<YOUR_SERVER_IPv6>` (if available) |
| `example.org` | TXT | `v=spf1 mx ~all` |
| `_dmarc.example.org` | TXT | `v=DMARC1; p=none; rua=mailto:dmarc@example.org` |
| DKIM selector | TXT | (generated during setup — see below) |
| PTR | PTR | `mx1.example.org` (set at VPS provider) |

## Compatible install methods

| Method | Upstream | When to use |
|---|---|---|
| Pre-built tarball (recommended) | https://github.com/foxcpp/maddy/releases | Linux amd64 — simplest |
| Docker | `docker pull foxcpp/maddy:0.6` | Containerized (extra config needed for ports) |
| Build from source | https://maddy.email/tutorials/building-from-source/ | Other architectures |
| Arch Linux AUR | `maddy` or `maddy-git` | Arch Linux |

## Inputs to collect

| Phase | Prompt | Applicability |
|---|---|---|
| hostname | "Mail server hostname (MX record)? e.g., mx1.example.org" | All |
| domain | "Primary mail domain? e.g., example.org" | All |
| server_ip | "Server's public IPv4 address?" | All |

## Binary tarball install (recommended)

Upstream tutorial: https://maddy.email/tutorials/setting-up/

### 1. Download and install

    # Check latest version at https://github.com/foxcpp/maddy/releases
    VERSION=0.7.0

    wget "https://github.com/foxcpp/maddy/releases/download/v${VERSION}/maddy-${VERSION}-x86_64-linux-musl.tar.zst"
    tar xf maddy-${VERSION}-x86_64-linux-musl.tar.zst
    cd maddy-${VERSION}-x86_64-linux-musl/

    # Install binary
    sudo cp maddy /usr/local/bin/
    sudo chmod +x /usr/local/bin/maddy

    # Install systemd unit files
    sudo cp systemd/*.service /etc/systemd/system/
    sudo systemctl daemon-reload

    # Create maddy user (maddy never runs as root)
    sudo useradd -mrU -s /sbin/nologin -d /var/lib/maddy -c "maddy mail server" maddy

    # Install default config
    sudo mkdir -p /etc/maddy
    sudo cp maddy.conf /etc/maddy/

### 2. Configure maddy.conf

Edit `/etc/maddy/maddy.conf`. Change the hostname and domain:

    $(hostname) = mx1.example.org
    $(primary_domain) = example.org

For multiple domains, update `local_domains`:

    $(local_domains) = $(primary_domain) other.org

### 3. Set up TLS certificates (Let's Encrypt recommended)

Maddy needs TLS certificates for SMTP and IMAP. Use Certbot or acme.sh to obtain certificates for `mx1.example.org`.

    # Using certbot (standalone, one-time)
    certbot certonly --standalone -d mx1.example.org

    # Copy certificates to maddy's expected location
    sudo install -m 644 /etc/letsencrypt/live/mx1.example.org/fullchain.pem /etc/maddy/certs/
    sudo install -m 600 /etc/letsencrypt/live/mx1.example.org/privkey.pem /etc/maddy/certs/
    sudo chown -R maddy:maddy /etc/maddy/certs/

Update `/etc/maddy/maddy.conf` to point to certificates:

    tls file /etc/maddy/certs/fullchain.pem /etc/maddy/certs/privkey.pem

### 4. Start maddy

    sudo systemctl enable --now maddy

### 5. Generate DKIM key and add DNS record

    sudo maddy dkim gen default example.org

This generates a DKIM key and prints the DNS TXT record value to add. Add it to your DNS:

    default._domainkey.example.org  TXT  "v=DKIM1; k=rsa; p=<key>"

### 6. Create user accounts

    # Add a user
    sudo maddy creds create user@example.org

    # Set password
    sudo maddy creds passwd user@example.org

    # Create IMAP mailbox for the user
    sudo maddy imap-acct create user@example.org

## Ports used

| Port | Protocol | Service |
|---|---|---|
| 25 | TCP | SMTP (inbound MX — internet to your server) |
| 465 | TCP | SMTPS (outbound submission with implicit TLS) |
| 587 | TCP | SMTP submission (outbound with STARTTLS) |
| 993 | TCP | IMAPS (IMAP with implicit TLS) |
| 143 | TCP | IMAP with STARTTLS |

Open all with your firewall:

    ufw allow 25/tcp
    ufw allow 465/tcp
    ufw allow 587/tcp
    ufw allow 993/tcp

## Upgrade

    # Download new release tarball, copy new binary over old
    sudo cp maddy /usr/local/bin/
    sudo systemctl restart maddy

## Gotchas

- **Port 25 is commonly blocked** — Verify your VPS provider allows outbound port 25 before setup. No workaround if blocked.
- **PTR (reverse DNS) is mandatory** — Most receiving mail servers reject mail from IPs without a matching PTR record. Set via your VPS control panel.
- **IMAP is beta** — The upstream docs note IMAP storage is in beta. For production use where IMAP stability is critical, test thoroughly first.
- **Certificate renewal** — Let's Encrypt certs expire every 90 days. Set up auto-renewal (`certbot renew`) and reload maddy after renewal: `systemctl reload maddy`.
- **Never run as root** — Maddy's design explicitly avoids root. The `maddy` system user must own `/var/lib/maddy` and `/etc/maddy/certs/`.
- **DNSSEC-validating resolver recommended** — For DANE support (TLS verification of outbound SMTP), run a local DNSSEC-validating resolver (Unbound or systemd-resolved with DNSSEC).
- **New project** — Maddy is relatively young compared to Postfix/Dovecot. Expect occasional rough edges. Check GitHub issues for known problems before deploying.

## Links

- GitHub: https://github.com/foxcpp/maddy
- Website: https://maddy.email/
- Setup tutorial: https://maddy.email/tutorials/setting-up/
- Full documentation: https://maddy.email/
- Releases: https://github.com/foxcpp/maddy/releases
- Docker guide: https://maddy.email/docker/
