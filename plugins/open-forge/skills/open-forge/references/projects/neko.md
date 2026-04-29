---
name: Neko
description: Self-hosted virtual browser / shared desktop over WebRTC — run Firefox, Chromium, Tor, or a full desktop environment in a Docker container and stream it to multiple users simultaneously.
---

# Neko

Neko is a WebRTC-based virtual browser / remote desktop server. It runs a headless X server + browser (or full desktop like XFCE/KDE) inside a container and streams the video/audio over WebRTC, letting one or many users share control through any modern browser. Use cases: watch parties, collaborative browsing, throwaway browsing, secure jump host, automated browser with playwright/puppeteer.

- Upstream repo: <https://github.com/m1k1o/neko>
- Docs: <https://neko.m1k1o.net/docs/v3/>
- Images: `ghcr.io/m1k1o/neko/<flavor>` (firefox, chromium, tor-browser, waterfox, google-chrome, microsoft-edge, brave, vivaldi, opera, kde, xfce, vlc, remmina, …) — see <https://neko.m1k1o.net/docs/v3/installation/docker-images>

## Compatible install methods

| Infra                                         | Runtime           | Notes                                                                      |
| --------------------------------------------- | ----------------- | -------------------------------------------------------------------------- |
| Single VM (2+ vCPU, 2+ GB RAM)                | Docker + Compose  | Recommended — upstream ships `docker-compose.yaml`                         |
| VM with NVIDIA GPU                            | Docker + nvidia-runtime | Use `.nvidia` image variants for hardware-accelerated encoding       |
| Kubernetes                                    | Plain manifests   | Possible; be mindful of UDP port ranges + shm_size                         |
| Bare metal                                    | Host install      | Supported but niche; docker is the blessed path                            |

## Inputs to collect

| Input                                    | Example                              | Phase   | Notes                                                                            |
| ---------------------------------------- | ------------------------------------ | ------- | -------------------------------------------------------------------------------- |
| Flavor / image                           | `ghcr.io/m1k1o/neko/firefox:3.0.4`   | Runtime | Pick a browser or desktop image; pin a version — avoid `:latest` in production    |
| Web port                                 | `8080`                               | Runtime | HTTP signalling + web UI; put behind TLS-terminating reverse proxy               |
| WebRTC UDP range                         | `52000-52100/udp`                    | Network | Must be reachable by clients; **don't** put behind NAT without NAT1to1 config    |
| `NEKO_NAT1TO1`                           | public IPv4 of the host              | Runtime | Required if the host is behind NAT (most VPS configs)                            |
| Screen geometry                          | `1920x1080@30`                       | Runtime | `NEKO_DESKTOP_SCREEN`; affects CPU/bandwidth                                     |
| User password                            | strong random                        | Runtime | `NEKO_MEMBER_MULTIUSER_USER_PASSWORD`                                            |
| Admin password                           | strong random, **different**         | Runtime | `NEKO_MEMBER_MULTIUSER_ADMIN_PASSWORD`                                           |
| Shared memory                            | `2gb`                                | Runtime | `shm_size: 2gb` — browsers will crash on the default 64 MB                       |

## Install via Docker Compose

Upstream's canonical compose (at <https://github.com/m1k1o/neko/blob/master/docker-compose.yaml>) — pin the image and set real passwords:

```yaml
services:
  neko:
    image: ghcr.io/m1k1o/neko/firefox:3.0.4   # pin; tags at ghcr.io
    restart: unless-stopped
    shm_size: 2gb
    ports:
      - "8080:8080"
      - "52000-52100:52000-52100/udp"
    environment:
      NEKO_DESKTOP_SCREEN: 1920x1080@30
      NEKO_MEMBER_MULTIUSER_USER_PASSWORD: "CHANGE_ME_user"
      NEKO_MEMBER_MULTIUSER_ADMIN_PASSWORD: "CHANGE_ME_admin"
      NEKO_WEBRTC_EPR: 52000-52100
      NEKO_WEBRTC_ICELITE: 1
      # Required when host is behind NAT (VPS, home NAT, etc.):
      NEKO_NAT1TO1: "203.0.113.42"   # public IP of the host
```

