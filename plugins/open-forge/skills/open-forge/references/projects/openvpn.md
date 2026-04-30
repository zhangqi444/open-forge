---
name: OpenVPN Community
description: The classic SSL/TLS VPN tunneling software. Battle-tested since 2001, runs on nearly every platform. OpenVPN, Inc. maintains it as `OpenVPN/openvpn` on GitHub. GPL-2.0-with-linking-exception.
---

# OpenVPN Community

OpenVPN is a mature, cross-platform, battle-tested VPN protocol + reference implementation. It creates point-to-site or site-to-site encrypted tunnels using SSL/TLS for key exchange and a custom protocol for the data plane (UDP or TCP).

The `OpenVPN/openvpn` repo is the **community edition** — the core binary (`openvpn`) that everyone else's management UIs wrap. It's not a "run this Docker image and get a VPN" project; it's the engine. For self-hosting, you almost always want a distribution that bundles openvpn + config helpers:

- **kylemanna/docker-openvpn** — de-facto Docker wrapper for CE; ancient but widely deployed
- **openvpn-install** script (Angristan fork) — bash script that installs + configures on any VPS
- **OpenVPN Access Server** — commercial product from OpenVPN, Inc. (different repo, different license, free for up to 2 connections)
- **Pritunl** — commercial-friendly open source management UI on top of OpenVPN
- **OpenVPN AS alternatives**: **OpenVPN-UI** (d3vilh/openvpn-ui), **OpenVPN-Admin** (various), **WireGuard** (not OpenVPN; simpler replacement)

## ⚠️ Consider WireGuard first

Front-loaded context: for new self-hosted VPNs in 2025+, **WireGuard** is usually the better choice:

- 10-100× faster on the same hardware
- 4000 lines of code vs OpenVPN's 100k+
- In-kernel (Linux)
- Simpler configuration
- Modern cryptography (Noise protocol)

Stick with OpenVPN when:

- You need to tunnel over TCP 443 to bypass aggressive firewalls (WireGuard is UDP-only)
- You need client certs + username/password MFA (Access Server territory)
- Existing corporate infra mandates it
- You're running AirVPN / Mullvad / ProtonVPN via their OpenVPN configs

## Compatible install methods

| Infra       | Runtime                                                     | Notes                                                                       |
| ----------- | ----------------------------------------------------------- | --------------------------------------------------------------------------- |
| Single VM   | `openvpn-install` script (Angristan)                        | **Easiest** standalone — <https://github.com/angristan/openvpn-install>     |
| Single VM   | Docker (`kylemanna/openvpn`)                                | Old but widely used; self-contained with helpers                            |
| Single VM   | Pritunl                                                     | Management UI on top of OpenVPN; <https://pritunl.com>                      |
| Single VM   | OpenVPN Access Server (AS)                                  | Commercial, **not this repo**; <https://openvpn.net/vpn-server/>            |
| Single VM   | Distro package (`apt install openvpn`) + manual config      | Max control; most work                                                      |
| Kubernetes  | Community Helm charts wrapping kylemanna                    | Niche                                                                       |
| Router      | OpenWRT / pfSense / OPNsense have native modules            | Good for always-on site-to-site                                             |

## Inputs to collect

| Input                    | Example                                   | Phase     | Notes                                                               |
| ------------------------ | ----------------------------------------- | --------- | ------------------------------------------------------------------- |
| Public IP / domain       | `vpn.example.com`                         | DNS       | Clients connect here                                                 |
| Transport + port         | `udp/1194` (default) or `tcp/443`         | Network   | UDP faster; TCP/443 bypasses restrictive firewalls                  |
| Server CA + cert + key   | generated via Easy-RSA                    | PKI       | Self-signed PKI; clients get client.crt + client.key                |
| Client certs             | one per client device                     | PKI       | Revoke via CRL when a device is lost                                |
| Tunnel network           | `10.8.0.0/24`                             | Runtime   | Pick something non-conflicting with LAN + typical cafe Wi-Fi        |
| Push routes              | `192.168.1.0/24`                          | Runtime   | LAN subnets accessible via VPN                                      |
| DNS push                 | `10.8.0.1` or public                      | Runtime   | Prevents DNS leaks                                                  |
| TLS crypt / auth key     | `openvpn --genkey secret ta.key`          | Security  | Adds HMAC pre-authentication — strongly recommended                 |

