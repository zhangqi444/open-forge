---
name: piler
description: Piler recipe for open-forge. Feature-rich open-source email archiving solution. Built-in SMTP server, full-text search, retention/legal hold, deduplication, encryption, LDAP/AD, 2FA, i18n. C + Docker + .deb. Source: https://github.com/jsuto/piler
---

# Piler

Feature-rich open-source email archival solution. Provides a built-in SMTP server that accepts email from your mail server, archives all messages with compression, deduplication, and optional encryption, and exposes them via a web UI with full-text search, expert search, tagging, legal hold, retention rules, bulk import/export, access control, and audit logs. Supports AD/LDAP, IMAP/POP3, SSO, Google Workspace, Microsoft 365, and 2FA via Google Authenticator. GPL-3.0 licensed.

Upstream: <https://github.com/jsuto/piler> | Website: <https://www.mailpiler.org>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker Compose | Recommended; official stack: MariaDB + MantiCore + Memcached + Piler |
| Ubuntu 24.04 (Noble) | .deb package | From GitHub Releases |
| Ubuntu arm64 | .deb (arm64) | Also available in releases |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Archive hostname (FQDN) | e.g. archive.example.com — used in SMTP banner and web UI links |
| config | MySQL/MariaDB user, password, database | Default in compose: piler/piler123 — change for production |
| config | Mail server relay | Configure your mail server to BCC/copy to piler's SMTP on port 25 |
| config (optional) | LDAP/AD settings | For SSO and user auth |
| infra | Port 25 | Piler's built-in SMTP accepts email for archiving |
| infra | Port 80/443 | Web UI |

## Software-layer concerns

### Architecture

| Service | Role |
|---|---|
| Piler (C daemon + PHP web) | SMTP inbound, archive logic, web UI |
| MariaDB | Metadata and message index |
| MantiCore Search | Full-text search engine |
| Memcached | Session and cache |

### Key env vars (Docker)

| Var | Description | Default |
|---|---|---|
| PILER_HOSTNAME | Archive server FQDN | archive.example.com |
| MYSQL_HOSTNAME | DB host | mysql |
| MYSQL_DATABASE / MYSQL_USER / MYSQL_PASSWORD | DB credentials | piler / piler / piler123 |
| MANTICORE_HOSTNAME | Search engine host | manticore |
| MEMCACHED_HOSTNAME | Cache host | memcached |
| RT | Real-time indexing (1=enabled) | 1 |

### Data volumes

| Volume | Description |
|---|---|
| piler_store | Archived email storage |
| piler_etc | Piler config files |
| db_data | MariaDB data |
| piler_manticore | MantiCore search index |

## Install — Docker Compose

```bash
git clone https://github.com/jsuto/piler.git
cd piler/docker

# Edit docker-compose.yaml:
# - Set MYSQL_PASSWORD (change from piler123)
# - Set ARCHIVE_HOST to your FQDN (e.g. archive.example.com)

ARCHIVE_HOST=archive.example.com docker compose up -d
```

Web UI at http://archive.example.com (default admin credentials in piler docs).

Then configure your mail server (Postfix, Exchange, etc.) to BCC or relay a copy of all mail to port 25 on the piler host.

## Install — .deb (Ubuntu 24.04)

```bash
# Download latest .deb from https://github.com/jsuto/piler/releases/latest
wget https://github.com/jsuto/piler/releases/download/piler-1.4.8/piler_1.4.8-noble-2e863b0_amd64.deb
sudo apt install ./piler_1.4.8-noble-2e863b0_amd64.deb
# Run the setup wizard
sudo /usr/lib/piler/scripts/setup.sh
```

## Upgrade procedure

Docker:
```bash
docker compose pull
docker compose up -d
```

.deb: download new package and `sudo apt install` to upgrade.

## Gotchas

- **Change default DB password** — the compose defaults use `piler123`. Change `MYSQL_PASSWORD` (and matching `MYSQL_USER`/`MYSQL_PASSWORD` in the piler service) before any production deployment.
- Port 25 must be reachable from your mail server — piler's SMTP daemon listens on port 25 for incoming archived mail. If you're behind a firewall, allow your mail server's IP to reach piler on port 25.
- MantiCore Search requires at least 512MB RAM reserved — the compose file sets a 512MB memory limit. Ensure the host has enough memory.
- The piler web UI is at the hostname set in `PILER_HOSTNAME` — your DNS must resolve this hostname to the host running piler.
- For Microsoft 365/Google Workspace archiving, configure journaling to send a copy of all mail to piler's SMTP address.

## Links

- Source: https://github.com/jsuto/piler
- Website & docs: https://www.mailpiler.org
- Releases: https://github.com/jsuto/piler/releases
- Docker README: https://github.com/jsuto/piler/blob/master/docker/README.md
