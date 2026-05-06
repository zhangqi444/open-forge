---
name: tox
description: Tox (c-toxcore) recipe for open-forge. Covers building the toxcore library and running a bootstrap node (tox-bootstrapd) via Docker. Tox is a peer-to-peer, encrypted, serverless instant messaging protocol with voice and video support.
---

# Tox

Peer-to-peer, end-to-end encrypted instant messaging protocol with text, voice, and video chat. Fully decentralized — no central servers required. The network is maintained by publicly-reachable **bootstrap nodes** that help peers find each other. Self-hosting a bootstrap node contributes to the network's resilience. Upstream (core library): <https://github.com/TokTok/c-toxcore>. Website: <https://tox.chat>.

**License:** GPL-3.0 · **Language:** C · **Default ports:** 33445/UDP+TCP (bootstrap node) · **Stars:** ~2,600

> **Self-hosting note:** Tox is serverless — users communicate directly peer-to-peer. There is no "Tox server" to host in the traditional sense. What you can self-host is a **bootstrap node** (`tox-bootstrapd`) to help peers initially find each other and join the DHT network.

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Docker (bootstrap node) | <https://hub.docker.com/r/toxchat/tox-bootstrapd> | ✅ | **Recommended** — easiest bootstrap node deploy. |
| Package (Ubuntu/Debian) | `apt install tox-bootstrapd` | Distro-packaged | Simple system service. |
| Build from source | <https://github.com/TokTok/c-toxcore/blob/master/INSTALL.md> | ✅ | Latest version or custom builds. |

## Game clients (for end users)

Tox is a protocol — users need a client app:

- **qTox** (Linux/Windows/macOS): <https://github.com/qTox/qTox>
- **µTox** (lightweight): <https://github.com/uTox/uTox>
- **Toxic** (CLI): <https://github.com/JFreegman/toxic>
- **Antidote** (iOS): <https://antidote.im>
- Full client list: <https://tox.chat/clients.html>

## Self-hosting a bootstrap node

Bootstrap nodes help new Tox clients initially connect to the DHT network. Running one is a public service — your node's address is published in the bootstrap node list.

### Install — Docker

```bash
mkdir tox-bootstrap && cd tox-bootstrap

# Create config directory
mkdir -p config

# Download default config
curl -o config/tox-bootstrapd.conf \
  https://raw.githubusercontent.com/TokTok/c-toxcore/master/other/bootstrap_daemon/tox-bootstrapd.conf

cat > docker-compose.yml << 'COMPOSE'
services:
  tox-bootstrapd:
    image: toxchat/tox-bootstrapd:latest
    restart: unless-stopped
    ports:
      - "33445:33445/tcp"
      - "33445:33445/udp"
    volumes:
      - ./config:/etc/tox-bootstrapd
      - tox-data:/var/lib/tox-bootstrapd

volumes:
  tox-data:
COMPOSE

docker compose up -d
```

### Install — Package (Ubuntu/Debian)

```bash
sudo apt update
sudo apt install tox-bootstrapd

sudo systemctl enable --now tox-bootstrapd
```

### Build from source

```bash
sudo apt install -y build-essential cmake libsodium-dev

git clone --recurse-submodules https://github.com/TokTok/c-toxcore.git
cd c-toxcore

mkdir _build && cd _build
cmake .. -DBOOTSTRAP_DAEMON=ON -DENABLE_SHARED=OFF
make -j$(nproc)
sudo make install
```

## Bootstrap node configuration

Edit `/etc/tox-bootstrapd/tox-bootstrapd.conf` (or `./config/tox-bootstrapd.conf` for Docker):

```ini
port = 33445
keys-file-path = "/var/lib/tox-bootstrapd/keys"
pid-file-path = "/var/run/tox-bootstrapd/tox-bootstrapd.pid"
enable-ipv6 = true
enable-ipv4-fallback = true
enable-lan-discovery = true
enable-tcp-relay = true
tcp-relay-ports = [443, 3389, 33445]
enable-motd = true
motd = "My Tox Bootstrap Node"

# Bootstrap off existing nodes to join the network
bootstrap-nodes = [
    { address = "node.tox.biribiri.org", port = 33445, public-key = "F404ABAA1C99A9D37D61AB54898F56793E1DEF8BD46B1038B9D822E8460FAB67" },
    { address = "tox.verdict.gg", port = 33445, public-key = "1C5293AEF2114717547B39DA8EA6F1E331E5E358B35F9B6B5F19317911C5F976" }
]
```

Get the current official bootstrap node list at: <https://nodes.tox.chat>

## Getting your node's public key

After first start, get your node's public key (needed to list your node publicly):

```bash
# Docker
docker exec tox-bootstrap-tox-bootstrapd-1 cat /var/lib/tox-bootstrapd/keys.txt

# Or read the keys file directly
sudo cat /var/lib/tox-bootstrapd/keys
```

## Software-layer concerns

| Concern | Detail |
|---|---|
| Architecture | Tox uses a DHT (Distributed Hash Table) — no central server. Bootstrap nodes are entry points only, not message relays. |
| Keys file | The bootstrap node generates a keypair on first start. The public key is your node's identity on the network. Preserve the keys file — losing it means your node appears as a new unknown node. |
| TCP relay | Enable `enable-tcp-relay` for users behind strict firewalls. TCP relay ports (443, 3389, 33445) must be open. |
| Port 33445 | Both TCP and UDP must be open. UDP is used for DHT; TCP relay is optional but improves connectivity. |
| No user data | A bootstrap node carries no user messages or data — it's only an entry point for DHT discovery. |
| Public node list | Submit your node to <https://nodes.tox.chat> after running it stably for a while. |

## Upgrade procedure

```bash
# Docker
docker compose pull
docker compose up -d

# Package
sudo apt update && sudo apt upgrade tox-bootstrapd
sudo systemctl restart tox-bootstrapd
```

## Gotchas

- **Serverless = no accounts to manage:** Tox has no user database, accounts, or passwords. User identity is their long Tox ID (public key). There's nothing to administer for end users.
- **Bootstrap node ≠ messaging server:** Messages never pass through your bootstrap node. It only helps peers find each other. Once connected to the DHT, peers communicate directly.
- **Both TCP and UDP on port 33445:** Firewalls/security groups must allow both TCP and UDP on 33445. Many admins forget UDP.
- **Keys file backup:** Back up `/var/lib/tox-bootstrapd/keys`. Losing it is not catastrophic (the node restarts with a new key) but your node will be unknown to clients that cached the old key.
- **Experimental cryptography warning:** The upstream README explicitly notes that Tox's security model has not been formally audited. For highly sensitive communications, consider alternatives with audited security (Signal, Wire).
- **Docker image source:** The official Docker image is `toxchat/tox-bootstrapd` on Docker Hub. Do not use unverified third-party images.

## Upstream links

- GitHub (core library): <https://github.com/TokTok/c-toxcore>
- Bootstrap daemon config: <https://github.com/TokTok/c-toxcore/blob/master/other/bootstrap_daemon/tox-bootstrapd.conf>
- Install guide: <https://github.com/TokTok/c-toxcore/blob/master/INSTALL.md>
- Website: <https://tox.chat>
- Clients: <https://tox.chat/clients.html>
- Bootstrap node list: <https://nodes.tox.chat>
- Docker Hub: <https://hub.docker.com/r/toxchat/tox-bootstrapd>
