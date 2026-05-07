---
name: gnunet
description: GNUnet recipe for open-forge. Decentralized, peer-to-peer networking framework supporting anonymous file sharing, censorship-resistant communication, and distributed identity. GPL-3.0, C. Source: https://gnunet.org/git/
---

# GNUnet

A software framework for decentralized, peer-to-peer networking with a focus on security, privacy, and censorship resistance. Provides anonymous file sharing (GNUnet FS), distributed name resolution (GNS — GNU Name System), secure messaging, and a base layer for building P2P applications. Part of the GNU Project. GPL-3.0 licensed, written in C. Website: <https://gnunet.org/>. Source: <https://gnunet.org/git/>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian / Ubuntu | APT package | `apt install gnunet` — recommended for most users |
| Any Linux | Build from source | Latest features; requires libgcrypt, libsodium, etc. |
| Guix / NixOS | Package manager | Well-supported on these distros |

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "Primary use case?" | File sharing / DNS alternative (GNS) / Messaging / All | Determines which GNUnet services to enable |
| "Run as system daemon or user?" | System / User | System daemon for always-on node; user for personal use |
| "Public IP available?" | Yes / No | Improves peer connectivity; NAT traversal available but limited |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "Port for peer connections?" | Number | Default 2086 (TCP+UDP) |
| "Enable file sharing daemon?" | Yes / No | `gnunet-service-fs` |
| "Enable GNS (name resolution)?" | Yes / No | `gnunet-service-gns` — alternative to DNS |

## Software-Layer Concerns

- **Multi-service architecture**: GNUnet is a framework of many cooperating services (transport, core, DHT, FS, GNS, identity, cadet, etc.) — all managed via `gnunet-arm`.
- **`gnunet-arm`**: The service manager — starts, stops, and monitors GNUnet services. Always the entry point.
- **Configuration**: `~/.config/gnunet.conf` (user) or `/etc/gnunet.conf` (system). Minimal config is auto-generated.
- **NAT traversal**: GNUnet includes NAT traversal helpers but works best with a public IP or port forwarding.
- **GNS**: The GNU Name System is a decentralized alternative to DNS — names end in `.gnu` and resolve via the DHT. Can coexist with system DNS.
- **Anonymous file sharing**: GNUnet FS provides anonymous, censorship-resistant file sharing — not BitTorrent; uses onion routing.
- **Resource limits**: Configure CPU and bandwidth limits in `gnunet.conf` to avoid saturating the host.
- **GTK/Qt GUI**: Optional `gnunet-gtk` provides a graphical interface for file sharing and peer management.

## Deployment

### Debian/Ubuntu — package install

```bash
apt install gnunet gnunet-gtk  # gnunet-gtk is optional

# Initialize user config
gnunet-arm -s   # start all services (user mode)
gnunet-arm -I   # list running services

# Check peer info
gnunet-peerinfo -s
```

### System-wide daemon (root/systemd)

```bash
# Install
apt install gnunet

# System service
systemctl enable gnunet
systemctl start gnunet

# Check
gnunet-arm -I
```

### Minimal `~/.config/gnunet.conf`

```ini
[arm]
START_SYSTEM_SERVICES = YES
START_USER_SERVICES = NO

[transport]
PLUGINS = tcp udp

[nat]
BEHIND_NAT = YES
ENABLE_UPNP = YES

[ats]
WAN_QUOTA_IN = 512 KiB/s
WAN_QUOTA_OUT = 512 KiB/s
```

### File sharing

```bash
# Index a file for sharing
gnunet-publish -k "my-keyword" /path/to/file

# Search for files
gnunet-search "my-keyword"

# Download a file by URI
gnunet-download -o output.file gnunet://fs/chk/...
```

### GNS setup (DNS alternative)

```bash
# Add a GNS record
gnunet-namestore -z myzone -a -n "www" -t A -V "192.168.1.1" -e never

# Query GNS
gnunet-gns -u www.myzone.gnu
```

## Upgrade Procedure

1. `apt update && apt upgrade gnunet` for package installs.
2. For source builds: `git pull`, `./configure && make && make install`, restart `gnunet-arm`.
3. Check https://gnunet.org/en/news.html for release notes and migration steps.

## Gotchas

- **Bootstrap time**: A new GNUnet node takes time to connect to peers — can take minutes to hours depending on network conditions.
- **NAT traversal is limited**: Best performance with a public IP or port forwarding on UDP/TCP 2086.
- **CPU/bandwidth**: GNUnet participates in the network by routing traffic for others — set resource limits to prevent overload.
- **Not a drop-in for BitTorrent**: GNUnet FS is anonymous but slower and less compatible than BitTorrent clients.
- **GNS is experimental**: The GNU Name System is functional but not widely adopted — `.gnu` names only resolve for GNUnet users.
- **Many services**: GNUnet runs ~15 background services — expect noticeable memory and CPU use.

## Links

- Website: https://gnunet.org/
- Documentation: https://docs.gnunet.org/
- Install guide: https://gnunet.org/en/install.html
- Source (Git): https://gnunet.org/git/
- Mailing list: https://gnunet.org/en/contact.html
