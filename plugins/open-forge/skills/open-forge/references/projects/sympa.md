---
name: sympa
description: Sympa recipe for open-forge. Electronic mailing list manager. Automates subscriptions, moderation, archives. Scales to large lists (20k+ subscribers). Perl + MySQL/PostgreSQL/LDAP. Source: https://github.com/sympa-community/sympa
---

# Sympa

Electronic mailing list manager. Automates list subscription, unsubscription, moderation, archiving, and message delivery. Designed for scale — handles 20,000+ subscriber lists efficiently. Supports multiple lists and domains on a single instance, LDAP/AD user auth, digest delivery, Sieve-style rules, and web interface. Perl. GPL-2.0 licensed.

Upstream: <https://github.com/sympa-community/sympa> | Docs: <https://www.sympa.community>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian/Ubuntu | APT packages | Recommended for most deployments |
| RHEL/CentOS/Fedora | RPM packages | Available |
| Any | CPAN (source) | For latest/custom builds |
| Any | Ansible | Official role: `sympa-community/ansible-role-sympa` |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | MTA installed (Postfix, Sendmail, or Exim) | Sympa integrates with your MTA for mail delivery |
| config | Domain name | e.g. lists.example.com |
| config | Database: MySQL/MariaDB or PostgreSQL | Host, DB name, user, password |
| config | SMTP server / MTA config | Sympa needs to hand off outbound mail |
| config | Web server (Apache/nginx) for web UI | Optional but recommended |
| config (optional) | LDAP server | For SSO/user auth |

## Software-layer concerns

### Architecture

- **Sympa daemon** — core process: queue management, delivery, archiving
- **wwsympa** — web interface (FastCGI)
- **MTA integration** — Postfix/Exim alias maps or Sendmail integration
- **Database** — MySQL/MariaDB or PostgreSQL stores subscriber lists, archives, config

### Key directories

| Dir | Description |
|---|---|
| `/etc/sympa/` | Configuration (sympa.conf) |
| `/var/lib/sympa/` | List archives, queue, home |
| `/var/spool/sympa/` | Mail queues |
| `/usr/lib/sympa/` | Modules, templates |

### sympa.conf key settings

```
domain    lists.example.com
listmaster  admin@example.com
db_type   mysql
db_name   sympa
db_host   localhost
db_user   sympa
db_passwd yourpassword
sendmail  /usr/sbin/sendmail
```

## Install — Debian/Ubuntu (APT)

```bash
sudo apt update
sudo apt install sympa

# During install, debconf prompts for:
# - Mail domain
# - Database backend (MySQL/PostgreSQL)
# - Database credentials
# - Admin (listmaster) email

# Start services
sudo systemctl enable --now sympa

# Configure MTA integration (Postfix)
# Add to /etc/postfix/main.cf:
# alias_maps = hash:/etc/mail/aliases,hash:/etc/sympa/data/alias
# transport_maps = hash:/etc/sympa/data/transport
sudo newaliases
sudo postmap /etc/sympa/data/transport

# Web UI: configure Apache/nginx to run wwsympa via FastCGI
# See: https://www.sympa.community/manual/install/configure-http-server.html
```

Full install guide: https://www.sympa.community/manual/install/

## Install — Ansible

```bash
ansible-galaxy install sympa-community.sympa
# Configure role variables (domain, db settings, MTA)
# See: https://github.com/sympa-community/ansible-role-sympa
```

## Upgrade procedure

```bash
sudo apt upgrade sympa
sudo sympa_wizard --check    # Verify config after upgrade
sudo systemctl restart sympa
```

See upgrade notes: https://www.sympa.community/manual/upgrade/

## Gotchas

- **MTA integration is required** — Sympa is not a standalone mail server. It hooks into Postfix/Exim/Sendmail for mail delivery. Configure alias maps and transport maps in your MTA.
- Postfix users must configure `alias_maps` and `transport_maps` to route list addresses to Sympa queues — without this, list mail delivery won't work.
- Large lists (10k+ subscribers) need tuning: increase `max_size`, `bulk_fork_threshold`, and `process_count` in `sympa.conf`.
- The web interface (wwsympa) is a FastCGI application — requires Apache mod_fcgid or nginx with FastCGI. Without the web UI, lists can still be managed via email commands and CLI.
- LDAP integration requires additional Perl modules (`Net::LDAP`) and ldap.conf configuration.

## Links

- Source: https://github.com/sympa-community/sympa
- Documentation: https://www.sympa.community/manual/
- Install guide: https://www.sympa.community/manual/install/
- Ansible role: https://github.com/sympa-community/ansible-role-sympa
- Translation: https://translate.sympa.community
