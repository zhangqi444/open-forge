---
name: ExpenseOwl
description: "Extremely simple self-hosted expense tracker with monthly pie-chart visualization. Docker / Go binary. Tanq16/ExpenseOwl. Single-user, PWA, CSV import/export, recurring transactions, dark/light theme."
---

# ExpenseOwl

**Extremely simple self-hosted expense tracker.** Quick expense/income add with just date, amount, and category. Monthly pie-chart breakdown + cashflow (income vs. expenses vs. balance). Table view, recurring transactions, custom categories, currency, dark/light themes, PWA, CSV export/import. No budgeting complexity — just fast, simple expense tracking for a home lab.

Built + maintained by **Tanq16**. Self-contained binary; no internet interaction at runtime.

- Upstream repo: <https://github.com/Tanq16/ExpenseOwl>
- Docker Hub: <https://hub.docker.com/r/tanq16/expenseowl>

## Architecture in one minute

- **Go** binary (single self-contained binary)
- Port **8080** (default)
- Persistent data stored in `/app/data` (mount a volume)
- No external DB — all data in the app's own storage
- **PWA** — installable on iOS/Android/desktop from the browser
- Resource: **tiny** — Go binary, minimal RAM

## Compatible install methods

| Infra          | Runtime                   | Notes                                          |
| -------------- | ------------------------- | ---------------------------------------------- |
| **Docker**     | `tanq16/expenseowl`       | **Primary** — Docker Hub                       |
| **Go binary**  | download from releases    | Run directly on any OS without Docker          |

## Install via Docker

```bash
docker run --rm -d \
  --name expenseowl \
  -p 8080:8080 \
  -v expenseowl:/app/data \
  tanq16/expenseowl:main
```

Visit `http://localhost:8080`.

## Install via Docker Compose

```yaml
services:
  expenseowl:
    image: tanq16/expenseowl:main
    restart: unless-stopped
    ports:
      - 5006:8080    # change 5006 to your preferred external port
    volumes:
      - /home/user/expenseowl:/app/data   # change path as needed
```

## Install via binary

1. Download the binary for your platform from [releases](https://github.com/Tanq16/ExpenseOwl/releases).
2. Run: `./expenseowl`
3. Visit `http://localhost:8080`.
4. Data is stored in a `data/` directory in your current working directory.

## First use

1. Deploy and visit `http://localhost:8080`.
2. Go to **Settings** → configure:
   - Custom categories (add/remove/reorder)
   - Currency symbol
   - Start date (first day of your tracking period)
3. Add your first expense: date + amount + category (required). Name + tags optional.
4. Dashboard shows this month's pie chart + cashflow.
5. Install as **PWA** for quick mobile access (iOS: Safari → Share → Add to Home Screen; Android: Chrome → Install).

## Features overview

| Feature | Details |
|---------|---------|
| Expense add | Date + amount + category (required); name + tags (optional) |
| Income tracking | Mark as income; shown separately in cashflow |
| Recurring transactions | Set up repeating expenses/income |
| Monthly pie chart | Category breakdown; click category to exclude from chart |
| Cashflow indicator | Total income + total expenses + balance (green/red) |
| Table view | All expenses listed; delete with shift-click to skip confirm |
| Custom categories | Add/remove/reorder; fully configurable |
| Custom currency | Any symbol |
| Custom start date | Align month start to your pay cycle |
| CSV export | Export all data |
| CSV import | Import from Firefly III, Actual, or other tools |
| Tags | Optional secondary classification; filterable in table |
| Dark/light theme | Both supported |
| PWA | Install on any device for native-app feel |
| No internet calls | Self-contained binary; no analytics, no CDN |

## Data & config layout

- `/app/data/` — all expense data + settings
- No external DB; no user accounts

## Backup

```sh
docker compose stop expenseowl
sudo tar czf expenseowl-$(date +%F).tgz /home/user/expenseowl/
docker compose start expenseowl
# Or export CSV from the Settings page for a portable backup
```

## Upgrade

```sh
docker pull tanq16/expenseowl:main && docker compose up -d
```

## Gotchas

- **Single-user only.** No accounts, no access control. Anyone who can reach the URL can add/delete expenses. Run on localhost or behind auth (Cloudflare Access, Authelia, nginx basic auth) if on a shared network.
- **No budgeting features.** ExpenseOwl is intentionally minimal — tracking only. If you need budget categories, forecasting, account reconciliation, or investment tracking, use Actual Budget or Firefly III instead.
- **CSV import is flexible.** You can import from other tools (Firefly III, Actual, generic CSVs) — the import UI shows expected column format. Good migration path.
- **Pie-chart click filtering.** Clicking a category in the dashboard pie chart or legend excludes it from the chart (e.g. exclude "Rent" to see discretionary spending as a proportion). Click again to re-include. This is per-session — not a persisted filter.
- **PWA offline mode.** The front end installs on-device; the back end still needs to be self-hosted and reachable. Offline entry isn't supported — you need network access to the server.
- **`tanq16/expenseowl:main` is the tag.** Using `:latest` may not resolve — use `:main` (or a versioned tag from releases).
- **Binary auto-creates `data/` in CWD.** When running the binary (not Docker), data goes into `./data/` relative to where you run it. Use an absolute path or always run from the same directory.

## Project health

Active Go development, Docker Hub CI, multi-arch, GitHub Actions release automation. Solo-maintained by Tanq16. MIT license.

## Expense-tracker-family comparison

- **ExpenseOwl** — Go, minimal, single-user, PWA, pie chart, CSV, no budgeting
- **Actual Budget** — React + Node, full budgeting, accounts, reconciliation; more complex
- **Firefly III** — PHP + MySQL, full personal finance; much more powerful + complex
- **Wallos** — PHP, subscription tracking (not general expenses)
- **Spendee / YNAB** — SaaS, polished, not self-hosted

**Choose ExpenseOwl if:** you want the fastest, simplest self-hosted way to see where your money went each month — no budgeting, no complexity, just add expense → see pie chart.

## Links

- Repo: <https://github.com/Tanq16/ExpenseOwl>
- Docker Hub: <https://hub.docker.com/r/tanq16/expenseowl>
- Actual Budget (full-budgeting alt): <https://actualbudget.org>
- Firefly III (full-finance alt): <https://firefly-iii.org>
