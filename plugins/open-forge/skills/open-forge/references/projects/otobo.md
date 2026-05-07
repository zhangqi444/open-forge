---
name: otobo
description: OTOBO recipe for open-forge. Flexible open-source web-based ticketing system for customer service, help desk, and ITSM. Fork of OTRS Community Edition. Perl + Docker. Source: https://github.com/RotherOSS/otobo
---

# OTOBO

Flexible open-source web-based ticketing system for customer service, help desks, and IT service management (ITSM). Provides classical ticketing, knowledgebase/FAQ with internal/external views, process automation, and an optional ITSM/CMDB component. Fork of ((OTRS)) Community Edition, maintained by Rother OSS GmbH since 2019. Perl + Docker. GPL-3.0 licensed.

Upstream: <https://github.com/RotherOSS/otobo> | Docs: <https://doc.otobo.org>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | Docker Compose | Recommended; official Docker images provided |
| Linux | Native (Perl) | Manual install; Perl + Apache + MySQL/PostgreSQL |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Database: MySQL/PostgreSQL host, name, user, password | Configured via web installer |
| config | Admin email + password | Set during web installer |
| config | Mail server (inbound + outbound) | For ticket email integration |
| config | FQDN / domain | External URL for email links |
| config (optional) | ITSM/CMDB add-on | Optional extension for IT asset management |

## Software-layer concerns

### Architecture

- Perl application — Apache mod_perl or nginx/FastCGI
- MySQL/MariaDB or PostgreSQL — primary data store
- Web-based installer configures all settings
- OTOBO daemon — background process for escalations, email fetching, auto-responses

### Key paths (Docker)

- Config: auto-generated via web installer → stored in container/volume
- Attachments/data: mounted volume

## Install — Docker Compose (recommended)

OTOBO provides an official Docker-based installation documented at https://doc.otobo.org/manual/installation/11.0/en/content/otobo-installation.html

```bash
# 1. Download docker-compose files from OTOBO releases
# https://github.com/RotherOSS/otobo/releases/latest
# Look for the Docker Compose bundle in release assets

# 2. Configure environment (copy and edit .env)
cp .env.dist .env
# Edit: OTOBO_DB_ROOT_PASSWORD, OTOBO_NGINX_SSL_CERTIFICATE, etc.

# 3. Start
docker compose up -d

# 4. Run web installer
# http://yourserver/otobo/installer.pl
# Follow steps: DB setup, admin account, mail config
```

See full Docker install guide at: https://doc.otobo.org/manual/installation/11.0/en/content/otobo-installation.html

## Software requirements (native install)

| Component | Requirement |
|---|---|
| OS | Linux (Debian, Ubuntu, RHEL, CentOS, SLES) — Windows not supported |
| Perl | 5.24+ |
| Database | MySQL 5.7+ / MariaDB 10.2+ / PostgreSQL 9.6+ |
| Web server | Apache 2.4+ (mod_perl) or nginx + FCGI |

Full requirements: https://doc.otobo.org/manual/installation/11.0/en/content/requirements.html

## Upgrade procedure

Docker:
```bash
# Back up database first
docker compose pull
docker compose up -d
# Run migration via web: Admin → System Maintenance → Database Update
```

See upgrade guide: https://doc.otobo.org/manual/installation/11.0/en/content/updating.html

## Gotchas

- Windows is not supported — OTOBO runs only on Linux and Unix derivatives.
- The OTOBO daemon must be running for escalations, email fetching, and auto-responses to work. In Docker, this is handled automatically; in native installs, start it via `bin/otobo.Daemon.pl start`.
- OTOBO is a fork of OTRS Community Edition — migration tools are available if you're coming from OTRS 6/7. See the migration guide in the docs.
- Email integration (inbound ticket creation) requires configuring postmaster email accounts in the OTOBO admin panel.
- ITSM/CMDB is a separate add-on (free) — install via the OTOBO package manager in the admin panel after base setup.

## Links

- Source: https://github.com/RotherOSS/otobo
- Documentation: https://doc.otobo.org
- Installation guide: https://doc.otobo.org/manual/installation/11.0/en/content/otobo-installation.html
- Requirements: https://doc.otobo.org/manual/installation/11.0/en/content/requirements.html
- Community forums: https://otobo.io/en/forums-en/otobo/english-area/
- Demo: https://otobo.io/en/service-management-plattform/otobo-demo/
