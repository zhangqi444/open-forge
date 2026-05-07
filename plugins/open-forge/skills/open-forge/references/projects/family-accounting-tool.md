---
name: family-accounting-tool
description: Family Accounting Tool (facto) recipe for open-forge. Web-based finance management for partners with shared/split expenses. Tracks transactions, calculates internal debt, extracts spending statistics. Scala/Play + MariaDB. Binary or Docker install. Source: https://github.com/nymanjens/facto
---

# Family Accounting Tool (facto)

Web-based household finance manager designed for partners or small groups with partially shared expenses. Tracks every transaction, calculates internal debt (who owes whom), extracts spending statistics by category, and helps verify no money goes missing. Scala/Play Framework backend + MariaDB/MySQL. Pre-built binary release available. Apache-2.0 licensed.

Upstream: <https://github.com/nymanjens/facto>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | Binary release + Java 11 + MariaDB | Recommended for real data |
| Any | Docker Compose | Quick demo/evaluation; not recommended for production data (upstream caveat) |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Java 11 (JDK) installed | Required for binary install |
| config | Database: MariaDB/MySQL host, DB name, user, password | |
| config | `play.http.secret.key` | Random secret for Play Framework session signing |
| config | `app.setup.defaultPassword` | Default password used on first setup |
| config | Port | Default: 9000 |

## Software-layer concerns

### Config file (`conf/application.conf`)

```hocon
db.default {
  driver = com.mysql.jdbc.Driver
  url = "jdbc:mysql://localhost/facto?user=facto&password=yourpassword"
  slick.profile = "slick.jdbc.MySQLProfile$"
}

play.http.secret.key = "your-random-secret-key-here"
app.setup.defaultPassword = "changeme"
```

### Data dirs

All data is in the configured database. No separate file storage directory.

## Install — Binary release (recommended for real data)

```bash
# 1. Install Java 11
sudo apt install openjdk-11-jdk

# 2. Install MariaDB and create database
sudo apt install mariadb-server
sudo mysql -u root <<SQL
CREATE DATABASE facto CHARACTER SET utf8mb4;
CREATE USER 'facto'@'localhost' IDENTIFIED BY 'yourpassword';
GRANT ALL PRIVILEGES ON facto.* TO 'facto'@'localhost';
SQL

# 3. Download latest release
# https://github.com/nymanjens/facto/releases/latest
# Download: "Binaries (compiled files) with demo configuration"
unzip facto-*.zip
cd facto-*/

# 4. Edit conf/application.conf (DB credentials, secret key, default password)

# 5. Create DB tables
bin/server -DdropAndCreateNewDb

# 6. Create admin user
bin/server -DcreateAdminUser

# 7. Run
bin/server

# Access at http://localhost:9000
# Admin panel: http://localhost:9000/app/useradministration
# Login: admin / changeme (or your configured defaultPassword)
```

## Install — Docker Compose (demo/evaluation only)

> **Upstream warning:** Docker setup works for evaluation but is not recommended for production with real data. See [this issue](https://github.com/nymanjens/facto/issues/4) for reasons.

```bash
wget https://raw.githubusercontent.com/nymanjens/facto/master/docker-compose.yml
# Edit docker-compose.yml to set a unique SECRET_KEY value
docker compose up -d
```

## Upgrade procedure

```bash
# 1. Back up database
mysqldump facto > facto-backup.sql

# 2. Download new release zip
# 3. Extract, overwrite bin/ and lib/ (preserve conf/)
# 4. Run migrations if prompted (check release notes)
# 5. Restart: bin/server
```

## Gotchas

- Java 11 is required — not Java 17 or 21; check the release notes if newer versions add support.
- `play.http.secret.key` must be a long random string — using a short or predictable value is a security risk (it signs session cookies).
- Run `bin/server -DdropAndCreateNewDb` only on **first install** — it drops and recreates all database tables, destroying all existing data.
- Docker is discouraged for production use with real financial data — the upstream author notes configuration issues that make data recovery harder in Docker. Use the binary install instead.
- Default login is `admin` with `app.setup.defaultPassword` from config — change this immediately after first login.

## Links

- Source: https://github.com/nymanjens/facto
- Releases: https://github.com/nymanjens/facto/releases/latest
