# DumbBudget

**What it is:** Simple, PIN-protected personal budgeting PWA. Track income and expenses with categories, date-range filtering, CSV export, and multi-currency support. Single-container, file-based storage — no database service required. Part of the DumbWare "dumb simple" self-hosted app suite.

**Official URL:** https://github.com/DumbWareio/DumbBudget

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux host | Docker Compose | Recommended |
| Any Linux host | Docker run | Single container |

---

## Inputs to Collect

| Phase | Input | Notes |
|-------|-------|-------|
| Deploy | `DUMBBUDGET_PIN` | Access PIN — **required**; without it the app is open to anyone |
| Deploy | `BASE_URL` | Full public URL (e.g. `http://localhost:3000` or `https://budget.example.com`) |
| Deploy | Data directory | Mounted at `/app/data`; stores transaction data |
| Deploy | Host port | Default `3000` |
| Optional | `CURRENCY` | Currency code (default `USD`; supports USD, EUR, GBP, JPY, and ~20 more) |
| Optional | `SITE_TITLE` | Custom page title (useful for multiple instances) |
| Optional | `INSTANCE_NAME` | Account/instance name shown in UI |
| Optional | `ALLOWED_ORIGINS` | Restrict CORS origins (default `*`); set to your URL for production |

---

## Software-Layer Concerns

### Docker image
```
dumbwareio/dumbbudget:latest
```

### docker-compose.yml
```yaml
services:
  dumbbudget:
    image: dumbwareio/dumbbudget:latest
    container_name: dumbbudget
    restart: unless-stopped
    ports:
      - ${DUMBBUDGET_PORT:-3000}:3000
    volumes:
      - ${DUMBBUDGET_DATA_PATH:-./data}:/app/data
    environment:
      - DUMBBUDGET_PIN=${DUMBBUDGET_PIN:-}
      - BASE_URL=${DUMBBUDGET_BASE_URL:-http://localhost:3000}
      - CURRENCY=${DUMBBUDGET_CURRENCY:-USD}
      - SITE_TITLE=${DUMBBUDGET_SITE_TITLE:-DumbBudget}
      - INSTANCE_NAME=${DUMBBUDGET_INSTANCE_NAME:-}
      # Optional: restrict origins
      # - ALLOWED_ORIGINS=${DUMBBUDGET_ALLOWED_ORIGINS:-http://localhost:3000}
```

### Data directory
- Transaction data stored in `./data/` (file-based, no external database)
- Create before first start: `mkdir data`

---

## Upgrade Procedure

```bash
docker compose pull
docker compose up -d
```

Data persists in the mounted volume. No migration step needed.

---

## Gotchas

- **`DUMBBUDGET_PIN` is required for security** — without a PIN the app is accessible to anyone who can reach the port; always set a PIN in production
- **`BASE_URL` must match your access URL** — used for PWA manifest and secure cookie scoping; if it doesn't match, the PWA install or auth may behave unexpectedly
- **Single-user design** — one PIN, one data store; not suited for multi-user households (run separate instances with different ports/data paths per user)
- **Currency is display-only** — there is no automatic conversion; the currency setting just controls the symbol shown
- **PWA support** — can be installed as a home-screen app on mobile; `BASE_URL` must be set correctly for the PWA manifest to work

---

## Supported Currencies

USD, EUR, GBP, JPY, AUD, CAD, CHF, CNY, HKD, NZD, MXN, RUB, SGD, KRW, INR, BRL, ZAR, TRY, PLN, SEK, NOK, DKK, IDR, PKR

---

## Links

- GitHub: https://github.com/DumbWareio/DumbBudget
- DumbWare suite: https://github.com/DumbWareio
