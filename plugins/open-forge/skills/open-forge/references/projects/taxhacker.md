---
name: TaxHacker
description: "Self-hosted AI accounting app for freelancers, indie-hackers, and small businesses — upload receipts/invoices/PDFs, AI (OpenAI/Gemini/Mistral/local LLM) auto-extracts amounts/dates/vendors/taxes into a structured DB. Multi-currency incl. crypto. MIT. Early dev."
---

# TaxHacker

TaxHacker is **self-hosted AI-powered accounting for small businesses / freelancers / indie hackers** — upload a photo of a receipt, invoice PDF, bank statement, or even a handwritten receipt, and it uses your chosen LLM (OpenAI, Google Gemini, Mistral, **or a self-hosted local LLM via OpenAI-compatible API — Ollama / LM Studio / vLLM / LocalAI**) to extract structured data: amounts, dates, vendors, line items, taxes, categories. Stores everything in a spreadsheet-like DB with custom fields, projects, categories. Multi-currency with historical FX + 14 cryptocurrencies. Built by **Vasily Zubarev (vas3k)**.

> **⚠️ Upstream status (from README):**
>
> *"This project is still in early development. Use at your own risk!"*
>
> Expect breaking changes + rough edges. Pin versions + test on copy of data before major upgrades.

Features:

- **AI extraction** — OpenAI, Google Gemini, Mistral, or **any OpenAI-compatible local LLM** (Ollama, LM Studio, vLLM, LocalAI)
- **Custom AI prompts** — edit system + field + project prompts directly in settings
- **Multi-currency** with **historical FX rates** (170+ currencies + 14 cryptocurrencies including BTC/ETH/LTC/DOT)
- **Auto-categorization** + custom categories + projects
- **Custom fields** — unlimited; like adding columns in Excel
- **Full-text search** on OCR'd document contents
- **Item splitting** — extract individual line items from invoices into separate transactions
- **Bulk operations** — multi-select + batch processing
- **Import/export** — CSV / Excel
- **Multi-project** support

- Upstream repo: <https://github.com/vas3k/TaxHacker>
- Demo video: <https://taxhacker.app/landing/video.mp4>
- Landing page: <https://taxhacker.app>
- Docker Hub: check repo README for current image path

## Architecture in one minute

- **Web app** (Next.js/Node based, per repo structure)
- **SQLite** or **PostgreSQL** for transactions + metadata
- **LLM provider** — externally called (OpenAI/Gemini/Mistral API OR your local Ollama endpoint)
- **Currency rates** from historical FX API
- **Resource**: modest — 300-500 MB RAM; LLM calls are external (not local compute unless you run your own LLM)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker Compose**                                                 | **Upstream-recommended**                                                           |
| Raspberry Pi       | arm64 — works                                                              | Modest CPU ok; LLM is external                                                                         |
| Kubernetes         | Community manifests                                                                          | Works                                                                                                   |
| Bare-metal node    | Possible                                                                                      | Less common                                                                                                       |

## Inputs to collect

| Input                   | Example                                          | Phase        | Notes                                                                    |
| ----------------------- | ------------------------------------------------ | ------------ | ------------------------------------------------------------------------ |
| Domain                  | `tax.home.lan`                                        | URL          | TLS reverse proxy                                                                |
| LLM provider            | OpenAI key / Gemini key / Mistral key / **Ollama URL**      | AI           | **BYOK** — provider bills go to your account                                                    |
| Base currency           | USD / EUR / ...                                              | Finance      | For FX conversion target                                                                                 |
| Storage path            | `./data` for uploads + DB                                                | Storage      | Receipts stored locally                                                                                                  |
| Admin                   | first-run                                                                | Bootstrap    | Strong password                                                                                                                          |

## Install via Docker Compose

```yaml
services:
  taxhacker:
    image: vas3k/taxhacker:latest                        # pin a specific version in prod
    container_name: taxhacker
    restart: unless-stopped
    ports:
      - "7331:7331"                                      # check current default port
    volumes:
      - ./data:/app/data
      - ./uploads:/app/uploads
    environment:
      # configure per current docs — LLM keys, FX API, base currency, etc.
      TZ: America/Los_Angeles
```

Browse → create admin → configure AI provider.

## First boot

1. Create admin
2. Settings → AI Provider → add OpenAI/Gemini/Mistral key, OR point at local Ollama (`http://ollama:11434/v1`)
3. Upload test receipt → verify extraction → tweak prompts if needed
4. Create projects + categories that match your tax reporting
5. Add custom fields (industry-specific — VAT number, project code, etc.)
6. Bulk upload existing receipts → batch-process
7. Configure export → test Excel/CSV round-trip before filing season
8. Back up before any upgrade

