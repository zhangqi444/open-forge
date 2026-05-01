---
name: WatchState
description: "Sync play state across Jellyfin, Plex, and Emby without third-party services. Docker. PHP. arabcoders/watchstate. Webhooks, import/export, parity checks, progress sync, multi-user identities."
---

# WatchState

**Sync your media server play state across Jellyfin, Plex, and Emby without third-party services.** WatchState is a self-hosted daemon that keeps watch-status in sync across all your media backends — many-to-many or one-way. Webhook receiver, scheduled sync tasks, backup/restore in portable format, un-matched item finder, metadata search, parity checks, and playlist sync (beta). MIT license.

Built + maintained by **arabcoders**. Also makes YTPTube (yt-dlp frontend).

- Upstream repo: <https://github.com/arabcoders/watchstate>
- Docs: <https://github.com/arabcoders/watchstate/tree/master/guides>
- GHCR: `ghcr.io/arabcoders/watchstate`
- Docker Hub: `arabcoders/watchstate`
- Unraid: Community App + YouTube guide

## Architecture in one minute

- **PHP** daemon + web UI
- Port **8080** (configurable)
- Persistent data in `./data:/config` volume
- Supports **Jellyfin, Plex, Emby** media servers
- Multi-user via **identities** (different users on the same backend)
- Webhooks receiver: media servers push events to WatchState on play/stop/scrobble
- Scheduled tasks: periodic sync when webhooks aren't available
- Resource: **low** — PHP process, infrequent DB writes

## Compatible install methods

| Infra            | Runtime                               | Notes                                                   |
| ---------------- | ------------------------------------- | ------------------------------------------------------- |
| **Docker Compose** | `ghcr.io/arabcoders/watchstate`     | **Primary** — one compose file, one `data/` directory   |
| **Unraid**       | Community App                         | Video guide by AlienTech42 on YouTube                   |

## Install via Docker Compose

```yaml
services:
    watchstate:
        image: ghcr.io/arabcoders/watchstate:latest
        user: "${UID:-1000}:${UID:-1000}"
        container_name: watchstate
        restart: unless-stopped
        ports:
            - "8080:8080"
        volumes:
            - ./data:/config:rw
```

```bash
mkdir -p ./data && docker compose up -d
```

Visit `http://localhost:8080`.

## First boot

1. Deploy container.
2. Visit `http://localhost:8080` → WatchState web UI.
3. **Add backends** (Settings → Backends):
   - Jellyfin: URL + API key
   - Plex: URL + token (copy from Plex settings)
   - Emby: URL + API key
4. Set up **sync direction** per backend (import, export, or both).
5. **Configure webhooks** in each media server pointing to `http://watchstate:8080/webhook`:
   - Jellyfin: Admin → Plugins → Webhooks
   - Plex: Settings → Webhooks (Plex Pass required for webhooks)
   - Emby: Dashboard → Notifications → Webhooks
6. Run an **initial import** (Tasks → Import) to seed WatchState's database.
7. Play an item in Jellyfin/Plex/Emby → verify the webhook fires and syncs to other backends.
8. Configure scheduled **export** tasks for backends that don't support webhooks reliably.

## Key features

| Feature | Description |
|---------|-------------|
| Play state sync | Mark as watched in Jellyfin → auto-marked in Plex + Emby |
| Webhooks | Real-time sync when you play/pause/finish items |
| Scheduled tasks | Catch anything webhooks miss; configurable interval |
| Import/Export | One-way or bidirectional per backend |
| Portable backup | Export watch state to a format importable elsewhere |
| Un-matched items | Find media your backends don't recognize |
| Parity checks | Verify all backends agree on the same data |
| Progress sync | Sync resume position (webhook or scheduled) |
| Playlist sync | Beta: cross-backend playlist sync |
| Multi-user | Identities for different users on the same backend |
| Metadata search | Search your backends' metadata from WatchState UI |

## Backup

```sh
docker compose stop watchstate
sudo tar czf watchstate-$(date +%F).tgz data/
docker compose start watchstate
```

WatchState's portable export (via the web UI) creates an importable file you can restore into a fresh instance.

## Upgrade

1. Releases: <https://github.com/arabcoders/watchstate/releases>
2. `docker compose pull && docker compose up -d`
3. WatchState runs any needed DB migrations on startup.

## Gotchas

- **Webhook URL is per-backend — copy it from the Backends page.** The upstream README video correction: don't guess the webhook URL — WatchState shows the exact URL for each backend in the web UI → Backends. Use that.
- **Plex webhooks require Plex Pass.** Plex's webhook feature is a Plex Pass (paid subscription) feature. Without it, you can only use scheduled polling for Plex sync — real-time webhook sync isn't available.
- **Multi-user via identities.** WatchState supports syncing multiple users' play state. Each user = an "identity" in WatchState settings. Useful for family Plex/Jellyfin accounts.
- **UID/GID must match `./data` directory ownership.** The compose file uses `user: "${UID:-1000}:${UID:-1000}"` — the container runs as your user. If `./data/` is owned by root or a different UID, the container will fail to write. Run `mkdir -p ./data && chown 1000:1000 ./data` if needed.
- **Initial import can be slow.** Seeding WatchState's database from large Plex/Jellyfin/Emby libraries can take a while on first run. Let it complete before testing sync.
- **Playlist sync is beta (2026-04-26).** Cross-backend playlist behavior differs between Plex, Jellyfin, and Emby — the feature may change or be removed. Enable in Tasks → Playlist. Not for production reliance yet.
- **Plex external invited users.** As of 2026-04-23, Plex re-enabled API access for invited users after briefly breaking it. This may change again at Plex's discretion.
- **WatchState syncs watch state, not metadata.** It doesn't move media files, rename them, or fix metadata. It only syncs "have I watched this?" (and progress position). Use Jellyseerr/Sonarr/Radarr for everything else.

## Project health

Active PHP development, GHCR + Docker Hub, Unraid CA, community YouTube guides, webhook support, playlist beta feature. Solo-maintained by arabcoders. MIT license.

## Watch-state-sync-family comparison

- **WatchState** — PHP, Jellyfin + Plex + Emby, webhooks + scheduled, multi-user identities, MIT
- **Jellyfin-Plex-Sync** — older scripts; less maintained
- **Trakt** — SaaS scrobbling service; 3rd-party dependency; works across many apps
- **Infuse** — iOS/Apple TV player that syncs across devices; partial overlap

**Choose WatchState if:** you want self-hosted play-state sync across Jellyfin, Plex, and/or Emby without depending on a third-party service like Trakt.

## Links

- Repo: <https://github.com/arabcoders/watchstate>
- GHCR: `ghcr.io/arabcoders/watchstate`
- Guides: <https://github.com/arabcoders/watchstate/tree/master/guides>
- YTPTube (same author): <https://github.com/arabcoders/ytptube>