## Install via `openvpn-install` (easiest on a VPS)

Single-file bash script that sets up CA, server cert, client certs, iptables, sysctl — the whole thing:

```sh
# Debian / Ubuntu / Fedora / AlmaLinux / RockyLinux
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh
sudo ./openvpn-install.sh
# Interactive; defaults are reasonable
# Generates /root/<client>.ovpn when done — import into OpenVPN Connect / Tunnelblick / etc.
```

Re-running the script lets you add/revoke clients.

## Install via Docker (kylemanna/openvpn)

```sh
# Init PKI (one-time)
docker run -v ovpn-data:/etc/openvpn --rm kylemanna/openvpn \
  ovpn_genconfig -u udp://vpn.example.com
docker run -v ovpn-data:/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki
# prompts for CA passphrase

# Run
docker run -v ovpn-data:/etc/openvpn -d -p 1194:1194/udp \
  --cap-add=NET_ADMIN --restart unless-stopped \
  --name openvpn kylemanna/openvpn

# Issue a client cert
docker run -v ovpn-data:/etc/openvpn --rm -it kylemanna/openvpn \
  easyrsa build-client-full alice nopass
docker run -v ovpn-data:/etc/openvpn --rm kylemanna/openvpn \
  ovpn_getclient alice > alice.ovpn
```

Compose equivalent:

```yaml
services:
  openvpn:
    image: kylemanna/openvpn:2.4    # pin; image hasn't been updated often
    cap_add: [NET_ADMIN]
    ports: ["1194:1194/udp"]
    restart: unless-stopped
    volumes:
      - ovpn-data:/etc/openvpn
volumes:
  ovpn-data:
```

## Install via Pritunl (management UI)

Pritunl runs OpenVPN under a web UI. Use if you want user management, MFA, RBAC:

```sh
# Ubuntu 22.04
sudo tee /etc/apt/sources.list.d/pritunl.list << EOF
deb https://repo.pritunl.com/stable/apt jammy main
EOF
wget -qO - https://raw.githubusercontent.com/pritunl/pgp/master/pritunl_repo_pub.asc | sudo apt-key add -
sudo apt update && sudo apt install pritunl mongodb-org
sudo systemctl enable --now pritunl mongod
# Setup at https://<host>/
```

Docs: <https://docs.pritunl.com>.

## Data & config layout

Typical server install:

- `/etc/openvpn/server.conf` — main config
- `/etc/openvpn/ca.crt` + `server.crt` + `server.key` + `dh.pem` + `ta.key` — PKI
- `/etc/openvpn/ccd/` — per-client config overrides
- `/etc/openvpn/crl.pem` — revocation list
- `/var/log/openvpn.log` (if configured)
- `/etc/openvpn/easy-rsa/` — PKI state (if using easy-rsa)

Client config (`.ovpn`): all-in-one file with inline certs. OpenVPN Connect (iOS/Android/macOS/Windows) + Tunnelblick (macOS) + built-in NetworkManager OpenVPN plugin (Linux) all consume this.

## Backup

```sh
# Entire /etc/openvpn (PKI + config)
sudo tar czf openvpn-$(date +%F).tgz /etc/openvpn /root/easy-rsa 2>/dev/null

# Docker volume
docker run --rm -v ovpn-data:/src -v "$PWD":/backup alpine \
  tar czf /backup/ovpn-data-$(date +%F).tgz -C /src .
```

**CA private key (`ca.key`) is the crown jewel** — anyone with it can issue valid client certs. Keep it offline if possible.

## Upgrade

1. Distro packages: `apt upgrade openvpn` / `dnf upgrade openvpn`. Restart service.
2. Docker (kylemanna): image rarely updated — the project is quasi-maintained. Consider migrating to a more actively maintained fork or to WireGuard.
3. Pritunl: `apt upgrade pritunl` + restart.
4. OpenVPN 2.5 → 2.6: minor config changes (default cipher negotiation); read upstream release notes.
5. OpenVPN 2.7 (future): new cryptographic negotiation; plan for client update coordination.
6. **Revoke + re-issue all client certs** if the CA is ever compromised.

