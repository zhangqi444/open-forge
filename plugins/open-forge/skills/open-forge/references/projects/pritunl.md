---
name: pritunl
description: Pritunl recipe for open-forge. Distributed enterprise VPN server built on OpenVPN. Web UI for managing users, organizations, and servers. MongoDB backend.
---

# Pritunl

Distributed enterprise VPN server built on the OpenVPN protocol. Provides a clean web UI for managing users, organizations, and VPN servers. Uses MongoDB as its backend. Supports multi-server clustering, Let's Encrypt, and TOTP 2FA. Upstream: <https://github.com/pritunl/pritunl>. Docs: <https://docs.pritunl.com/>.

> **Note:** Pritunl uses OpenVPN under the hood (not WireGuard). Clients use standard OpenVPN clients to connect. For WireGuard-based alternatives see: wg-easy, Netmaker, Netbird.

## Compatible install methods

| Method | When to use |
|---|---|
| RPM package (RHEL/Oracle/Rocky/Alma) | Recommended; upstream provides repo |
| DEB package (Ubuntu/Debian) | Recommended; upstream provides repo |
| Docker (community image) | Quick eval; no official image |

## Requirements

- MongoDB (required; can be local or Atlas)
- OpenVPN installed
- Linux with systemd

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | "Linux distro?" | Drives which package repo to use (RPM vs DEB) |
| preflight | "MongoDB URI?" | Default: local `mongodb://localhost:27017/pritunl` |
| preflight | "Domain for Pritunl web UI?" | For TLS; Pritunl can provision Let's Encrypt |

## Package install (Ubuntu)

Full guide: <https://docs.pritunl.com/docs/installation>

```bash
# Add MongoDB repo
sudo tee /etc/apt/sources.list.d/mongodb-org.list << EOF
deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse
EOF
curl -fsSL https://pgp.mongodb.com/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor

# Add Pritunl repo
sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb https://repo.pritunl.com/stable/apt jammy main
EOF
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com --recv 7568D9BB55FF9E5287D586017AE645C0CF8E292A

# Install
sudo apt update
sudo apt install -y mongodb-org pritunl
sudo systemctl enable --now mongod pritunl
```

## Initial setup

```bash
# Get initial setup key
sudo pritunl setup-key

# Open UI: https://<server-ip>
# Enter MongoDB URI and setup key
# Get default credentials:
sudo pritunl default-password
```

## Software-layer concerns

- Web UI: port `443` (HTTPS)
- VPN: OpenVPN uses ports `1194/udp` (default) or custom — configure per server in UI
- MongoDB: local instance fine for single-node; use replica set for HA
- Clustering: multiple Pritunl nodes can share the same MongoDB — clients connect to any node
- 2FA: TOTP via Google Authenticator / Authy; enable per-user in UI

## Upgrade procedure

```bash
sudo apt update && sudo apt upgrade pritunl
sudo systemctl restart pritunl
```

## Gotchas

- MongoDB is a hard dependency — start `mongod` before `pritunl`
- Pritunl uses its own OpenVPN binaries (`pritunl-openvpn`) — conflicts with system OpenVPN packages in some distros
- No official Docker image; community images exist but may lag releases
- Let's Encrypt auto-renewal requires port 80 accessible from the internet during renewal
- Default admin username is `pritunl`; get initial password with `sudo pritunl default-password`

## Links

- GitHub: <https://github.com/pritunl/pritunl>
- Docs: <https://docs.pritunl.com/>
- Install guide: <https://docs.pritunl.com/docs/installation>
