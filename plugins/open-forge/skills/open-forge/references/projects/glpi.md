---
name: GLPI
description: "Free asset + IT management (ITSM) platform — ITIL service desk, CMDB, incidents, problems, changes, contracts, licenses, knowledge base, DCIM, projects, SLM. French acronym for 'Gestionnaire Libre de Parc Informatique'. PHP + MySQL/MariaDB. GPL-3.0."
---

# GLPI

GLPI is **the go-to open-source ITSM + asset management platform** — standing for **Gestionnaire Libre de Parc Informatique** (French: "Free IT Inventory Manager"). Deployed widely in French-speaking enterprises, schools, municipalities, and globally. Direct competitor to ServiceNow / Jira Service Management / ManageEngine / Ivanti / Cherwell / Freshservice. Covers the full ITIL stack: CMDB (assets + configs), service desk (tickets/incidents/problems/changes), contracts + licenses, knowledge base, DCIM, project management, SLM, service catalog — under **one roof, fully FOSS**.

First released **2003**; 20+ years mature. Commercial support via **Teclib'** (the current stewards).

Features:

- **SACM (Service Asset & Configuration Management)** — CMDB with computers, network gear, printers, software, peripherals, VMs
- **Native dynamic inventory** (v10+) — agents push inventory; no separate FusionInventory needed
- **Request fulfillment + incident + problem management** — full ITIL workflow
- **Change management** — CAB approvals, change windows, rollback plans
- **Knowledge base + FAQ**
- **Contract + vendor management** — warranty, renewals, SLAs
- **Financial management** — purchases, depreciation, TCO
- **Software + license management** — compliance, allocation
- **DCIM** — rack + power + network topology
- **Impact analysis** — change preview
- **Service catalog + SLM** — tiered service levels
- **Asset reservation** — book conference room AV kit etc.
- **Entity separation** — multi-org / multi-school / multi-client
- **Project + task management**
- **Intervention planning** — field service
- **Plugins** — rich plugin ecosystem at <http://plugins.glpi-project.org>
- **REST API**
- **LDAP/AD + SAML/OIDC SSO**

- Upstream repo: <https://github.com/glpi-project/glpi>
- Website: <https://glpi-project.org>
- Plugins directory: <https://plugins.glpi-project.org>
- Docs: <https://glpi-project.org/documentation/>
- Demo (commercial): <https://www.glpi-network.cloud>
- Commercial: <https://www.teclib-edition.com>
- Forum: <https://forum.glpi-project.org>

## Architecture in one minute

