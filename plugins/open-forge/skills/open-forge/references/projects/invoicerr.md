# Invoicerr

**Open source invoicing for freelancers — create and manage quotes and invoices, track status, built-in PDF generation, email sending, JWT/OIDC auth, and a plugin system.**
GitHub: https://github.com/invoicerr-app/invoicerr

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux amd64 / arm64 | Docker Compose + PostgreSQL | Recommended |

> arm/v7 (32-bit ARM) not supported due to Prisma binary requirements.

---

## Inputs to Collect

### Required
- `DATABASE_URL` — PostgreSQL connection string
- `APP_URL` — public URL (used in email templates)
- `CORS_ORIGINS` — comma-separated list of allowed origins
- `JWT_SECRET` — random string for JWT auth

### Optional (email features)
- `SMTP_HOST`, `SMTP_USER`, `SMTP_FROM`, `SMTP_PASSWORD`, `SMTP_PORT`, `SMTP_SECURE`

### Optional (OIDC)
- `OIDC_ISSUER`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, and endpoint URLs

---

## Software-Layer Concerns

### Docker Compose
```yaml
services:
  invoicerr:
    image: ghcr.io/invoicerr-app/invoicerr:latest
    ports:
      - "80:80"
    environment:
      - DATABASE_URL=postgresql://invoicerr:invoicerr@invoicerr_db:5432/invoicerr_db
      - APP_URL=https://invoicerr.example.com
      - CORS_ORIGINS=https://invoicerr.example.com
      - JWT_SECRET=your_jwt_secret
      # SMTP settings for email features:
      - SMTP_HOST=smtp.example.com
      - SMTP_USER=user@example.com
      - SMTP_PASSWORD=your_smtp_password
      - SMTP_PORT=587
      - SMTP_SECURE=false
    depends_on:
      - invoicerr_db

  invoicerr_db:
    image: postgres:15
    environment:
      POSTGRES_USER: invoicerr
      POSTGRES_PASSWORD: invoicerr
      POSTGRES_DB: invoicerr_db
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

### Ports
- `80` — web UI

### Key features
- Create/manage invoices and quotes (quotes convertible to invoices)
- Client management with contact details
- Status tracking (signed, paid, unread, etc.)
- Built-in quote signing with secure tokens
- PDF generation (quotes, invoices, receipts)
- Send quote/invoice emails directly from the app
- Custom brand identity (logo, company name, VAT)
- JWT or OIDC authentication
- Plugin system for community extensions
- SQLite option available for quick local setups (see repo)

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- `APP_URL` must be set correctly — it's used in all outbound email template links
- `CORS_ORIGINS` must include every domain/port that accesses the app
- 32-bit ARM (arm/v7) not supported
- Maintainer has limited availability — community PRs welcomed

---

## References
- GitHub: https://github.com/invoicerr-app/invoicerr#readme
