---
name: Spacebar
description: "Free, open-source, self-hostable Discord-compatible chat / voice / video platform (formerly 'Fosscord'). Server + Client repos. Reuses Discord's client API so custom Discord clients/bots work with minimal changes. In active development. AGPL-3.0."
---

# Spacebar

Spacebar (formerly **Fosscord**) is **a self-hostable, Discord-compatible chat + voice + video platform**. It implements Discord's REST + Gateway + CDN APIs closely enough that unmodified Discord custom clients and many bots can connect to a Spacebar server with minimal config changes. You run your own instance; users can join your instance the same way they'd join a Discord server, but you own the data, rules, and infrastructure.

> **Project status — read carefully:**
>
> - **Status: Development** (per upstream README as of late 2024). Not "production-ready" — expect rough edges, missing features, breaking changes.
> - **Compatibility with Discord's live API is a moving target** — Discord changes theirs; Spacebar catches up; occasional drift breaks custom clients until re-synced.
> - **Voice + video implementation uses WebRTC + selfhosted SFU** — moderately complex to deploy + tune.
> - **Better alternatives for "just want a chat server":** Matrix (Synapse/Dendrite/Conduit), Revolt, Rocket.Chat, Mattermost. Spacebar is uniquely for "I want to self-host something Discord-compatible."

Split across several repositories:

