---
name: Converse
description: "100% client-side web-based XMPP/Jabber chat app. Pairs with an XMPP server (Prosody/ejabberd/Openfire). OMEMO end-to-end encryption, MUC, HTTP file upload. Mozilla Public License 2.0. Active + Weblate translations + desktop/Tauri companions."
---

# Converse

Converse is **"Slack / Discord / WhatsApp, but XMPP + browser-based + yours"** — a modern, feature-rich, 100% client-side XMPP chat application that runs in a web browser. Runs as standalone web app, embedded component on an existing website, or as a desktop app (Converse Desktop / Tauri). **Important: Converse is ONLY the client** — it needs an XMPP server (Prosody, ejabberd, Openfire, etc.) to connect to. Use together with self-hosted Prosody for a fully self-hosted chat stack with E2E encryption (OMEMO).

Built + maintained by **JC Brand + community** (conversejs org). **License: Mozilla Public License 2.0**. Active; mature (10+ year project); 40+ translated languages via Weblate; active XMPP MUC community.

Use cases: (a) **self-hosted team chat** — paired with Prosody/ejabberd (b) **embedded customer-support chat** on your website (c) **federated XMPP community** — chat with users on other XMPP servers across the open XMPP network (d) **E2E-encrypted group chat** — OMEMO encryption (signal-like E2E) (e) **escape Slack/Discord/WhatsApp** — open protocol, federated, self-hostable (f) **anonymous chat** — anonymous login without account (server permitting) (g) **desktop chat client** via Converse Desktop / Tauri companion.

Features (from upstream README):

- **Multiple UI modes**: overlay chat boxes, full-page app, embedded components
- **Rich messaging**: styling, corrections, reactions, URL previews
- **OMEMO** end-to-end encryption (Signal-compatible algorithm)
- **HTTP file upload** (XEP-0363)
- **Multi-user chat (MUC)** — group chats / "rooms"
- **Status messages + availability indicators**
- **Desktop notifications**
- **Plugin architecture** via pluggable.js
- **40+ languages** via Weblate
- **Responsive** desktop + mobile
- **Anonymous login** (server permitting)
- **Live demos** at conversejs.org

- Upstream repo: <https://github.com/conversejs/converse.js>
- Homepage / demo: <https://conversejs.org>
- Docs: <https://conversejs.org/docs/>
- Quickstart: <https://conversejs.org/docs/quickstart/>
- Configuration: <https://conversejs.org/docs/configuration/>
- Plugin development: <https://conversejs.org/docs/development/plugin-development/>
- Desktop: <https://github.com/conversejs/converse-desktop>
- Tauri: <https://github.com/conversejs/converse-tauri>
- XMPP MUC: xmpp:discuss@conference.conversejs.org
- Translations: <https://hosted.weblate.org/engage/conversejs/>

## Architecture in one minute

- **JavaScript (TypeScript) single-page app** — runs ENTIRELY in browser
- **No backend** — Converse IS the client
- **Requires XMPP server** — Prosody (Lua), ejabberd (Erlang), Openfire (Java), etc.
- **Resource** for web-serving: tiny — just static file hosting
- **Deployment**: serve bundled JS + HTML from any static webserver (nginx, Caddy)
- **XMPP server** is the actual "backend" — runs 5222 (client) + 5269 (S2S federation) + 5280 (BOSH/WebSocket)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Static webserver** | **Build + serve dist/ with nginx/Caddy**                      | **Primary**                                                                        |
| **Prosody integration** | **mod_conversejs** serves it straight from Prosody               | **Clean all-in-one XMPP + chat UI**                                                                               |
| CDN                | Load from CDN in a page                                                     | Simplest embedding                                                                                   |
| Docker             | Various community images (app-only; XMPP server separately)                                                          | Typical                                                                                               |
| Converse Desktop / Tauri | Native app wrapper                                                                                            | For desktop users                                                                                                 |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| XMPP server hostname | `xmpp.example.com`                                          | **CRITICAL** | **MUST have a working XMPP server first**                                                                                    |
| BOSH/WebSocket URL   | `wss://xmpp.example.com:5443/xmpp-websocket`                | Connection   | Converse talks to XMPP via WebSocket or BOSH                                                                                    |
| Web-hosting domain   | `chat.example.com`                                          | URL          | TLS recommended                                                                                    |
| Converse config      | JS config object: bosh_service_url, websocket_url, whitelisted_plugins, etc. | **CRITICAL** | **All behavior is here**                                                                                                            |
| OMEMO enabled        | `omemo_default: true`                                       | E2E          | For encryption                                                                                                            |

## Install via Docker + Prosody (typical pair)

