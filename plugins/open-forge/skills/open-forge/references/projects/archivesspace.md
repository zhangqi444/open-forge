---
name: archivesspace
description: ArchivesSpace recipe for open-forge. Open source archives information management application for describing and providing web access to archival collections, manuscripts, and digital objects. Built on Ruby with MySQL/PostgreSQL backend. Source: https://github.com/archivesspace/archivesspace
---

# ArchivesSpace

Open source archives information management application used by universities, libraries, museums, and cultural institutions. Manages archival collections, manuscripts, digital objects, and finding aids. Ships with both a staff interface (back end management) and a public interface (web access for researchers). Provides an extensive REST API. Uses Solr for full-text search. Upstream: https://github.com/archivesspace/archivesspace. Docs: https://docs.archivesspace.org/. Demo (sandbox): https://archivesspace.org/application/sandbox.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| ZIP distribution | Linux / macOS | Recommended. Self-contained bundle with embedded JRuby + Jetty. |
| Docker | Linux / macOS | Official images available. Requires Java 21+ |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| install | "Database type + credentials?" | MySQL 8 (recommended) or PostgreSQL. SQLite for demo/test only. |
| install | "Java version?" | Java 17 or 21 required (v4.2+ supports Java 21) |
| install | "External Solr or bundled?" | Bundled Solr for small deployments; external for production |
| config | "App timezone?" | e.g. America/New_York — set in config/config.rb |
| config | "Backend / frontend ports?" | Default: backend 8089, frontend 8080, public 8081, Solr 8090 |
| auth | "Admin password?" | Set after first boot via the staff web interface |

## Software-layer concerns

### ZIP distribution install

  # Prerequisites: Java 17 or 21
  java -version

  # Download latest release
  wget https://github.com/archivesspace/archivesspace/releases/download/v4.2.0/archivesspace-v4.2.0.zip
  unzip archivesspace-v4.2.0.zip
  cd archivesspace

### Configure database (config/config.rb)

  # MySQL (recommended for production):
  AppConfig[:db_url] = "jdbc:mysql://127.0.0.1:3306/archivesspace?user=as_user&password=secret&useUnicode=true&characterEncoding=UTF-8"
  AppConfig[:db_max_connections] = 30

  # Create the MySQL database and user first:
  # CREATE DATABASE archivesspace DEFAULT CHARACTER SET utf8mb4;
  # CREATE USER 'as_user'@'localhost' IDENTIFIED BY 'secret';
  # GRANT ALL ON archivesspace.* TO 'as_user'@'localhost';

  # Timezone:
  AppConfig[:time_zone] = "America/New_York"

### Initialize and start

  # Initialize DB (first run only — creates schema):
  scripts/setup-database.sh

  # Start ArchivesSpace (all services: backend, frontend, public, indexer):
  ./archivesspace.sh start   # Linux/macOS

  # Stop:
  ./archivesspace.sh stop

  # Logs in: logs/archivesspace.out

### Service ports (defaults)

  Backend API:  http://localhost:8089
  Staff UI:     http://localhost:8080
  Public UI:    http://localhost:8081
  OAI-PMH:      http://localhost:8082
  Solr:         http://localhost:8090

### First login

  # Default admin credentials (change immediately):
  URL: http://localhost:8080
  Username: admin
  Password: admin

### Run as a system service (Linux)

  # Create /etc/systemd/system/archivesspace.service:
  [Unit]
  Description=ArchivesSpace
  After=network.target mysql.service

  [Service]
  Type=forking
  User=archivesspace
  WorkingDirectory=/opt/archivesspace
  ExecStart=/opt/archivesspace/archivesspace.sh start
  ExecStop=/opt/archivesspace/archivesspace.sh stop
  Restart=on-failure

  [Install]
  WantedBy=multi-user.target

  systemctl enable archivesspace && systemctl start archivesspace

### Docker deployment

  # Official Docker Compose file in repo:
  # https://github.com/archivesspace/archivesspace/blob/master/docker-compose.yml

  docker compose up -d

  # Uses MySQL 8, external Solr, and the ArchivesSpace app container.

## Upgrade procedure

  ./archivesspace.sh stop

  # Backup database first!
  mysqldump archivesspace > archivesspace_backup.sql

  # Download and unzip new version alongside old
  unzip archivesspace-vX.Y.Z.zip

  # Copy config from old install:
  cp old-archivesspace/config/config.rb archivesspace-vX.Y.Z/config/config.rb

  # Copy plugins:
  cp -r old-archivesspace/plugins/local archivesspace-vX.Y.Z/plugins/

  cd archivesspace-vX.Y.Z
  scripts/setup-database.sh   # runs migrations
  ./archivesspace.sh start

## Gotchas

- **Java required**: ArchivesSpace runs on JRuby inside Jetty. Java 17 or 21 must be installed on the host. Java 11 support ends at v4.2.0.
- **MySQL 8 charset**: database must use `utf8mb4` character set. Older `utf8` (3-byte) will cause truncation errors on Unicode content.
- **Demo SQLite is not for production**: the bundled SQLite database is for evaluation only. Switch to MySQL/PostgreSQL before storing real data.
- **Solr dependency**: full-text search requires Solr. The bundled Solr works for small sites; large deployments should run external Solr.
- **setup-database.sh is idempotent**: safe to re-run on upgrades — it applies pending migrations and does not re-create existing tables.
- **Plugins in `plugins/local/`**: local customizations go in `plugins/local/`. Copy this directory when upgrading to preserve customizations.
- **Membership model**: ArchivesSpace is free and open source, but has an optional paid membership program through LYRASIS for institutional support and member benefits.
- **Staff vs Public UI**: the staff interface (port 8080) is for archivists managing records; the public interface (port 8081) is for researchers browsing finding aids. Both must be running.

## References

- Upstream GitHub: https://github.com/archivesspace/archivesspace
- Documentation: https://docs.archivesspace.org/
- Getting started: https://docs.archivesspace.org/administration/getting_started/
- Docker guide: https://docs.archivesspace.org/administration/docker/
- REST API: https://archivesspace.github.io/archivesspace/api/
- Releases: https://github.com/archivesspace/archivesspace/releases
