---
name: Gokapi
description: "Modern self-hosted Firefox-Send alternative. Go. File expiry (downloads/days), user roles, file-requests, dedup, S3 storage, end-to-end encryption, OIDC (Authelia/Keycloak), REST API, custom CSS/JS. Active; Forceu maintainer; 83% coverage; ReadTheDocs."
---

# Gokapi

Gokapi is **"Firefox Send / PicoShare / Zipline — but Go + encrypted + role-based + S3-backed"** — a modern self-hosted file-sharing alternative to (discontinued) Firefox Send. Expiring file shares (after N downloads or N days); user management with roles; **file-requests** (shareable URL for external parties to upload, visible only to requestor); file-deduplication; **AWS S3 or S3-compatible** storage (optional); **end-to-end encryption**; **OpenID Connect** (Authelia/Keycloak); REST API; customizable CSS/JS.

Built + maintained by **Philipp (Forceu)** + community. License: check LICENSE (MIT typical). Active; **83% Go coverage**; Go Report Card; ReadTheDocs; Docker images (f0rc3/gokapi); 8+ years of releases.

Use cases: (a) **replace Firefox Send** (Mozilla discontinued 2020) (b) **e2e-encrypted client-document transfer** — legal/medical/accounting-compliance (c) **expiring file shares** — auto-delete after N downloads / N days (d) **file-request from external party** — "please upload your W-9 here" (e) **organization-level file-share** — role-based, OIDC integrated (f) **S3-backed unlimited scale** — Backblaze B2/AWS/R2 backend (g) **customer-document-delivery** — expiring + downloadable counts (h) **anti-imgur abuse-protection** — only registered users upload.

Features (per README):

- **Expiring file shares** (N downloads / N days)
- **User management with roles**
- **File-requests** (external-upload URLs)
- **File deduplication**
- **Cloud-storage** — AWS S3, Backblaze B2, S3-compatible
- **End-to-end encryption** uploads
- **OpenID Connect** (Authelia, Keycloak)
- **REST API**
- **Customizable UI** (custom CSS/JS)

- Upstream repo: <https://github.com/Forceu/Gokapi>
- Docs: <https://gokapi.readthedocs.io>
- Docker Hub: <https://hub.docker.com/r/f0rc3/gokapi>

## Architecture in one minute

- **Go** single binary
- **SQLite** — metadata DB
- **Local filesystem OR S3** — object storage
- **Resource**: low — 50-150MB RAM
- **Port 53842** default

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`f0rc3/gokapi`**                                              | **Primary**                                                                        |
| **Binary**         | **Linux/macOS/Windows**                                         | Bare-metal                                                                                   |
| Source             | `go build`                                                                                                             | Dev                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `send.example.com`                                          | URL          | TLS MANDATORY                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    | Strong                                                                                    |
| Storage backend      | Local OR S3                                                 | Storage      |                                                                                    |
| S3 creds (if S3)     | Bucket + keys + endpoint                                    | Storage      |                                                                                    |
| OIDC (opt)           | Authelia / Keycloak                                         | Auth         |                                                                                    |
| Encryption passphrase | E2E                                                                                                                  | Security     |                                                                                    |
| External URL         | Must match public access                                                                                                      | URL          | Affects shareable-links                                                                                                            |

## Install via Docker

```yaml
services:
  gokapi:
    image: f0rc3/gokapi:latest        # **pin version**
    volumes:
      - gokapi-config:/app/config
      - gokapi-data:/app/data
    ports: ["53842:53842"]
    restart: unless-stopped

volumes:
  gokapi-config: {}
  gokapi-data: {}
```

## First boot

1. Start container → browse `:53842`
2. First-run: configure admin + storage + encryption
3. Verify OIDC if configured
4. Test file upload → expiration → auto-delete
5. Create file-request URL; test external upload
6. Configure reverse proxy for TLS + auth-boundary
7. Back up config + DB

## Data & config layout

- `/app/config/` — configuration + SQLite DB
- `/app/data/` — uploaded files (if local storage)
- S3 bucket (if S3-backed)

## Backup

```sh
sudo tar czf gokapi-config-$(date +%F).tgz gokapi-config/ gokapi-data/
# If S3-backed: S3 lifecycle rules handle storage; config DB is what matters
```

## Upgrade

1. Releases: <https://github.com/Forceu/Gokapi/releases>. Active.
2. Docker pull + restart
3. 8+ years of releases — stable cadence

## Gotchas

