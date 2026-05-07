# GRR

**Resource booking and asset management for small/medium organizations** — web-based room, equipment, and resource reservation system. Multilingual (FR/EN/ES/IT/DE), built on PHP/Symfony with MySQL, featuring admin area, user management, and reporting.

**Official site:** https://grr.devome.com/?lang=en
**Source:** https://github.com/JeromeDevome/GRR
**License:** GPL-2.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | PHP 8 + MySQL/MariaDB | Native install; Symfony 6 |
| Any VPS / bare metal | Docker | Community Docker setups available |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Language preference (FR, EN, ES, IT, DE)
- MySQL/MariaDB credentials

### Phase 2 — Deploy
- Database name, user, password, host
- SMTP/mail config for booking notifications
- Admin account credentials

---

## Software-Layer Concerns

- **Stack:** PHP 8, Symfony 6, MySQL/MariaDB
- **Requirements:** PHP 8+, MySQL/MariaDB, web server (Apache/Nginx)
- **Config:** Database and mail settings configured via `.env` or Symfony config files
- **Data dirs:** Standard Symfony `var/` for cache/logs; must be writable
- **Supported versions:** Only `4.4.X` and later receive security fixes; upgrade older installs
- **Production warning:** Use only published release archives, not branch code (branches may contain untested development code)

---

## Deployment

Follow the official installation documentation:
https://devome.com/GRR/DOC/installation-et-mise-a-jour/installation

Key steps:
1. Download a release archive (not branch code)
2. Configure database credentials in `.env`
3. Run Symfony setup commands (migrations, cache clear)
4. Configure web server document root to `public/`

---

## Upgrade Procedure

Follow: https://devome.com/GRR/DOC/installation-et-mise-a-jour/mise-a-jour

Only upgrade between supported versions (`4.4.X` series). Always back up the database before upgrading.

---

## Gotchas

- **Never deploy from branch code** — only use tagged releases from GitHub releases page
- **Only `4.4.X` is actively supported** — older versions have no security patches; upgrade before exposing to internet
- **French-first project** — primary docs and community are in French; English docs exist but may lag
- **Symfony cache** — must clear cache after config changes: `php bin/console cache:clear`
- **File permissions** — `var/cache` and `var/log` must be writable by the web server user

---

## Links

- Upstream README: https://github.com/JeromeDevome/GRR#readme
- Documentation: https://devome.com/GRR/DOC/
- Installation guide: https://devome.com/GRR/DOC/installation-et-mise-a-jour/installation
- Forum: https://site.devome.com/fr/grr/forum-grr
