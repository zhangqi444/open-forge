---
name: ImmichFrame
description: "Digital photo frame display for Immich. Web demo + client apps. MIT. 3rob3/immichFrame. Docs site + demo site. Lightweight. Kiosk/raspberry pi use-case."
---

# ImmichFrame

ImmichFrame is **"make an old tablet/monitor/Pi into a digital photo frame pulling from your Immich library"** — a dedicated display-layer on top of Immich. Pulls random/filtered photos from Immich, cycles through them on a screen. Great for wall-mounted tablets, Raspberry Pi kiosk displays, Chromecast-able browser tabs.

Built + maintained by **3rob3** / immichFrame org. License: **MIT**. Documentation site + demo site. Active.

Use cases: (a) **wall-mounted tablet photo frame** (b) **Raspberry Pi + monitor photo frame** (c) **ChromeOS kiosk** (d) **retail/lobby slideshow** (e) **family-gift digital frame** (f) **screensaver on spare monitor** (g) **anti-doom-scroll decor** for families (h) **album-of-the-week display**.

**NOT a server on its own** — companion/client to **Immich** server. Add to Immich ecosystem.

Features (per README):

- **Web-based display** (browser kiosk-friendly)
- **Native apps** for some platforms
- **Pulls from Immich API**
- **Demo site** at <https://demo.immichframe.dev>
- **Docs site** at <https://immichframe.dev>

- Upstream repo: <https://github.com/immichFrame/ImmichFrame>
- Docs: <https://immichframe.dev>
- Demo: <https://demo.immichframe.dev>

## Architecture in one minute

- **Web app** (Vue/React likely) + **native clients**
- **Reads from Immich API** via access-token
- **No state of its own** typically (configuration only)
- **Resource**: tiny on display device
- **Port**: web UI (for web version)

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Docker** (web)   | Host web frame; display device browses to it                    | Primary                                                                                    |
| **Native apps**    | Android, others                                                                                                        | Alt                                                                                   |
| **Browser kiosk**  | Point Chromium at hosted instance                                                                                      | Alt — simplest for Pi                                                                                   |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Immich URL           | `https://photos.example.com`                                | Required     |                                                                                    |
| Immich API key       | Generate in Immich user settings                            | **CRITICAL** | **Leaked = full read of all photos**                                                                                    |
| Filters              | Album/person/date                                           | Config       |                                                                                    |
| Display interval     | Seconds per photo                                           | Config       |                                                                                    |

## Install via Docker (web version)

```yaml
services:
  immich-frame:
    image: ghcr.io/immichframe/immichframe:latest        # **pin version**
    ports: ["8080:8080"]
    environment:
      IMMICH_URL: "https://photos.example.com"
      IMMICH_API_KEY: ${IMMICH_API_KEY}
    restart: unless-stopped
```

## First boot

1. Generate Immich API key for a read-only-ish account
2. Deploy web frame
3. Point kiosk device browser at it (or install native app)
4. Configure filters (album/person)
5. Hide cursor / enter fullscreen
6. Enjoy photos

## Data & config layout

- **Nearly stateless** — config via env-vars

## Backup

No persistent data — just keep env/config.

## Upgrade

1. Releases: <https://github.com/immichFrame/ImmichFrame/releases>
2. Docker pull + restart
3. Native apps: update from distribution channel

## Gotchas

- **143rd HUB-OF-CREDENTIALS Tier 2 — IMMICH-READ-API-KEY**:
  - Stores Immich API key
  - Leaked key = read of ALL photos in Immich library (unless scoped)
  - **143rd tool in hub-of-credentials family — Tier 2**
- **KIOSK-DISPLAY-SHOULDER-SURFING**:
  - Photos may include private moments on public wall-display
  - Reinforces Reitti (116) kiosk pattern
  - **Kiosk-display-shoulder-surfing-risk: 2 tools** (Reitti+ImmichFrame) 🎯 **2-TOOL MILESTONE**
- **API-KEY-SCOPE-DISCIPLINE**:
  - Create dedicated read-limited user/key
  - Don't use admin key for display
  - **Recipe convention: "dedicated-reduced-scope-API-key-per-consumer callout"**
  - **NEW recipe convention** (ImmichFrame 1st formally)
- **COMPANION-TOOL-TO-IMMICH**:
  - Depends on Immich; no independent lifecycle
  - **Ecosystem-dependent-subsystem: 2 tools** (NC Talk+ImmichFrame) 🎯 **2-TOOL MILESTONE**
- **UNOFFICIAL-ECOSYSTEM-TOOL**:
  - Not Immich-org; third-party
  - Reinforces "unofficial-companion-tool-API-drift-risk" (112)
  - **Unofficial-companion-tool-family: 2 tools** (Immich Power Tools + ImmichFrame) 🎯 **2-TOOL MILESTONE**
- **NATIVE-APP-IS-CLIENT**:
  - Some platforms have native apps (Android etc.)
  - Reinforces client-app framing (Fladder 117)
  - **Client-app-not-server: 2 tools** (Fladder+ImmichFrame-native) 🎯 **2-TOOL MILESTONE**
- **DEMO-SITE-PROVIDED**:
  - <https://demo.immichframe.dev>
  - Try-before-self-host
  - **Recipe convention: "public-demo-site positive-signal"** — reinforces
- **DOCS-SITE-PROVIDED**:
  - <https://immichframe.dev>
  - Rare for a companion tool
  - **Recipe convention: "docs-site-for-companion-tool positive-signal"**
  - **NEW positive-signal convention** (ImmichFrame 1st formally)
- **MIT LICENSE**:
  - Permissive
- **INSTITUTIONAL-STEWARDSHIP**: 3rob3 + immichFrame org + docs-site + demo-site + MIT + active. **129th tool — unofficial-companion-with-full-docs sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + docs + demo + MIT + releases + multi-platform. **135th tool in transparent-maintenance family.**
- **DIGITAL-PHOTO-FRAME-CATEGORY:**
  - **ImmichFrame** — Immich client
  - **PhotoPrism's own display** — if on PhotoPrism
  - **Dakboard** — commercial; calendar + photos (not FOSS)
  - **Frameo** — commercial app
  - **manual browser slideshow** — point Chromium at a folder
- **ALTERNATIVES WORTH KNOWING:**
  - **PhotoPrism display** — if on PhotoPrism
  - **Manual browser** — if you want zero dependencies
  - **Choose ImmichFrame if:** you're on Immich and want a polished display.
- **PROJECT HEALTH**: active + docs + demo + MIT + multi-platform. Strong.

## Links

- Repo: <https://github.com/immichFrame/ImmichFrame>
- Docs: <https://immichframe.dev>
- Demo: <https://demo.immichframe.dev>
- Immich: <https://github.com/immich-app/immich>
