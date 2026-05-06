---
name: mpd-project
description: MPD (Music Player Daemon) recipe for open-forge. Covers the flexible server-side music player daemon. Upstream: https://github.com/MusicPlayerDaemon/MPD. Manual: https://mpd.readthedocs.io/en/stable/user.html
---

# MPD — Music Player Daemon

Flexible, powerful, server-side application for playing music of various formats. MPD stores a database of all available music; playback, playlist management, and info retrieval are controlled remotely via its network protocol. Upstream: <https://github.com/MusicPlayerDaemon/MPD>. Manual: <https://mpd.readthedocs.io/en/stable/user.html>.

> **License:** GPL-2.0.

MPD itself is a daemon listening for client connections (default port `6600`). Clients (command-line tools like `mpc`, GUI clients like Cantata, ncmpcpp, etc.) connect to it over TCP. MPD plays audio through the server's audio hardware.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| apt package (Debian/Ubuntu) | https://mpd.readthedocs.io/en/stable/user.html | ✅ | Easiest path on Debian/Ubuntu |
| Source compile (Meson/Ninja) | https://mpd.readthedocs.io/en/stable/user.html | ✅ | Latest version; distro packages often outdated |
| Android (Google Play) | https://mpd.readthedocs.io/en/stable/user.html | ✅ | Experimental Android build |

> **Note:** Upstream explicitly warns that Debian/Ubuntu stable packages are heavily outdated. For current features, compile from source or use Debian unstable/sid packages.

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | "Install method?" | Options: apt / source-compile | Drives path |
| music | "Where is your music library?" | Directory path | All — becomes music_directory in mpd.conf |
| audio | "Audio output type?" | Options: alsa / pulseaudio / pipewire / null | All |
| network | "Bind MPD to which address?" | IP or `any` | All — default binds to all interfaces on port 6600 |
| user | "Run MPD as system daemon or user daemon?" | Options: system / user | Affects config path and service management |

## Software-layer concerns

### Config file locations

| Run mode | Config path |
|---|---|
| System daemon | /etc/mpd.conf |
| User daemon (XDG) | ~/.config/mpd/mpd.conf |
| Android | mpd.conf in top-level data partition directory |

### Key mpd.conf settings

```
music_directory   "~/Music"         # path to music library
db_file           "~/.config/mpd/database"
log_file          "~/.config/mpd/log"
pid_file          "~/.config/mpd/pid"
state_file        "~/.config/mpd/state"
sticker_database  "~/.config/mpd/sticker.db"

bind_to_address   "any"
port              "6600"

audio_output {
    type  "alsa"
    name  "My ALSA Output"
}
```

See /usr/share/doc/mpd/html or the upstream manual for the full reference of all settings and output plugins.

### Data directories

| Data | Default path |
|---|---|
| Music library | Configured via music_directory |
| Database | Configured via db_file |
| Playlists | Configured via playlist_directory |
| State file | Configured via state_file |

### Install via apt (Debian/Ubuntu)

```bash
apt install mpd
# Default music dir after apt install: /var/lib/mpd/music/
# Config: /etc/mpd.conf — edit music_directory to match your library
systemctl enable mpd
systemctl start mpd
```

### Compile from source

```bash
# Install build dependencies (Debian Trixie example — see user manual for full list)
apt install meson g++ pkgconf \
  libfmt-dev libpcre2-dev \
  libmad0-dev libmpg123-dev libid3tag0-dev \
  libflac-dev libvorbis-dev libopus-dev libogg-dev \
  libavcodec-dev libavformat-dev \
  libasound2-dev libpulse-dev \
  libsqlite3-dev libicu-dev

# Get source
curl -O https://www.musicpd.org/download.html  # or clone git repo
tar xf mpd-<version>.tar.xz
cd mpd-<version>

# Build
meson setup --buildtype=release build
ninja -C build
ninja -C build install
```

### User daemon (systemd user service)

```bash
systemctl --user enable mpd
systemctl --user start mpd
```

## Upgrade procedure

### apt

```bash
apt update && apt upgrade mpd
```

### Source

```bash
# Re-compile from new tarball or git pull
git pull
meson setup --buildtype=release build --reconfigure
ninja -C build
ninja -C build install
systemctl restart mpd
```

## Gotchas

- **Distro packages are often very outdated.** Upstream explicitly notes Debian/Ubuntu stable ships old MPD versions. If you need recent features or bug fixes, compile from source or use Debian unstable.
- **music_directory must be readable by the mpd user.** If running as a system daemon (user `mpd`), the music directory must be accessible by that user. chmod/chown accordingly, or run MPD as your own user.
- **Android output is limited.** On Android, only the OpenSL ES output plugin is available; ALSA is not.
- **Port 6600 is open by default.** If you bind to `any`, MPD accepts connections from all network interfaces. Restrict with bind_to_address or a firewall rule if running on a networked server.
- **Database must be updated after adding music.** After adding files to music_directory, send `mpc update` or trigger an update via any MPD client.
- **Playlist directory must exist.** MPD does not create it automatically; create it before starting MPD.

## Upstream docs

- User manual: https://mpd.readthedocs.io/en/stable/user.html
- Protocol spec: https://mpd.readthedocs.io/en/latest/protocol.html
- GitHub README: https://github.com/MusicPlayerDaemon/MPD
- Forum/discussions: https://github.com/MusicPlayerDaemon/MPD/discussions
