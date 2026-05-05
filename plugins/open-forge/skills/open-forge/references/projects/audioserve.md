---
name: audioserve
description: Audioserve recipe for open-forge. Simple personal audio server for audiobooks, music, and podcasts. Serves files from directories with playback position sync. Single binary written in Rust. Upstream: https://github.com/izderadicka/audioserve
---

# Audioserve

Simple personal server for streaming audio files from your filesystem. Designed primarily for audiobooks but works for any organised audio directory. Key feature: syncs play position between clients. Single Rust binary — minimal resource usage. Upstream: <https://github.com/izderadicka/audioserve> — MIT.

Clients: PWA web client (built-in), Android client, any HTTP client. No desktop GUI — web-first.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://github.com/izderadicka/audioserve#docker> | Yes | Recommended. Simple single-container setup. |
| Binary (direct) | <https://github.com/izderadicka/audioserve/releases> | Yes | Bare-metal. Download pre-built binary, point at audio dir. |
| Build from source | <https://github.com/izderadicka/audioserve#compilation> | Yes | Custom feature flags or unsupported platforms. Requires Rust + ffmpeg. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| auth | Shared secret for client access | Sensitive | All — passed as `--shared-secret` or env var |
| storage | Path to audio library root directory | Free-text | All |
| port | HTTP port (default: 3000) | Free-text | All |
| transcoding | Enable transcoding? (requires ffmpeg in container) | Yes/No | Optional — for format conversion and bitrate control |

## Docker Compose method

```yaml
version: "3.8"

services:
  audioserve:
    image: izderadicka/audioserve:latest
    container_name: audioserve
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - /path/to/audiobooks:/audiobooks:ro
      - /path/to/podcasts:/podcasts:ro
      - audioserve_data:/home/audioserve/.audioserve
    environment:
      - AUDIOSERVE_SHARED_SECRET=REPLACE_WITH_SECRET
    command: >
      --shared-secret env:AUDIOSERVE_SHARED_SECRET
      --data-dir /home/audioserve/.audioserve
      /audiobooks
      /podcasts

volumes:
  audioserve_data:
```

Access: `http://<host>:3000`

When prompted for the password in the web client, enter the value of `AUDIOSERVE_SHARED_SECRET`.

## Multiple collections

Audioserve supports multiple root directories (each becomes a separate "collection"):

```bash
# Pass multiple paths as positional arguments:
audioserve [options] /audiobooks /podcasts /music
```

In Docker Compose, mount each directory and list them all in the `command`.

## Key options

| Flag | Purpose |
|---|---|
| `--shared-secret <secret>` | Client access password |
| `--port <N>` | HTTP listen port (default 3000) |
| `--no-dir-collapsing` | Disable single-subfolder collapsing |
| `--allow-symlinks` | Follow symlinks in audio directories |
| `--max-transcodings <N>` | Limit concurrent transcoding jobs |
| `--positions-backup-schedule` | Cron schedule for play-position backups |
| `--url-path-prefix <path>` | Serve under a URL prefix (behind reverse proxy) |
| `--ssl-key` / `--ssl-cert` | Direct TLS (or use reverse proxy) |

Full options: `audioserve --help` or <https://github.com/izderadicka/audioserve#command-line-options>

## Playback position sync

Audioserve stores per-file play positions on the server and syncs them to clients. Works between the web app, Android client, and any client using the API. Position data is stored in the `--data-dir` path.

## Apple (iOS/macOS) compatibility

Apple devices require specific transcoding configuration for formats other than AAC/MP3. See upstream: <https://github.com/izderadicka/audioserve#alternative-transcodings-and-transcoding-configuration-for-apple-users>

## Security best practices

From upstream: do not expose Audioserve directly on the internet without a reverse proxy and strong shared secret. Recommended setup:
1. Run behind Nginx/Caddy with HTTPS
2. Set a long random shared secret
3. Consider IP allowlisting if personal use only

## Upgrade procedure

```bash
docker compose pull audioserve
docker compose up -d audioserve
```

For binary installs: download the new release binary and restart the service.

## Gotchas

- **Shared secret is the only authentication.** Anyone with the secret gets full access to all audio collections. Use a strong random secret and keep it private.
- **Audio files are served from the mounted directories.** The directory structure becomes the navigation tree in the UI. Organise files into sensible subdirectories before mounting.
- **Transcoding requires ffmpeg.** The default Docker image includes ffmpeg. For binary installs, ffmpeg must be installed separately on the host if transcoding is needed.
- **No user accounts.** All clients share one secret — no per-user access control or listening history.
- **Position sync only works with the built-in clients.** Third-party players (VLC, etc.) won't sync position back to the server.

## Upstream docs

- GitHub: <https://github.com/izderadicka/audioserve>
- Deploy guide: <https://github.com/izderadicka/audioserve/blob/master/docs/deploy.md>
- API docs: <https://github.com/izderadicka/audioserve/blob/master/docs/api.md>
- Docker Hub: <https://hub.docker.com/r/izderadicka/audioserve>
