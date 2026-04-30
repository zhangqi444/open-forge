---
name: Tautulli
description: "Monitoring and tracking tool for Plex Media Server — rich watch history, user statistics, real-time activity, notifications (Discord/Telegram/Slack/webhooks/etc.), newsletters, per-user stats. Python/Flask. GPL-3.0."
---

# Tautulli

Tautulli is **the "analytics + ops dashboard" for Plex Media Server**. Plex itself doesn't expose rich historical or per-user analytics out of the box; Tautulli sits alongside your Plex server, polls the API, records every play, builds gorgeous dashboards, and fires notifications on events (new movie added, user started/finished watching, stream transcoded, bandwidth hit threshold, etc.).

Formerly known as **PlexPy**. Same codebase, renamed.

Features:

- **Real-time activity monitor** — who's watching what, where from, transcode vs direct play, bandwidth
- **History** — every play, ever; per-user; per-title; per-library
- **Statistics dashboard** — top users, top titles, most-watched genres, watch time over time
- **Per-user stats** — watch time, favorite genres, top titles, on a schedule
- **Notifications** — fires on events (stream start/stop/pause, recently added, new device, watched, buffering, concurrent streams threshold)
- **Notification agents** — Discord, Telegram, Slack, Pushover, Pushbullet, Email, IFTTT, Webhook, Prowl, Notify My Android, Boxcar, Facebook, Twitter, Scripts, Join, Hipchat, MQTT, etc.
- **Newsletter** — weekly HTML email of "what's new"
- **Graphs** — 20+ pre-built; customizable
- **IP logging** + geolocation (IPinfo/MaxMind)
- **Database stats** — tracks Plex DB health
- **Import from Plex** — full history backfill
- **Themeable UI**

Formerly PlexPy — old redirects may still point there. Project rebranded ~2018.

- Upstream repo: <https://github.com/Tautulli/Tautulli>
- Website: <https://tautulli.com>
- Docs / Wiki: <https://github.com/Tautulli/Tautulli/wiki>
- Discord: <https://discord.gg/9a2pVPBedW>
- Reddit: <https://www.reddit.com/r/Tautulli>

## Architecture in one minute

- **Python/Flask app** — single process
- **SQLite** — internal DB (watch history, settings, users)
- **Talks to Plex via Plex HTTP API** (token-authenticated)
- **Polls** for activity every few seconds
- **Low resource** — ~100 MB RAM idle; CPU bursts during image processing / newsletter generation

## Compatible install methods

| Infra             | Runtime                                                         | Notes                                                                         |
| ----------------- | --------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Single VM         | **Docker (`ghcr.io/tautulli/tautulli`)**                              | **Most popular**                                                                   |
| Single VM         | **LinuxServer.io (`lscr.io/linuxserver/tautulli`)**                                  | Alternative image with LSIO conventions (PUID/PGID)                                         |
| Single VM         | **Native Python**                                                                                | Follow upstream Wiki                                                                                    |
| Synology / QNAP   | Community packages + Docker                                                                                 | Common NAS deployment alongside Plex                                                                                |
| Raspberry Pi      | arm/arm64 Docker                                                                                                        | Works great                                                                                                                     |
| Managed           | — (no SaaS)                                                                                                                        |                                                                                                                                                |

## Inputs to collect

| Input              | Example                                 | Phase      | Notes                                                                       |
| ------------------ | --------------------------------------- | ---------- | --------------------------------------------------------------------------- |
| Plex server URL    | `http://192.168.1.10:32400`                   | Plex       | Direct LAN address fastest                                                         |
| Plex token         | see Plex support article                          | Auth       | Required; Tautulli reads DB/metadata via this                                               |
| Tautulli port      | `8181`                                                | Network    | Default                                                                                       |
| Admin login        | set on first boot                                             | Security   | **Always enable** — it holds your Plex token                                                                |
| GeoIP (opt)        | MaxMind license key                                                   | Feature    | For geolocation on activity                                                                                         |
| Notifier creds     | Discord webhook / Telegram bot token / SMTP                                   | Notifications | Per-agent                                                                                                            |
| Import from Plex   | tick during first-run                                                                  | Setup      | One-time full backfill                                                                                                                |

## Install via Docker

```yaml
services:
  tautulli:
    image: ghcr.io/tautulli/tautulli:latest         # pin in prod (e.g., v2.14.5)
    container_name: tautulli
    restart: unless-stopped
    environment:
      TZ: America/Los_Angeles
      PUID: "1000"
      PGID: "1000"
    volumes:
      - ./config:/config
    ports:
      - "8181:8181"
    depends_on:
      - plex                                          # if on same compose
```

Browse `http://<host>:8181/`. First-run wizard: enable HTTP auth → paste Plex URL + token.

## First boot

