---
name: DDNS Updater
description: "Lightweight Go daemon that keeps DNS A/AAAA records up-to-date across 50+ DNS providers. Docker + static-binary + AUR. MIT license. qdm12 — prolific sole-maintainer (Gluetun et al). Active; versioned docs."
---

# DDNS Updater

DDNS Updater is **"a tiny Go daemon that updates DNS records when your public IP changes"** — run it at home behind a dynamic-IP ISP, and it keeps your DNS records (A for IPv4, AAAA for IPv6) updated across 50+ DNS providers (Cloudflare, GoDaddy, Namecheap, Google Domains, Hetzner, DigitalOcean, DuckDNS, etc.). Zero-dependency binary + tiny Docker image (~5MB). MIT licensed. Widely-deployed in the homelab community.

Built + maintained by **qdm12** (Quentin McGaw) — same maintainer as **Gluetun** (VPN sidecar), **caddy-scratch**, **srv-scan**, and many other homelab staples. License: **MIT** (explicitly). Active; versioned docs (per program version); Docker on ghcr.io + Docker Hub; binaries for Linux/Windows/macOS; AUR package.

Use cases: (a) **home server behind dynamic IP** — ISP rotates public IP; DDNS keeps domain pointed correctly (b) **self-hosting any public service** from home — Plex/Nextcloud/etc. need stable DNS (c) **WireGuard / Tailscale exit node at home** with public endpoint (d) **hobby website at home** — cheaper than VPS (e) **migrating DNS providers** — DDNS updater works across providers; easy to swap (f) **IPv6 support** — many DDNS tools are IPv4-only; DDNS Updater handles both.

Features (per upstream README):

- **50+ DNS providers**: Aliyun, AllInkl, ChangeIP, Cloudflare, DigitalOcean, DuckDNS, Dreamhost, DynDNS, Gandi, GoDaddy, Google (Domains), He.net (Hurricane Electric), Hetzner, Infomaniak, Ionos, IPv64, Linode, Namecheap, NoIP, OVH, Porkbun, Route53 (AWS), Scaleway, Selfhost.de, Spaceship, Strato, Yandex, Zoneedit, many more
- **A + AAAA** record support
- **Zero-dependency binaries** (static Go)
- **Tiny Docker image** (~5MB from scratch)
- **Web UI** for status
- **Versioned docs** per release

- Upstream repo: <https://github.com/qdm12/ddns-updater>
- Docker (ghcr.io): <https://github.com/qdm12/ddns-updater/pkgs/container/ddns-updater>
- Docker Hub: <https://hub.docker.com/r/qmcgaw/ddns-updater>
- Releases (binaries): <https://github.com/qdm12/ddns-updater/releases>
- AUR: <https://aur.archlinux.org/packages/ddns-updater>

## Architecture in one minute

- **Go** static binary
- Config: JSON file (`config.json`) + env vars
- **Resource**: tiny — 10-30MB RAM; near-zero CPU
- **Port**: web UI 8000 default (optional; can run headless)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker**         | **`qmcgaw/ddns-updater` or `ghcr.io/qdm12/ddns-updater`**       | **Primary**                                                                        |
| Binary             | Static releases from GitHub                                     | No dependencies                                                                                   |
| AUR                | `ddns-updater` on Arch                                         | Arch                                                                                               |
| systemd            | Binary + systemd unit                                          | Linux                                                                                              |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| DNS provider         | Cloudflare / Namecheap / etc.                               | Config       | One or multiple                                                                                    |
| API credentials      | Provider API token / key                                    | **CRITICAL** | **DNS-control capability**                                                                                    |
| Domain(s)            | `home.example.com`                                          | Config       | Multiple allowed                                                                                    |
| Record type          | A (IPv4), AAAA (IPv6), or both                              | Config       |                                                                                    |
| Check interval       | Default 5min                                                | Config       |                                                                                    |

## Install via Docker

