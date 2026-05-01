# SolidInvoice

**Open-source invoicing platform for freelancers and small businesses — quotes, invoices, recurring billing, and online payments.**
Official site: https://solidinvoice.co
GitHub: https://github.com/SolidInvoice/SolidInvoice

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Server + MySQL/MariaDB |
| Any Linux | Docker (single) | Quick start, no DB container |
| Any Linux | Bare metal | PHP 8.4+, MySQL/PostgreSQL required |

---

## Inputs to Collect

### All phases
- `DOMAIN` — public hostname (e.g. `invoice.example.com`)
- `DATA_DIR` — host path for app data (e.g. `/opt/solidinvoice/data`)
- `DB_NAME` — database name (e.g. `solidinvoice`)
- `DB_PASSWORD` — MySQL password (leave empty for `MYSQL_ALLOW_EMPTY_PASSWORD=1` dev setups)
- Payment gateway credentials (Stripe, PayPal, etc.) configured post-install via UI

---

## Software-Layer Concerns

### Config
- Web-based setup wizard runs on first access
- Payment gateways configured via Settings in the UI
- REST API token auth via `X-API-TOKEN` header
- Multi-tenancy supported (multiple companies per install)

### Data
- MySQL 8+ or PostgreSQL (MariaDB supported)
- App data volume: `/etc/solidinvoice` inside container

### Ports
- `8765` — web UI

### Docker Compose
```yaml
services:
  db:
    image: "mysql:8.0"
    volumes:
      - db_data:/var/lib/mysql
    restart: always
    environment:
      MYSQL_DATABASE: solidinvoice
      MYSQL_ALLOW_EMPTY_PASSWORD: 1
  app:
    image: "solidinvoice/solidinvoice:latest"
    depends_on:
      - db
    ports:
      - "8765:8765"
    restart: always
    volumes:
      - app_data:/etc/solidinvoice

volumes:
  db_data: {}
  app_data: {}
```

---

## Upgrade Procedure

1. `docker compose pull`
2. `docker compose up -d`
3. Check logs: `docker compose logs -f app`
4. Follow any migration prompts via the web UI

See [UPGRADE.md](https://github.com/SolidInvoice/SolidInvoice/blob/3.0.x/UPGRADE.md) for version-specific steps.

---

## Gotchas

- `MYSQL_ALLOW_EMPTY_PASSWORD=1` is for development only — set a real password in production
- PHP 8.4+ required for bare-metal installs; ext-curl, ext-gd, ext-intl, ext-openssl, ext-pdo, ext-soap, ext-xsl needed
- No per-client limits; MIT licensed
- Built-in MCP server for AI agent automation (v3+)

---

## References
- [Documentation](https://solidinvoice.co)
- [Docker Hub](https://hub.docker.com/r/solidinvoice/solidinvoice)
- [Upgrade Guide](https://github.com/SolidInvoice/SolidInvoice/blob/3.0.x/UPGRADE.md)
- [GitHub README](https://github.com/SolidInvoice/SolidInvoice#readme)
