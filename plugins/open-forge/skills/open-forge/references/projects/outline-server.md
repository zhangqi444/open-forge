---
name: outline-server
description: Outline Server recipe for open-forge. Covers the official install-script method (Docker-based, Linux), manual Docker Compose deployment, and pairing with the Outline Manager desktop app for access key management. Upstream docs: https://github.com/OutlineFoundation/outline-server
---

# Outline Server

Self-hosted Shadowsocks VPN proxy server with a REST API for access key management. Designed for digital rights defenders and journalists to share censorship-resistant internet access. Pairs with the **Outline Manager** desktop app for a graphical control plane and the **Outline Client** app for end users. Upstream: <https://github.com/OutlineFoundation/outline-server> — Apache 2.0.

Outline Server runs a Shadowsocks instance (via `outline-ss-server`) per access key, plus a management REST API. The server is intentionally minimal: no web UI, no built-in TLS (Shadowsocks handles encryption natively), minimal logging (by design, to protect users).

## Compatible install methods

| Method | Upstream | First-party? | When to use |
|---|---|---|---|
| Install script (recommended) | <https://github.com/OutlineFoundation/outline-server#install-script> | Yes | One-liner bash script. Pulls Docker images, writes config, outputs management API URL + certificate fingerprint. Recommended for production Linux servers. |
| Manual Docker Compose | Community approach | Community | Advanced use: pin image versions, customise ports, integrate into existing Compose stack. |
| Outline Manager (guided) | <https://getoutline.org/set-up-your-own-vpn-server/> | Yes | GUI-assisted: Manager prompts you to run the install script on your server and pastes the results back in. Easiest for non-technical users. |

## Inputs to collect

| Phase | Prompt | Format | Applicability |
|---|---|---|---|
| preflight | Which install method? | Options: Install script / Manual Docker / Outline Manager guided | Drives method section |
| server | What is the public IP or hostname of your VPN server? | Free-text | All methods — needed for --hostname flag |
| ports | Custom management API port? (leave blank for random) | Free-text or blank | Install script (--api-port N) |
| ports | Custom access keys port? (leave blank for random) | Free-text or blank | Install script (--keys-port N) |
| firewall | Open required ports in your firewall? | Confirm | User must open management port + keys port (both TCP and UDP for keys port) |

## Install script method

Upstream: <https://github.com/OutlineFoundation/outline-server/tree/master/src/server_manager/install_scripts>

### Prerequisites

- Linux VPS (Ubuntu 20.04+ recommended), x86-64 or ARM64
- Docker + curl installed
- Root or sudo access
- Public IP reachable by clients

### Install

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/OutlineFoundation/outline-server/master/src/server_manager/install_scripts/install_server.sh)"
```

With explicit hostname and fixed ports (recommended for firewall rules):

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/OutlineFoundation/outline-server/master/src/server_manager/install_scripts/install_server.sh)" \
  install_server.sh \
  --hostname YOUR_PUBLIC_IP_OR_DOMAIN \
  --api-port 8443 \
  --keys-port 2233
```

The script:
1. Pulls quay.io/outline/shadowbox and quay.io/outline/watchtower
2. Creates /opt/outline/ with config and persistent data
3. Generates a self-signed TLS cert for the management API
4. Outputs a management API config string -- copy this into Outline Manager

### Output -- management API config string

After install, the script prints something like:

```
{"apiUrl":"https://<IP>:8443/<random-secret>","certSha256":"<hex-fingerprint>"}
```

Save this string. It is needed to pair with Outline Manager. If lost, retrieve from /opt/outline/access.txt.

### Firewall rules required

| Port | Protocol | Purpose |
|---|---|---|
| --api-port (e.g. 8443) | TCP | Management API (Outline Manager to server) |
| --keys-port (e.g. 2233) | TCP + UDP | Shadowsocks client traffic |

If using random ports, check /opt/outline/shadowbox_config.json for the assigned values.

```bash
# UFW example
ufw allow 8443/tcp
ufw allow 2233/tcp
ufw allow 2233/udp
```

## Manual Docker Compose method