```sh
mkdir -p ddns-data
cat > ddns-data/config.json << 'EOF'
{
  "settings": [
    {
      "provider": "cloudflare",
      "zone_identifier": "YOUR_ZONE_ID",
      "domain": "home.example.com",
      "ttl": 600,
      "token": "YOUR_CF_API_TOKEN",
      "ip_version": "ipv4"
    }
  ]
}
EOF

docker run -d \
  -p 8000:8000 \
  -v $(pwd)/ddns-data:/updater/data \
  --name ddns-updater \
  --restart unless-stopped \
  qmcgaw/ddns-updater:v2.10.0     # **pin version — versioned docs recommend**
```

## First boot

1. Get API token from DNS provider (scope = DNS edit for specific zone)
2. Write `config.json` with provider-specific fields (per upstream docs)
3. Start container
4. Browse `:8000` — check status page
5. Verify DNS record updates on first run
6. (Optional) Integrate with monitoring (Uptime-Kuma / Tianji / Gatus)

## Data & config layout

- `config.json` — provider credentials + domains
- `updates.json` — history of updates (rotating)

## Backup

```sh
# Just back up the config + update history
cp ddns-data/config.json ddns-updater-config-$(date +%F).json
```

## Upgrade

1. Releases: <https://github.com/qdm12/ddns-updater/releases>. Active; frequent.
2. **Versioned docs**: match README + docs to program version (README links per-version docs)
3. Docker: pull pinned version + restart
4. Config schema occasionally changes between major versions — read release notes

## Gotchas

- **DNS-PROVIDER API TOKENS = HIGH-VALUE CREDENTIALS**:
  - Token scope matters: **DNS-Edit-specific-zone** is the minimum privilege needed
  - Full-account tokens = attacker can modify billing, move domains out, or resell
  - Cloudflare: use scoped API Tokens (not Global API Key)
  - Namecheap: use domain-specific API access with IP-allowlist
  - **62nd tool in hub-of-credentials family — Tier 2 with DNS-control-sensitivity**
  - **Compromise impact**: attacker who steals token can:
    - Point your domain at attacker-controlled IP (phishing your users)
    - Create subdomains (phishing)
    - Delete records (DoS)
    - **Not** transfer domain (usually needs registrar auth)
- **LEAST-PRIVILEGE TOKEN CONFIGURATION IS CRITICAL**:
  - **Recipe convention: "DNS-API-token-least-privilege" callout** — applies to any DNS-interacting tool
  - **NEW recipe convention** — 1st tool named here (DDNS Updater)
- **PUBLIC-IP DISCLOSURE**:
  - DNS record publicly visible = your home IP visible
  - **Privacy implication**: anyone can `dig` your domain → know your approximate location
  - Mitigation: Cloudflare proxy (orange cloud) → DNS returns Cloudflare IP, not yours
  - Proxy limits: doesn't work for non-HTTP (WireGuard, SSH)
- **IP-CHECK-SERVICES FINGERPRINTING**:
  - DDNS Updater checks "what's my public IP" via external services (ipify, ifconfig.co, etc.)
  - Those services log your home IP + user-agent
  - **Mitigation**: use router's own IP-reporting, or anonymize via VPN-checked-IP
- **VERSIONED DOCS = BEST-PRACTICE REWARDING STABLE-INTERFACE**:
  - README + docs versioned per release
  - Upgrading tool = read docs for YOUR version, not HEAD
  - **Recipe convention: "versioned-docs-with-matched-README" quality signal** — rare but excellent
  - **NEW positive-signal convention** — 1st tool named (DDNS Updater)
- **QDM12 MAINTAINER-ECOSYSTEM**:
  - qdm12 is prolific: DDNS Updater + Gluetun (used in Dispatcharr 96, slskd 98 VPN-sidecar recipes) + caddy-scratch + srv-scan + many more
  - Consistent quality, design philosophy, Go-native stack
  - **Recipe convention: "prolific-maintainer-ecosystem" signal** — noting when a maintainer has a coherent related toolset
  - **NEW positive-signal convention** — 1st tool explicitly named (DDNS Updater; retroactive to Gluetun)
