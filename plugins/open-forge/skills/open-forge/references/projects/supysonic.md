---
name: supysonic
description: Supysonic recipe for open-forge. Python implementation of the Subsonic server API. Stream your music library to any Subsonic-compatible client. Supports transcoding, scrobbling, playlists, cover art, jukebox. Python + pip or .deb. Source: https://github.com/spl0k/supysonic
---

# Supysonic

Python implementation of the Subsonic server API (v1.12.0). Serve your personal music library to any Subsonic-compatible client (DSub, Ultrasonic, Symfonium, Navidrome-compatible apps, etc.). Supports browsing by folder or tags, streaming, transcoding, playlists, cover art, starred tracks/albums, ratings, Last.fm and ListenBrainz scrobbling, jukebox mode, and background library watching. AGPL-3.0 licensed.

Upstream: <https://github.com/spl0k/supysonic> | Docs: <https://supysonic.readthedocs.io>

## Compatible combos

| Infra | Runtime | Notes |
|---|---|---|
| Linux | pip + gunicorn | Recommended |
| Debian/Ubuntu | .deb package | Available |
| Any | Community Docker image | No official image; community images on Docker Hub |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| config | Music library path | Directory with your music files |
| config | Admin username | Created via CLI |
| config | Database | SQLite (default) or PostgreSQL |
| config | Port | Default: 5722 |
| config (optional) | Last.fm API key + secret | For scrobbling |
| config (optional) | ListenBrainz user token | For scrobbling |
| config (optional) | Transcoding tools | e.g. ffmpeg — for format conversion |

## Software-layer concerns

### Config file (`~/.config/supysonic/supysonic.conf`)

```ini
[base]
# SQLite (default)
database_uri = sqlite:////var/supysonic/supysonic.db

# PostgreSQL alternative:
# database_uri = postgresql://supysonic:yourpassword@localhost/supysonic

[webapp]
secret_key = your-random-secret-key
log_file = /var/supysonic/supysonic.log
log_level = WARNING

[daemon]
log_file = /var/supysonic/daemon.log
log_level = WARNING

[lastfm]
# api_key = your-lastfm-api-key
# secret = your-lastfm-secret

[listenbrainz]
# user_token = your-listenbrainz-token
```

### Transcoding

Supysonic supports transcoding via external tools. Configure in `[transcoding]` config section. ffmpeg is the most common choice.

## Install — pip + gunicorn

```bash
# Install
pip install supysonic gunicorn

# Create admin user
supysonic-cli user add admin
supysonic-cli user setroles --admin admin

# Add music library
supysonic-cli folder add MyLibrary /path/to/music

# Scan library
supysonic-cli folder scan MyLibrary

# Run server on port 5722
supysonic-server
# Or: gunicorn supysonic.web:create_application() -b 0.0.0.0:5722
```

Connect any Subsonic client to http://yourserver:5722 (username: admin, password set during `user add`).

## Install — .deb (Debian/Ubuntu)

```bash
# Download from: https://github.com/spl0k/supysonic/releases
# Then:
sudo dpkg -i supysonic_*.deb
sudo systemctl enable --now supysonic
```

## Daemon (background library watching)

```bash
# Start daemon for background library scans + jukebox
supysonic-daemon start

# Or via systemd (if using .deb install)
sudo systemctl enable --now supysonic-daemon
```

## Upgrade procedure

```bash
pip install --upgrade supysonic
supysonic-server  # restart
```

## Gotchas

- No official Docker image — community images exist on Docker Hub; check their readmes for configuration details.
- The `supysonic-cli folder scan` command must be run after initial setup and after adding new music. The daemon can watch for changes automatically.
- SQLite is fine for personal use; use PostgreSQL for better concurrent access and large libraries.
- Transcoding requires external binaries (e.g. ffmpeg) installed on the system and configured in `supysonic.conf` — without transcoding config, clients requesting format conversion will get errors.
- Default port 5722 — choose this when connecting Subsonic clients and ensure the firewall allows it.

## Links

- Source: https://github.com/spl0k/supysonic
- Documentation: https://supysonic.readthedocs.io
- Setup guide: https://supysonic.readthedocs.io/en/latest/setup/index.html
- Subsonic API clients: https://www.subsonic.org/pages/apps.jsp
