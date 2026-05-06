---
name: cyrus-imap
description: Cyrus IMAP recipe for open-forge. Enterprise-grade IMAP/POP3/JMAP email, CalDAV/CardDAV, and NNTP server designed for sealed server deployments with high scalability and ACL-based access control. Source: https://github.com/cyrusimap/cyrus-imapd
---

# Cyrus IMAP

Enterprise-grade mail server providing IMAP, POP3, JMAP, CalDAV, CardDAV, and NNTP protocols. Designed for "sealed server" deployments where users do not log in directly — all access is via protocols. Offers multi-concurrent-connection mailboxes, ACL-based access control, storage quotas, and high scalability. Used at large universities and enterprises. Upstream: https://github.com/cyrusimap/cyrus-imapd. Docs: https://www.cyrusimap.org/imap/.

Note: Cyrus IMAP is a powerful but complex MDA (Mail Delivery Agent). It handles mail storage and access, not sending — pair with a MTA (Postfix, Exim) for full email service.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| APT packages | Debian / Ubuntu | Recommended. `apt-get install cyrus-imapd` from official repos. |
| Source build | Linux | For custom features. See upstream docs for build deps. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Server hostname/FQDN?" | Used in Cyrus config and TLS certificate |
| auth | "SASL authentication method?" | Default: PAM or LDAP. Determines how users authenticate |
| storage | "Mail spool path?" | Default: /var/spool/cyrus — where mailboxes are stored |
| tls | "TLS certificate paths?" | Cert + key for IMAPS/POPS (ports 993/995) |

## Software-layer concerns

### APT install (Debian/Ubuntu)

  apt-get update
  apt-get install cyrus-imapd cyrus-admin cyrus-clients

  # cyrus-imapd: the core IMAP/POP server
  # cyrus-admin: cyradm management tool
  # cyrus-clients: command-line test clients

### Key configuration file: /etc/imapd.conf

  # Hostname
  servername: mail.example.com

  # Admin users (can use cyradm to manage mailboxes)
  admins: cyrus

  # SASL auth method (authenticate against system PAM users)
  sasl_mech_list: PLAIN LOGIN
  sasl_pwcheck_method: saslauthd
  allowplaintext: yes  # set to no in production with TLS

  # Mail storage
  partition-default: /var/spool/cyrus/mail
  configdirectory: /var/lib/cyrus

  # TLS (for IMAPS port 993)
  tls_cert_file: /etc/ssl/certs/mail.example.com.crt
  tls_key_file: /etc/ssl/private/mail.example.com.key

### Key configuration file: /etc/cyrus.conf

Defines which services run. Default enables:
  - imap (port 143)
  - imaps (port 993, TLS)
  - pop3 (port 110)
  - pop3s (port 995, TLS)
  - lmtpd (port 24 or socket — for MTA delivery)
  - sieve (port 4190 — mail filtering scripts)

### Starting/managing Cyrus

  systemctl enable cyrus-imapd
  systemctl start cyrus-imapd

### Creating mailboxes (cyradm)

  # Log in as Cyrus admin
  cyradm --user cyrus localhost

  # In cyradm prompt:
  cm user/alice@example.com      # create mailbox for user alice
  lm                              # list mailboxes
  setquota user/alice 102400      # set 100MB quota

### MTA integration (Postfix → Cyrus via LMTP)

  # In Postfix main.cf:
  mailbox_transport = lmtp:unix:/var/run/cyrus/socket/lmtp

  # Cyrus must be configured with lmtpd socket in cyrus.conf:
  lmtpunix      cmd="lmtpd" listen="/var/run/cyrus/socket/lmtp" prefork=1

### CalDAV/CardDAV

  # Enable httpd service in cyrus.conf:
  httpd        cmd="httpd" listen="8080" prefork=1

  # Enable in imapd.conf:
  httpmodules: caldav carddav

  # CalDAV available at http://mail.example.com:8080/dav/

## Upgrade procedure

  apt-get update && apt-get upgrade cyrus-imapd
  systemctl restart cyrus-imapd

## Gotchas

- **Sealed server model**: regular OS users do not need to exist for Cyrus mailboxes. Authentication is handled by SASL (PAM, LDAP, etc.) separately.
- **cyrus system user**: Cyrus runs as the `cyrus` Unix user. The cyrus user is NOT the admin account — the admin is configured via `admins:` in imapd.conf.
- **LMTP for delivery**: Cyrus does not receive mail from the internet directly. A MTA (Postfix, Exim) must deliver via LMTP to Cyrus. Configure the MTA's transport.
- **saslauthd must be running**: for PAM-based auth, saslauthd daemon must be active. Check: `systemctl status saslauthd`.
- **TLS required for plain auth**: SASL PLAIN sends passwords in the clear. Always use TLS (IMAPS port 993) in production.
- **cyradm for mailbox management**: mailboxes must be created explicitly with cyradm or the Cyrus admin API — they are not auto-created on first login by default.
- **JMAP support**: Cyrus 3.x supports JMAP (modern JSON email API). Enable httpd with the jmap module for JMAP access.

## References

- Upstream GitHub: https://github.com/cyrusimap/cyrus-imapd
- Documentation: https://www.cyrusimap.org/imap/
- Installation guide: https://www.cyrusimap.org/imap/download/installation/
- CalDAV/CardDAV: https://www.cyrusimap.org/caldav/
- JMAP: https://www.cyrusimap.org/jmap/
