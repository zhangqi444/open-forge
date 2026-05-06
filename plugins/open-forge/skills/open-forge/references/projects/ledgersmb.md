---
name: ledgersmb
description: LedgerSMB recipe for open-forge. Integrated double-entry accounting and ERP for small/medium businesses. Covers invoicing, quotations, orders, inventory, projects, timecards, budgeting, and shipping. Perl/PostgreSQL app with Docker support. Source: https://github.com/ledgersmb/LedgerSMB
---

# LedgerSMB

Integrated double-entry accounting and ERP system for small and medium businesses. Covers quotations, orders, invoicing, inventory management, project tracking, timecards, budgeting, shipping, and full financial reporting. Supports multiple currencies, multi-user roles, and a built-in PDF/ODF/HTML template engine. Built on Perl with PostgreSQL as the database. Official Docker image: `ghcr.io/ledgersmb/ledgersmb`. Upstream: https://github.com/ledgersmb/LedgerSMB. Docs: https://ledgersmb.org. GPLv2.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Docker Compose (official) | Linux | Recommended; from ledgersmb/ledgersmb-docker |
| Debian/Ubuntu package | Debian / Ubuntu | `apt install ledgersmb` |
| From source (tarball) | Linux | See https://ledgersmb.org/content/installing-ledgersmb |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| db | "PostgreSQL password?" | POSTGRES_PASSWORD — for the database container |
| admin | "LedgerSMB setup password?" | Set during first-run at /setup.pl |
| company | "Company/database name?" | Created via /setup.pl after install |
| port | "Host port?" | Default: 5762 |

## Software-layer concerns

### Method 1: Docker Compose (recommended)

  # Download official compose file:
  wget https://raw.githubusercontent.com/ledgersmb/ledgersmb-docker/1.13/docker-compose.yml

  # Edit the POSTGRES_PASSWORD in docker-compose.yml (or use a .env file):
  # POSTGRES_PASSWORD=your_secure_password

  docker compose up -d

  # LedgerSMB is available at:
  #   http://localhost:5762/setup.pl  — database/company creation (admin)
  #   http://localhost:5762/login.pl  — normal user login

### docker-compose.yml overview

  services:
    postgres:
      image: postgres:15-alpine
      environment:
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-abc}   # CHANGE THIS
        PGDATA: /var/lib/postgresql/data/pgdata
      volumes:
        - pgdata:/var/lib/postgresql/data
      restart: unless-stopped

    lsmb:
      image: ghcr.io/ledgersmb/ledgersmb:1.13
      depends_on:
        - postgres
      ports:
        - "5762:5762"
      restart: unless-stopped

  volumes:
    pgdata:

### First-run: create a company database

  # Navigate to http://localhost:5762/setup.pl
  # 1. Enter a superuser name and the PostgreSQL admin password
  # 2. Create a new company (database):
  #    - Company name (becomes the DB name)
  #    - Country and chart of accounts
  #    - Admin user for the company
  # 3. Log in at http://localhost:5762/login.pl

### Key setup steps after first login

  # - Set up your Chart of Accounts (via System > Chart of Accounts)
  # - Configure customers and vendors
  # - Set up products/services
  # - Configure email (System > Defaults > Email)

### Environment variables

  POSTGRES_PASSWORD   PostgreSQL superuser password
  # LedgerSMB configuration is in the container's ledgersmb.conf;
  # override by mounting a custom conf file as a volume.

### Ports

  5762/tcp   # Web UI (HTTP; use reverse proxy for TLS)

### Reverse proxy (nginx)

  server {
      listen 443 ssl;
      server_name ledger.example.com;
      location / {
          proxy_pass http://127.0.0.1:5762;
          proxy_set_header Host $host;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto https;
      }
  }

### Method 2: Debian/Ubuntu package

  sudo apt install ledgersmb
  # Requires PostgreSQL installed separately.
  # After install, configure /etc/ledgersmb/ledgersmb.conf
  # and navigate to http://localhost:5762/setup.pl

## Upgrade procedure

  # Docker:
  docker compose pull
  docker compose up -d
  # LedgerSMB runs schema migrations automatically on startup.

  # Debian:
  sudo apt update && sudo apt upgrade ledgersmb

  # After major version upgrades: check the release notes for manual migration steps.
  # https://github.com/ledgersmb/LedgerSMB/releases

## Gotchas

- **PostgreSQL only**: LedgerSMB requires PostgreSQL. MySQL/MariaDB is not supported. Use the provided postgres container or an external PostgreSQL 14+ instance.
- **setup.pl vs login.pl**: `/setup.pl` is the privileged admin interface for creating/managing company databases. It requires the PostgreSQL superuser password. Normal users log in at `/login.pl` with their company-specific credentials.
- **Company = database**: Each "company" in LedgerSMB is a separate PostgreSQL database. You can run multiple companies from one LedgerSMB instance.
- **Change the default password**: The Docker Compose default `POSTGRES_PASSWORD=abc` is insecure. Always set a strong password before deploying.
- **Not production-ready without TLS**: The default compose setup uses HTTP only. Put it behind nginx/Caddy with TLS before exposing to the internet.
- **Double-entry accounting**: LedgerSMB enforces double-entry bookkeeping. You need basic accounting knowledge (debits/credits, chart of accounts) to use it effectively.
- **Chart of accounts varies by country**: Select the appropriate country template in setup.pl. The chart of accounts defines your account structure and cannot be easily changed later.

## References

- Upstream GitHub: https://github.com/ledgersmb/LedgerSMB
- Docker images: https://github.com/ledgersmb/ledgersmb-docker
- Website: https://ledgersmb.org
- Installing from tarball: https://ledgersmb.org/content/installing-ledgersmb-113
- Docker Hub: https://hub.docker.com/r/ledgersmb/ledgersmb
