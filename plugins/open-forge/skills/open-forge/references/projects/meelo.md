---
name: Meelo
description: "Self-hosted music server for collectors. Docker. NestJS + PostgreSQL + Prisma. Arthi-chaud/Meelo. Music videos as first-class, B-sides/rare tracks, album releases/tracks/versions, transcoding, MusicBrainz/LastFM/ListenBrainz, Android app."
---

# Meelo

**Self-hosted music server designed for music collectors.** Think Plex/Jellyfin for music, but built specifically around the needs of collectors: music videos as first-class citizens, B-side detection, rare track tagging, album releases (multiple versions of the same album), automatic featuring/duet detection, song versions, and flexible metadata parsing. Scrobbles to LastFM and ListenBrainz.

Built + maintained by **Arthi-chaud**. See repo license.

- Upstream repo: <https://github.com/Arthi-chaud/Meelo>
- Wiki + setup: <https://github.com/Arthi-chaud/Meelo/wiki>
- Android app: APK on GitHub Releases
- Docker Hub: <https://hub.docker.com/u/arthichaud> (check repo for current image names)

## Architecture in one minute

- **NestJS** (Node.js/TypeScript) backend
- **PostgreSQL** + Prisma ORM
- **React** (Next.js) web frontend
- Transcoding via ffmpeg (for unsupported audio/video formats)
- Metadata providers: **MusicBrainz**, **Genius**, **Wikipedia**, Discogs, AcousticBrainz, and others
- Scrobbling: **LastFM** + **ListenBrainz**
- Android app (APK); iOS alpha in testing
- Resource: **medium** — NestJS + PostgreSQL + transcoding

## Compatible install methods

| Infra              | Runtime         | Notes                                                          |
| ------------------ | --------------- | -------------------------------------------------------------- |
| **Docker Compose** | official images | **Primary** — follow the wiki for current compose setup        |

Full setup wiki: <https://github.com/Arthi-chaud/Meelo/wiki>

> You'll need a well-organized music library: either embedded metadata (ID3/Vorbis) or a standard folder structure. Tools like **beets** or **iTunes** are recommended for library cleanup before import.

## Install

1. Follow the wiki: <https://github.com/Arthi-chaud/Meelo/wiki>
2. Clone the repo or download the compose file.
3. Configure `.env` with DB credentials, music path, and provider API keys.
4. `docker compose up -d`.
5. First scan: trigger a library scan in the web UI.

## What makes Meelo different for collectors

| Concept | Description |
|---------|-------------|
| **Music Videos** | First-class entities; accessible from album/artist/song pages; distinguishes from interviews, BTS, trailers |
| **B-sides** | Automatically identified and shown on the album page |
| **Rare tracks** | Shown on the artist page so they're not lost in a large library |
| **Album releases** | Multiple physical/digital versions of the same album; main version shown in browsing; others accessible |
| **Tracks** | A song can appear on multiple albums; no duplicated songs in browsing |
| **Song versions** | (e.g. radio edit vs album version vs live) — grouped under the same song |
| **Album/Song types** | Types like live, instrumental, remix — easily filterable |
| **Compilation filter** | Filter songs exclusive to compilation albums |
| **Featuring/Duet detection** | Automatic parsing of "feat." and "&" in track titles |

## Metadata providers

| Provider | Used for |
|----------|---------|
| MusicBrainz | Artist/album/track IDs, release info |
| Genius | Lyrics, song descriptions |
| Wikipedia | Artist/album descriptions, biographies |
| Discogs | Catalog info, release details |
| AcousticBrainz | Audio features |

All metadata is fetched automatically during library scanning.

## Scrobbling

- **LastFM**: configure LastFM API key; listens scrobble automatically
- **ListenBrainz**: configure user token; scrobbles automatically

## Supported formats

All audio and video formats (virtually) supported via transcoding (ffmpeg). Transcoding is only triggered when the format isn't natively supported by the browser.

## Synced lyrics

- Download synced (karaoke-style) LRC lyrics from providers
- Reads `.lrc` files alongside audio files
- Reads embedded lyrics from file metadata

## Gotchas

- **Library must be organized before import.** Meelo requires either embedded metadata (ID3/Vorbis tags) or a standard folder structure to parse correctly. A messy library with wrong/missing tags will import poorly. Run beets or a tag editor first.
- **Requires some regex knowledge.** The wiki notes "you might need to know a bit about Regexes" — some metadata parsing configurations use regex patterns. Basic regex skills help for custom setups.
- **Multiple Docker images.** Meelo has separate images for the backend API, web frontend, and worker. Check the wiki for the current compose file — it's the authoritative source for which images and versions to use.
- **PostgreSQL required.** No SQLite option — use PostgreSQL.
- **Music videos need proper file naming.** For Meelo to correctly identify a file as a music video vs a studio track, naming conventions matter. See the wiki for the recommended file naming format.
- **Album releases vs. albums.** The concept of "releases" is central to Meelo's design. One "album" (the abstract concept) has multiple "releases" (the physical/digital editions). This is more complex than most music servers but accurately models a collector's library.
- **Android APK, not Play Store.** The Android app is distributed as an APK via GitHub Releases — sideloading required.
- **iOS alpha.** An iOS alpha is available for testers; join the discussion on GitHub.

## Backup

```sh
docker compose stop
docker compose exec postgres pg_dump -U meelo meelo > meelo-$(date +%F).sql
# music files are your source; back up Meelo's DB + uploads folder
docker compose start
```

## Upgrade

```sh
docker compose pull && docker compose up -d
```

## Project health

Active NestJS development, Android app (alpha iOS), MusicBrainz/Genius/Wikipedia providers, LastFM + ListenBrainz scrobbling, wiki docs. Solo-maintained by Arthi-chaud.

## Music-server-family comparison

- **Meelo** — NestJS, collector-focused, music videos, B-sides, releases/tracks/versions, MusicBrainz, scrobbling
- **Navidrome** — Go, Subsonic API, lean, fast, great for simple libraries; no collector-specific features
- **Jellyfin** — media server with music library; no collector-specific curation
- **Beets** — Python, music library tagger/organizer; pairs well with Meelo for pre-import cleanup
- **Funkwhale** — Python, ActivityPub federated music; different focus

**Choose Meelo if:** you're a music collector who wants a server that understands B-sides, rare tracks, album releases, music videos, and song versions — not just a flat file browser.

## Links

- Repo: <https://github.com/Arthi-chaud/Meelo>
- Wiki: <https://github.com/Arthi-chaud/Meelo/wiki>
- Android APK: GitHub Releases