## Data & config layout

- `/app/data/` — SQLite DB + app state
- `/app/uploads/` — uploaded receipt images/PDFs
- DB contains **sensitive financial data** — treat with care

## Backup

```sh
sudo tar czf taxhacker-$(date +%F).tgz data/ uploads/
```

**Tax data is legally required to be retained** (varies by jurisdiction — often 5-10+ years). Keep off-site immutable backups.

## Upgrade

1. Releases: <https://github.com/vas3k/TaxHacker/releases>.
2. **Back up first.** Early-dev software = schema changes.
3. Docker: bump tag → restart → verify nothing broken on sample transactions before deleting backup.
4. Read release notes — breaking changes likely pre-1.0.

## Gotchas

- **EARLY DEVELOPMENT — upstream explicitly warns "use at your own risk."** Don't rely on it as your only record; keep CSV/Excel exports of processed data as fallback.
- **AI extraction is probabilistic** — numbers, dates, vendor names will occasionally be misread. **Always review before filing taxes.** For business accounting, AI is a first-pass convenience, not a replacement for review.
- **BYOK model** — same as batch 72 Pulse + batch 71 Paperless-AI:
  - OpenAI/Gemini/Mistral costs accrue to YOUR bill
  - Set spending caps on your provider side
  - **Your receipts go to the LLM provider** — contents leave your machine. For sensitive financial data, prefer local Ollama
- **Local LLM quality caveat** (per upstream): *"Just make sure that your local model is good in OCR tasks, results are not guaranteed."* Test each model on representative receipts. Smaller local models often miss currency symbols + numbers.
- **Tax-law variance**: TaxHacker extracts data; it does NOT file taxes or validate compliance with YOUR jurisdiction's rules. Always pair with proper accounting software or accountant for filing.
- **Currency detection + FX**: historical rates pulled from external API. Verify rate source + spot-check for important transactions. Rate APIs can have downtime.
- **Cryptocurrency support**: 14 cryptos covered. Crypto tax is complex (cost basis, FIFO vs HIFO, like-kind rules) — TaxHacker handles extraction but not cost-basis tracking. Pair with Cointracking / Koinly / CoinTracker for full crypto tax.
- **Custom prompts = custom risk**: editing system prompts can degrade extraction quality. Test changes on known documents before applying to backlog.
- **Audit trail**: for tax purposes, keep the original receipts (images/PDFs) in the `uploads/` volume — don't delete after extraction. Tax auditors typically want originals.
- **Jurisdictional + language handling**: upstream claims "any language, any currency" — works well for Latin scripts; handwritten + non-Latin may vary by LLM.
- **Full-text search**: indexed OCR content. Useful for finding that one receipt from 2 years ago.
- **No accounting double-entry** — TaxHacker is data extraction + categorization, not full accounting (not QuickBooks). For double-entry bookkeeping use GnuCash / Manager / Akaunting.
- **License**: **MIT** — permissive.
- **Author looking for work** (README front-matter): the project is maintained by someone actively job-searching. Worth noting for sustainability assessment; reality is **bus-factor-1 project** — plan accordingly. (Pattern repeats from batch 70 mox/Duplicacy and others.)
- **Alternatives worth knowing:**
  - **Paperless-ngx** (batch 57-ish) — document archiving with AI tagging; not accounting-focused
  - **Paperless-AI** (batch 71) — wraps Paperless with LLM analysis
  - **GnuCash** — double-entry open-source accounting; no AI
  - **Firefly III** — personal finance management (OSS)
  - **Akaunting** — small business accounting (OSS + paid modules)
  - **Manager** — cross-platform accounting (free desktop, paid cloud/server)
  - **QuickBooks / Xero / FreshBooks** — commercial cloud accounting
  - **Expensify / Receipt Bank** — commercial receipt-scanning
  - **Choose TaxHacker if:** you want self-hosted + AI receipt extraction + BYOK + custom fields/prompts + don't need full double-entry bookkeeping.
  - **Choose Firefly III + GnuCash if:** want established OSS + proper bookkeeping (less AI).

## Links

- Repo: <https://github.com/vas3k/TaxHacker>
- Landing: <https://taxhacker.app>
- Demo: <https://taxhacker.app/landing/video.mp4>
- Releases: <https://github.com/vas3k/TaxHacker/releases>
- Author: <https://vas3k.com>
- Paperless-ngx (alt): <https://github.com/paperless-ngx/paperless-ngx>
- Firefly III: <https://www.firefly-iii.org>
- GnuCash: <https://www.gnucash.org>
- Ollama (local LLM): <https://ollama.com>
- LocalAI: <https://localai.io>
