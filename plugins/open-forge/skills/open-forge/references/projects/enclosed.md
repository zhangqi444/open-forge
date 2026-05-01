---
name: Enclosed
description: "Send private end-to-end encrypted notes and files. Zero-knowledge server. Password + TTL + self-destruct-after-read. Node.js. CorentinTh. enclosed.cc demo + docs. CLI companion."
---

# Enclosed

Enclosed is **"PrivateBin / OneTimeSecret — but modern + self-hostable + E2E-encrypted with server zero-knowledge"** — a minimalistic web application for sending private + secure notes and files. **All notes are end-to-end encrypted**; server has zero-knowledge of content. Password + TTL + self-destruct-after-read.

Built + maintained by **Corentin Thomasset (CorentinTh)**. Demo at enclosed.cc. Docs site. CLI companion (`@enclosed/cli`). MIT likely.

Use cases: (a) **one-time secret sharing** — passwords to colleagues (b) **self-destruct sensitive notes** (c) **E2E-encrypted file transfer** (small files) (d) **Wetransfer-for-secrets** (e) **replace password-in-email** (f) **HR onboarding credentials delivery** (g) **CI secret-sharing** via CLI (h) **incident-response-secrets transport**.

Features (per README):

- **End-to-end encryption** (server zero-knowledge)
- **Password protection**
- **TTL expiration**
- **Self-destruct after read**
- **Notes + files**
- **CLI companion**
- **Self-hostable via Docker**

- Upstream repo: <https://github.com/CorentinTh/enclosed>
- Demo: <https://enclosed.cc>
- Docs: <https://docs.enclosed.cc>
- CLI: <https://www.npmjs.com/package/@enclosed/cli>
- Self-host docs: <https://docs.enclosed.cc/self-hosting/docker>

## Architecture in one minute

- **Node.js + Vue** likely
- **SQLite** typical
- **E2E encryption** in browser; server stores ciphertext only
- **Resource**: low — <200MB
- **Port**: web UI

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **Upstream image**                                              | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `send.example.com`                                          | URL          | **TLS MANDATORY**                                                                                    |
| Storage dir          | Ciphertext                                                  | Storage      |                                                                                    |

## Install via Docker

Per <https://docs.enclosed.cc/self-hosting/docker>:
```yaml
services:
  enclosed:
    image: corentinth/enclosed:latest        # **pin version**
    ports: ["8787:8787"]
    volumes:
      - ./enclosed-data:/app/.data
    restart: unless-stopped
```

## First boot

1. Start; browse UI
2. Create first note; test copy-link workflow
3. **Verify URL contains fragment (#) with key** — key is in URL-fragment which never hits server
4. Optionally require admin-auth for creators (not readers)
5. Put behind TLS
6. Configure retention defaults

## Data & config layout

- `/app/.data/` — SQLite + encrypted-note blobs

## Backup

```sh
sudo tar czf enclosed-$(date +%F).tgz enclosed-data/
# Only ciphertext; keys are in reader's URL fragments — ENCRYPT anyway
```

## Upgrade

1. Releases: <https://github.com/CorentinTh/enclosed/releases>
2. Docker pull + restart

## Gotchas

- **154th HUB-OF-CREDENTIALS Tier 4 — ZERO-KNOWLEDGE SERVER**:
  - Server holds ciphertext only; keys in URL fragments (never sent to server)
  - True E2E
  - Metadata only: timestamps, sizes, access counts
  - **154th tool in hub-of-credentials family — Tier 4 (near-zero)**
  - **Zero-knowledge-server: 1 tool** 🎯 **NEW FAMILY** (Enclosed; distinct from Tier 4/ZERO-stateless — Enclosed DOES store ciphertext, just can't decrypt it)
- **URL-FRAGMENT-AS-KEY**:
  - Key after `#` in URL never sent to server (browser behavior)
  - Reinforces Chitchatter (114) URL-as-encryption-key pattern
  - **URL-as-encryption-key-secure-sharing: 2 tools** (Chitchatter+Enclosed) 🎯 **2-TOOL MILESTONE**
- **SELF-DESTRUCT-AFTER-READ**:
  - Read-once semantics
  - Deletion mostly-trustworthy (server could still log access but can't decrypt)
  - **Recipe convention: "read-once-self-destruct-semantics positive-signal"**
  - **NEW positive-signal convention** (Enclosed 1st formally)
- **METADATA-LEAK-POTENTIAL**:
  - Server sees: IP of sender + reader, timestamp, size, access pattern
  - Traffic analysis possible
  - **Recipe convention: "metadata-leak-even-with-E2E callout"**
  - **NEW recipe convention** (Enclosed 1st formally)
- **CLI-COMPANION**:
  - `@enclosed/cli` for scripting
  - **CLI-companion-for-automation: 2 tools** (Docspell+Enclosed) 🎯 **2-TOOL MILESTONE**
- **LIVE-DEMO-ZEROKNOWLEDGE**:
  - Public demo at enclosed.cc
  - Users can test without self-host
  - **Recipe convention: "public-demo-zero-knowledge-trust positive-signal"**
  - **NEW positive-signal convention** (Enclosed 1st formally)
- **PASSWORD + TTL DOUBLE-LOCKS**:
  - Password adds layer beyond URL-key
  - TTL limits exposure-window
  - **Recipe convention: "defense-in-depth-password-plus-URL-key positive-signal"**
  - **NEW positive-signal convention** (Enclosed 1st formally)
- **FILE-SIZE-LIMITS NEEDED**:
  - E2E files can be abused — storage DoS
  - Set limits
  - **Recipe convention: "E2E-file-upload-size-limit-discipline callout"**
  - **NEW recipe convention** (Enclosed 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: CorentinTh + demo + docs-site + CLI-companion + MIT + active. **140th tool 🎯 140-TOOL MILESTONE in institutional-stewardship family — sole-maintainer-with-full-ecosystem sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + docs + demo + CLI + Docker + MIT. **146th tool in transparent-maintenance family.**
- **SECRET-SHARING-CATEGORY:**
  - **Enclosed** — modern; E2E; CLI
  - **PrivateBin** — PHP; E2E; mature
  - **OneTimeSecret** — Ruby; original (commercial + OSS)
  - **Snote** — various
- **ALTERNATIVES WORTH KNOWING:**
  - **PrivateBin** — if you want mature + PHP-ecosystem
  - **OneTimeSecret** — if you want original + commercial-option
  - **Choose Enclosed if:** you want modern + docker-simple + CLI.
- **PROJECT HEALTH**: active + demo + docs + CLI + MIT. Strong.

## Links

- Repo: <https://github.com/CorentinTh/enclosed>
- Demo: <https://enclosed.cc>
- Docs: <https://docs.enclosed.cc>
- PrivateBin (alt): <https://github.com/PrivateBin/PrivateBin>
