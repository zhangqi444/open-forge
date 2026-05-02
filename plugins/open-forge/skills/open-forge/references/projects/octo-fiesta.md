---
name: octo-fiesta-project
description: Octo-Fiesta recipe for open-forge. Subsonic API proxy that transparently integrates Deezer, Qobuz, Yandex Music, and SquidWTF as on-demand music sources for Navidrome. Downloads missing tracks and adds them to your library. Upstream: https://github.com/V1ck3s/octo-fiesta
---

# Octo-Fiesta

A Subsonic API proxy server that sits between your Subsonic-compatible client and Navidrome. When a requested song isn't in your local library, Octo-Fiesta fetches it from a configured music streaming provider (Deezer, Qobuz, Yandex Music, or the no-credentials SquidWTF), downloads it with full metadata, and serves it seamlessly — then adds it to your library so future plays come from local storage.

Upstream: <https://github.com/V1ck3s/octo-fiesta>

Built with .NET 9 (backend). Requires a running Navidrome instance.

## Compatible combos

| Infra | Provider | Notes |
|---|---|---|
| Any Linux host with Navidrome | SquidWTF | No credentials needed; FLAC 24-bit quality |
| Any Linux host with Navidrome | Deezer | ARL token required; FLAC 16-bit max |
| Any Linux host with Navidrome | Qobuz | User ID + auth token required; FLAC 24-bit/192kHz |
| Any Linux host with Navidrome | Yandex Music | OAuth token required; FLAC 16-bit |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Navidrome URL?" | e.g. `http://navidrome:4533` |
| preflight | "Music provider?" | `SquidWTF` (no creds), `Deezer`, `Qobuz`, or `YandexMusic` |
| preflight | "Storage mode?" | `Permanent` (saved to Navidrome library) or `Cache` (temp, auto-deleted) |
| preflight | "Host path for downloaded songs?" | Bind-mounted as `/app/downloads`; must be Navidrome's music dir |
| config (Deezer) | "Deezer ARL token?" | From browser cookies after logging in; see wiki for instructions |
| config (Qobuz) | "Qobuz user ID and auth token?" | From browser network requests on play.qobuz.com |
| config (Yandex) | "Yandex Music OAuth token?" | From <https://oauth.yandex.ru/authorize?response_type=token&client_id=23cabbbdc6cd418abb4b39c32c41195d> |

## Software-layer concerns

### Image

```
ghcr.io/v1ck3s/octo-fiesta
```

No explicit tag in upstream compose — check releases for a pinnable version: <https://github.com/V1ck3s/octo-fiesta/releases>

### Setup overview

```
[Subsonic client] → [Octo-Fiesta :5274] → [Navidrome :4533]
                                        ↓ (on cache miss)
                              [Music provider API]
                                        ↓
                              /app/downloads → Navidrome music library
```

Point your Subsonic client at Octo-Fiesta's URL instead of Navidrome directly.

### Compose (SquidWTF — no credentials required)

```yaml
services:
  octo-fiesta:
    image: ghcr.io/v1ck3s/octo-fiesta
    container_name: octo-fiesta
    restart: unless-stopped
    ports:
      - "5274:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ASPNETCORE_URLS=http://+:8080
      - Library__DownloadPath=/app/downloads
      - Subsonic__Url=http://navidrome:4533
      - Subsonic__MusicService=SquidWTF
      - Subsonic__StorageMode=Permanent
    volumes:
      - /path/to/navidrome/music:/app/downloads   # must match Navidrome's music dir
```

> Source: upstream docker-compose.yml + .env.example — <https://github.com/V1ck3s/octo-fiesta>

### Compose (Deezer)

Add to the environment section:
```yaml
      - Subsonic__MusicService=Deezer
      - Deezer__Arl=your-deezer-arl-token
      - Deezer__ArlFallback=optional-fallback-arl
      # - Deezer__Quality=FLAC          # or MP3_320, MP3_128; default: highest available
```

### Compose (Qobuz)

```yaml
      - Subsonic__MusicService=Qobuz
      - Qobuz__UserAuthToken=your-qobuz-token
      - Qobuz__UserId=your-qobuz-user-id
      # - Qobuz__Quality=FLAC_24_HIGH   # FLAC / FLAC_24_HIGH / FLAC_24_LOW / FLAC_16 / MP3_320
```

