# Flexisip

**Comprehensive, modular SIP server suite** written in C++17. Includes proxy server, push notification gateway (for mobile apps), presence server, B2BUA (Back-to-Back User Agent), and RegEvent server. Powers the linphone.org VoIP service since 2011.

**Official site:** https://www.linphone.org/en/flexisip-sip-server/  
**Source:** https://github.com/BelledonneCommunications/flexisip  
**License:** AGPL-3.0 (open source) / Proprietary (commercial, contact Belledonne Communications)

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Linux (Debian 12+) | Docker | Primary recommended path |
| Linux | Build from source (C++20) | Complex build; many dependencies |

> **Dual-licensed:** Free under AGPL-3.0 for open source projects. Commercial license available for closed-source use.

---

## System Requirements

- **C++ compiler:** GCC ≥ 13.0 or Clang ≥ 19.0 (C++20 required)
  - Debian 12: Only Clang supported (GCC too old)
- **Build tools:** make or Ninja, Python ≥ 3
- **Mandatory dependencies:** OpenSSL, libnghttp2, libsrtp2, SQLite3, libmysql-client
- **Optional:** Redis (Hiredis), SNMP (NetSNMP), XML (XercesC), JSON (jsoncpp), JWT (cpp-jwt), systemd

---

## Inputs to Collect

### Deploy phase
| Input | Description |
|-------|-------------|
| SIP domain | Your SIP/VoIP domain name |
| Transport | UDP/TCP/TLS port configuration |
| Push gateway config | APNs/FCM credentials (for mobile push) |
| Database | MySQL/SQLite for registrar |
| Redis URL | For clustering/replication (optional) |
| TLS certificates | Required for TLS transport |

---

## Software-layer Concerns

### Docker (recommended)
```bash
docker pull belledonnecommunications/flexisip:latest
docker run -d \
  --name flexisip \
  -p 5060:5060/udp \
  -p 5060:5060/tcp \
  -p 5061:5061/tcp \
  -v /etc/flexisip:/etc/flexisip \
  belledonnecommunications/flexisip:latest
```

See the [official documentation](https://www.linphone.org/en/flexisip-sip-server/#flexisip-documentation) for full Docker configuration with config file examples.

### Server components
| Module | Purpose |
|--------|---------|
| **Proxy** | Routes SIP messages between clients |
| **Push Gateway** | Delivers SIP calls/messages via APNs (iOS) and FCM (Android) when app is background |
| **Presence Server** | Online status and availability tracking |
| **B2BUA** | Caller ID translation, media transcoding, SIP trunking |
| **RegEvent Server** | Notifies tier domains of user registrations |

### Config file
Flexisip configuration lives in `/etc/flexisip/flexisip.conf`. Key sections:
- `[global]` — transports, log level, aliases
- `[module::Registrar]` — registrar backend (SQLite/MySQL/Redis)
- `[module::PushNotification]` — APNs/FCM credentials
- `[module::Presence]` — presence server settings

---

## Upgrade Procedure

```bash
docker pull belledonnecommunications/flexisip:latest
docker stop flexisip && docker rm flexisip
# Re-run docker run with same volume mounts
```

---

## Gotchas

- **Dual license.** AGPL-3.0 means any modifications must be open-sourced. For proprietary/commercial deployments, a commercial license from Belledonne Communications is required.
- **Complex production setup.** Flexisip is enterprise-grade SIP infrastructure, not a simple install. Plan for significant SIP/VoIP expertise.
- **Push notifications require app-specific credentials.** APNs certificates (iOS) and FCM server keys (Android) must be configured for push gateway functionality.
- **Clustering uses Redis.** For high-availability or multi-server setups, configure Redis (Hiredis) as the shared registrar backend.
- **Debian 12 GCC limitation.** GCC on Debian 12 doesn't support C++20; use Clang when building from source.
- **Related ecosystem:** Works with Linphone clients (iOS, Android, desktop) and any standards-compliant SIP client.

---

## References

- Official docs: https://www.linphone.org/en/flexisip-sip-server/#flexisip-documentation
- Supported RFCs: https://www.linphone.org/en/flexisip-sip-server/#flexisip-software
- Upstream README: https://github.com/BelledonneCommunications/flexisip#readme
