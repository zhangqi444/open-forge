---
name: Mini QR
description: "Scan and generate customized QR codes. Vue/Vite SPA. PWA. 30+ languages. Frame customization; presets; CSV batch export; WCAG-A compliant. GPL-v3. lyqht. Gigazine-reviewed."
---

# Mini QR

Mini QR is **"a beautiful QR-code generator + scanner — fully client-side"** — create beautiful customized QR codes, scan various QR code types. Runs in browser (SPA) + installable as PWA. **No server-side state required**. 30+ languages. Minimal WCAG-A compliant. Gigazine-reviewed.

Built + maintained by **lyqht (Estee Tey)**. License: **GPL-v3**. Active. Multi-preset (Padlet, Supabase, Vercel, ViteConf, etc.).

Use cases: (a) **QR-code-of-the-day for marketing** (b) **WiFi-QR for guests** (c) **vCard-QR** (d) **event-check-in QR** (e) **URL-shortener-alternative** (f) **CSV-batch QR export** (g) **print-ready QR** with frames + logos (h) **privacy-conscious QR-gen** (no cloud-leak of URLs).

Features (per README):

- **Customizable colors + styles**
- **Export**: PNG, JPG, SVG
- **Copy to clipboard**
- **Light/dark/system-preference**
- **Randomize style button**
- **30+ languages**
- **Save + load** config
- **Custom logo image**
- **Presets**
- **Frame customization + text labels**
- **Error-correction-level** tunable
- **QR scanner** — camera or image upload
- **Batch CSV export**
- **PWA installable**
- **Data templates**: text, URL, email, phone, SMS, WiFi, vCard, location, calendar

- Upstream repo: <https://github.com/lyqht/mini-qr>

## Architecture in one minute

- **Vue/Vite SPA**
- **Client-side only** (no server)
- **Static hosting** compatible
- **Resource**: tiny — static files
- **Port**: 80/443 via static hosting

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Static hosting** | **Netlify, Vercel, Pages, nginx**                               | **Primary**                                                                        |
| **Docker**         | nginx + built assets                                                                                                   | Alt                                                                                   |
| **PWA**            | Install from browser                                                                                                   | End-user                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Domain               | `qr.example.com`                                            | URL          | TLS for PWA                                                                                    |
| Build + serve        | Vite build → static files                                   | Deploy       |                                                                                    |

## Install (Docker)

```yaml
services:
  mini-qr:
    image: lyqht/mini-qr:latest        # **pin if published**
    ports: ["8080:80"]
    restart: unless-stopped
```

Or clone + build + serve statically:
```sh
git clone https://github.com/lyqht/mini-qr.git
cd mini-qr
npm install
npm run build
# Serve dist/ from any static host
```

## First boot

1. Build + deploy
2. Browse; test QR generation + scan
3. Install as PWA on phone/desktop
4. Put behind TLS (PWA requires HTTPS)

## Data & config layout

- Client-side only — no server state
- Per-user saved configs stored in browser localStorage

## Backup

No server-side data to back up.

## Upgrade

1. Releases: <https://github.com/lyqht/mini-qr/releases>
2. Rebuild + redeploy static assets

## Gotchas

- **149th HUB-OF-CREDENTIALS Tier 4/ZERO — FULLY-CLIENT-SIDE**:
  - No server state; no network calls from the tool itself
  - Sensitive data (WiFi passwords encoded in QR) never leaves browser
  - **149th tool in hub-of-credentials family — Tier 4/ZERO**
  - **Zero-credential-hub-tool Tier 4/ZERO: 4 tools** (MAZANOKE+Chitchatter+Logdy+Mini QR) 🎯 **4-TOOL MILESTONE**
  - **Stateless-tool-rarity: 14 tools** (+Mini QR) 🎯 **14-TOOL MILESTONE**
- **CLIENT-SIDE-PRIVACY-POSITIVE**:
  - QR generation = cryptographically-trivial; doing it client-side = data doesn't leave
  - WiFi passwords, vCards, etc. stay private
  - **Recipe convention: "client-side-crypto-privacy-positive positive-signal"**
  - **NEW positive-signal convention** (Mini QR 1st formally)
- **WCAG-A-ACCESSIBILITY**:
  - Minimally-compliant-to-WCAG-A
  - **Recipe convention: "WCAG-accessibility-compliance positive-signal"**
  - **NEW positive-signal convention** (Mini QR 1st formally) — rare to call out in self-hosted tools
- **30+LANGUAGES**:
  - Broad i18n
  - **Recipe convention: "extensive-i18n-30-plus-languages positive-signal"**
  - **NEW positive-signal convention** (Mini QR 1st formally)
- **PRESS-RECOGNITION (Gigazine)**:
  - Media reviewed
  - **Recipe convention: "press-media-recognition positive-signal"**
  - **NEW positive-signal convention** (Mini QR 1st formally)
- **CSV-BATCH-EXPORT**:
  - Bulk generation
  - **Recipe convention: "bulk-generation-CSV-import positive-signal"**
  - **NEW positive-signal convention** (Mini QR 1st formally)
- **RICH-DATA-TYPES**:
  - 9+ data types (text, URL, email, phone, SMS, WiFi, vCard, location, calendar)
  - **Recipe convention: "rich-structured-data-types positive-signal"**
  - **NEW positive-signal convention** (Mini QR 1st formally)
- **GPL-V3**:
  - Strong copyleft
  - Contrast MIT-permissive
  - **Recipe convention: "GPL-v3-strong-copyleft neutral-signal"** — reinforces
- **PWA-INSTALLABLE**:
  - Works offline post-install
  - **PWA-installable: 3 tools** (Tasks.md + Mini QR + [earlier ones]) 🎯 **3-TOOL MILESTONE** (approximate)
- **INSTITUTIONAL-STEWARDSHIP**: lyqht solo + i18n + accessibility + press-reviewed + PWA. **135th tool — solo-OSS-with-polish sub-tier**.
- **TRANSPARENT-MAINTENANCE**: active + GPL-v3 + i18n + PWA + multi-platform-exports + presets. **141st tool in transparent-maintenance family.**
- **QR-CODE-TOOL-CATEGORY:**
  - **Mini QR** — pretty + client-side + generator+scanner
  - **qrencode** (CLI) — Unix-classic
  - **GoQR.me** (commercial web)
  - **qr.io** (commercial web)
- **ALTERNATIVES WORTH KNOWING:**
  - **qrencode CLI** — if you want scriptable
  - **Choose Mini QR if:** you want pretty + privacy + accessibility + multi-format.
- **PROJECT HEALTH**: active + i18n + PWA + GPL-v3 + press-recognized. Strong.

## Links

- Repo: <https://github.com/lyqht/mini-qr>
- qrencode (alt CLI): <https://fukuchi.org/works/qrencode/>
