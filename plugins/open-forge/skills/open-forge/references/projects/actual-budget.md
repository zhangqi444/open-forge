---
name: actual-budget-project
description: Actual Budget recipe for open-forge. MIT-licensed local-first personal finance / envelope-budgeting app — Node.js Electron desktop apps + optional sync server for multi-device. Alternative to YNAB (You Need A Budget) and Mint (RIP). Local-first = your budget file lives on your device(s); the sync server's only job is to shuttle encrypted deltas between devices. End-to-end encryption supported when multiple devices sync. Single-container deploy: `actualbudget/actual-server:latest` on port 5006. Envelope-budgeting methodology, bank sync via GoCardless (EU / UK) and SimpleFIN (US/Canada). Covers the official docker-compose.yml (tiny!), ACTUAL_HTTPS_*/ACTUAL_PORT env vars, note that actual-server repo was merged INTO actualbudget/actual (packages/sync-server) in Feb 2025, and the PikaPods / Fly.io managed alternatives.
---

# Actual Budget

MIT-licensed local-first personal finance tool. Upstream: <https://github.com/actualbudget/actual>. Docs: <https://actualbudget.org/docs>. Website: <https://actualbudget.org>.

**Positioning:** privacy-focused alternative to YNAB (You Need A Budget — subscription-based, ~$100/year) and Mint (dead since 2024). Same envelope-budgeting methodology as YNAB, but local-first + self-hostable.

## Local-first — what that means

