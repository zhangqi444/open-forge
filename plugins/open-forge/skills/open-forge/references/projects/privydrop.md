# PrivyDrop

**Peer-to-peer file and text sharing via WebRTC** — transfer files, folders, and rich text directly between browsers with no server relay. End-to-end encrypted, supports breakpoint-resumable transfers, multi-receiver rooms, and unlimited file sizes via Chrome's direct-to-disk streaming.

**Official site:** https://www.privydrop.app
**Source:** https://github.com/david-bai00/PrivyDrop
**License:** MIT

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any VPS / bare metal | Docker Compose | Recommended; includes TURN server option |
| Local LAN | Docker Compose | LAN-only mode; no domain required |
| Public domain | Docker Compose | Full mode with HTTPS + Let's Encrypt |

---

## Inputs to Collect

### Phase 1 — Planning
- Deployment mode: `lan-http` / `lan-tls` / `public` / `full`
- Domain name (required for `full` mode with auto-TLS)
- Let's Encrypt email (for `full` mode)
- Whether to include TURN server (`--with-turn`, needed for complex NAT)
- Whether to include Nginx reverse proxy (`--with-nginx`)

### Phase 2 — Deploy
- Redis connection (included in Docker Compose stack)
- TURN server credentials (if enabling `--with-turn`)

---

## Software-Layer Concerns

- **Config path:** `deploy.sh` script handles mode-based configuration; no manual config file editing required
- **Env vars:** Backend uses Node.js + Express + Socket.IO; Redis for signaling/room state
- **Data dirs:** No persistent user storage — all data is P2P; Redis is used for room/signaling state only
- **Tech stack:** Next.js 14 frontend, Node.js/Express backend, Socket.IO signaling, WebRTC for data transfer, Redis
- **Ports:** Default HTTP :80 (with Nginx), HTTPS :8443 (LAN TLS), frontend dev :3002, backend :3001
- **LAN TLS note:** Import `docker/ssl/ca-cert.pem` into browser/system trust store when using self-signed certs

---

## Deployment

```bash
git clone https://github.com/david-bai00/PrivyDrop
cd PrivyDrop

# LAN (no domain)
bash ./deploy.sh --mode lan-http

# LAN + TURN (for complex NAT)
bash ./deploy.sh --mode lan-http --with-turn

# Public domain with full HTTPS + TURN
bash ./deploy.sh --mode full --domain your-domain.com --with-nginx --with-turn --le-email you@domain.com
```

---

## Upgrade Procedure

```bash
git pull
docker compose pull
docker compose up -d
```

---

## Gotchas

- **No persistent file storage** — files are never stored on the server; only signaling/room data passes through Redis
- **TURN server required** for users behind symmetric NAT or restrictive firewalls; without it, direct P2P may fail
- **LAN TLS self-signed certs** require manual CA trust on each device; browsers will warn otherwise
- **Chrome-only** for direct-to-disk streaming and unlimited file transfer; other browsers have size limits
- **Resume transfers** require setting a save directory in Chrome; on interruption, both sender and receiver must refresh to restart
- **Multi-receiver:** All receivers in a room download simultaneously; new joiners can connect mid-transfer

---

## Links

- Upstream README: https://github.com/david-bai00/PrivyDrop#readme
- Docker Deployment Guide: https://github.com/david-bai00/PrivyDrop/blob/main/docs/DEPLOYMENT_docker.md
