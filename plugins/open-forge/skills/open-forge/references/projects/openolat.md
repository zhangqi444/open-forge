---
name: openolat
description: OpenOLAT recipe for open-forge. Web-based learning management system (LMS) for teaching, assessment and communication. Java/Tomcat app with courses, assessments, calendar, messaging, REST API, and LDAP/SSO integration. Source: https://github.com/OpenOLAT/OpenOLAT
---

# OpenOLAT

Web-based learning management system (LMS) for universities and organizations. Supports course authoring, e-assessments, certificates, portfolios, group collaboration, class calendar, integrated messaging, REST API, LDAP, and SSO (Shibboleth/SAML). Apache-2.0 licensed. Java + Tomcat + PostgreSQL/MySQL. Actively developed.

Upstream: <https://github.com/OpenOLAT/OpenOLAT> | Docs: <https://docs.openolat.org> | Demo: <https://learn.olat.com>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | Docker / Docker Compose | Recommended for quick start |
| Linux | Tomcat + Java (manual) | Production-grade; requires PostgreSQL or MySQL |
| Any | PostgreSQL 14+ | Recommended database |
| Any | MySQL 8+ / MariaDB 10.6+ | Alternate database |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | Java 17+ installed | Required for manual install |
| config | Database type: PostgreSQL or MySQL | PostgreSQL recommended |
| config | Database host, name, user, password | |
| config | OpenOLAT server URL | Public URL (used in emails, links) |
| config | SMTP settings | For notifications and invitations |
| config | Admin password | Set on first boot |
| config | Data directory | Persistent storage for uploaded files |

## Software-layer concerns

### Architecture

- Java web app running in Apache Tomcat (embedded or standalone)
- PostgreSQL or MySQL/MariaDB as database
- File system data directory for course assets, user uploads, etc.

### Key config file

`olat.local.properties` (or env vars via Docker). Key properties:

```properties
# Server URL
server.domainname=olat.example.com
server.contextpath=/

# Database (PostgreSQL example)
db.vendor=postgresql
db.host=localhost
db.port=5432
db.name=openolat
db.user=openolat
db.pass=yourpassword

# Data directory (persistent)
userdata.dir=/var/lib/openolat

# SMTP
smtp.host=smtp.example.com
smtp.port=587
smtp.user=
smtp.password=
smtp.from=noreply@olat.example.com
```

## Install — Docker Compose (recommended)

```bash
mkdir openolat && cd openolat

cat > docker-compose.yml << 'EOF'
services:
  openolat:
    image: openolat/openolat:latest
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8080:8080"
    environment:
      OPENOLAT_DB_VENDOR: postgresql
      OPENOLAT_DB_HOST: db
      OPENOLAT_DB_PORT: 5432
      OPENOLAT_DB_NAME: openolat
      OPENOLAT_DB_USER: openolat
      OPENOLAT_DB_PASSWORD: yourpassword
      OPENOLAT_SERVER_DOMAINNAME: olat.example.com
      OPENOLAT_SMTP_HOST: smtp.example.com
    volumes:
      - openolat_data:/var/lib/openolat

  db:
    image: postgres:16
    restart: unless-stopped
    environment:
      POSTGRES_DB: openolat
      POSTGRES_USER: openolat
      POSTGRES_PASSWORD: yourpassword
    volumes:
      - db_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U openolat"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  openolat_data:
  db_data:
EOF

docker compose up -d
```

Access at http://localhost:8080. Default admin credentials are shown in container logs on first boot.

## Install — Manual (Tomcat)

See the full installation guide at https://docs.openolat.org/manual_admin/installation/installGuide/

```bash
# Prerequisites: Java 17+, PostgreSQL, Tomcat 10+
sudo apt install openjdk-17-jdk postgresql tomcat10

# Create DB
sudo -u postgres psql <<SQL
CREATE DATABASE openolat ENCODING 'UTF8';
CREATE USER openolat WITH PASSWORD 'yourpassword';
GRANT ALL PRIVILEGES ON DATABASE openolat TO openolat;
SQL

# Download OpenOLAT WAR from https://github.com/OpenOLAT/OpenOLAT/releases
# Deploy to Tomcat webapps/ directory

# Create data directory
sudo mkdir -p /var/lib/openolat
sudo chown -R tomcat:tomcat /var/lib/openolat

# Create config file: /etc/openolat/olat.local.properties
# (set db.*, server.domainname, userdata.dir, smtp.*)

sudo systemctl restart tomcat10
```

## Upgrade procedure

Docker:
```bash
docker compose pull
docker compose up -d
```

Manual: Download new WAR, replace in Tomcat webapps/, restart Tomcat. Database migrations run automatically on startup.

## Gotchas

- Data directory must be on persistent storage — user uploads, course assets, and session data all live here. Map it as a Docker volume or ensure it's backed up.
- Java 17+ required — older Java versions (8, 11) are no longer supported as of recent releases.
- The admin account credentials are generated on first boot and printed to container logs — check `docker compose logs openolat` after first start.
- OpenOLAT uses in-memory caching heavily — allocate at least 2–4 GB RAM for production use. Set JVM heap size via `JAVA_OPTS=-Xmx4g` in Tomcat/Docker env.
- SMTP configuration is needed for user registration, password resets, and course notifications — without it, these workflows will silently fail.
- Community membership: the project is open source but frentix GmbH provides commercial support. The community instance at https://community.openolat.org is available for questions.

## Links

- Source: https://github.com/OpenOLAT/OpenOLAT
- Documentation: https://docs.openolat.org
- Installation guide: https://docs.openolat.org/manual_admin/installation/installGuide/
- Admin manual: https://docs.openolat.org/manual_admin/
- Demo: https://learn.olat.com
