---
name: XWiki
description: "Enterprise self-hosted wiki platform with structured data and application scripting. Docker. Java/Tomcat + PostgreSQL/MySQL/MariaDB. xwiki/xwiki-platform. Extensible, 900+ extensions, wiki applications, REST API."
---

# XWiki

**Enterprise-grade self-hosted wiki platform.** More than a wiki — XWiki is a structured content and application development platform. Create wikis, documentation, knowledge bases, and custom applications using wiki pages with scripting and structured data. 900+ extensions available. Used by enterprises, universities, and governments for internal knowledge management.

Built + maintained by **XWiki SAS** and open-source community. LGPL license.

- Upstream repo: <https://github.com/xwiki/xwiki-platform>
- Website: <https://www.xwiki.org>
- Docker Hub: <https://hub.docker.com/_/xwiki>
- Download + install: <https://www.xwiki.org/xwiki/bin/view/Download/>
- Docs: <https://www.xwiki.org/xwiki/bin/view/Documentation/>
- Extensions: <https://extensions.xwiki.org>

## Architecture in one minute

- **Java / Tomcat** application server
- **PostgreSQL** (recommended), MySQL, or MariaDB
- Docker Compose: `xwiki` + database containers
- Port **8080** (web UI)
- Data stored in `/usr/local/xwiki/data` volume
- Resource: **medium-high** — Java + database; 1–2 GB RAM minimum; 2+ GB recommended

## Compatible install methods

| Infra               | Runtime                     | Notes                                                           |
| ------------------- | --------------------------- | --------------------------------------------------------------- |
| **Docker Compose**  | `xwiki:lts-postgres-tomcat` | **Primary** — official Docker Hub image; several variants       |
| **WAR file**        | Tomcat + Java               | Deploy `.war` to existing Tomcat; database separately           |
| **Installer**       | `.jar` installer            | Interactive install wizard for Windows/Linux/macOS              |
| **DEB/RPM**         | Linux packages              | Via XWiki APT/YUM repo                                          |

## Docker image variants

| Tag | Database | Notes |
|-----|----------|-------|
| `lts-postgres-tomcat` | PostgreSQL | Recommended — latest LTS |
| `stable-postgres-tomcat` | PostgreSQL | Latest stable (may not be LTS) |
| `lts-mysql-tomcat` | MySQL | MySQL variant |
| `lts-mariadb-tomcat` | MariaDB | MariaDB variant |

## Install via Docker Compose (PostgreSQL)

```yaml
services:
  xwiki:
    image: xwiki:lts-postgres-tomcat
    container_name: xwiki
    depends_on:
      - db
    ports:
      - "8080:8080"
    environment:
      - DB_USER=xwiki
      - DB_PASSWORD=xwiki
      - DB_DATABASE=xwiki
      - DB_HOST=db
    volumes:
      - xwiki_data:/usr/local/xwiki/data
    restart: unless-stopped

  db:
    image: postgres:17-alpine
    container_name: xwiki_postgres
    environment:
      - POSTGRES_USER=xwiki
      - POSTGRES_PASSWORD=xwiki
      - POSTGRES_DB=xwiki
      - POSTGRES_INITDB_ARGS=--encoding=UTF8
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

volumes:
  xwiki_data:
  postgres_data:
```

Full Docker Compose examples: <https://github.com/xwiki/xwiki-docker>

## First boot

1. Start containers. **First-start is slow** — Java app deploys to Tomcat, database schema initializes.
2. Visit `http://localhost:8080` → XWiki installation wizard.
3. Follow wizard: select flavor (Standard = recommended for most users), install extensions.
4. Create admin account.
5. Configure XWiki settings (name, logo, registration, email).
6. Start creating pages and wikis.
7. Install extensions from the Extension Manager for added functionality.
8. Put behind TLS.

## Key concepts

| Concept | Description |
|---------|-------------|
| **Space** | Namespace grouping pages (like a section or folder) |
| **Page** | Individual content unit; supports wiki markup, structured data, scripting |
| **Flavor** | Pre-packaged XWiki installation profile (Standard = blog + apps; others for specific use cases) |
| **Extension** | Plugins for additional functionality (900+ available at extensions.xwiki.org) |
| **XClass** | Structured data schema attached to pages (like a database schema for wiki pages) |
| **XObject** | Instance of an XClass attached to a page (structured data record) |
| **Script** | Groovy/Velocity scripting inside pages for dynamic content and mini-apps |
| **Macro** | Reusable content and feature blocks |
| **Wiki Farm** | Multiple wikis managed from a single XWiki instance (multi-tenancy) |

