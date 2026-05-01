# Deployrr

**Automated Docker-based homelab deployment tool — 160+ pre-configured apps, Traefik setup, auth integration (Authentik/Authelia), and stack management via an interactive CLI.**
Official site: https://www.simplehomelab.com/deployrr/
GitHub: https://github.com/SimpleHomelab/Deployrr
Docs: https://docs.deployrr.app

---

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Ubuntu / Debian | Node.js CLI (npx) | Primary supported platform |
| Arch, CentOS/RHEL/Rocky | Node.js CLI | Working but unsupported |
| Windows WSL / LXC / VM | Node.js CLI | Supported deployment targets |

---

## Inputs to Collect

### All phases
- Domain name(s) — Deployrr configures Traefik with Let's Encrypt (Cloudflare DNS challenge only)
- Cloudflare API token — required for SSL certificate issuance
- Auth provider choice — Authentik, Authelia, TinyAuth, or Google OAuth
- Debrid/media server credentials — for relevant app stacks (Plex, Jellyfin, Starr apps, Gluetun)

---

## Software-Layer Concerns

### Prerequisites
Node.js + npm must be installed first:
```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Install / Update
```bash
sudo npx @simplehomelab/deployrr@latest
# then run from anywhere:
deployrr
```

### What it sets up
- Traefik reverse proxy with automatic Let's Encrypt TLS
- Socket-Proxy for secure Docker API access
- CrowdSec intrusion detection
- 160+ apps: Portainer, Plex, Jellyfin, Starr apps, Gluetun, Dozzle, Uptime-Kuma, Homepage, n8n, Ollama, Open-WebUI, and more
- Automated backup and restore
- Monitoring and logging stack

### License tiers
- Free: essential features for basic setups
- Basic / Plus / Pro: paid tiers with additional features
- Annual website membership includes full access

---

## Upgrade Procedure

Re-run the same install command:
```bash
sudo npx @simplehomelab/deployrr@latest
```

---

## Gotchas

- DNS challenge provider is **Cloudflare-only** — ports 80/443 must be forwarded
- Primary support is Ubuntu/Debian; other distros work but are unsupported
- Some database-dependent apps may require manual DB removal when re-deploying
- V5 is end-of-life at v5.11.2 — migrate to v6 for continued updates

---

## References
- Documentation: https://docs.deployrr.app
- Full app list: https://github.com/SimpleHomelab/Deployrr/blob/main/APPS.md
- GitHub: https://github.com/SimpleHomelab/Deployrr#readme
