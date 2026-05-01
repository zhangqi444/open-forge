---
name: Movim
description: "Federated blogging + chat platform — web frontend for XMPP protocol. PHP. Federates with all XMPP servers (Prosody/Ejabberd). Podman-quick-test. movim org. movim.eu."
---

# Movim

Movim is **"Mastodon-like + chat — but over XMPP, so federating with the entire XMPP ecosystem"** — a federated blogging + chat platform that acts as a web frontend for XMPP. Works with Prosody, Ejabberd, and every other XMPP server. Gives XMPP a modern web UX.

Built + maintained by **movim** org. movim.eu website. Active CI. XMPP-community tool.

Use cases: (a) **modern XMPP web UX** (b) **federated blogging** (c) **federated chat** (d) **already-on-XMPP organizations** (e) **decentralized social network without Mastodon** (f) **cross-federation chat** (XMPP users on any server) (g) **lightweight Mastodon alternative** (h) **schools/companies already using XMPP for IM**.

Features (per README):

- **Federated blogging** (XMPP PubSub)
- **Federated chat**
- **Web frontend** for XMPP
- **Podman quick-test**
- **Self-hostable**

- Upstream repo: <https://github.com/movim/movim>
- Website: <https://movim.eu>
- Wiki: <https://github.com/movim/movim/wiki>
- INSTALL.md: <https://github.com/movim/movim/blob/master/INSTALL.md>

## Architecture in one minute

- **PHP** + PostgreSQL
- **XMPP server required** (Prosody or Ejabberd)
- **WebSocket proxy** for chat
- **Resource**: moderate
- **Port**: 8443 (quick-test); typically behind reverse proxy

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Podman Compose** | **Quick-test only**                                             | Test only (caches disabled)                                                                                    |
| **Manual**         | PHP + Postgres + XMPP server                                                                                           | **Primary for production** — see INSTALL.md                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `movim.example.com`                                         | URL          | TLS                                                                                    |
| XMPP server          | Prosody/Ejabberd                                            | **CRITICAL** | Prerequisite                                                                                    |
| PostgreSQL           | Data                                                        | DB           |                                                                                    |
| XMPP BOSH/WebSocket  | Endpoints                                                   | Integration  |                                                                                    |
| Domain DNS           | For federation                                              | Network      | SRV records                                                                                    |

## Install (production)

See <https://github.com/movim/movim/blob/master/INSTALL.md>. Steps roughly:
1. Install XMPP server (Prosody recommended)
2. Install PHP 8+ + Postgres
3. Clone movim
4. Configure config file (DB + XMPP endpoints)
5. Run migrations
6. Put nginx in front
7. Configure systemd

## Quick-test (Podman)

```sh
git clone https://github.com/movim/movim.git
cd movim
podman-compose up
# Visit https://127.0.0.1:8443/
```

## First boot

1. Create admin
2. Test federation (post to XMPP node)
3. Test chat (add XMPP contact)
4. Configure SRV records for federation
5. Put behind TLS
6. Back up DB + XMPP storage

## Data & config layout

- PostgreSQL — Movim data
- XMPP server data — separate (Prosody/Ejabberd files)

## Backup

```sh
pg_dump movim > movim-$(date +%F).sql
# Plus your XMPP server's data
```

## Upgrade

1. Releases: <https://github.com/movim/movim/releases>
2. Read release notes
3. DB migrations

## Gotchas

- **153rd HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — FEDERATED SOCIAL + CHAT**:
  - Holds: all your posts, chat history, XMPP creds per user, federation-pulled-content
  - Federated = data leaves to other servers
  - **153rd tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "federated-social-XMPP-frontend"** (1st — Movim)
  - **CROWN-JEWEL Tier 1: 49 tools / 46 sub-categories**
- **XMPP-FEDERATION-DATA-EXPOSURE**:
  - Federated posts leave your server
  - Once federated, not recoverable
  - **Recipe convention: "federated-protocol-cross-org-data-exposure"** — reinforces NC Talk (116)
- **REQUIRES XMPP-SERVER-EXPERTISE**:
  - Must configure Prosody/Ejabberd
  - SRV records, certs, c2s/s2s ports
  - **Recipe convention: "XMPP-server-prerequisite-expertise-required callout"**
  - **NEW recipe convention** (Movim 1st formally)
- **PODMAN-AS-DOCKER-ALTERNATIVE**:
  - Quick-test via podman-compose
  - Docker-alternative community
  - **Recipe convention: "Podman-alternative-container-runtime positive-signal"**
  - **NEW positive-signal convention** (Movim 1st formally)
  - **Podman-support: 1 tool** 🎯 **NEW FAMILY** (Movim)
- **QUICK-TEST-NOT-PRODUCTION**:
  - Explicit "test only; caches disabled"
  - Responsible setup-guidance
  - **Recipe convention: "test-only-setup-explicit-warning positive-signal"**
  - **NEW positive-signal convention** (Movim 1st formally)
- **XMPP-ECOSYSTEM-COMPATIBILITY**:
  - Works with ANY XMPP server
  - **Recipe convention: "standard-protocol-any-server-compat positive-signal"**
  - **NEW positive-signal convention** (Movim 1st formally)
- **DECADE-PLUS-OSS**:
  - Movim is long-running (~2010+)
  - **Decade-plus-OSS: 8 tools** (+Movim) 🎯 **8-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: movim org + website + wiki + active + Podman-support + decade-plus + INSTALL.md. **139th tool — decade-plus-XMPP-org sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + website + wiki + INSTALL-doc + Podman-quick-test. **145th tool in transparent-maintenance family.**
- **FEDERATED-SOCIAL-CATEGORY:**
  - **Movim** — XMPP-based; blog + chat
  - **Mastodon** — ActivityPub; microblog
  - **Pleroma/Akkoma** — ActivityPub; lighter
  - **Friendica** — polyglot (ActivityPub, Diaspora, OStatus)
  - **Diaspora** — older; D* protocol
- **ALTERNATIVES WORTH KNOWING:**
  - **Mastodon** — if you want ActivityPub + dominant
  - **Friendica** — if you want multi-protocol
  - **Choose Movim if:** you're already on XMPP.
- **PROJECT HEALTH**: active + decade-plus + website + wiki + CI. Strong within XMPP niche.

## Links

- Repo: <https://github.com/movim/movim>
- Website: <https://movim.eu>
- Prosody (XMPP server): <https://prosody.im>
- Ejabberd (XMPP server): <https://www.ejabberd.im>
- Mastodon (alt): <https://github.com/mastodon/mastodon>
