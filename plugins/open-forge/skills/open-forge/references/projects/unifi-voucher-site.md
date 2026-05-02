---
name: unifi-voucher-site-project
description: UniFi Voucher Site recipe for open-forge. Web platform for generating and managing UniFi network guest vouchers with Docker Compose. Based on upstream README at https://github.com/glenndehaan/unifi-voucher-site.
---

# UniFi Voucher Site

**What it is:** Web-based platform for generating and managing UniFi network guest WiFi vouchers. Supports OIDC SSO, REST API, receipt/PDF printing, email delivery, QR codes, and bulk export.
**Official URL:** https://github.com/glenndehaan/unifi-voucher-site
**License:** MIT

## Compatible Combos

| Infra | Runtime | Notes |
|-------|---------|-------|
| Any   | Docker Compose | Recommended |
| Any   | Docker CLI | Single container |

## Inputs to Collect

### Phase: provision
- Domain/subdomain for the voucher portal
- Port mapping (default: `3000`)
- UniFi OS Console IP address

### Phase: deploy
- `UNIFI_IP` — IP address of your UniFi OS Console
- `UNIFI_PORT` — Port of UniFi OS Console (443 or 8443)
- `UNIFI_TOKEN` — API Key created on the Integrations tab in UniFi OS
- `UNIFI_SITE_ID` — UniFi site ID (default: `default`)
- `UNIFI_SSID` — Guest SSID name (used in templates and QR codes)
- `UNIFI_SSID_PASSWORD` — Guest SSID password (leave empty for open networks)
- `AUTH_INTERNAL_PASSWORD` — Web UI login password (default: `0000` — change this!)
- `AUTH_INTERNAL_BEARER_TOKEN` — Bearer token for API access

## Software-Layer Concerns

### Docker Compose

```yaml
services:
  unifi-voucher-site:
    image: glenndehaan/unifi-voucher-site:latest
    ports:
      - "3000:3000"
    environment:
      UNIFI_IP: '192.168.1.1'
      UNIFI_PORT: 443
      UNIFI_TOKEN: ''
      UNIFI_SITE_ID: 'default'
      UNIFI_SSID: ''
      UNIFI_SSID_PASSWORD: ''
      AUTH_INTERNAL_ENABLED: 'true'
      AUTH_INTERNAL_PASSWORD: 'changeme'
      AUTH_INTERNAL_BEARER_TOKEN: 'your-uuid-here'
      AUTH_OIDC_ENABLED: 'false'
      AUTH_DISABLE: 'false'
    restart: unless-stopped
```

### Version Compatibility
- v8.x requires UniFi OS v4.2.8+ and UniFi Network v9.1.119+
- v7.x supports older UniFi Network Server (≥ v5.4.9)

### Upgrade
1. `docker compose pull`
2. `docker compose up -d`

### Migration from 7.x to 8.x
See the migration guide in the upstream README before upgrading major versions.

## Gotchas
- Requires a UniFi Access Point and the Hotspot Portal configured in UniFi Network (voucher authentication must be enabled)
- `UNIFI_TOKEN` is an Integration API Key from the UniFi OS Console — not your admin password
- `AUTH_INTERNAL_PASSWORD` defaults to `0000` — change it before exposing publicly
- OIDC authentication is optional; set `AUTH_OIDC_ENABLED=true` and configure `AUTH_OIDC_*` vars if using SSO
- Home Assistant integration available for centralized management

## References
- [Upstream README](https://github.com/glenndehaan/unifi-voucher-site)
- [Docker Hub](https://hub.docker.com/r/glenndehaan/unifi-voucher-site)
