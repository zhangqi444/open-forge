---
name: exim
description: Exim recipe for open-forge. Battle-tested message transfer agent (MTA) developed at University of Cambridge. Highly configurable SMTP server. GPL-3.0, C. Source: https://git.exim.org/exim.git
---

# Exim

A battle-tested, highly configurable Message Transfer Agent (MTA) developed at the University of Cambridge. The default MTA on Debian-based systems. Handles SMTP relay, routing, filtering, and delivery with an extremely flexible ACL-based configuration system. GPL-3.0 licensed, written in C. Used extensively by ISPs and enterprises. Upstream: <https://www.exim.org/>. Spec: <https://www.exim.org/exim-html-current/doc/html/spec_html/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian / Ubuntu | APT (exim4) | Default MTA — ships pre-installed |
| CentOS / RHEL | RPM or source | Available in EPEL |
| Any Linux | Build from source | tarball from exim.org |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Mail domain?" | FQDN | Primary domain for which Exim accepts mail |
| "Relay or local delivery?" | Relay / Local / Both | Exim's main mode of operation |
| "TLS certificate paths?" | PEM file paths | Let's Encrypt recommended |
| "Local users get mailboxes?" | Yes / No | Whether Exim delivers to local system users |
| "Smart host (relay via external SMTP)?" | host:port | Optional — route outbound through upstream SMTP relay |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Authentication (SMTP AUTH)?" | PLAIN / LOGIN / CRAM-MD5 | For client submission — port 587 |
| "DKIM signing?" | Yes / No | Recommended for deliverability |
| "SPF/DMARC checks on inbound?" | Yes / No | Recommended — requires spf-tools-perl / opendmarc |

## Software-Layer Concerns

- **Single large config file**: Exim's `exim4.conf` (or Debian's split `conf.d/`) is highly flexible but complex. The spec document is the definitive reference.
- **Debian split config**: Debian/Ubuntu use `update-exim4.conf` with a directory of fragment files — simpler for common setups, but reading the generated `exim4.conf.conf` is helpful for debugging.
- **ACLs (Access Control Lists)**: Exim uses ACLs at each SMTP phase (connect, HELO, MAIL, RCPT, DATA) to accept/reject/defer messages. This is where spam filtering hooks live.
- **Router + Transport model**: Routing rules determine where to send mail; transports determine how. This two-stage model makes Exim very flexible for complex routing.
- **Spool directory**: `/var/spool/exim4/` — stores queued messages. Must have adequate disk space.
- **DNS requirements**: MX, PTR (rDNS), SPF, DKIM, DMARC records essential for outbound deliverability.
- **Port 25 blocking**: VPS providers commonly block outbound port 25 — request unblocking.
- **Maildir vs mbox**: Exim can deliver to either format — configure in transport definition.

## Deployment

### Debian/Ubuntu (exim4)

```bash
sudo apt install exim4-daemon-heavy

# Interactive configuration wizard
sudo dpkg-reconfigure exim4-config
# Choose: internet site (direct delivery) or satellite site (relay via smart host)
# Set: system mail name, allowed relay IPs, other destinations

# View/edit generated config
sudo cat /etc/exim4/update-exim4.conf.conf

# Regenerate and restart
sudo update-exim4.conf
sudo systemctl restart exim4
```

### Enable TLS

```bash
# Copy Let's Encrypt certs
cp /etc/letsencrypt/live/mail.example.com/fullchain.pem /etc/exim4/exim.crt
cp /etc/letsencrypt/live/mail.example.com/privkey.pem /etc/exim4/exim.key
chown root:Debian-exim /etc/exim4/exim.{crt,key}
chmod 640 /etc/exim4/exim.{crt,key}
```

Add to exim4 config:
```
tls_certificate = /etc/exim4/exim.crt
tls_privatekey = /etc/exim4/exim.key
tls_advertise_hosts = *
```

### DKIM signing (outbound)

```bash
# Generate key
openssl genrsa -out /etc/exim4/dkim-example.com.key 2048
openssl rsa -in /etc/exim4/dkim-example.com.key -pubout > /tmp/dkim.pub

# Add DNS TXT record: mail._domainkey.example.com → public key

# Exim transport config (add to smtp transport):
# dkim_domain = example.com
# dkim_selector = mail
# dkim_private_key = /etc/exim4/dkim-example.com.key
```

### Mail queue management

```bash
exim -bp              # show queue
exim -qff             # force queue run
exim -Mrm <message-id>  # remove from queue
exigrep pattern /var/log/exim4/mainlog  # search logs
```

## Upgrade Procedure

1. APT: `sudo apt update && sudo apt upgrade exim4` — config preserved.
2. Check https://www.exim.org/exim-html-current/doc/html/spec_html/ch-upgrading_exim.html for migration notes.
3. Test with `exim -bV` (version check) and send a test email.

## Gotchas

- **Complex config**: Exim's power comes at the cost of configuration complexity. Start with `dpkg-reconfigure exim4-config` on Debian; avoid hand-editing the full spec config until comfortable.
- **Port 25 blocking**: VPS providers block outbound port 25 by default — contact support to unblock.
- **DNS PTR record**: Your server's IP must have a PTR (reverse DNS) record matching your mail hostname, or major mail providers will reject outbound mail.
- **Queue buildup**: Monitor `/var/spool/exim4/` — a misconfigured relay or spam situation can fill disk rapidly.
- **`exim4-daemon-heavy` vs `light`**: Use `heavy` for ACL-based spam filtering, DKIM, and routing flexibility. `light` is for simple mail relay only.
- **Panic log**: `/var/log/exim4/paniclog` — if this file is non-empty, Exim has a serious configuration error. Check this first when debugging.

## Links

- Website: https://www.exim.org/
- Specification (full docs): https://www.exim.org/exim-html-current/doc/html/spec_html/
- Source: https://git.exim.org/exim.git
- GitHub mirror: https://github.com/Exim/exim
- Debian wiki: https://wiki.debian.org/Exim
