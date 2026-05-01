---
name: La Suite Meet
description: "HD video calls, screen sharing, chat — directly from browser. Powered by LiveKit. French-government-backed (suitenumerique). Large-meeting (100+). Recording + transcription (beta). Telephony. suitenumerique org. Matrix chat."
---

# La Suite Meet

La Suite Meet is **"Zoom/Jitsi — but LiveKit-powered + French-government-backed + part of La Suite numerique (sovereign digital workspace)"** — browser-based video conferencing for large meetings (100+), with screen sharing, chat, recording, transcription (beta), and telephony integration.

Built + maintained by **suitenumerique** org (French government DINUM / La Suite numerique). Part of the French sovereign digital-workspace suite. Deployed at visio.numerique.gouv.fr. Matrix chat.

Use cases: (a) **government-agency video conferencing** (b) **Zoom alternative with sovereignty** (c) **large-meeting (100+) video** (d) **browser-native (no install)** (e) **recorded + transcribed meetings** (f) **screen-share + chat + telephony** (g) **integrated with La Suite numerique** (h) **community + OSS-minded orgs**.

Features (per README):

- **LiveKit-powered**
- **Stable in large meetings** (+100 participants)
- **Multiple screen-sharing streams**
- **Non-persistent, secure chat**
- **E2E encryption** (coming soon)
- **Meeting recording**
- **Meeting transcription + summary** (beta)
- **Telephony integration**
- **Robust auth + access control**
- **Customizable frontend**

- Upstream repo: <https://github.com/suitenumerique/meet>
- Production: <https://visio.numerique.gouv.fr>
- Matrix: <https://matrix.to/#/#meet-official:matrix.org>

## Architecture in one minute

- **LiveKit** WebRTC media server
- **Backend**: likely Django or Node (suitenumerique-pattern)
- **PostgreSQL** data
- **coTURN** usually for NAT
- **Resource**: LiveKit can use significant CPU for transcoding; mostly media-relay at scale
- **Port**: web + WebRTC (UDP)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker Compose** | Reference deploy                                                | **Primary**                                                                        |
| **K8s / Helm**     | For scale                                                                                                              | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `meet.example.com`                                          | URL          | **TLS MANDATORY — WebRTC requires HTTPS**                                                                                    |
| LiveKit URL          | LiveKit media server endpoint                               | Config       |                                                                                    |
| LiveKit API key/sec  | Auth to LiveKit                                             | Secret       |                                                                                    |
| TURN server          | If behind NAT                                               | Network      | coTURN recommended                                                                                    |
| UDP port range       | Open for WebRTC                                             | Firewall     |                                                                                    |
| OIDC provider (opt)  | For SSO                                                     | Auth         |                                                                                    |

## Install via Docker

See <https://github.com/suitenumerique/meet/tree/main/docs>. Typical:
```yaml
services:
  livekit:
    image: livekit/livekit-server:v1.X        # **pin**
    ports: ["7880:7880", "7881:7881"]
    # UDP range for media
  meet:
    image: suitenumerique/meet:latest        # **pin**
  postgres:
    image: postgres:15
```

## First boot

1. Deploy LiveKit + coTURN + Meet backend
2. Configure auth (OIDC recommended)
3. Test audio + video + screen-share
4. Test large meeting (>50 participants)
5. Configure recording (if enabled) — data-path + retention
6. Put behind TLS
7. Back up PostgreSQL

## Data & config layout

- PostgreSQL: users, meeting metadata, recordings-metadata
- Object-storage (S3/MinIO): recording blobs (if recording enabled)

## Backup

```sh
pg_dump meet > meet-$(date +%F).sql
# Plus S3/MinIO recordings bucket
```

## Upgrade

1. Releases: <https://github.com/suitenumerique/meet/releases>
2. LiveKit version compatibility
3. Changelog: <https://github.com/suitenumerique/meet/blob/main/CHANGELOG.md>

## Gotchas

- **158th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — LIVE-CALL + RECORDING + TRANSCRIPT**:
  - Holds: live call media (WebRTC), recordings, transcripts, participant PII, call metadata
  - Meeting recordings = **extremely sensitive** (whole meeting contents)
  - Transcripts = searchable-text-of-spoken-content
  - **158th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **Self-hosted-video-conf + chat-with-call-recording: 2 tools** (NC Talk+Meet) 🎯 **2-TOOL MILESTONE** — matured sub-category
  - **CROWN-JEWEL Tier 1: 52 tools / 48 sub-categories** (sub-cat not new — matured)
