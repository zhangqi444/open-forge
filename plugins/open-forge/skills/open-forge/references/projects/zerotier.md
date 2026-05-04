---
name: zerotier
description: ZeroTier recipe for open-forge. Software-defined networking that creates encrypted peer-to-peer virtual Ethernet networks. Connect any devices as if on the same LAN — across cloud, on-prem, and edge.
---

# ZeroTier

Software-defined networking platform that creates virtual Ethernet networks over the internet. Devices join a ZeroTier network and communicate peer-to-peer (end-to-end encrypted) as if on the same LAN — regardless of NAT, firewalls, or cloud provider. Upstream: <https://github.com/zerotier/ZeroTierOne>. Docs: <https://docs.zerotier.com>.

> **Self-hosted vs. ZeroTier Cloud:** ZeroTier clients are free and open-source. The public coordination infrastructure (planet/moon servers) is run by ZeroTier Inc. for free. For full self-hosting (including your own coordination root), deploy **ZeroNSD** or a **Moon** node.

## Compatible install methods

| Method | When to use |
|---|---|
| Package install (Linux/macOS/Windows) | Recommended; official packages from zerotier.com |
| Docker | Containerized Linux nodes |
| Mobile apps (iOS/Android) | Free from App Store / Google Play |
| Self-hosted Moon node | Custom coordination root for latency/privacy |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Using ZeroTier Cloud (zerotier.com) or fully self-hosted?" | Cloud = free coordination via zerotier.com; self-hosted = Moon node |
| preflight | "ZeroTier Network ID?" | 16-char hex; create at my.zerotier.com or via self-hosted controller |

## Client install (Linux)

```bash
curl -s https://install.zerotier.com | sudo bash
sudo systemctl enable zerotier-one --now
sudo zerotier-cli join <network-id>
```

After joining, approve the device at [my.zerotier.com](https://my.zerotier.com) (or your self-hosted controller).

## Docker client

```bash
docker run -d \
  --name zerotier \
  --cap-add NET_ADMIN \
  --cap-add SYS_ADMIN \
  --device /dev/net/tun \
  --network host \
  -v zerotier-data:/var/lib/zerotier-one \
  zerotier/zerotier-synology:latest <network-id>
```

Or use community image `zyclonite/zerotier` for general Docker use.

## Self-hosted Moon node (optional)

A Moon is a user-defined root server for reduced latency and independence from ZeroTier Inc.:

```bash
# On your Moon server (must have public IP)
sudo zerotier-cli orbit <moon-world-id> <moon-seed>
```

Full Moon setup: <https://docs.zerotier.com/zerotier/moons>

## Self-hosted Network Controller

ZeroTierOne includes a built-in network controller (enabled by default). Third-party UIs:
- [ZeroTier Controller UI](https://github.com/dec0dOS/zero-ui) — web UI for the built-in controller

Or use [ztncui](https://github.com/key-networks/ztncui) for a standalone controller UI.

## Software-layer concerns

- ZeroTier virtual interface: `zt<network-suffix>` — shows up as a network interface on each device
- Default IP range: assigned by the network controller (you choose the subnet at my.zerotier.com)
- No open ports required on clients — ZeroTier traverses NAT via UDP hole-punching; relay used as fallback
- Traffic is encrypted end-to-end; ZeroTier Inc. relays only when P2P fails and cannot decrypt traffic
- License: MPL 2.0 (client); proprietary for ZeroTier Cloud management plane

## Upgrade procedure

```bash
# Linux (apt)
sudo apt update && sudo apt upgrade zerotier-one
sudo systemctl restart zerotier-one
```

## Gotchas

- **Approval required**: after `zerotier-cli join`, device shows as "pending" until approved in controller
- P2P may not work on highly restricted networks (enterprise firewalls) — relay fallback is slower
- Docker client needs `NET_ADMIN`, `SYS_ADMIN`, and `/dev/net/tun` — not compatible with rootless Docker without extra config
- Free tier at my.zerotier.com: up to 25 devices; paid plans for more
- For fully self-hosted (no zerotier.com dependency): run a Moon node + self-hosted controller

## Links

- GitHub: <https://github.com/zerotier/ZeroTierOne>
- Docs: <https://docs.zerotier.com>
- Downloads: <https://www.zerotier.com/download/>
- My ZeroTier (controller UI): <https://my.zerotier.com>