- [**server**](https://github.com/spacebarchat/server) — API, Gateway, CDN, WebRTC, admin dashboard
- [**client**](https://github.com/spacebarchat/client) — Spacebar-branded client (also works with discord.com)
- [**docs**](https://github.com/spacebarchat/docs) — project documentation
- [**landing page**](https://github.com/spacebarchat/landingpage) — homepage

Features (as planned / partially shipped):

- Guild (server) + channels + threads + roles + permissions
- Text messages + embeds + attachments
- Voice channels with WebRTC
- Video + screenshare (WebRTC)
- Extendable plugin system
- Theme system + design editor
- Configurable limits (message size, upload size, file types, etc. — per instance)
- Multi-instance + bridging (goal; partial)
- i18n (via Crowdin)
- Self-configurable captcha / auth / invite rules

- Upstream (main): <https://github.com/spacebarchat/spacebarchat>
- Server: <https://github.com/spacebarchat/server>
- Client: <https://github.com/spacebarchat/client>
- Website: <https://spacebar.chat>
- Docs: <https://docs.spacebar.chat>
- Discord: <https://discord.gg/ZrnGQP6p3d>
- OpenCollective: <https://opencollective.com/spacebar>

## Architecture in one minute

- **API server** (TypeScript / Node.js) — REST endpoints compatible with Discord API
- **Gateway** — WebSocket for real-time events (compat with Discord gateway)
- **CDN** — file/asset storage endpoints
- **WebRTC SFU** — voice/video routing
- **Admin dashboard** — server management UI
- **DB**: **MongoDB** (most common), with Postgres/MySQL in some configurations (check current — it's evolved)
- **Redis**: recommended for scale
- **Client**: React-native / Electron (desktop); web client served separately

## Compatible install methods

| Infra          | Runtime                                                     | Notes                                                                    |
| -------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------ |
| Single VM      | **Docker Compose** (community-maintained compose in server repo)  | **Most common path**                                                             |
| Single VM      | Native Node.js + MongoDB + Redis                                        | More ops                                                                         |
| Kubernetes     | Community manifests / Helm                                                    | Possible                                                                                    |
| Managed        | — (some community-hosted instances; no first-party SaaS)                            | List at spacebar.chat                                                                               |
| Raspberry Pi   | Limited — WebRTC CPU demands + MongoDB footprint                                         | Not ideal                                                                                              |

## Inputs to collect

| Input              | Example                              | Phase      | Notes                                                                |
| ------------------ | ------------------------------------ | ---------- | -------------------------------------------------------------------- |
| Domain             | `spacebar.example.com`                   | URL        | API + gateway                                                              |
| CDN domain         | `cdn.spacebar.example.com`                     | URL        | For uploads                                                                        |
| Media domain       | `media.spacebar.example.com`                         | URL        | For WebRTC RTP                                                                               |
| DB                 | MongoDB URI                                           | DB         | Primary; some deployments use SQL                                                                   |
| Redis              | URI                                                         | Cache      | Recommended                                                                                                  |
| TURN               | coturn server                                                        | WebRTC     | Required for voice/video behind NAT                                                                                     |
| Admin account      | first user via signup                                                        | Bootstrap  | Grant admin via DB or admin dashboard                                                                                              |
| SMTP               | host/port/user/pass                                                                  | Email      | Registration verify + resets                                                                                                               |
| TLS                | wildcard cert recommended                                                                         | Security   | `*.spacebar.example.com`                                                                                                                              |

## Install via Docker Compose (community)

Read the current server README; upstream ships a scaffold `docker-compose.yml`. Rough shape:

```sh
git clone https://github.com/spacebarchat/server.git
cd server
cp config.example.json config.json     # or use env vars
# Edit config.json: DB URL, domains, secrets
docker compose up -d
```

Plan for ~1 hour of config work reading their docs for the first setup. Voice requires TURN/STUN.

## First boot

1. Browse `https://spacebar.example.com` → register first account (becomes instance admin via admin dashboard grant or DB edit)
2. Log in via a client (Spacebar's client or a Discord custom client pointed at your API URL)
3. Create a guild → text channel → voice channel (WebRTC)
4. Invite another user; test end-to-end
5. Configure limits (Admin dashboard): max upload size, message rate, invite rate

## Pointing a Discord client at Spacebar

Some Discord custom clients (Vesktop, BetterDiscord, OpenAsar, etc.) let you override the API endpoint. Configuration varies:

- Typical: set `CLIENT_ENDPOINT=https://spacebar.example.com/api` or edit the client config
- Web client: use Spacebar's own client OR host a modified discord.com client

## Data & config layout

- MongoDB — all guild/channel/message/user data
- Redis — cache + rate limits
- `uploads/` or CDN bucket — attachments + avatars + emoji
- `config.json` or env — secrets + domain + limits

## Backup

```sh
# Mongo
docker exec mongo mongodump --uri mongodb://user:pass@localhost/spacebar -o /tmp/backup
# Tar + copy out
# CDN storage (uploads)
tar czf sb-cdn-$(date +%F).tgz cdn-data/
# Config
cp config.json sb-config-$(date +%F).bak
```

Uploads can grow large (video/screenshot pastes). Plan retention.

## Upgrade

1. Releases: <https://github.com/spacebarchat/server/releases>. Active; sometimes irregular.
2. **Back up DB + uploads + config.**
3. Git pull + `docker compose up -d`. Schema migrations may be manual for pre-1.0.
4. Client updates separately.
5. Read release notes — API compat shifts may require client rebuilds.

## Gotchas

- **Development-status**: don't use for production-critical communities. Community members expect Discord-level reliability; Spacebar isn't there yet.
- **Discord API drift**: Discord changes its API frequently; Spacebar's compat may break custom clients until caught up. If you need bulletproof "Discord-exact behavior," stay on Discord.
- **WebRTC voice/video** — requires a TURN server (coturn) for NATed users to connect. Set up TURN with TLS + long-term credentials before advertising voice.
- **Port 3478 (STUN/TURN)** + media port range (typically 49152-65535) must be reachable. Plan firewall / cloud egress.
- **Scaling voice/video**: the bundled SFU is single-node; for 10s of users per voice channel is fine; hundreds requires clustering/SFU federation (experimental).
- **File uploads**: set tight size limits (Discord's default was 25 MB / 50 MB nitro) — otherwise users will abuse.
- **CDN security**: uploads served from your CDN domain. Ensure no execution (`text/html` served with `Content-Disposition: attachment` + `X-Content-Type-Options: nosniff`).
- **Bot compatibility** — many Discord.js bots work if you set the base URL. Gateway intents, some newer endpoints may be missing.
- **Moderation**: Spacebar gives you mod tools but not Discord's "trust & safety" team. You are responsible for CSAM / illegal content handling. Have clear ToS + reporting flow.
- **Legal**: self-hosting a chat platform = you're potentially a "service provider." DMCA / GDPR / COPPA implications vary by jurisdiction + user base.
- **Data portability**: users can't "take their Discord history" to Spacebar or vice versa. Federation/bridges are a goal, not reality.
- **Fosscord → Spacebar rename** — old docs + Discord URLs reference Fosscord. Same project. Don't be confused.
- **Admin dashboard**: check current state; may be basic or in flux.
- **Alternative clients**: Spacebar-branded client exists; you can also use a modified open-source Discord client; or browser-based.
- **SSL for WebRTC**: media domain needs valid TLS for WebRTC connections from browsers. No self-signed.
- **License**: AGPL-3.0.
- **Alternatives worth knowing:**
  - **Matrix** (Synapse / Dendrite / Conduit) — federated, mature, richer encryption (E2EE), less "Discord-UI" (separate recipe)
  - **Revolt** — self-hostable Discord-alike; more production-ready than Spacebar (separate recipe likely)
  - **Rocket.Chat** — mature open-source team chat
  - **Mattermost** — Slack-alike team chat (separate recipe)
  - **Zulip** — thread-focused team chat
  - **Discord** (SaaS) — the original; best reliability + feature set; not self-hostable
  - **Choose Spacebar if:** you specifically want Discord API compatibility + self-host; accept development status.
  - **Choose Matrix if:** E2EE + federation + long-term stability matter.
  - **Choose Revolt if:** you want a Discord-like UX without strict API compat.
  - **Choose Mattermost/Rocket.Chat if:** team-chat ergonomics + polished self-host.

## Links

- Main repo: <https://github.com/spacebarchat/spacebarchat>
- Server: <https://github.com/spacebarchat/server>
- Client: <https://github.com/spacebarchat/client>
- Docs: <https://docs.spacebar.chat>
- Website: <https://spacebar.chat>
- Discord: <https://discord.gg/ZrnGQP6p3d>
- OpenCollective: <https://opencollective.com/spacebar>
- Crowdin translations: <https://translate.spacebar.chat>
- Contributing: <https://docs.spacebar.chat/contributing/>
- Matrix alternative: <https://matrix.org>
- Revolt alternative: <https://revolt.chat>