- **E2E-ENCRYPTION-COMING-SOON**:
  - Explicit "coming soon" in features list
  - Currently NOT E2E — LiveKit can decode media
  - **Recipe convention: "E2E-encryption-roadmap-not-shipped callout"**
  - **NEW recipe convention** (Meet 1st formally)
- **CALL-RECORDING-CONSENT-LAW**:
  - Recording requires consent in many jurisdictions
  - **Recipe convention: "call-recording-consent-law-discipline"** — reinforces NC Talk (116)
- **TRANSCRIPTION-DATA-PROCESSING**:
  - Transcripts use STT service
  - Audio streams sent to STT = data-processor relationship
  - **Recipe convention: "transcription-STT-data-processor-agreement callout"**
  - **NEW recipe convention** (Meet 1st formally)
- **GOVERNMENT-BACKED-OSS**:
  - French DINUM / La Suite numerique
  - Long-term stewardship expected
  - **Government-backed-OSS: 1 tool** 🎯 **NEW FAMILY** (Meet; distinct from private-sector OSS)
- **SOVEREIGNTY-POSITIONING**:
  - Explicitly positioned as sovereign alternative
  - **Recipe convention: "digital-sovereignty-positioning positive-signal"**
  - **NEW positive-signal convention** (Meet 1st formally)
- **LIVEKIT-DEPENDENCY**:
  - Media stack depends on LiveKit (OSS + commercial)
  - Version-compat matters
  - **Recipe convention: "upstream-media-server-dependency neutral-signal"**
  - **NEW neutral-signal convention** (Meet 1st formally)
- **LARGE-MEETING-100-PLUS**:
  - Explicitly optimized for 100+ participants
  - Scale-tested
  - **Recipe convention: "scale-tested-large-meetings positive-signal"**
  - **NEW positive-signal convention** (Meet 1st formally)
- **TELEPHONY-INTEGRATION**:
  - PSTN dial-in support
  - **Recipe convention: "PSTN-telephony-integration positive-signal"**
  - **NEW positive-signal convention** (Meet 1st formally)
- **MATRIX-CHAT-COMMUNITY**:
  - **Matrix-chat-community: 2 tools** (Ferron+Meet) 🎯 **2-TOOL MILESTONE**
- **INSTITUTIONAL-STEWARDSHIP**: suitenumerique-French-gov + production-deploy-visio.numerique.gouv.fr + Matrix + CHANGELOG + roadmap-board. **144th tool — government-ministry-OSS-stewardship sub-tier** (NEW-soft; distinct from Pelican's commercial-consultancy).
- **TRANSPARENT-MAINTENANCE**: active + CHANGELOG + roadmap-board + Matrix + production. **150th tool in transparent-maintenance family** 🎯 **150-TOOL TRANSPARENT-MAINTENANCE MILESTONE at Meet**.
- **VIDEO-CONF-CATEGORY:**
  - **Meet (La Suite)** — gov-backed; LiveKit-powered; large-meeting
  - **Jitsi Meet** — dominant OSS; WebRTC
  - **BigBlueButton** — edu-focused; large-class
  - **NC Talk** — Nextcloud ecosystem
  - **Element Call** — Matrix-integrated
- **ALTERNATIVES WORTH KNOWING:**
  - **Jitsi Meet** — if you want dominant + mature
  - **BigBlueButton** — if you want edu-classroom features
  - **NC Talk** — if you're on Nextcloud
  - **Choose Meet if:** you want LiveKit + large-meeting + gov-grade-stewardship.
- **PROJECT HEALTH**: active + gov-backed + production-deployed + roadmap-public + Matrix. Very strong stewardship.

## Links

- Repo: <https://github.com/suitenumerique/meet>
- Production: <https://visio.numerique.gouv.fr>
- LiveKit: <https://livekit.io>
- Jitsi (alt): <https://github.com/jitsi/jitsi-meet>
- BigBlueButton (alt): <https://github.com/bigbluebutton/bigbluebutton>
