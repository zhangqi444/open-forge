# WYGIWYH (What You Get Is What You Have)

**Opinionated self-hosted personal finance tracker built on a "spend this month's income this month" principle — with multi-currency, DCA tracking, automation rules, and an API.**
GitHub: https://github.com/eitchtee/WYGIWYH
Demo: https://wygiwyh-demo.herculino.com (demo@demo.com / wygiwyhdemo)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | PostgreSQL required |
| Unraid | Unraid Community App | Available in the store |

---

## Inputs to Collect

### Required
- `SECRET_KEY` — Django cryptographic signing key (must be unique and unpredictable)
- `SQL_DATABASE` — PostgreSQL database name
- `SQL_USER`, `SQL_PASSWORD`, `SQL_HOST`, `SQL_PORT` — database credentials
- `DJANGO_ALLOWED_HOSTS` — space-separated list of allowed hostnames/IPs
- `URL` — space-separated trusted origins with protocol (e.g. https://finance.example.com)

### Optional
- `ADMIN_EMAIL` + `ADMIN_PASSWORD` — auto-create admin account on first start (skip createsuperuser step)
- `HTTPS_ENABLED` — set true if serving behind HTTPS reverse proxy
- `INTERNAL_PORT` — container listen port (default: 8000)
- `ENABLE_SOFT_DELETE` — keep deleted transactions in DB for deduplication (default: false)
- `TASK_WORKERS` — async task worker count (default: 1)

---

## Software-Layer Concerns

### Install
```bash
mkdir WYGIWYH && cd WYGIWYH
# Download docker-compose.prod.yml from the repo
touch .env  # populate from .env.example in the repo
docker compose up -d
# Create admin (if ADMIN_EMAIL/ADMIN_PASSWORD not set):
docker compose exec -it web python manage.py createsuperuser
```

### Reference files
- Compose: https://github.com/eitchtee/WYGIWYH/blob/main/docker-compose.prod.yml
- Env example: https://github.com/eitchtee/WYGIWYH/blob/main/.env.example

### OIDC
- Supports OpenID Connect via django-allauth
- OIDC accounts auto-link to existing local accounts with matching email — only use trusted providers

### MCP Server
- Built-in MCP server for connecting AI agents to financial data

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d
3. docker compose exec web python manage.py migrate (if prompted)

---

## Gotchas

- Not a budgeting app by design — there are no budget envelopes or spending limits
- Set DJANGO_ALLOWED_HOSTS and URL correctly or you will get CSRF errors on form submissions
- HTTPS_ENABLED controls secure cookie flag; must be true when behind an HTTPS reverse proxy
- Demo mode disables API, Rules, Automatic Exchange Rates, and Import/Export
- Custom currencies supported (crypto, reward points, etc.)
- CHECK_FOR_UPDATES=true by default — makes a GitHub API call every 12 hours

---

## References
- GitHub: https://github.com/eitchtee/WYGIWYH#readme
- Compose file: https://github.com/eitchtee/WYGIWYH/blob/main/docker-compose.prod.yml
- Env example: https://github.com/eitchtee/WYGIWYH/blob/main/.env.example
