---
name: group-office
description: Group Office recipe for open-forge. Enterprise CRM and groupware — calendars, contacts, email, projects, files, and more. PHP + MySQL. Docker. AGPL-3.0. Source: https://github.com/Intermesh/groupoffice
---

# Group Office

Enterprise-grade open source groupware and CRM. Provides calendars, contacts, email (IMAP/SMTP), task management, project management, file sharing, and billing — all in one unified web interface. PHP + MySQL. Docker Compose deployment via the companion docker-groupoffice repo. AGPL-3.0 licensed (Professional edition also available).

Upstream: https://github.com/Intermesh/groupoffice | Docker: https://github.com/Intermesh/docker-groupoffice | Docs: https://groupoffice.readthedocs.io

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Recommended (official docker-groupoffice repo) |
| Linux | APT packages (Debian/Ubuntu) | Official .deb packages available |
| Linux | Manual (PHP + Nginx/Apache + MySQL) | See install guide |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Port | Host port to expose, default 9090 |
| config | Version tag | Pin to a specific version, e.g. intermesh/groupoffice:25.0 -- do NOT use latest |
| config (upgrade) | License key | Professional edition requires license key from group-office.com account |
| config (cron) | Path to docker-groupoffice clone | Needed for the cron job command |

## Software-layer concerns

- Cron job required: Group Office relies on scheduled tasks (cron.php) running every minute. Must be configured on the host -- not baked into the container.
- Version pinning critical: upgrading skips major versions will corrupt data. Always upgrade step-by-step (25.0 -> 25.1, not 25.0 -> 25.2).
- Professional edition: some modules require a paid license. The AGPL community edition is fully functional for most use cases.
- Data persistence: the docker-groupoffice compose file maps volumes for the app data and database.

## Install -- Docker Compose

```bash
git clone https://github.com/Intermesh/docker-groupoffice.git
cd docker-groupoffice
# Check compose.yml and pin the image tag to a specific version
# Edit: intermesh/groupoffice:25.0
docker compose up -d
# Open http://yourserver:9090 -- GroupOffice installer appears
```

### Cron job (required)

On Linux, create /etc/cron.d/groupoffice (replace /path/to/docker-groupoffice):

```cron
* * * * * root cd /path/to/docker-groupoffice && docker compose exec -u www-data -T groupoffice php /usr/local/share/groupoffice/cron.php
```

## Upgrade procedure

1. Check the current version tag in compose.yml (e.g. intermesh/groupoffice:25.0)
2. Upgrade only one minor version at a time (25.0 -> 25.1 -> 25.2, not 25.0 -> 25.2)
3. For Professional edition: install the latest license key from your group-office.com account first
4. Edit compose.yml to update the tag, then:

```bash
docker compose pull
docker compose up -d
# GroupOffice runs DB migrations automatically on startup
```

### Install license key (Professional)

```bash
docker compose exec -u www-data groupoffice \
  php /usr/local/share/groupoffice/cli.php core/System/setLicense --key=<YOURKEY>
```

## Gotchas

- Never use the `latest` tag in production: major version upgrades must be done step-by-step; latest may jump multiple versions and break the database schema.
- Cron job is mandatory: without it, reminders, email sync, and recurring tasks will not work. Set it up immediately after first login.
- Installer runs on first visit: the web installer creates the admin account and configures the database -- complete it before anyone else accesses the instance.
- AGPL vs Professional: the community AGPL edition is available free. The Professional edition adds modules (billing, HR, etc.) and requires a paid subscription from group-office.com.

## Links

- Source: https://github.com/Intermesh/groupoffice
- Docker repo: https://github.com/Intermesh/docker-groupoffice
- Documentation: https://groupoffice.readthedocs.io
- Website: https://www.group-office.com
