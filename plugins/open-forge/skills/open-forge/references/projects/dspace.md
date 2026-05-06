---
name: dspace
description: DSpace recipe for open-forge. Open source institutional repository providing durable access to digital resources, with REST API, OAI-PMH, SWORD ingest, and Angular UI. Used by 2000+ universities worldwide. Source: https://github.com/DSpace/DSpace
---

# DSpace

Open source institutional repository and digital library platform used by 2,000+ organizations worldwide. Provides durable access to digital resources (theses, publications, datasets, images). Consists of a Java/Spring REST API backend and a separate Angular frontend. Supports OAI-PMH, SWORD ingest, full-text search via Solr, and SAML/ORCID integration. Upstream: https://github.com/DSpace/DSpace. Docs: https://wiki.lyrasis.org/display/DSDOC/.

Note: DSpace 7+ (current) is a complete rewrite from older 6.x and below. Installation is significantly different from legacy versions.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Manual (Java + PostgreSQL + Solr + Tomcat) | Linux | Standard production install. |
| Docker Compose (dev/test only) | Docker | Quick-start for development; not production-ready per upstream. |
| Ansible/cloud | Linux | Community Ansible scripts available. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Server hostname/URL?" | e.g. https://dspace.example.edu — set as dspace.server.url in local.cfg |
| setup | "Admin email and password?" | First administrator account |
| setup | "PostgreSQL connection details?" | host, port, db name, user, password |
| setup | "Solr URL?" | Default: http://localhost:8983/solr |
| setup | "Email (SMTP) for notifications?" | DSpace sends submission and workflow emails |
| storage | "Assetstore path?" | Where uploaded bitstreams are stored on disk |

## Software-layer concerns

### Prerequisites

- Java 17 (LTS)
- PostgreSQL 14+ with pgcrypto extension enabled
- Apache Solr 8.x or 9.x
- Apache Tomcat 9+ (or other servlet container) for backend
- Node.js 18+ for the Angular frontend (dspace-angular)

### PostgreSQL setup

  psql -U postgres -c "CREATE USER dspace WITH PASSWORD 'dspace';"
  psql -U postgres -c "CREATE DATABASE dspace OWNER dspace;"
  psql -U dspace -d dspace -c "CREATE EXTENSION pgcrypto;"

### Backend (REST API) install summary

  # Download backend release from GitHub releases
  # Extract, copy config/local.cfg.EXAMPLE to config/local.cfg
  # Edit local.cfg: set dspace.dir, dspace.server.url, db.*, solr.*, mail.*
  cd [dspace-installer]
  ant fresh_install

  # Deploy ROOT.war to Tomcat webapps
  cp /dspace/webapps/server/ROOT.war $TOMCAT_HOME/webapps/

  # Initialize database
  /dspace/bin/dspace database migrate

  # Create admin
  /dspace/bin/dspace create-administrator

Key local.cfg settings:

  dspace.dir = /dspace
  dspace.server.url = https://dspace.example.edu/server
  dspace.ui.url = https://dspace.example.edu
  db.url = jdbc:postgresql://localhost:5432/dspace
  db.username = dspace
  db.password = <password>
  solr.server = http://localhost:8983/solr
  mail.server = smtp.example.edu
  mail.from.address = dspace-noreply@example.edu

### Frontend (dspace-angular) install summary

  git clone https://github.com/DSpace/dspace-angular
  cd dspace-angular
  cp config/example.yml config/default.yml
  # Edit default.yml: set rest.host/port/nameSpace/ssl to match your backend
  yarn install
  yarn build:prod
  # Serve via PM2 or systemd with: yarn serve:ssr

### Solr setup

DSpace requires specific Solr cores. The installer copies them:
  cp -r /dspace/solr/* $SOLR_HOME/server/solr/

## Upgrade procedure

1. Back up PostgreSQL database and /dspace/assetstore/
2. Download new release, re-run ant install (updates /dspace/bin, /dspace/lib, /dspace/webapps)
3. Run: /dspace/bin/dspace database migrate
4. Redeploy ROOT.war to Tomcat
5. Upgrade dspace-angular separately (check its CHANGELOG for config changes)

## Gotchas

- **Two separate repos**: backend (DSpace/DSpace) and frontend (DSpace/dspace-angular) have separate release cycles. Versions must be compatible — check the compatibility matrix in docs.
- **Docker Compose is dev-only**: upstream explicitly states the provided docker-compose is not production-ready; use the manual install for production.
- **Solr cores must match DSpace version**: don't use stock Solr; copy DSpace's provided core configs.
- **pgcrypto extension**: must be enabled in the dspace database before running migrations.
- **Memory**: DSpace (Tomcat) needs at least 2GB heap; set JAVA_OPTS=-Xmx2048m in Tomcat config.
- **OAI-PMH**: served as a separate webapp (oai.war); deploy separately if needed.

## References

- Backend GitHub: https://github.com/DSpace/DSpace
- Frontend GitHub: https://github.com/DSpace/dspace-angular
- Installation docs (DSpace 7): https://wiki.lyrasis.org/display/DSDOC7x/Installing+DSpace
- Installation docs (DSpace 9): https://wiki.lyrasis.org/display/DSDOC9x/Installing+DSpace
- REST Contract: https://github.com/DSpace/RestContract
