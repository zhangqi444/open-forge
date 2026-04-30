---
name: Standard Notes
description: "End-to-end encrypted note-taking app for digitalists — cross-platform (Web/Mac/Win/Linux/iOS/Android) with self-hostable backend. Emphasis on longevity + sustainability. Zero-knowledge encryption: server sees only ciphertext. AGPL-3.0 (core). Commercial extensions + SaaS by parent Proton/Standard Notes."
---

# Standard Notes

Standard Notes is **a cross-platform, end-to-end encrypted note-taking app** with apps for Web, macOS, Windows, Linux, iOS, and Android. Its defining design choice: **zero-knowledge encryption** — your notes are encrypted on-device before being synced; the server stores only ciphertext. If someone breaches the server, they see encrypted blobs they can't decrypt.

**Acquisition context**: Standard Notes was **acquired by Proton AG in 2024** (same parent as ProtonMail / Proton VPN / SimpleLogin). The open-source app + self-host backend remain under their existing licenses; the hosted service is now part of the Proton ecosystem.

Focus areas:

- **Longevity**: they're explicit about building to last decades — plaintext-forward file format, portable, few dependencies
- **Simplicity**: plain-text notes by default; rich features are optional extensions
- **Privacy**: zero-knowledge E2E encryption; server never sees your content
- **Sustainability**: funded by subscriptions + Proton; no ads, no tracking

Features:

