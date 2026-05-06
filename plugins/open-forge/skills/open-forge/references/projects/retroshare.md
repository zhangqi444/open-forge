---
name: retroshare
description: RetroShare recipe for open-forge. Decentralized, private, secure communication toolkit offering chat, forums, messaging, file transfer, and channels — all peer-to-peer over an encrypted F2F network. Source: https://github.com/RetroShare/RetroShare
---

# RetroShare

Decentralized, private, secure, cross-platform communication toolkit. Provides file sharing, chat, messages, forums, channels, boards and more over a Friend-to-Friend (F2F) encrypted network. Upstream: <https://github.com/RetroShare/RetroShare>. Downloads and docs: <https://retroshare.cc>.

RetroShare uses its own encrypted P2P protocol (not federated with ActivityPub or Matrix). All traffic is end-to-end encrypted between trusted friends. There is no central server — each node is identified by a PGP key.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| Binary release (GUI desktop app) | Linux, Windows, macOS | Download from https://retroshare.cc/downloads.html. Qt-based GUI. |
| Headless server (`retroshare-service`) | Linux | CLI daemon + web interface, suitable for server deployment. |
| Build from source | Linux, Windows, macOS | C++ / Qt5. See `build_scripts/` in the repo for platform-specific guides. |
| Flatpak / distro packages | Linux | Available in some distros and Flathub. |

> **Note:** RetroShare does not ship an official Docker image. The `retroshare-service` binary is the recommended server-side deployment.

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Which platform is this for?" | Linux server (headless) vs desktop (GUI) |
| setup | "External IP or hostname for this node?" | Needed for Direct Connections / TCP/UDP forwarding |
| network | "Which TCP/UDP ports will you forward?" | Default: `9090` TCP (configurable) |
| identity | "PGP key name / display name for this node?" | Used as the node's identity on the network |

## Software-layer concerns

- **Config dir (Linux):** `~/.retroshare/` — stores keys, contacts, downloaded files index
- **Default port:** `9090` TCP + UDP (configurable in Preferences > Network)
- **Web UI port (retroshare-service):** `9090` by default (also used for the JSON API on a separate port, default `9092`)
- **No database:** All state stored as flat files / SQLite in the config directory
- **PGP identity:** Generated on first run; back up `~/.retroshare/` to preserve your identity and friends list

### Running as a headless server

```bash
retroshare-service --webinterface 9090 --webinterfaceacl 127.0.0.1 \
  --jsonApiPort 9092 --jsonApiBindAddress 127.0.0.1
```

Then access the web UI at `http://localhost:9090`.

For autostart, create a systemd unit:

```ini
[Unit]
Description=RetroShare Service
After=network.target

[Service]
User=retroshare
ExecStart=/usr/bin/retroshare-service --webinterface 9090 --webinterfaceacl 127.0.0.1
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Upgrade procedure

1. Download the latest binary release from https://retroshare.cc/downloads.html
2. Stop the running service: `systemctl stop retroshare`
3. Replace the binary
4. Start: `systemctl start retroshare`
5. RetroShare has strong backward compatibility — config dir is preserved across upgrades

## Gotchas

- **Port forwarding required** for direct connections. Without it, RetroShare falls back to relay/Tor hidden services, which are slower.
- **Friend exchange is manual**: you share a PGP certificate string or file with friends out-of-band; there is no public discovery.
- **retroshare-service web UI** is basic; for full features use the Qt desktop client.
- **First run takes time** to generate the PGP key — do not kill the process.
- **No Docker image** from upstream; third-party images exist but are unsupported.

## References

- [Upstream README](https://github.com/RetroShare/RetroShare#readme)
- [Downloads page](https://retroshare.cc/downloads.html)
- [Documentation](https://retrosharedocs.readthedocs.io/en/latest/)
- [Linux build guide](https://github.com/RetroShare/RetroShare/blob/master/build_scripts/Debian+Ubuntu/Linux_InstallGuide.md)
