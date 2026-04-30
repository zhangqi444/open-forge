---
name: Fluxer
description: "Free + open-source Discord-like instant messaging and VoIP platform. Text/voice/video channels, communities, DMs. Currently primarily run as a hosted service at fluxer.app (~125k users); upstream acknowledges self-hosting is NOT YET READY. AGPL-3.0."
---

# Fluxer

Fluxer is a free and open-source **Discord-alternative** — instant messaging, voice/video chat, community servers, DMs, roles/permissions, file sharing — built for friends, groups, and communities. It's been operating as a **hosted service** at <https://fluxer.app> with ~125,000 users as of the current refactor.

**⚠️ READ BEFORE DEPLOYING** (paraphrased from upstream, verbatim-in-spirit):

> "Holy smokes, what a ride. Fluxer is taking off much earlier than I'd expected. I know it's hard to resist, but please **wait a little longer before you dive deep into the current codebase or try to set up self-hosting**. I'm aware the current stack isn't very lightweight. I'm working on making self-hosting as straightforward as possible. Self-hosted deployments won't include any traces of Plutonium, and nothing is paywalled."

Current state (as of the recipe writing):

- **Hosted service**: stable, 125k users, production-grade at <https://fluxer.app>
- **Self-hosting**: **NOT recommended yet** — upstream is mid-refactor; docs + simplified deployment are "coming soon"
- **License**: AGPL-3.0 (source open, network-use counts)
- **Development**: driven by founder + 2 full-time employees; moving fast; contracting community contributors soon

If you want a self-hosted Discord alternative **today**, use one of:

- **Revolt** (also Discord-like, OSS, more mature self-hosting)
- **Matrix + Element** (federated, biggest OSS ecosystem)
- **Rocket.Chat** (mature, open-core)
- **Mattermost** (Slack-alternative; teams-focused)