1. First wizard → set admin user/password
2. Enter Plex URL + server token (see <https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/>)
3. Test connection → Tautulli discovers your libraries + users
4. Tick **Import from Plex** → backfill full watch history (may take hours for old installs)
5. Notification Agents → add Discord webhook / Telegram / Email as you like
6. Build your first newsletter → subscribe your users
7. Dashboard → enjoy

## Data & config layout

- `/config/config.ini` — settings + Plex token **(sensitive)**
- `/config/tautulli.db` — SQLite (watch history, users, notifications)
- `/config/logs/` — logs
- `/config/cache/` — images / thumbnails / newsletter assets
- `/config/backups/` — auto-backed-up DB

## Backup

```sh
# Tautulli auto-backs up tautulli.db on schedule in config/backups/
tar czf tautulli-$(date +%F).tgz config/
```

The DB has all history — don't lose it.

## Upgrade

1. Releases: <https://github.com/Tautulli/Tautulli/releases>. Regular.
2. Docker: bump tag → restart. Schema migrations auto.
3. **Enable auto-update in Settings → General** for maintenance mode.
4. Before major updates, back up DB.

## Gotchas

- **The Plex token is powerful.** It can access your entire Plex library + management. **Do not expose Tautulli publicly without auth.** Put behind reverse proxy + Authelia/Authentik if you need remote access.
- **Get the token correctly**: Plex has a [support article](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/) — don't share it, it's essentially your Plex password in URL form.
- **Tautulli should run on the SAME network as Plex** where possible — LAN direct connection is much faster than remote Plex URLs.
- **History backfill** can take hours on large libraries — let it finish; pause UI browsing during first run.
- **Notification fatigue**: starting out, enable a handful. "Recently added" + "Stream started" + "Stream stopped" + "Plex server down" is a sane baseline. Don't enable all 40 triggers at once.
- **Concurrent stream limits**: Tautulli can notify when concurrent streams > N. Useful for catching password-sharing (if that's a concern).
- **Transcoding alert**: configure "transcode" notifications to spot CPU-heavy transcodes; tune Plex quality/direct-play.
- **GeoIP privacy**: logs include client IPs + geolocation. If your users care, disable or anonymize.
- **Newsletters**: HTML email; looks great but can be heavy. Configure SMTP carefully; Gmail's app password required if using Gmail as SMTP.
- **Webhook scripting**: Tautulli can run shell scripts on events — powerful + dangerous. Use for custom integrations (e.g., trigger Kodi library update on "recently added").
- **Mobile**: no native app; UI is mobile-responsive; some community-made widgets/apps exist (unofficial).
- **Plex changes**: Plex occasionally tweaks their API; Tautulli catches up within a release or two. Stay updated.
- **Backup DB before upgrading** on major releases.
- **Stream termination**: Tautulli can **kill streams** (banned users, over-limit) via Plex API. Powerful feature; audit log it.
- **Formerly PlexPy**: old tutorials reference PlexPy. Same project.
- **Comparison to Plex's own stats**: Plex dashboard gives basic activity; Tautulli gives 100× more. Worth running alongside.
- **License**: GPL-3.0.
- **Alternatives worth knowing:**
  - **Plex Dashboard** (built-in) — basic activity + history; less detailed than Tautulli
  - **Emby/Jellyfin** — both have built-in analytics; no Tautulli needed for those platforms
  - **Ombi** — request-management tool for Plex (separate concern, often paired with Tautulli)
  - **Overseerr** — newer Ombi-alike (separate recipe likely)
  - **Plex webhooks + custom dashboards** — DIY (Grafana)
  - **jfa-go** — Jellyfin user management (tangentially related)
  - **maintainerr** — library cleanup rules for Plex
  - **Varken** — Grafana-based stats for Plex/Sonarr/Radarr (separate recipe)
  - **Choose Tautulli if:** you run Plex and want best-in-class analytics + notifications — no contest.
  - **For Jellyfin users**: Jellyfin has built-in stats; Tautulli doesn't support Jellyfin.

## Links

- Repo: <https://github.com/Tautulli/Tautulli>
- Website: <https://tautulli.com>
- Docs / Wiki: <https://github.com/Tautulli/Tautulli/wiki>
- Installation guide: <https://github.com/Tautulli/Tautulli/wiki/Installation>
- Docker (GHCR): <https://github.com/Tautulli/Tautulli/pkgs/container/tautulli>
- Docker (Docker Hub): <https://hub.docker.com/r/tautulli/tautulli>
- LinuxServer.io image: <https://hub.docker.com/r/linuxserver/tautulli>
- Releases: <https://github.com/Tautulli/Tautulli/releases>
- Discord: <https://discord.gg/9a2pVPBedW>
- Reddit: <https://www.reddit.com/r/Tautulli>
- Finding Plex token: <https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/>
- Plex: <https://www.plex.tv>
- Jellyfin (alt platform): <https://jellyfin.org>
- Varken (alt: Grafana-based): <https://github.com/Boerderij/Varken>
