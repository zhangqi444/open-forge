---
name: Nextcloud Talk
description: "Chat, video, and audio calls for Nextcloud. Part of Nextcloud ecosystem. Federated chats across Nextcloud servers; screen-sharing; Matterbridge sync; end-to-end encryption for private calls. Nextcloud GmbH. AGPL-3.0. REUSE-compliant."
---

# Nextcloud Talk

Nextcloud Talk (repo slug: **spreed**) is **"WhatsApp + Zoom — but inside Nextcloud + federated across Nextcloud instances"** — the video/audio/chat app integrated into Nextcloud. Private/group/public/password-protected calls. **Federated chats** across Nextcloud servers. Screen-sharing. Integrates with Files, Calendar, Contacts, Deck, Maps, etc. **Matterbridge** integration syncs to Slack, Discord, IRC, Telegram, etc.

**NOT a standalone app** — requires Nextcloud server. Add-on to `nextcloud/server`.

Built + maintained by **Nextcloud GmbH**. License: **AGPL-3.0**. **REUSE-compliant** (machine-readable licensing). Mature (decade+). Large community.

Use cases: (a) **Zoom/Teams replacement inside Nextcloud** (b) **federated-chat across companies' Nextclouds** (c) **internal-team video** (d) **GDPR-friendly video-conferencing** (e) **self-hosted replacement for WhatsApp** (f) **classroom/education video** (g) **integrated messaging with Files/Calendar/Deck** (h) **Matterbridge hub** to all other chats.

Features (per README):

- **💬 Chat** — with file upload/share + mentions
- **👥 Calls** — private, group, public, password-protected
- **🌐 Federated chats** — cross-server
- **💻 Screen sharing**
- **🚀 Nextcloud integration** — Files, Calendar, Contacts, Dashboard, Deck, Maps, etc.
- **🌉 Matterbridge** — sync to Slack/Discord/IRC/Telegram

- Upstream repo: <https://github.com/nextcloud/spreed>
- Docs: <https://nextcloud-talk.readthedocs.io/en/latest/>
- User docs: <https://docs.nextcloud.com/server/latest/user_manual/en/talk/>

## Architecture in one minute

- **PHP** (Nextcloud app)
- **JavaScript/Vue** frontend
- **HPB (High-Performance Backend)** optional for large-scale signaling (written in Go)
- **TURN/STUN** server required for NAT traversal (coTURN usually)
- **Resource**: adds ~100-300MB to Nextcloud base
- **Deployment**: as Nextcloud app via Apps menu OR bundled

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Nextcloud App**  | **Install via Apps menu in NC admin**                           | **Primary**                                                                        |
| **HPB sidecar**    | Go-based signaling (for large groups/calls)                                                                            | Optional                                                                                   |
| **coTURN**         | STUN/TURN for NAT                                                                                                      | Recommended                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Existing Nextcloud   | Required                                                    | Prereq       |                                                                                    |
| coTURN server        | For NAT traversal                                           | Network      | Strongly recommended                                                                                    |
| HPB server (opt)     | If >10 users in a call                                      | Scale        |                                                                                    |
| TLS                  | **Mandatory** (WebRTC requires HTTPS)                       | TLS          |                                                                                    |

## Install

**As Nextcloud app:**
1. Nextcloud Admin → Apps → Social & communication
2. Install "Talk"
3. Configure coTURN in Talk admin settings
4. Test call with second user

**HPB (for scale):**
See <https://github.com/strukturag/nextcloud-spreed-signaling>

## First boot

1. Install Talk app in Nextcloud
2. Configure coTURN:
   ```
   docker run -d -p 3478:3478 -p 3478:3478/udp --name coturn \
     coturn/coturn:latest -n --listening-port=3478 --external-ip=<YOUR_IP>
   ```
3. In Talk admin, point at coTURN
4. Create test conversation
5. Test audio, video, screen-share
6. For scale, deploy HPB

## Data & config layout

- Nextcloud's data dir holds chat content
- Nextcloud's DB holds conversation metadata
- Coturn has no persistent state

## Backup

Part of your **Nextcloud backup** — Talk data is inside NC data dir + DB.

## Upgrade

1. Nextcloud Apps → Updates
2. Version-compatibility with NC version
3. Breaking changes noted in release notes

## Gotchas