```yaml
services:
  prosody:
    image: prosody/prosody:0.12      # **pin version**
    ports:
      - "5222:5222"   # client
      - "5269:5269"   # server-to-server (federation)
      - "5280:5280"   # BOSH/WebSocket HTTP
    volumes:
      - ./prosody-config:/etc/prosody
      - ./prosody-data:/var/lib/prosody

  converse-web:
    image: nginx:alpine
    volumes:
      - ./converse-dist:/usr/share/nginx/html    # Converse prebuilt dist + index.html
    ports: ["8080:80"]
```

`index.html` (minimal):

```html
<script src="/dist/converse.min.js"></script>
<link rel="stylesheet" href="/dist/converse.min.css">
<script>
  converse.initialize({
    bosh_service_url: 'https://xmpp.example.com:5280/http-bind/',
    websocket_url: 'wss://xmpp.example.com:5443/xmpp-websocket',
    authentication: 'login',
    auto_away: 300,
    blacklisted_plugins: [],
    view_mode: 'fullscreen',
    omemo_default: true,
  });
</script>
```

## First boot

1. Deploy XMPP server (Prosody/ejabberd) **first**; verify it works
2. Deploy Converse as static assets with config pointing to XMPP server
3. Register first user on XMPP server
4. Browse Converse URL, log in, verify chat works
5. Test MUC (group chat) creation
6. Enable OMEMO; test E2E between two accounts
7. Put both behind TLS reverse proxy
8. Back up XMPP server data (Converse itself is stateless)

## Data & config layout

- **Converse is STATELESS** — all user data (accounts, messages, rosters) lives on the XMPP server
- JS config: hardcoded in index.html or loaded dynamically
- Client-side localStorage for UI preferences + cached state
- OMEMO keys in IndexedDB client-side (sensitive — tied to the browser)

## Backup

- **Back up the XMPP server** (Prosody `/var/lib/prosody`, ejabberd DB), NOT Converse itself.

## Upgrade

1. Releases: <https://github.com/conversejs/converse.js/releases>. Semver; active.
2. Rebuild dist + redeploy static files.
3. Test major version jumps; config syntax occasionally evolves.

## Gotchas

- **CONVERSE IS CLIENT-ONLY** — **#1 misconception**. New users expect Converse to "be a chat server." It's not. You need Prosody / ejabberd / Openfire / Tigase / MongooseIM / etc. **Recipe convention: flag "client-only / needs-server" status for tools that don't include the server side.** Applicable to: Converse, Gajim, Element (Matrix client-only), IRC clients in general.
- **XMPP ECOSYSTEM COMPLEXITY**: XMPP is a complex protocol with MANY XEPs (extension proposals). Feature support depends on BOTH client + server. Checklist for common features:
  - **OMEMO** (E2E encryption): needs XEP-0384; Prosody + Converse support ✓
  - **Push notifications**: needs XEP-0357; mobile clients need this
  - **MUC** (group chat): XEP-0045 / MUC; universal
  - **MAM** (message archive): XEP-0313; needed for message history
  - **HTTP File Upload**: XEP-0363; needs server component
  - **Carbons** (multi-device sync): XEP-0280; universal
  - **Bookmarks**: XEP-0049 / 0402
- **OMEMO KEYS LIVE CLIENT-SIDE**: in IndexedDB of the browser. **Clear-browser-data = lose E2E keys + historical E2E messages permanently** unless backed up. Users should back up OMEMO keys or understand this risk.
- **FEDERATION = S2S PORT 5269**: XMPP's killer feature is cross-server federation. Users on your `example.com` server can chat with users on `xmpp.messaging.one` or `jabber.de`. Requires:
  - S2S port 5269 open
  - DNS SRV records for `_xmpp-server._tcp`
  - TLS for S2S (DANE / STARTTLS)
  - **Federation = BOTH privacy-friendly (decentralized) AND abuse-surface (spam from open federation)**; adjust federation-whitelist as needed
