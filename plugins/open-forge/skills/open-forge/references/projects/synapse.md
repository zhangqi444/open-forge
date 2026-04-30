---
name: Synapse
description: "Reference Matrix homeserver — the canonical AGPL implementation of the Matrix open standard for secure, federated, interoperable real-time communication. Python. Element Server Suite (ESS) is the official deployment path. AGPL-3.0 or commercial (Element)."
---

# Synapse

Synapse is **the reference Matrix homeserver** — the canonical, AGPL-licensed implementation of the **[Matrix protocol](https://matrix.org)** for secure, decentralized, federated real-time communication. Matrix is an open standard (think "IRC + XMPP for the modern era but with E2E encryption + federation + bridges"); Synapse is the most-deployed server that speaks it.

Built + maintained by **Element** (formerly New Vector Ltd, now Element Inc.) — UK/EU commercial entity behind the **Element messenger client** (iOS/Android/Web/Desktop) + Matrix.org Foundation-adjacent. Relicensed from Apache-2.0 to **AGPL-3.0** in late 2023 as part of Element's commercial model shift; **dual-license commercial option** available from Element.

**Important: Element does not provide free support.** Upstream is explicit: "There is no support provided by Element unless you have a subscription." Community support happens in Matrix rooms. For SLAs + enterprise: buy **Element Server Suite (ESS) Pro** or **ESS TI-M** (the German-healthcare-compliant variant).

**ESS editions:**
- **ESS Community** — free; small-to-midscale non-commercial; K8s-based (Helm)
- **ESS Pro** — commercial; professional deployments
- **ESS TI-M** — Germany-specific; TI-Messenger Pro + ePA (healthcare) Gematik-compliance

Use cases: (a) **organizational chat** sovereign + encrypted (b) **federation-enabled community** (rooms across instances) (c) **Element client + Synapse backend** for Slack/Teams alternative (d) **bridges to IRC/XMPP/Discord/Slack/WhatsApp/Signal** for cross-protocol chat (e) **healthcare communication** (ESS TI-M) (f) **government/defense secure comms**.

Features (protocol-level):

- **End-to-end encryption** (Olm + Megolm)
- **Federation** — users on different homeservers can chat in shared rooms
- **Rooms + spaces** (hierarchical)
- **Voice + video** (via Element Call or integrated)
- **File sharing + emoji reactions + threads**
- **Bridges** — IRC, XMPP, Discord, Slack, WhatsApp, Signal, Telegram, Mastodon, SMS/MMS
- **Widgets** — embed external tools (Jitsi, collaborative docs)
- **Client-side SSO** — OIDC/SAML/CAS
- **Verification** (cross-signing, QR codes, emoji)

- Upstream repo: <https://github.com/element-hq/synapse>
- Documentation: <https://element-hq.github.io/synapse/>
- Installation: <https://element-hq.github.io/synapse/latest/setup/installation.html>
- Configuration: <https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html>
- Federation guide: <https://element-hq.github.io/synapse/latest/federate.html>
- Matrix protocol: <https://matrix.org>
- Element Server Suite: <https://element.io/server-suite>
- ESS Community (Helm): <https://github.com/element-hq/ess-helm>
- Element commercial: <https://element.io/pricing>
- Matrix Foundation: <https://matrix.org/foundation/>
- Community support: `#synapse:matrix.org` → <https://matrix.to/#/#synapse:matrix.org>

## Architecture in one minute

- **Python 3.9+** application — asynchronous (twisted / asyncio)
- **PostgreSQL** — strongly recommended for production (SQLite dev-only)
- **Worker processes** for scaling (federation, media, client-reader, etc.) — non-trivial to configure
- **Redis** — required for multi-worker setups
- **Reverse proxy** — nginx / Caddy / Traefik
- **Resource**: modest for a small instance (1-2GB RAM); scales significantly with federation + room count + user count

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Kubernetes         | **ESS Community Helm chart** (official)                        | **Upstream-recommended modern path**                                               |
| Docker             | `matrixdotorg/synapse` or `ghcr.io/element-hq/synapse`                     | Classic single-container                                                                   |
| Debian/Ubuntu      | Official `matrix-synapse-py3` package (Element-maintained APT)                             | Well-documented                                                                            |
| Fedora / Arch      | Community packages                                                                          | Fine                                                                                                  |
| pip                | `pip install matrix-synapse`                                                                              | For custom setups                                                                                                    |

## Inputs to collect

| Input                | Example                                                        | Phase        | Notes                                                                    |
| -------------------- | -------------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Server name          | `example.com` (not `matrix.example.com`)                           | **CRITICAL** | **Immutable** after first user registers; changing = start over                  |
| Delegation           | `.well-known/matrix/server` + `/client`                                    | Federation   | Lets you run Synapse on `matrix.example.com` while server_name = `example.com`             |
| Domain               | `matrix.example.com`                                                                     | Network      | Where Synapse actually listens; delegation points here                                    |
| TURN server          | coturn for voice/video — highly recommended                                                      | VoIP         | Without: voice/video fails behind strict NAT (same reality as MiroTalk batch 80)                                                 |
| PostgreSQL           | PG 12+                                                                                           | DB           | **Don't use SQLite for production**                                                                                       |
| `registration_shared_secret` | long random                                                                                     | Secret       | For admin user creation                                                                                                      |
| `macaroon_secret_key`, `form_secret`, signing keys                         | random                                                                                                        | Secrets      | **Immutable** — signing keys especially; rotating = federation breaks + user keys invalidate                                                                                                           |
| SMTP                 | For password reset + notifications                                                                                                            | Email        | Recommended                                                                                                                                  |
| OIDC / SAML (opt)    | Keycloak / Authentik / Google / GitHub                                                                                                                        | SSO          | Production-grade auth                                                                                                                                                    |

## Install via Docker Compose (minimal)

```yaml
services:
  synapse:
    image: ghcr.io/element-hq/synapse:latest           # **pin version** in prod
    restart: always
    volumes:
      - ./synapse-data:/data
    environment:
      SYNAPSE_SERVER_NAME: example.com
      SYNAPSE_REPORT_STATS: "no"
    depends_on: [db]
    ports: ["8008:8008"]
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: synapse
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: synapse
      POSTGRES_INITDB_ARGS: "--encoding=UTF8 --lc-collate=C --lc-ctype=C"
    volumes: [pg_data:/var/lib/postgresql/data]

volumes:
  pg_data:
```

For first-time config generation:
```sh
docker run -it --rm -v ./synapse-data:/data \
  -e SYNAPSE_SERVER_NAME=example.com -e SYNAPSE_REPORT_STATS=no \
  ghcr.io/element-hq/synapse:latest generate
```
Edit `homeserver.yaml` → set `database:` to Postgres, SMTP, etc.

Production: use **ESS Community Helm** <https://github.com/element-hq/ess-helm>.

## First boot

1. Decide `server_name` — this is **the user identity suffix** (`@alice:example.com`). **Cannot change later.**
2. Generate config, edit `homeserver.yaml` (DB = Postgres, federation = allowed or private, registration = closed)
3. Set up `.well-known/matrix/server` + `/client` on the server-name domain (HTTPS)
4. Start Synapse + verify federation: <https://federationtester.matrix.org/>
5. Create admin: `register_new_matrix_user` (uses registration_shared_secret)
6. Install Element Web or direct users to desktop/mobile Element app
7. Configure TURN server (coturn) for VoIP
8. Set up SMTP for password reset
9. **Disable open registration** unless intentional (Matrix server-name hijacking spam is real)
10. Back up Postgres + signing keys

## Data & config layout

- `/data/homeserver.yaml` — main config
- `/data/<server-name>.signing.key` — **THE most critical file** — identity of the homeserver
- PostgreSQL DB — all rooms, events, users, encryption keys
- `/data/media_store/` — uploaded files
- `.well-known/` on server-name domain — delegation + client config

## Backup

```sh
# DB:
pg_dump -Fc -U synapse synapse > synapse-$(date +%F).dump
# Config + signing key:
sudo tar czf synapse-config-$(date +%F).tgz /data/homeserver.yaml /data/*.signing.key /data/*.log.config
# Media store:
sudo rsync -avR /data/media_store/ /backup/synapse-media/
```

**Signing key is THE identity.** Lose it → your server can no longer prove to other servers that it's the same instance → federation breaks catastrophically. Back up to a SEPARATE encrypted location.

## Upgrade

1. Releases: <https://element-hq.github.io/synapse/latest/upgrade.html>. Active cadence (monthly+).
2. **Read upgrade notes ALWAYS.** Synapse occasionally deprecates features + changes defaults.
3. **Back up DB + signing key FIRST.**
4. Docker: pin version, bump, run.
5. Schema migrations happen automatically; large DBs take time.
6. **Python version requirements drift** — older Synapse was 3.7+; current is 3.9+. Update your base environment accordingly.

## Gotchas

- **AGPL-3.0 relicense (late 2023)** is a big deal. Pre-2023 Synapse was Apache-2.0 — permissive, used widely in commercial products. Element relicensed to AGPL to force competitors hosting Matrix-as-a-service to contribute back OR buy a commercial license. **Self-hosting privately = AGPL compliant.** Commercial SaaS offering Synapse → contact Element. Same consideration applies to third-party clients + bridges (some have not updated). Recurring AGPL class: MiroTalk (batch 80), AnonAddy (79), WriteFreely (74), Papra (81), Fider (82), FreeScout (82), myDrive (82). Synapse is the highest-profile member.
- **"No Element-provided support without subscription"** — upstream is BLUNT. Unlike most AGPL projects, Element will not help you on GitHub issues for support questions. Community Matrix rooms ARE the support channel. Budget accordingly.
- **`server_name` is IMMUTABLE.** Set at first run. Baked into every user ID, every room, every signed event. Changing it = start fresh. Plan your domain strategy CAREFULLY before first user registers. Naming convention: `server_name: example.com` + serve Synapse on `matrix.example.com` via delegation (the standard pattern).
- **Signing key IS the server identity** — federate for years, lose this key → irreversibly orphaned from federation. Back up separately + protect fiercely. Same "crown-jewel secret" pattern as myDrive ENCRYPTION_KEY (82), Nexterm ENCRYPTION_KEY (81), AnonAddy DKIM (79). Synapse signing key is one more in the **critical-secret-as-crown-jewel** family.
- **Federation is the feature AND the operational complexity.** Your server talks to thousands of other Matrix homeservers → you receive copies of events in federated rooms → your DB grows. Joining big rooms like `#matrix:matrix.org` = massive event import. Small home servers easily accumulate 100+ GB DB if joining large rooms. Plan storage + pruning.
- **Media store grows unboundedly.** Federated users upload files into shared rooms → your server fetches + caches them. Without retention policy, disk fills. Configure `media_retention_policy` + run `admin_api` media cleanup.
- **PostgreSQL-only in production.** SQLite works for development; dies under federation load. Migrating SQLite → PG after the fact = painful but documented.
- **Workers for scaling** — Synapse is single-process by default. For 100+ active users, configure worker processes (federation_reader, federation_sender, media_repository, etc.) — NON-TRIVIAL. Helm chart handles this for you; manual is painful.
- **TURN server mandatory for VoIP.** Same reality as MiroTalk (batch 80): direct WebRTC fails through strict NATs. Deploy coturn alongside Synapse or use a managed TURN.
- **Open registration = spam magnet.** Leave `enable_registration: false` except for trusted invitations. Bots create accounts + spam federated rooms.
- **Bridges are heterogenous + their own projects** — mautrix (Signal, WhatsApp, Telegram, Discord, Slack), matrix-appservice-irc, Beeper-family. Each has its own deployment concerns; bridges are SEPARATE daemons talking to Synapse as application-services.
- **Element client vs other clients**: Element is the reference client (iOS/Android/Web/Desktop). Alternatives: FluffyChat, Cinny, Thunderbird-Matrix, Nheko, SchildiChat. Your Synapse serves them all.
- **E2E encryption device verification UX** is historically rough (cross-signing, emoji verification). Better now but still a user-education item.
- **Bot-facing and webhook alternatives**: Matrix has bots + webhook bridges. Less turnkey than Slack but viable.
- **Project health**: Element Inc. — commercial company + Matrix Foundation + large ecosystem + institutional users (French government, German healthcare, UK government — big-deal references). Commercial-tier-funds-upstream at scale (ESS Pro + Pro/TI-M subscriptions). Healthy + sovereign-adoption-strong. Bus-factor-1 not a concern.
- **Alternatives worth knowing:**
  - **Dendrite** — Element's next-gen Matrix homeserver (Go, more scalable, feature-incomplete vs Synapse)
  - **Conduit** — Rust Matrix homeserver; small + fast; feature-subset
  - **Conduwuit** — Conduit fork; active
  - **XMPP (Prosody / ejabberd)** — alternative federated chat standard (older)
  - **Mattermost** / **Rocket.Chat** — centralized team-chat Slack-alternatives (no federation)
  - **Zulip** — threaded-first team chat
  - **Signal** — commercial + E2E + centralized
  - **Choose Synapse if:** you want Matrix + reference implementation + big ecosystem + willing to operate it or pay for ESS.
  - **Choose Dendrite / Conduit if:** you want smaller footprint + early-adopter Matrix.
  - **Choose Mattermost if:** you want team chat without federation complexity.

## Links

- Repo: <https://github.com/element-hq/synapse>
- Docs: <https://element-hq.github.io/synapse/>
- Installation: <https://element-hq.github.io/synapse/latest/setup/installation.html>
- Configuration: <https://element-hq.github.io/synapse/latest/usage/configuration/config_documentation.html>
- Upgrade guide: <https://element-hq.github.io/synapse/latest/upgrade.html>
- ESS Community (Helm): <https://github.com/element-hq/ess-helm>
- ESS Pro: <https://element.io/server-suite>
- Element: <https://element.io>
- Matrix protocol: <https://matrix.org>
- Matrix Foundation: <https://matrix.org/foundation/>
- Federation tester: <https://federationtester.matrix.org/>
- coturn (TURN server): <https://github.com/coturn/coturn>
- Community support (Matrix room): <https://matrix.to/#/#synapse:matrix.org>
- Dendrite (alt): <https://github.com/element-hq/dendrite>
- Conduit (alt): <https://conduit.rs>
- Conduwuit (alt): <https://github.com/girlbossceo/conduwuit>
- Element Call: <https://call.element.io>
- Beeper (commercial Matrix-for-humans): <https://www.beeper.com>
