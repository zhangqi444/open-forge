---
name: Vince
description: "Vince Analytics — self-hosted Google Analytics alternative. Single Go binary. Drop-in Plausible script compatible. Automatic TLS. GDPR/CCPA/PECR compliant; no cookies. vinceanalytics org."
---

# Vince

Vince is **"Plausible — but a single-binary Go tool that drops in anywhere"** — a self-hosted alternative to Google Analytics. **Zero-dependency single binary**. **Drop-in replacement for Plausible Analytics** — point existing Plausible JS scripts at a vince instance. **Automatic TLS** (Let's Encrypt built-in). **GDPR/CCPA/PECR compliant**. No cookies.

Built + maintained by **vinceanalytics** org. Website + demo. Active. MIT or similar (check LICENSE).

Use cases: (a) **GA replacement** — privacy-respecting analytics (b) **Plausible-compatible** — reuse scripts (c) **single-binary deploy** — tiny ops burden (d) **GDPR-safe analytics** (e) **small-site analytics** (<10 sites) (f) **blog + personal-site analytics** (g) **public-dashboards for transparency** (h) **share-access to client-dashboards**.

Features (per README):

- **Automatic TLS** (Let's Encrypt)
- **Plausible script-compatible** drop-in
- **Outbound links / file downloads / 404s / custom events**
- **Time-period comparison**
- **Public dashboards**
- **Unique share-links** (password-protectable)
- **Zero-dependency single binary**
- **Easy to operate**
- **Unlimited sites + events**
- **Privacy-first** — no cookies; GDPR/CCPA/PECR

- Upstream repo: <https://github.com/vinceanalytics/vince>
- Website: <https://vinceanalytics.com>
- Blog: <https://vinceanalytics.com/blog/deploy-local/>
- Demo: <https://demo.vinceanalytics.com>

## Architecture in one minute

- **Go** single binary
- **Embedded storage** (custom format) — no external DB
- **Built-in Let's Encrypt**
- **Resource**: tiny — low-CPU, grows with event volume
- **Port**: 80 + 443

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Binary**         | Single file                                                     | **Primary**                                                                        |
| **Docker**         | If published                                                                                                           | Alt                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `analytics.example.com`                                     | URL          | **For auto-TLS**                                                                                    |
| Admin creds          | First-boot                                                  | Bootstrap    |                                                                                    |
| Sites to track       | Domains you'll add                                          | Config       |                                                                                    |
| Port 80 + 443        | Expose to world (for ACME)                                  | Network      |                                                                                    |

## Install

Download binary + run:
```sh
curl -L https://github.com/vinceanalytics/vince/releases/latest/download/vince-linux-amd64 -o vince
chmod +x vince
# See website for exact CLI flags
./vince --help
```

Add to your website:
```html
<!-- Same as Plausible: -->
<script defer data-domain="example.com" src="https://analytics.example.com/js/script.js"></script>
```

## First boot

1. Download + install
2. Start with your domain
3. ACME cert auto-issues
4. Create admin user
5. Add first site
6. Embed JS snippet
7. Verify events arriving in dashboard
8. Optional: configure public dashboard

## Data & config layout

- Single data directory (custom format)
- Config file or flags

## Backup

```sh
sudo tar czf vince-$(date +%F).tgz vince-data/
# **Contains analytics — GDPR-aware**
```

## Upgrade

1. Releases: <https://github.com/vinceanalytics/vince/releases>
2. Download new binary, replace, restart
3. Data-format compatibility usually preserved

## Gotchas

- **150th HUB-OF-CREDENTIALS Tier 3 — ANALYTICS DATA**:
  - Visitor analytics — IPs (hashed), user-agents, referrers, timestamps
  - GDPR scope — depends on hashing
  - **150th tool in hub-of-credentials family — Tier 3**
  - **150-TOOL HUB-OF-CREDENTIALS MILESTONE at Vince**
- **GDPR/CCPA/PECR-COMPLIANT-BY-DESIGN**:
  - No cookies
  - IP hashing
  - **Recipe convention: "privacy-law-compliant-by-design positive-signal"**
  - **NEW positive-signal convention** (Vince 1st formally)
- **PLAUSIBLE-SCRIPT-COMPATIBLE**:
  - Drop-in replacement
  - Huge migration value
  - **Recipe convention: "drop-in-replacement-for-OSS-tool positive-signal"**
  - **NEW positive-signal convention** (Vince 1st formally)
- **AUTOMATIC-TLS**:
  - No separate reverse proxy needed
  - Still fine behind a proxy
  - **Automatic-TLS-built-in: 2 tools** (Caddy-implicit + Vince) 🎯 **2-TOOL MILESTONE** (first formal tracking)
  - **NEW positive-signal convention** (Vince 1st formally)
- **ZERO-DEPENDENCY-SINGLE-BINARY**:
  - **Zero-dependency-single-binary: 2 tools** (Logdy+Vince) 🎯 **2-TOOL MILESTONE**
- **PUBLIC-DASHBOARD-DISCLOSURE-RISK**:
  - Public dashboards expose visitor patterns
  - Consider what's visible
  - **Recipe convention: "public-dashboard-disclosure-review callout"**
  - **NEW recipe convention** (Vince 1st formally)
- **SHARE-LINK-PASSWORD-PROTECTED**:
  - Individual dashboard-share with password
  - URL-as-access-gate (reinforces Chitchatter 114)
  - **Recipe convention: "password-protected-share-link positive-signal"**
  - **NEW positive-signal convention** (Vince 1st formally)
- **LEAN-VS-PLAUSIBLE**:
  - README explicit: not feature-parity; for single-entity self-host
  - **Recipe convention: "scope-limitation-honest-declaration positive-signal"**
  - **NEW positive-signal convention** (Vince 1st formally; 7th flavor of honest-declaration)
- **INSTITUTIONAL-STEWARDSHIP**: vinceanalytics org + website + blog + demo + tags/API + GDPR-focus + single-binary. **136th tool — Plausible-alternative-org sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + blog + demo + website + releases. **142nd tool in transparent-maintenance family.**
- **ANALYTICS-CATEGORY:**
  - **Vince** — Plausible-compatible; lean; single-binary
  - **Plausible** — Go; mature; script-compatible target
  - **Umami** — Node; popular
  - **Matomo** — PHP; mature; enterprise
  - **GoatCounter** — Go; simple; minimal
- **ALTERNATIVES WORTH KNOWING:**
  - **Plausible** — upstream-spec; mature; AGPL
  - **Umami** — if you want Node-based + polish
  - **GoatCounter** — if you want minimalist Go tool
  - **Matomo** — if you want enterprise-features
  - **Choose Vince if:** you want Plausible-compat + single-binary + auto-TLS + lean.
- **PROJECT HEALTH**: active + website + demo + Plausible-compat. Strong for niche.

## Links

- Repo: <https://github.com/vinceanalytics/vince>
- Website: <https://vinceanalytics.com>
- Plausible (upstream spec): <https://github.com/plausible/analytics>
- Umami (alt): <https://github.com/umami-software/umami>
- GoatCounter (alt): <https://github.com/arp242/goatcounter>