## Notable extensions

- **Blog** — blogging platform built on wiki pages
- **Forum** — discussion boards
- **Meeting** — meeting notes and minutes
- **Project Management** — task tracking
- **Confluence Migrator** — import from Atlassian Confluence
- **Office Document Viewer** — preview Word/Excel/PDF in wiki
- **LDAP/SAML/OIDC** — enterprise authentication
- **Structured Data** — spreadsheet-like tables in wiki pages

## Gotchas

- **First startup takes minutes.** XWiki deploys a large Java application on first boot — it may take 2–5 minutes before the web UI is reachable. Don't kill the container. Watch `docker logs xwiki`.
- **Memory.** XWiki needs real RAM. Tomcat JVM defaults may be too low — set `JAVA_OPTS=-Xmx1024m -Xms512m` or more in environment. 2 GB RAM for the host is the practical minimum for comfortable use.
- **`POSTGRES_INITDB_ARGS=--encoding=UTF8`** is required for the PostgreSQL container on first init. Without UTF8 encoding, XWiki will fail to initialize the database schema on some locales.
- **Flavor selection.** During the wizard, pick "XWiki Standard Flavor" for a standard wiki with blog and apps. Other flavors are for specific enterprise use cases. The flavor installs a curated set of extensions.
- **Extension Manager vs manual install.** Most extensions install via the in-browser Extension Manager (no restart needed). Some require manual JAR deployment to Tomcat.
- **Wiki Farm.** A single XWiki instance can host multiple separate wikis (sub-wikis). Useful for multi-department or multi-project setups.
- **Confluence migration.** XWiki has a dedicated Confluence Migrator extension — useful if moving from Atlassian's cloud pricing.
- **Scripting security.** XWiki pages can run Groovy scripts. Grant scripting rights carefully — only to trusted admin users. Untrusted users should not have script execution rights.
- **Long-term support (LTS) vs stable.** Use the LTS tag for production — it receives security patches longer. Stable may include newer features but has a shorter support window.

## Backup

```sh
# Stop + dump DB
docker compose stop xwiki
docker compose exec db pg_dump -U xwiki xwiki > xwiki-$(date +%F).sql
# Data volume
sudo tar czf xwiki-data-$(date +%F).tgz xwiki_data/
docker compose start xwiki
```

Or use XWiki's built-in Export (page-level or full-farm export in XAR format).

## Upgrade

1. Releases: <https://www.xwiki.org/xwiki/bin/view/ReleaseNotes/>
2. `docker compose pull && docker compose up -d`
3. XWiki handles DB migrations on startup; check the admin panel for any post-upgrade tasks.
4. For major version upgrades, read the migration guide first.

## Project health

20+ year old project, very active Java development, 900+ extensions, official Docker images (multiple variants), enterprise support from XWiki SAS, large community, JIRA issue tracker. LGPL license.

## Wiki-platform-family comparison

- **XWiki** — Java+Tomcat, enterprise, structured data + scripting, 900+ extensions, wiki farm, LGPL
- **MediaWiki** — PHP, Wikipedia's engine, page-focused, massive extensions, simpler data model
- **Confluence** — SaaS/self-hosted, Atlassian, enterprise; XWiki is the open-source alternative
- **BookStack** — PHP, simple book/shelf hierarchy, great for documentation; much simpler than XWiki
- **WikiJS** — Node.js, modern UI, markdown-first, simpler than XWiki
- **Outline** — Node.js, knowledge base, modern Notion-like; no scripting

**Choose XWiki if:** you need an enterprise wiki platform with structured data, application scripting, multi-wiki farm support, and 900+ extensions — particularly as an open-source alternative to Confluence.

## Links

- Repo: <https://github.com/xwiki/xwiki-platform>
- Docker Hub: <https://hub.docker.com/_/xwiki>
- Docker Compose examples: <https://github.com/xwiki/xwiki-docker>
- Extensions: <https://extensions.xwiki.org>
- Docs: <https://www.xwiki.org/xwiki/bin/view/Documentation/>
- Download: <https://www.xwiki.org/xwiki/bin/view/Download/>
