---
name: Ghostfolio
description: "Open-source wealth management dashboard — portfolio tracker for stocks, ETFs, bonds, crypto, cash, commodities. Performance, allocation, dividends, benchmarks, multiple currencies. Data providers: Yahoo Finance / CoinGecko / Manual. Nest.js + Angular + Postgres + Redis. AGPL-3.0."
---

# Ghostfolio

Ghostfolio is the OSS self-hosted **wealth management dashboard** — aggregate your stocks, ETFs, bonds, crypto, cash, and commodities across multiple accounts/brokers into a single view, see performance over time, asset allocation, dividends, benchmarks, and get tax reports. Think Personal Capital / Empower / Portfolio Performance / Sharesight — open source and on your server.

What you get:

- **Multi-asset** — stocks, ETFs, mutual funds, bonds, options (manual), crypto, cash, commodities, real estate (manual)
- **Multi-currency** — holdings across USD/EUR/GBP/CHF/JPY/...; automatic FX
- **Performance** — absolute + TWR (time-weighted return) + IRR; net-of-fees
- **Allocation** — by asset class, region, industry, account
- **Benchmarks** — vs S&P 500, MSCI World, custom
- **Dividends** — tracking + calendar + projections
- **X-Ray** — portfolio diagnostic (sector exposure, currency exposure, concentration risk)
- **FIRE calculator** — withdrawal rate modeling
- **Data providers**: Yahoo Finance (default, free), CoinGecko (crypto), EOD Historical Data / Financial Modeling Prep / Alpha Vantage / RapidAPI (paid for higher rate limits + more markets), Manual entry
- **Importers** — CSV + account statement parsers (Interactive Brokers, Trade Republic, others)
- **API** — REST for automations
- **Multi-user** + role-based
- **Ghostfolio Premium** (SaaS) — hosted tier with extra data; OSS version has all features unlocked

- Upstream repo: <https://github.com/ghostfolio/ghostfolio>
- Website: <https://ghostfol.io>
- Docs: <https://ghostfol.io/resources>
- Docker Hub: <https://hub.docker.com/r/ghostfolio/ghostfolio>
- Discord: <https://discord.gg/eSHyYPVa6Q>

## Architecture in one minute

- **Backend**: NestJS (Node.js + TypeScript)
- **Frontend**: Angular
- **DB**: Postgres 13+
- **Cache + queue**: Redis
- **Data fetching**: polls providers on schedule (symbol prices, currency rates)
- **Workers**: Bull queue workers for heavy tasks
- **Reverse proxy** required for TLS

## Compatible install methods

| Infra       | Runtime                                                | Notes                                                          |
| ----------- | ------------------------------------------------------ | -------------------------------------------------------------- |
| Single VM   | **Docker Compose**                                       | **Upstream-recommended**                                           |
| Single VM   | Native Node.js                                              | `docker-compose.yml` + docs suggest Docker primarily                   |
| Kubernetes  | Community manifests                                           | Works; Helm charts in community                                                |
| Managed     | Ghostfolio Premium (hosted)                                      | Separate account; supports dev                                                       |

## Inputs to collect

| Input             | Example                         | Phase     | Notes                                                           |
| ----------------- | ------------------------------- | --------- | --------------------------------------------------------------- |
| Domain            | `money.example.com`               | URL       | Reverse proxy with TLS                                              |
| Postgres          | creds                                | DB        | Bundled in compose or external                                             |
| Redis             | localhost or bundled                   | Cache     | Required                                                                             |
| Admin user        | first signup                              | Bootstrap | First user is admin                                                                              |
| Base currency     | `USD` / `EUR` / `CHF`                       | Config    | UI default; per-user overridable                                                                         |
| Data provider     | Yahoo (default)                               | Market    | Switch to paid providers via env for higher reliability                                                                        |
| Access token      | per-user auto-generated                         | API       | For "login with token" shareable access; NOT a password                                                                                    |

## Install via Docker Compose

Upstream provides a canonical compose file. Outline:

```yaml
services:
  ghostfolio:
    image: ghostfolio/ghostfolio:2.x           # pin specific version
    container_name: ghostfolio
    restart: unless-stopped
    depends_on:
      postgres: { condition: service_healthy }
      redis: { condition: service_started }
    ports:
      - "3333:3333"
    environment:
      ACCESS_TOKEN_SALT: <random-32-chars>
      DATABASE_URL: postgresql://user:<strong>@postgres:5432/ghostfolio?connect_timeout=300&sslmode=prefer
      JWT_SECRET_KEY: <random-64-chars>
      POSTGRES_DB: ghostfolio
      POSTGRES_USER: user
      POSTGRES_PASSWORD: <strong>
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: <strong>
      TZ: UTC
      # Optional: paid data providers for more stability
      # API_KEY_EOD_HISTORICAL_DATA: ...
      # API_KEY_FINANCIAL_MODELING_PREP: ...

  postgres:
    image: postgres:15-alpine
    container_name: ghostfolio-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ghostfolio
      POSTGRES_USER: user
      POSTGRES_PASSWORD: <strong>
    volumes:
      - ghostfolio-db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d $$POSTGRES_DB -U $$POSTGRES_USER"]
      interval: 10s

  redis:
    image: redis:alpine
    container_name: ghostfolio-redis
    restart: unless-stopped
    command: ["redis-server", "--requirepass", "<strong>"]

volumes:
  ghostfolio-db:
```

Browse `https://money.example.com` → register → you're the admin.

## First boot

1. Register first account → admin
2. Settings → choose base currency
3. Add an account (broker / bank / crypto exchange)
4. Add activities: Buy / Sell / Dividend / Interest / Transfer
   - Ticker symbol (Yahoo format: e.g., `AAPL`, `VT`, `TSLA`, `BTC-USD`)
   - Quantity, unit price, fee, date
5. Import CSV (supports several broker formats); or upload account statement
6. Dashboard populates over minutes (data provider polls)
7. Configure benchmarks in Settings
8. "X-Ray" tab → portfolio diagnostic

## Data provider choices

- **Yahoo Finance** (default) — free, most tickers, but occasionally unstable + rate-limited
- **CoinGecko** — crypto default
- **EOD Historical Data** (paid, ~$20/mo) — more markets (non-US exchanges); more reliable
- **Financial Modeling Prep** (paid) — similar
- **Alpha Vantage** (paid tier) — historical depth
- **Manual** — enter prices yourself

For US stocks + ETFs + crypto, Yahoo is fine. If you hold significant European/Swiss/Asian securities, paid providers make sense.

## Data & config layout

- Postgres: all activities, accounts, portfolios, users, settings, holdings snapshots
- Redis: price cache, currency-rate cache, background jobs
- No persistent files beyond DB

## Backup

```sh
# DB (CRITICAL — all transactions + accounts)
docker exec ghostfolio-postgres pg_dump -U user ghostfolio | gzip > ghost-$(date +%F).sql.gz

# .env + configs: standard file copy
```

## Upgrade

1. Releases: <https://github.com/ghostfolio/ghostfolio/releases>. Very active (weekly-ish).
2. **Back up DB first** — migrations happen on most releases.
3. Docker: bump tag → `docker compose pull && docker compose up -d`. Migrations auto-run on boot.
4. Read CHANGELOG for breaking config/env changes.

## Gotchas

