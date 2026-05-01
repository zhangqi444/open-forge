---
name: ProjectSend
description: "Self-hosted client portal for file sharing. Freelancers, agencies, accountants, photographers, architects, NGOs. PHP. Maintained since 2011. projectsend.org. Demo + docs. Static-analysis + asset-build CI."
---

# ProjectSend

ProjectSend is **"Dropbox-Business / ShareFile / Hightail — but self-hosted, for client-facing portals"** — a client portal for file-sharing with external clients, partners, teams. Built for freelancers, agencies, accountants, photographers, architects, NGOs — any business that sends files to external people. **Maintained since 2011** — decade-plus.

Built + maintained by **projectsend** org. PHP. Website + docs + demo. PHP static-analysis + asset-build CI.

Use cases: (a) **freelancer-to-client deliverables portal** (b) **agency-to-client proofs/assets** (c) **accountant-to-client documents** (d) **photographer-to-client galleries** (e) **architect-to-client plans** (f) **NGO-to-partner file-sharing** (g) **large-file-delivery with audit-trail** (h) **branded client-portal on your own domain**.

Features (per README + website):

- **Self-hosted client portal**
- **Per-client access**
- **File versioning**
- **Client + user roles**
- **Multi-language**
- **Demo available**
- **Maintained since 2011**

- Upstream repo: <https://github.com/projectsend/projectsend>
- Website: <https://www.projectsend.org>
- Docs: <https://docs.projectsend.org>
- Demo: <https://www.projectsend.org/demo/>

## Architecture in one minute

- **PHP**
- **MySQL/MariaDB**
- LAMP-stack or Docker
- **Resource**: moderate; files use disk
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Community-maintained                                                                                                   | Alt                                                                                   |
| **LAMP**           | Traditional PHP-MySQL                                                                                                  | Primary                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `files.example.com`                                         | URL          | **TLS MANDATORY — client files**                                                                                    |
| PHP version          | 8.X                                                         | Runtime      | Check docs for supported                                                                                    |
| MySQL/MariaDB        | Data                                                        | DB           |                                                                                    |
| Admin                | First-boot                                                  | Bootstrap    |                                                                                    |
| File storage path    | `/var/www/files`                                            | Storage      |                                                                                    |
| SMTP                 | Notifications                                               | Email        |                                                                                    |

## Install (LAMP)

See <https://docs.projectsend.org/install/>. Typical:
1. Install PHP 8.X + extensions + MySQL + web server (nginx/Apache)
2. Clone ProjectSend into web-root
3. Create MySQL database + user
4. Run web-installer
5. Configure file-upload path + size limits
6. SMTP for client-notifications

## Install via Docker

Community images exist. Pin the version. Example:
```yaml
services:
  mysql:
    image: mysql:8
    environment:
      MYSQL_DATABASE: projectsend
      MYSQL_USER: projectsend
  projectsend:
    image: linuxserver/projectsend:latest        # **pin**
    ports: ["80:80"]
    depends_on: [mysql]
    volumes:
      - ./projectsend-data:/config
      - ./projectsend-uploads:/uploads
    environment:
      - PUID=1000
      - PGID=1000
```

## First boot

1. Run web-installer
2. Create admin
3. Create first client account
4. Upload sample files
5. Test client login + download
6. Configure SMTP for notifications
7. Put behind TLS
8. Configure file-size limits
9. Back up DB + /uploads

## Data & config layout

- MySQL — users, clients, files, access-logs
- `/uploads/` — actual files

## Backup

