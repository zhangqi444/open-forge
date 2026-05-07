---
name: chasquid
description: chasquid recipe for open-forge. SMTP email server focused on simplicity, security, and ease of operation. Go, Apache-2.0. Source: https://blitiri.com.ar/p/chasquid/
---

# chasquid

An SMTP email server with a focus on simplicity, security, and ease of operation. Supports multiple domains, TLS (STARTTLS + TLS-on-connect), SMTP AUTH, SPF checking, DKIM (via milter), Dovecot integration for IMAP, and Prometheus metrics. Apache-2.0 licensed, written in Go. Packaged for Debian, Ubuntu, Alpine, and Arch. Upstream: <https://blitiri.com.ar/p/chasquid/>. Docs: <https://blitiri.com.ar/p/chasquid/docs/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian / Ubuntu | APT package | `apt install chasquid` — simplest install |
| Alpine Linux | APK package | `apk add chasquid` (testing repo) |
| Arch Linux | AUR package | `pacaur -S chasquid` |
| Any Linux | Build from source | Requires Go toolchain |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Mail domain(s)?" | FQDN(s) | e.g. example.com — creates domains/ structure |
| "Hostname for the MX record?" | FQDN | e.g. mx.example.com |
| "TLS certificate source?" | certbot / manual | Certbot layout matches chasquid certs/ dir structure |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Users to create?" | user@domain list | Added via `chasquid-util user-add` |
| "Deliver locally or relay to Dovecot?" | local / dovecot | LMTP delivery to Dovecot for IMAP access |
| "DKIM signing?" | Yes / No | Via milter integration (e.g. OpenDKIM) |

## Software-Layer Concerns

- **Config structure** (`/etc/chasquid/`):
  - `chasquid.conf` — main config
  - `domains/<domain>/users` — username/password DB
  - `domains/<domain>/aliases` — alias mappings
  - `certs/<hostname>/fullchain.pem` + `privkey.pem` — TLS certs
- **Certbot integration**: `certs/` layout matches `/etc/letsencrypt/live/` — symlink: `sudo ln -s /etc/letsencrypt/live/ /etc/chasquid/certs`; grant read permissions via ACL.
- **SMTP AUTH**: chasquid handles auth natively using the `users` database file per domain.
- **LMTP / Dovecot**: For IMAP access, configure chasquid to deliver via LMTP to Dovecot.
- **SPF**: Built-in SPF checking for inbound mail.
- **DKIM**: Not built-in — use a milter (OpenDKIM, rspamd) for DKIM signing.
- **Prometheus metrics**: Exposes metrics endpoint for monitoring.
- **chasquid-util**: CLI tool for user management, config validation, and debugging.

## Deployment

### Debian/Ubuntu

```bash
apt install chasquid

# Create domain directory and add users
chasquid-util user-add user@example.com
# (prompts for password)

# Symlink certbot certs
ln -s /etc/letsencrypt/live/ /etc/chasquid/certs
setfacl -R -m u:chasquid:rX /etc/letsencrypt/{live,archive}

# Validate config
chasquid-util print-config

systemctl enable --now chasquid
```

### DNS records required

```
# MX record
example.com.  IN MX 10 mx.example.com.

# SPF
example.com.  IN TXT "v=spf1 mx ~all"

# DKIM (via OpenDKIM or similar)
mail._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=..."

# DMARC
_dmarc.example.com. IN TXT "v=DMARC1; p=none; rua=mailto:dmarc@example.com"
```

### chasquid.conf (minimal example)

```
hostname: "mx.example.com"
max_data_size_mb: 50
smtp_address: ":25"
submission_address: ":587"
submission_over_tls_address: ":465"
monitoring_address: ":1099"
mail_delivery_agent_bin: "maildrop"  # or dovecot LMTP
```

## Upgrade Procedure

1. APT: `apt upgrade chasquid` — config files in `/etc/chasquid/` preserved.
2. Source: `git pull`, `make`, `sudo make install-binaries`, restart service.
3. Check release notes at https://blitiri.com.ar/p/chasquid/ for config changes.

## Gotchas

- **Certbot ACL**: Without `setfacl`, chasquid can't read Let's Encrypt private keys — TLS will fail.
- **Port 25 requires root or CAP_NET_BIND_SERVICE**: The APT package handles this via systemd capabilities. Source installs may need `setcap cap_net_bind_service=+ep /usr/local/bin/chasquid`.
- **DKIM not built-in**: Use OpenDKIM, rspamd, or Postal for DKIM signing — chasquid connects via milter protocol.
- **No web UI**: chasquid is CLI-configured and managed. Use `chasquid-util` for user/domain management.
- **Alias format**: The `aliases` file uses a simple `alias: destination` format — see upstream docs for full syntax.

## Links

- Website: https://blitiri.com.ar/p/chasquid/
- Docs: https://blitiri.com.ar/p/chasquid/docs/
- Install guide: https://blitiri.com.ar/p/chasquid/install/
- Source (Gitiles): https://blitiri.com.ar/git/r/chasquid/
- How-to guides: https://blitiri.com.ar/p/chasquid/howto/
