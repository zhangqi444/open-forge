---
name: Owncast
description: Self-hosted live video streaming + chat server (Twitch alternative for individuals). Single-user, RTMP ingest, HLS output, built-in chat, custom theming, Fediverse-integrated. Single Go binary. MIT.
---

# Owncast

Owncast is "your own little Twitch in a box." One broadcaster, live video over RTMP, HLS playback in any browser, built-in chat with moderation, clean single-binary deploy. Built by Gabe Kangas (ex-Twitch) since 2020.

- **RTMP ingest** from OBS, Streamlabs, ffmpeg, or any other RTMP client
- **HLS output** — playback in any browser, no Flash, no plugins
- **Built-in chat** — with moderation, emojis, user profiles
- **Custom CSS theming** — make it look like your brand
- **Fediverse integration** — stream start notifications go to ActivityPub followers (Mastodon, etc.)
- **External notifications** — Discord, browser push, email via SMTP
- **Single admin** — not multi-user, unlike Twitch (one streamer per install)
- **No transcoding by default** (bring your own bitrate ladders if needed) — lowers CPU drastically
- **Mobile-friendly** player
- **Windows not officially supported** (use WSL2)

- Upstream repo: <https://github.com/owncast/owncast>
- Website: <https://owncast.online>
- Docs: <https://owncast.online/docs/>
- Quickstart: <https://owncast.online/docs/quickstart/>
- Demo: <https://watch.owncast.online>
- Docker Hub: <https://hub.docker.com/r/owncast/owncast>

## Architecture in one minute

- **Single Go binary** — ingests RTMP, transmuxes to HLS, serves web player, handles chat (WebSocket), stores chat history in SQLite
- **SQLite** — chat history, user profiles, moderation, settings
- **`data/` directory** — SQLite DB + HLS segments + uploaded emoji/logos/chat history
- **Ports**:
  - `8080` (configurable) — HTTP web UI + HLS + admin + chat WebSocket
  - `1935` — RTMP ingest (streamers push here)

## Compatible install methods

| Infra       | Runtime                                         | Notes                                                             |
| ----------- | ----------------------------------------------- | ----------------------------------------------------------------- |
| Single VM   | Docker / Compose                                 | **Most common**                                                     |
| Single VM   | Native binary (Go)                               | Upstream recommended for bare VPS                                    |
| Single VM   | `curl`-pipe install script                        | <https://owncast.online/quickstart/>                                  |
| Kubernetes  | Community Helm chart                              | Exists; search Artifact Hub                                           |
| Windows     | **Not supported natively** — use WSL2            | Upstream doc note                                                     |
| Raspberry Pi | armv7/arm64 binaries                             | Low-bitrate streaming works fine                                       |

## Inputs to collect

| Input                  | Example                              | Phase     | Notes                                                           |
| ---------------------- | ------------------------------------ | --------- | --------------------------------------------------------------- |
| Streaming URL          | `rtmp://stream.example.com/live`      | Network   | What you paste into OBS                                          |
| Stream key             | random string                          | Security  | Admin password basically — do NOT share                           |
| Admin password         | strong                                 | Bootstrap | For `/admin` UI                                                  |
| Port (web)             | `8080`                                  | Network   | Proxy behind TLS                                                  |
| Port (RTMP)            | `1935`                                  | Network   | RTMP is cleartext — don't expose to untrusted networks            |
| Data dir               | `./data`                               | Storage   | Persistent DB + HLS cache                                         |
| CPU                    | 1 vCPU per 720p/30fps (no transcode)   | Capacity  | Add cores for transcode ladders                                    |
| Bandwidth out          | bitrate × viewer count                  | Capacity  | 4 Mbps stream × 20 viewers = 80 Mbps out                            |

## Install via Docker

```sh
docker run -d --name owncast \
  -p 8080:8080 \
  -p 1935:1935 \
  -v $(pwd)/data:/app/data \
  --restart unless-stopped \
  owncast/owncast:0.2.5    # pin; check Docker Hub
```

Admin: <http://owncast.example.com/admin> (default login **admin / abc123**).

## Install via Docker Compose

```yaml
services:
  owncast:
    image: owncast/owncast:0.2.5
    container_name: owncast
    restart: unless-stopped
    ports:
      - "8080:8080"    # web + HLS + chat WS
      - "1935:1935"    # RTMP ingest
    volumes:
      - ./data:/app/data
```

Front the web with a reverse proxy for HTTPS (`owncast.example.com` → `127.0.0.1:8080`). RTMP stays on 1935 direct (or proxied via nginx-rtmp-module — unusual).

## Install natively (recommended by upstream for bare VPS)

```sh
curl -fsSL https://owncast.online/install.sh | bash
# Installs binary + creates systemd service + prompts for data dir
```

Or manually from releases: <https://github.com/owncast/owncast/releases>.

## First boot + streamer setup

1. Browse `https://owncast.example.com/admin` (default **admin / abc123**)
2. **Server Config → Admin Password** — change it
3. **Server Config → Stream Key** — generate a new one (this is what OBS uses)
4. **Server Config → Server Settings** — set title, logo, tags, social links, external actions
5. In OBS:
   - **Settings → Stream → Custom**
   - **Server**: `rtmp://<your host>:1935/live`
   - **Stream Key**: (from admin UI)
   - **Output → Encoder**: x264 or hardware, target 2500-6000 kbps for 720p-1080p
