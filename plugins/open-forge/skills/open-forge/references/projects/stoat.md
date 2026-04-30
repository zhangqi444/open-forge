---
name: Stoat
description: "Self-hostable Discord-alternative chat platform — fork of Revolt. Rust backend (REST + WebSocket + file + push services) + MongoDB + Redis + MinIO. AGPL-3.0. Active fork of Revolt chat."
---

# Stoat

Stoat is **"Discord — open-source + self-hostable"** — a fork of the **Revolt** chat platform, offering a user-first chat experience with Discord-like UX (servers, channels, DMs, roles, emoji, file uploads). Rust-based microservices backend: `delta` (REST API), `bonfire` (WebSocket events), `january` (proxy), `gifbox` (Tenor proxy), `autumn` (files/S3), `crond` + `pushd` (maintenance + notifications). Stoat inherits Revolt's AGPL-3.0 license + architecture.

Built + maintained by **stoatchat org** (Revolt-fork community) + contributors. License: **AGPL-3.0-or-later** (explicitly shown in README crate tables). Active; public hosted service (stoat.chat); MongoDB + Redis + MinIO backing stores; Rust 1.86.0+ MSRV.

Use cases: (a) **replace Discord for communities that want self-host** — gaming, developer communities, hobby groups (b) **Matrix-alternative for Discord-native users** — less-complex than Matrix but self-hostable (c) **University / company chat** — alternatives to Slack/Discord with data-ownership (d) **Revolt-continuity** — if Revolt itself slows, Stoat is an active fork (e) **AGPL-aligned OSS communities** — reject Discord's cloud + TOS + IPO pressure (f) **gaming-community self-host** — need voice+text+role-based access for gaming guild.

Features (inherited from Revolt + Stoat):

- **Servers + channels + DMs**
- **Roles + permissions**
- **Custom emoji + reactions**
- **File uploads** (S3-compatible via `autumn`)
- **URL previews / embeds** (via `january` proxy)
- **Push notifications** (via `pushd`)
- **Voice** (Revolt experimental; Stoat status may differ)
- **Discord-familiar UX**

- Upstream Stoat repo: <https://github.com/stoatchat/stoatchat>
- Developer docs: <https://developers.stoat.chat>
- Revolt (upstream origin): <https://github.com/revoltchat/backend>

## Architecture in one minute

- **Rust 1.86+** microservices — multiple binaries
- **MongoDB 27017** — primary DB
- **Redis 6379** — pub/sub + caching
- **MinIO 14009** — S3-compatible object storage (files, avatars, attachments)
- **Resource**: moderate-high — 1-2GB RAM + storage for files
- Multiple containers + reverse-proxy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | **Upstream + Revolt deployment recipes**                        | **Primary**                                                                        |
| Kubernetes         | Helm chart (Revolt ecosystem)                                                    | Alternative                                                                                   |
| Bare-metal Rust    | Build + deploy each microservice                                                                    | DIY                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `chat.example.com`                                          | URL          | TLS required                                                                                    |
| MongoDB              | Hosted + persistent                                         | DB           | Backup strategy                                                                                    |
| Redis                | Hosted                                                      | Cache        |                                                                                    |
| MinIO / S3           | File storage                                                | Storage      |                                                                                    |
| `JWT_SECRET`         | Auth                                                        | **CRITICAL** | **IMMUTABLE**                                                                                    |
| SMTP                 | For email verification + notifications                                                                                  | Email        |                                                                                                            |
| VAPID keys           | Web push                                                                                                            | Optional     |                                                                                                            |
| Captcha (hCaptcha)   | Sign-up protection                                                                                                    | Security     | Anti-spam                                                                                                                            |

## Install

Follow upstream docker-compose deployment at <https://developers.stoat.chat>. Typical shape:

