---
name: Ombi
description: "Self-hosted media request system — users request movies/TV/music, integrates with Plex/Emby/Jellyfin + Sonarr/Radarr/Lidarr to auto-approve-and-download. The ‘wife-approval' interface for arr-stack homelabs. .NET Core. GPL-2.0."
---

# Ombi

Ombi is **"grandma-friendly, wife-approval-certified"** — a self-hosted media request portal. Your Plex/Emby/Jellyfin users hit Ombi instead of bugging you directly; they request "can you add season 3 of The Office?" or "add the new Taylor Swift album"; Ombi checks whether it's already in your library, and if not, passes the request to Sonarr / Radarr / Lidarr which then downloads + adds it. The **polite front-end to the arr-stack** — turns the admin from "the media-library concierge" into "the person who set up the self-service portal".

Built + maintained by **tidusjar (Jamie)** and the Ombi-app org. **GPL-2.0**. Long history (first releases ~2015 as PlexRequests.Net; evolved through multiple rewrites). Mature + stable product.

Use cases: (a) **family media server** where non-admin users need a self-service way to request content (b) **community Plex/Emby/Jellyfin** with user-management + quotas + auto-approval (c) **friends-and-family Plex** where you're sick of Slack/text requests (d) **small-shared-library** with social-media-like discovery UI.

Features:

- **Movies + TV + Music requests** (via Sonarr/Radarr/Lidarr integration)
- **Plex / Emby / Jellyfin media-server integration**
- **Auto-approve specific users** — trusted users skip admin approval
- **User management** — Plex.tv SSO, Emby SSO, local accounts
- **Notifications** — Discord, Slack, Telegram, email, Mattermost, Gotify, pushover, webhook
- **Language / quality profiles per user**
- **Request-limit quotas per user**
- **Mobile apps** (iOS + Android — though quality varies, check current status)
- **Landing page** with server availability + downtime notice
- **Issue reporting** from users ("audio out of sync")
- **Newsletter** — weekly "here's what's new in your library" email
- **OAuth/SSO** via Plex login

- Upstream repo: <https://github.com/Ombi-app/Ombi>
- Homepage: <https://ombi.io>
- Docs: <https://docs.ombi.app>
- Installation: <https://docs.ombi.app/installation/>
- Reverse-proxy: <https://docs.ombi.app/info/reverse-proxy/>
- Discord: <https://discord.gg/Sa7wNWb>
- Docker (LinuxServer): <https://hub.docker.com/r/linuxserver/ombi>
- Feature requests: <https://features.ombi.io>
- Patreon: <https://patreon.com/tidusjar/Ombi>
- Translations (Crowdin): <https://crowdin.com/project/ombi>

## Architecture in one minute

- **.NET Core** backend + **Angular** frontend
- **SQLite** default; MySQL optional
- **Single binary** — runs on Windows, Linux, macOS, Docker, Pi
- **Resource**: modest — 200-400MB RAM typical
- **Port 3579** default
- **LinuxServer.io Docker image** is the common deployment path (PUID/PGID, s6-overlay)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Docker             | **`lscr.io/linuxserver/ombi`** (LSIO) or upstream binary       | **Most common — LSIO-ecosystem trust signal**                                        |
| Bare-metal         | .NET Core runtime + tarball release                                       | Windows service / systemd                                                                  |
| Raspberry Pi       | arm/arm64 builds available                                                             | Works                                                                                                  |
| unRAID / Synology  | Well-documented community templates                                                                         | Native                                                                                                             |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `requests.example.com`                                          | URL          | TLS mandatory if Plex-SSO used                                                                      |
| Data dir             | `/config` (LSIO) / `ApplicationPath`                                    | Storage      | SQLite + settings                                                                                    |
| Plex / Emby / Jellyfin URL + API key                      | `http://plex:32400` + token                                       | Integration  | Ombi reads library to know what's already present                                                                                    |
| Sonarr / Radarr / Lidarr URLs + API keys                    | `http://sonarr:8989` + key                                              | Integration  | For auto-download of approved requests                                                                                              |
| SMTP                 | For notifications                                                                                                           | Email        | Strongly recommended                                                                                                                     |
| `BaseUrl` (opt)      | `/ombi` if reverse-proxied under path                                                                                                                  | Network      | Critical when behind path-prefix proxy                                                                                                                        |

## Install via Docker Compose (LinuxServer.io)

```yaml
services:
  ombi:
    image: lscr.io/linuxserver/ombi:latest           # **pin version** in prod
    container_name: ombi
    environment:
      PUID: 1000
      PGID: 1000
      TZ: Etc/UTC
      # BASE_URL: /ombi                              # if reverse-proxied under path
    volumes:
      - ./ombi-config:/config
    ports: ["3579:3579"]
    restart: unless-stopped
```

Per upstream <https://docs.ombi.app/installation/>.

## First boot

1. Browse `http://host:3579`
2. Setup wizard — pick auth (local / Plex / Emby / Jellyfin)
3. Configure Plex/Emby/Jellyfin connection → test
4. Configure Sonarr / Radarr / Lidarr → pick default quality + language + root folders
5. Configure notifications (Discord / email / etc.)
6. Import users from Plex/Emby → set auto-approve for trusted users
7. Set quotas for other users (e.g., "5 requests/week")
8. Place behind TLS reverse proxy
9. Send users the URL
10. Back up `/config` (SQLite DB)

