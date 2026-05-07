---
name: eprints
description: EPrints recipe for open-forge. Digital document management and institutional repository system for academic institutions. Source: https://github.com/eprints/eprints3.4
---

# EPrints

A digital document management system with flexible metadata and workflow model, primarily aimed at academic institutions for building open-access repositories, e-thesis collections, and research data archives. GPL-3.0 licensed, written in Perl. Upstream: <https://github.com/eprints/eprints3.4>. Website: <https://www.eprints.org/>. Demo: <http://tryme.demo.eprints-hosting.org/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian/Ubuntu VPS | Native Perl + Apache + MySQL | Official/recommended install method |
| Any Linux | Docker | Community-maintained Docker image available |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "What domain will EPrints be served from?" | FQDN | e.g. eprints.example.org |
| "Repository ID / short name?" | Alphanumeric, no spaces | Used internally; e.g. myrepo |
| "Admin email address?" | Email | Used for system notifications |
| "Institution/organisation name?" | String | Displayed in repository UI |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "MySQL root password?" | String (sensitive) | For initial database setup |
| "EPrints database user password?" | String (sensitive) | Created during install |
| "SMTP relay for outbound mail?" | Host:port | EPrints sends deposit notifications and admin alerts |

## Software-Layer Concerns

- **Stack**: Apache + mod_perl + MySQL + Perl. EPrints is tightly coupled to Apache/mod_perl; NGINX is not officially supported.
- **Config files**: Main config at `/opt/eprints3/archives/<repoid>/cfg/cfg.d/`. Each repository is a subdirectory under `archives/`.
- **Data dirs**: `/opt/eprints3/archives/<repoid>/documents/` (uploaded files), `/opt/eprints3/archives/<repoid>/cfg/` (config).
- **Indexer**: Background `epadmin indexer start` process must run for full-text search to work.
- **Cron jobs**: `epadmin generate_views`, `epadmin generate_abstracts`, nightly stats — configure in crontab for the eprints user.
- **Plugins**: Bazaar (EPrints plugin repository) allows installing themes and plugins via admin UI.
- **Upgrades**: Use the EPrints upgrade script; always back up database and documents before upgrading.

## Deployment

### Debian/Ubuntu (recommended)

```bash
# Add EPrints Debian repo
wget -O /etc/apt/trusted.gpg.d/eprints.asc https://files.eprints.org/eprints.asc
echo "deb https://files.eprints.org/debian bullseye main" > /etc/apt/sources.list.d/eprints.list
apt update && apt install eprints

# Create repository
epadmin create
# Follow prompts: repoid, hostname, admin email, DB credentials

# Start Apache and indexer
service apache2 start
epadmin indexer start <repoid>
```

### Docker (community)

Search Docker Hub for community EPrints images. Official Docker support is not provided upstream — verify image freshness before use.

## Upgrade Procedure

1. Back up: mysqldump the database + tar the archives directory.
2. Download new EPrints release from https://github.com/eprints/eprints3.4/releases
3. Follow upgrade guide at https://wiki.eprints.org/w/Upgrading
4. Run `epadmin upgrade <repoid>` for each repository.
5. Restart Apache and indexer.

## Gotchas

- **mod_perl required**: EPrints will not run under FastCGI or PHP — Apache + mod_perl is the only upstream-supported method.
- **Perl version sensitivity**: Requires specific Perl version range; check upstream release notes.
- **Full-text indexer**: Must be running as a background daemon; easy to forget after server reboots — add to init/systemd.
- **Large file uploads**: Apache `LimitRequestBody` and PHP-style upload limits don't apply, but Apache `MaxRequestBodySize` / network timeouts can interrupt large document uploads.
- **Complex metadata model**: EPrints uses its own XML-based metadata schema — customisation requires Perl knowledge.
- **No Docker-first path**: Upstream's blessed install is Debian packages; Docker is community territory.

## Links

- Source: https://github.com/eprints/eprints3.4
- Website: https://www.eprints.org/
- Wiki / Upgrade guide: https://wiki.eprints.org/
- Releases: https://github.com/eprints/eprints3.4/releases
- Demo: http://tryme.demo.eprints-hosting.org/