- **This is NOT investment advice / tax software.** Ghostfolio is a dashboard. Tax calculations (capital gains, lot matching, wash sales, tax-lot reporting) vary by jurisdiction and brokerage conventions. Ghostfolio gives you raw data + basic reports; for tax filing use dedicated software (TurboTax, TaxAct, Koinly, your accountant).
- **Yahoo Finance rate limits + data quality** — free Yahoo is fine for low-frequency polling (hourly) on majors. Heavily delisted symbols, pink sheets, and newer IPOs sometimes have gaps. Fallback: manual entry or paid provider.
- **Split adjustments** — Yahoo historical prices are split-adjusted, but split events in your transaction list need to be reflected manually if you hold pre-split shares. Ghostfolio supports split activities but you enter them.
- **Multi-currency** is a key feature. Set a base currency; Ghostfolio stores activities in transaction currency + displays in base. FX-adjusted returns matter; verify Ghostfolio's FX conversion aligns with your view.
- **Performance calculation** — TWR (time-weighted) vs IRR (money-weighted). Check which is displayed. TWR is manager-skill-neutral; IRR includes timing. Different answers!
- **Portfolio snapshots** — Ghostfolio recomputes historical value by applying activities to current prices; this means if you add backdated data, prior snapshots change. Normal but surprising.
- **Lots + FIFO/LIFO**: advanced cost-basis tracking is limited. Enterprise portfolio tools do this better.
- **CSV import**: formats differ by broker. Common brokers (Interactive Brokers, Trade Republic, Degiro, Trading 212) have community-contributed importers. Your broker may need a custom mapper.
- **Crypto accounting** — DeFi / staking / airdrops are partial. For serious on-chain crypto accounting, pair with Koinly/CoinTracker exports.
- **Account reconciliation** — Ghostfolio doesn't auto-reconcile against broker statements. You enter activities; dashboard reflects. Drift vs reality = re-import or correct.
- **Privacy**: self-hosting means your portfolio data never hits Ghostfolio's servers (unlike SaaS Personal Capital which sees everything). But: market-data provider calls leak your ticker set. Yahoo sees you query AAPL + ENTERPRISE-X; treat that as acceptable for most threat models.
- **Multi-user** — can host for family members; each has their own portfolio. No shared/joint portfolios natively (work around with separate accounts that hold same positions).
- **Access tokens (shareable)** — each user has a "login with access token" option. Useful for read-only sharing with your accountant. **Do NOT expose publicly** — the token is the credential.
- **Ghostfolio Premium** is the hosted version with extra data sources + higher rate limits + support. OSS self-host has all features; Premium = convenience.
- **Mobile apps**: web is responsive + PWA. No native iOS/Android apps.
- **Backups = everything**: if you lose DB, reconstructing years of transactions is painful. Daily pg_dump + offsite.
- **Dividend ex-date timing** — Ghostfolio records dividends when entered; actual ex-date vs payment-date can differ. For accurate total return, enter on ex-date.
- **AGPL-3.0** — strong copyleft; hosting modified fork = source must be available.
- **Security**: don't expose your Ghostfolio on the public internet without strong auth. Reverse-proxy with basic auth / OIDC / fail2ban / Tailscale.
- **Alternatives worth knowing:**
  - **Portfolio Performance** (desktop) — Java; mature; EU-popular; no web UI
  - **Sharesight** — SaaS; excellent tax reports (AU/NZ/UK/US)
  - **Personal Capital / Empower** — US SaaS; free but sees everything
  - **Mint / Monarch / YNAB / Actual** — budget tools more than portfolio trackers (separate recipe for Actual)
  - **Maybe Finance** — open-source; earlier in development
  - **Firefly III** — personal finance + budgeting; less investment-focused (separate recipe)
  - **StockBit / Wallmine / Delta / Stake** — mobile-focused
  - **Choose Ghostfolio if:** you want a modern OSS portfolio dashboard with multi-currency + X-Ray.
  - **Choose Portfolio Performance if:** you want mature desktop + best tax-lot + German-user polish.
  - **Choose Sharesight if:** tax reporting is the top requirement.
  - **Choose Actual/Firefly III if:** your goal is budgeting, not portfolio.

## Links

- Repo: <https://github.com/ghostfolio/ghostfolio>
- Website: <https://ghostfol.io>
- Docs / Resources: <https://ghostfol.io/resources>
- Self-host docs: <https://github.com/ghostfolio/ghostfolio/blob/main/README.md>
- Docker Hub: <https://hub.docker.com/r/ghostfolio/ghostfolio>
- Releases: <https://github.com/ghostfolio/ghostfolio/releases>
- Discord: <https://discord.gg/eSHyYPVa6Q>
- Slack (community): via the website
- Premium: <https://ghostfol.io/en/pricing>
- Twitter: <https://twitter.com/ghostfolio_>
- FAQ: <https://ghostfol.io/en/faq>
- Blog: <https://ghostfol.io/en/blog>