## Data & config layout

- `/config/` (LSIO) or `ApplicationPath` — SQLite DB + settings.json + logs
- Integrates with external services; doesn't store media itself
- API keys stored in DB — **treat as secret**

## Backup

```sh
docker compose stop ombi
sudo tar czf ombi-config-$(date +%F).tgz ombi-config/
docker compose start ombi
```

Or online SQLite snapshot if you want zero-downtime.

## Upgrade

1. Releases: <https://github.com/Ombi-app/Ombi/releases>. Stable cadence.
2. LSIO Docker: bump tag; LSIO handles migrations.
3. Back up config dir FIRST.
4. Occasionally breaking changes — read release notes.

## Gotchas

- **Ombi = request portal, NOT media server.** It doesn't host your media; it orchestrates requests to your arr-stack. You need Plex/Emby/Jellyfin + Sonarr/Radarr separately. Framing: "Ombi is a button that says 'download this for me'".
- **Pirated-content legal risk** — same framing as Bazarr / Tdarr (batch 84) / arr-stack-context. Ombi doesn't download content itself, but it orchestrates Sonarr/Radarr which use Usenet/torrents. Downloading unlicensed content = copyright liability in most jurisdictions. Your own library + legal rips = fine. Expose Ombi to the public internet = **you're now running a piracy-request-portal-as-a-service**, which is a distinct legal risk from personal use. Keep it behind VPN / trusted-users-only.
- **API keys for Sonarr/Radarr/Lidarr/Plex** — stored in Ombi DB. If Ombi is compromised, attacker has write-access to your arr-stack + can download arbitrary content into your library. **TLS mandatory. Strong admin password mandatory. Behind SSO/VPN if possible.** Same **hub-of-credentials crown-jewel** pattern as Nexterm (81), myDrive (82), Webtop (83), xyOps (84). Fifth tool in that family.
- **Plex SSO privacy**: authenticating users via Plex.tv means Ombi talks to plex.tv servers for every login. Your users' auth flows transit Plex. If your threat model avoids Plex entirely → use local accounts or Emby/Jellyfin.
- **v4 rewrite history**: Ombi has been through multiple rewrites (v2 → v3 → v4). Some old docs / blog posts reference old versions. Always consult current docs.
- **Mobile app quality is variable** — iOS + Android apps exist but have historically lagged in updates. Web UI is the primary interface; set user expectations.
- **BASE_URL setting for reverse-proxy sub-paths** is a common stumble. If hosting at `example.com/ombi/`, set `BASE_URL: /ombi` before deployment. Changing after the fact requires full restart + cache-clear.
- **User quota + auto-approve** is the key admin-UX lever — tune it to avoid storage runaway. Users will request every movie they've ever heard of. Quota (e.g., 3 movies/week per user) keeps it manageable.
- **Notifications overload**: enabling Discord/email for every request + every approval + every available = notification spam. Start with "available" only for most users; admin gets "new request" alerts.
- **Newsletter feature** can be spammy if over-used. Weekly max; highlight 5-10 new items; don't list every episode of every show.
- **Issue reporting from users** is underused — many deployments ignore this. If your users can report "audio desync on this movie", you can proactively fix or re-download. Better feedback loop than discovering bad files months later.
- **LinuxServer.io image conventions** apply (PUID/PGID, s6-overlay, `TZ`, `/config` mount). Same family as Webtop (83), Bazarr, Sonarr, Radarr. Trusted packaging ecosystem.
- **Project health**: tidusjar solo-led + Ombi-app org + Patreon + Discord community + long history (10+ years). Cadence slower than peak years; still actively maintained + stable. Widely deployed in Plex/Jellyfin community. Not going anywhere soon.
- **Alternatives worth knowing:**
  - **Overseerr** — Plex-focused request portal; TypeScript + React; modern UI; arguably nicer UX than Ombi for Plex-only setups. **Fork-lineage**: originated as different code but similar scope.
  - **Jellyseerr** — Overseerr fork for Jellyfin/Emby. Very active; strong choice for Jellyfin users.
  - **Petio** — Plex companion request/stats tool; community project
  - **Requestrr** — Discord-bot-based requests; chat-interface instead of web UI
  - **Choose Ombi if:** you want mature + multi-media-server (Plex + Emby + Jellyfin + Lidarr music) + established.
  - **Choose Overseerr if:** Plex-only + want modern UI.
  - **Choose Jellyseerr if:** Jellyfin/Emby-focused.

## Links

- Repo: <https://github.com/Ombi-app/Ombi>
- Homepage: <https://ombi.io>
- Docs: <https://docs.ombi.app>
- Installation: <https://docs.ombi.app/installation/>
- Reverse-proxy guide: <https://docs.ombi.app/info/reverse-proxy/>
- Discord: <https://discord.gg/Sa7wNWb>
- Patreon: <https://patreon.com/tidusjar/Ombi>
- Feature requests: <https://features.ombi.io>
- Crowdin (translations): <https://crowdin.com/project/ombi>
- LinuxServer.io image: <https://docs.linuxserver.io/images/docker-ombi/>
- Overseerr (alt): <https://overseerr.dev>
- Jellyseerr (alt): <https://github.com/fallenbagel/jellyseerr>
- Requestrr (alt): <https://github.com/darkalfx/requestrr>
