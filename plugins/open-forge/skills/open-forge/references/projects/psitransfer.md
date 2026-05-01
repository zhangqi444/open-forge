---
name: PsiTransfer
description: "Simple self-hosted file-sharing (Dropbox/WeTransfer alternative). No accounts. Big file support via tus.io resumable. AES-encrypted password-protected buckets. Vue frontend. psi-4ward/psitransfer. Docker Hub psitrax."
---

# PsiTransfer

PsiTransfer is **"WeTransfer / Dropbox-Transfer — but self-hosted, no accounts, big-file-friendly"** — a file-sharing service. **No accounts**, mobile-responsive UI, streams support HUGE files, resumable uploads/downloads (**tus.io**), AES-encrypted password-protected download lists, one-time-downloads, optional admin page.

Built + maintained by **psi-4ward**. Docker Hub `psitrax/psitransfer`. Node.js + Vue. Mature (blog posts at psi.cx). Snyk badge. PayPal donations.

Use cases: (a) **send-big-file-to-client** (b) **temporary file-drop** for collaborators (c) **WeTransfer-alternative** (d) **receive-files-from-external-senders** (if guest-upload enabled) (e) **one-time-download for sensitive files** (f) **expiring-bucket transfers** (g) **no-account-required** transfers (h) **resumable transfers on spotty connections**.

Features (per README):

- **No accounts/logins**
- **Mobile responsive**
- **Big files** via streaming
- **tus.io** resumable
- **Expire-time** per bucket
- **One-time downloads**
- **Zip/tar.gz bundle download**
- **Modal file preview**
- **AES password-protected buckets**
- **Admin page** (opt-in via adminPass)
- **Lightweight Vue frontend** (<100k gzipped)

- Upstream repo: <https://github.com/psi-4ward/psitransfer>
- Docker: `psitrax/psitransfer`
- Blog: <https://psi.cx/tags/PsiTransfer/>

## Architecture in one minute

- Node.js + Vue
- Filesystem storage (buckets)
- tus.io resumable protocol
- **Resource**: low; scales with transfers
- **Port**: HTTP

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | `psitrax/psitransfer`                                           | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `send.example.com`                                          | URL          | TLS                                                                                    |
| Storage path         | Bucket storage                                              | Storage      | **Plan capacity**                                                                                    |
| Max file size        | Default unlimited                                           | Config       | Set limit                                                                                    |
| Default expiry       | 24h typical                                                 | Config       |                                                                                    |
| Admin password       | Optional                                                    | Bootstrap    | Disables admin page if unset                                                                                    |

## Install via Docker

```yaml
services:
  psitransfer:
    image: psitrax/psitransfer:latest        # **pin**
    ports: ["3000:3000"]
    environment:
      - PSITRANSFER_ADMIN_PASS=${ADMIN_PASS}
      - PSITRANSFER_UPLOAD_DIR=/data
    volumes:
      - ./psitransfer-data:/data
    restart: unless-stopped
```

## First boot

1. Start; browse UI
2. Test upload small file
3. Test resumable upload (big file, disconnect-resume)
4. Set bucket expiry
5. Test AES-password-protected bucket
6. Configure admin password; check /admin page
7. Put behind TLS
8. Configure storage-cleanup policy

## Data & config layout

- `/data/` — bucket storage

## Backup

```sh
# Transient data — backup only if legally required
sudo tar czf psitransfer-$(date +%F).tgz psitransfer-data/
```

## Upgrade

1. Releases: <https://github.com/psi-4ward/psitransfer/releases>
2. Docker pull + restart
3. Check bucket-format compat

## Gotchas

- **173rd HUB-OF-CREDENTIALS Tier 3 — FILE-TRANSFER-TRANSIENT**:
  - Holds: transient files (sometimes sensitive), AES bucket keys in URLs (fragment!), admin password
  - Files mostly expire; still sensitive during lifetime
  - **173rd tool in hub-of-credentials family — Tier 3**
- **URL-FRAGMENT-AS-KEY**:
  - AES password in URL fragment
  - Reinforces Chitchatter/Enclosed pattern
  - **URL-as-encryption-key-secure-sharing: 3 tools** (Chitchatter+Enclosed+PsiTransfer) 🎯 **3-TOOL MILESTONE**
- **BUCKET-EXPIRY-DISCIPLINE**:
  - Expired buckets should actually be deleted
  - **Recipe convention: "transient-file-expiry-actual-deletion callout"**
  - **NEW recipe convention** (PsiTransfer 1st formally)
- **ABUSE-AS-MALWARE-DISTRIBUTOR**:
  - Public instance can be abused for malware/phishing hosting
  - Require ToS + abuse reporting
  - **Recipe convention: "file-transfer-malware-abuse-mitigation callout"**
  - **NEW recipe convention** (PsiTransfer 1st formally)
- **ADMIN-PAGE-OPT-IN**:
  - Disabled until adminPass set
  - Secure-default pattern
  - **Recipe convention: "admin-panel-disabled-by-default-secure positive-signal"**
  - **NEW positive-signal convention** (PsiTransfer 1st formally)
- **TUS.IO-RESUMABLE**:
  - Standard resumable protocol
  - **Recipe convention: "standard-protocol-implementation positive-signal"** — reinforces Movim (120)
- **SNYK-VULNERABILITY-TRACKING**:
  - Snyk badge
  - Public vuln-check
  - **Snyk-vulnerability-tracking: 1 tool** 🎯 **NEW FAMILY** (PsiTransfer)
  - (Related to SonarCloud at oCIS, Codacy at Cloud Commander/SerpBear, Qodana at Recyclarr — security-hygiene-constellation continues)
- **INSTITUTIONAL-STEWARDSHIP**: psi-4ward + Snyk + blog + Docker-Hub + OSS + active. **159th tool — sole-dev-with-snyk sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + Snyk + releases + Docker-Hub + blog. **165th tool in transparent-maintenance family.**
- **FILE-TRANSFER-CATEGORY:**
  - **PsiTransfer** — no-account, big-files, AES
  - **Send (firefox-send-fork)** — E2E encrypted
  - **Firefly** — self-hosted Firefox Send fork
  - **Linx** — Go; similar UX
  - **Pingvin Share** — modern alternative
- **ALTERNATIVES WORTH KNOWING:**
  - **Send** — if you want E2E
  - **Pingvin Share** — if you want modern stack
  - **Choose PsiTransfer if:** you want mature + tus.io + big-file + no-account.
- **PROJECT HEALTH**: active + mature + Snyk + blog. Strong.

## Links

- Repo: <https://github.com/psi-4ward/psitransfer>
- Pingvin Share (alt): <https://github.com/stonith404/pingvin-share>