`docker compose up -d`, then browse `http://<host>:8080`. Log in as user (read-only-ish) or admin (can host, grant control).

### GPU acceleration (optional)

Use `.nvidia` image variants and add the NVIDIA runtime:

```yaml
    image: ghcr.io/m1k1o/neko/chromium.nvidia:3.0.4
    runtime: nvidia
    environment:
      NVIDIA_VISIBLE_DEVICES: all
      NVIDIA_DRIVER_CAPABILITIES: all
```

Host must have NVIDIA driver + nvidia-container-toolkit installed.

### Multi-user rooms

For ephemeral per-user rooms, see [neko-rooms](https://github.com/m1k1o/neko-rooms) — a management service that spawns/destroys Neko containers via API.

## Data & config layout

- No persistent data by default. Each restart is a fresh profile.
- Optional persistent profile: mount `/home/neko` (or browser-specific profile path) to a volume — see <https://neko.m1k1o.net/docs/v3/configuration/user-persistence>.
- Config is entirely environment-variable driven; full reference at <https://neko.m1k1o.net/docs/v3/configuration>.

## Upgrade

1. Check release notes: <https://github.com/m1k1o/neko/releases>. v2 → v3 had significant config key renames.
2. Bump image tag in compose; `docker compose pull && docker compose up -d`.
3. If migrating from v2, consult <https://neko.m1k1o.net/docs/v3/migration-from-v2>.

## Gotchas

- **WebRTC is UDP.** Clients need the full 52000-52100 range reachable on UDP, not just TCP 8080. Firewalls that block UDP will show a connected UI with a black screen.
- **NAT1to1 is almost always required on VPS.** Without `NEKO_NAT1TO1=<public ip>`, ICE candidates advertise the container's internal IP and clients outside your LAN can't connect.
- **`shm_size` must be ≥ 1 GB** (2 GB for Chromium-family) or the browser inside Neko will crash with obscure errors. Default 64 MB is far too small.
- **No built-in TLS.** The web UI is HTTP; put it behind Caddy / Traefik / nginx that terminates TLS. Modern browsers require HTTPS for getUserMedia (microphone) on anything other than `localhost`.
- **Admin vs user passwords must differ** and should both be strong — there's no rate limiting built in.
- **Persistent browser state is opt-in.** Cookies/logins vanish on restart unless you mount the profile volume. Conversely, treat every Neko session as *potentially* persistent if you add the volume — sensitive logins survive.
- **ICE Lite mode (`NEKO_WEBRTC_ICELITE=1`)** works when the host has a public IP. Behind symmetric NAT you need a TURN server instead — set `NEKO_WEBRTC_ICELITE=0` and configure `NEKO_WEBRTC_ICESERVER_*`.
- **Version skew:** v2 config keys (`NEKO_PASSWORD`, `NEKO_PASSWORD_ADMIN`) still appear in older tutorials — v3 uses `NEKO_MEMBER_MULTIUSER_*` family. Don't mix them.
- **Audio requires extra setup on some browsers.** Chromium-family usually works out of the box; Tor Browser often has no sound by design.
- **Tor Browser flavor pins an old Tor version per release** — don't expect automatic security updates until a new image tag ships.
- **Bandwidth-heavy.** 1080p30 ≈ 3-5 Mbit/s per connected client upstream. Plan VPS egress accordingly.

## Links

- Docs: <https://neko.m1k1o.net/docs/v3/>
- Installation: <https://neko.m1k1o.net/docs/v3/installation>
- Docker images catalog: <https://neko.m1k1o.net/docs/v3/installation/docker-images>
- Configuration reference: <https://neko.m1k1o.net/docs/v3/configuration>
- Releases: <https://github.com/m1k1o/neko/releases>
- Companion: <https://github.com/m1k1o/neko-rooms> (ephemeral per-user rooms), <https://github.com/m1k1o/neko-vpn> (VPN-scoped sessions)