- **Cross-platform apps**: Web, macOS, Windows, Linux (AppImage/deb/snap), iOS, Android
- **Zero-knowledge encryption** — AES-256-GCM + Argon2 for key derivation
- **Unlimited devices** on free tier
- **Rich editors** (paid): Markdown, Code, Rich Text, Spreadsheet, Task, Daily Writing
- **File attachments** (paid)
- **Listed** — publish notes as a blog (on SN's Listed.to)
- **Smart tags / nested tags**
- **Vault passwords** — protect specific notes with additional passphrase
- **Two-factor auth** — TOTP
- **Revision history** — restore previous note versions (100+ revisions)
- **Extensions API** — build custom editors

- Upstream monorepo: <https://github.com/standardnotes/app>
- Server: <https://github.com/standardnotes/server>
- Website: <https://standardnotes.com>
- Self-hosting docs: <https://standardnotes.com/help/self-hosting/getting-started>
- Listed (blog publishing): <https://listed.to>
- Parent (Proton): <https://proton.me>

## Architecture in one minute

- **Client apps**: TypeScript / React (web, Electron), React Native (mobile)
- **Server stack** (for self-host):
  - Multiple microservices: auth, syncing, files, websockets, revisions, workspace
  - **MySQL** (primary DB)
  - **Redis** (sessions / pub-sub)
  - Built with Node.js / TypeScript
- **Encryption happens on client** — server just stores blobs + metadata
- **Docker Compose stack** is the documented self-host path (not trivial — 6-10 containers)

## Compatible install methods

| Infra          | Runtime                                                            | Notes                                                                         |
| -------------- | ------------------------------------------------------------------ | ----------------------------------------------------------------------------- |
| Single VM      | **Docker Compose (`standardnotes/server`)**                            | **Upstream-documented**                                                           |
| Single VM      | **Just use the web app** at app.standardnotes.com (E2E encrypted anyway)         | Zero ops                                                                                  |
| Kubernetes     | Community manifests                                                                | Nontrivial — many services                                                                                |
| Raspberry Pi   | Marginal — multi-container footprint is heavy                                                | RAM-constrained                                                                                                       |
| Managed        | **standardnotes.com** (Proton-operated)                                                             | Recommended for most users                                                                                                        |

## Inputs to collect

| Input              | Example                             | Phase      | Notes                                                                       |
| ------------------ | ----------------------------------- | ---------- | --------------------------------------------------------------------------- |
| Domain             | `sync.example.com`                       | URL        | API endpoint (apps point at this)                                                   |
| MySQL creds        | user/pass/db                                | DB         | Via Docker Compose env                                                                    |
| Redis              | default bundled                                 | Cache      | Local service                                                                                       |
| JWT secrets        | generated (multiple!)                                   | Security   | Each service has its own; generate long random                                                                        |
| SMTP (opt)         | for password reset                                              | Email      | Required for user onboarding if self-registering                                                                                       |
| File storage       | local or S3                                                          | Files      | For paid-tier file attachments                                                                                                       |
| Reverse proxy      | nginx / Traefik / Caddy                                                        | TLS        | Required — apps need HTTPS                                                                                                                 |

## Install self-hosted server

Follow <https://github.com/standardnotes/server> — the repo ships a `server-application` compose + env generator script:

```sh
git clone https://github.com/standardnotes/server.git
cd server
cp .env.sample .env
# Generate secrets (a dozen of them)
./server.sh setup
./server.sh start
```

Point your reverse proxy (`api.example.com`) at the server's port; configure TLS.

**Client config**: on sign-in, apps accept a custom **Sync Server** URL (Preferences → Advanced → Sync Server). Point at `https://api.example.com` and sign up.

## First boot

1. Bring up stack; wait for migrations
2. Open web or desktop app → Sign in → **Advanced → Sync Server URL** → enter your self-host URL
3. **Register** a new account (a new one — existing standardnotes.com accounts are a different DB)
4. Create a few notes → verify they sync
5. Enable 2FA on your account
6. Set up a second device → restore sync

## Data & config layout

- MySQL — notes (encrypted blobs), users, revisions, sync state
- Redis — sessions, pub-sub
- File storage — paid-tier attachments
- Secrets/JWT keys — `.env` (protect like crown jewels)

## Backup

```sh
# MySQL dump
docker exec sn-db mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases | gzip > sn-db-$(date +%F).sql.gz
# File uploads (paid tier)
tar czf sn-files-$(date +%F).tgz files/
# .env (contains all JWT keys + DB creds)
cp .env sn-env-$(date +%F).bak
```

**Losing `.env` JWT keys breaks sync for all clients** — they'll need to re-sign-in. And the encrypted data is only recoverable if users know their account password (which derives the encryption key).

## Upgrade

1. Releases: <https://github.com/standardnotes/server/releases>. Active.
2. `git pull` → `./server.sh start` (rebuilds, runs migrations)
3. Before major jumps, back up DB + `.env`. Watch release notes for env var additions.

## Gotchas

- **Self-hosting SN is complex.** ~8-10 containers, multiple microservices, MySQL + Redis, TLS mandatory, lots of env vars. Not a one-line docker-run. If you just want E2E encrypted notes, the hosted service (standardnotes.com) is E2E too — **you don't need to self-host for privacy** because the server can't decrypt anyway.
- **Proton acquisition (2024)**: self-host code is still OSS; future roadmap may emphasize Proton-ecosystem integration. Watch upstream.
- **Paid features are extensions + files + some editors** — the free tier is "basic plain-text notes, unlimited devices." Extensions are gated. You can self-host the core but extensions are tied to your paid plan.
- **Encryption key = your password.** Lose password = lose notes. There's no recovery — that's the whole point of zero-knowledge. Make a strong password + write it down + consider a backup password.
- **Two-factor backup**: if you enable 2FA + lose your authenticator → recovery is via backup codes. SAVE THEM.
- **Self-host client apps too (optional)**: you can self-host the web app (static files) + point at your self-host API. Or use official apps pointed at your API.
- **Client app version compatibility**: mobile apps may be harder to point at self-host — check SN docs for current instructions.
- **Listed (blog publishing)** is a Standard Notes SaaS feature — not self-hostable unless you build your own equivalent.
- **Revision history storage grows** — old revisions kept per retention policy; purge via admin if needed.
- **File attachments** — paid-tier; needs file-storage microservice + local or S3 backend.
- **Multi-user**: SN server supports multiple accounts; use for family. No team/group features beyond that.
- **Server resource**: ~2 GB RAM for the full stack (containers); MySQL dominates.
- **No mobile sync-server picker UI in all versions** — check current SN docs; sometimes requires a special "Advanced" option or URL scheme.
- **Listed content** stays on SN's servers even if you move to self-host.
- **Security model assumption**: encryption happens client-side; server compromise = ciphertext leak but no content leak. This only holds if clients are trustworthy; a malicious update (supply chain) could exfiltrate plaintext. SN reproducible builds help.
- **License**: the monorepo uses **AGPL-3.0** for core code (check LICENSE files). Proton acquisition doesn't change existing licenses.
- **Alternatives worth knowing:**
  - **Joplin** — E2E encrypted notes + self-host sync (WebDAV/Nextcloud/S3/Joplin Server) (separate recipe likely)
  - **Obsidian** — local Markdown files; Sync is commercial; not E2E by default but encryption-at-rest option (separate recipe likely)
  - **Trilium / TriliumNext** — self-hosted note-taking with tree structure (separate recipe likely)
  - **Logseq** — local Markdown, outliner style
  - **Silverbullet** — Markdown wiki
  - **AppFlowy** — Notion-alike self-hostable
  - **SimpleNote** (Automattic) — SaaS, free, unlimited, not E2E encrypted
  - **Bear** — Apple-only, polished, not E2E
  - **Notion** (SaaS) — workspace-first, not E2E
  - **Cryptee** — E2E encrypted photos + notes SaaS
  - **Choose Standard Notes if:** you specifically want zero-knowledge E2E + longevity-focused design + cross-platform apps; are OK with Proton ecosystem direction.
  - **Choose Joplin if:** you want Markdown + easier self-host + more editor control.
  - **Choose Obsidian if:** local-first + plugin ecosystem matter more than server sync.
  - **Choose Trilium if:** hierarchical / relational notes matter.

## Links

- Monorepo (apps): <https://github.com/standardnotes/app>
- Server: <https://github.com/standardnotes/server>
- Website: <https://standardnotes.com>
- Self-hosting guide: <https://standardnotes.com/help/self-hosting/getting-started>
- Longevity: <https://standardnotes.com/longevity>
- Help: <https://standardnotes.com/help>
- Forum: <https://standardnotes.com/forum>
- Discord: <https://standardnotes.com/discord>
- Listed (blogs): <https://listed.to>
- Proton (parent): <https://proton.me>
- Releases: <https://github.com/standardnotes/app/releases>
- Joplin (alt): <https://joplinapp.org>
- Obsidian (alt): <https://obsidian.md>
- Trilium (alt): <https://github.com/zadam/trilium>
