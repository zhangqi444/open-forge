---
name: unifi-voucher-site
description: Recipe for UniFi Voucher Site — web-based platform for generating and managing UniFi network guest WiFi vouchers. Docker Compose, single container, no external DB.
---

# UniFi Voucher Site

Web-based platform for generating and managing UniFi network guest vouchers. Upstream: https://github.com/glenndehaan/unifi-voucher-site

Node.js + ExpressJS app that connects to your UniFi OS Console via its Integration API. Generates single-use or multi-use WiFi vouchers with configurable expiry, bandwidth, and data limits. Optionally emails or prints vouchers (80mm thermal / PDF).

## Prerequisites

- UniFi OS v4.2.8+ (Cloud Gateway, Cloud Key, or UniFi OS Server)
- UniFi Network v9.1.119+
- UniFi Integration API Key (created under UniFi OS → Settings → Integrations)
- Hotspot Portal enabled with voucher authentication

> **Upgrading from 7.x?** 8.x dropped support for the legacy standalone UniFi Network Server. See the migration guide in the README and migrate to UniFi OS Server first.

## Compatible combos

| Runtime | Notes |
|---|---|
| Docker Compose | Primary method — single container, no external DB |
| Docker run | Also supported; compose preferred |
| Home Assistant add-on | Community add-on available |

## Inputs to collect

| Phase | Prompt | Notes |
|---|---|---|
| preflight | UniFi OS Console IP | e.g. 192.168.1.1 |
| preflight | Console port | 443 (Cloud Key/OS) or 8443 (legacy) |
| preflight | UniFi Integration API Key | UniFi OS → Settings → Integrations |
| preflight | Site ID | Default: default |
| preflight | Guest SSID name | Used in QR codes and email templates |
| preflight | Guest SSID WPA password | Leave empty for Open networks |
| auth | Auth mode | internal / OIDC / disabled |
| auth | Admin password (internal) | Replaces default 0000 |
| auth | API bearer token (internal) | UUID format for REST API |
| vouchers | Voucher type definitions | Format: minutes,use,up_kbps,down_kbps,data_MB; |
| smtp (opt) | SMTP host, port, TLS, user, pass | For emailing vouchers to guests |

### Voucher type format

  expiration_minutes,usage_type,upload_kbps,download_kbps,data_limit_MB;

- usage_type: 0 = multi-use unlimited, 1 = single-use, N = multi-use N times
- Omit bandwidth/data to leave unlimited: 480,1,,,;
- Multiple types: 480,1,,,;1440,0,10000,10000,5120;

## Software-layer concerns

**Config:** All via environment variables — no config file.

**Data:** Stateless. Voucher records live in UniFi Controller, not this app. No volume needed.

**Port:** Container on 3000. Often kept LAN-internal (admin portal).

**API Key:** UNIFI_TOKEN is an Integration API Key (not username/password). Create under UniFi OS → Settings → Integrations.

**Kiosk mode:** Self-service at /kiosk. Enable with KIOSK_ENABLED: 'true'.

**Printing:** Set PRINTERS to pdf and/or ESC/POS printer IP. Layout: full, slim_qr, or slim.

## Docker Compose

```yaml
services:
  unifi-voucher-site:
    image: glenndehaan/unifi-voucher-site:latest
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      UNIFI_IP: '192.168.1.1'
      UNIFI_PORT: 443
      UNIFI_TOKEN: 'your-integration-api-key'
      UNIFI_SITE_ID: 'default'
      UNIFI_SSID: 'GuestWiFi'
      UNIFI_SSID_PASSWORD: ''
      AUTH_INTERNAL_ENABLED: 'true'
      AUTH_INTERNAL_PASSWORD: 'changeme'
      AUTH_INTERNAL_BEARER_TOKEN: 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
      AUTH_OIDC_ENABLED: 'false'
      AUTH_DISABLE: 'false'
      VOUCHER_TYPES: '480,1,,,;'
      VOUCHER_CUSTOM: 'true'
      SERVICE_WEB: 'true'
      SERVICE_API: 'false'
```

## Upgrade procedure

```bash
docker compose pull
docker compose up -d
```

No database migrations — app is stateless. Check releases for breaking changes, especially 7.x → 8.x.

## Gotchas

- **8.x requires UniFi OS v4.2.8+ and Network v9.1.119+** — legacy standalone Network Server not supported.
- **API Key not username/password** — old UNIFI_USERNAME/UNIFI_PASSWORD env vars are gone in 8.x.
- **Hotspot Portal must be configured** with voucher authentication enabled in UniFi.
- **Self-signed certs** — may need NODE_TLS_REJECT_UNAUTHORIZED: '0' for self-signed UniFi Console certs (not recommended for production).

## Links

- Upstream README + full env var reference: https://github.com/glenndehaan/unifi-voucher-site
- Docker Hub: https://hub.docker.com/r/glenndehaan/unifi-voucher-site
- Hotspot Portal guide: https://help.ui.com/hc/en-us/articles/115000166827
