# Noosfero

**Platform for social and solidarity economy networks** — Ruby on Rails web platform combining blog, e-Portfolios, CMS, RSS feeds, thematic discussion, events calendar, and collective intelligence tools in one system. Designed for social economy organizations and networks.

**Official site:** https://gitlab.com/noosfero/noosfero
**Source:** https://gitlab.com/noosfero/noosfero
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Ruby on Rails + PostgreSQL | Primary supported stack |
| Any VPS / bare metal | Docker | Dockerfile included in repository |

---

## Inputs to Collect

### Phase 1 — Planning
- Domain / hostname
- Language / locale (multilingual support)
- Whether to enable federation/network features between Noosfero instances

### Phase 2 — Deploy
- PostgreSQL credentials
- SMTP/mail config
- Redis connection (for background jobs)
- Secret key base

---

## Software-Layer Concerns

- **Stack:** Ruby on Rails, PostgreSQL, Redis (for background processing), Solr (for search)
- **Multi-tenant:** Supports multiple communities/organizations within one installation
- **Features:** Blogs, e-Portfolios, CMS pages, events, discussion forums, RSS, file management, plugins
- **Search:** Apache Solr for full-text search (optional but recommended)
- **Plugin system:** Extend functionality via plugins

---

## Deployment

Follow the installation guide in the repository:
https://gitlab.com/noosfero/noosfero/-/blob/master/doc/install.md

Key steps:
1. Install Ruby, PostgreSQL, Redis, and optionally Solr
2. Clone the repository and install gems: `bundle install`
3. Configure `config/database.yml` and `config/noosfero.yml`
4. Run database setup: `rake db:setup`
5. Start with Passenger, Puma, or a similar Rack server behind Nginx/Apache

---

## Upgrade Procedure

```bash
git pull
bundle install
rake db:migrate
# Restart application server
```

---

## Gotchas

- **Solr search** — search functionality requires a running Solr instance; without it, search is limited
- **Redis required** for background job processing (Sidekiq/Delayed Job)
- **Multi-tenant complexity** — managing multiple communities on one instance requires understanding of Noosfero's environment/domain model
- **Low recent activity** — last significant commits were mid-2025; check the repository for current maintenance status before deploying in production
- **Brazilian origin** — developed primarily by COLIVRE in Brazil; community and some docs are in Portuguese

---

## Links

- Upstream README: https://gitlab.com/noosfero/noosfero/-/blob/master/README.md
- Installation guide: https://gitlab.com/noosfero/noosfero/-/blob/master/doc/install.md
