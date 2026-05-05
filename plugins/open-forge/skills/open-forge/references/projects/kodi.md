---
name: Kodi
description: "Award-winning open-source home theater media center — play and organize video, audio, photos, and live TV across Android, Linux, macOS, Windows, iOS, and Raspberry Pi. C++. GPL-2.0."
---

# Kodi

Kodi (formerly XBMC) is a free, open-source media player and home theater software that runs on virtually every platform. It organizes your local media library (movies, TV shows, music, photos), plays virtually any media format, supports live TV and PVR, and is extensible through thousands of add-ons.

Maintained by the non-profit XBMC Foundation with hundreds of volunteer contributors. Originally created in 2003 for the original Xbox.

Use cases: (a) HTPC media center on a living room TV (b) Raspberry Pi media player (c) local network media library with TMDb/TVDb metadata scraping (d) PVR/DVR with a TV tuner card or network tuner (e) self-hosted streaming frontend.

Features:

- **Media library** — movies, TV shows, music, photos; auto-scraped metadata, posters, fanart
- **Format support** — nearly every video/audio/image format; H.264, H.265, AV1, VP9, DTS, Dolby
- **Network protocols** — SMB, NFS, SFTP, WebDAV, HTTP, FTP, UPnP/DLNA as sources
- **Live TV & PVR** — DVB-T/S/C tuners via PVR add-ons; Electronic Program Guide (EPG)
- **Add-ons** — 1000+ add-ons: streaming services, subtitle providers, skins, scrapers, scripts
- **Remote control** — Kodi remote app (Android/iOS), Harmony, CEC (control via TV remote), HTTP API
- **Skinning engine** — fully customizable interface; popular skins: Estuary (default), Aura, Arctic Zephyr
- **Music** — library, playlists, scrobbling (Last.fm), internet radio, visualizations
- **Raspberry Pi** — optimized builds; hardware-decoded video; LibreELEC (Kodi-only OS) recommended
- **Platforms** — Android, Linux, macOS, Windows, iOS, tvOS, Raspberry Pi (via LibreELEC/OSMC)

- Upstream repo: https://github.com/xbmc/xbmc
- Homepage: https://kodi.tv/
- Wiki: https://kodi.wiki/
- Add-ons: https://kodi.tv/addons
- Forum: https://forum.kodi.tv/

## Architecture

Kodi is a desktop/embedded application — it runs *on* the media playback device (TV box, PC, Raspberry Pi, etc.), not as a server. There is no "Kodi server" to deploy on a VPS; it's a client-side media player.

**The self-hosted aspect:**
- Your media files live on a NAS, local disk, or server (Samba/NFS share)
- Kodi runs on the playback device and reads from that storage
- Optionally: MySQL/MariaDB shared library so multiple Kodi instances share the same watched status and metadata

**Companion tools:**
- **LibreELEC** — minimal Linux OS that boots directly into Kodi; recommended for dedicated HTPC/RPi
- **OSMC** — Debian-based OS with Kodi; more flexible than LibreELEC
- **Plex/Emby/Jellyfin** — alternative server-based approaches; Kodi has add-ons to be a client for these

## Compatible install methods

| Platform      | Method                           | Notes                                              |
|---------------|----------------------------------|----------------------------------------------------|
| Raspberry Pi  | LibreELEC (recommended)          | Dedicated Kodi OS; best performance, easiest setup |
| Raspberry Pi  | OSMC                             | Debian-based; more system access                   |
| Linux (Ubuntu)| `sudo apt install kodi`          | Ubuntu/Debian packages available                   |
| Windows       | Installer from kodi.tv           | Download .exe from official site                   |
| macOS         | `.dmg` from kodi.tv              | Download from official site                        |
| Android       | APK or Google Play               | Works on Android TV boxes, Fire TV (sideload)      |
| iOS/tvOS      | TestFlight or AltStore           | Apple restrictions; not on App Store               |
| Docker        | linuxserver/kodi-headless        | Headless Kodi for library management only          |

## Inputs to collect

| Input            | Example                          | Phase    | Notes                                              |
|------------------|----------------------------------|----------|----------------------------------------------------|
| Media sources    | `\\NAS\Movies`, `nfs://192.168.1.5/media` | Setup | Add under Settings → Media Sources        |
| MySQL DB (opt)   | `mysql://kodi:pass@host/kodi`    | Library  | For shared library across multiple Kodi instances  |
| Scraper          | TMDb (movies), TVDb (TV shows)   | Library  | Set per source; auto-downloads metadata/art        |
| PVR add-on (opt) | TVHeadend, NextPVR, Tvhclient    | TV       | For live TV; requires compatible TV tuner          |

