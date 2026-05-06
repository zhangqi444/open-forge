---
name: peergos
description: Peergos recipe for open-forge. Private, encrypted, peer-to-peer file storage and social platform — end-to-end encrypted files, sharing, chat, calendar, email. Java JAR or Docker self-host. Upstream: https://github.com/Peergos/Peergos
---

# Peergos

Private, encrypted, peer-to-peer file storage and social platform. Store, share and view files with end-to-end encryption — your server is trustless (cannot read your data even if compromised). Also includes chat, calendar, news feed, task lists, and an email client.

2,403 stars · AGPL-3.0

Upstream: https://github.com/Peergos/Peergos
Website: https://peergos.org
Tech book: https://book.peergos.org
Hosted service: https://peergos.net
Docker Hub: https://hub.docker.com/r/peergos/server

## What it is

Peergos provides a trustless, encrypted personal cloud:

- **End-to-end encryption** — All data encrypted on the client before sending; server cannot read content or infer file structure
- **File storage** — Store any file type with preview for images, video, audio, PDF, office docs
- **Secure sharing** — Cryptographic access control; share files/folders with specific users
- **Secret links** — Generate read-only secret links to files/folders without requiring login
- **WebDAV bridge** — Mount Peergos as a network drive (WebDAV)
- **File sync** — Sync local directories with Peergos storage
- **Secure messenger** — End-to-end encrypted chat
- **Email client** — Encrypted email with bridge support
- **Calendar** — Private calendar
- **Social network** — Follow other users; private social feed
- **Custom web apps** — Sandboxed web apps running from Peergos, unable to exfiltrate data
- **IPFS-based** — Built on a minimal IPFS implementation (Nabu) for P2P data routing
- **Multi-device** — Log in from any device; data syncs
- **Trustless server** — Even if your server is compromised, data and metadata remain protected (encryption at rest + in transit)

## Compatible combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Docker | peergos/server image | Recommended for self-hosting |
| Bare metal | Java 17+ JAR | Download from releases |
| Peergos.net | Hosted | Paid hosted service |

## Inputs to collect

### Phase 1 — Pre-install
- Domain name and HTTPS setup (required for multi-device/social features)
- Storage path (for encrypted data blocks)
- Port (default: 8000)
- Whether to allow public signups or restrict to invited users

## Software-layer concerns

### Docker run
  docker run -d --name peergos \
    -p 8000:8000 \
    -v /path/to/data:/data \
    peergos/server:latest

### Docker Compose
  version: '3'
  services:
    peergos:
      image: peergos/server:latest
      restart: unless-stopped
      ports:
        - "8000:8000"
      volumes:
        - ./data:/data
      command: ["java", "-jar", "Peergos.jar", "server",
                "-peergos-url", "https://peergos.example.com",
                "-ip-address", "0.0.0.0",
                "-port", "8000"]

### JAR install
  # Download Peergos.jar from https://github.com/Peergos/Peergos/releases
  java -jar Peergos.jar server \
    -peergos-url https://peergos.example.com \
    -ip-address 0.0.0.0 \
    -port 8000

### Key startup flags
  -peergos-url    — public URL of your instance (used in social links and identity)
  -ip-address     — bind address (0.0.0.0 for all interfaces)
  -port           — HTTP port (default 8000); use reverse proxy for HTTPS
  -storage-path   — where encrypted data blocks are stored

### Ports
- 8000 — HTTP (use Nginx/Traefik for HTTPS; HTTPS required for production)

### Reverse proxy (Nginx)
  server {
    listen 443 ssl;
    server_name peergos.example.com;
    client_max_body_size 0;    # allow large uploads
    location / {
      proxy_pass http://localhost:8000;
      proxy_set_header Host $host;
      proxy_set_header X-Forwarded-Proto https;
      proxy_buffering off;
    }
  }

## Upgrade procedure

1. Stop the current container/process
2. docker pull peergos/server:latest (or download new JAR)
3. Start with same data volume mounted — Peergos handles data format migrations automatically
4. Verify login and file access

## Gotchas

- HTTPS required for production — multi-device login and social features require a public HTTPS URL; localhost is fine for single-device personal use
- No password recovery — encryption keys are derived from username + password; if you forget your password, data is unrecoverable
- Trustless but not anonymous — the server knows your username and IP; anonymity requires Tor
- Storage grows indefinitely — encrypted blocks are stored immutably; storage usage grows with use and doesn't shrink on file deletion until garbage collection runs
- Java heap — for larger user bases, increase JVM heap: -Xmx2g flag
- AGPL-3.0 — modifications must be open-sourced; running as a service for others requires compliance with AGPL network use clause
- Peergos.net for ease — the self-hosted path requires careful setup; the hosted service at peergos.net is simpler for most users

## Links

- Upstream README: https://github.com/Peergos/Peergos/blob/master/README.md
- Tech book: https://book.peergos.org
- Releases: https://github.com/Peergos/Peergos/releases
- Docker Hub: https://hub.docker.com/r/peergos/server
- web-ui repo: https://github.com/Peergos/web-ui
