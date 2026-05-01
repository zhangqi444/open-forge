# Invio

**Self-hosted invoicing — create invoices, share a secure link, get paid. No bloat, no subscriptions, no client accounts needed.**
Official site: https://invio.dev
GitHub: https://github.com/kittendevv/Invio
Demo: https://demo.invio.dev

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux | Docker Compose | Recommended |

---

## Inputs to Collect

### Required
- `ADMIN_USER` — admin username
- `ADMIN_PASS` — admin password
- `JWT_SECRET` — JWT signing secret (change from default)
- `ORIGIN` — public URL where the frontend is served (e.g. https://invoices.example.com)

---

## Software-Layer Concerns

### Setup
1. Copy the example env file: `cp .env.example .env`
2. Edit `.env` with your values
3. Run `docker compose up -d`

### docker-compose.yml
```yaml
name: invio

services:
  invio:
    image: ghcr.io/kittendevv/invio:latest
    env_file:
      - .env
    volumes:
      - invio_data:/app/data
    ports:
      - "8000:8000"
    restart: unless-stopped

volumes:
  invio_data:
    driver: local
```

### .env (minimum required)
```env
ADMIN_USER=admin
ADMIN_PASS=your-secure-password
JWT_SECRET=change-me-in-production
ORIGIN=http://localhost:8000

# Database path (default works for Docker)
DATABASE_PATH=/app/data/invio.db
```

### Ports
- `8000` — web UI

### Key features
- No client accounts — share invoice via secure link
- SQLite database stored in persistent volume
- Free and open source, no per-invoice fees

---

## Upgrade Procedure

1. docker compose pull
2. docker compose up -d

---

## Gotchas

- `ORIGIN` must match the URL you use to access Invio (SvelteKit CSRF protection) — wrong value causes request failures
- Change `JWT_SECRET` and `ADMIN_PASS` before exposing to the internet
- Full setup guide: https://github.com/kittendevv/Invio/wiki/Quick-Start

---

## References
- Quick Start: https://github.com/kittendevv/Invio/wiki/Quick-Start
- GitHub: https://github.com/kittendevv/Invio#readme
