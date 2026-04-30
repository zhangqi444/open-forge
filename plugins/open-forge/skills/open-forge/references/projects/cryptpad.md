---
name: CryptPad
description: "End-to-end encrypted collaborative office suite — documents, spreadsheets, slides, kanban, whiteboard, forms, polls. Real-time multi-user editing. Server stores only encrypted data. Node.js + CouchDB (historical) / filesystem. AGPL-3.0."
---

# CryptPad

CryptPad is an **end-to-end encrypted, real-time collaborative office suite** — documents, spreadsheets, presentations, kanban boards, whiteboards, forms, polls, rich text, code — all synced between collaborators, with the server storing only **encrypted** blobs. If the server is breached, attackers see ciphertext. If the admin is malicious (or compromised), they still can't decrypt your content — provided they don't swap the JavaScript (see gotcha).

Developed and maintained by **XWiki SAS** (French OSS company); funded partly by EU R&D + commercial hosting.

Apps inside CryptPad:

- **Document** — rich text (like Google Docs)
- **Sheet** — spreadsheet (like Google Sheets; uses OnlyOffice under the hood for encrypted sheets)
- **Presentation** — slides (like Google Slides; also OnlyOffice-based)
- **Form** — Google Forms-like, but encrypted
- **Kanban** — Trello-like board
- **Code** — syntax-highlighted collaborative code editor
- **Whiteboard** — drawing/sketching
- **Diagram** — flowcharts (draw.io-like)
- **Markdown** — simpler rich text
- **File storage** ("CryptDrive") — like encrypted Dropbox

Plus:

- **Teams** — shared workspaces
- **Contacts** + messaging
- **Calendar**

Features:

