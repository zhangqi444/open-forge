# Samvera Hyrax

**Digital repository framework** — a Ruby on Rails Engine for building institutional digital repositories. Part of the Samvera community ecosystem. Manages digital objects with flexible metadata, configurable deposit workflows, and Fedora-based storage. Used by libraries, archives, and research institutions.

**Official site:** https://samvera.org  
**Source:** https://github.com/samvera/hyrax  
**Docs / Wiki:** https://github.com/samvera/hyrax/wiki  
**License:** Apache-2.0

> ⚠️ **Framework, not a standalone app.** Hyrax is a Rails Engine that must be mounted inside a Rails application. You build a "Hyrax-based application" rather than deploying Hyrax directly.

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any | Docker Compose (development) | Official dev environment via `CONTAINERS.md` |
| Linux | Ruby on Rails (native) | Production deployments; see hyrax wiki |
| Kubernetes | Helm chart (hyrax-chart) | Latest release: `hyrax-chart-3.7.3` |

---

## System Requirements

- Ruby on Rails application (Hyrax is a Rails Engine, not a standalone app)
- Solr (search index)
- Fedora Commons (object storage) or ActiveFedora/Valkyrie backend
- Redis (background jobs via Sidekiq)
- PostgreSQL or MySQL/MariaDB
- FITS (file identification/characterization, optional but common)

---

## Inputs to Collect

### Application setup
| Input | Description |
|-------|-------------|
| Rails app name | Your institutional repository application name |
| `SOLR_URL` | Solr core URL |
| `FEDORA_URL` | Fedora repository URL |
| `REDIS_URL` | Redis URL for Sidekiq |
| `DATABASE_URL` | PostgreSQL/MySQL connection string |
| Admin email / password | Initial admin user |

---

## Software-layer Concerns

### Creating a Hyrax-based application
```bash
# Create a new Rails app
rails new my-repository
cd my-repository

# Add Hyrax to Gemfile
echo "gem 'hyrax'" >> Gemfile
bundle install

# Run Hyrax generator
rails generate hyrax:install

# Run migrations
rails db:create db:migrate

# Start the application
rails server
```

### Docker-based development
The repository provides a full Docker setup:
```bash
git clone https://github.com/samvera/hyrax
cd hyrax
# See CONTAINERS.md for the full Docker development workflow
docker compose up
```

### Helm chart (Kubernetes)
Latest chart: `hyrax-chart-3.7.3` (released 2026-04-13)
```bash
helm repo add samvera https://samvera.github.io/charts
helm install my-hyrax samvera/hyrax
```
See https://github.com/samvera/hyrax/tree/main/chart for values documentation.

### Key components
| Component | Purpose |
|-----------|---------|
| Solr | Full-text search and faceted browse |
| Fedora | Authoritative object/binary storage |
| Sidekiq | Background job processing (ingest, characterization) |
| Redis | Sidekiq queue backend |
| FITS | File format identification and technical metadata extraction |

---

## Upgrade Procedure

1. Update the `hyrax` gem version in `Gemfile`
2. Run `bundle update hyrax`
3. Review the [Hyrax release notes](https://github.com/samvera/hyrax/releases) for migration instructions
4. Run `rails db:migrate`
5. Re-run any Hyrax generators if prompted

---

## Gotchas

- **Not a standalone application.** You must create and maintain a Rails host application that mounts Hyrax.
- **Production deploys require institutional DevOps.** Hyrax + Fedora + Solr + Sidekiq is a complex stack. Plan for significant infrastructure work.
- **Fedora is optional with Valkyrie.** Hyrax supports the Valkyrie persistence layer, which allows using PostgreSQL as the object store instead of Fedora. Recommended for new deployments.
- **Community support via Slack.** The Samvera community uses Slack (`#dev` channel) — join at https://samvera.atlassian.net/wiki/spaces/samvera/pages/405211682/Getting+Started+in+the+Samvera+Community.
- **Not suitable for simple blogging/CMS.** Hyrax is purpose-built for institutional repository use cases (digital collections, ETDs, data management).

---

## References

- Upstream README: https://github.com/samvera/hyrax#readme
- Hyrax Wiki: https://github.com/samvera/hyrax/wiki
- Docker dev setup: https://github.com/samvera/hyrax/blob/main/CONTAINERS.md
- Samvera community: https://samvera.org
