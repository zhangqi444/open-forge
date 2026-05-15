---
name: NPMplus
description: "Enhanced fork of Nginx Proxy Manager. HTTP/3/QUIC + CrowdSec/OpenAppSec + OIDC + mTLS + ECH + zstd/brotli + Alpine-based. AGPL-3.0 fork of MIT nginx-proxy-manager. ZoeyVid sole."
---

# NPMplus

NPMplus is **"Nginx Proxy Manager — but with HTTP/3, CrowdSec WAF, OIDC, mTLS, ECH, and hardened TLS built-in"** — an **enhanced fork** of [nginx-proxy-manager](https://github.com/NginxProxyManager/nginx-proxy-manager). Explicitly **AGPL-3.0 (fork)** despite upstream MIT.

Built + maintained by **ZoeyVid** (sole). Long list of improvements over upstream. Active.

## ⚠️ NOTABLE UPSTREAM DIFFERENCE

README explicitly says: **"please report issues first to this fork before reporting them to the upstream repository."** Makes clear this is a distinct fork with active issue-tracker. Also: **AGPL-3.0 fork of MIT upstream** — license-upgraded.

Use cases: (a) **NPM + HTTP/3** — modern protocols (b) **NPM + CrowdSec WAF** — community-threat-intel integration (c) **NPM + OIDC** — SSO for proxied apps (d) **NPM + hardened TLS** — enforce strong ciphers (e) **NPM + ML-KEM** — post-quantum TLS (f) **NPM + ECH** — Encrypted Client Hello (g) **NPM + mTLS** — client-cert auth (h) **NPM-replacement** for security-conscious ops.

Features over upstream (summarized from README):

- **HTTP/3/QUIC** (needs UDP 443)
- **CrowdSec + OpenAppSec** integration
- **ACME profiles** — Let's Encrypt shortlived default
- **OIDC** auth
- **ML-KEM (post-quantum TLS)**
- **HTTPS for NPMplus interface itself**
- **GoAccess** log-viewer integrated
- **Punycode domains**
- **Zstd + Brotli** compression
- **Always-sent security headers**
- **mTLS CA-cert upload**
- **File/PHP server support**
- **TLS cert compression (zlib-ng + brotli)**
- **Optional Encrypted Client Hello**
- **Local Gravatar cache** (privacy)
- **Local TOTP QR generation** (no third-party API)
- **Secure cookies + CSP** instead of local storage
- **Password-reset CLI** (SQLite only)

- Upstream repo: <https://github.com/ZoeyVid/NPMplus>
- Upstream-upstream: <https://github.com/NginxProxyManager/nginx-proxy-manager>

## Architecture in one minute

- **Alpine-based** single image (smaller than upstream)
- **Nginx** (custom-built with aws-lc + patches)
- **SQLite** (or MySQL — check docs)
- **Node.js** for admin UI
- **Optional**: CrowdSec/OpenAppSec agents
- **Resource**: low — Alpine
- **Port**: 80, 443, 443/udp (QUIC)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | Single image                                                                                                           | Primary                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Ports                | 80, 443, 443/udp (QUIC)                                     | Network      |                                                                                    |
| Admin creds          | Email + password                                            | Bootstrap    |                                                                                    |
| DNS                  | Pointed at server                                           | Prereq       | For ACME                                                                                    |
| HSTS preload         | Register with <https://hstspreload.org>                     | Optional     |                                                                                    |
| CrowdSec key (opt)   | API key                                                     | Optional     |                                                                                    |
| OIDC provider (opt)  | Client ID + secret                                          | Optional     |                                                                                    |

## Install via Docker

```yaml
services:
  npmplus:
    image: zoeyvid/npmplus:2026-04-21-r2        # **pin version**
    network_mode: host        # or publish 80, 443, 443/udp
    volumes:
      - ./npmplus-data:/data
    environment:
      TZ: UTC
    restart: unless-stopped
```

## First boot

1. Start; access via https (NPMplus serves its own UI over HTTPS)
2. Set admin password
3. Add proxy host for first service
4. Request Let's Encrypt cert
5. Enable OIDC if desired
6. Enable CrowdSec integration
7. Register HSTS preload (if desired)
8. Back up `/data`

## Data & config layout

- `/data/` — SQLite + Let's Encrypt certs + nginx configs

## Backup

```sh
sudo tar czf npmplus-data-$(date +%F).tgz npmplus-data/
# Contains LE private keys, user creds — **ENCRYPT**
```

## Upgrade

1. Releases: <https://github.com/ZoeyVid/NPMplus/releases>. Active.
2. Docker pull + restart
3. Read CHANGELOG for breaking changes (many security-features roll forward)

## Gotchas

- **145th HUB-OF-CREDENTIALS CROWN-JEWEL TIER 1 — EDGE-PROXY CREDS**:
  - Let's Encrypt private keys for ALL your domains
  - OIDC client secrets
  - Proxied-backend configs
  - Potential mTLS CA chains
  - **145th tool in hub-of-credentials family — Tier 1 CROWN-JEWEL**
  - **Reverse-proxy-edge-credential-hub: 1 tool** 🎯 **NEW FAMILY** (NPMplus) — though Caddy/NPM/Traefik would all qualify if we'd recipe'd them
- **LICENSE-UPGRADE FORK (MIT → AGPL-3.0)**:
  - Fork changes to AGPL — stronger copyleft
  - Contributors need to be aware
  - **Recipe convention: "license-upgrade-fork-MIT-to-AGPL neutral-signal"**
  - **NEW neutral-signal convention** (NPMplus 1st formally)
- **SOLE-MAINTAINER-FORK-OF-LARGER-PROJECT**:
  - ZoeyVid sole maintainer of a security-critical fork
  - Bus-factor = 1
  - **Recipe convention: "sole-maintainer-security-critical-fork callout"**
  - **NEW recipe convention** (NPMplus 1st formally) — critical nuance
- **FORK-FIRST ISSUE-REPORTING**:
  - Author requests issues go to fork first, not upstream
  - **Recipe convention: "fork-first-issue-reporting positive-signal"**
  - **NEW positive-signal convention** (NPMplus 1st formally)
- **HTTP/3 REQUIRES UDP/443 EXPOSE**:
  - Commonly forgotten
  - Also may need firewall/router-level UDP NAT
  - **Recipe convention: "HTTP3-UDP-port-exposure callout"**
  - **NEW recipe convention** (NPMplus 1st formally)
- **HSTS-PRELOAD-IS-IRREVERSIBLE**:
  - Once registered, browsers force HTTPS permanently
  - **Recipe convention: "HSTS-preload-irreversible-opt-in callout"**
  - **NEW recipe convention** (NPMplus 1st formally)
- **POST-QUANTUM-TLS-ML-KEM**:
  - Cutting-edge; may have compat issues
  - **Recipe convention: "post-quantum-TLS-early-adopter-risk callout"**
  - **NEW recipe convention** (NPMplus 1st formally)
- **MANY-FEATURE-FLAGS**:
  - Dozens of toggles (ECH, ML-KEM, OCSP-must-staple)
  - Each = potential foot-gun
  - **Recipe convention: "many-feature-flags-learning-curve neutral-signal"**
  - **NEW neutral-signal convention** (NPMplus 1st formally)
- **LOCAL-GRAVATAR-CACHE (privacy)**:
  - Doesn't leak user email to Gravatar
  - **Recipe convention: "local-third-party-cache-privacy-positive positive-signal"**
  - **NEW positive-signal convention** (NPMplus 1st formally)
- **LOCAL-TOTP-QR (privacy)**:
  - TOTP QR generated in-browser
  - **Recipe convention: "local-TOTP-QR-no-third-party positive-signal"**
  - **NEW positive-signal convention** (NPMplus 1st formally)
- **FORK-HONEST-DECLARATION**:
  - 6 flavors: life-pause, discontinuation, rewrite-pause, WIP, active-rewrite, closed-beta
  - NPMplus: **active-security-enhanced-fork** (neither dying nor WIP)
  - Distinct pattern from the 6 prior — honest ACTIVE positioning
- **INSTITUTIONAL-STEWARDSHIP**: ZoeyVid sole + AGPL-fork + security-focused + active + extensive-README + CHANGELOG + fork-first-policy. **131st tool — sole-maintainer-security-fork sub-tier** (NEW-soft; distinct from portracker's sole-maintainer pattern).
- **TRANSPARENT-MAINTENANCE**: active + extensive-CHANGELOG + fork-first-policy + extensive-README + security-features-list. **137th tool in transparent-maintenance family.**
- **REVERSE-PROXY-CATEGORY:**
  - **NPMplus** — NPM + security-enhancements (fork)
  - **Nginx Proxy Manager** — upstream; mature; MIT
  - **Caddy** — single-binary; automatic-HTTPS
  - **Traefik** — container-native; dynamic
  - **HAProxy** — low-level; high-perf
- **ALTERNATIVES WORTH KNOWING:**
  - **Caddy** — if you want automatic-HTTPS + simpler config + active
  - **NPM upstream** — if you want MIT + simpler
  - **Traefik** — if you want K8s/Docker dynamic
  - **Choose NPMplus if:** you want NPM-UX + modern-security + HTTP/3.
- **PROJECT HEALTH**: active + sole-maintainer (bus-factor 1) + security-focused + explicit-fork. Strong but single-person-risk.

## Links

- Repo: <https://github.com/ZoeyVid/NPMplus>
- Upstream: <https://github.com/NginxProxyManager/nginx-proxy-manager>
- Caddy (alt): <https://caddyserver.com>
- Traefik (alt): <https://github.com/traefik/traefik>