```yaml
services:
  database:
    image: mongo:8     # **pin**
    volumes: [mongodb-data:/data/db]
    restart: always
  redis:
    image: redis:7-alpine
    restart: always
  minio:
    image: minio/minio     # **pin version**
    command: server /data
    restart: always
  delta:
    image: ghcr.io/stoatchat/delta:latest     # **pin**
    # env: MONGODB=..., REDIS=..., JWT_SECRET=...
  bonfire:
    image: ghcr.io/stoatchat/bonfire:latest
  autumn:
    image: ghcr.io/stoatchat/autumn:latest
  # january, gifbox, crond, pushd, web clients...
```

## First boot

1. Start stack; verify all microservices healthy
2. Browse client UI; register first user (admin)
3. Configure captcha + SMTP + VAPID
4. Create first server + channel
5. Invite members (create invite link)
6. Test file upload + URL preview
7. Put all endpoints behind TLS reverse proxy
8. Back up MongoDB + MinIO + Redis

## Data & config layout

- MongoDB — users, messages, servers, channels
- Redis — session state, pub/sub
- MinIO — files, avatars, attachments (can be TBs)
- Config env-per-microservice

## Backup

```sh
docker compose exec database mongodump --archive=/tmp/mongo.archive
docker compose exec database cat /tmp/mongo.archive > stoat-mongo-$(date +%F).archive
# MinIO: mc mirror or S3 lifecycle rules
```

## Upgrade

1. Releases: <https://github.com/stoatchat/stoatchat/releases>. Active fork.
2. Docker: pull all microservice images + rolling-restart in dependency order.
3. Multi-service upgrade = more fragile than monolith; read release notes carefully.
4. **Back up all 3 datastores BEFORE upgrade.**

## Gotchas

- **REVOLT-FORK LINEAGE**:
  - Stoat forked from Revolt (revoltchat)
  - Upstream Revolt still exists; Stoat is community continuation / evolution
  - **Recipe convention: "fork-after-upstream-slowdown" pattern** — similar to Redlib-from-Libreddit (95) + YDL-M-from-youtube-dl (97)
  - **5th tool in forking-after-slowdown class** (Ergo=3rd, Redlib=4th, YDL-M-via-forks=5th, Stoat=6th maybe) — actually need to recount family
  - **NEW sub-category: "multi-binary-microservice-fork"** — Stoat vs monolith forks
- **AGPL-3.0 = STRICT NETWORK-SERVICE-DISCLOSURE**:
  - Every user interacting with your hosted Stoat = AGPL-triggered
  - **Must provide source code** (including any modifications) to users on request
  - Recipe convention reinforced: "AGPL-network-service-disclosure" (Worklenz 100 prior)
  - **Stoat inherits Revolt's AGPL — any Stoat-based hosted service MUST disclose modifications**
- **CHAT-PLATFORM = HUB-OF-CREDENTIALS TIER 2 WITH HIGH MESSAGE-DENSITY**:
  - All user messages (DMs, server chat, files)
  - Private server content (potentially sensitive — confidential project discussions, personal info)
  - File attachments (potentially all sorts of content)
  - Server owner = god-mode over server
  - Admin = god-mode over instance
  - **61st tool in hub-of-credentials family — Tier 2 (possibly Tier 1 if hosting public server)**
- **HOSTED-PUBLIC = ABUSE-CONDUIT RISK**:
  - Open signup → spam + bots + CSAM risk
  - Server-discovery features amplify abuse potential
  - **Overlaps with public-UGC-host-abuse-conduit-risk meta-family** (Slash/Zipline/Opengist/OxiCloud 100): chat is distinct but shares risks
  - **Recipe convention: "chat-platform-abuse-risk" sub-category**
  - Mitigation: captcha (hCaptcha), phone verification, server-owner reporting tools, CSAM scanning (PhotoDNA), rate-limits