For advanced users who want pinned versions or integration into an existing Compose stack.

```yaml
version: "3.8"

services:
  shadowbox:
    image: quay.io/outline/shadowbox:stable
    container_name: outline-server
    restart: unless-stopped
    network_mode: host
    environment:
      - SB_API_PORT=8443
      - SB_API_PREFIX=REPLACE_WITH_RANDOM_SECRET
      - SB_CERTIFICATE_FILE=/opt/outline/shadowbox-selfsigned.crt
      - SB_PRIVATE_KEY_FILE=/opt/outline/shadowbox-selfsigned.key
    volumes:
      - outline_data:/opt/outline
    cap_add:
      - NET_ADMIN

volumes:
  outline_data:
```

Note: network_mode: host is required. Shadowsocks binds one port per access key dynamically; bridge networking does not work without complex port-range mapping.

Generate TLS cert before first run:

```bash
openssl req -x509 -nodes -days 3650 -newkey ec -pkeyopt ec_paramgen_curve:P-256 \
  -subj "/CN=YOUR_IP" \
  -keyout /opt/outline/shadowbox-selfsigned.key \
  -out /opt/outline/shadowbox-selfsigned.crt

# Get cert fingerprint for Outline Manager:
openssl x509 -noout -fingerprint -sha256 -inform pem -in /opt/outline/shadowbox-selfsigned.crt
```

## Pairing with Outline Manager

1. Download Outline Manager from <https://getoutline.org/> (macOS, Windows, Linux, ChromeOS)
2. Click Set up Outline -> Add server -> Connect
3. Paste the management API config string (from install script output or /opt/outline/access.txt)
4. Manager connects and shows the server dashboard

From Manager you can:
- Create / delete access keys
- Rename keys
- Set per-key data limits
- Copy shareable ss:// access links for Outline Client users

## Data directory layout

| Path | Contents |
|---|---|
| /opt/outline/ | Server root (created by install script) |
| /opt/outline/access.txt | Management API URL + cert fingerprint |
| /opt/outline/shadowbox_config.json | Runtime config (ports, keys state) |
| /opt/outline/persisted-state/ | Persistent access key data |
| /opt/outline/shadowbox-selfsigned.crt | Management API TLS cert |
| /opt/outline/shadowbox-selfsigned.key | Management API TLS key |

## Upgrade procedure

The install script bundles Watchtower, which auto-updates Outline Server Docker images. To check:

```bash
docker ps | grep watchtower
```

To manually upgrade (if Watchtower is not running):

```bash
docker pull quay.io/outline/shadowbox:stable
docker restart outline-server
```

## Gotchas

- --hostname is required for remote servers. Without it the API URL defaults to 127.0.0.1 and clients cannot connect.
- network_mode: host is non-negotiable in Docker Compose. Per-key dynamic port binding requires host networking.
- No web UI. Management is exclusively via Outline Manager desktop app or direct REST API calls.
- Minimal logging by design. Outline logs access key IDs but not destination IPs or domains -- intentional privacy feature.
- Watchtower auto-updates the server by default. Pin the image tag in Compose if you prefer manual control.
- TLS cert is self-signed. The management API uses a self-signed cert; Outline Manager verifies it by certSha256 fingerprint, not CA chain. No domain required.
- Access keys are Shadowsocks URLs (ss://). Share them via Outline Manager. End users install Outline Client and paste the link.
- Cloud firewall gotcha: AWS, GCP, Hetzner etc. have a separate network-level firewall independent of ufw. Open both the API port and keys port in the cloud console AND in the OS firewall.
- IPv6: Outline supports IPv6 but the install script defaults to IPv4. If your server is IPv6-only, pass --hostname with the IPv6 address.

## Upstream docs

- GitHub: <https://github.com/OutlineFoundation/outline-server>
- Outline project site: <https://getoutline.org/>
- Outline Manager releases: <https://github.com/OutlineFoundation/outline-apps/releases>
- Shadowsocks resistance against blocking: <https://github.com/OutlineFoundation/outline-server/blob/master/docs/shadowsocks.md>
