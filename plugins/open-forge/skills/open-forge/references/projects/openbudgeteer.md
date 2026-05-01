---
name: OpenBudgeteer
description: "Self-hosted budgeting app based on the Bucket Budgeting Principle (YNAB-inspired). Docker. .NET + Blazor Server. TheAxelander/OpenBudgeteer. Supports MariaDB, MySQL, PostgreSQL, and SQLite. Budget buckets, account tracking, transactions, import, reports. MIT."
---

# OpenBudgeteer

**Self-hosted YNAB-inspired bucket budgeting.** OpenBudgeteer implements the Bucket Budgeting Principle — allocate money into named buckets before spending it. Inspired by YNAB and Buckets. .NET Core backend with Blazor Server frontend. Supports MariaDB, MySQL, PostgreSQL, and SQLite. Tracks accounts, transactions, budget buckets, and generates reports.

Built + maintained by **TheAxelander**. MIT license.

- Upstream repo: <https://github.com/TheAxelander/OpenBudgeteer>
- Docker Hub: `axelander/openbudgeteer`
- Documentation: <https://theaxelander.github.io>

## Architecture in one minute

- **.NET** app with **Blazor Server** frontend (server-side rendered)
- Database: **MariaDB**, **MySQL**, **PostgreSQL**, or **SQLite**
- Port **80** (inside container, map to host port e.g. 8081)
- Single container — database is external
- Resource: **low-medium** — .NET, minimal footprint with SQLite; scales with DB size

## Compatible install methods

| Infra      | Runtime                      | Notes                                           |
| ---------- | ---------------------------- | ----------------------------------------------- |
| **Docker** | `axelander/openbudgeteer`    | **Primary** — MariaDB, PostgreSQL, or SQLite     |

Example files in repo: `examples/compose-mariadb.yaml`, `examples/compose-postgres.yaml`

## Install via Docker — PostgreSQL

```yaml
services:
  openbudgeteer:
    image: axelander/openbudgeteer:latest
    container_name: openbudgeteer
    ports:
      - "8081:80"
    environment:
      - CONNECTION_PROVIDER=postgres
      - CONNECTION_SERVER=openbudgeteer-db
      - CONNECTION_DATABASE=openbudgeteer
      - CONNECTION_USER=openbudgeteer
      - CONNECTION_PASSWORD=changeme
      - APPSETTINGS_CULTURE=en-US
      - APPSETTINGS_THEME=solar
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:alpine
    container_name: openbudgeteer-db
    environment:
      - POSTGRES_USER=openbudgeteer
      - POSTGRES_PASSWORD=changeme
      - POSTGRES_DB=openbudgeteer
    volumes:
      - db-data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  db-data:
```

## Install via Docker — MariaDB

```yaml
services:
  openbudgeteer:
    image: axelander/openbudgeteer:latest
    container_name: openbudgeteer
    ports:
      - "8081:80"
    environment:
      - CONNECTION_PROVIDER=mariadb
      - CONNECTION_SERVER=openbudgeteer-mysql
      - CONNECTION_PORT=3306
      - CONNECTION_DATABASE=openbudgeteer
      - CONNECTION_USER=openbudgeteer
      - CONNECTION_PASSWORD=changeme
      - CONNECTION_ROOT_PASSWORD=rootpassword
      - APPSETTINGS_CULTURE=en-US
      - APPSETTINGS_THEME=solar
    depends_on:
      - mysql
    restart: unless-stopped

  mysql:
    image: mariadb
    container_name: openbudgeteer-mysql
    environment:
      MARIADB_ROOT_PASSWORD: rootpassword
    volumes:
      - db-data:/var/lib/mysql
    restart: unless-stopped

volumes:
  db-data:
```

Visit `http://localhost:8081` after startup.

## Environment variables

| Variable | Required | Notes |
|----------|----------|-------|
| `CONNECTION_PROVIDER` | ✅ | `mariadb`, `mysql`, `postgres`, or `sqlite` |
| `CONNECTION_SERVER` | ✅ (DB) | Hostname of the database container |
| `CONNECTION_PORT` | ✅ (MariaDB/MySQL) | Default 3306 |
| `CONNECTION_DATABASE` | ✅ | Database name |
| `CONNECTION_USER` | ✅ | Database user |
| `CONNECTION_PASSWORD` | ✅ | Database password |
| `CONNECTION_ROOT_PASSWORD` | MariaDB only | Root password for auto-provisioning |
| `APPSETTINGS_CULTURE` | ❌ | e.g. `en-US`, `de-DE` — controls date/number formatting |
| `APPSETTINGS_THEME` | ❌ | UI theme (e.g. `solar`, `darkly`) |

## Features overview

| Feature | Details |
|---------|---------|
| Bucket budgeting | Allocate money into named buckets before you spend it (YNAB-style) |
| Account tracking | Multiple accounts; track balances |
| Transaction management | Log and categorise transactions |
| Transaction import | Import from bank CSV exports |
| Budget buckets | Create, name, and fill budget categories |
| Monthly budgeting | Plan and review budgets month-by-month |
| Reports | Spending reports; trends over time |
| Multi-currency | Culture/locale setting for formatting |
| Themes | Multiple dark/light themes via Bootswatch |
| Multiple DB backends | MariaDB, MySQL, PostgreSQL, SQLite |
| Single container | One container + external DB; simple to deploy |

## Gotchas

- **Example compose uses `openbudgeteer:pre-release` image.** Use `axelander/openbudgeteer:latest` (or a specific release tag) for production. The example compose files in the repo reference a local pre-release build.
- **Example compose uses an external `app-global` network.** If you don't have this external network, either create it (`docker network create app-global`) or remove the `networks` blocks and use the default bridge.
- **SQLite path.** For SQLite, set `CONNECTION_PROVIDER=sqlite` and mount a volume for the SQLite file. See the docs for the exact path.
- **No multi-user support.** OpenBudgeteer is a single-user app by design — no login screen or user management; expose behind a reverse proxy with auth.
- **Culture setting affects import.** Set `APPSETTINGS_CULTURE` to match your locale — it affects CSV import date/number parsing.
- **MIT license.** Free to use, modify, and redistribute.

## Backup

```sh
# PostgreSQL
docker compose exec db pg_dump -U openbudgeteer openbudgeteer > openbudgeteer-$(date +%F).sql

# MariaDB
docker compose exec mysql mysqldump -u openbudgeteer -p openbudgeteer > openbudgeteer-$(date +%F).sql
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active .NET/Blazor development, multi-DB support, MIT license.

## Budgeting-family comparison

- **OpenBudgeteer** — .NET/Blazor, bucket budgeting (YNAB-inspired), MariaDB/Postgres/SQLite, MIT
- **Firefly III** — PHP/Laravel, double-entry accounting, comprehensive; more complex; AGPL-3.0
- **Actual Budget** — Node.js/SQLite, envelope budgeting, local-first, sync; MIT
- **Budgetzero** — Vue.js, zero-based budgeting, minimal; MIT

**Choose OpenBudgeteer if:** you want a simple, self-hosted YNAB-style bucket budgeting app with .NET/Blazor, multiple database backend support, and no complexity overhead.

## Links

- Repo: <https://github.com/TheAxelander/OpenBudgeteer>
- Docs: <https://theaxelander.github.io>
- Docker Hub: <https://hub.docker.com/r/axelander/openbudgeteer>
