---
name: Pinchflat
description: "Self-hosted YouTube media manager — yt-dlp-powered channel/playlist monitoring with rules-based auto-download, Plex/Jellyfin/Kodi-friendly naming, podcast RSS feeds, SponsorBlock tags, Apprise notifications. Elixir/Phoenix + SQLite. AGPL-3.0."
---

# Pinchflat

Pinchflat is **"set rules, Pinchflat downloads the matching YouTube content forever"** — a self-hosted YouTube media manager built on **yt-dlp**. Subscribe to channels/playlists, configure format + quality + naming rules, Pinchflat periodically checks for new content + downloads it to disk. Integrates with **Plex / Jellyfin / Kodi** (naming + structure), **podcast apps** (RSS feeds), **SponsorBlock** (auto-tag sponsor segments), **Apprise** (notifications).

Developed by **Kieran Eglin (kieraneglin)**. Active project; thoughtful UX.

> **💜 Community note (preserved from upstream, 2025-02-14):**
>
> *"[zakkarry](https://github.com/sponsors/zakkarry), who is a collaborator on [cross-seed](https://github.com/cross-seed/cross-seed) and an extremely helpful community member in general, is facing hard times due to medical debt and family illness. If you're able, please consider sponsoring him on GitHub or donating via buymeacoffee. Tell him I sent you!"*
>
> (Noting this because it's the kind of community care worth honoring. Unrelated to Pinchflat operation.)

Features:

- **Rule-based downloads** — per-channel/playlist: format, quality, naming, cutoff date, title filters
- **Novel new-content detection** — faster than polling all metadata
- **Plex/Jellyfin/Kodi-friendly naming + structure**
- **Podcast RSS feeds** — serve downloaded audio as RSS for podcast apps
- **Audio-only downloads**
- **SponsorBlock integration** — auto-tag sponsor segments
- **Apprise notifications**
- **YouTube cookies** — download private playlists (your own watch-later, members-only, etc.)
- **Auto-redownload after a set period** — pick up better quality or updated SB tags
- **Auto-delete old content** — retention policy
- **Custom yt-dlp options** (advanced)
- **Custom lifecycle scripts** — pre/post download/delete hooks (alpha)
- **Prometheus metrics** (optional)
- **Single Docker container**, no external DB

- Upstream repo: <https://github.com/kieraneglin/pinchflat>
- Wiki (primary docs): <https://github.com/kieraneglin/pinchflat/wiki>
- Discord: <https://discord.gg/j7T6dCuwU4>
- Docker (GHCR): `ghcr.io/kieraneglin/pinchflat:latest`
- Docker Hub: `keglin/pinchflat:latest`
- Sponsor: <https://github.com/sponsors/kieraneglin>

## Architecture in one minute

- **Elixir / Phoenix** app (OTP supervision = highly fault-tolerant for long-running download workers)
- **SQLite** — uses WAL mode by default
- **yt-dlp** + **ffmpeg** bundled in the image
- **No external DB / queue / broker** — everything in one container
- **Resource**: modest — 200-400 MB RAM idle; CPU + disk bursty during downloads

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Single VM / NAS    | **Docker (`ghcr.io/kieraneglin/pinchflat:latest`)**                | **Upstream-recommended**                                                           |
| Unraid             | Community Apps store                                                       | Popular                                                                                    |
| Portainer          | Compose file                                                                          | Works                                                                                                   |
| Podman             | With `--userns=keep-id` (documented)                                                                | Works; documented flags                                                                                                       |
| Raspberry Pi       | arm64 image                                                                                          | CPU-bound on video transcode; audio fine                                                                                                             |
| Kubernetes         | Community manifests                                                                                                 | Works                                                                                                                                                |

## Inputs to collect

| Input                      | Example                                          | Phase        | Notes                                                                        |
| -------------------------- | ------------------------------------------------ | ------------ | ---------------------------------------------------------------------------- |
| Config dir                 | `/opt/pinchflat/config` → `/config`                  | Storage      | SQLite DB + state — **prefer local disk, NOT network share** (WAL)                   |
| Downloads dir              | `/media/youtube` → `/downloads`                            | Storage      | Big; separate volume; plan size                                                              |
| TZ                         | `America/Los_Angeles`                                        | Env          | IANA format                                                                                      |
| Basic auth (optional)      | `BASIC_AUTH_USERNAME` + `BASIC_AUTH_PASSWORD`                         | Auth         | **Highly recommended** before exposing                                                                                 |
| YouTube cookies (optional) | cookies.txt format                                                        | Auth         | For private playlists / authenticated browsing                                                                                                 |
| Media server               | Plex / Jellyfin / Kodi                                                               | Integration  | Naming templates align with these                                                                                                                               |
| UMASK (optional)           | `022` default; `000` for Unraid                                                                     | Perms        | Per documented Unraid note                                                                                                                                                      |

## Install via Docker Compose

```yaml
services:
  pinchflat:
    image: ghcr.io/kieraneglin/pinchflat:latest            # pin specific version in prod
    container_name: pinchflat
    restart: unless-stopped
    environment:
      TZ: America/Los_Angeles
      # BASIC_AUTH_USERNAME: admin
      # BASIC_AUTH_PASSWORD: CHANGE_STRONG_PASSWORD
      # EXPOSE_FEED_ENDPOINTS: "true"                       # only if serving RSS publicly
    ports:
      - "8945:8945"
    volumes:
      - /opt/pinchflat/config:/config
      - /media/youtube:/downloads
```

Browse `http://<host>:8945/` → configure sources.

## First boot

1. Browse → optional basic auth check
2. Add first Source: paste YouTube channel/playlist URL → choose preset (podcast / movies / minimal)
3. Review download path + naming template → adjust for media server
4. Enable SponsorBlock if wanted
5. Let Pinchflat perform initial scan — can take minutes to hours depending on backlog
6. Test Plex/Jellyfin picks up the downloads → media server settings may need scheduled library scan
7. Set up Apprise for download/error notifications
8. If using RSS feeds → set `EXPOSE_FEED_ENDPOINTS=true` + put behind basic auth

## Data & config layout

- `/config/` — SQLite DB (`pinchflat.db` + WAL files) + config + logs
- `/downloads/` — downloaded media organized by your naming template
- **SQLite uses WAL mode by default**: `pinchflat.db`, `pinchflat.db-wal`, `pinchflat.db-shm` co-resident

## Backup

```sh
sudo tar czf pinchflat-config-$(date +%F).tgz /opt/pinchflat/config/
# Downloads volume: your normal media backup policy (or no backup — re-downloadable)
```

## Upgrade

1. Releases: <https://github.com/kieraneglin/pinchflat/releases>. Active.
2. Docker: bump tag → restart → migrations auto.
3. **Pre-release disclaimer** in README: project is still actively evolving; back up `/config/` before upgrade.

## Gotchas

- **`/config/` on network share = WAL mode issues.** Upstream explicitly warns (issue #137): SQLite WAL mode misbehaves on NFS/SMB. Options:
  1. Store `/config/` on local disk (preferred — upstream recommendation)
  2. Set `JOURNAL_MODE=delete` (rollback-journal; less performant, works on NFS)
  - **Switching JOURNAL_MODE on existing DB can cause data loss** — back up first.
  - `/downloads/` on NAS/SMB is fine — those are just files.
- **Don't run container as root** (upstream explicit): creates permission issues across media-server containers. Use non-root UID matching your Plex/Jellyfin user.
- **Podman `--userns=keep-id --user=$UID`** is the documented pattern — different from Docker.
- **File permissions on bind mounts**: classic — `PUID/PGID` gotcha. Match host user who owns the dirs.
- **YouTube ToS**: downloading YouTube content violates ToS in most scenarios. You take the risk. SponsorBlock is strictly a tagging integration (content-aware); SponsorBlock compliance isn't the issue, YouTube ToS is.
- **YouTube fights scrapers**: yt-dlp breaks periodically when YouTube changes APIs. Pinchflat bumps yt-dlp regularly; stay current. If downloads stop, check yt-dlp issue tracker + update Pinchflat.
- **YouTube cookies = your YouTube session**: treat cookies.txt as YOUR credentials. Don't share, don't commit to git. Revoke + regenerate if leaked.
- **IP rate-limiting**: if you download too aggressively, YouTube may throttle/block your IP. Reduce `YT_DLP_WORKER_CONCURRENCY` (default 2) if hitting limits.
- **Audio-only as podcast**: Pinchflat exposes RSS feeds per source. Great pattern for podcast apps. `EXPOSE_FEED_ENDPOINTS=true` controls public-RSS endpoint exposure; pair with basic auth if public-facing.
- **Storage growth**: YouTube videos are big. 4K 60-minute video = ~4-10 GB. Plan disk.
- **Auto-delete**: optional retention; great for news/talk-show channels where you don't need to keep forever.
- **Auto-redownload**: periodically re-fetches content — better quality when it becomes available, updated SponsorBlock tags. Eats bandwidth + disk churn; tune cadence.
- **Custom yt-dlp options + lifecycle scripts**: advanced power; easy to break things. Document your overrides.
- **Pre-release status**: project shipping + active; treat major versions with backup discipline.
- **Comparison**:
  - **Tube Archivist** — larger ecosystem; more features; heavier
  - **ytdl-sub** — YAML-config CLI-first; headless
  - **TubeSync** — similar to Pinchflat; older
  - **Plex YouTube Channel plugin** — dead; don't use
  - **Choose Pinchflat if:** polished UI + rules-based + Plex/Jellyfin-ready + self-contained container.
  - **Choose Tube Archivist if:** want watch-in-app experience too.
  - **Choose ytdl-sub if:** YAML/GitOps-friendly + CLI-first.
- **License**: **AGPL-3.0**.
- **Bus factor**: solo (kieraneglin) + growing community. Active releases. Solo-dev with healthy cadence pattern (same as batches 72-75 for similar projects).

## Links

- Repo: <https://github.com/kieraneglin/pinchflat>
- Wiki: <https://github.com/kieraneglin/pinchflat/wiki>
- Discord: <https://discord.gg/j7T6dCuwU4>
- Releases: <https://github.com/kieraneglin/pinchflat/releases>
- Docker (GHCR): <https://ghcr.io/kieraneglin/pinchflat>
- Docker Hub: <https://hub.docker.com/r/keglin/pinchflat>
- FAQ: <https://github.com/kieraneglin/pinchflat/wiki/Frequently-Asked-Questions>
- RSS feed docs: <https://github.com/kieraneglin/pinchflat/wiki/Podcast-RSS-Feeds>
- Auth docs: <https://github.com/kieraneglin/pinchflat/wiki/Username-and-Password>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>
- SponsorBlock: <https://sponsor.ajay.app>
- Tube Archivist (alt): <https://github.com/tubearchivist/tubearchivist>
- ytdl-sub (alt): <https://github.com/jmbannon/ytdl-sub>
- TubeSync (alt): <https://github.com/meeb/tubesync>
