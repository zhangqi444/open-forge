---
name: prosody-im
description: Prosody IM recipe for open-forge. Feature-rich, easy-to-configure XMPP server written in Lua. MIT licensed. Source: https://prosody.im / https://hg.prosody.im/
---

# Prosody IM

A feature-rich and easy-to-configure XMPP (Jabber) server written in Lua. Supports modern XMPP extensions (XEPs) including multi-user chat (MUC), file transfer, push notifications, and federation. Low resource footprint, suitable for personal to community-scale deployments. MIT licensed. Source: <https://prosody.im>

## Compatible Combos

| Infra | Runtime | Notes |
|---|---|---|
| Debian / Ubuntu | APT + systemd | Official Prosody community packages; recommended |
| Fedora / RHEL | DNF + systemd | Available in Fedora repos |
| Any Linux | Source build + systemd | Build from Mercurial source |
| Any Linux | Docker | Community Docker images (not official) |

> Official Prosody community packages (deb/rpm) are strongly recommended over distro packages for up-to-date XEP support.

## Inputs to Collect

### Phase 1 — Preflight

| Prompt | Format | Notes |
|---|---|---|
| "XMPP domain?" | FQDN | e.g. example.com — users will be user@example.com |
| "Admin JID(s)?" | JID(s) | e.g. admin@example.com — must exist as a user |
| "TLS certificate source?" | letsencrypt / manual | Prosody can auto-use Let's Encrypt certs |
| "Enable file upload?" | Yes / No | HTTP file upload (mod_http_file_share) for MMS-style sharing |
| "Enable MUC (group chat)?" | Yes / No | Multi-user chat rooms |

### Phase 2 — Deploy

| Prompt | Format | Notes |
|---|---|---|
| "TURN server?" | Hostname:port / none | For WebRTC call support (coturn) |
| "Federation?" | Yes / No | Allow s2s (server-to-server) with other XMPP servers |
| "Storage backend?" | internal / sqlite / postgresql | Default is internal (flat file); SQLite recommended for small deployments |

## Software-Layer Concerns

- **Config file**: `/etc/prosody/prosody.cfg.lua` — Lua syntax; module list, virtualhost, component declarations.
- **TLS**: Required for modern XMPP clients. Prosody reads certs from `/etc/prosody/certs/`; use `prosodyctl cert import` to pull from Let's Encrypt.
- **Modules**: Community modules at https://modules.prosody.im/ — install to `/usr/lib/prosody/modules/` or `/usr/local/lib/prosody/modules/` and add to `modules_enabled`.
- **prosodyctl**: Management CLI — add users, reload config, check config, generate certs.
- **Ports**: 5222 (client-to-server), 5269 (server-to-server federation), 5280/5281 (HTTP/HTTPS for BOSH, websocket, file upload).
- **DNS SRV records**: Required for clients to auto-discover the server and for federation (`_xmpp-client._tcp`, `_xmpp-server._tcp`, `_xmpps-client._tcp`).

## Deployment

### Debian/Ubuntu (recommended)

```bash
# Add official Prosody community package repo
echo "deb https://packages.prosody.im/debian $(lsb_release -sc) main" | \
  tee /etc/apt/sources.list.d/prosody.list
wget -qO - https://prosody.im/files/prosody-debian-packages.key | apt-key add -
apt update && apt install prosody lua-unbound

# Configure
vim /etc/prosody/prosody.cfg.lua
# Set: VirtualHost "example.com", admins, modules_enabled/disabled, storage, etc.

# Add TLS certificates (Let's Encrypt path via certbot)
prosodyctl cert import /etc/letsencrypt/live/example.com/

# Create admin user
prosodyctl adduser admin@example.com

# Enable and start
systemctl enable --now prosody

# Check config for errors
prosodyctl check config
```

### Sample minimal config

```lua
admins = { "admin@example.com" }
modules_enabled = {
    "roster"; "saslauth"; "tls"; "dialback"; "disco";
    "carbons"; "pep"; "private"; "blocklist"; "vcard4";
    "vcard_legacy"; "version"; "uptime"; "time"; "ping";
    "register"; "admin_adhoc"; "smacks";
    "http_file_share"; "muc"; "mam";
}
allow_registration = false
c2s_require_encryption = true
s2s_require_encryption = true
authentication = "internal_hashed"
storage = "sqlite"

VirtualHost "example.com"
    ssl = {
        key = "/etc/prosody/certs/example.com.key";
        certificate = "/etc/prosody/certs/example.com.crt";
    }

Component "conference.example.com" "muc"
    name = "Conference rooms"
    restrict_room_creation = "local"

Component "upload.example.com" "http_file_share"
    http_file_share_size_limit = 10*1024*1024  -- 10 MB
```

### DNS records (required)

```
_xmpp-client._tcp.example.com. 86400 IN SRV 0 5 5222 xmpp.example.com.
_xmpp-server._tcp.example.com. 86400 IN SRV 0 5 5269 xmpp.example.com.
_xmpps-client._tcp.example.com. 86400 IN SRV 0 5 5223 xmpp.example.com.
```

## Upgrade Procedure

```bash
# APT
apt update && apt upgrade prosody
systemctl restart prosody

# Reload config without full restart:
prosodyctl reload
```

## Gotchas

- **DNS SRV records essential**: Without them, most XMPP clients cannot auto-discover your server; federation with other servers will also fail.
- **TLS cert permissions**: Prosody runs as the `prosody` user — cert files must be readable by it. `prosodyctl cert import` handles this; manual cert placement may not.
- **`c2s_require_encryption = true`**: Strongly recommended; without it, clients may connect unencrypted.
- **Community modules vs built-in**: Many modern XEPs (MAM, OMEMO support via PEP, smacks) require community modules from modules.prosody.im — distro packages may not include them.
- **File upload component domain**: `upload.example.com` must also resolve in DNS (A/AAAA or CNAME) and have a TLS cert.
- **Port 5269 for federation**: If hosting behind NAT/firewall, ensure port 5269 is open for s2s federation to work.
- **`allow_registration = false`**: Recommended for public deployments; open registration attracts spam bots.

## Links

- Homepage: https://prosody.im
- Documentation: https://prosody.im/doc/
- Community modules: https://modules.prosody.im/
- Packages: https://prosody.im/download/
- Source (Mercurial): https://hg.prosody.im/
