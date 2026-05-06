---
name: bitcart
description: Bitcart recipe for open-forge. Self-hosted cryptocurrency payments processor and development platform supporting Bitcoin and altcoins, with admin panel, store frontend, and REST API. Source: https://github.com/bitcart/bitcart
---

# Bitcart

Self-hosted cryptocurrency payment processor and development platform. Supports Bitcoin and many altcoins, provides a merchant admin panel, a ready-made store frontend, and a REST API for checkout integration. Ecosystem spans multiple repos: core daemons/API, admin UI, store, Docker packaging, and SDK. Upstream: https://github.com/bitcart/bitcart. Docs: https://docs.bitcart.ai.

## Compatible install methods

| Method | Platform | Notes |
|---|---|---|
| bitcart-docker setup script | Linux (Docker) | Recommended. Clones bitcart/bitcart-docker and runs setup.sh. |
| One-domain mode | Linux (Docker) | All services under a single domain using reverse proxy. |
| Multi-domain mode | Linux (Docker) | API, admin, and store on separate subdomains. |
| Local/LAN mode | Linux (Docker) | Use a .local domain; setup.sh patches /etc/hosts automatically. |
| Tor | Linux (Docker) | Set BITCART_TOR_SERVICES; no public domain needed. |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| setup | "Domain for Bitcart (one-domain mode)?" | e.g. payments.example.com — set as BITCART_HOST |
| setup | "Separate admin/store subdomains?" | If yes, set BITCART_ADMIN_HOST and BITCART_STORE_HOST |
| setup | "SSL / reverse proxy?" | setup.sh provisions Let's Encrypt automatically for public domains |
| crypto | "Which cryptocurrencies to enable?" | BTC enabled by default; add via BITCART_CRYPTOS env var |

## Software-layer concerns

Quick install (one-domain mode):

  sudo su -
  git clone https://github.com/bitcart/bitcart-docker
  cd bitcart-docker
  export BITCART_HOST=payments.yourdomain.tld
  ./setup.sh

Multi-domain mode:

  export BITCART_HOST=api.yourdomain.tld
  export BITCART_ADMIN_HOST=admin.yourdomain.tld
  export BITCART_STORE_HOST=store.yourdomain.tld
  export BITCART_ADMIN_API_URL=https://api.yourdomain.tld
  export BITCART_STORE_API_URL=https://api.yourdomain.tld
  ./setup.sh

Key env vars (set before running setup.sh):

  BITCART_HOST          - main domain (one-domain mode)
  BITCART_ADMIN_HOST    - admin panel domain (multi-domain)
  BITCART_STORE_HOST    - store frontend domain (multi-domain)
  BITCART_CRYPTOS       - comma-separated list of coins (default: btc)
  REVERSEPROXY          - nginx (default) or none

DNS: Point A records for all _HOST domains to your server before running setup.sh.

setup.sh installs Docker if missing, generates docker-compose files, creates a systemd/upstart service, and provisions SSL certificates.

## Upgrade procedure

  cd bitcart-docker
  ./setup.sh   # re-runs generator and pulls updated images
  # Or for minor updates:
  docker-compose pull
  docker-compose up -d

## Gotchas

- DNS A records must exist before running setup.sh — Let's Encrypt validation will fail otherwise.
- .local domains: only work for LAN/local access; setup.sh patches /etc/hosts on the server only.
- One-domain mode recommended for most self-hosters: simpler DNS, single SSL cert.
- Cryptocurrency daemon sync time: Bitcoin full-node sync takes days; ElectrumX/lightweight mode is faster — see docs for lightweight setup.
- Firewall: open ports 80, 443 (and 8080/8000 if running without reverse proxy).
- Admin panel and store are separate Docker services — both need to be running for full functionality.

## References

- Upstream README: https://github.com/bitcart/bitcart#readme
- Docker deployment: https://github.com/bitcart/bitcart-docker
- Full docs: https://docs.bitcart.ai
- Admin panel repo: https://github.com/bitcart/bitcart-admin
- Store repo: https://github.com/bitcart/bitcart-store
