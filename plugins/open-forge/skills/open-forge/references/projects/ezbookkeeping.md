---
name: ezBookkeeping
description: "Lightweight self-hosted personal finance app — transaction ledger + powerful search + charts + multi-currency + multi-timezone + 2FA/OIDC/WebAuthn + AI (Ollama/OpenAI/MCP) + PWA + broad import (CSV/OFX/QIF/MT940/Camt/GnuCash/Beancount/Firefly III/...). Go + SQLite/MySQL/Postgres. MIT."
---

# ezBookkeeping

ezBookkeeping is **"YNAB/Firefly III but lighter"** — a self-hosted personal finance app built for **Raspberry Pi / NAS / MicroServer** resource constraints. Record daily transactions, import from broad list of financial formats (banks export via CSV/OFX/QIF/MT940/Camt.052/053/IIF/GnuCash/Firefly III/Beancount), search + filter + analyze via charts, custom query dimensions. **PWA** means native-like experience on mobile.

Features:

- **Open-source + self-hosted** — MIT license, full privacy
- **Lightweight + fast** — runs on Pi / NAS
- **Docker + binary** install; x86/amd64/ARM
- **DB**: SQLite / MySQL / PostgreSQL
- **UI**: desktop + mobile optimized; PWA; dark mode
- **AI**:
  - Receipt image recognition (OCR → transaction)
  - **MCP (Model Context Protocol) support** — AI agents can interact
  - Agent Skills + API CLI for AI integration
- **Bookkeeping features**:
  - Two-level accounts + categories
  - Image attachments per transaction
  - Location tracking (map)
  - Scheduled transactions
  - Advanced filter/search/viz
- **Localization**: multi-language, multi-currency, multi-exchange-rate-source (auto-update), multi-timezone, custom date/number/currency formats
- **Security**:
  - 2FA (TOTP)
  - OIDC external auth
  - Login rate limiting
  - Application lock (PIN or **WebAuthn**)
- **Import/Export**: CSV, OFX, QFX, QIF, IIF, Camt.052, Camt.053, MT940, GnuCash, Firefly III, Beancount, more

Developed by **mayswind**; active; Go-based.

- Upstream repo: <https://github.com/mayswind/ezbookkeeping>
- Homepage + full feature list: <https://ezbookkeeping.mayswind.net>
- Live demo: <https://ezbookkeeping-demo.mayswind.net>
- Docker Hub: <https://hub.docker.com/r/mayswind/ezbookkeeping>
- Releases: <https://github.com/mayswind/ezbookkeeping/releases>
- DeepWiki: <https://deepwiki.com/mayswind/ezbookkeeping>

## Architecture in one minute

- **Go** backend (compiled binary or Docker image)
- **SQLite** by default (simplest); MySQL + PostgreSQL supported
- **Frontend** bundled in same binary/image
- **Exchange rate** fetched from configurable source(s) periodically
- **Resource**: tiny — 50-200 MB RAM; ARM+x86 images
- **PWA** for installable mobile experience

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / Pi / NAS | **Docker** (`mayswind/ezbookkeeping`)                             | **Upstream-primary**                                                               |
| Bare metal         | **Pre-built binary** from GitHub Releases                                            | Windows / macOS / Linux                                                                    |
| From source        | Go + Node + GCC + `build.sh`                                                                  | For developers                                                                                             |
| Docker Compose     | External MySQL/PG + ezBookkeeping                                                                       | For multi-container / prod                                                                                         |
| Proxmox LXC        | Binary install in LXC                                                                                   | Works; resource-efficient                                                                                          |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `money.example.com`                                                | URL          | TLS — personal finance data, **always** TLS                                          |
| DB                   | SQLite file (default) / MySQL / Postgres                                  | Storage      | SQLite sufficient for single-user; MySQL/PG for shared/large                                   |
| Admin / users        | first signup → admin                                                             | Bootstrap    | Disable open signup after personal account(s) created                                                                 |
| Exchange rate source | fixer / central banks / ECB                                                               | Finance      | Configurable                                                                                                 |
| OIDC (opt)           | existing IdP                                                                                      | Auth         | For family-shared instance                                                                                                            |
| SMTP                 | for password reset / 2FA recovery                                                                               | Email        | Recommended                                                                                                                              |

## Install via Docker

```sh
# Quick start (SQLite; data inside container volume)
docker run -d --name ezbookkeeping \
  -p 8080:8080 \
  -v ezbookkeeping_data:/ezbookkeeping/data \
  mayswind/ezbookkeeping
```

For production: mount `/ezbookkeeping/conf/ezbookkeeping.ini` with your config + external DB.

## First boot

1. Browse `http://<host>:8080/` → sign up → **this account becomes admin**
2. Disable open signup in admin panel (now you have your account)
3. Configure exchange rate source + preferred currency
4. Enable 2FA + WebAuthn application lock
5. Import existing data (CSV / OFX from bank; or from Firefly III / GnuCash / Beancount)
6. Set up scheduled transactions (rent, subscriptions)
7. Put behind TLS reverse proxy
8. Schedule backups (see below)
9. Optional: configure OIDC for family members
10. Optional: configure AI receipt OCR

## Data & config layout

- SQLite: `/ezbookkeeping/data/ezbookkeeping.db` — entire ledger + attachments metadata
- Attachments (receipt images) — in data dir
- Logs: `/ezbookkeeping/data/log/`
- Config: `/ezbookkeeping/conf/ezbookkeeping.ini`

