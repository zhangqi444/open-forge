---
name: FreeSWITCH
description: "Software-defined telecom stack for voice, video, and messaging. Runs SIP, WebRTC, PSTN, conferencing, IVR, and voicemail on commodity hardware. C-based, highly extensible via Lua/Python/JavaScript scripting. MPL-1.1."
---

# FreeSWITCH

**What it is:** A full-featured open-source telephony platform. Powers PBX systems, call centers, conferencing bridges, IVR trees, and WebRTC gateways. Supports SIP, H.323, WebRTC, PSTN (via hardware or SIP trunks), and many codecs.

**Official site:** https://freeswitch.org  
**GitHub:** https://github.com/signalwire/freeswitch  
**Docs:** https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/  
**License:** MPL-1.1

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Bare metal / VM | Debian package | Recommended; official .deb packages via FSGET |
| Bare metal / VM | Build from source | Supported on Debian, RHEL/CentOS, macOS, Windows |
| Docker | signalwire/freeswitch image | Community-maintained; build-from-source Dockerfiles in repo |
| Raspberry Pi | Debian package | Officially supported |

---

## Inputs to Collect

### Pre-install
- SIP domain / public IP or hostname
- SIP trunk credentials (provider, username, password, server)
- Desired internal extension range (e.g. 1000-1019)
- Whether WebRTC is needed (TLS cert + STUN/TURN)
- Voicemail storage path

### Runtime
- Admin password for ESL (Event Socket Layer)
- Sofia SIP profile settings (internal port 5060, external port 5080)
- Codec preferences (PCMU, PCMA, G722, Opus, etc.)

---

## Software-Layer Concerns

### Config paths
- /etc/freeswitch/ - main config directory (XML-based)
- /etc/freeswitch/sip_profiles/ - SIP profiles (internal.xml, external.xml)
- /etc/freeswitch/dialplan/ - call routing rules
- /etc/freeswitch/directory/ - user/extension definitions
- /var/lib/freeswitch/recordings/ - call recordings
- /var/lib/freeswitch/voicemail/ - voicemail storage
- /var/log/freeswitch/ - logs

### Key env vars / settings
- default_password - default user password (change immediately!)
- domain - SIP domain (in vars.xml)
- external_rtp_ip / external_sip_ip - NAT traversal (set to public IP)
- ESL listens on 127.0.0.1:8021 by default; password in event_socket.conf.xml

### Ports
- 5060 UDP/TCP - SIP internal profile
- 5080 UDP/TCP - SIP external profile
- 5066 TCP - SIP over WebSocket (WebRTC)
- 7443 TCP - SIP over WebSocket TLS (WebRTC)
- 16384-32768 UDP - RTP media
- 8021 TCP - ESL (Event Socket Layer)

---

## Install (Debian - recommended)

```bash
wget -O - https://files.freeswitch.org/repo/deb/debian-release/fsget3.py | sudo python3
sudo apt install freeswitch-meta-all
sudo systemctl enable --now freeswitch
```

Docker build-from-source examples:
https://github.com/signalwire/freeswitch/tree/master/docker/examples

---

## Upgrade Procedure

```bash
sudo apt update && sudo apt upgrade freeswitch-meta-all
# Reload config without restart
fs_cli -x "reloadxml"
fs_cli -x "sofia profile internal restart"
```

---

## Gotchas

- NAT traversal is the #1 pain point - always set external_rtp_ip and external_sip_ip to your public IP; without this, one-way audio is common
- Default password (1234) in vars.xml must be changed before exposing to the internet
- RTP port range (16384-32768 UDP) must be open in firewall; missing these causes no audio
- ESL (port 8021) should not be exposed externally - it gives full control of FreeSWITCH
- Config is XML - hierarchical and verbose; use the vanilla config as a base
- mod_signalwire is bundled and allows pairing with SignalWire cloud for PSTN trunking

---

## Upstream Docs

- Installation: https://freeswitch.org/confluence/display/FREESWITCH/Installation
- Configuration guide: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/
- SIP profiles: https://developer.signalwire.com/freeswitch/FreeSWITCH-Explained/Configuration/Sofia-SIP-Stack/