- **FEDERATION SPAM = REAL PROBLEM**: open XMPP federation has attracted spammers similarly to open email. Modern Prosody ships with sensible anti-spam modules. Check before opening federation.
- **BOSH vs WEBSOCKET**: both supported; WebSocket is newer + better. BOSH is HTTP-polling-based fallback for environments that block WebSocket.
- **CORS for WebSocket/BOSH**: if Converse is served from a different domain than the XMPP server, configure CORS on the XMPP HTTP endpoint. Common homelab stumble.
- **HUB-OF-CREDENTIALS: 0 (STATELESS for Converse itself)**: **5th tool in stateless-tool-rarity** (OpenSpeedTest 91, Moodist 93, dashdot 93, Redlib 95-if-no-OAuth, **Converse 96**). But the XMPP server it pairs with IS Tier 2 (user accounts, messages, rosters). Frame accordingly.
- **DUAL-TOOL SECURITY MODEL** (Converse + XMPP server): attack surface is the XMPP server + the client's browser storage. Converse itself is static assets.
- **BROWSER PERMISSIONS**: desktop notifications, possibly microphone (for A/V if enabled). Standard browser-permission model.
- **ANONYMOUS LOGIN SUPPORT**: Converse supports anonymous login (SASL ANONYMOUS) if XMPP server permits. Useful for public chat rooms; disable if you want named users only.
- **MPL-2.0 LICENSE** — weak copyleft (file-level); commercial-reuse-friendly; obligations only on MPL-licensed files if modified.
- **INSTITUTIONAL-STEWARDSHIP**: JC Brand (JC Brand / jcbrand) individual + long-term community + opencollective-funding. Hybrid. **22nd tool in institutional-stewardship — sole-founder-with-mature-community sub-tier.**
- **SUSTAINABILITY**: Converse has OpenCollective funding + consulting (jcbrand.com consulting gigs) + sponsors. Hybrid-funding model. **15th tool in pure-donation/community with consulting-hybrid**.
- **TRANSPARENT-MAINTENANCE**: MPL-2 + Weblate + demo + docs + tests + 10+ year history + active commits. **26th tool in transparent-maintenance family.**
- **WEBLATE TRANSLATIONS** (40+ languages) — pattern with Kometa 95. International care signal.
- **E2E ENCRYPTION MESSAGING TOOLS INVITE NATION-STATE ATTENTION**: OMEMO-enabled XMPP + Converse is a credible E2E messaging stack. Nation-states may target infrastructure + users. Threat model:
  - Users face metadata collection even with E2E content
  - Server operators face subpoenas / NSLs
  - Code-level attacks (supply chain) possible
  - **Operational security matters**: TLS, MFA, audit, server-side hardening, OMEMO key backup practices
  - Applicable also to: Matrix/Element (batch future), Rocket.Chat, Mattermost (to lesser degree)
- **XMPP DECLINE-BUT-STILL-ALIVE NARRATIVE**: XMPP has lost mindshare to Matrix + Signal + commercial. But mature + federated + E2E-capable + self-hostable. Still a legitimate choice. Recipe framing: "XMPP is not dead; it's mature".
- **ALTERNATIVES WORTH KNOWING:**
  - **XMPP Clients:**
    - **Gajim** — Python/GTK desktop; mature
    - **Dino** — Vala/GTK; modern Linux desktop
    - **Monal** — iOS; good OMEMO
    - **Conversations** (Android; Play + F-Droid) — the gold-standard mobile XMPP client
    - **Swift** — cross-platform desktop
    - **Movim** — PHP social-network-style XMPP client
  - **XMPP Servers** (PAIR with Converse):
    - **Prosody** — Lua; modern; friendly config
    - **ejabberd** — Erlang; legendary reliability
    - **Openfire** — Java; admin GUI
    - **Tigase** — Java; enterprise-focused
    - **MongooseIM** — Erlang; enterprise-focused
  - **Non-XMPP alternatives:**
    - **Matrix** (Synapse / Dendrite / Conduit server + Element / Cinny / FluffyChat clients) — modern decentralized; bigger-than-XMPP mindshare 2020s
    - **Rocket.Chat** — MongoDB-based; Team chat focus
    - **Mattermost** — Go; team chat; freemium
    - **Signal** — E2E only; not federated; not self-hostable
    - **Briar** / **Session** — privacy-first
  - **Choose Converse if:** you want browser-based XMPP + modern UI + OMEMO + MPL-2 + embeddable.
  - **Choose Element if:** you want Matrix ecosystem + broader community + more mindshare.
  - **Choose Gajim/Conversations if:** you want native clients over web.
- **PROJECT HEALTH**: active + MPL-2 + Weblate + OpenCollective + sponsors + Desktop/Tauri wrappers + 10+ years. Mature + healthy.

## Links

- Repo: <https://github.com/conversejs/converse.js>
- Homepage: <https://conversejs.org>
- Docs: <https://conversejs.org/docs/>
- Quickstart: <https://conversejs.org/docs/quickstart/>
- Desktop: <https://github.com/conversejs/converse-desktop>
- Tauri: <https://github.com/conversejs/converse-tauri>
- XMPP.org (protocol): <https://xmpp.org>
- Prosody (server): <https://prosody.im>
- ejabberd (server): <https://www.ejabberd.im>
- Openfire (server): <https://www.igniterealtime.org/projects/openfire/>
- Element (Matrix alt): <https://element.io>
- Gajim (XMPP desktop alt): <https://gajim.org>
- Conversations (Android): <https://conversations.im>
- OpenCollective: <https://opencollective.com/conversejs>
