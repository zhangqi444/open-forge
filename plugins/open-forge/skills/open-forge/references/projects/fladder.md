---
name: Fladder
description: "Cross-platform Jellyfin frontend built on Flutter. Desktop + mobile + web. Stream or sync locally; direct/transcode/offline playback; trickplay; intro/credit skipping; multiple profiles + servers. DonutWare org. Conventional Commits."
---

# Fladder

Fladder is **"Swiftfin/Infuse — but Flutter, so Android + iOS + macOS + Linux + Windows + Web all from one codebase"** — a **cross-platform Jellyfin frontend** built on Flutter. Plays + syncs content to device. Multi-profile + multi-server switching. Direct, transcode, offline playback. **Intro/credit skipping**. **Trickplay** (timeline scrubbing thumbnails).

**NOT a server** — this is a **client app** for your existing Jellyfin server. Covered as a recipe for operators who want to recommend/distribute a client to users.

Built + maintained by **DonutWare** org. License: check LICENSE. Active build CI; Conventional-Commits-badged; GitHub Releases + downloads tracked.

Use cases: (a) **one Jellyfin client for everything** — Android + iOS + desktop (b) **recommend to your family** — they install from GH Releases (c) **replace Swiftfin/Finamp** (d) **offline-sync for road trips** (e) **ad-free** Jellyfin-only client (f) **beautiful-UI Jellyfin browser** (g) **developer-tested Flutter app** (h) **avoid vendor-specific mobile apps**.

Features (per README):

- **Cross-platform Flutter app** — desktop + mobile + (probably) web
- **Stream OR sync locally**
- **Multiple profiles + servers**
- **Direct/transcode/offline playback**
- **Intro/credits skipping**
- **Trickplay**
- **Library refresh + metadata editing**

- Upstream repo: <https://github.com/DonutWare/Fladder>
- Releases: <https://github.com/DonutWare/Fladder/releases>

## Architecture in one minute

- **Flutter (Dart)** — compiled per-platform
- **Talks to Jellyfin via its REST API**
- **Local cache** — SQLite + files for offline content
- **No server component** — client-only

## Compatible install methods

| Infra              | Runtime                                                        | Notes                                                                          |
| ------------------ | -------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| **Platform binaries** | **Android APK / iOS / macOS / Windows / Linux**              | **Primary**                                                                        |

## Inputs to collect

| Input                | Example                                                     | Phase        | Notes                                                                    |
| -------------------- | ----------------------------------------------------------- | ------------ | ------------------------------------------------------------------------ |
| Existing Jellyfin    | Required                                                    | Prereq       | Server you control                                                                                    |
| Jellyfin URL         | `https://jellyfin.example.com`                              | Config       | TLS                                                                                    |
| Jellyfin user + password | Per-user                                               | Auth         |                                                                                    |
| Device storage       | For offline sync                                            | Storage      |                                                                                    |

## Install

Desktop + mobile:
1. Go to <https://github.com/DonutWare/Fladder/releases/latest>
2. Download appropriate artifact:
   - `.apk` for Android
   - `.ipa` for iOS (may need sideloading)
   - `.app` / `.dmg` for macOS
   - `.exe` / installer for Windows
   - `.AppImage` / `.deb` for Linux
3. Install

## First boot

1. Open app
2. Enter Jellyfin URL + credentials
3. Add additional servers if multi-server
4. Configure playback preferences (direct/transcode)
5. Optional: pre-sync favorites for offline use

## Data & config layout

- **Per-platform app-data directory** (varies by OS)
- Contains Jellyfin URL + credentials (should be encrypted by OS keychain)
- Cached metadata + synced content

## Backup

Client app — typical approach: reinstall + reconnect (no backup needed).

## Upgrade

1. Releases: <https://github.com/DonutWare/Fladder/releases>. Active.
2. Download + install new version
3. Conventional Commits helps changelog readability

## Gotchas

- **141st HUB-OF-CREDENTIALS Tier 2 — CLIENT-SIDE JELLYFIN CREDS**:
  - Stores Jellyfin URL + user credentials on device
  - OS keychain preferred but not guaranteed
  - Offline content = potentially-private content on lost/stolen device
  - **141st tool in hub-of-credentials family — Tier 2 (client-side)**
  - **NEW sub-category: "client-app-with-credential-storage-on-device"** (1st — Fladder; distinct client-side framing)
