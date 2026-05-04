---
name: fonoster
description: Recipe for Fonoster — open-source programmable telecommunications stack (Twilio alternative).
---

# Fonoster

Open-source, API-oriented programmable telecommunications platform — an alternative to Twilio. Provides a Voice API for building phone applications, SIP trunking integration, IVR/automation via NodeJS SDK, AI-powered Autopilot (LLM-driven voice agents), and a web dashboard. Built on Asterisk + gRPC microservices. Upstream: <https://github.com/fonoster/fonoster>. Docs: <https://docs.fonoster.com>. License: MIT. ~6K stars.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://docs.fonoster.com/self-hosting/deploy-with-docker> | ✅ | Recommended self-hosted production setup |
| Fonoster Cloud | <https://app.fonoster.com> | ✅ (managed) | Hosted SaaS — no self-hosting needed |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | "Public hostname/domain for Fonoster?" | hostname | All. Used for SIP signaling and API endpoints. |
| infra | "SIP trunk provider and credentials?" | Provider + credentials | Required for PSTN calling (inbound/outbound numbers) |
| software | "Admin email?" | Email | First-run setup |
| software | "Admin password?" | Sensitive string | First-run setup |
| software | "Speech vendor?" | Google / ElevenLabs / Amazon Polly / etc. | Optional — for `Say` verb / Autopilot |

## Software-layer concerns

### Docker Compose

Follow the upstream self-hosting guide at <https://docs.fonoster.com/self-hosting/deploy-with-docker> — the compose file is maintained in the repository.

Key services in the stack:

| Service | Purpose |
|---|---|
| `apiserver` | gRPC API server |
| `routr` | SIP proxy / signaling (built on Routr v2) |
| `mediacontroller` | Asterisk-based media server |
| `autopilot` | LLM-driven voice agent service |
| `identity` | Auth / JWT / OAuth2 |
| `postgresql` | Primary database |
| `redis` | Cache + pub/sub |
| `nats` | Message bus between microservices |

### API example (NodeJS SDK)

```typescript
import VoiceServer from "@fonoster/voice";
import { VoiceRequest, VoiceResponse, GatherSource } from "@fonoster/voice";

new VoiceServer().listen(async (req: VoiceRequest, voice: VoiceResponse) => {
  await voice.answer();
  await voice.say("Hello! Please say your name.");
  const { speech: name } = await voice.gather({ source: GatherSource.SPEECH });
  await voice.say(`Nice to meet you, ${name}!`);
  await voice.hangup();
});
```

### SIP / telephony requirements

- A SIP trunk provider (e.g. Twilio SIP Trunking, Vonage, Telnyx, or any SIP provider)
- Public IP with UDP/TCP port 5060 (SIP) and RTP ports (typically 10000–20000) open
- DNS A record pointing to your server's public IP

### First API keys

After deploying, follow <https://docs.fonoster.com/self-hosting/first-apikeys> to generate your first API key for SDK use.

### Securing the API (TLS)

See <https://docs.fonoster.com/self-hosting/securing-the-api> for TLS setup with a reverse proxy.

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Check the changelog at <https://github.com/fonoster/fonoster/releases> for breaking changes before upgrading.

## Gotchas

- **SIP ports must be publicly accessible**: VoIP won't work behind NAT without proper port-forwarding or STUN/TURN. The server needs a static public IP.
- **RTP port range**: Open UDP 10000–20000 (or your configured range) in your firewall — this carries the actual audio.
- **Speech vendor setup**: The `Say` verb and Autopilot require configuring a TTS vendor (Google, ElevenLabs, etc.) with API credentials.
- **Complex stack**: Fonoster is a multi-service system. Troubleshoot individual services with `docker compose logs <service>`.
- **Early-stage software**: The platform is under active development. Review release notes carefully before production deployments.

## Links

- GitHub: <https://github.com/fonoster/fonoster>
- Docs: <https://docs.fonoster.com>
- Self-hosting guide: <https://docs.fonoster.com/self-hosting/overview>
- Discord: <https://discord.gg/4QWgSz4hTC>
- Dashboard: <https://app.fonoster.com>