- **PUBLIC-UGC-HOST ABUSE-CONDUIT-RISK META-FAMILY EXTENDED**:
  - Anyone with upload-URL can upload
  - File-requests = external-upload by design
  - **META-FAMILY now 7 tools** (Slash + Zipline + Opengist + OxiCloud + FileGator + PicoShare + **Gokapi**)
  - **Mitigation stronger in Gokapi**: user-roles + file-requests only generate per-user; not blanket-public-upload
  - **Recipe convention: "role-based-upload restricts abuse-surface" positive-signal**
  - **NEW positive-signal convention** (Gokapi's upgrade from PicoShare-style)
- **END-TO-END ENCRYPTION = KEY-MANAGEMENT**:
  - E2E keys held by uploader; server cannot read files
  - If uploader loses key → file unrecoverable
  - Recipient needs key shared out-of-band (or in URL fragment)
  - **Recipe convention: "E2E-encryption-key-management-burden" callout**
  - **NEW recipe convention**
- **EXPIRY = SEMI-RELIABLE**:
  - Files auto-delete after N-downloads OR N-days
  - Depends on Gokapi being running
  - **NOT a cryptographic guarantee** (unlike forward-secrecy)
  - **Recipe convention: "expiry-enforcement-depends-on-server-uptime" callout**
- **FIREFOX-SEND REPLACEMENT POSITIONING**:
  - Mozilla discontinued Firefox Send in 2020 after abuse (malware distribution)
  - Gokapi inherits both use-case + abuse potential
  - **Recipe convention: "Firefox-Send-successor-responsibility" context**
  - **NEW recipe convention** (Gokapi 1st)
- **OIDC INTEGRATION = STANDARDS-ALIGNED**:
  - Authelia + Keycloak supported
  - Standards-first = good engineering
  - **Recipe convention: "OIDC-standards-first positive-signal"** — reinforces OxiCloud 100 precedent (multi-tool)
- **S3-BACKED STORAGE = UNLIMITED SCALE**:
  - Can use any S3-compatible
  - **Recipe convention: "S3-API-as-portability-layer"** extended (PicoShare 103 was 1st formal; Gokapi 2nd)
- **CUSTOM CSS/JS = XSS-RISK**:
  - Admin can inject arbitrary CSS/JS
  - If admin account compromised → XSS everywhere
  - **Recipe convention: "admin-injected-CSS-JS-XSS-surface" callout**
  - **NEW recipe convention**
- **83% GO COVERAGE**:
  - Higher than most OSS projects (most report <50%)
  - **Recipe convention: "measurable-code-coverage positive-signal"** (Baby Buddy 106 had Coveralls; Gokapi has 83% badge)
- **GO REPORT CARD**:
  - Automated Go-code-quality scoring
  - **Recipe convention: "Go-Report-Card positive-signal"**
  - **NEW positive-signal convention**
- **HUB-OF-CREDENTIALS TIER 2**:
  - User accounts + encryption keys (if E2E) + S3 creds + OIDC trust + shared URLs
  - E2E reduces server-side-exposure
  - **89th tool in hub-of-credentials family — Tier 2**
- **DEDUPLICATION = STORAGE-EFFICIENCY**:
  - Same file uploaded twice → stored once
  - **Mild privacy leak**: an attacker who can upload can test whether a file they possess is already on server (file-existence-inference)
  - **Recipe convention: "dedup-file-existence-inference-risk" callout**
  - **NEW recipe convention** (subtle)
- **INSTITUTIONAL-STEWARDSHIP**: Forceu sole + community. **75th tool — sole-maintainer-with-community sub-tier (34th).**
- **TRANSPARENT-MAINTENANCE**: active + 83% coverage + Go-Report-Card + ReadTheDocs + 8+-year-history + Docker + releases. **83rd tool in transparent-maintenance family.**
- **FILE-SHARE-CATEGORY:**
  - **Gokapi** — Go; e2e encryption; S3; OIDC; roles
  - **PicoShare** (103) — Go; simplest; shared-secret
  - **Zipline** (98) — Node; ShareX-focused
  - **PingVin** — Node + Svelte
  - **Transfer.sh** — CLI-focused
  - **Firefly Send** (OSS revival attempts)
- **ALTERNATIVES WORTH KNOWING:**
  - **PicoShare** — if you want minimal + single-shared-secret
  - **Zipline** — if you want ShareX + feature-rich UI
  - **PingVin** — if you want Node + email-to-recipient
  - **Choose Gokapi if:** you want Go + E2E + S3 + OIDC + roles + dedup.
- **PROJECT HEALTH**: active + long-history + coverage + docs + Docker + OIDC + encryption. EXCELLENT.

## Links

- Repo: <https://github.com/Forceu/Gokapi>
- Docs: <https://gokapi.readthedocs.io>
- PicoShare (batch 103): <https://github.com/mtlynch/picoshare>
- Zipline (batch 98): <https://github.com/diced/zipline>
- Firefox Send (discontinued): <https://en.wikipedia.org/wiki/Firefox_Send>
- PingVin: <https://github.com/stonith404/pingvin-share>
