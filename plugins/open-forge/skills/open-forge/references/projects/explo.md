---
name: Explo
description: "Self-hosted music discovery tool for self-hosted music systems. Docker/binary. Go. LumePart/Explo. ListenBrainz recommendations, YouTube/Soulseek download, Navidrome/Jellyfin/Plex playlist creation."
---

# Explo

**Self-hosted Discover Weekly for your music server.** Explo uses your ListenBrainz listening history to fetch personalised music recommendations, downloads the tracks (from YouTube or Soulseek), and creates playlists in your self-hosted music system (Navidrome, Jellyfin, Plex, and more). Bridges music discovery with a self-hosted media library.

Built + maintained by **LumePart**. See repo license.

- Upstream repo: <https://github.com/LumePart/Explo>
- Wiki / docs: <https://github.com/LumePart/Explo/wiki>

## Architecture in one minute

- **Go** binary (or Docker container)
- **ListenBrainz** API for personalised recommendations (Weekly Exploration, Weekly Jams, Daily Jams)
- **yt-dlp** / YouTube for track downloads (via goutubedl Go wrapper)
- **Soulseek** as an alternative download source
- **ffmpeg** for post-processing audio metadata
- Writes downloaded tracks to a configured music directory
- Creates playlists in your music system via API
- No persistent database — stateless; runs as cron/scheduled task
- Resource: **low** — Go binary; bandwidth/disk bound during downloads

## Compatible install methods

| Infra       | Runtime          | Notes                                     |
| ----------- | ---------------- | ----------------------------------------- |
| **Docker**  | see repo         | Containerised; mount music library volume |
| **Binary**  | GitHub Releases  | Go binary; run directly or via cron       |

## Inputs to collect

| Input                         | Example                              | Phase    | Notes                                                                            |
| ----------------------------- | ------------------------------------ | -------- | -------------------------------------------------------------------------------- |
| ListenBrainz username         | your ListenBrainz account name       | Auth     | Required — used to fetch your recommendation playlists                          |
| ListenBrainz token            | from listenbrainz.org/profile/       | Auth     | API token for ListenBrainz                                                      |
| Music system type + URL       | Navidrome / Jellyfin / Plex URL      | Integrate| For playlist creation in your music server                                       |
| Music system API key / token  | server API key                       | Auth     | For playlist creation API calls                                                  |
| Music library path            | `/music`                             | Storage  | Where Explo downloads tracks (must be accessible to your music server)           |
| Download source               | `youtube` / `soulseek` / both        | Config   | Which source(s) to use for downloading tracks                                   |

## Install

Refer to the Getting Started wiki: <https://github.com/LumePart/Explo/wiki/2.-Getting-Started>

General pattern:
```bash
# Configure .env or config flags
# Set LISTENBRAINZ_USER, LISTENBRAINZ_TOKEN, MUSIC_DIR, MUSIC_SERVER_*, SOURCE, etc.

# Run (one-shot; schedule with cron or systemd timer)
./explo   # or: docker run --env-file .env -v /music:/music explo
```

## How it works

1. **Fetch** — Explo calls ListenBrainz's recommendation API for your account:
   - Weekly Exploration (new discoveries)
   - Weekly Jams (tracks you'd like more of)
   - Daily Jams (daily personalised picks)
2. **Download** — For each recommended track, download from YouTube (via yt-dlp) or Soulseek
3. **Tag** — Add ID3/metadata (title, artist, album) to YouTube downloads via ffmpeg
4. **Library** — Files land in your configured music directory (accessible to your music server)
5. **Playlist** — Explo calls your music server's API to create a playlist of the new tracks
6. **Listen** — Open your music server → find the Explo-generated playlist → enjoy

## Supported music systems

Check the [System Notes wiki](https://github.com/LumePart/Explo/wiki/4.-System-Notes) for the current list. Typically includes:
- Navidrome
- Jellyfin
- Plex
- Subsonic-compatible servers

## Configuration parameters

See the full reference: <https://github.com/LumePart/Explo/wiki/3.-Configuration-Parameters>

Key parameters include: ListenBrainz credentials, download source, music directory, music server URL + credentials, playlist type (weekly/daily), and more.

## Gotchas

- **ListenBrainz account and scrobbling history required.** ListenBrainz recommendations are based on your listening history. If you're a new user with few scrobbles, recommendations will be sparse. Scrobble from your music server (Navidrome + ListenBrainz plugin, Jellyfin Scrobbler, etc.) to build history.
- **yt-dlp must be available.** For YouTube downloads, yt-dlp must be installed and accessible in PATH (or included in Docker image). Keep yt-dlp updated — YouTube changes its API regularly, breaking older versions.
- **Soulseek requires a Soulseek account.** If using Soulseek as a download source, you need a Soulseek account. Quality and availability vary by track.
- **YouTube audio quality.** yt-dlp downloads the best available audio stream (typically 128–256 kbps AAC/Opus). For lossless, Soulseek may find better sources (FLAC, MP3 320) but is less reliable.
- **Music directory must be shared.** The download directory must be on a volume accessible to both Explo and your music server. Explo writes tracks; your music server scans and indexes them.
- **Run as cron/timer.** Explo is not a long-running daemon — it runs, fetches, downloads, creates playlist, and exits. Schedule it weekly (matching Discover Weekly cadence) or daily via cron or a systemd timer.
- **Copyright notice.** Downloading copyrighted music from YouTube or Soulseek may be illegal in your jurisdiction. Use responsibly and in accordance with local laws.

## Example cron schedule

```cron
# Run every Monday at 8 AM to fetch weekly recommendations
0 8 * * 1  /usr/local/bin/explo >> /var/log/explo.log 2>&1
```

## Project health

Active Go development, ListenBrainz + yt-dlp + Soulseek integration, multi-system playlist support. See repo for current status and license.

## Music-discovery-family comparison

- **Explo** — Go, ListenBrainz recs, YouTube + Soulseek download, Navidrome/Jellyfin/Plex playlists
- **Spotify Discover Weekly** — SaaS; the inspiration; not self-hosted
- **Beets** — Python, music library manager; no discovery/download
- **Lidarr** — C#, artist-based music acquisition from usenet/torrent; no recommendation engine
- **Maloja + ListenBrainz** — scrobbling + stats; no auto-download

**Choose Explo if:** you use ListenBrainz for music scrobbling and want automated Discover-Weekly-style recommendations downloaded into your self-hosted music library.

## Links

- Repo: <https://github.com/LumePart/Explo>
- Wiki (setup + config): <https://github.com/LumePart/Explo/wiki>
- ListenBrainz: <https://listenbrainz.org>
- yt-dlp: <https://github.com/yt-dlp/yt-dlp>