- **CLIENT-APP NOT A SERVER**:
  - No self-host component
  - But operators may distribute/recommend this to users
  - **Recipe convention: "client-app-recipe-for-operator-distribution neutral-signal"**
  - **NEW neutral-signal convention** (Fladder 1st formally)
  - **Client-app-not-server: 1 tool** 🎯 **NEW FAMILY** (Fladder)
- **OFFLINE-CONTENT-ON-DEVICE-RISK**:
  - Lost/stolen device = content-leak
  - Many platforms offer device-encryption by default (iOS yes; Android-depends)
  - **Recipe convention: "offline-content-device-loss-risk callout"**
  - **NEW recipe convention** (Fladder 1st formally)
- **FLUTTER-CROSS-PLATFORM-TRADEOFF**:
  - One codebase = faster feature cadence
  - Platform-native polish sometimes sacrificed
  - **Recipe convention: "Flutter-cross-platform-UX-tradeoff neutral-signal"**
  - **NEW neutral-signal convention** (Fladder 1st formally)
- **iOS-DISTRIBUTION-CHALLENGES**:
  - Not on App Store (based on README lack-of-mention)
  - Need to sideload or use AltStore / TrollStore
  - Apple's barriers to indie iOS apps
  - **Recipe convention: "iOS-sideload-friction callout"**
  - **NEW recipe convention** (Fladder 1st formally)
- **CONVENTIONAL-COMMITS-BADGE**:
  - Signals automated-changelog + semantic-version discipline
  - **Recipe convention: "Conventional-Commits-badge positive-signal"**
  - **NEW positive-signal convention** (Fladder 1st formally)
- **MULTI-SERVER-MULTI-PROFILE**:
  - Switch between Jellyfin instances
  - Edge-case: family + friends' servers
  - **Recipe convention: "multi-server-multi-profile-client positive-signal"**
  - **NEW positive-signal convention** (Fladder 1st formally)
- **INTRO-CREDIT-SKIPPING**:
  - Jellyfin has intro-detection plugin; Fladder uses it
  - **Recipe convention: "server-plugin-consumed-by-client positive-signal"**
  - **NEW positive-signal convention** (Fladder 1st formally)
- **GH-RELEASES-ONLY (no app-store)**:
  - Distribution entirely via GitHub
  - Users must trust GH binaries
  - **Recipe convention: "GitHub-releases-only-distribution neutral-signal"**
  - **NEW neutral-signal convention** (Fladder 1st formally)
- **INSTITUTIONAL-STEWARDSHIP**: DonutWare org + CI + Conventional-Commits + GH downloads tracked + cross-platform-build-CI + active. **127th tool — cross-platform-client-org sub-tier** (NEW-soft).
- **TRANSPARENT-MAINTENANCE**: active + CI + releases + Conventional-Commits + downloads-visible. **133rd tool in transparent-maintenance family.**
- **NATIVE-MOBILE-COMPANION-APP FAMILY: 3 tools** (AliasVault+Docspell+Fladder) 🎯 **3-TOOL MILESTONE** — but Fladder is PRIMARY-client not companion-to-server
- **JELLYFIN-CLIENT-CATEGORY:**
  - **Fladder** — Flutter cross-platform
  - **Swiftfin** — native iOS/tvOS
  - **Finamp** — Flutter music-focused (Jellyfin audio)
  - **Jellyfin Mobile** — official Android
  - **Jellyfin Media Player** — desktop
- **ALTERNATIVES WORTH KNOWING:**
  - **Swiftfin** — if Apple-ecosystem-only + native-polish
  - **Finamp** — if you only need music
  - **Jellyfin official clients** — if you want default-supported
  - **Choose Fladder if:** you want one app on 5 platforms.
- **PROJECT HEALTH**: active + CI + Conventional-Commits + cross-platform-build. Strong.

## Links

- Repo: <https://github.com/DonutWare/Fladder>
- Releases: <https://github.com/DonutWare/Fladder/releases>
- Swiftfin (alt): <https://github.com/jellyfin/Swiftfin>
- Finamp (alt): <https://github.com/UnicornsOnLSD/finamp>
- Jellyfin official: <https://jellyfin.org/downloads>
