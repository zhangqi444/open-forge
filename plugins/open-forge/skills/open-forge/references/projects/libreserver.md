# LibreServer

**All-in-one home server configuration system based on Debian** — shell-based installer and management system that sets up a full personal internet server including email, chat, VoIP, wikis, blogs, social networks, and federated services. Runs on old laptops, single-board computers, or can be accessed via onion address.

**Official site:** https://libreserver.org
**Source:** https://github.com/bashrc2/libreserver
**License:** AGPL-3.0

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Home server / SBC / old laptop | Debian (bare metal) | Primary supported platform |
| VPS | Debian | Also supported |
| Tor hidden service | Debian | Onion address support built in |

---

## Inputs to Collect

### Phase 1 — Planning
- Hardware: home server, Raspberry Pi, old laptop, or VPS
- Whether to use clearnet domain, onion-only, or both
- Domain name (for clearnet access)

### Phase 2 — Deploy
- Debian installation (fresh install recommended)
- Domain name and DNS configuration
- Admin username and password

---

## Software-Layer Concerns

- **Shell-based:** Entire system configured and managed via shell scripts
- **Debian-based:** Designed for Debian; may work on derivatives but Debian is the tested platform
- **Federated services included:** Email (full stack), XMPP/Matrix chat, VoIP (SIP), wikis, blogs, Mastodon/ActivityPub social networking, and more
- **Onion support:** Can run exclusively on Tor hidden service without a domain name/public IP
- **Self-contained:** Manages its own Nginx config, TLS certificates, DNS updates, and service configuration

---

## Deployment

Follow the installation instructions at:
https://libreserver.org

Key steps:
1. Install Debian on your hardware
2. Follow the LibreServer installation script
3. Configure your domain and desired services via the web admin interface

Community/support: Matrix room `#epicyon:conduit.libreserver.org`

---

## Upgrade Procedure

```bash
# Via the admin web interface: update option available
# Or via command line per upstream documentation
```

---

## Gotchas

- **Fresh Debian install recommended** — installing on an existing configured system may cause conflicts
- **Opinionated defaults** — LibreServer makes many configuration decisions for you; highly customized setups may conflict
- **No AI tooling used in development** — project explicitly rejects AI-generated code; human-written only
- **Community-focused philosophy** — designed for federated personal/community servers, not enterprise use

---

## Links

- Upstream README: https://github.com/bashrc2/libreserver#readme
- Official site and installation guide: https://libreserver.org
- Matrix community: #epicyon:conduit.libreserver.org