Your budget file lives on your device (as a SQLite DB inside Electron app data or in the browser's IndexedDB for the web client). The sync server's ONLY job is to relay encrypted deltas between your devices. If the server goes down, your budget still works — you just can't sync new changes to other devices until it's back.

This is architecturally different from Firefly III / Ledger-web / GnuCash-online:

- **Firefly III** = server-side app; data lives on server; clients are thin.
- **Actual** = client-side app; data lives on clients; server is just a sync relay.

Consequence: you can use Actual entirely WITHOUT a server (local-only apps for Windows/Mac/Linux). The sync server is optional, for multi-device households.

## Features

- **Envelope budgeting** — assign every dollar to a category before spending.
- **Accounts**: checking, savings, credit cards, loans, investments, off-budget accounts.
- **Transaction entry**: manual, CSV/OFX/QIF/CAMT.053 import, bank sync.
- **Bank sync**:
  - **GoCardless (Nordigen)** — free for EU / UK banks; 2000+ banks.
  - **SimpleFIN** — US / Canada; ~$15/year.
- **Scheduled + recurring transactions** + rules (auto-categorize).
- **Reports**: net worth, cash flow, spending by category, etc.
- **End-to-end encryption** — server stores only ciphertext deltas. Master password never leaves your device.
- **Multi-currency**.
- **Rule engine** — regex-based auto-categorization, splitting, payee normalization.
- **Plugins / community mods**: <https://actualbudget.org/docs/experimental/plugins>.
- **Mobile-web** — works in mobile browsers but no native mobile app (yet — community projects exist).
- **API + CLI** for scripting: `@actual-app/api`.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| **Local-only desktop app** (no server) | <https://actualbudget.org/download/> | ✅ | Single-user, single-device. Zero ops. |
| Docker run (self-host server) | <https://actualbudget.org/docs/install/docker> | ✅ Recommended | Multi-device / family self-host. |
| Docker Compose | <https://github.com/actualbudget/actual-server/blob/master/docker-compose.yml> | ✅ | Same image, compose convenience. |
| Fly.io managed | <https://actualbudget.org/docs/install/fly> | ✅ | ~$1.50/month hosted. |
| PikaPods managed | <https://www.pikapods.com/pods?run=actual> | ✅ | ~$1.40/month, easiest non-technical. |
| Build from source | standard Node build | ✅ | Contributors. |

Image: `docker.io/actualbudget/actual-server:latest`. Pin a version in prod.

## ⚠️ Repo consolidation (Feb 2025)

The old `actualbudget/actual-server` repo was merged into `actualbudget/actual` under `packages/sync-server` in February 2025 and marked read-only. The canonical location is now `https://github.com/actualbudget/actual/tree/master/packages/sync-server`. The old repo's README + docker-compose.yml are still valid for install (same image, same flags) but new development happens in the main repo.

## Inputs to collect

| Phase | Prompt | Tool / format | Applicability |
|---|---|---|---|
| preflight | "Use case?" | `AskUserQuestion`: `local-only-single-device` / `self-host-server-for-multi-device` / `managed-hosted (pikapods/fly)` | Drives path. |
| (local-only) | "OS for desktop app?" | `AskUserQuestion`: `windows` / `macos` / `linux` | Download from actualbudget.org/download/. |
| (self-host) | "Install method?" | `AskUserQuestion`: `docker-run` / `docker-compose` / `source-node-build` | Docker recommended. |
| ports | "Server port?" | Default `5006` | |
| storage | "Data dir?" | Default `./actual-data` host → `/data` container | SQLite + budget files live here. |
| tls | "TLS?" | `AskUserQuestion`: `none-behind-proxy` / `actual-handles-tls (ACTUAL_HTTPS_KEY/CERT)` | Typically use reverse proxy. |
| secrets | "Encryption passphrase?" | Strong random, per-user | Set in-app when enabling E2EE. Server never sees it. |
| limits | "File size limits?" | Defaults: 20MB sync / 50MB encrypted / 20MB upload | Bump for large budgets. |
| bank-sync | "Bank sync?" | `AskUserQuestion`: `none` / `gocardless (EU/UK)` / `simplefin (US/Canada)` | Optional. |

## Install — Local-only desktop (simplest)

1. Go to <https://actualbudget.org/download/>.
2. Download the installer for Windows / macOS / Linux.
3. Install + launch.
4. Create a budget file → start using.

No server, no Docker, no ops. Budget files live in OS-specific app data dir. You can export/backup manually.

## Install — Docker run (self-host server)

```bash
docker run -d --name actual-server \
  -p 5006:5006 \
  -v ~/actual-data:/data \
  --restart unless-stopped \
  docker.io/actualbudget/actual-server:latest
# → http://<host>:5006/
```

## Install — Docker Compose

Upstream `docker-compose.yml` (verbatim, tiny):

```yaml
services:
  actual_server:
    image: docker.io/actualbudget/actual-server:latest     # pin a version in prod
    ports:
      - '5006:5006'
    environment:
      # - ACTUAL_HTTPS_KEY=/data/selfhost.key
      # - ACTUAL_HTTPS_CERT=/data/selfhost.crt
      # - ACTUAL_PORT=5006
      # - ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB=20
      # - ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB=50
      # - ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB=20
    volumes:
      - ./actual-data:/data
    healthcheck:
      test: ["CMD-SHELL", "node src/scripts/health-check.js"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 20s
    restart: unless-stopped
```

Bring up:

```bash
mkdir ~/actual && cd ~/actual
curl -fsSLO https://raw.githubusercontent.com/actualbudget/actual-server/master/docker-compose.yml
docker compose up -d
# → http://<host>:5006/
```

On first visit, you'll be prompted to set a server password. Then sign up for an account → create a budget → the browser client syncs to the server.

## Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `ACTUAL_PORT` | `5006` | HTTP listen port |
| `ACTUAL_HOSTNAME` | `::` | Listen address (use `0.0.0.0` if you need IPv4-only) |
| `ACTUAL_HTTPS_KEY` | — | Path to TLS key (enables HTTPS) |
| `ACTUAL_HTTPS_CERT` | — | Path to TLS cert |
| `ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB` | `20` | Max per-sync upload |
| `ACTUAL_UPLOAD_SYNC_ENCRYPTED_FILE_SYNC_SIZE_LIMIT_MB` | `50` | Max encrypted upload |
| `ACTUAL_UPLOAD_FILE_SIZE_LIMIT_MB` | `20` | Max file upload |
| `ACTUAL_LOGIN_METHOD` | `password` | `password` / `openid` (SSO) |
| `ACTUAL_OPENID_*` | — | OpenID Connect SSO config |
| `ACTUAL_TRUSTED_PROXIES` | — | Behind reverse proxy — needed for real-IP logging |

Full reference: <https://actualbudget.org/docs/config/>.

## Reverse proxy (Caddy example)

```caddy
actual.example.com {
    reverse_proxy actual_server:5006
}
```

Don't set `ACTUAL_HTTPS_*` when behind a proxy; let the proxy do TLS.

## Bank sync setup

### GoCardless (EU / UK — free)

1. Sign up at <https://bankaccountdata.gocardless.com> → get a Secret ID + Secret Key.
2. In Actual: Settings → **Bank sync** → enter credentials.
3. Link an account: select your bank → complete bank-side consent (usually redirected to bank's online banking) → link.
4. Transactions sync on-demand (click "Sync" per account) or scheduled.

Free tier: 200 API calls/day, 200 requests/month per end-user.

### SimpleFIN (US / Canada — ~$15/year)

1. Sign up at <https://www.simplefin.org> → get a setup token.
2. In Actual: Settings → **Bank sync** → SimpleFIN → paste token.
3. Link accounts.

### None / manual

Import CSV / OFX / QIF / CAMT.053 files from your bank's download page. Works everywhere but is manual.

## End-to-end encryption

Per-budget, opt-in:

1. Open budget → Settings → **Enable end-to-end encryption**.
2. Set an encryption passphrase (separate from login password).
3. Re-encrypt existing data.

After enabling, server sees ONLY ciphertext. Lose the passphrase = budget is unreadable. Keep it with your password manager.

## Data layout

| Path (container) | Content |
|---|---|
| `/data/server-files/` | Per-user budget files (SQLite or encrypted blobs) |
| `/data/user-files/` | User uploads (optional attachment feature) |
| `/data/account.sqlite` | Server-side user database |
| `/data/server-files/account.sqlite` | Same (depending on version) |
| `/data/config.json` | Server config |

**Backup priority:**

1. **`/data/` volume** (tar it) — everything.
2. **Individual budget file exports** via the UI — additional offsite copy.
3. **E2EE passphrase** (if enabled) — store in password manager; server-side backup is useless without it.

Client backup: the desktop app stores budgets in OS app data; also export via File → Export (Actual's own format) for portability.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
docker compose logs -f actual_server
```

Actual runs DB migrations automatically. Release notes: <https://github.com/actualbudget/actual/releases>.

Major-version bumps (v24 → v25) may change the sync protocol — desktop clients + server should be upgraded together.

## Gotchas

- **Local-first means your budget is AT THE CLIENT.** If you clear browser data / uninstall the desktop app, you lose uncommitted changes. Sync regularly when multi-device.
- **Server password protects the whole server.** It's a single shared secret for account creation. Treat it like a sudo password — don't share publicly.
- **E2EE is per-budget, OPT-IN.** By default, the server CAN read your budget data. Enable E2EE in budget settings if privacy matters.
- **Losing the E2EE passphrase = budget unreadable.** Not recoverable. Store in password manager; write down master recovery.
- **No mobile native app** yet. Mobile-web works (PWA), but UX is limited. Community projects: <https://github.com/microadam/actual-plaid-api>, etc.
- **Bank sync requires API account at GoCardless or SimpleFIN.** Neither is free forever — GoCardless has generous free tier for personal use; SimpleFIN charges.
- **GoCardless consent expires every 90 days** (regulatory requirement). You re-auth every 3 months.
- **Single-user friction**: Actual was designed for single-user + single-household. Multi-user in one budget works but is clunky (the "shared budget" concept).
- **No budget-level permissions.** Anyone with a login to the server can create their own budgets. All budgets share the server (different users can have different budgets, but not granular per-budget sharing without giving full login).
- **OIDC SSO** is supported via `ACTUAL_LOGIN_METHOD=openid`. Works well with Authelia / Authentik / Pocket ID.
- **File size limits** can bite on large budgets with decades of transactions. Bump `ACTUAL_UPLOAD_FILE_SYNC_SIZE_LIMIT_MB` if you see 413s.
- **Starting fresh vs migrating**: read <https://actualbudget.org/docs/migration/> for migrating from YNAB / Mint / etc.
- **Report engine is decent** but not as flexible as full-spreadsheet tools. Export to CSV if you need custom analysis.
- **No investment tracking UI beyond basic accounts.** Actual is focused on CHECKING / credit-card / budgeting. For investment portfolio tracking, look at Ghostfolio / Wealthfolio.
- **Rules engine (auto-categorization)** is regex-based and powerful. Start simple; rules grow organically.
- **Repo consolidation**: new development in `actualbudget/actual` `packages/sync-server`; old `actualbudget/actual-server` is frozen. Both refer to the SAME Docker image.
- **PikaPods / Fly.io hosting** is a legit alternative — $1.40-1.50/month for managed. Worth it if you value time over control.
- **Backup scripts**: several community scripts automate `/data` backups; see Discord.
- **Browser-based client** stores DB in IndexedDB → different browsers = different local state. Chrome vs Firefox on same device = 2 separate stores.
- **Envelope budgeting has a learning curve** — if you're coming from Mint (passive tracking), there's a mindset shift. Read the community's "Starting Fresh" guide.
- **Desktop app = Electron** — ~200 MB download, ~500 MB RAM. If that bothers you, use the web app.
- **Actual is actively developed** (rare for open-source personal finance); core team + community are responsive on Discord.

## Links

- Upstream repo: <https://github.com/actualbudget/actual>
- Sync-server package (was `actual-server`): <https://github.com/actualbudget/actual/tree/master/packages/sync-server>
- Docs: <https://actualbudget.org/docs>
- Install overview: <https://actualbudget.org/docs/install/>
- Docker install: <https://actualbudget.org/docs/install/docker>
- Fly.io install: <https://actualbudget.org/docs/install/fly>
- Configuration: <https://actualbudget.org/docs/config/>
- Desktop downloads: <https://actualbudget.org/download/>
- Website: <https://actualbudget.org>
- Docker Hub: <https://hub.docker.com/r/actualbudget/actual-server>
- Releases: <https://github.com/actualbudget/actual/releases>
- Discord: <https://discord.gg/pRYNYr4W5A>
- FAQ: <https://actualbudget.org/docs/faq>
- Envelope budgeting guide: <https://actualbudget.org/docs/getting-started/envelope-budgeting>
- Starting Fresh guide: <https://actualbudget.org/docs/getting-started/starting-fresh>
- Migration from YNAB / Mint / etc.: <https://actualbudget.org/docs/migration/>
- PikaPods managed: <https://www.pikapods.com/pods?run=actual>
- Bank sync (GoCardless): <https://bankaccountdata.gocardless.com>
- Bank sync (SimpleFIN): <https://www.simplefin.org>
