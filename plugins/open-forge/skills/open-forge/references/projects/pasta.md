---
name: pasta-project
description: PASTA recipe for open-forge. Audio and Subtitle Track Changer for Plex. Web UI to view detailed audio/subtitle track info and bulk-set tracks for entire shows or single episodes. Runs client-side (no server-side data handling). Single container. Upstream: https://github.com/cglatot/pasta
---

# PASTA

**P**lex **A**udio and **S**ubtitle **T**rack **A**utomator. A web UI for viewing detailed audio and subtitle track info from your Plex library and bulk-setting tracks for entire shows or single episodes — without doing it episode by episode.

Runs entirely client-side: your browser talks directly to your Plex server. No data passes through the PASTA container itself. Also available as a hosted service at <https://pasta.cglatot.com> (no self-hosting required if you prefer).

Upstream: <https://github.com/cglatot/pasta> | Hosted: <https://pasta.cglatot.com>

Single container. AMD64 native; ARM64 via manual build.

## Compatible combos

| Infra | Notes |
|---|---|
| Any Linux host | Single container; nginx serving static files |
| ARM (Raspberry Pi etc.) | Build from source — see ARM section |
| No Docker | Use hosted version at pasta.cglatot.com |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Host port?" | Default: `8087` |

No other configuration required — all Plex connection details are entered in the browser UI at runtime.

## Software-layer concerns

### Image

```
cglatot/pasta:latest
```

Docker Hub: <https://hub.docker.com/r/cglatot/pasta>

### Compose

```yaml
services:
  pasta:
    image: cglatot/pasta
    container_name: pasta
    ports:
      - "8087:80"
    restart: unless-stopped
```

> Source: upstream README — <https://github.com/cglatot/pasta>

No volumes needed — all state is in the browser session; nothing is persisted server-side.

### ARM (Raspberry Pi and other ARM devices)

No prebuilt ARM image on Docker Hub. Build from source:

```bash
git clone https://github.com/cglatot/pasta
cd pasta
docker buildx build -t "cglatot/pasta:latest" --platform linux/arm64 .
# Then use the compose above
docker compose up -d
```

### How it works

1. Open PASTA in your browser (`http://host:8087`)
2. Enter your Plex server URL and Plex token
3. Browse your libraries; PASTA shows detailed track info (codec, language, forced/default flags, track name, etc.)
4. Select the audio or subtitle track you want for a show → apply to all episodes or a single one

All API calls go from your browser → Plex directly. PASTA itself is just a static web app served by nginx.

> **Tip:** Works fastest when your browser is on the same network as the Plex server (avoids going out and back through the internet).

### Getting your Plex token

1. In Plex Web, play any media item
2. Open browser DevTools → Network tab → filter for `X-Plex-Token`
3. Or: Settings → Account → click your username → "Get token" in the URL
4. Or: see [official Plex docs](https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/)

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No persistent data to migrate.

## Gotchas

- **Client-side only** — PASTA does not proxy or store your Plex credentials. Your Plex token is only used in browser memory and sent directly from your browser to Plex. Still: don't expose PASTA publicly without access control if you're concerned about someone entering their Plex token on your instance.
- **No prebuilt ARM image** — `cglatot/pasta` on Docker Hub is AMD64 only. ARM users must build from source (see above).
- **Plex server must be reachable from your browser** — if your Plex server is on a private LAN and you're accessing PASTA remotely, direct Plex API calls from your browser will fail. Use a VPN or ensure Plex remote access is enabled.
- **Track names may look identical** — PASTA shows extended track metadata (codec, channel layout, bitrate) that Plex's standard UI hides, which is how you distinguish between two tracks both labeled "English (SRT)".
- **No authentication on PASTA itself** — the container is just nginx serving static files. Add a reverse proxy with auth if you want to restrict access.

## Links

- Upstream README: <https://github.com/cglatot/pasta>
- Docker Hub: <https://hub.docker.com/r/cglatot/pasta>
- Hosted version: <https://pasta.cglatot.com>
- Plex token guide: <https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/>