## Backup

```sh
# SQLite + attachments
sudo tar czf ezbookkeeping-$(date +%F).tgz /var/lib/docker/volumes/ezbookkeeping_data

# Or if using MySQL/PG:
pg_dump -Fc -U ezb ezb > ezb-$(date +%F).dump
```

**Encrypt backups.** Personal finance data = high-value for targeted attackers + stalkers + ex-partners.

## Upgrade

1. Releases: <https://github.com/mayswind/ezbookkeeping/releases>. Active.
2. Docker: pin version → bump tag → migrations auto.
3. **Back up DB before upgrade.** Financial data = no-tolerance-for-loss.
4. Binary: replace binary + restart service.

## Gotchas

- **Personal finance data = HIGHLY sensitive.** Always TLS; encrypted backups; strong master password + 2FA + WebAuthn app-lock. Treat ezBookkeeping data like you'd treat Mint/YNAB data — because it IS that data.
- **Transaction history retention = long.** For tax reasons, most jurisdictions require 5-7 year retention of financial records (varies: US IRS 7 years audit window; German 10 years; etc.). Archive monthly snapshots; don't trust a single DB file.
- **OCR / receipt image recognition = AI call.** Depending on configured AI backend (Ollama local vs OpenAI/Claude cloud), receipts may be transmitted to third parties. Review before enabling. Same AI-privacy-boundary as WhoDB (batch 77), Kuma in Baserow (this batch).
- **MCP support = AI agents can query your finances.** If you wire ezBookkeeping's MCP endpoint to Claude/Cursor/etc., that agent can read your ledger. Scope access carefully; never give a networked AI agent write access to your money ledger unless you've thought it through. Same class of concern as WhoDB MCP (batch 77).
- **Application lock (PIN / WebAuthn)** = second factor BEYOND login. For shared devices or brief-away scenarios. Enable.
- **Exchange rates**: auto-updated from configurable sources. ECB/central bank rates are standard but delay end-of-day. Real-time rates require commercial providers. Check your use case.
- **Multi-currency**: two-level accounts (e.g., Assets → Checking, Assets → Savings). Each account has native currency; reports convert via exchange rates. Rate at transaction time vs report time impacts reconciliation. Understand the semantics before inputting historical transactions.
- **Import format variety** covers most banks worldwide — MT940 / Camt.052 / Camt.053 for EU SEPA; OFX/QFX for US banks; GnuCash/Firefly III/Beancount for migrations from other tools. Rare: IIF for old Quicken.
- **Receipt attachments grow DB**: for heavy receipt-photo use, consider external blob store or periodic archive-old-photos-to-S3.
- **OIDC for family-shared use**: each family member has their own login via org IdP. Alternative: one shared login (bad idea for audit trail).
- **Location tracking** — stores GPS coords with transactions. Privacy: if you back up + share backups, you're sharing your location history. Disable if concerned.
- **Open signup = bad idea on internet-exposed**: close open signup after you + family are registered. Spam/abuse vector otherwise.
- **Scheduled transactions**: set-and-forget rent/subscription logging. Audit periodically — stale schedules after life changes (new apartment, canceled subscription) pollute data.
- **SQLite on container-unraided-network-share = WAL mode risk** (same pattern as Pinchflat batch 76). Keep `/data/` on local disk or use MySQL/PG.
- **License**: **MIT**. Permissive.
- **Project health**: mayswind solo-led but disciplined release cadence + wide import format support + i18n. Bus-factor-1 risk class, but data is YOUR data in an open, standard format (can always export to Beancount/GnuCash/SQL). Exit strategy is trivial.
- **Alternatives worth knowing:**
  - **Firefly III** — older, more established, PHP; also self-hostable
  - **Actual Budget** — YNAB-like, Node, self-hostable, great
  - **Maybe (open-source version)** — recently OSS'd
  - **Beancount / Ledger-CLI / hledger** — plain-text accounting; programmer-oriented
  - **GnuCash** — desktop-app; classic
  - **Lunch Money / YNAB / Copilot** — commercial cloud
  - **Tink / Plaid bank-sync** — commercial data feeds (pair with any of the above)
  - **Choose ezBookkeeping if:** Pi/NAS deploy + multi-currency + i18n-rich + modern UI + broad import formats.
  - **Choose Firefly III if:** mature ecosystem + more users + PHP stack preferred.
  - **Choose Actual Budget if:** YNAB-like zero-based budgeting mental model.
  - **Choose Beancount if:** you're a programmer + want plain-text git-versioned ledger.

## Links

- Repo: <https://github.com/mayswind/ezbookkeeping>
- Homepage: <https://ezbookkeeping.mayswind.net>
- Full feature list: <https://ezbookkeeping.mayswind.net/features/>
- Demo: <https://ezbookkeeping-demo.mayswind.net>
- Docker Hub: <https://hub.docker.com/r/mayswind/ezbookkeeping>
- Releases: <https://github.com/mayswind/ezbookkeeping/releases>
- DeepWiki (LLM-friendly docs): <https://deepwiki.com/mayswind/ezbookkeeping>
- Firefly III (alt): <https://www.firefly-iii.org>
- Actual Budget (alt): <https://actualbudget.org>
- Beancount (alt): <https://beancount.github.io>
- GnuCash (alt): <https://www.gnucash.org>
- Model Context Protocol: <https://modelcontextprotocol.io>
