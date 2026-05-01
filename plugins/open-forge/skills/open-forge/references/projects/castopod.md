# Castopod

**Free and open-source podcast hosting platform with ActivityPub federation, audience engagement tools, and a built-in podcast player.**
Official site: https://castopod.org
GitHub: https://github.com/ad-aures/castopod

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker | Official Docker install guide |
| Any Linux | PHP + MySQL/MariaDB | Manual install (PHP 8.1+, MySQL 5.7+ or MariaDB 10.3+) |
| YunoHost | YunoHost app | One-click via install-app.yunohost.org |
| Any | Ansible Playbook | Community playbook available |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname for the Castopod instance
- Database credentials — host, name, user, password
- SMTP config — for email notifications and password resets
- Admin email + password — for initial setup wizard

---

## Software-Layer Concerns

### Requirements (manual install)
- PHP 8.1+
- MySQL 5.7+ or MariaDB 10.3+
- A web server (Apache / nginx) with rewrite rules

### Docker install
Full Docker guide: https://docs.castopod.org/getting-started/docker.html
No official docker-compose.yml in the main repo — follow the documentation site for the current recommended compose.

### Ports
- `80` / `443` — standard web (behind reverse proxy)

### ActivityPub / Fediverse
Castopod supports federation via ActivityPub — podcast episodes and interactions can appear in Mastodon and other Fediverse clients.

---

## Upgrade Procedure

1. docker compose pull (or download new release archive)
2. docker compose up -d
3. Run any database migrations via the admin UI or CLI as noted in the release notes

---

## Gotchas

- The main repo is the canonical source but contributions must be submitted to the GitLab mirror (code.castopod.org), not GitHub
- Castopod.com offers a managed hosted version if self-hosting is not desired
- ActivityPub federation is enabled by default — configure your public URL correctly or federation links will break
- Release downloads and PHP install packages are at https://castopod.org/getting-started/

---

## References
- Getting started: https://castopod.org/getting-started/
- Docker install: https://docs.castopod.org/getting-started/docker.html
- GitHub: https://github.com/ad-aures/castopod#readme
