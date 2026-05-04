---
name: rustdesk
description: Recipe for RustDesk self-hosted server — open-source remote desktop relay and rendezvous service.
---

# RustDesk

Open-source remote desktop software with a self-hostable relay/rendezvous server. Client apps (Windows, macOS, Linux, Android, iOS) connect through your own server rather than RustDesk's public infrastructure. Server repo: <https://github.com/rustdesk/rustdesk-server>. Client repo: <https://github.com/rustdesk/rustdesk>. Site: <https://rustdesk.com>. License: AGPL-3.0. ~80K stars (client).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker Compose | <https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/> | ✅ | Recommended. Two-container setup (hbbs + hbbr). |
| Binary (bare metal) | <https://github.com/rustdesk/rustdesk-server/releases> | ✅ | Run `hbbs` and `hbbr` binaries directly on Linux. |
| RustDesk Server Pro | <https://rustdesk.com/pricing.html> | ✅ (commercial) | Adds web admin console, user management, audit logs. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| infra | "Public hostname or IP of the server?" | hostname / IP | All. Used in `hbbs -r <relay>:21117` command. |
| network | "Firewall: can you open TCP ports 21115–21119 and UDP 21116?" | Confirm | Required for all client connections |
| software | "Keep relay host separate from rendezvous host?" | Yes / No (default: same host) | Multi-server setups |

## Software-layer concerns

### Docker Compose

Replace `rustdesk.example.com` with your actual server hostname or IP.

```yaml
version: '3'
networks:
  rustdesk-net:
    external: false

services:
  hbbs:
    container_name: hbbs
    ports:
      - 21115:21115
      - 21116:21116
      - 21116:21116/udp
      - 21118:21118
    image: rustdesk/rustdesk-server:latest
    command: hbbs -r rustdesk.example.com:21117
    volumes:
      - ./data:/root
    networks:
      - rustdesk-net
    depends_on:
      - hbbr
    restart: unless-stopped

  hbbr:
    container_name: hbbr
    ports:
      - 21117:21117
      - 21119:21119
    image: rustdesk/rustdesk-server:latest
    command: hbbr
    volumes:
      - ./data:/root
    networks:
      - rustdesk-net
    restart: unless-stopped
```

### Port reference

| Port | Protocol | Service | Purpose |
|---|---|---|---|
| 21115 | TCP | hbbs | NAT type test |
| 21116 | TCP + UDP | hbbs | ID registration + heartbeat |
| 21117 | TCP | hbbr | Relay traffic |
| 21118 | TCP | hbbs | WebSocket (web client, optional) |
| 21119 | TCP | hbbr | WebSocket relay (web client, optional) |

### Data directory

`./data:/root` — contains the server keypair (`id_ed25519` + `id_ed25519.pub`) generated on first run. Back this up.

### Client configuration

1. In the RustDesk client: **Settings → Network**
2. Set **ID Server** to your `hbbs` host
3. Set **Relay Server** to your `hbbr` host (same host if using above compose)
4. Set **Key** to the contents of `./data/id_ed25519.pub`

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No schema migrations. Keypair in `./data` persists across upgrades.

## Gotchas

- **Replace the example hostname**: `rustdesk.example.com` in the `hbbs` command must be your real relay hostname/IP — clients won't connect through relay otherwise.
- **All ports must be open**: UDP on 21116 is required for direct (peer-to-peer) connections. If blocked, all traffic routes through the relay.
- **Protect the keypair**: `./data/id_ed25519` is the server's identity. Losing it requires reconfiguring every client with the new public key.
- **No access control by default**: Any RustDesk client can register an ID against your open-source server. Use RustDesk Server Pro or configure a client allowlist if you need access restrictions.
- **hbbs and hbbr must be mutually reachable**: If running on separate hosts, ensure hbbs can reach hbbr and vice versa, and both are publicly accessible.

## Links

- Server GitHub: <https://github.com/rustdesk/rustdesk-server>
- Client GitHub: <https://github.com/rustdesk/rustdesk>
- Self-host docs: <https://rustdesk.com/docs/en/self-host/rustdesk-server-oss/>
- Server Pro: <https://rustdesk.com/pricing.html>
