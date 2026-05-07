# LibreKB

**Simple self-hosted knowledge base web app** — PHP/MySQL knowledge base that runs on virtually any web host. Features TinyMCE article editing, user management with predefined groups, password resets via email, and responsive Bootstrap design. No fluff, installs in minutes.

**Official site:** https://librekb.com
**Source:** https://github.com/michaelstaake/LibreKB
**License:** GPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | PHP + MySQL/MariaDB | Classic LAMP; runs on shared hosting too |
| Any VPS / bare metal | Docker | Docker support available |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Whether running on shared hosting or VPS/dedicated server

### Phase 2 — Deploy
- MySQL/MariaDB credentials (database name, user, password, host)
- SMTP config for password reset emails
- Admin account email and password

---

## Software-Layer Concerns

- **Stack:** PHP, MySQL/MariaDB
- **Editor:** TinyMCE for rich-text article editing
- **User management:** Predefined user groups with role-based access
- **Update checks:** Removed in v2.0.1 by community request; check for updates manually
- **Branding:** Easily customizable to match your project or business

---

## Deployment

1. Download the latest release from https://github.com/michaelstaake/LibreKB/releases
2. Extract to your web server document root
3. Create a MySQL database and user
4. Visit the installer at `https://your-domain/install/` and follow the web wizard
5. Remove or restrict the `install/` directory after setup

Full documentation: https://docs.librekb.com

---

## Upgrade Procedure

Follow the upgrade guide at https://docs.librekb.com. Back up the database before upgrading.

---

## Gotchas

- **Remove `/install/` after setup** — leaving it accessible is a security risk
- **No automatic update checks** since v2.0.1 — monitor GitHub releases manually
- **Shared hosting compatible** — low PHP/MySQL requirements; works on budget hosting plans
- **SMTP required for password resets** — without mail config, users can't self-service password resets

---

## Links

- Upstream README: https://github.com/michaelstaake/LibreKB#readme
- Documentation: https://docs.librekb.com
- Discussions/Forum: https://github.com/michaelstaake/LibreKB/discussions