## First setup flow

1. Install Kodi (via LibreELEC for RPi, or package/installer for other platforms)
2. Add media sources: Videos → Files → Add Videos → Browse to NAS/local path
3. Set content type (Movies/TV Shows) and choose scraper (TMDb/TVDb)
4. Let library scan run — Kodi downloads metadata, posters, fanart
5. Configure skin if desired (Settings → Interface → Skin)
6. Install add-ons as needed (Settings → Add-ons → Install from repository)
7. Set up remote control (Kodi Remote app, or HTTP API at port 8080)

## Shared library (MySQL)

For multiple Kodi instances sharing watched status:

```sql
CREATE DATABASE kodi_video;
CREATE DATABASE kodi_music;
GRANT ALL ON kodi_video.* TO 'kodi'@'%' IDENTIFIED BY 'password';
GRANT ALL ON kodi_music.* TO 'kodi'@'%' IDENTIFIED BY 'password';
```

In Kodi's `advancedsettings.xml`:
```xml
<advancedsettings>
  <videodatabase>
    <type>mysql</type>
    <host>192.168.1.x</host>
    <port>3306</port>
    <user>kodi</user>
    <pass>password</pass>
    <name>kodi_video</name>
  </videodatabase>
</advancedsettings>
```

## HTTP API / JSON-RPC

Kodi exposes a JSON-RPC API (enabled in Settings → Services → Control):

```
http://kodi-ip:8080/jsonrpc
# Examples:
POST {"jsonrpc":"2.0","method":"Player.PlayPause","params":{"playerid":1},"id":1}
POST {"jsonrpc":"2.0","method":"Application.GetProperties","params":{"properties":["volume"]},"id":1}
```

## Gotchas

- **Kodi is not a media server** — Kodi doesn't serve media to other clients (no transcoding, no browser interface). If you want server-based streaming, use Jellyfin/Plex/Emby instead. Kodi can act as a client to those.
- **Add-on quality varies wildly** — official add-ons (from kodi.tv/addons) are reviewed; third-party repositories ("unofficial add-ons") are not. Piracy add-ons exist; avoid them for legal and security reasons.
- **DRM-protected content** — most commercial streaming services (Netflix, Disney+, Amazon Prime) require their own apps; Kodi can't play DRM-protected streams from these services natively. Some services have official Kodi add-ons (Plex, Emby, Crunchyroll).
- **Hardware acceleration** — critical for smooth 4K playback. Enable in Settings → Player → Videos → Allow hardware acceleration. Raspberry Pi 4 handles 4K H.264/H.265 fine with hardware decode; Pi 3 struggles with 4K.
- **LibreELEC vs OSMC** — LibreELEC is Kodi-only (no other apps, no SSH for most users); OSMC is full Debian with Kodi. LibreELEC is faster and more stable for pure HTPC use; OSMC if you need system-level access.
- **Library not auto-updating** — Kodi doesn't watch folders for changes by default. Set up auto-update in Settings → Media → Library → Update library on startup, or install a library watcher add-on.
- **Remote access security** — the HTTP API and web interface have no auth by default (or basic auth). Don't expose port 8080 to the internet without authentication.
- **iOS/Apple TV** — Apple doesn't allow Kodi in the App Store due to policy concerns about add-ons. Install via TestFlight (beta) or AltStore; may require renewal every 7 days for unsigned installs.
- **Alternatives:** Jellyfin (server + client; transcodes for remote access; browser UI), Plex (SaaS server, free tier; polished; transcode-capable), Emby (similar to Plex), VLC (simple player, no library), Infuse (Apple-only, excellent for local media).

## Links

- Repo: https://github.com/xbmc/xbmc
- Homepage: https://kodi.tv/
- Wiki: https://kodi.wiki/view/Main_Page
- Downloads: https://kodi.tv/download/
- Add-ons: https://kodi.tv/addons
- Forum: https://forum.kodi.tv/
- LibreELEC: https://libreelec.tv/
- OSMC: https://osmc.tv/
- JSON-RPC API docs: https://kodi.wiki/view/JSON-RPC_API