- **DEPENDENT-ON-PROVIDER-API STABILITY**:
  - Each DNS provider has its own API
  - Provider changes API or tokens = DDNS Updater breaks for that provider
  - Breaking-changes happen (e.g., Google Domains was sold to Squarespace; API deprecated)
  - **Recipe convention: "multi-provider-API-drift-risk"** — tools dependent on many third-party APIs have broader maintenance surface
- **HUB-OF-CREDENTIALS TIER 2**:
  - DNS provider API tokens for every domain you update
  - Web UI (if exposed) shows domains + update history
  - **62nd tool in hub-of-credentials family — Tier 2.**
- **WEB UI = SHOULD BE INTERNAL-ONLY**:
  - Default port 8000; exposes status + update history
  - Don't expose web UI to the internet — should be LAN-only or behind auth
  - Use `LISTENING_ADDRESS=127.0.0.1:8000` or firewall
- **CHANGELOG QUALITY**: qdm12 writes detailed changelogs + supports older versions. Good-maintenance signal.
- **TRANSPARENT-MAINTENANCE**: active + versioned-docs + CI + multiple-distributions (Docker + AUR + binary) + 50+ providers supported + MIT + public-stats-badges. **55th tool in transparent-maintenance family.**
- **INSTITUTIONAL-STEWARDSHIP**: qdm12 + community. **48th tool — sole-maintainer-prolific-homelab-ecosystem sub-tier** (**NEW sub-tier**) — distinct from sole-maintainer-with-community because qdm12 has an identifiable portfolio of tools (Gluetun, DDNS Updater, etc.).
  - **NEW sub-tier: "prolific-sole-maintainer-with-coherent-toolset"**
  - **1st tool named explicitly** (DDNS Updater); retroactive to Gluetun.
- **MIT LICENSE = PERMISSIVE**:
  - Commercial re-use allowed
  - Common choice for infrastructure tools
- **ALTERNATIVES WORTH KNOWING:**
  - **cloudflared** + `cloudflared tunnel` — if on Cloudflare, Cloudflare Tunnel bypasses DDNS entirely (traffic goes out-and-back via CF)
  - **Tailscale / WireGuard with public-exit** — different paradigm (VPN, not public DNS)
  - **inadyn** — classic DDNS client; C-based; more narrow provider support
  - **ddclient** — Perl; classic; long-standing; growing-narrower provider support
  - **Cloudflare Dynamic DNS scripts** — bash + cron; DIY
  - **Provider-specific tools** (Namecheap's own, etc.)
  - **Choose DDNS Updater if:** you want modern + Go + wide-provider-support + MIT + active.
  - **Choose inadyn if:** you want classic minimalist with narrow needs.
  - **Choose Cloudflare Tunnel if:** you're Cloudflare-native + want zero-exposure.
- **PROJECT HEALTH**: active + qdm12-maintained + versioned docs + 50+ providers + multi-distribution + wide-use in homelab community. EXCELLENT signals for a widely-deployed infra tool.


## Links

- Repo: <https://github.com/qdm12/ddns-updater>
- Docker ghcr: <https://github.com/qdm12/ddns-updater/pkgs/container/ddns-updater>
- Docker Hub: <https://hub.docker.com/r/qmcgaw/ddns-updater>
- Releases: <https://github.com/qdm12/ddns-updater/releases>
- AUR: <https://aur.archlinux.org/packages/ddns-updater>
- qdm12 profile: <https://github.com/qdm12>
- Gluetun (same maintainer): <https://github.com/qdm12/gluetun>
- Cloudflare Tunnel (alt): <https://www.cloudflare.com/products/tunnel/>
- inadyn (alt classic): <https://github.com/troglobit/inadyn>
- ddclient (alt classic): <https://github.com/ddclient/ddclient>
