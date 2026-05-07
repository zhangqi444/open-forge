---
name: icecast-2
description: Icecast 2 recipe for open-forge. Streaming audio/video server for Internet radio stations and live media. Supports Ogg/Vorbis, MP3, Opus, AAC, WebM. GPL-2.0, C. Source: https://gitlab.xiph.org/xiph/icecast-server
---

# Icecast 2

A free, open-source streaming media server supporting audio (Ogg/Vorbis, MP3, Opus, AAC, FLAC) and video (WebM, Ogg/Theora). Used for Internet radio stations, podcasting, live event streaming, and private jukeboxes. Listeners connect to a mountpoint URL; sources (DJ software, live encoders) push audio to the server. GPL-2.0 licensed, written in C. Website: <https://icecast.org/>. Source: <https://gitlab.xiph.org/xiph/icecast-server>

## Compatible Combos

| Infra | Runtime | Source client | Notes |
|---|---|---|---|
| Debian / Ubuntu | APT package | Butt, IceS, DarkIce, Mixxx, Liquidsoap | Most common setup |
| Docker | Docker image | Any Icecast-compatible source | Containerized option |
| Any Linux | Build from source | Any Icecast-compatible source | Latest features |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Domain or IP for listeners?" | FQDN / IP | Used in stream directory listings and player URLs |
| "Listen port?" | Number | Default 8000 |
| "Number of concurrent listeners?" | Count | Affects server sizing |
| "Source client?" | Butt / IceS / Liquidsoap / Mixxx / other | Software pushing audio to Icecast |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Stream format?" | MP3 / OGG / Opus / AAC | Depends on source client capability |
| "Mountpoint name?" | string | e.g. `/stream.ogg` or `/live.mp3` |
| "Max listeners per mountpoint?" | Number | -1 = unlimited |

## Software-Layer Concerns

- **Source + server model**: Icecast is the relay server — a separate source client (Butt, Liquidsoap, IceS, etc.) encodes and pushes audio to it. Icecast re-serves to listeners.
- **Mountpoints**: Each stream is a mountpoint (e.g. `/stream.ogg`). Multiple mountpoints can coexist on one server.
- **Config file**: `icecast.xml` — defines passwords, ports, mountpoints, limits, and directory listings.
- **Three passwords**: `source-password` (source clients connect with this), `relay-password` (for relay servers), `admin-password` (web admin panel at `/admin`).
- **Web admin**: Built-in web UI at `http://host:8000/admin` — shows listener counts, current track, source connections.
- **XSLT frontend**: Admin UI rendered via XSLT — templates in the `admin/` directory, customizable.
- **Shoutcast compatibility**: Icecast can accept Shoutcast/SHOUTcast source clients via the compat port.
- **Directory listing**: Icecast can register streams with Xiph's directory (dir.xiph.org) for public discovery.

## Deployment

### Debian/Ubuntu package

```bash
apt install icecast2

# Installer asks for hostname, passwords — configures /etc/icecast2/icecast.xml
# Manually edit if needed:
nano /etc/icecast2/icecast.xml

systemctl enable icecast2 && systemctl start icecast2
# Web admin: http://localhost:8000/admin
```

### Key `icecast.xml` settings

```xml
<icecast>
  <location>Earth</location>
  <admin>admin@example.com</admin>
  <limits>
    <clients>100</clients>
    <sources>2</sources>
    <burst-size>65536</burst-size>
  </limits>
  <authentication>
    <source-password>hackme</source-password>  <!-- CHANGE THIS -->
    <relay-password>hackme</relay-password>     <!-- CHANGE THIS -->
    <admin-user>admin</admin-user>
    <admin-password>hackme</admin-password>     <!-- CHANGE THIS -->
  </authentication>
  <hostname>radio.example.com</hostname>
  <listen-socket>
    <port>8000</port>
  </listen-socket>
  <paths>
    <logdir>/var/log/icecast2</logdir>
    <webroot>/usr/share/icecast2/web</webroot>
    <adminroot>/usr/share/icecast2/admin</adminroot>
  </paths>
  <logging>
    <accesslog>access.log</accesslog>
    <errorlog>error.log</errorlog>
    <loglevel>3</loglevel>
  </logging>
</icecast>
```

### Docker

```yaml
services:
  icecast:
    image: moul/icecast
    ports:
      - "8000:8000"
    volumes:
      - ./icecast.xml:/etc/icecast2/icecast.xml
    restart: unless-stopped
```

### NGINX reverse proxy (recommended for HTTPS)

```nginx
server {
    listen 443 ssl;
    server_name radio.example.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        # Important: disable buffering for streaming
        proxy_buffering off;
        proxy_cache off;
    }
}
```

### Source client example (Butt)

Configure Butt (Broadcast Using This Tool):
- Server: `radio.example.com` / Port: `8000`
- Password: (your `source-password`)
- Mount: `/stream.ogg`
- Format: OGG/Vorbis or MP3

## Upgrade Procedure

1. `apt update && apt upgrade icecast2` for package installs.
2. Backup `icecast.xml` before upgrading.
3. Check https://icecast.org/changelog/ for config format changes between versions.

## Gotchas

- **Change all three default passwords**: Source, relay, and admin passwords default to `hackme` — change before exposing to the internet.
- **Proxy buffering must be off**: NGINX/HAProxy must disable response buffering (`proxy_buffering off`) or audio streams will stall.
- **Source client required**: Icecast doesn't generate audio — you need a separate source client (Butt, Liquidsoap, IceS, Mixxx, etc.) to push audio to it.
- **Mountpoint in player URL**: Listeners must use the full URL including mountpoint, e.g. `https://radio.example.com/stream.ogg`.
- **Burst on connect**: Icecast buffers a burst of audio when a listener connects to reduce initial buffering. Set `<burst-size>` to suit your stream's bitrate.
- **Max clients per mountpoint**: Set `<max-listeners>` in mountpoint config to cap listener count and prevent bandwidth overload.

## Links

- Website: https://icecast.org/
- Documentation: https://icecast.org/docs/
- Source (GitLab): https://gitlab.xiph.org/xiph/icecast-server
- Source clients: https://icecast.org/apps/
- Changelog: https://icecast.org/changelog/