- **Zero-knowledge E2E encryption** — server never sees cleartext
- **Real-time collaboration** — multi-cursor, multi-user
- **Offline-first** with sync-on-reconnect
- **Sharing** via secret links (with read / read-write / owner options)
- **Guest access** without registration (for public pads)
- **Admin panel** — user quotas, storage, customization
- **Federated?** No — users on different servers can't collaborate; each server is a silo
- **Self-host or use cryptpad.fr** (upstream's free + paid SaaS)

- Upstream repo: <https://github.com/cryptpad/cryptpad>
- Website: <https://cryptpad.org>
- Docs: <https://docs.cryptpad.org>
- Admin guide: <https://docs.cryptpad.org/en/admin_guide/installation.html>
- Hosted (official): <https://cryptpad.fr>
- Matrix: `#cryptpad:matrix.org`

## Architecture in one minute

- **Node.js** backend
- **Frontend**: TypeScript, encryption in-browser via libsodium / WebCrypto
- **Storage**: filesystem (default, fine for most) — each pad = a file of encrypted bytes
- **No database in the traditional sense** — pads + chain-blocks on disk; user accounts via crypto-derived keys
- **WebSockets** — for real-time sync
- **Sandbox domains**: CryptPad uses TWO domains (main + sandbox) to isolate pad content from the main app; this matters for your reverse-proxy config
- **OnlyOffice**: sheets + slides use an embedded OnlyOffice build (no separate OnlyOffice server; runs client-side)

## Compatible install methods

| Infra       | Runtime                                              | Notes                                                              |
| ----------- | ---------------------------------------------------- | ------------------------------------------------------------------ |
| Single VM   | **Docker Compose** (official since v5.4.0)              | **Upstream-maintained**                                                |
| Single VM   | Node.js bare metal                                          | Follow admin guide                                                           |
| Kubernetes  | Community manifests                                            | Works                                                                              |
| Managed     | cryptpad.fr (SaaS) — free + paid plans                              | Upstream's funding                                                                         |

## Inputs to collect

| Input             | Example                            | Phase      | Notes                                                          |
| ----------------- | ---------------------------------- | ---------- | -------------------------------------------------------------- |
| Main domain       | `cryptpad.example.com`                | URL        | User-visible                                                       |
| Sandbox domain    | `cryptpad-sandbox.example.com`           | URL        | **MUST differ from main** — cross-origin isolation requirement            |
| Shared TLS        | Let's Encrypt covering both                      | Security   | **Mandatory**                                                               |
| Storage path      | `/opt/cryptpad/data`                                 | Storage    | Where encrypted pads live                                                           |
| Admin email       | set via config                                                | Bootstrap  | For support contact                                                                              |
| Admin public key  | from your CryptPad account profile                                | Bootstrap  | Admin panel access = being listed in `config.js`                                                             |
| Max storage/user  | e.g., `50MB`                                                              | Quota      | Per free-tier user                                                                                            |
| Quotas for premium| e.g., `5 GB`                                                                  | Quota      | Configurable                                                                                                              |

## Install via Docker Compose

Clone the repo and follow the `docker-compose.yml` there. Outline:

```yaml
services:
  cryptpad:
    image: cryptpad/cryptpad:version-2025.x    # pin specific version
    container_name: cryptpad
    restart: unless-stopped
    environment:
      - CPAD_MAIN_DOMAIN=https://cryptpad.example.com
      - CPAD_SANDBOX_DOMAIN=https://cryptpad-sandbox.example.com
      - CPAD_CONF=/cryptpad/config/config.js
      - CPAD_HTTP2_DISABLE=true
    ports:
      - "3000:3000"
      - "3003:3003"
    volumes:
      - ./data/blob:/cryptpad/blob
      - ./data/block:/cryptpad/block
      - ./data/customize:/cryptpad/customize
      - ./data/data:/cryptpad/data
      - ./data/files:/cryptpad/datastore
      - ./config/config.js:/cryptpad/config/config.js
```

Front with nginx/Caddy/Traefik configured for BOTH domains + TLS. CryptPad ships an nginx config template in `docs/example.nginx.conf`.

## Config highlights (`config/config.js`)

```js
module.exports = {
    httpUnsafeOrigin: 'https://cryptpad.example.com',
    httpSafeOrigin:   'https://cryptpad-sandbox.example.com',
    httpAddress: '::',
    httpPort: 3000,
    websocketPort: 3003,
    maxWorkers: 4,
    adminEmail: 'admin@example.com',
    adminKeys: [
        // Your CryptPad account's signing key (from Profile)
        "[alice@cryptpad.example.com/pUb1iCk3yB4s364==]",
    ],
    defaultStorageLimit: 50 * 1024 * 1024,   // 50 MB per user
    customLimits: {
        // Higher quota for specific user
        "[boss@cryptpad.example.com/pUb1iCk3yB4s364==]": { limit: 5 * 1024 * 1024 * 1024, plan: 'premium' },
    },
    enforceMFA: false,    // TOTP
    logLevel: 'info',
};
```

## First boot

1. Browse `https://cryptpad.example.com`
2. Register — keys derived locally from username + password (NOT sent to server)
3. **Export your account keys** — Settings → Export keys. **This is the ONLY recovery option.** Losing password with no backup = data loss.
4. Copy your signing key from Profile → paste into `adminKeys` in `config.js` → restart CryptPad → your account is now admin
5. Admin panel → set default quotas, broadcast messages, ban abusers, instance customization

## Data & config layout

- `blob/` — binary uploads (encrypted)
- `block/` — chain blocks (encrypted pad content)
- `data/` — user metadata
- `datastore/` — older legacy storage
- `customize/` — branding overrides (logo, CSS)
- `config/config.js` — the only server-side config

## Backup

```sh
# Stop for consistency
docker compose stop cryptpad
tar czf cryptpad-$(date +%F).tgz blob/ block/ data/ datastore/ customize/ config/
docker compose start cryptpad
```

Since data is encrypted, the backup is useful only with the **users' keys** to decrypt. Without keys, the ciphertext is unrecoverable.

## Upgrade

1. Releases: <https://github.com/cryptpad/cryptpad/releases>. Active.
2. Read release notes — occasional breaking config changes.
3. Docker: bump tag, pull, up -d.
4. Bare metal: `git pull` + follow admin guide upgrade steps.

## Gotchas

- **Two domains are mandatory** — `main` (app) + `sandbox` (pad content). They MUST be different origins (subdomains OK). This is a security feature: the sandbox origin cannot read main-origin cookies.
- **HTTPS is mandatory** — WebCrypto requires secure context; no HTTP fallback.
- **"Active attack" threat model** — the server delivers the JavaScript that does the encryption. A malicious or compromised admin could ship trojaned JS that exfiltrates keys. CryptPad's README mentions this explicitly. Mitigations:
  - Don't self-host for adversarial users
  - Review code if deeply paranoid
  - Use SRI-style integrity pinning (outside CryptPad's scope)
  - Trust cryptpad.fr if you can't self-host + audit
- **Losing password = losing data** — there's no server-side password reset (server can't decrypt anything). Export your keys as a backup file + store securely. Teach all users to do this.
- **Sharing model**: pad URL = decryption key. Share the URL = share the pad. Treat URLs as secrets.
  - Three permission levels: viewer, editor, owner
  - Different URLs for each level (URL carries the capability)
- **No federation**: your CryptPad users can't collaborate with users on another CryptPad instance. Each instance is siloed.
- **Storage quotas**: essential for public instances — otherwise one user can fill your disk. Configure defaults + per-user overrides in config.js.
- **Team workspaces**: shared "teams" let multiple users collaborate in a shared drive. Teams have their own quota.
- **Performance**: real-time sync + encryption = CPU heavy on the client side. Large documents (>50 pages) get sluggish; larger sheets (10k+ rows) more so.
- **OnlyOffice dependency**: Sheet + Presentation apps embed OnlyOffice compiled to JS. Updates lag upstream OnlyOffice.
- **Mobile**: responsive PWA; functional but not as smooth as desktop. No native apps.
- **Admin panel** (at `/admin/`): broadcast messages to users, manage quotas, ban users, view registered users, check storage. Access by listing your signing key in `adminKeys`.
- **Registration**: can be disabled for private instances (invitation-only).
- **Customize**: put your logo + favicon + CSS in `customize/` — overrides defaults without editing source.
- **Forms + polls**: great for internal surveys + RSVP. Results encrypted to form owner.
- **Imports**: CryptPad can import .docx, .odt, .xlsx, .csv (converted during import), but conversion quality varies.
- **Exports**: same formats; re-encryption on export.
- **Legal context**: EU-funded project (NLnet / EU Commission); strong privacy stance; GDPR-compatible out of the box.
- **License**: AGPL-3.0.
- **Commercial support**: XWiki SAS offers paid hosting + on-prem contracts for orgs that need SLA + support.
- **Alternatives worth knowing:**
  - **Nextcloud Office (Collabora)** — OSS office on Nextcloud; NOT E2E; relies on server trust (separate recipe)
  - **OnlyOffice DocumentServer** — standalone; NOT E2E
  - **Etherpad** — collaborative text only; no encryption (separate recipe)
  - **Standard Notes** — E2E encrypted notes app; narrower scope (separate recipe)
  - **Anytype** — local-first E2E notes + bases
  - **Proton Drive / Proton Docs** — commercial E2E
  - **Google Docs / Microsoft 365** — the SaaS reference; NOT E2E from a privacy standpoint
  - **Choose CryptPad if:** you need E2E-encrypted real-time office collaboration for sensitive work (journalism, legal, HR, activism, academic).
  - **Choose Nextcloud + Collabora if:** you want office collaboration + full Nextcloud ecosystem, without E2E.
  - **Choose Google Docs if:** you trust Google + want max polish + unmatched collaboration UX.

## Links

- Repo: <https://github.com/cryptpad/cryptpad>
- Website: <https://cryptpad.org>
- Docs: <https://docs.cryptpad.org>
- Admin install guide: <https://docs.cryptpad.org/en/admin_guide/installation.html>
- Dev guide: <https://docs.cryptpad.org/en/dev_guide/setup.html>
- Releases: <https://github.com/cryptpad/cryptpad/releases>
- Docker Hub: <https://hub.docker.com/r/cryptpad/cryptpad>
- Hosted service: <https://cryptpad.fr>
- XWiki SAS: <https://xwiki.com>
- Threat model / security: <https://blog.cryptpad.org/2020/02/07/Threat-model/>
- Example nginx config: <https://github.com/cryptpad/cryptpad/blob/main/docs/example.nginx.conf>
- Matrix room: <https://matrix.to/#/#cryptpad:matrix.org>