```sh
mysqldump projectsend > projectsend-$(date +%F).sql
sudo tar czf projectsend-uploads-$(date +%F).tgz projectsend-uploads/
# Contains client files + access logs + user PII — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/projectsend/projectsend/releases>
2. **Backup DB + files first** — PHP-ecosystem upgrades occasionally need manual steps
3. Read release notes

## Gotchas

- **174th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — CLIENT-FACING-DOCUMENT-PORTAL**:
  - Holds: **all client-facing files** — contracts, proofs, designs, financial docs, confidential photos/plans
  - Per-client access = audit-grade separation
  - User + client credentials, SMTP
  - **174th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - Parallels oCIS (122) + Seafile — but distinct because **client-external-facing**, not team-internal
  - **NEW CROWN-JEWEL Tier 1 sub-category: "client-portal + external-facing-file-sharing"** (1st — ProjectSend; distinct from internal team-collab like oCIS)
  - **CROWN-JEWEL Tier 1: 60 tools / 54 sub-categories** 🎯 **60-TOOL CROWN-JEWEL MILESTONE at ProjectSend**
- **EXTERNAL-CLIENT-ACCESS-ATTACK-SURFACE**:
  - External clients log in = public-facing auth
  - Weak-client-password = breach vector
  - **Recipe convention: "external-client-weak-password-enforcement callout"**
  - **NEW recipe convention** (ProjectSend 1st formally)
- **DECADE-PLUS-OSS (MAINTAINED SINCE 2011)**:
  - **Decade-plus-OSS: 11 tools** (+ProjectSend) 🎯 **11-TOOL MILESTONE**
- **PHP-STATIC-ANALYSIS CI**:
  - CI runs phpstan/psalm
  - Security + quality
  - **Recipe convention: "PHP-static-analysis-CI positive-signal"**
  - **NEW positive-signal convention** (ProjectSend 1st formally)
- **ASSET-BUILD-CI**:
  - Separate CI job for frontend assets
  - **Recipe convention: "separate-asset-build-CI-discipline positive-signal"**
  - **NEW positive-signal convention** (ProjectSend 1st formally)
- **CLIENT-AUDIENCE-EXPLICITLY-LISTED**:
  - README names audience: freelancers, agencies, accountants, photographers, architects, NGOs
  - Clear positioning
  - **Recipe convention: "explicit-audience-enumeration positive-signal"**
  - **NEW positive-signal convention** (ProjectSend 1st formally)
- **LIVE-DEMO**:
  - projectsend.org/demo
  - **Live-demo-available: N tools** (continuing family)
- **LAMP-STACK-COMPATIBILITY**:
  - Broadest-possible shared-hosting audience
  - **Recipe convention: "LAMP-stack-compatibility positive-signal"**
  - **NEW positive-signal convention** (ProjectSend 1st formally)
- **UPLOAD-SIZE-LIMITS-PHP-CONFIG**:
  - PHP upload-size settings apply
  - Must configure php.ini + nginx/apache limits
  - **Recipe convention: "PHP-upload-size-multi-layer-config callout"**
  - **NEW recipe convention** (ProjectSend 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: projectsend org + website + docs + demo + decade-plus-2011 + static-analysis-CI + asset-build-CI. **160th tool 🎯 160-TOOL MILESTONE in institutional-stewardship family — decade-plus-client-portal sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + static-analysis + asset-build + docs + demo + decade-plus. **166th tool in transparent-maintenance family.**
- **CLIENT-PORTAL-CATEGORY:**
  - **ProjectSend** — classic PHP; decade-plus
  - **Pydio Cells** — Go; enterprise
  - **Nextcloud + sharing** — team-first, not client-portal-first
  - **ShareFile/Dropbox Business** — commercial SaaS
  - **FileRun** — commercial; self-hosted option
- **ALTERNATIVES WORTH KNOWING:**
  - **Pydio Cells** — if you want Go + enterprise
  - **Nextcloud** — if you want broader file-sync + team
  - **Choose ProjectSend if:** you want decade-plus + PHP + client-portal-first + LAMP-simple.
- **PROJECT HEALTH**: active + decade-plus + CI + docs + demo. Very strong.

## Links

- Repo: <https://github.com/projectsend/projectsend>
- Website: <https://www.projectsend.org>
- Pydio Cells (alt): <https://github.com/pydio/cells>