- **PHP** (7.4+ / 8.x) web app
- **MySQL / MariaDB** — primary DB
- **Apache / Nginx** front web
- **GLPI Agent** (optional) — installed on endpoints for dynamic inventory (replaces older FusionInventory-Agent + OCS-Inventory paths)
- **Cron / systemd timer** — runs GLPI scheduled tasks (auto-actions, notifications, inventory polls)
- **Resource**: small orgs (<500 assets) fine on 2 GB RAM; 10k+ assets needs tuning + MariaDB optimization

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                         |
| ------------------ | -------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM          | **Native (Apache/Nginx + PHP-FPM + MariaDB)**                      | **Upstream-documented primary path**                                              |
| Single VM          | **Docker Compose** (community + official images)                           | Well-documented                                                                           |
| Kubernetes         | Community Helm charts                                                                       | Works                                                                                                   |
| Managed            | **GLPI Network** (cloud SaaS, commercial by Teclib')                                                     | Paid hosted                                                                                                          |
| Raspberry Pi       | Small home-lab use; underpowered for corporate workloads                                                                |                                                                                                                                 |

## Inputs to collect

| Input              | Example                             | Phase       | Notes                                                                   |
| ------------------ | ----------------------------------- | ----------- | ----------------------------------------------------------------------- |
| Domain             | `glpi.example.com`                     | URL         | Behind TLS reverse proxy                                                        |
| DB                 | MariaDB 10.6+ / MySQL 8             | DB          | Strong password                                                                             |
| Admin              | `glpi` / `glpi` (default on install)            | Bootstrap   | **Change defaults — there are FOUR** (see gotchas)                                                              |
| SMTP               | for notifications                                       | Email       | Required for ticket workflow                                                                                        |
| LDAP (opt)         | AD/LDAP bind                                                        | Auth        | Typical in enterprise                                                                                                                |
| Cron               | `/usr/bin/php /var/www/glpi/front/cron.php`                           | Schedule    | Run every 1-5 min; **critical for notifications + SLAs**                                                                                                          |

## Install via Docker Compose (community image)

Several community images exist; e.g., `diouxx/glpi`. A typical compose:

```yaml
services:
  glpi-db:
    image: mariadb:10.11
    environment:
      MARIADB_ROOT_PASSWORD: CHANGE_ME
      MARIADB_DATABASE: glpi
      MARIADB_USER: glpi
      MARIADB_PASSWORD: CHANGE_ME
    volumes:
      - ./db:/var/lib/mysql
  glpi:
    image: diouxx/glpi:latest   # GLPI v11 now stable; pin specific tag once diouxx image tracks v11
    depends_on:
      - glpi-db
    environment:
      TIMEZONE: Europe/Paris
    ports:
      - "8080:80"
    volumes:
      - ./glpi:/var/www/html/glpi
```

Browse `http://<host>:8080/` → installer wizard.

## First boot

1. Browse installer → language → accept license → DB connection (host=`glpi-db`, user=`glpi`)
2. Installer creates schema + default accounts
3. **Log in as `glpi` / `glpi`** → immediately change ALL four default passwords (see below)
4. Configure entity hierarchy (`Administration → Entities`) if multi-org
5. Configure LDAP (`Setup → Authentication → LDAP directories`)
6. Set up notifications (`Setup → Notifications → Email followups`)
7. **Set up cron** — hook the GLPI cron runner or container handles it
8. Install GLPI Agent on endpoints for dynamic inventory
9. Configure SLAs, entities, tickets workflow
10. Customize forms + dropdowns for your org

## Data & config layout

- `/var/www/html/glpi/` (native) or `/var/www/html/` (container) — app code
- `/var/www/html/glpi/files/` — uploaded docs, logs, cached data
- `/var/www/html/glpi/config/` — `config_db.php` (DB creds) + local config
- Database — **all** operational data

## Backup

```sh
# DB (CRITICAL — tickets + CMDB + everything)
docker exec glpi-db mariadb-dump -u root -p$ROOT_PASS glpi | gzip > glpi-db-$(date +%F).sql.gz
# Files (uploads + config)
docker run --rm --volumes-from glpi alpine tar czf - /var/www/html/glpi/files /var/www/html/glpi/config | gzip > glpi-files-$(date +%F).tgz
```

Backup retention per ITIL policy (often 7+ years for tickets/contracts for audit/compliance).

## Upgrade

1. Releases: <https://github.com/glpi-project/glpi/releases>. Active; regular minors.
2. **Back up DB + files.**
3. **Read upgrade notes** for major versions — often have required steps (e.g., PHP version upgrade, plugin compat).
4. Native: replace `glpi/` dir; visit web installer → "Upgrade".
5. Docker: bump tag; migrations auto on first boot (logs).
6. Verify plugins are compatible with new version — check plugin pages before upgrading.

## Gotchas

- **FOUR default accounts** — all with predictable creds; **change ALL on day 1**:
  - `glpi` / `glpi` — super-admin
  - `tech` / `tech` — technician
  - `normal` / `normal` — normal user
  - `post-only` / `postonly` — post-only user
- **Cron is critical** — many features (SLA tracking, notifications, auto-close, inventory) only work when cron runs. Verify it's running after install.
- **File permissions**: `files/` + `config/` must be writable by web user. Common install failure.
- **PHP version compat**: GLPI is picky about PHP versions. Check supported range before install (e.g., GLPI 10.0 = PHP 7.4-8.2).
- **Plugin ecosystem is huge but variable-quality**: popular plugins (FusionInventory historically, formcreator, genericobject, moreticket) are solid; others unmaintained. Check last-commit date.
- **Migration from OCS-Inventory / FusionInventory**: both are effectively superseded by the native GLPI Agent (v10+). Migration path documented; plan carefully.
- **French-first project**: docs + forum + support frequently French-first, English translations sometimes lag. Communities are friendly but a French speaker helps.
- **Entities ≠ tenants**: GLPI's entity system partitions data but still one DB. True multi-tenancy (hard isolation) not the model.
- **Performance at scale**: 100k+ asset deployments need MariaDB tuning, query-cache, innodb_buffer_pool, disabled-feature pruning. Commercial support helpful.
- **Backup restore test**: do it. Tickets + CMDB are audit-critical — restoration procedure should be practiced annually.
- **Notifications SMTP**: tickets rely on email threading. Configure `Followup` emails carefully — SMTP errors = silent ticket workflow failures.
- **API authentication**: uses user_token + app_token. Scope app_tokens narrowly.
- **ITIL terminology**: GLPI uses ITIL terms (Request, Incident, Problem, Change). If your org doesn't do ITIL, configure ticket categories + workflows to match your lexicon.
- **License + commercial**: core is **GPL-3.0**. Teclib' sells commercial support + "GLPI Network" cloud + commercial plugins.
- **SaaS alternative**: GLPI Network (<https://www.glpi-network.cloud>) is the official hosted version — consider if you don't want to operate.
- **Alternatives worth knowing:**
  - **Snipe-IT** — asset-focused; lighter ITSM (separate recipe likely)
  - **iTop** — French ITSM/CMDB; similar space; commercial lean
  - **OTRS / Znuny** — ticket-management-focused
  - **osTicket** — simpler help desk; no CMDB
  - **Zammad** — modern ticket system (separate recipe)
  - **ServiceNow / Jira Service Management / Freshservice / ManageEngine** — commercial SaaS
  - **Nagios/Zabbix** — monitoring (see batch 68 Zabbix), not ITSM — different space
  - **Choose GLPI if:** full ITIL stack + CMDB + free + mature.
  - **Choose Snipe-IT if:** just asset management, simpler.
  - **Choose Zammad/osTicket if:** just help desk.
  - **Choose ServiceNow/Jira SM if:** enterprise SaaS acceptable.

## Links

- Repo: <https://github.com/glpi-project/glpi>
- Website: <https://glpi-project.org>
- Docs: <https://glpi-project.org/documentation/>
- Plugins: <https://plugins.glpi-project.org>
- Forum: <https://forum.glpi-project.org>
- GLPI Agent: <https://github.com/glpi-project/glpi-agent>
- Releases: <https://github.com/glpi-project/glpi/releases>
- GLPI Network (commercial/cloud): <https://www.glpi-network.cloud>
- Teclib' (commercial): <https://www.teclib-edition.com>
- Snipe-IT (alt, asset-only): <https://snipeitapp.com>
- iTop (alt): <https://www.combodo.com/itop>
- Zammad (alt, help desk): <https://zammad.org>
