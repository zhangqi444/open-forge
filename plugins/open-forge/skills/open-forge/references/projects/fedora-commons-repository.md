---
name: fedora-commons-repository
description: Fedora Commons Repository recipe for open-forge. Robust, modular digital repository for management and preservation of digital content. Widely used by libraries, archives, and research institutions. Java / WAR deployment. Apache-2.0. Source: https://github.com/fcrepo/fcrepo
---

# Fedora Commons Repository

Robust, modular digital repository system for managing and disseminating digital content. Purpose-built for digital libraries, archives, universities, and cultural heritage organizations. Provides a Linked Data Platform (LDP) and OCFL-based storage, REST API, RDF metadata, access controls, versioning, and fixity checking. Java web application deployed as a WAR file in Jetty or Tomcat. Apache-2.0 licensed. Stewardship by Lyrasis.

Not to be confused with Fedora Linux. This is Fedora (Flexible Extensible Digital Object Repository Architecture).

Upstream: https://github.com/fcrepo/fcrepo | Docs: https://wiki.lyrasis.org/display/FEDORA6x | Downloads: https://wiki.lyrasis.org/display/FF/Downloads

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Any | WAR in Jetty (embedded) | Quickstart via mvn jetty:run |
| Any | WAR in Tomcat | Production recommended |
| Any | WAR in Jetty (standalone) | Download from Lyrasis |
| Any | Docker | Community Docker images exist; see docs |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Base URL / context path | Default: http://localhost:8080/fcrepo/rest |
| config | Storage backend | Local filesystem (OCFL), S3, or other BinaryStore |
| config | Auth method | WebAC, external auth, or no auth for testing |
| config | Java heap | Fedora can be memory-intensive; tune -Xmx |
| config (optional) | Database | Modeshape / JCR backend config for metadata indexing |

## Software-layer concerns

- OCFL storage: Fedora 6+ uses the Oxford Common File Layout for object storage; data lives under `fcrepo.home` (default: ~/fcrepo-home)
- REST API: content and metadata accessible at `/fcrepo/rest/` via LDP-compliant HTTP
- Versioning: built-in version history (Memento-based) for all repository objects
- Fixity: checksum verification for stored binaries
- Auth: WebAC (Web Access Control) with ACL-based permissions; integrate with external IdP via Shiro or CAS
- Java 11+ required (Java 17 recommended for Fedora 6.x)

## Install -- Quick start (embedded Jetty via Maven)

For testing only:

```bash
git clone https://github.com/fcrepo/fcrepo.git
cd fcrepo
mvn install
cd fcrepo-webapp
mvn jetty:run
# API at http://localhost:8080/fcrepo/rest
```

## Install -- WAR in Tomcat (production)

1. Download the latest WAR from https://wiki.lyrasis.org/display/FF/Downloads
2. Deploy to Tomcat:

```bash
cp fcrepo.war /opt/tomcat/webapps/
# Start Tomcat
/opt/tomcat/bin/startup.sh
# API at http://yourserver:8080/fcrepo/rest
```

3. Configure storage and auth in `$CATALINA_HOME/conf/context.xml` or via system properties:

```bash
-Dfcrepo.home=/data/fcrepo-data \
-Dfcrepo.auth.principal.header.enabled=true
```

## Upgrade procedure

1. Back up the OCFL storage directory (fcrepo.home) and any database
2. Download the new WAR from https://wiki.lyrasis.org/display/FF/Downloads
3. Stop Tomcat, replace the WAR, start Tomcat
4. Check the release notes for migration steps: https://wiki.lyrasis.org/display/FEDORA6x/Upgrade+Guide

```bash
systemctl stop tomcat
cp fcrepo-new.war /opt/tomcat/webapps/fcrepo.war
systemctl start tomcat
```

## Gotchas

- Not a general-purpose file server: Fedora is designed for archival repositories with strict provenance, versioning, and preservation requirements -- not for everyday file sharing.
- Java heap tuning required: repositories with large binary content or heavy metadata indexing need significant heap (-Xmx2g or more).
- Authentication is not enabled by default: out of the box, the API is open. Configure WebAC or an external auth system before exposing to the network.
- OCFL storage is NOT directly human-readable: objects are stored in a content-addressed layout under fcrepo.home. Do not move or rename files manually.
- Community support via Lyrasis: mailing lists and Slack channels (DuraSpace/Lyrasis community); commercial support available.

## Links

- Source: https://github.com/fcrepo/fcrepo
- Documentation: https://wiki.lyrasis.org/display/FEDORA6x
- Downloads: https://wiki.lyrasis.org/display/FF/Downloads
- Upgrade guide: https://wiki.lyrasis.org/display/FEDORA6x/Upgrade+Guide
- Lyrasis: https://www.lyrasis.org