### Compose (Yandex Music)

```yaml
      - Subsonic__MusicService=YandexMusic
      - YandexMusic__Token=your-oauth-token
```

### Key environment variables

| Variable | Default | Purpose |
|---|---|---|
| `Subsonic__Url` | `http://localhost:4533` | Navidrome/Subsonic server URL |
| `Subsonic__MusicService` | `SquidWTF` | Music provider: `SquidWTF`, `Deezer`, `Qobuz`, `YandexMusic` |
| `Subsonic__StorageMode` | `Permanent` | `Permanent` = save to library; `Cache` = temp files with TTL |
| `Subsonic__CacheDurationHours` | `1` | TTL for `Cache` mode (hours) |
| `Subsonic__DownloadMode` | `Track` | `Track` = download requested track only; `Album` = download full album |
| `Subsonic__EnableExternalPlaylists` | `true` | Enable playlist search/download from provider |
| `Subsonic__ExplicitFilter` | `All` | `All`, `ExplicitOnly`, or `CleanOnly` |
| `Subsonic__AutoUpgradeQuality` | `false` | Re-download existing tracks if higher quality becomes available |
| `Subsonic__FolderTemplate` | `{artist}/{album}/{track} - {title}` | Folder structure for downloads |
| `Library__DownloadPath` | `/app/downloads` | Download destination inside container |
| `ASPNETCORE_URLS` | `http://+:8080` | Internal listen address |

Folder template placeholders: `{artist}`, `{album}`, `{title}`, `{track}`, `{disc}`, `{year}`, `{genre}`, `{quality}`

### Storage modes

**Permanent:** Downloaded tracks are saved permanently to the Navidrome music library directory. Navidrome picks them up automatically (on next scan or watch trigger). Repeat plays come from local storage.

**Cache:** Tracks are served temporarily and deleted after `CacheDurationHours`. Nothing is added to the Navidrome library permanently. Useful for browsing without growing your library.

### Download path must match Navidrome's music library

The `/app/downloads` path inside the container must be the same directory Navidrome uses as its music library. Mount the same host path on both containers:

```yaml
# navidrome
volumes:
  - /data/music:/music

# octo-fiesta
volumes:
  - /data/music:/app/downloads
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

Downloads in the music library are unaffected. Database/state is stateless (Navidrome holds all library metadata).

## Gotchas

- **Download path must match Navidrome's music directory** — if they diverge, downloaded tracks appear on disk but Navidrome never sees them.
- **SquidWTF is a third-party service** — no credentials needed but availability depends on the external service being up. It uses Qobuz/Tidal backends; check its status page if downloads fail.
- **Deezer ARL tokens expire** — when they do, downloads silently fail. Renew by logging into Deezer in a browser and extracting the new `arl` cookie. Use `Deezer__ArlFallback` for redundancy.
- **Qobuz credentials are from browser network requests** — not from the Qobuz app; retrieve `userAuthToken` and `userId` from `play.qobuz.com` network traffic.
- **Point clients at Octo-Fiesta, not Navidrome** — the proxy is transparent, but if clients hit Navidrome directly they bypass the on-demand download logic.
- **`Album` download mode can be slow** — triggers a full album download when you play a single track. Only enable if you want full albums downloaded on first play.
- **Subsonic client compatibility** — some clients may not work correctly through the proxy; see the upstream wiki's [Compatible Clients](https://github.com/V1ck3s/octo-fiesta/wiki/Compatible-Clients) page for a tested list and known-incompatible clients.
- **Legal considerations** — Octo-Fiesta downloads from licensed streaming services. Ensure you have active subscriptions to any paid providers (Deezer, Qobuz, Yandex Music) you use.

## Links

- Upstream README + wiki: <https://github.com/V1ck3s/octo-fiesta>
- Getting Deezer ARL: <https://github.com/V1ck3s/octo-fiesta/wiki/Getting-Deezer-Credentials-(ARL-Token)>
- Getting Qobuz credentials: <https://github.com/V1ck3s/octo-fiesta/wiki/Getting-Qobuz-Credentials-(User-ID-&-Token)>
- Compatible clients: <https://github.com/V1ck3s/octo-fiesta/wiki/Compatible-Clients>
- Installation guide: <https://github.com/V1ck3s/octo-fiesta/wiki/Installation>