6. Click **Start Streaming** in OBS → viewers can watch at `https://owncast.example.com/`

## Data & config layout

Inside `/app/data/`:

- `owncast.db` — SQLite (chat history, users, moderation, settings)
- `emoji/` — uploaded custom emoji
- `public/` — static assets
- `hls/` — live HLS segment cache (written at streaming time; auto-pruned)
- `backup/` — DB backups (auto, weekly by default)
- `logs/`

Size: DB stays small (~MBs); HLS cache is transient (few minutes of video at a time).

## Backup

```sh
# Pause stream first (ideal)
docker run --rm -v "$(pwd)/data:/src" -v "$(pwd):/backup" alpine \
  tar czf /backup/owncast-$(date +%F).tgz --exclude=hls --exclude=backup -C /src .
```

Exclude `hls/` (transient). SQLite auto-backup in `backup/` is a second layer.

## Upgrade

1. Releases: <https://github.com/owncast/owncast/releases>. Periodic.
2. `docker compose pull && docker compose up -d`. SQLite migrations run automatically.
3. **Back up `/app/data`** before minor-version bumps.
4. Native installs: re-run install script OR replace binary + restart systemd unit.
5. Read release notes — breaking chat emoji/custom theme changes happen occasionally.

## Gotchas

- **Default admin password is `admin` / `abc123`** — **CHANGE ON FIRST BOOT**. This is one of the most-scanned default credential pairs on the internet. Stream keys also ship with sensible defaults that you must regenerate.
- **Stream key = password for the broadcast channel.** Anyone with it can hijack your stream. Regenerate after accidental sharing (invalidates active OBS config).
- **RTMP is cleartext** — don't RTMP-in from a coffee-shop wifi. RTMPS isn't supported natively; use a WireGuard/tailscale tunnel from broadcaster to server for "secure RTMP."
- **HLS latency is 10-30 seconds** — not low-latency. For <5s latency, use SRT or WebRTC (Owncast doesn't do these). Fine for "streamer commentary" or "concert" but NOT for "gamer-talks-to-chat-in-real-time." Twitch/YouTube Live feel instant because they use low-latency HLS / WebRTC.
- **Single-user only** — cannot host multiple streamers on one Owncast install. Each broadcaster needs their own Owncast instance. This is a deliberate design choice (simpler, no discovery/moderation overhead).
- **Bandwidth budget**: 4 Mbps stream × 100 viewers = **400 Mbps outbound**. For larger audiences, put a CDN in front (Cloudflare, Bunny) or accept the bandwidth bill. VPS bandwidth is often the bottleneck, not CPU.
- **Transcoding to multiple bitrate ladders** (e.g., 1080p + 720p + 480p for "quality selector") costs CPU. Default off — you stream at one bitrate, viewers get that. Enable ladders via admin UI if CPU allows.
- **Chat history** is kept in SQLite — can grow large over time; admin UI has a prune function.
- **Moderator roles** supported; per-user actions (ban, timeout, remove message).
- **Windows not supported natively** — upstream docs say use WSL2. Mac + Linux fine.
- **Fediverse integration** auto-announces "$streamer is live!" as an ActivityPub post (Mastodon-visible). Configure in admin UI.
- **No paid-subscription / donation flow built in** — Owncast is free/public streaming only. For monetization, link out to Patreon/Ko-fi/OpenCollective/etc. via the "external actions" feature.
- **Embed** — `<iframe>` with your Owncast URL embeds the player + chat on any page.
- **Chat bot API** — chat is accessible via WebSocket; community bots exist for auto-moderation + commands.
- **MIT license** — permissive.
- **Alternatives worth knowing:**
  - **PeerTube** — decentralized YouTube/Twitch; VOD first, live is a secondary feature; federated via ActivityPub
  - **nginx-rtmp-module + custom UI** — full DIY; much more flexible but much more work
  - **Ant Media Server** — commercial; low-latency WebRTC/SRT/HLS
  - **Mirotalk / Jitsi Videobridge** — conferencing, not broadcasting
  - **Misskey Play / Pleroma live** — federated micro-live ecosystem (small)
  - **Twitch / YouTube Live / Kick** — commercial SaaS

## Links

- Repo: <https://github.com/owncast/owncast>
- Website: <https://owncast.online>
- Docs: <https://owncast.online/docs/>
- Quickstart: <https://owncast.online/docs/quickstart/>
- Docker guide: <https://owncast.online/docs/installer-docker/>
- Demo: <https://watch.owncast.online>
- Docker Hub: <https://hub.docker.com/r/owncast/owncast>
- Releases: <https://github.com/owncast/owncast/releases>
- API docs: <https://owncast.online/api/>
- Windows setup (WSL2): <https://github.com/owncast/owncast/blob/develop/contrib/owncast_for_windows.md>
- Discord: <https://owncast.rocks>
- Mastodon: <https://fosstodon.org/@owncast>
