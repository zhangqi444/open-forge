# SpendSpentSpent

**What it is:** A fast, easy-to-use self-hosted expense tracker focused on making logging a new expense as quick as possible. Three-pane layout: add expenses (with optional location tagging and recurring entries), view day-by-day details, and explore monthly/yearly graphs by category. Companion Android app available.

**Official URL:** https://github.com/lamarios/SpendSpentSpent
**Docs:** https://lamarios.github.io/SpendSpentSpent/docs
**Demo:** https://sss.ftpix.com
**License:** MIT
**Stack:** Flutter (Android app) + backend service; Docker

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS / bare metal | Docker Compose | Recommended |
| Homelab / Raspberry Pi | Docker | Lightweight |

---

## Inputs to Collect

### Pre-deployment
- External port — map to the backend API (default `8080`)
- Database volume path — persists expense data

### Runtime
- Expense categories — created via the web UI
- Currency and locale settings — configured in app settings

---

## Software-Layer Concerns

**Docker run (quick start):**
```bash
docker run -d \
  -p 8080:8080 \
  -v sss-data:/data \
  lamarios/spend-spent-spent:latest
```

**Access:** `http://localhost:8080`

**Three pages (swiped left/right on mobile):**
- **Center (Spend):** Add expenses by category, optionally tag location, set up recurring entries
- **Right (Spent):** View the selected month's expenses day by day; delete entries; see locations on a map
- **Left (Statistics):** Monthly and yearly graphs comparing overall and per-category spending

**Android app:** Available on GitHub — connects to your self-hosted instance via the server URL.

**Recurring expenses:** Set up monthly bills, subscriptions, or other recurring costs once; they auto-appear each period.

**Location tagging:** Optional per-expense — useful for tracking where you spend money geographically.

**Upgrade procedure:**
1. `docker pull lamarios/spend-spent-spent:latest`
2. `docker compose up -d` (or restart the container)

---

## Gotchas

- **Simplicity by design** — not a full double-entry bookkeeping system; no bank import, no budgets, no forecasting — just fast expense logging and visual summaries
- **No built-in authentication** — add a reverse proxy with auth for internet-facing deployments
- **Android app only** — no iOS app; web UI works on all browsers including mobile

---

## Links
- GitHub: https://github.com/lamarios/SpendSpentSpent
- Docs: https://lamarios.github.io/SpendSpentSpent/docs
- Demo: https://sss.ftpix.com
