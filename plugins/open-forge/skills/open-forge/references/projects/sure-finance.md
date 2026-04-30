---
name: Sure (fka Maybe Finance)
description: "Open-source personal finance + net-worth app — budgets, accounts, investments, forecasts. Community fork of abandoned Maybe Finance project. Rails 7 + Postgres + Redis + Sidekiq. Bank sync via Plaid (optional). AGPL-3.0."
---

# Sure

Sure is a full-featured OSS **personal finance + wealth-tracking** app — budgets, manual + synced accounts, credit cards, mortgages, investments, net worth over time, forecasts. It lives in the same space as Mint / YNAB / Monarch / Copilot, but self-hosted and **community-maintained** after the original team shut down their commercial SaaS.

> **History (important context):** Sure is the **community fork** of the now-abandoned **Maybe Finance** (`maybe-finance/maybe`) project. Maybe Inc. spent ~$1M building it 2021-2023, open-sourced it when the business model didn't work, briefly ran a hosted version, then shut down entirely. The Sure fork (`we-promise/sure`, website sure.am) picks up development. If you're looking for "Maybe self-hosted," this is where it lives now.
>
> **Trademark note**: "Maybe" is a trademark of Maybe Finance Inc. — forks cannot use that name. Sure is a rename to avoid the trademark issue.

Features:

- **Accounts** — checking, savings, credit cards, loans, investments, real estate (manual), crypto (manual)
- **Bank sync** via **Plaid** (US + parts of EU/CA; optional — BYO Plaid API keys)
- **Manual-only mode** — no Plaid, full functionality
- **Budgets** — category-based; monthly view
- **Transactions** — categorize, tag, split, rules
- **Net worth** — over time chart; asset + liability breakdown
- **Investment holdings** — shares, cost basis, current value; cursor to external price data
- **Forecasts** — projected balance + goal tracking
- **Multi-currency**
- **Multi-user / household** (in-repo support varies)
- **API** — REST for automation
- **Dark mode**

- Upstream repo: <https://github.com/we-promise/sure>
- Website: <https://sure.am>
- Original (archived): <https://github.com/maybe-finance/maybe>
- Self-host docs: <https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md>
- Discord: <https://discord.gg/36ZGBsxYEK>

## Architecture in one minute

- **Rails 7** (Ruby on Rails)
- **Postgres** — primary DB
- **Redis** — cache + Sidekiq queue
- **Sidekiq** — background jobs (bank sync, price updates, recalculation)
- **Stimulus + Hotwire** — frontend (no heavy SPA)
- **Tailwind CSS**
- **Plaid API** (optional) — bank sync; commercial service; your own account + API keys
- **Mailer** — SMTP for notifications
- **Storage** — Active Storage (S3 optional for uploads/logos)

## Compatible install methods

| Infra        | Runtime                                             | Notes                                                             |
| ------------ | --------------------------------------------------- | ----------------------------------------------------------------- |
| Single VM    | **Docker Compose** (upstream docs)                    | **The way**                                                          |
| Single VM    | Native Rails (bundle + rails server)                     | Dev only; not recommended for prod                                      |
| Kubernetes   | DIY — community manifests                                    | Works                                                                         |
| Managed      | — (no official SaaS; community-run demos only)                    |                                                                                     |
| Raspberry Pi | arm64 Docker                                                         | Workable for small/single-user                                                              |

## Inputs to collect

| Input             | Example                      | Phase     | Notes                                                               |
| ----------------- | ---------------------------- | --------- | ------------------------------------------------------------------- |
| Domain            | `money.example.com`            | URL       | Reverse proxy with TLS                                                 |
| Postgres          | user/pass                            | DB        | v14+                                                                           |
| Redis             | bundled or external                      | Queue     | Required for Sidekiq                                                                     |
| SECRET_KEY_BASE   | `rails secret` output                        | Crypto    | Rails crypto root; don't rotate                                                                   |
| SMTP              | host/port/user/pass                             | Email     | For invites + password reset                                                                                  |
| Plaid keys (opt)  | from <https://plaid.com>                              | Bank sync | Paid beyond sandbox; production access needs Plaid approval                                                         |
| Stripe keys (opt) | from Stripe                                             | Billing   | Only if monetizing a hosted deployment                                                                                     |
| Admin email       | first signup                                               | Bootstrap | First user is admin                                                                                                                  |
| Base currency     | `USD` / `EUR`                                                 | Locale    | Can be changed per user                                                                                                                      |

