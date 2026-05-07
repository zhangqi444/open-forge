---
name: postfix
description: Postfix recipe for open-forge. Fast, easy-to-administer, and secure Sendmail replacement. The de facto standard MTA on Linux. IPL-1.0 licensed. Source: http://www.postfix.org/
---

# Postfix

The de facto standard Linux mail transfer agent (MTA). Fast, secure, and easy to administer. Replaces Sendmail with a modular, drop-in architecture. Powers outbound SMTP for millions of Linux servers, from single-app notification mail to full-featured mail servers. IPL-1.0 licensed. Source: <http://www.postfix.org/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Any Linux | System package (deb/rpm) | Preferred — tight OS integration |
| Docker | Docker Compose | Possible but less common for production |

> Postfix is almost always deployed as a system package. Docker is used mainly for isolated testing or sidecars.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Hostname (FQDN)?" | FQDN | e.g. mail.example.com — used in HELO/banner |
| "Mail domain?" | Domain | e.g. example.com |
| "Role: relay-only or full mail server?" | Choice | Relay = only sends outbound for local apps |
| "TLS cert path?" | Path | e.g. /etc/letsencrypt/live/mail.example.com/ |
| "Relay host (if using upstream SMTP)?" | host:port | e.g. [smtp.sendgrid.net]:587 |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "SASL credentials?" | user:pass | Needed if relaying through upstream provider |
| "mynetworks?" | CIDR list | e.g. 127.0.0.1/8, 10.0.0.0/8 |

## Software-Layer Concerns

- **main.cf**: Primary config file — all key settings live here.
- **master.cf**: Service definitions — controls which daemons run (smtpd, smtp, lmtp, etc.).
- **myhostname**: Must be the FQDN of the server — affects HELO and bounce handling.
- **mydomain**: The domain for which Postfix accepts mail (if acting as destination MTA).
- **mynetworks**: Hosts allowed to relay without authentication — keep tight.
- **TLS**: Use `smtpd_tls_cert_file` / `smtpd_tls_key_file` for inbound TLS; `smtp_tls_security_level = may` for opportunistic outbound TLS.
- **SASL auth**: `libsasl2-modules` + `sasl2-bin` required for SMTP AUTH; or use `postfix-sasl` package.
- **Relay credentials**: Store in `/etc/postfix/sasl_passwd`, then `postmap /etc/postfix/sasl_passwd`.
- **Virtual domains/mailboxes**: Requires `virtual_mailbox_domains`, `virtual_mailbox_base`, and a delivery agent (Dovecot LMTP or `virtual`).
- **SPF/DKIM/DMARC**: Postfix itself handles delivery only — use OpenDKIM + OpenDMARC sidecar daemons for signing/policy.
- **Bounce handling**: `notify_classes = bounce, resource, software` controls who gets bounce notifications.

## Deployment

### 1. Install

```bash
apt install postfix postfix-pcre libsasl2-modules

# During debconf: choose "Internet Site" for full MTA, "Satellite" for relay-only
```

### 2. Basic relay-only configuration (sending app notifications only)

```bash
# /etc/postfix/main.cf
myhostname = app.example.com
myorigin = /etc/mailname
mydestination = localhost
relayhost = [smtp.sendgrid.net]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
```

```bash
# /etc/postfix/sasl_passwd
[smtp.sendgrid.net]:587  apikey:SG.xxxxxxxxxxxxxxxx
```

```bash
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
systemctl restart postfix
```

### 3. Full inbound+outbound MTA (with TLS)

```bash
# /etc/postfix/main.cf additions
smtpd_tls_cert_file = /etc/letsencrypt/live/mail.example.com/fullchain.pem
smtpd_tls_key_file = /etc/letsencrypt/live/mail.example.com/privkey.pem
smtpd_use_tls = yes
smtpd_tls_security_level = may
smtp_tls_security_level = may
```

```bash
systemctl enable --now postfix
```

### 4. Test

```bash
echo "Test" | mail -s "Test" user@example.com
mailq           # check queue
journalctl -u postfix -f  # watch logs
```

## Upgrade Procedure

1. `apt upgrade postfix` — Postfix is backwards-compatible; config rarely breaks.
2. Review `/usr/share/doc/postfix/changelog.Debian.gz` for notes.
3. `postfix check` — validates config before reload.
4. `systemctl reload postfix`

## Gotchas

- **`postmap` after every hash file change**: Virtual maps, sasl_passwd, access tables — all need `postmap` re-run after edits.
- **myhostname must resolve forward and reverse**: PTR record must match myhostname or many receiving servers will reject mail.
- **Never put sasl_passwd in /etc without chmod 600**: Contains SMTP credentials in plaintext.
- **mydestination vs virtual_mailbox_domains**: A domain can't be in both — `mydestination` is for local Unix delivery, `virtual_mailbox_domains` is for virtual mailboxes.
- **DKIM requires OpenDKIM**: Postfix alone does not sign messages; install `opendkim` and `opendkim-tools` separately.
- **Debian split config**: Debian/Ubuntu have a `conf.d/` style config via `postfix-main` debconf — use `postconf -e` for safe edits rather than direct file editing.

## Links

- Website: http://www.postfix.org/
- Documentation: http://www.postfix.org/documentation.html
- Basic config guide: http://www.postfix.org/BASIC_CONFIGURATION_README.html
- TLS readme: http://www.postfix.org/TLS_README.html
- SASL auth: http://www.postfix.org/SASL_README.html