## Gotchas

- **This repo (`OpenVPN/openvpn`) is the C source code.** You don't "install it" with a Docker image from upstream; you use a distribution wrapper.
- **OpenVPN CE vs OpenVPN Access Server:** different products. AS is commercial, has a web UI, limits free tier to 2 connections. CE has no GUI.
- **UDP vs TCP.** UDP/1194 default; TCP is slower but works through almost any NAT/firewall. Use UDP unless you specifically need TCP/443 for bypassing.
- **TLS-crypt (or `tls-auth`) is essential** for DoS resistance + DPI fingerprint hiding. Always use it.
- **Default cipher may be weak.** OpenVPN 2.4 defaulted to BF-CBC; 2.5+ uses AES-256-GCM via ncp. Check your config: `cipher` should be `AES-256-GCM` or unset with `data-ciphers`.
- **MTU tuning matters.** `fragment 1400 \ mss-fix 1400` helps on networks where 1500-byte packets get mangled (cellular, airline Wi-Fi).
- **DNS leaks on Windows** — push `block-outside-dns` directive to force DNS over the tunnel.
- **iptables masquerading** required for the VPN clients to reach the internet via the server: `iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE`. Angristan's script and kylemanna image handle this; manual installs forget it.
- **Port forwarding at the router** is required if your OpenVPN server is behind NAT (home hosting).
- **Certificate revocation** needs `crl-verify` in server.conf pointing to `crl.pem`. Easy-RSA generates it; you must restart OpenVPN (or `SIGHUP`) to reload.
- **Easy-RSA v3 vs v2** — v3 is the current version; v2 is deprecated. Scripts differ.
- **`client-to-client`** directive allows VPN clients to reach each other. Off by default; enable only if needed (hub-and-spoke safer).
- **Pushing DNS:** `push "dhcp-option DNS 10.8.0.1"` + run a resolver (dnsmasq, pi-hole) on the server to avoid leaking DNS.
- **Time-synced clocks required** for TLS handshake. NTP on both server + clients.
- **Logging `auth.log` leaks client IPs and usernames.** Comply with your privacy policy / GDPR if offering VPN as a service.
- **Killswitch** is a client-side concept (NetworkManager, Tunnelblick option) — not a server directive.
- **kylemanna/openvpn image is outdated.** Many users have migrated to d3vilh/openvpn-ui (with UI), Angristan script, or WireGuard. Check the project's last commit date before committing to it.
- **License**: GPL-2.0 with linking exception (makes it compatible with OpenSSL-style linking).
- **Alternatives worth knowing:**
  - **WireGuard** — modern, fast, simpler
  - **Tailscale** — WireGuard + SaaS control plane; zero-config
  - **Headscale** — self-hosted Tailscale control plane
  - **Netbird** — open-source Tailscale-like with self-hosted management
  - **SoftEther** — alternative multi-protocol VPN
  - **Pritunl** — commercial-friendly wrapper on OpenVPN

## Links

- Repo (C source): <https://github.com/OpenVPN/openvpn>
- Website: <https://openvpn.net>
- Community wiki: <https://community.openvpn.net/openvpn>
- Manual: <https://openvpn.net/community-resources/reference-manual-for-openvpn-2-6/>
- Easy-RSA: <https://github.com/OpenVPN/easy-rsa>
- OpenVPN Access Server: <https://openvpn.net/vpn-server/>
- angristan/openvpn-install: <https://github.com/angristan/openvpn-install>
- kylemanna/docker-openvpn: <https://github.com/kylemanna/docker-openvpn>
- Pritunl: <https://pritunl.com>
- d3vilh/openvpn-ui: <https://github.com/d3vilh/openvpn-ui>
- Upstream releases: <https://github.com/OpenVPN/openvpn/releases>
- WireGuard (alternative): <https://www.wireguard.com>
