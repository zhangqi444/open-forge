---
name: Snapdrop
description: Local-network file sharing via browser (WebRTC), inspired by Apple AirDrop. Upstream is low-maintenance since the LimeWire acquisition; the active fork is PairDrop.
---

# Snapdrop

Snapdrop is a browser-based P2P file-sharing tool: open the page on two devices on the same network, peers auto-discover by IP, transfer happens via WebRTC with a small signalling Node.js backend. No accounts, no central storage.

- Upstream repo: <https://github.com/SnapDrop/snapdrop>
- **Important context (front-loaded):** Snapdrop was acquired by LimeWire in 2023. The repo remains available for self-hosting but receives minimal upkeep. The active community-maintained fork with feature additions (paste-room codes, persistent display names, peer-ID rooms, IPv6, PWA improvements) is **[PairDrop](https://github.com/schlagmichdoch/PairDrop)** — many self-hosters now pick PairDrop instead. Both ship a compatible Docker setup.
- Image (community): `linuxserver/snapdrop` on Docker Hub (not the vendor's image; maintained by linuxserver.io)

## Compatible install methods

| Infra              | Runtime                                        | Notes                                                                |
| ------------------ | ---------------------------------------------- | -------------------------------------------------------------------- |
| Single VM / LAN host | Docker (`linuxserver/snapdrop`)              | Simplest, and what most self-hosters use                             |
| Cloned repo        | Upstream `docker-compose.yml`                  | **Dev-mode build**, creates throwaway self-signed certs daily        |
| Alternative        | PairDrop via Docker                            | Active fork; drop-in replacement, better maintained                  |
| Bare metal (Node)  | `node server/index.js` behind nginx            | Client is static HTML; server is Node.js                             |

## Inputs to collect

| Input          | Example                       | Phase     | Notes                                                                       |
| -------------- | ----------------------------- | --------- | --------------------------------------------------------------------------- |
| Host port      | `8080`                        | Runtime   | Default linuxserver image exposes port 80                                    |
| FQDN           | `snapdrop.lan`                | Runtime   | Required for real TLS + PWA features                                         |
| TLS            | reverse-proxy-terminated      | TLS       | Use Caddy/Traefik/nginx-proxy in front — don't rely on the dev self-signed   |
| Trusted proxy  | reverse proxy IP              | Runtime   | Set `X-Forwarded-For` or all peers behind the proxy become mutually visible  |

## Install via linuxserver image (recommended for users)

```sh
docker run -d \
  --name snapdrop \
  -p 8080:80 \
  --restart unless-stopped \
  lscr.io/linuxserver/snapdrop:latest
```

Browse `http://<host>:8080` on two devices on the same LAN (or the same public-IP NAT). PWA features (install prompt, background transfer) require HTTPS, so put it behind a TLS-terminating reverse proxy in any real deployment.

Image: <https://docs.linuxserver.io/images/docker-snapdrop/>.

## Install via upstream repo (dev-style)

Upstream `docker-compose.yml` is explicitly dev-oriented. It builds a custom nginx image that **regenerates self-signed certs on every restart**, expiring after ~24h:

```sh
git clone https://github.com/SnapDrop/snapdrop.git
cd snapdrop
echo 'FQDN=snapdrop.lan' > docker/fqdn.env   # set to your FQDN
docker compose up -d
```

Browse `http://<host>:8080` or `https://<host>:443` (accept the self-signed cert, or download `http://<host>:8080/ca.crt` and trust it on your clients). Source: <https://github.com/SnapDrop/snapdrop/blob/master/docs/local-dev.md>.

For real deployment, prefer the linuxserver image with your own reverse proxy and real TLS.

## Deployment notes (from upstream)

- Client expects the server at `http(s)://<your domain>/server` (same-origin).
- Behind a reverse proxy, set `X-Forwarded-For` — otherwise all clients behind the proxy end up in the same visibility group (because peer discovery is by public IP).
- Default node port is 3000.
- Example nginx config: <https://github.com/SnapDrop/snapdrop/blob/master/docker/nginx/default.conf>.

## Data & config layout

- **No persistent data.** Files transit peer-to-peer via WebRTC; nothing is stored server-side.
- No database.
- Room membership = shared public IP (same NAT bucket). That's it.

## Upgrade

- linuxserver image: `docker pull lscr.io/linuxserver/snapdrop:latest && docker compose up -d`. Release cadence is set by linuxserver, not upstream Snapdrop.
- Upstream repo: `git pull && docker compose up -d --build`. Expect little to no change — last substantive upstream activity is years old.
- Migrating to PairDrop: same UX, more features; see <https://github.com/schlagmichdoch/PairDrop#-pairdrop>.

## Gotchas

- **Upstream is in maintenance mode.** Issues pile up. Prefer PairDrop for active development.
- **Peer grouping is by public IP.** Two users behind the same NAT / corporate proxy / VPN see each other — by design, but surprising on CGNAT or when you share an office network. Without `X-Forwarded-For` being set by your reverse proxy, this breaks open: *every* client behind the proxy shares a visibility room.
- **PWA + clipboard + camera features require HTTPS.** The upstream dev setup ships throwaway self-signed certs; use a real reverse proxy with Let's Encrypt for anything long-lived.
- **The upstream dev compose regenerates certs daily** (`create.sh` entrypoint). Browsers re-prompt every 24h. Not a bug — explicitly documented.
- **No authentication.** Anyone on the same public-IP network can see all peers and send files. Works because it's a LAN tool — do **not** expose to the open internet as a general relay.
- **Self-hosting on a VPS is fine** but each user is effectively alone (different public IPs each). The expected topology is "LAN + someone on the same Wi-Fi".
- **Firewall:** WebRTC data channels need NAT traversal. On restrictive corporate networks, STUN may be insufficient and Snapdrop offers no bundled TURN.
- **IPv6** is not handled uniformly — users on an IPv6 address + IPv4 on the same LAN sometimes fail to see each other.
- **The `latest` tag on the upstream repo** has been stuck for years; do not assume it reflects recent security patches.
- **LimeWire note:** the hosted `snapdrop.net` now redirects to LimeWire's service with different terms. Self-hosted instances are unaffected but the branding in the README nudges users to the SaaS.

## Links

- Repo: <https://github.com/SnapDrop/snapdrop>
- PairDrop (active fork): <https://github.com/schlagmichdoch/PairDrop>
- linuxserver image docs: <https://docs.linuxserver.io/images/docker-snapdrop/>
- Local-dev docs: <https://github.com/SnapDrop/snapdrop/blob/master/docs/local-dev.md>
- nginx example config: <https://github.com/SnapDrop/snapdrop/blob/master/docker/nginx/default.conf>