## Install via Docker Compose

Follow upstream's canonical compose at `docs/hosting/docker.md`. Outline:

```yaml
services:
  web:
    image: ghcr.io/we-promise/sure:latest   # pin a specific tag in prod
    restart: unless-stopped
    depends_on: [db, redis]
    environment:
      SECRET_KEY_BASE: <rails-secret-output>
      DB_HOST: db
      POSTGRES_DB: sure_production
      POSTGRES_USER: sure
      POSTGRES_PASSWORD: <strong>
      REDIS_URL: redis://redis:6379/0
      RAILS_SERVE_STATIC_FILES: "true"
      RAILS_LOG_TO_STDOUT: "true"
      SELF_HOSTED: "true"                   # enables single-install defaults
      # SMTP (required for email)
      SMTP_ADDRESS: smtp.example.com
      SMTP_PORT: "587"
      SMTP_USER_NAME: ...
      SMTP_PASSWORD: ...
      SMTP_TLS_ENABLED: "true"
      # Plaid (optional)
      # PLAID_CLIENT_ID: ...
      # PLAID_SECRET: ...
      # PLAID_ENV: sandbox
    ports:
      - "3000:3000"

  worker:
    image: ghcr.io/we-promise/sure:latest
    restart: unless-stopped
    depends_on: [db, redis]
    command: bundle exec sidekiq
    environment:
      <<: *web-env   # same env as web

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: sure
      POSTGRES_PASSWORD: <strong>
      POSTGRES_DB: sure_production
    volumes:
      - sure-db:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    restart: unless-stopped

volumes:
  sure-db:
```

On first boot: `docker exec sure-web bundle exec rails db:prepare` (if not auto-run). Browse `https://money.example.com` → sign up → you're admin.

## First boot

1. Sign up (first user) → you're admin
2. **Add Account**:
   - Manual: "Checking", balance, currency
   - Plaid: log in via Plaid Link → select bank → transactions import
3. Categorize recent transactions (Sure learns from your patterns)
4. **Budgets** → monthly category targets
5. **Investments** (if holding stocks/crypto): add as "Investment account" → add holdings with cost basis
6. **Dashboard** → net worth chart populates over time

## Plaid setup

- Plaid free "sandbox" mode — fake test data; good for development
- Plaid **production** — requires Plaid account approval (proof of use case, sometimes production verification)
- Plaid cost — free for small volume; paid for larger
- US coverage is strongest; some EU/CA banks; limited elsewhere
- Without Plaid, Sure is fully functional in manual mode

## Data & config layout

- Postgres: users, accounts, transactions, budgets, investments, everything
- Redis: Sidekiq queue + cache
- `.env` / compose env — all secrets
- Active Storage (optional S3) — user avatars + bank logos

## Backup

```sh
# DB (CRITICAL — financial data)
docker exec sure-db pg_dump -U sure sure_production | gzip > sure-$(date +%F).sql.gz

# Encrypted secrets (Rails credentials.yml.enc): back up .env/compose
```

Rotate backups offsite. Financial data loss is the worst kind.

## Upgrade

1. Releases: <https://github.com/we-promise/sure/releases>. Early stage — expect frequent updates + occasional breaking changes.
2. **Back up DB first.**
3. Bump image tag → `docker compose pull && docker compose up -d`. Migrations run via Rails autoload on boot (or run `rails db:migrate` explicitly).
4. Read release notes — Plaid integration + auth flow evolve.

## Gotchas

