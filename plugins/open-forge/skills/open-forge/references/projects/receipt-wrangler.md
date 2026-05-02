# Receipt Wrangler

**What it is:** An easy-to-use self-hosted receipt manager. Scan, store, and split receipts among household members or groups. Features OCR-powered receipt scanning, AI-assisted data extraction, email integration for automated receipt ingestion, multi-user support, and flexible group management for splitting expenses.

**Official URL:** https://receiptwrangler.io
**Docs:** https://receiptwrangler.io/docs
**GitHub:** https://github.com/Receipt-Wrangler/receipt-wrangler
**License:** AGPL-3.0
**Stack:** Go (API) + Angular (desktop) + Ionic (mobile); Docker Compose

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any Linux VPS | Docker Compose | Recommended; official compose available in docs |

---

## Inputs to Collect

### Pre-deployment
- Database — PostgreSQL (recommended for production) or SQLite
- `SECRET_KEY` — JWT signing secret; generate a random string
- AI/OCR settings — optional; configure an OpenAI-compatible API for AI receipt extraction
- Email integration — optional IMAP settings for automated receipt ingestion from email

Refer to https://receiptwrangler.io/docs for the current Docker Compose file and full environment variable reference, as configuration options evolve with versions.

---

## Software-Layer Concerns

**Installation:** Follow the official Docker Compose guide at https://receiptwrangler.io/docs — the monorepo contains the API, desktop app, and mobile app; the compose file wires them together.

**OCR / AI extraction:** Receipt Wrangler can use an OpenAI-compatible API to parse receipt images. Configure the API endpoint and key in the admin settings after first login.

**Email ingestion:** Connect an IMAP mailbox so receipts forwarded to a specific email are automatically processed and imported.

**Upgrade procedure:**
```bash
docker compose pull
docker compose up -d
```

---

## Gotchas

- **Monorepo** — API, desktop, and mobile app are all in one repo; the Docker Compose setup handles all components
- **OCR requires an AI backend** — without configuring an OpenAI-compatible endpoint, automated receipt data extraction won't work; manual entry is still available
- **AGPL-3.0** — modifications must be open-sourced if distributed
- **Docs are the source of truth** — visit https://receiptwrangler.io/docs for the current compose file and configuration reference as it changes between versions

---

## Links
- GitHub: https://github.com/Receipt-Wrangler/receipt-wrangler
- Docs: https://receiptwrangler.io/docs
