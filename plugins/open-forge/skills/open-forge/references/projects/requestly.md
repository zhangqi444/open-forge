---
name: Requestly
description: "Open-source HTTP debug + mock platform — browser extension + desktop apps that intercept, modify, and mock HTTP(S) requests/responses. Combines Charles Proxy + Fiddler + Postman + mock server. Self-hosted server optional. AGPL-3.0."
---

# Requestly

Requestly is **a browser-extension + desktop-app platform for intercepting, modifying, and mocking HTTP(S) traffic** — rewriting URLs, modifying headers + request/response bodies, throttling, blocking, injecting scripts, creating mock API endpoints, capturing sessions for debugging, and sending API requests. Billed as "Charles Proxy + Fiddler + Postman in one, with beautiful UI and collaboration."

Primarily a **developer productivity tool**. Self-hosting usually applies to:

1. **The backend API server** (session sync, mock server, team collaboration)
2. **The browser extensions** connect to it for persistence + sharing

If you're a solo dev, you can use the extension/desktop app in local mode with no backend at all. If you want team features (shared rules, shared mocks, teams, SSO), you self-host the server or use their cloud.

Features:

- **HTTP Rules** — intercept + modify:
  - URL rewrite (Map Local, Map Remote)
  - Redirect (e.g., prod → staging)
  - Modify request/response headers
  - Modify request/response body
  - Throttling (latency simulation)
  - Block requests
  - Inject scripts on web pages
- **API Client** — import cURL, send requests, see responses (Postman-like, minimal)
- **Mock Server** — create API mocks with custom responses; URL generated per-mock
- **Sessions** — record browser session with network + console + DOM for bug repro
- **Collaboration** — share rules with teammates (workspaces)
- **Integrations**: Selenium, Cypress, Playwright, Puppeteer, ADB (for mobile traffic)

- Upstream repo: <https://github.com/requestly/requestly>
- Website: <https://requestly.io>
- Docs: <https://docs.requestly.io>
- Downloads: <https://requestly.io/downloads>
- Chrome extension: <https://chrome.google.com/webstore/detail/redirect-url-modify-heade/mdnleldcmiljblolnjhpnblkcekpdkpa>
- Slack: <https://bit.ly/requestly-slack>
- Getting Started (cloud): <https://app.requestly.io/getting-started>

## Architecture in one minute

- **Client** (where rules run):
  - **Browser extension** — Chrome, Firefox, Edge, Brave, Opera, Safari — MV3 where supported
  - **Desktop app** (Electron) — Windows, macOS, Linux — can capture mobile/desktop-app traffic via proxy
- **Backend server** (optional self-host):
  - Node.js backend + Firestore (or MySQL) + Redis
  - Serves auth, workspace sync, mock server, sessions storage
  - Repo ships docker-compose scaffolding for self-host
- **Cloud**: `app.requestly.io` — hosted by Requestly Inc. (free tier + paid)

## Compatible install methods

| Infra              | Runtime                                                    | Notes                                                                   |
| ------------------ | ---------------------------------------------------------- | ----------------------------------------------------------------------- |
| Single VM          | Docker Compose (self-host repo `docker-compose.yml`)          | For team / private deployment                                                    |
| Browser only       | Install extension from store; local-only rules                       | **No server needed for solo local use**                                                 |
| Desktop only       | Electron app                                                                      | For capturing non-browser traffic                                                                 |
| Kubernetes         | Community/custom manifests                                                                       | Possible                                                                                                  |
| Managed (cloud)    | **app.requestly.io** (upstream SaaS, free tier)                                                               | Simplest                                                                                                        |

## Inputs to collect

| Input              | Example                          | Phase     | Notes                                                             |
| ------------------ | -------------------------------- | --------- | ----------------------------------------------------------------- |
| Domain             | `requestly.example.com`              | URL       | Self-hosted server                                                     |
| DB                 | Firestore/MySQL/Postgres creds          | DB        | Upstream docs specify; check repo                                              |
| Redis              | host + port                                   | Cache     | For queues                                                                               |
| SMTP               | host/port/user/pass                                  | Email     | For invites / resets                                                                                  |
| Auth providers     | Google OAuth / email / SSO                                        | Auth      | Configure in server env                                                                                             |
| Extension endpoint | point extension to your self-hosted URL                                | Client    | Per-user config                                                                                                                  |

## Install (self-hosted server, Docker)

Upstream ships the open-source repo with scaffolding. Self-hosted is less-documented than the cloud path; read `requestly/requestly/README` and `docker/` folder in repo carefully.

Typical shape:

```yaml
services:
  requestly-backend:
    image: requestly/requestly:latest          # pin in prod; check upstream image name
    environment:
      DB_URI: ...
      REDIS_URL: redis://redis:6379
      APP_URL: https://requestly.example.com
      GOOGLE_OAUTH_CLIENT_ID: ...
      GOOGLE_OAUTH_CLIENT_SECRET: ...
      JWT_SECRET: <random>
    depends_on: [redis]
    ports: ["5000:5000"]
  redis:
    image: redis:7-alpine
```