- **Community fork: "we-promise/sure" is where active development is.** The original `maybe-finance/maybe` is archived. Don't pull images from old maybe-finance registries.
- **Not investment/tax advice.** Sure shows your financial state; it does not file taxes, advise trades, or constitute financial planning. For taxes: use TurboTax / accountant. For advice: talk to a CFP.
- **Plaid access is the main friction point** — production Plaid requires account approval + $$$ for volume. For personal use, sandbox is free + fake data; pay for production if you want real bank sync. Many users run manual-only.
- **EU / non-US users**: Plaid coverage varies. GoCardless (formerly Nordigen) open banking is a popular alternative but not natively integrated here. Check community for EU bank-sync workarounds (SaltEdge, TrueLayer).
- **Rails Sidekiq worker MUST run** — without it, background jobs (price updates, Plaid sync, forecasts) never complete. Common first-install mistake: forgetting to start the worker service.
- **Redis MUST be persistent enough** for queued jobs; losing Redis mid-sync = missed jobs. For prod, configure Redis AOF persistence.
- **Secrets in Rails**: `SECRET_KEY_BASE` and Rails encrypted credentials — back them up. Losing = cannot decrypt stored API tokens (Plaid refresh tokens, for example).
- **Trademark compliance for forks**: if you fork Sure to run as a product, (1) include AGPLv3 license + Maybe Finance attribution, (2) **do not** use "Maybe" or Maybe's logo — that's Maybe Finance Inc.'s trademark. Sure's README lays this out.
- **Performance at scale**: >100k transactions per user = slow recalculations. Sure is designed for individual/household use; not built for bookkeepers managing hundreds of clients.
- **Multi-user / household** — check current state in repo; some features were single-user in Maybe era, some were added by Sure.
- **Price data for investments**: depends on data provider config. Some tickers work; exotic exchanges less so.
- **No mobile app** — responsive web works; PWA is an option.
- **AGPLv3** — network use triggers source disclosure if you modify + host for others. Personal self-hosting is always fine.
- **Early project state**: Sure is <1 year into the fork. Expect bugs; contribute fixes; don't treat as a 10-year-mature tool yet. For conservative users, wait 6-12 months and revisit.
- **Active Discord**: <https://discord.gg/36ZGBsxYEK> — good for questions, bug reports, feature ideas.
- **Alternatives worth knowing:**
  - **Firefly III** — classic OSS personal finance; PHP; mature (separate recipe)
  - **Actual Budget** — envelope budgeting (YNAB-style); excellent UX; ESM based; self-host + sync (separate recipe)
  - **GnuCash** — double-entry desktop classic; no web UI (separate recipe likely)
  - **Wallos** — subscription tracker narrower
  - **Financial Freedom** — another OSS PF app
  - **Copilot / Monarch / YNAB / Empower / Mint** — commercial SaaS alternatives
  - **Ghostfolio** — investment-focused; less budgeting (separate recipe — batch 55)
  - **Choose Sure if:** you want the Maybe Finance vision + active community + comprehensive (accounts + budgets + investments).
  - **Choose Firefly III if:** you want maturity + stability + great docs.
  - **Choose Actual Budget if:** envelope budgeting / YNAB-style is your jam + beautiful UX.
  - **Choose Ghostfolio if:** you only care about investment portfolio tracking.

## Links

- Repo: <https://github.com/we-promise/sure>
- Website: <https://sure.am>
- Docker install: <https://github.com/we-promise/sure/blob/main/docs/hosting/docker.md>
- Discord: <https://discord.gg/36ZGBsxYEK>
- Issues: <https://github.com/we-promise/sure/issues>
- Releases: <https://github.com/we-promise/sure/releases>
- Original Maybe Finance (archived): <https://github.com/maybe-finance/maybe>
- Maybe's final release note: <https://github.com/maybe-finance/maybe/releases/tag/v0.6.0>
- Plaid API docs: <https://plaid.com/docs/>
- Alternatives comparison: <https://sure.am>
