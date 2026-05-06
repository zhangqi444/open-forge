---
name: opensmtpd
description: Recipe for OpenSMTPD — a free, secure, portable SMTP server from the OpenBSD project. Package-manager install (Linux/BSD) or source build.
---

# OpenSMTPD

Free, portable implementation of the server-side SMTP protocol (RFC 5321) from the OpenBSD project. Designed for security, simplicity, and correctness. Supports TLS, virtual domains, aliases, relaying, filters, and local mail delivery. Widely available in Linux and BSD package repositories. Upstream: <https://github.com/OpenSMTPD/OpenSMTPD>. Website: <https://opensmtpd.org/>.

License: ISC. Platform: Linux, BSD, macOS. Latest stable: 7.8.0p1. Package-manager install preferred over Docker.

> **Note**: OpenSMTPD does not have an official Docker image. It is primarily installed via system package managers. This recipe covers package-manager and source installs.

## Compatible install methods

| Method | When to use |
|---|---|
| Package manager (apt/apk/yum) | Recommended — most distributions ship OpenSMTPD |
| Source build | When you need the latest version not yet in distro repos |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| domain | "Mail domain (e.g. example.com)?" | Used in `smtpd.conf` |
| relay | "Relay all mail outbound, or accept mail for local delivery?" | Most VPS setups relay through a smarthost |
| tls | "TLS certificate and key paths?" | Required for production; use Let's Encrypt |
| users | "Local Unix users or virtual aliases?" | `aliases` file or `virtuals` table |

## Installation by platform

### Debian / Ubuntu

```bash
sudo apt update && sudo apt install opensmtpd
```

### Alpine Linux

```bash
apk add opensmtpd
```

### Fedora / CentOS / RHEL

```bash
yum install opensmtpd
# or
dnf install opensmtpd
```

### openSUSE Tumbleweed

```bash
zypper install OpenSMTPD
```

### Arch Linux

See [Arch Wiki — OpenSMTPD](https://wiki.archlinux.org/index.php/OpenSMTPD#Installation)

### macOS (MacPorts)

```bash
port install opensmtpd
```

## Configuration (`/etc/smtpd/smtpd.conf`)

Minimal example — accept local mail and relay outbound via smarthost:

```
# PKI (TLS certificate)
pki mail.example.com cert "/etc/ssl/example.com.fullchain.pem"
pki mail.example.com key  "/etc/ssl/private/example.com.key"

# Tables
table aliases file:/etc/smtpd/aliases

# Listeners
listen on lo
listen on eth0 tls pki mail.example.com

# Rules
action "local"   mbox alias <aliases>
action "relay"   relay

match from local for local action "local"
match from any   for domain "example.com" action "local"
match from local for any    action "relay"
```

### Relay through smarthost (e.g. SendGrid, Mailgun)

```
table credentials { "smtp.sendgrid.net" = "apikey:YOUR_SENDGRID_API_KEY" }

action "outbound" relay host smtp+tls://apikey@smtp.sendgrid.net:587 \
    auth <credentials>

match from local for any action "outbound"
```

## Start / enable

```bash
# systemd
sudo systemctl enable --now smtpd

# OpenRC (Alpine)
rc-update add smtpd default
rc-service smtpd start
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Config file | `/etc/smtpd/smtpd.conf` (Debian: `/etc/opensmtpd/smtpd.conf`) |
| Aliases | `/etc/smtpd/aliases` — local user aliases |
| Virtuals | `/etc/smtpd/virtuals` — virtual domain mappings |
| Mail queue | `/var/spool/smtpd/` |
| Logs | `syslog` / `journald` — filter with `grep smtpd /var/log/mail.log` |
| SMTP ports | `25` (inbound MX), `587` (submission), `465` (SMTPS) |
| MTA-STS / DKIM | Not built-in — use `opensmtpd-filter-dkimsign` package for DKIM signing |

## Upgrade procedure

```bash
# Package manager upgrade
sudo apt update && sudo apt upgrade opensmtpd
sudo systemctl restart smtpd
```

For source upgrades, build from the new release tarball and replace the binary.

## Gotchas

- **Distro packages may be old**: Some distributions ship OpenSMTPD versions that lag the upstream by months or years. The upstream GitHub warns that security fixes may not be backported. Check your distro's version: `smtpd -V`.
- **Config syntax changed in 6.6**: OpenSMTPD 6.6+ introduced a completely new configuration syntax. Configs from older versions will not work. Do not copy old tutorials without checking the version.
- **DKIM signing not built-in**: OpenSMTPD does not include DKIM signing. Install the `opensmtpd-filter-dkimsign` package or use a third-party filter.
- **Port 25 blocked on most VPS**: Cloud providers (AWS, GCP, Azure, Hetzner) block outbound port 25 to prevent spam. You must relay outbound mail through a smarthost (SendGrid, Mailgun, Postmark, etc.).
- **No web UI**: OpenSMTPD is a pure command-line/config-file MTA. There is no web interface.
- **smtpctl for management**: Use `smtpctl show queue`, `smtpctl show stats`, and `smtpctl schedule all` to manage the mail queue.

## Upstream links

- Source: <https://github.com/OpenSMTPD/OpenSMTPD>
- Website: <https://opensmtpd.org/>
- Manual pages: <https://opensmtpd.org/manual.html>
- Wiki (mail server guide): <https://github.com/OpenSMTPD/OpenSMTPD/wiki>
- Portable project info: <https://opensmtpd.org/portable.html>
