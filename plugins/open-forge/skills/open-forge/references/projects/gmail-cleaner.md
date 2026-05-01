---
name: Gmail Cleaner
description: "Free, privacy-focused web GUI for bulk-unsubscribing + cleaning Gmail. Runs 100% locally. Python + Docker. Gmail API batch requests. MIT. Gururagavendra/gmail-cleaner."
---

# Gmail Cleaner

Gmail Cleaner is **"Clean Email / Unroll.me — but self-hosted + free + privacy-focused"** — a web GUI for **bulk unsubscribing, deleting by sender, marking-as-read, archive, label-management** in Gmail. Explicitly **no subscription, no data collection, runs 100% locally**. Gmail API batched (100 emails/call). MIT.

Built + maintained by **Gururagavendra**. Python. Docker. Gmail API-based.

Use cases: (a) **bulk-unsubscribe from newsletters** (b) **delete-by-sender inbox cleanup** (c) **bulk-mark-read** thousands of emails (d) **archive-by-sender** (e) **label-management** at scale (f) **sender-size ranking** (who sends you the most) (g) **CSV export of metadata** (h) **privacy-aware Unroll.me alternative**.

Features (per README):

- **Bulk unsubscribe**
- **Delete by sender** (see top senders first)
- **Bulk-delete multiple senders** with progress
- **Mark-as-read** thousands
- **Archive emails**
- **Label management** (create/delete/apply/remove)
- **Mark important**
- **Email download (CSV metadata)**
- **Smart filters** (date/size/category/sender/label)
- **Privacy-first** (local only)
- **Gmail API batch** — fast
- **Gmail-style UI**

- Upstream repo: <https://github.com/Gururagavendra/gmail-cleaner>

## Architecture in one minute

- **Python** (Flask/FastAPI likely)
- Gmail API via OAuth2
- Local-only — no DB
- **Resource**: low
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Upstream                                                                                                               | **Primary**                                                                                   |
| **Native Python**  | Pip                                                                                                                    | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Google OAuth client  | Google Cloud Console                                        | Secret       | **Required — Gmail API**                                                                                    |
| OAuth redirect       | `http://localhost:5000/oauth2callback`                      | Config       | Match client config                                                                                    |
| Gmail account        | Your personal Gmail                                         | Auth         | Grants modify-scope                                                                                    |

## Install via Docker

Per README:
```yaml
services:
  gmail-cleaner:
    image: gururagavendra/gmail-cleaner:latest        # **pin**
    ports: ["5000:5000"]
    environment:
      - GOOGLE_CLIENT_ID=...
      - GOOGLE_CLIENT_SECRET=...
    volumes:
      - ./gmail-cleaner-data:/data        # OAuth tokens
    restart: unless-stopped
```

## First boot

1. Create Google Cloud OAuth client (Desktop/Web)
2. Set client-id + secret in env
3. Start Gmail Cleaner
4. Log in via OAuth flow
5. **Review scopes** — modify-Gmail is powerful
6. Test on a small sender first (delete-preview)
7. Bulk operations with confidence
8. Revoke OAuth when done (or lock down to local-only)

## Data & config layout

- `/data/` — OAuth tokens (session-lived)

## Backup

OAuth tokens are refresh-able; no critical data stored.

## Upgrade

1. Releases: <https://github.com/Gururagavendra/gmail-cleaner/releases>
2. Docker pull + restart
3. Re-auth if OAuth format changes

## Gotchas

- **179th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — GMAIL-MODIFY-TOKEN**:
  - Holds: **Gmail modify-scope OAuth refresh-token** = can read + delete + label-manage ALL emails in the logged-in account
  - Distinct from **workspace domain-delegation** (Open Archiver, 122) — this is per-user OAuth
  - Still god-mode-per-user
  - **179th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "Gmail-modify-OAuth-token-cleanup-tool"** (1st — Gmail Cleaner; per-user-god-mode)
  - **CROWN-JEWEL Tier 1: 62 tools / 55 sub-categories**
- **GMAIL-MODIFY-SCOPE-DESTRUCTIVE**:
  - `gmail.modify` + `gmail.delete` scopes = can delete ALL emails
  - No undo for deletion
  - **Recipe convention: "Gmail-OAuth-modify-scope-destructive-review callout"**
  - **NEW recipe convention** (Gmail Cleaner 1st formally; HIGH-severity)
- **LOCAL-ONLY-POSITIVE-SIGNAL**:
  - "Runs 100% on your machine"
  - Data never leaves
  - **Recipe convention: "data-never-leaves-machine-privacy-declaration positive-signal"**
  - **NEW positive-signal convention** (Gmail Cleaner 1st formally)
  - Reinforces Mini QR client-side-crypto pattern
- **BATCH-API-EFFICIENCY**:
  - 100 emails per API call (Gmail batch)
  - **Recipe convention: "batched-API-call-efficiency-positive positive-signal"**
  - **NEW positive-signal convention** (Gmail Cleaner 1st formally)
- **FREE-FOREVER-EXPLICIT**:
  - "No subscription required — free forever"
  - Honest-positioning
  - **Recipe convention: "free-forever-explicit-positioning positive-signal"**
  - **NEW positive-signal convention** (Gmail Cleaner 1st formally)
- **GOOGLE-CLOUD-CONSOLE-PREREQ**:
  - User must create OAuth client
  - Non-trivial setup
  - **Recipe convention: "user-provides-own-OAuth-app neutral-signal"**
  - **NEW neutral-signal convention** (Gmail Cleaner 1st formally — distinct from "platform does it for you" pattern)
- **NO-DATA-COLLECTION-CLAIM**:
  - Verify by reading code
  - **Recipe convention: "no-data-collection-claim-code-verification callout"**
  - **NEW recipe convention** (Gmail Cleaner 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: Gururagavendra sole-dev + MIT + local-only-positioning + batch-efficient. **165th tool — privacy-positioned-local-tool sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + Docker + MIT. **171st tool in transparent-maintenance family.**
- **INBOX-CLEANUP-CATEGORY:**
  - **Gmail Cleaner** — self-hosted; Gmail-only; local-only
  - **Clean Email** — commercial SaaS
  - **Unroll.me** — commercial (controversial data-history)
  - **Trimbox** — commercial
- **ALTERNATIVES WORTH KNOWING:**
  - **Clean Email / Trimbox** — commercial + multi-provider
  - **Choose Gmail Cleaner if:** you want self-hosted + Gmail-only + local-only + free.
- **PROJECT HEALTH**: active + MIT + honest-positioning + Docker. Strong for privacy-aware tool.

## Links

- Repo: <https://github.com/Gururagavendra/gmail-cleaner>
