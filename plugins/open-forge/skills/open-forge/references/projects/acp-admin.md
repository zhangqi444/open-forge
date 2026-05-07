# ACP Admin (CSA/ACP/Solawi Admin)

**Web application for managing Community Supported Agriculture organizations** — Ruby on Rails multi-tenant platform for CSA (Community Supported Agriculture), ACP (Agriculture Contractuelle de Proximité), and Solawi (Solidarische Landwirtschaft). Handles memberships, basket deliveries, invoicing, payments, and member communications. Used by 30+ organizations across Switzerland, Germany, and the Netherlands.

**Official site:** https://acp-admin.ch / https://csa-admin.org
**Source:** https://github.com/csa-admin-org/csa-admin
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Ruby on Rails + SQLite | One SQLite DB per tenant; primary supported stack |

---

## Inputs to Collect

### Phase 1 — Planning
- Organization name and subdomain structure
- Language: en, fr, de, it, or nl
- Whether hosting single or multiple organizations (multi-tenant)

### Phase 2 — Deploy
- Admin and member hostnames (subdomains)
- Postmark API key (for transactional email and newsletters)
- Rails credentials / secret key base
- EBICS credentials (optional, for automatic bank payment import)

---

## Software-Layer Concerns

- **Stack:** Ruby on Rails, SQLite (one database per tenant), SolidQueue/ActiveJob for async jobs
- **Multi-tenant:** Each tenant is resolved by request subdomain; completely isolated SQLite databases
- **Email:** Transactional emails and newsletters sent via **Postmark** (not generic SMTP)
- **Async jobs:** SolidQueue backed by SQLite; no Redis/Sidekiq required
- **Config file:** `config/tenant.yml` — define admin/member subdomains per tenant
- **Features:** Member management, basket subscriptions, depot locations, delivery cycles, invoicing, QR-code/SEPA payment references, EBICS bank import, bidding rounds for solidarity pricing, activity participation, newsletters

---

## Deployment

```bash
git clone https://github.com/csa-admin-org/csa-admin
cd csa-admin
cp config/tenant.yml.example config/tenant.yml
# Edit config/tenant.yml with your admin and member hostnames
bin/setup
```

For local subdomain routing, use [puma-dev](https://github.com/puma/puma-dev):
- Admin UI: `https://admin.my-domain.test`
- Member portal: `https://members.my-domain.test`

Full documentation: https://csa-admin.org

---

## Upgrade Procedure

```bash
git pull
bundle install
bin/rails db:migrate
# Restart application server
```

---

## Gotchas

- **Postmark required** for email — the app is wired to Postmark, not generic SMTP; you need a Postmark account
- **Subdomain-based multi-tenancy** — DNS must be configured to point all subdomains to the server; wildcard DNS recommended
- **French-primary documentation** — `acp-admin.ch` docs are in French; csa-admin.org has multilingual content
- **EBICS for payment import** — automatic bank statement processing requires EBICS access from your bank; optional but powerful for larger organizations
- **SQLite per tenant** — works well for CSA scale; not a concern unless running hundreds of tenants

---

## Links

- Upstream README: https://github.com/csa-admin-org/csa-admin#readme
- Official site: https://csa-admin.org
- ACP Admin (French): https://acp-admin.ch