- **136th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — CHAT + VIDEO + FILES**:
  - Part of Nextcloud — which is already a credential-hub
  - Adds: audio recordings, video recordings, screen-shared content, call logs
  - Federated chats = cross-org data exchange
  - **136th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **NEW CROWN-JEWEL Tier 1 sub-category: "self-hosted-video-conf + chat-with-call-recording"** (1st — NC Talk; distinct from standalone chat — has WebRTC + recording)
  - **CROWN-JEWEL Tier 1: 40 tools / 37 sub-categories** 🎯 **40-TOOL MILESTONE in CROWN-JEWEL Tier 1**
- **WEBRTC-REQUIRES-HTTPS-ALWAYS**:
  - Browsers block WebRTC over plain HTTP
  - **Recipe convention: "WebRTC-HTTPS-mandatory callout"**
  - **NEW recipe convention** (NC Talk 1st formally)
- **TURN/STUN-SERVER-REQUIRED-FOR-NAT**:
  - Most home users behind NAT — without TURN, calls fail
  - coTURN is the standard
  - **Recipe convention: "coTURN-required-for-WebRTC-NAT callout"**
  - **NEW recipe convention** (NC Talk 1st formally)
- **HPB-REQUIRED-FOR-SCALE**:
  - Built-in signaling scales to ~10 users
  - Beyond that, need HPB (Go) sidecar
  - **Recipe convention: "scale-threshold-sidecar-discipline callout"**
  - **NEW recipe convention** (NC Talk 1st formally)
- **FEDERATED-CHATS-CROSS-ORG-DATA-FLOW**:
  - Talk with users on OTHER Nextcloud servers
  - Data leaves your server
  - Compliance implication
  - **Recipe convention: "federated-protocol-cross-org-data-exposure callout"**
  - **NEW recipe convention** (NC Talk 1st formally)
- **MATTERBRIDGE-MULTIPLIES-BRIDGE-SURFACE**:
  - Bridges to Slack/Discord/IRC/Telegram etc.
  - Each bridge = another credential to manage
  - Each bridge = another potential leak-point
  - **Recipe convention: "Matterbridge-multiplier-credential-discipline callout"**
  - **NEW recipe convention** (NC Talk 1st formally)
- **REUSE-COMPLIANT**:
  - Machine-readable copyright + license info (SPDX)
  - Rare-to-find
  - **Recipe convention: "REUSE-compliant-SPDX-machine-readable positive-signal"**
  - **NEW positive-signal convention** (NC Talk 1st formally)
- **CALL-RECORDING-LEGAL-EXPOSURE**:
  - Recording calls has jurisdiction-specific consent law
  - **Recipe convention: "call-recording-consent-law-discipline callout"**
  - **NEW recipe convention** (NC Talk 1st formally)
- **ECOSYSTEM-TIGHTLY-COUPLED**:
  - Not standalone — depends on Nextcloud
  - **Ecosystem-dependent-subsystem: 1 tool** (NC Talk) 🎯 **NEW family**
- **INSTITUTIONAL-STEWARDSHIP**: Nextcloud GmbH + decade+ + readthedocs + REUSE + AGPL-3 + large community + milestones-published. **122nd tool — corporate-backed-ecosystem sub-tier**.
- **TRANSPARENT-MAINTENANCE**: Nextcloud's decade+ process + readthedocs + REUSE + milestones + issue-tracker + active + multiple-repos (spreed + signaling + apps). **128th tool in transparent-maintenance family.**
- **Decade-plus-OSS: 5 tools** (+NC Talk) 🎯 **5-TOOL MILESTONE** (Nextcloud ecosystem started 2010 as ownCloud fork)
- **VIDEO-CONF-CATEGORY:**
  - **NC Talk** — integrated with Nextcloud; federated
  - **Jitsi Meet** — standalone; mature; Prosody/XMPP
  - **BigBlueButton** — education-focused; heavier
  - **LiveKit + Meet** — WebRTC toolkit
  - **Element + Element Call** — Matrix-based
- **ALTERNATIVES WORTH KNOWING:**
  - **Jitsi Meet** — if you want standalone + no-Nextcloud
  - **BigBlueButton** — if you want education + whiteboards
  - **Element Call** — if you already use Matrix
  - **Choose NC Talk if:** you're already on Nextcloud + want integrated chat/video.
- **PROJECT HEALTH**: mature + corporate-backed + decade+ + AGPL + REUSE + milestones. Reference-grade ecosystem-app.

## Links

- Repo: <https://github.com/nextcloud/spreed>
- Docs: <https://nextcloud-talk.readthedocs.io>
- Jitsi (alt): <https://github.com/jitsi/jitsi-meet>
- BigBlueButton (alt): <https://github.com/bigbluebutton/bigbluebutton>
- HPB: <https://github.com/strukturag/nextcloud-spreed-signaling>