Then configure the extension/desktop app to point at your self-hosted URL (Settings → Server URL override).

**Note:** the upstream project is primarily optimized for their cloud. Self-hosting works but documentation can lag; plan for some friction + community support on Slack.

## Install (extension only, local use)

1. Install from Chrome Web Store / Firefox Add-ons
2. Click extension icon → create rule (e.g., redirect `https://api.prod.com` → `https://api.staging.com`)
3. Rules apply immediately; no server needed

## Desktop app (capture mobile traffic)

1. Install desktop app
2. Configure phone to use desktop's IP:port as HTTP proxy (Wi-Fi settings)
3. Install Requestly CA cert on phone (for HTTPS interception) — iOS: Settings → General → Profile; Android: System CA store (≥ Android 14 requires rooting for system CAs)
4. Traffic flows through desktop; rules apply

## First boot

1. **Solo dev workflow (most common):**
   - Install browser extension
   - Create HTTP rule ("Map prod → staging"), enable
   - Browse → rule applies
2. **Team workflow:**
   - Self-host or use cloud
   - Create workspace; invite teammates
   - Share rules/mocks within workspace
   - Each teammate installs extension + logs into your server

## Data & config layout (self-hosted)

- DB — rules, mocks, sessions, users, workspaces
- Redis — sessions + queues
- Object/file storage — session recordings (can be large)

## Backup (self-hosted)

- DB dump (Postgres/MySQL/Firestore export)
- Object storage for session recordings

## Upgrade

1. Releases: <https://github.com/requestly/requestly/releases>. Active.
2. Extension: auto-updates via store.
3. Desktop app: in-app update prompt.
4. Self-host: bump Docker tag; migrations likely auto.

## Gotchas

- **HTTPS interception on phones requires installing a CA** — treat with care. Uninstall the CA when done; don't leave debugging CAs trusted on production devices.
- **Android 14+** doesn't trust user-installed CAs for apps targeting API 34 — making Android HTTPS debugging harder; desktop-app proxy may not see TLS-pinned app traffic.
- **Certificate pinning in apps** (banking, Instagram, etc.) — Requestly can't decrypt without pinning bypass (Frida, etc.). Don't expect to intercept every app.
- **Extension permissions** are broad — it can read/modify your traffic. Install the official extension only; don't sideload unknown builds.
- **Rule privacy** — in team workspace, shared rules may contain secrets in headers. Don't embed production tokens in rules that go into shared workspaces.
- **Browser extension vs MV3** — Chrome MV3 changed `webRequest` semantics; some header-modify rules migrated to `declarativeNetRequest` with quirks. Latest Requestly handles this, but older patterns may not.
- **Firefox** has a different extension model; some features may lag Chrome.
- **Self-host UX** — the primary path Requestly targets is the cloud. Self-hosting repo isn't always turnkey — plan for reading issues + Slack for setup help.
- **Session recording privacy** — captures DOM + network + console; sharing with teammates may leak PII from your live session. Review before sharing.
- **Mock server URLs** — self-hosted mocks publish URLs on your domain; treat as public-reachable if needed.
- **Migration from cloud to self-hosted** — export via API; not a one-click operation.
- **AGPL-3.0** — modifying + exposing to others requires source disclosure.
- **Commercial tiers** — Requestly Cloud has free + Pro tiers; team features gated.
- **Alternatives worth knowing:**
  - **mitmproxy** — CLI/web proxy; scriptable; more power-user (separate recipe likely)
  - **Charles Proxy** — commercial classic; excellent for debugging
  - **Fiddler Classic / Fiddler Everywhere** — commercial; Windows-heavy
  - **Proxyman** — macOS commercial; polished
  - **HTTPToolkit** — open-core, powerful; Electron + CLI (separate recipe likely)
  - **Postman / Insomnia / Bruno** — API clients (different use case; Requestly overlaps on API client)
  - **WireMock / Prism / json-server** — standalone mock servers
  - **ModHeader / Tamper** — simpler browser extensions
  - **Choose Requestly if:** you want an integrated rule + mock + API + session tool with a browser extension UX.
  - **Choose mitmproxy if:** you want scriptability + CLI + depth, cloud-free.
  - **Choose Charles/Proxyman if:** you want commercial polish + pay for it.
  - **Choose Postman/Bruno if:** API-client is the primary need.

## Links

- Repo: <https://github.com/requestly/requestly>
- Website: <https://requestly.io>
- Docs: <https://docs.requestly.io>
- Downloads: <https://requestly.io/downloads>
- Chrome extension: <https://chrome.google.com/webstore/detail/redirect-url-modify-heade/mdnleldcmiljblolnjhpnblkcekpdkpa>
- Getting Started: <https://app.requestly.io/getting-started>
- Slack: <https://bit.ly/requestly-slack>
- Releases: <https://github.com/requestly/requestly/releases>
- API Client docs: <https://requestly.io/feature/api-client>
- Mock server docs: <https://docs.requestly.io/mock-server>
- mitmproxy alternative: <https://github.com/mitmproxy/mitmproxy>
- HTTPToolkit alternative: <https://github.com/httptoolkit/httptoolkit>