- **JWT_SECRET IMMUTABILITY**: **41st tool in immutability-of-secrets family.** (41-tool count since 40 was Flatnotes)
- **MICROSERVICE COMPLEXITY**:
  - 7+ microservices is a lot for homelab
  - Failure modes: 1 service down = part of system broken (DMs work, voice doesn't, or file-upload fails, etc.)
  - Debugging = multi-container logs + Redis inspection + Mongo queries
  - **Recipe convention: "microservice-complexity-tax"** — compared to monolithic tools, operational burden is higher
- **MULTI-DATASTORE = 3x BACKUP SURFACE**:
  - MongoDB + Redis (ephemeral mostly, but session state) + MinIO file blobs
  - Consistent backup across 3 stores = harder than SQL single-DB
  - Snapshot moment = pick one: consistent MongoDB + matching MinIO? Non-trivial
- **MODERATION TOOLS**:
  - Admin needs: ban, delete, report-queue, audit-log
  - Verify these features available + usable
  - **Chat platforms without good moderation = abuse magnets**
- **VOICE FEATURE STATUS**:
  - Revolt's voice was experimental
  - Stoat's voice status may differ; check README/changelog
  - If needed, consider Mumble / Jitsi / Element Call as separate voice stack
- **INSTITUTIONAL-STEWARDSHIP**: stoatchat org + community fork of Revolt. **47th tool in institutional-stewardship — community-fork-of-existing-OSS sub-tier** (**NEW sub-tier**) — distinct from rebrand-preservation (tools that rebrand) and forking-after-slowdown (tools that fork abandoned projects).
  - **NEW sub-tier: "community-fork-of-active-project"** — fork for different direction, not abandonment
  - **1st tool in this sub-tier**
- **TRANSPARENT-MAINTENANCE**: active + docs site + developers.stoat.chat + crates published + Rust-ecosystem. **54th tool in transparent-maintenance family.**
- **CHAT-PLATFORM CATEGORY**:
  - **Matrix (Synapse + Dendrite + Conduit)** — federated; mature; complex
  - **Element (Matrix client)** — most-used Matrix client
  - **Rocket.Chat** — Node.js; commercial + OSS; feature-rich
  - **Mattermost** — Go; commercial tier; Slack-alike
  - **Zulip** — Python; threaded; academic roots
  - **Discord** (commercial) — most-polished; closed
  - **Slack** (commercial) — business-focused
  - **Revolt** (Stoat upstream) — Rust; Discord-like; AGPL
  - **Stoat** — Revolt fork; community continuation
  - **Spacebar** (formerly Fosscord) — another Discord-protocol clone
- **ALTERNATIVES WORTH KNOWING:**
  - **Matrix + Element** — if federation + E2E-encryption matters
  - **Mattermost** — if you want commercial-supportable option
  - **Rocket.Chat** — if feature-richness matters + Node ecosystem
  - **Zulip** — if threaded-conversations matter
  - **Revolt** — upstream origin; might be better choice if still active
  - **Choose Stoat if:** you want Revolt-UX + active-fork-community + AGPL + Rust.
  - **Choose Matrix if:** federation + E2E + protocol-openness matter.
  - **Choose Mattermost if:** commercial-grade + Slack-familiar.
- **PROJECT HEALTH**: active + Rust + microservice-professional + crates-published. Fork-community-fragility caveat: forks can diverge/merge/die; monitor upstream Revolt + Stoat dynamics.

## Links

- Repo: <https://github.com/stoatchat/stoatchat>
- Developer docs: <https://developers.stoat.chat>
- Revolt (upstream): <https://github.com/revoltchat/backend>
- Matrix (alt federated): <https://matrix.org>
- Element (Matrix client): <https://element.io>
- Mattermost (alt commercial): <https://mattermost.com>
- Rocket.Chat (alt): <https://rocket.chat>
- Zulip (alt threaded): <https://zulip.com>
- Spacebar (alt Discord-clone): <https://spacebar.chat>
- Discord (commercial original): <https://discord.com>