Come back to Fluxer when upstream announces self-hosting readiness (follow <https://blog.fluxer.app>).

Features (on the hosted service; self-host will include all, not paywalled):

- **Text channels** per community + DMs + group DMs
- **Voice + video** channels (WebRTC)
- **Communities + channels + categories**
- **Roles + permissions**
- **File sharing + inline previews**
- **Reactions, replies, threads**
- **Rich embeds + bots** (API coming with self-hosting)
- **Mobile + desktop apps** (web + native)

- Upstream repo: <https://github.com/fluxerapp/fluxer>
- Hosted service: <https://fluxer.app>
- Blog: <https://blog.fluxer.app>
- Launch post: <https://blog.fluxer.app/how-i-built-fluxer-a-discord-like-chat-app/>
- Roadmap: <https://blog.fluxer.app/roadmap-2026/>
- Donations: <https://fluxer.app/donate>
- Docs: <https://docs.fluxer.app> (under construction)

## Architecture (as advertised)

- **TypeScript** across the stack (Node.js + TypeScript per repo metadata)
- **WebRTC** for voice/video
- **Postgres** + **Redis** likely (not explicitly confirmed in public README)
- **"Not very lightweight"** per upstream — the current stack is production-tuned for their hosted service, not simplicity-first
- **Refactor in progress** — branch `refactor` (default) — will simplify self-hosting

## Compatible install methods (current state)

| Infra         | Runtime                                              | Notes                                                                              |
| ------------- | ---------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Hosted        | Sign up at <https://fluxer.app>                          | **Recommended today** — production-ready                                              |
| Self-host     | Source available, but **NOT yet straightforward**         | Upstream: "wait a little longer before you dive deep into self-hosting"                    |
| Future        | Simplified Docker Compose                                    | Planned; timeline depends on refactor completion                                                |

## When self-hosting becomes feasible

Expected inputs (based on similar chat platforms):

| Input             | Expected example                | Notes                                                     |
| ----------------- | ------------------------------- | --------------------------------------------------------- |
| Domain            | `chat.example.com`                | For web + API                                                 |
| TLS               | Let's Encrypt                      | Mandatory — WebRTC + secure cookies                               |
| DB                | Postgres                             | Per likely architecture                                            |
| Redis             | localhost                              | Queue + cache + real-time pub/sub                                     |
| TURN/STUN         | coturn                                   | For users behind symmetric NAT (voice/video)                              |
| Object storage    | S3-compatible                                | For file uploads                                                         |
| SMTP              | host + creds                                    | For email verification + password reset                                           |
| Admin             | First-run wizard                                    | Config community + tiers                                                                |

## Install (CURRENT STATE)

Upstream is explicit: **don't attempt yet.** Check <https://github.com/fluxerapp/fluxer> periodically; when upstream ships a Docker Compose + docs ping, come back.

## Interim alternatives (your Discord-replacement today)

### Revolt

```yaml
# https://developers.revolt.chat/self-hosting/docker
services:
  revolt:
    image: ghcr.io/revoltchat/server:latest
    # ... see upstream docs
```

Revolt is closest in spirit + feature set + philosophy to Fluxer. MIT-licensed, active self-hosting story.

### Matrix + Element

Federated, full-featured, mature self-hosting. Higher complexity but ecosystem is vast. See our `matrix` / `synapse` / `element` recipes.

### Rocket.Chat

Team-chat focused; mature self-hosted docker-compose.

### Mattermost

Slack-style team chat; "Team Edition" is OSS.

### Revolt vs Matrix vs Mattermost — pick one based on:

- **Revolt** — Discord-like; small communities; easiest UX
- **Matrix** — federated; maximum interop; steepest ops
- **Rocket.Chat/Mattermost** — business-team-chat vibe

## Gotchas (specific to Fluxer)

- **Self-hosting is NOT production-ready yet** — upstream explicitly asks you to wait. Respect that. If you deploy the current `refactor` branch, you're on your own; expect breakage.
- **"Plutonium"** — mentioned in upstream README: "Self-hosted deployments won't include any traces of Plutonium." This references some hosted-service-only component (payments / tiering / moderation?). Either way, self-hosted = fully functional with no paywall.
- **Tiers + limits** — on self-hosted, admins configure their own tiers/limits in an admin panel (not paywalled).
- **Production has 125k users** — the code is battle-tested, but the deployment procedure is optimized for the founder's single production instance, not for third-party ops. The refactor aims to fix this.
- **Small team** — founder + 2 full-time, some contractors. Community contributions will open when PRs are enabled (after refactor).
- **Hiring + bounties** — upstream mentions part-time contract work + careers page. If you're a TypeScript/WebRTC dev who wants to contribute, reach out via their careers page.
- **Donation-driven** — <https://fluxer.app/donate> supports ongoing development. "The project will be made sustainable through community contributions and bounties for development work."
- **AGPL-3.0** — strong copyleft. Hosting a fork = source must be available to users.
- **Refactor timeline** — "not much left now" per README; no hard ETA. Watch the repo.
- **Discord February announcement** — mentioned cryptically in README ("Discord's announcement in February has changed things"). Has energized Fluxer growth; also means the team is swamped.
- **Community discussions**: limited right now (PRs disabled, issues curated). After refactor opens, expect Discord / forum presence.
- **Why cover it at all?** — Fluxer is appearing on self-hosting directories (selfh.st) because hosted-service+OSS-source is how most Discord alternatives start. Catalog now, revisit when self-hosting ships.

## Alternatives today

- **Revolt** — `github.com/revoltchat/revolt` — MIT — mature self-hosting
- **Matrix (Synapse/Dendrite) + Element** — federated; biggest OSS community
- **Rocket.Chat** — `github.com/RocketChat/Rocket.Chat` — MIT — mature
- **Mattermost** — `github.com/mattermost/mattermost` — MIT (+ commercial editions)
- **Jitsi Meet** — video-focused; not full chat platform
- **Zulip** — threaded-topic chat; great for work
- **Element One / Beeper** — commercial federated-chat bridges
- **Choose Fluxer WHEN:** upstream ships self-hosting docs + it matches your philosophy (community-funded, solo-founder-led, Discord-inspired UX, AGPL).
- **Choose Revolt TODAY:** closest Discord alternative with production-grade self-hosting.
- **Choose Matrix TODAY:** if federation matters.

## Links

- Repo: <https://github.com/fluxerapp/fluxer>
- Hosted service: <https://fluxer.app>
- Blog: <https://blog.fluxer.app>
- Launch post: <https://blog.fluxer.app/how-i-built-fluxer-a-discord-like-chat-app/>
- 2026 roadmap: <https://blog.fluxer.app/roadmap-2026/>
- Donate: <https://fluxer.app/donate>
- Docs: <https://docs.fluxer.app>
- Careers: <https://fluxer.app/careers>
- Revolt (alternative today): <https://github.com/revoltchat/revolt>
- Matrix Synapse: <https://github.com/element-hq/synapse>
- Rocket.Chat: <https://github.com/RocketChat/Rocket.Chat>
- Mattermost: <https://github.com/mattermost/mattermost>
